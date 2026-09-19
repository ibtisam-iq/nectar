# journalctl

`journalctl` queries the systemd journal, which stores every service's output, syslog messages and kernel messages with indexed metadata. Filtering by unit, boot, priority and time answers most "what happened to this service" questions in one command.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| By unit | `-u nginx` (repeatable) | `journalctl -u nginx -n 5` |
| Follow | `-f`, like `tail -f` | `journalctl -fu nginx` |
| By boot | `-b` current, `-b -1` previous; list with `--list-boots` | `journalctl --list-boots` |
| By priority | `-p err` means `err` and worse; ranges with `-p warning..err` | `journalctl -p err -b` |
| Kernel only | `-k` (implies the current boot unless `-b` is given) | `journalctl -k -n 5` |
| By time | `--since "1 hour ago"`, `--until "2026-09-17 05:48"`, `-S`/`-U` | `journalctl --since today` |
| Text search | `-g <regex>` (`--grep`) | `journalctl -g "bad command"` |
| By field | `_PID=`, `_COMM=`, `_UID=`, `SYSLOG_IDENTIFIER=` (`-t`) | `journalctl -F _SYSTEMD_UNIT` |
| Output modes | `short-iso`, `short-precise`, `cat`, `verbose`, `json`, `json-pretty` | `journalctl -o json -n 1` |
| Storage | `Storage=auto`: persistent only if `/var/log/journal` exists | `journalctl --header` (the `File path` line) |
| Size limit | `SystemMaxUse=` (default 10% of the filesystem, capped at 4G) | `journalctl --disk-usage` |
| Cleanup | `--vacuum-size=`, `--vacuum-time=`, `--vacuum-files=` | `journalctl --vacuum-time=2d` |
| Config | `/etc/systemd/journald.conf.d/*.conf`; restart `systemd-journald` | `systemd-analyze cat-config systemd/journald.conf` |
| Rate limit | Per service, `RateLimitBurst=` in `RateLimitIntervalSec=`; drops are logged as "Suppressed N messages" | `journalctl -u systemd-journald` |
| Write to it | `logger`, `systemd-cat`, or stdout of any service | `logger -t test hello` |
<!-- --8<-- [end:facts] -->

---

## Filtering by Unit, Priority and Kernel

`-u` selects a unit's messages, including those logged by systemd about it. `-n` limits the count and `--no-pager` makes the output suitable for scripts.

```bash
journalctl -u nginx -n 4 --no-pager
journalctl -p err -b --no-pager | tail -5
journalctl -k -n 4 --no-pager
```

Output:

```text
Sep 17 05:43:10 rocky-01 nginx[924]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Sep 17 05:43:10 rocky-01 systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
Sep 17 05:47:21 rocky-01 systemd[1]: Reloading nginx.service - The nginx HTTP and reverse proxy server...
Sep 17 05:47:21 rocky-01 systemd[1]: Reloaded nginx.service - The nginx HTTP and reverse proxy server.
Sep 17 05:43:10 rocky-01 kernel: SELinux: CONFIG_SECURITY_SELINUX_CHECKREQPROT_VALUE is non-zero.  This is deprecated and will be rejected in a future kernel release.
Sep 17 05:43:10 rocky-01 kernel: SELinux: https://github.com/SELinuxProject/selinux-kernel/wiki/DEPRECATE-checkreqprot
Sep 17 05:43:10 rocky-01 systemd[1]: Failed to start systemd-network-generator.service - Generate network units from Kernel command line.
Sep 17 05:43:10 rocky-01 kernel: cryptd: max_cpu_qlen set to 1000
Sep 17 05:43:10 rocky-01 kernel: AVX2 version of gcm_enc/dec engaged.
Sep 17 05:43:10 rocky-01 kernel: AES CTR mode by8 optimization enabled
Sep 17 05:43:35 rocky-01 systemd-rc-local-generator[1207]: /etc/rc.d/rc.local is not marked executable, skipping.
```

| Priority | Number | Typical content |
|---|---|---|
| `emerg` | 0 | System unusable |
| `alert` | 1 | Immediate action needed |
| `crit` | 2 | Hardware or critical failure |
| `err` | 3 | Errors, failed units |
| `warning` | 4 | Warnings |
| `notice` | 5 | Normal but significant |
| `info` | 6 | Informational |
| `debug` | 7 | Debug output |

A quick summary of what went wrong since boot groups identical messages:

```bash
journalctl -b -p warning..err -o cat --no-pager | sort | uniq -c | sort -rn | head -5
```

Output:

```text
      1 systemd-network-generator.service: Failed with result 'exit-code'.
      1 software IO TLB: No low mem
      1 release 42 started
      1 atd.service: Referenced but unset environment variable evaluates to an empty string: OPTS
      1 [Firmware Bug]: TSC doesn't count with P0 frequency!
```

---

## Filtering by Time, Text and Field

Several `-u` options combine with OR; different filter types combine with AND. `-r` prints newest first.

```bash
journalctl -u nginx -u crond --since today --until "05:48" -r -n 3 --no-pager
journalctl -g "bad command" --no-pager
journalctl _COMM=crontab -o short-iso --no-pager | tail -3
journalctl -F _SYSTEMD_UNIT | sort | head -8
```

Output:

```text
Sep 17 05:47:21 rocky-01 systemd[1]: Reloaded nginx.service - The nginx HTTP and reverse proxy server.
Sep 17 05:47:21 rocky-01 systemd[1]: Reloading nginx.service - The nginx HTTP and reverse proxy server...
Sep 17 05:47:01 rocky-01 crond[930]: (CRON) bad command (/etc/cron.d/report)
Sep 17 05:47:01 rocky-01 crond[930]: (CRON) bad command (/etc/cron.d/report)
2026-09-17T05:47:36+00:00 rocky-01 crontab[2152]: (bob) AUTH (crontab command not allowed)
2026-09-17T05:47:36+00:00 rocky-01 crontab[2267]: (laborant) REPLACE (laborant)
2026-09-17T05:47:36+00:00 rocky-01 crontab[2232]: (laborant) LIST (laborant)
atd.service
crond.service
dbus-broker.service
examiner.service
healthcheck.service
init.scope
nginx.service
rsyslog.service
```

`-F` lists every value a field has taken, which is how to discover unit names or identifiers to filter on. `examiner.service` is the iximiuz Labs agent that ran these commands.

### Structured fields

Every entry carries trusted fields (prefixed `_`, set by journald) and fields supplied by the sender.

```bash
journalctl -u crond -n 1 -o verbose --no-pager
```

Output:

```text
Thu 2026-09-17 05:48:01.862268 UTC [s=af35bd2a1fad4d609d262225b39dea17;i=471;b=9977b4c094c543d1adee466cf7cd4b89;m=1172d95a;t=65ba753ae4f20;x=4d9ca3a460989e16]
    _BOOT_ID=9977b4c094c543d1adee466cf7cd4b89
    _MACHINE_ID=0edc75cd1dd1440c9cb5984b45402cdb
    _HOSTNAME=rocky-01
    _RUNTIME_SCOPE=system
    PRIORITY=6
    _UID=0
    _GID=0
    _SELINUX_CONTEXT=kernel
    _SYSTEMD_SLICE=system.slice
    _CAP_EFFECTIVE=1ffffffffff
    _TRANSPORT=syslog
    SYSLOG_FACILITY=9
    _COMM=crond
    _EXE=/usr/sbin/crond
    _SYSTEMD_CGROUP=/system.slice/crond.service
    _SYSTEMD_UNIT=crond.service
    _SYSTEMD_INVOCATION_ID=b8bcccd8982649e4a810cb86a1df3192
    SYSLOG_IDENTIFIER=CROND
    _CMDLINE=/usr/sbin/CROND -n
    SYSLOG_TIMESTAMP=Sep 17 05:48:01 
    SYSLOG_PID=2282
    _PID=2282
    MESSAGE=(root) CMDEND (/opt/jobs/nightly.sh)
    _SOURCE_REALTIME_TIMESTAMP=1789624081862268
```

`-o json` emits the same fields on one line per entry, ready for `jq`:

```bash
journalctl -t deploy -o json --no-pager | jq -r ".PRIORITY, .SYSLOG_FACILITY, .MESSAGE"
```

Output:

```text
4
16
release 42 started
```

Facility 16 is `local0` and priority 4 is `warning`, as sent by `logger -p local0.warning`.

---

## Boots and Persistence

With `Storage=auto` (the default), journald writes to `/var/log/journal` only if the directory exists; otherwise it keeps a volatile journal in `/run/log/journal`. The Rocky playground started volatile, so `-b -1` had nothing to show.

```bash
journalctl -b -1 --no-pager
journalctl --header | grep "File path"
```

Output:

```text
Specifying boot ID or boot offset has no effect, no persistent journal was found.
File path: /run/log/journal/0edc75cd1dd1440c9cb5984b45402cdb/system.journal
```

Creating the directory with the right ownership and flushing the runtime journal makes it persistent without a reboot. As root:

```bash
mkdir -p /var/log/journal && systemd-tmpfiles --create --prefix /var/log/journal && journalctl --flush
ls -ld /var/log/journal; journalctl --header | grep "File path"
```

Output:

```text
drwxr-sr-x+ 3 root systemd-journal 4096 Sep 17 05:48 /var/log/journal
File path: /var/log/journal/0edc75cd1dd1440c9cb5984b45402cdb/system.journal
```

After a reboot, both boots are available:

```bash
journalctl --list-boots --no-pager
journalctl -b -1 -n 4 --no-pager
journalctl -b -1 -k -g "Killed process|segfault|blocked for more" -o cat --no-pager
```

Output:

```text
IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
 -1 9977b4c094c543d1adee466cf7cd4b89 Thu 2026-09-17 05:43:10 UTC Thu 2026-09-17 06:00:24 UTC
  0 c70c671e1088493aa0c29f0e04252988 Thu 2026-09-17 06:00:26 UTC Thu 2026-09-17 06:01:24 UTC
Sep 17 06:00:24 rocky-01 systemd-shutdown[1]: Syncing filesystems and block devices.
Sep 17 06:00:24 rocky-01 systemd-shutdown[1]: Sending SIGTERM to remaining processes...
Sep 17 06:00:24 rocky-01 systemd-journald[2507]: Received SIGTERM from PID 1 (systemd-shutdow).
Sep 17 06:00:24 rocky-01 systemd-journald[2507]: Journal stopped
parse-config[4369]: segfault at 0 ip 0000000000401163 sp 00007ffd294110a0 error 6 in parse-config[401000+1000] likely on CPU 1 (core 1, socket 0)
Memory cgroup out of memory: Killed process 4383 (python3) total-vm:78352kB, anon-rss:65184kB, file-rss:5304kB, shmem-rss:0kB, UID:0 pgtables:192kB oom_score_adj:0
parse-config[4467]: segfault at 0 ip 0000000000401163 sp 00007ffc50338b40 error 6 in parse-config[401000+1000] likely on CPU 3 (core 3, socket 0)
INFO: task sh:4577 blocked for more than 10 seconds.
INFO: task sh:4577 blocked for more than 20 seconds.
```

!!! tip "The last lines of the previous boot explain an unplanned reboot"
    A clean shutdown ends with `systemd-shutdown` lines, as above. A journal that stops mid-sentence with no shutdown sequence points to a power loss, a kernel panic or a hypervisor reset.

!!! warning "-k silently restricts the search to the current boot"
    `journalctl -k --since "2026-09-17 05:55:00"` returned `-- No entries --` after the reboot although the kernel lines exist; adding `-b -1` found them.

---

## Size, Retention and Configuration

journald's defaults live in `/usr/lib/systemd/journald.conf` on Rocky 10.2 (there is no `/etc/systemd/journald.conf`); overrides go in a drop-in. The startup line reports the current size and limit. As root:

```bash
mkdir -p /etc/systemd/journald.conf.d; printf "[Journal]\nSystemMaxUse=200M\nMaxRetentionSec=1month\n" > /etc/systemd/journald.conf.d/50-size.conf; systemctl restart systemd-journald; journalctl -u systemd-journald -n 3 --no-pager
```

Output:

```text
Sep 17 05:48:37 rocky-01 systemd-journald[2507]: Collecting audit messages is disabled.
Sep 17 05:48:37 rocky-01 systemd-journald[2507]: Journal started
Sep 17 05:48:37 rocky-01 systemd-journald[2507]: System Journal (/var/log/journal/0edc75cd1dd1440c9cb5984b45402cdb) is 8M, max 200M, 191.9M free.
```

Before the drop-in, the same line said `max 4G, 3.9G free`. `journalctl --vacuum-size=100M` or `--vacuum-time=2d` removes archived files immediately; the active file is never deleted.

### Rate limiting

A service that floods the journal loses messages once it exceeds its burst. The limit below is set low to make it visible; the defaults are 10000 messages per 30 seconds, scaled up with free disk space. As root:

```bash
systemd-run --unit=flood -p LogRateLimitIntervalSec=5s -p LogRateLimitBurst=100 -q /usr/bin/bash -c 'for i in $(seq 1 5000); do echo "retrying db connection $i"; done; sleep 7; echo done'
sleep 9; journalctl -u flood -o cat --no-pager | grep -c retrying; journalctl -u flood --no-pager | grep -v retrying
```

Output:

```text
276
Sep 17 06:06:38 rocky-01 systemd-journald[360]: Suppressed 4725 messages from flood.service
Sep 17 06:06:38 rocky-01 bash[1663]: done
Sep 17 06:06:38 rocky-01 systemd[1]: flood.service: Deactivated successfully.
```

---

## Access Control

Users outside `adm`, `systemd-journal` and `wheel` see only their own user journal, which may not exist. The user `bob` is in none of those groups:

```bash
journalctl -n 2 --no-pager
```

Output:

```text
Hint: You are currently not seeing messages from other users and the system.
      Users in groups 'adm', 'systemd-journal', 'wheel' can see all messages.
      Pass -q to turn off this notice.
No journal files were opened due to insufficient permissions.
```

---

## Common Errors

### `Specifying boot ID or boot offset has no effect, no persistent journal was found.`

**Cause:** The journal is volatile, so earlier boots were never stored.

**Fix:** Create `/var/log/journal` as shown above, or set `Storage=persistent` in a drop-in.

### `No journal files were opened due to insufficient permissions.`

**Cause:** The user is not in a group with journal access.

**Fix:** `sudo usermod -aG systemd-journal <user>` (or `adm`), then log in again.

### `Suppressed 4725 messages from flood.service`

**Cause:** The service exceeded its log rate limit, and the lines were discarded.

**Fix:** Reduce the log volume, or raise `LogRateLimitBurst=` for that unit or `RateLimitBurst=` in `journald.conf`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do you see the logs of one service since the last boot?"
    **Say first:** `journalctl -u <unit> -b`.

    **Proof:** `journalctl -u nginx -b --no-pager`

    **Follow-up:** And for the boot before the last one?

??? question "L1: Why can journalctl -b -1 return nothing?"
    **Say first:** The journal is volatile: `/var/log/journal` does not exist, so only the current boot is kept in `/run`.

    **Proof:** `journalctl --header | grep "File path"` shows `/run/log/journal`.

    **Follow-up:** How do you make it persistent without a reboot?
<!-- --8<-- [end:l1] -->

??? question "L2: Show only errors from the last hour, from all services, newest first."
    **Say first:** Combine priority, time and reverse order.

    **Proof:** `journalctl -p err --since "1 hour ago" -r`

    **Follow-up:** How do you include warnings but exclude notices? (`-p warning..emerg` or `-p 0..4`.)

??? question "L2: The journal uses 4 GB of disk. Reduce it now and cap it for the future."
    **Say first:** Vacuum now, then set `SystemMaxUse=` in a drop-in.

    **Proof:** `sudo journalctl --vacuum-size=500M`; `SystemMaxUse=500M` in `/etc/systemd/journald.conf.d/50-size.conf`; `sudo systemctl restart systemd-journald`.

    **Follow-up:** Why does vacuum never delete the file currently being written?

??? question "L2: Extract the messages of a script's runs in JSON for another tool."
    **Say first:** Tag the script's output and query by identifier.

    **Proof:** `./backup.sh 2>&1 | systemd-cat -t backup`; `journalctl -t backup -o json | jq -r .MESSAGE`

    **Follow-up:** Which fields can the script not forge? (Those starting with `_`.)

??? question "L2: List every process name that logged in this boot."
    **Say first:** Ask for the distinct values of a field.

    **Proof:** `journalctl -b -F _COMM`

    **Follow-up:** How do you then show only one PID's messages? (`journalctl _PID=2282`.)

??? question "L3: A service logs thousands of lines per second and some lines are missing from the journal. What happened?"
    **Say first:** journald rate limiting dropped them and logged a "Suppressed N messages" line.

    **Proof:** `journalctl -u systemd-journald -g Suppressed`

    **Follow-up:** Why is raising the limit not the whole fix? (The flood costs disk and CPU; the service's log level is the root cause.)

??? question "L3: A server rebooted overnight and nobody knows why. Where do you look?"
    **Say first:** The end of the previous boot's journal, then kernel messages from that boot.

    **Proof:** `journalctl -b -1 -n 50`; `journalctl -b -1 -k -p warning`; `last -x reboot shutdown`.

    **Follow-up:** What does a journal that ends with no shutdown lines suggest?

---

## Related

- [Log Locations](log-locations.md): where rsyslog copies these messages
- [systemctl](../08-systemd-and-services/systemctl.md): the journal lines in `status`
- [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md): kernel entries
- [Service Won't Start](../interview/scenarios/service-wont-start.md): the journal as the first check

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
