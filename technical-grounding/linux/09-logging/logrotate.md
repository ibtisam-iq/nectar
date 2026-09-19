# logrotate

`logrotate` renames, compresses and deletes log files on a schedule so that `/var/log` does not fill the disk. The interview point is what happens to a program that still holds the old file open, and how `create`, `copytruncate` and `postrotate` handle it.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Config | `/etc/logrotate.conf` (globals), `/etc/logrotate.d/<app>` (per log) | `cat /etc/logrotate.conf` |
| Schedule | `logrotate.timer`, daily on both families (cron.daily on older systems) | `systemctl list-timers logrotate.timer` |
| State file | Last rotation per file: RHEL `/var/lib/logrotate/logrotate.status`, Ubuntu `/var/lib/logrotate/status` | `cat` the file |
| Dry run | `logrotate -d <conf>` changes nothing | `logrotate -d /etc/logrotate.conf` |
| Force | `logrotate -f <conf>` rotates even if not due | `logrotate -v -f /etc/logrotate.d/app` |
| Frequency | `daily`, `weekly`, `monthly`, `yearly`, or `size 100M`; `maxsize` combines both | `man logrotate.conf` |
| Keep | `rotate 7` keeps seven old files | `ls /var/log/app` |
| Naming | Numbered (`app.log.1`) or dated with `dateext` (RHEL default) | `ls /var/log` |
| `create` | Rename the file, create a new empty one; the program must reopen | `postrotate` block |
| `copytruncate` | Copy then truncate in place; the program keeps its descriptor; lines written between copy and truncate are lost | `ls -l /proc/<pid>/fd` |
| `compress` / `delaycompress` | gzip old files; skip the newest one | `ls *.gz` |
| `postrotate` ... `endscript` | Command after rotation, usually a reload or `kill -USR1` | `cat /etc/logrotate.d/nginx` |
| `sharedscripts` | Run `postrotate` once for all files that matched | `cat /etc/logrotate.d/nginx` |
| `su user group` | Rotate as that user; required when the directory is group- or world-writable | `logrotate -d` warning |
<!-- --8<-- [end:facts] -->

---

## Defaults on Each Family

=== "RHEL / Rocky"

    ```bash
    grep -v "^#" /etc/logrotate.conf | grep .
    systemctl cat logrotate.timer | grep -E "^On|^Acc|^Rand|^Pers"
    ```

    Output:

    ```text
    weekly
    rotate 4
    create
    dateext
    include /etc/logrotate.d
    OnCalendar=daily
    RandomizedDelaySec=1h
    Persistent=true
    ```

=== "Ubuntu / Debian"

    ```bash
    cat /etc/logrotate.conf | grep -v "^#" | grep .
    logrotate -d /etc/logrotate.conf 2>&1 | grep -i "state" | head -2
    ```

    Output:

    ```text
    weekly
    su root adm
    rotate 4
    create
    include /etc/logrotate.d
    Reading state from file: /var/lib/logrotate/status
    state file /var/lib/logrotate/status does not exist
    ```

    The state file appears after the first scheduled run. Ubuntu has no `dateext`, so rotated files are numbered (`syslog.1`, `syslog.2.gz`), and the global `su root adm` matches the `adm`-group log files.

The vendor rule for nginx shows the usual pattern: rename, create a new file, then signal the master process to reopen its logs.

```bash
cat /etc/logrotate.d/nginx
```

Output:

```text
/var/log/nginx/*.log {
    create 0640 nginx root
    daily
    rotate 10
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /bin/kill -USR1 `cat /run/nginx.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
```

---

## The Open File Descriptor Problem

A program that opened `app.log` holds a descriptor to the inode, not to the name. After `create` renames the file, the program keeps writing into `app.log.1`, and the new `app.log` stays empty. The demo below uses a small writer that never reopens its log.

```bash
cat /etc/logrotate.d/app
logrotate -v -f /etc/logrotate.d/app 2>&1 | tail -8
sleep 2
ls -l /var/log/app
ls -l /proc/$(systemctl show -p MainPID --value app-writer)/fd | grep app
tail -1 /var/log/app/app.log.1; wc -l < /var/log/app/app.log
```

Output:

```text
/var/log/app/*.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    create 0640 root root
}
old log /var/log/app/app.log.3.gz does not exist
renaming /var/log/app/app.log.2.gz to /var/log/app/app.log.3.gz (rotatecount 7, logstart 1, i 2), 
old log /var/log/app/app.log.2.gz does not exist
renaming /var/log/app/app.log.1.gz to /var/log/app/app.log.2.gz (rotatecount 7, logstart 1, i 1), 
old log /var/log/app/app.log.1.gz does not exist
log /var/log/app/app.log.8.gz doesn't exist -- won't try to dispose of it
renaming /var/log/app/app.log to /var/log/app/app.log.1
creating new /var/log/app/app.log mode = 0640 uid = 0 gid = 0
total 4
-rw-r----- 1 root root   0 Sep 17 05:53 app.log
-rw-r--r-- 1 root root 390 Sep 17 05:53 app.log.1
l-wx------ 1 root root 64 Sep 17 05:53 3 -> /var/log/app/app.log.1
05:53:27 request 20
0
```

The same thing makes a deleted log keep using disk: `rm` removes the name, the writer keeps the inode, and `df` does not drop until the program closes it. There are two fixes:

| Fix | How | Trade-off |
|---|---|---|
| Signal the program to reopen | `postrotate` with `systemctl reload app` or `kill -USR1` | Needs support in the program; no lost lines |
| Truncate in place | `copytruncate` instead of `create` | Works with any program; lines written during the copy are lost; the file must be opened with `O_APPEND` |

After replacing `create 0640 root root` with `copytruncate` in the rule and restarting the writer, it keeps its descriptor on `app.log`:

```bash
logrotate -f /etc/logrotate.conf; ls -l /var/log/app
sleep 2
ls -l /var/log/app; ls -l /proc/$(systemctl show -p MainPID --value app-writer)/fd | grep app
```

Output:

```text
total 8
-rw-r----- 1 root root  20 Sep 17 05:53 app.log
-rw-r----- 1 root root 190 Sep 17 05:53 app.log-20260917
total 8
-rw-r----- 1 root root 220 Sep 17 05:53 app.log
-rw-r----- 1 root root 190 Sep 17 05:53 app.log-20260917
l-wx------ 1 root root 64 Sep 17 05:53 3 -> /var/log/app/app.log
```

This time the file is named `app.log-20260917`, because the run used `/etc/logrotate.conf`, which sets `dateext` and then includes the app rule.

!!! warning "Running logrotate on one snippet ignores the global settings"
    `logrotate -f /etc/logrotate.d/app` produced `app.log.1`; `logrotate -f /etc/logrotate.conf` produced `app.log-20260917`. Test a rule through the main file, or repeat the needed globals inside the snippet.

!!! tip "copytruncate needs an appending writer"
    A program that writes at its own offset without `O_APPEND` continues at the old offset after truncation, leaving a sparse file that starts with NUL bytes. The writer above opens with mode `a`, so the new file starts cleanly.

---

## Dry Runs and the State File

`-d` prints the decision for each file without changing anything. logrotate rotates only when the state file says the interval has passed.

```bash
grep -v "app" /var/lib/logrotate/logrotate.status | head -3; grep app /var/lib/logrotate/logrotate.status
logrotate -d /etc/logrotate.conf 2>&1 | grep -A4 "considering log /var/log/nginx/access.log"
```

Output:

```text
logrotate state -- version 2
"/var/log/nginx/error.log" 2026-9-17-5:53:52
"/var/log/hawkey.log" 2026-9-17-5:53:52
"/var/log/app/app.log" 2026-9-17-5:53:52
considering log /var/log/nginx/access.log
  Now: 2026-09-17 05:53
  Last rotated at 2026-09-17 05:53
  log does not need rotating (log has already been rotated)
considering log /var/log/nginx/error.log
```

---

## Common Errors

### `error: skipping "/var/log/app/app.log" because parent directory has insecure permissions (It's world writable or writable by group which is not "root") Set "su" directive in config file to tell logrotate which user/group should be used for rotation.`

**Cause:** The log directory is writable by a non-root group or by everyone, so rotating as root could be abused through symlinks.

**Fix:** Tighten the directory to `0755 root root`, or add `su <user> <group>` to the rule. The captured case was `chmod 775 /var/log/app; chgrp laborant /var/log/app`.

### `warning: /tmp/bad.conf:4 unknown option 'copytruncte' -- ignoring line`

**Cause:** A misspelled directive; logrotate skips the line and continues with the rest.

**Fix:** Run `logrotate -d` after every change and read the warnings.

### `error: /tmp/dup.conf:1 duplicate log entry for /var/log/app/app.log`

**Cause:** Two rules match the same file.

**Fix:** Keep one rule per file; check with `grep -r app.log /etc/logrotate.d`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between create and copytruncate?"
    **Say first:** `create` renames the file and makes a new one, so the program must reopen it; `copytruncate` copies and truncates in place, so the program keeps writing but a few lines can be lost.

    **Proof:** `ls -l /proc/<pid>/fd` shows `app.log.1` after `create` without a reload.

    **Follow-up:** Which one does the nginx package use, and how does nginx reopen?

??? question "L1: How is logrotate scheduled on current RHEL and Ubuntu?"
    **Say first:** By `logrotate.timer`, daily, with `Persistent=true`.

    **Proof:** `systemctl list-timers logrotate.timer`

    **Follow-up:** Why does a weekly rule still wait a week if the timer runs daily? (The state file.)
<!-- --8<-- [end:l1] -->

??? question "L2: Rotate /var/log/app/*.log daily, keep 14 compressed copies, and reload the service afterwards."
    **Say first:** One rule file with `daily`, `rotate 14`, `compress`, `delaycompress`, `sharedscripts` and a `postrotate` reload.

    **Proof:** `postrotate` / `systemctl reload app >/dev/null 2>&1 || true` / `endscript`; then `logrotate -d /etc/logrotate.conf`.

    **Follow-up:** Why `delaycompress`?

??? question "L2: Test a new rule without waiting for tomorrow."
    **Say first:** Dry run, then force a rotation through the main config.

    **Proof:** `logrotate -d /etc/logrotate.conf`; `logrotate -v -f /etc/logrotate.conf`

    **Follow-up:** What does forcing do to every other log on the host?

??? question "L2: Rotate a log when it reaches 100 MB, even if the rule is daily."
    **Say first:** Use `maxsize 100M` with `daily`, and run logrotate more often (an hourly timer).

    **Proof:** `maxsize 100M` in the rule; `systemctl edit logrotate.timer` with `OnCalendar=hourly`.

    **Follow-up:** How does `size` differ from `maxsize`? (`size` ignores the time interval.)

??? question "L3: After rotation, the application's log file stays at 0 bytes and the disk keeps filling. Why?"
    **Say first:** The program still writes to the renamed file because nothing told it to reopen.

    **Proof:** `ls -l /proc/<pid>/fd | grep log`; `lsof +L1` for deleted rotated files still open.

    **Follow-up:** Fix with a `postrotate` reload, or `copytruncate` if the program cannot reopen.

??? question "L3: logrotate runs but one application's logs never rotate. What do you check?"
    **Say first:** The dry-run decision, the state file and warnings about permissions or duplicates.

    **Proof:** `logrotate -d /etc/logrotate.conf 2>&1 | grep -A5 app`; `grep app /var/lib/logrotate/logrotate.status`; `journalctl -u logrotate`.

    **Follow-up:** What does "parent directory has insecure permissions" require?

---

## Related

- [Log Locations](log-locations.md): the files being rotated
- [File Descriptors](../02-files-and-filesystem/file-descriptors.md): why a renamed file is still written
- [Systemd Timers](../10-scheduling/systemd-timers.md): `logrotate.timer`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
