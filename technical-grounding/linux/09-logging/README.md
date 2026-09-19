# Logging

Where Linux keeps its logs, how to query the journal, how rsyslog and logrotate manage text files, and how to turn raw log lines into answers.

---

## Revision Card

| Fact | Value |
|---|---|
| Two paths | journald (binary, indexed) and rsyslog (text files) |
| General log | RHEL `/var/log/messages`, Ubuntu `/var/log/syslog` |
| Auth log | RHEL `/var/log/secure`, Ubuntu `/var/log/auth.log` |
| Cron log | RHEL `/var/log/cron`, Ubuntu `syslog` |
| Journal persistence | Only if `/var/log/journal` exists (`Storage=auto`) |
| Journal access | Groups `adm`, `systemd-journal`, `wheel` |
| `-k` | Kernel messages of the current boot only, unless `-b` is given |
| Journal limit | `SystemMaxUse=`, default 10% of the filesystem, at most 4G |
| Flooding | journald drops lines and logs "Suppressed N messages" |
| rsyslog rule | `facility.priority action`; `& stop` ends processing |
| Forwarding | `@host` UDP, `@@host` TCP |
| logrotate schedule | `logrotate.timer`, daily; the state file decides what is due |
| `create` vs `copytruncate` | Reopen needed vs in-place truncation with possible loss |
| Snippet-only run | `logrotate -f /etc/logrotate.d/app` ignores `logrotate.conf` globals |
| Insecure directory | logrotate skips it until `su user group` is set |

| Task | Command |
|---|---|
| One service, this boot | `journalctl -u nginx -b` |
| Follow | `journalctl -fu nginx` |
| Errors since boot | `journalctl -p err -b` |
| Previous boot | `journalctl --list-boots`, `journalctl -b -1 -n 50` |
| Time window | `journalctl --since "1 hour ago" --until "10 min ago"` |
| Make persistent | `sudo mkdir -p /var/log/journal`, `sudo systemd-tmpfiles --create --prefix /var/log/journal`, `sudo journalctl --flush` |
| Shrink | `sudo journalctl --vacuum-size=500M` |
| Test a syslog rule | `logger -p local3.err -t app "test"` |
| Check rsyslog config | `sudo rsyslogd -N1` |
| Test logrotate | `sudo logrotate -d /etc/logrotate.conf` |
| Top client IPs | `awk '{print $1}' access.log`, `sort`, `uniq -c`, `sort -rn`, `head` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Log Locations](log-locations.md) | The logging pipeline, `/var/log` on each family, permissions, binary login records | Core | High |
| [journalctl](journalctl.md) | Filters, fields, output modes, boots, persistence, size limits, rate limiting | Core | High |
| [rsyslog](rsyslog.md) | Rules, validation, central logging | Core | Low |
| [logrotate](logrotate.md) | Defaults, `create` vs `copytruncate`, dry runs, state file | Core | Med |
| [Log Parsing Recipes](log-parsing-recipes.md) | nginx access and error logs, SSH failures, time windows, live filtering | Core | High |

---

## Scenarios and Labs

- [Service Won't Start](../interview/scenarios/service-wont-start.md): reading the journal for a failed unit
- [Cron Job Not Running](../interview/scenarios/cron-job-not-running.md): finding cron's output in the logs
