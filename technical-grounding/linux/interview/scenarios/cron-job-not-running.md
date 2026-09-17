# Cron Job Not Running

A scheduled job produces nothing, although its script works when run by hand. The interviewer checks whether the candidate separates "cron did not start it" from "cron started it and it failed", and knows how the cron environment differs from a login shell.

---

## Symptom

> "We moved the nightly sales report to a new server. The script works when I run it, but no report files appear. What do you check?"

---

## Clarifying Questions

- **How was it scheduled?** A user crontab, `/etc/cron.d`, a `cron.daily` script or a systemd timer each fail differently.
- **How was it tested by hand?** From which directory, as which user, and with which shell?
- **Which distribution?** RHEL logs job output in `/var/log/cron`; Ubuntu discards it without a mail server.
- **Is there any trace of a run?** No trace points to the scheduler; a trace with errors points to the script.
- **Did anything else change?** Time zone, user, paths, permissions and installed tools all move with a server migration.

---

## Diagnostic Path

The job belongs to the user `reports` on Rocky Linux 10.2. `/opt/reports/run.sh` reads a config file next to it and calls `report-gen` from `/usr/local/bin`:

```bash
#!/bin/bash
# nightly sales report
source ./report.conf
report-gen > "$REPORT_DIR/sales-$(date +%F).csv"
```

As the owner runs it, from the script's directory, it works:

```bash
su - reports -c "cd /opt/reports && bash run.sh; cat /srv/reports/*"
```

Output:

```text
orders,2026-09-17,42
```

### 1. Check the Scheduler

```bash
rm -f /srv/reports/*; systemctl is-active crond; systemctl is-enabled crond
crontab -l -u reports; ls -l /var/spool/cron/
grep reports /var/log/cron | tail -3
```

Output:

```text
inactive
enabled
*/1 * * * * /opt/reports/run.sh
total 4
-rw------- 1 root root 32 Sep 17 06:25 reports
Sep 17 06:25:29 rocky-01 crontab[2987]: (root) REPLACE (reports)
```

The job is installed, but `crond` is not running, so nothing ran: the log shows only the crontab install. Enabled but inactive means it was stopped after boot, or it failed.

```bash
systemctl start crond; systemctl status crond --no-pager | sed -n "1,3p"
```

Output:

```text
● crond.service - Command Scheduler
     Loaded: loaded (/usr/lib/systemd/system/crond.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-09-17 06:25:47 UTC; 25ms ago
```

The test runs every minute (`*/1`) so each fix shows up quickly; the real schedule is nightly.

### 2. Read What the Run Printed

cronie on a host without `sendmail` logs each output line as `CMDOUT`.

```bash
grep reports /var/log/cron | tail -3; ls -l /opt/reports/run.sh
```

Output:

```text
Sep 17 06:26:01 rocky-01 CROND[3218]: (reports) CMD (/opt/reports/run.sh)
Sep 17 06:26:01 rocky-01 CROND[3202]: (reports) CMDOUT (/bin/sh: line 1: /opt/reports/run.sh: Permission denied)
Sep 17 06:26:01 rocky-01 CROND[3202]: (reports) CMDEND (/opt/reports/run.sh)
-rw-r--r-- 1 root root 105 Sep 17 06:25 /opt/reports/run.sh
```

The manual test used `bash run.sh`, which needs only read permission; cron executes the file, which needs the execute bit.

### 3. Reproduce the Cron Environment

Waiting a minute per attempt is slow. Running the script as the job's user, from its home directory, with an empty environment and cron's `PATH`, reproduces the conditions at once. As root:

```bash
chmod 755 /opt/reports/run.sh
cd /home/reports && su reports -s /bin/sh -c 'env -i HOME=/home/reports LOGNAME=reports SHELL=/bin/sh PATH=/usr/bin:/bin /opt/reports/run.sh'; echo rc=$?
```

Output:

```text
/opt/reports/run.sh: line 3: ./report.conf: No such file or directory
/opt/reports/run.sh: line 4: /sales-2026-09-17.csv: Permission denied
rc=1
```

The next cron run logged the same two lines:

```bash
grep reports /var/log/cron | tail -4
```

Output:

```text
Sep 17 06:27:01 rocky-01 CROND[3428]: (reports) CMD (/opt/reports/run.sh)
Sep 17 06:27:01 rocky-01 CROND[3410]: (reports) CMDOUT (/opt/reports/run.sh: line 3: ./report.conf: No such file or directory)
Sep 17 06:27:01 rocky-01 CROND[3410]: (reports) CMDOUT (/opt/reports/run.sh: line 4: /sales-2026-09-17.csv: Permission denied)
Sep 17 06:27:01 rocky-01 CROND[3410]: (reports) CMDEND (/opt/reports/run.sh)
```

| Line | Cause |
|---|---|
| `./report.conf: No such file or directory` | cron starts in the user's home directory, not in `/opt/reports` |
| `/sales-2026-09-17.csv: Permission denied` | `REPORT_DIR` was never set, so the path became `/sales-...`; by hand it also came from `.bash_profile`, which cron does not read |

### 4. Fix and Confirm

```bash
sed -i 's|^source ./report.conf|source /opt/reports/report.conf|' /opt/reports/run.sh
printf 'PATH=/usr/local/bin:/usr/bin:/bin\n*/1 * * * * /opt/reports/run.sh >> /var/tmp/reports-cron.log 2>&1\n' > /tmp/reports.cron; crontab -u reports /tmp/reports.cron; crontab -l -u reports
cd /home/reports && su reports -s /bin/sh -c 'env -i HOME=/home/reports LOGNAME=reports SHELL=/bin/sh PATH=/usr/bin:/bin /opt/reports/run.sh'; echo rc=$?
touch /var/tmp/reports-cron.log; chown reports: /var/tmp/reports-cron.log
rm -f /srv/reports/*; sleep 50; grep reports /var/log/cron | tail -2; ls -l /srv/reports; cat /srv/reports/*; cat /var/tmp/reports-cron.log
```

Output:

```text
Backup of reports's previous crontab saved to /root/.cache/crontab/crontab.reports.bak
PATH=/usr/local/bin:/usr/bin:/bin
*/1 * * * * /opt/reports/run.sh >> /var/tmp/reports-cron.log 2>&1
/opt/reports/run.sh: line 4: report-gen: command not found
rc=127
Sep 17 06:28:01 rocky-01 CROND[3556]: (reports) CMD (/opt/reports/run.sh >> /var/tmp/reports-cron.log 2>&1)
Sep 17 06:28:01 rocky-01 CROND[3540]: (reports) CMDEND (/opt/reports/run.sh >> /var/tmp/reports-cron.log 2>&1)
total 4
-rw-r--r-- 1 reports reports 21 Sep 17 06:28 sales-2026-09-17.csv
orders,2026-09-17,42
```

With the config path fixed, the manual test exposed the third problem: `report-gen` lives in `/usr/local/bin`, outside cron's `PATH`. The `PATH=` line in the crontab fixes it for the real run, which produced the report and left the log file empty.

### 5. Know the Ubuntu Differences

On Ubuntu 24.04, cron discards output when no mail server exists, and a `cron.d` file without a user field is rejected when cron loads it. As root:

```bash
echo '* * * * * echo noisy output' > /etc/cron.d/nouser; echo '* * * * * laborant echo noisy output' > /etc/cron.d/noisy; date; sleep 58; journalctl -u cron --since -70s -o cat --no-pager | grep -v pam_unix
```

Output:

```text
Thu Sep 17 06:01:54 UTC 2026
Error: bad username; while reading /etc/cron.d/nouser
(*system*nouser) ERROR (Syntax error, this crontab file will be ignored)
(laborant) CMD (echo noisy output)
(CRON) info (No MTA installed, discarding output)
```

Debian's `run-parts` and cron also skip any file in `cron.daily` or `cron.d` whose name contains a dot, without a log line; see [cron and at](../../10-scheduling/cron-and-at.md).

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Daemon not running | `systemctl is-active crond` (or `cron`) is `inactive`; no `CMD` lines | `systemctl enable --now crond` |
| Job not installed where expected | `crontab -l -u <user>` empty; job in another user's crontab | Install it for the right user |
| Syntax error | `bad minute` on install; `bad command` or `bad username` for `cron.d` | Correct the line; add the user field in `cron.d` |
| Ignored file | Dot in the name on Debian; not executable in `cron.daily` | Rename; `chmod +x`; `run-parts --test` |
| Not executable | `CMDOUT (... Permission denied)` | `chmod 755`, or call the interpreter explicitly |
| Relative paths | `No such file or directory` for `./file` | Absolute paths, or `cd "$(dirname "$0")"` |
| Missing variables | Empty values from `.bashrc` or `.bash_profile` | Set them in the script, the crontab or an env file |
| `PATH` | `command not found`, exit 127 | Full paths, or `PATH=` in the crontab |
| `%` in the command | `unexpected EOF while looking for matching` | `\%` |
| Access denied | `You (user) are not allowed to use this program (crontab)` | `cron.allow` / `cron.deny` |
| Output lost | Nothing in logs on Ubuntu | Redirect to a file inside the job |
| Wrong time | Server time zone differs from the expected one | `timedatectl`; `CRON_TZ=` or convert the schedule |

---

## Fix

Correct the proven causes only: here the daemon, the execute bit, the config path and `PATH`. Confirm with the next run's log and the output file, not with another manual run.

---

## Prevention

- Write cron scripts as if the environment were empty: absolute paths, `set -euo pipefail`, variables defined in the script.
- Redirect every job's output to a log file, or use a systemd timer so output lands in the journal.
- Test with `env -i` as the job's user before scheduling.
- Monitor the job's result with a heartbeat or a file age check; a running daemon proves nothing about the job.
- Keep job names in `/etc/cron.d` and `cron.daily` free of dots.

---

## Related

- [cron and at](../../10-scheduling/cron-and-at.md): syntax, environment and `run-parts`
- [Systemd Timers](../../10-scheduling/systemd-timers.md): the alternative with journal logging
- [Exit Codes and Chaining](../../01-shell-and-cli/exit-codes-and-chaining.md): 126, 127 and friends
- [Variables and Environment](../../01-shell-and-cli/variables-and-environment.md): login vs non-login shells
- [Log Locations](../../09-logging/log-locations.md): where cron logs on each family

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
