# Time and Timezones

Linux keeps system time in UTC and converts it to a timezone only for display, while an NTP client (chrony on RHEL and current Ubuntu) keeps the clock correct. Wrong time breaks TLS, Kerberos, TOTP, log correlation and distributed systems such as etcd, so time is part of every "it works on one server only" investigation.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Owner | `timedatectl` shows and sets time, timezone and NTP state | `timedatectl` |
| Timezone | `/etc/localtime` is a symlink into `/usr/share/zoneinfo/`; `TZ=` overrides it per process | `ls -l /etc/localtime` |
| Set timezone | `timedatectl set-timezone Asia/Karachi` | `timedatectl list-timezones` |
| NTP client | chrony (`chronyd`) on RHEL and Ubuntu with the `chrony` package; `systemd-timesyncd` is Ubuntu's minimal default | `systemctl is-active chronyd` |
| chrony config | RHEL `/etc/chrony.conf`; Ubuntu `/etc/chrony/chrony.conf` plus `sources.d/*.sources` | `grep ^pool /etc/chrony.conf` |
| Server vs pool | `server` is one host; `pool` resolves a name to several; `iburst` speeds up the first sync | `chronyc sources` |
| Step vs slew | `makestep 1.0 3` steps the clock if it is off by more than 1 s during the first 3 updates; otherwise chrony slews it gradually | `journalctl -u chronyd` |
| Serving time | `allow <network>` makes chronyd an NTP server on UDP 123 | `ss -ulpn 'sport = :123'` |
| Stratum | Distance from a reference clock; each NTP hop adds one | `chronyc tracking` |
| Manual time | `timedatectl set-time` requires NTP off, and interprets the value in the local timezone | `timedatectl set-ntp false` |
| RTC | The hardware clock (`hwclock`), normally in UTC; many cloud and microVM instances have none | `timedatectl` (`RTC time`) |
| Epoch | Seconds since 1970-01-01 UTC | `date +%s`, `date -d @0 -u` |
<!-- --8<-- [end:facts] -->

---

## Timezones

```bash
timedatectl
timedatectl list-timezones | grep -E 'Karachi|Kolkata'
sudo timedatectl set-timezone Asia/Karachi
ls -l /etc/localtime
date; date -u
TZ=America/New_York date
date -d '2026-09-17 09:00 UTC'
date -d @0 -u
```

Output:

```text
               Local time: Thu 2026-09-17 12:18:53 UTC
           Universal time: Thu 2026-09-17 12:18:53 UTC
                 RTC time: n/a
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: no
              NTP service: inactive
          RTC in local TZ: no
Asia/Karachi
Asia/Kolkata
lrwxrwxrwx 1 root root 34 Sep 17 17:19 /etc/localtime -> ../usr/share/zoneinfo/Asia/Karachi
Thu Sep 17 17:19:12 PKT 2026
Thu Sep 17 12:19:12 UTC 2026
Thu Sep 17 08:19:12 EDT 2026
Thu Sep 17 14:00:00 PKT 2026
Thu Jan  1 00:00:00 UTC 1970
```

The kernel clock did not change; only the display did. `TZ=` affects one command, and `date -d` converts a time given in UTC into the local zone. The timezone was set back to UTC afterwards.

!!! tip "Keep servers in UTC"
    UTC has no daylight saving jumps, and logs from servers in different regions line up without conversion. Applications and people convert to local time at the edge.

---

## NTP with chrony

In the lab, `web` syncs from the public pool and serves time to the other hosts (`allow 172.16.0.0/16` appended to `/etc/chrony.conf`). Public server addresses are replaced with documentation addresses:

```bash
grep -vE '^#|^$' /etc/chrony.conf
chronyc -n sources
chronyc tracking | head -4
```

Output:

```text
pool 2.rocky.pool.ntp.org iburst
sourcedir /run/chrony-dhcp
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
ntsdumpdir /var/lib/chrony
logdir /var/log/chrony
allow 172.16.0.0/16
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^+ 198.51.100.152                2   6    17    25  -2058us[-2296us] +/-   17ms
^- 198.51.100.141                2   6   113    19  +3434us[+3434us] +/-   73ms
^* 192.0.2.123                   4   6    17    25  +1019us[ +767us] +/-   12ms
^- 203.0.113.200                 3   6    17    26  -1233us[-1442us] +/-   70ms
Reference ID    : C000027B (192.0.2.123)
Stratum         : 5
Ref time (UTC)  : Thu Sep 17 12:18:19 2026
System time     : 0.000014169 seconds slow of NTP time
```

| Column | Meaning |
|---|---|
| `^` | A server (`=` a peer) |
| `*` / `+` / `-` / `?` | Selected, combined, not combined, unusable |
| `Poll` | Log2 of the polling interval (6 = 64 s) |
| `Reach` | Octal register of the last 8 polls; `377` means all answered |
| `Last sample` | Adjusted offset, `[measured offset]`, and the error margin |

The router `gw` uses `web` as its only server:

=== "RHEL / Rocky"

    ```bash
    sudo sed -i 's/^pool .*/server 172.16.1.3 iburst/' /etc/chrony.conf
    sudo systemctl enable --now chronyd
    sleep 6; chronyc sources
    chronyc tracking | grep -E 'Reference|Stratum|System time|Leap'
    timedatectl | grep -E 'synchronized|NTP service'
    ```

    Output:

    ```text
    MS Name/IP address         Stratum Poll Reach LastRx Last sample               
    ===============================================================================
    ^* web                           5   6     7     2    -10ns[ -143ms] +/-   34ms
    Reference ID    : AC100103 (web)
    Stratum         : 6
    System time     : 0.007435778 seconds slow of NTP time
    Leap status     : Normal
    System clock synchronized: yes
                  NTP service: active
    ```

=== "Ubuntu / Debian"

    ```bash
    echo 'server 172.16.1.3 iburst' | sudo tee /etc/chrony/sources.d/lab.sources
    sudo systemctl enable --now chrony
    sleep 16; chronyc sources | grep -E '^MS|web'
    timedatectl | grep -E 'synchronized|NTP service'
    ```

    Output:

    ```text
    server 172.16.1.3 iburst
    # ... (trimmed)
    MS Name/IP address         Stratum Poll Reach LastRx Last sample               
    ^* web                           3   6    17    11   +737ns[  +28us] +/-   19ms
    System clock synchronized: yes
                  NTP service: active
    ```

    Installing `chrony` removed `systemd-timesyncd`; the Ubuntu pool servers stay configured next to the new source.

On `gw`, the first sample (`[ -143ms]`) shows the clock was 143 ms behind, and the adjusted offset of `-10ns` shows it was corrected. The stratum is one higher than the source's.

---

## Wrong Time and Its Effects

`set-time` needs NTP turned off. When NTP comes back, chronyd steps the clock:

```bash
sudo timedatectl set-ntp false
sudo timedatectl set-time '2026-09-17 12:00:00'
date
sudo timedatectl set-ntp true
sleep 5; date
sudo journalctl -u chronyd --since -1min --no-pager -o cat | grep -i 'clock'
```

Output:

```text
Thu Sep 17 12:00:00 UTC 2026
Thu Sep 17 12:19:39 UTC 2026
# ... (trimmed)
System clock wrong by 19152.562322 seconds
System clock was stepped by 19152.562322 seconds
System clock wrong by 1174.067989 seconds
System clock was stepped by 1174.067989 seconds
```

The last pair is this test: the clock was 1174 seconds (about 20 minutes) behind and chrony stepped it within five seconds. The earlier pair, 19152 seconds, came from the same command a minute before, run while the timezone was still `Asia/Karachi`: `set-time` read `12:00` as Pakistan time, 5 hours 19 minutes behind the real UTC time.

!!! warning "set-time uses the local timezone"
    `timedatectl set-time '12:00'` on a host in `PKT` sets 07:00 UTC. Check `Time zone` first, or give the time with an explicit zone through `date -s '12:00 UTC'`.

A clock outside a certificate's validity window makes every TLS connection fail. `openssl verify -attime` shows the effect without changing the clock:

```bash
openssl req -x509 -newkey rsa:2048 -nodes -keyout k.pem -out c.pem -days 30 -subj /CN=api.shop.internal 2>/dev/null
openssl x509 -in c.pem -noout -dates
openssl verify -CAfile c.pem c.pem
openssl verify -CAfile c.pem -attime "$(date -d '-1 day' +%s)" c.pem
openssl verify -CAfile c.pem -attime "$(date -d '+60 days' +%s)" c.pem
```

Output:

```text
notBefore=Sep 17 12:20:01 2026 GMT
notAfter=Oct 17 12:20:01 2026 GMT
c.pem: OK
CN = api.shop.internal
error 9 at 0 depth lookup: certificate is not yet valid
error c.pem: verification failed
CN = api.shop.internal
error 10 at 0 depth lookup: certificate has expired
error c.pem: verification failed
```

A server whose clock runs a day behind rejects a certificate issued today as `not yet valid`; a clock far ahead rejects a valid certificate as expired.

---

## Common Errors

### `hwclock: Cannot access the Hardware Clock via any known method.`

**Cause:** the VM has no real-time clock device, as `RTC time: n/a` in `timedatectl` shows.

**Fix:** nothing to fix; the clock comes from the hypervisor and NTP.

### `506 Cannot talk to daemon`

**Cause:** `chronyc` ran while `chronyd` was stopped.

**Fix:** `sudo systemctl enable --now chronyd` (Ubuntu: `chrony`).

### `error 9 at 0 depth lookup: certificate is not yet valid`

**Cause:** the local clock is earlier than the certificate's `notBefore`.

**Fix:** fix time synchronization, then retry; check with `timedatectl` and `chronyc tracking`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why should servers run NTP, and what breaks without it?"
    **Say first:** clocks drift, and wrong time breaks TLS validity checks, Kerberos, TOTP, scheduled jobs, log correlation and distributed consensus.

    **Proof:** `openssl verify -attime` with a shifted time fails; `chronyc tracking` shows the offset.

    **Follow-up:** Which component in Kubernetes is most sensitive to clock skew?

??? question "L1: What is the difference between stepping and slewing the clock?"
    **Say first:** stepping jumps the time at once; slewing speeds up or slows down the clock until it is correct, so time never goes backwards.

    **Proof:** `makestep 1.0 3` in `chrony.conf`; `journalctl -u chronyd` shows `System clock was stepped`.

    **Follow-up:** Why can a backwards step hurt a database or a log pipeline?
<!-- --8<-- [end:l1] -->

??? question "L2: Set the timezone to Asia/Karachi and show the current time in UTC and in New York."
    **Say first:** `timedatectl set-timezone`, then `date -u` and `TZ=`.

    **Proof:** `sudo timedatectl set-timezone Asia/Karachi; date -u; TZ=America/New_York date`.

    **Follow-up:** Where does the timezone setting live on disk?

??? question "L2: Configure a RHEL host to sync only from 172.16.1.3 and prove it is synchronized."
    **Say first:** replace the `pool` line with a `server` line and restart chronyd.

    **Proof:** `server 172.16.1.3 iburst` in `/etc/chrony.conf`; `chronyc sources` shows `^*`; `timedatectl` shows `System clock synchronized: yes`.

    **Follow-up:** What must the time server allow?

??? question "L2: Read this: chronyc sources shows Reach 0 and ? for the only server. What do you check?"
    **Say first:** the server is not answering: check UDP 123 reachability, the server's `allow` list and its daemon.

    **Proof:** `ss -ulpn 'sport = :123'` on the server; `sudo tcpdump -ni any udp port 123` on both sides.

    **Follow-up:** Why does a firewall rule for TCP 123 not help?

??? question "L3: TLS handshakes from one server fail with certificate is not yet valid, while other servers work. What do you do?"
    **Say first:** compare that server's clock with a good source and fix its time synchronization.

    **Proof:** `timedatectl`; `chronyc tracking`; `date -u` against another host; `openssl s_client -connect host:443` shows the verify error.

    **Follow-up:** Why can a VM's clock jump after a suspend or a host migration?

---

## Related

- [Scheduling](../10-scheduling/README.md): cron and timers depend on the clock and timezone
- [journalctl](../09-logging/journalctl.md): `--utc` and time ranges
- [SSL and TLS Certificates](../../networking/ssl-tls-certificates-guide.md): certificate validity

Captured on Rocky Linux 10.2 (chrony 4.8) and Ubuntu 24.04.4 (OpenSSL 3.0.13, chrony) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09. Public NTP server addresses are replaced with documentation addresses.
