# cron and at

`cron` runs commands on a repeating schedule and `at` runs a command once at a given time. Jobs that work in a terminal and fail under cron are a standard interview question, because cron runs them with a different environment, a different shell and no terminal.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Field order | minute, hour, day of month, month, day of week, command | `cat /etc/crontab` |
| Ranges and steps | `1-5`, `1,15`, `*/10`; day of week 0 and 7 are Sunday | `man 5 crontab` |
| Day fields | If both day of month and day of week are set, either match runs the job | `man 5 crontab` |
| Shortcuts | `@reboot`, `@hourly`, `@daily`, `@weekly`, `@monthly`, `@yearly` | `man 5 crontab` |
| User crontabs | `crontab -e`, `-l`, `-r`, `-u user`; stored in `/var/spool/cron/` (RHEL) or `/var/spool/cron/crontabs/` (Ubuntu) | `sudo ls /var/spool/cron` |
| System crontabs | `/etc/crontab` and `/etc/cron.d/*` have a user field after the schedule | `cat /etc/cron.d/0hourly` |
| Periodic directories | `/etc/cron.hourly`, `daily`, `weekly`, `monthly`, run by `run-parts` | `ls /etc/cron.daily` |
| anacron | Runs daily, weekly and monthly jobs missed while the host was off | `cat /etc/anacrontab` |
| Environment | `SHELL=/bin/sh`, minimal `PATH`, `HOME` of the user, no profile files | `* * * * * env > /tmp/cron-env.txt` |
| `%` | Means newline in a crontab command; write `\%` | `date +\%F` |
| Output | Mailed to `MAILTO` (default the owner); without an MTA it is logged or discarded | `journalctl -u crond` |
| Access | `cron.allow` wins if present, otherwise `cron.deny`; same model for `at.allow` and `at.deny` | `ls /etc/cron.*` |
| Daemon | `crond` (cronie) on RHEL, `cron` on Ubuntu; reloads crontabs automatically | `systemctl status crond` |
| Logs | RHEL `/var/log/cron`; Ubuntu `syslog`, both in the journal | `journalctl -u cron` |
| `at` / `batch` | One-off job at a time / when load is low; `atq`, `atrm`, `at -c` | `atq` |
<!-- --8<-- [end:facts] -->

---

## Crontab Syntax

Each line is five time fields and a command; `*` means every value.

| Schedule | Meaning |
|---|---|
| `*/15 * * * *` | Every 15 minutes |
| `0 9-17 * * 1-5` | On the hour, 09:00 to 17:00, Monday to Friday |
| `30 2 1 * *` | 02:30 on the first of each month |
| `0 0 1,15 * 5` | Midnight on the 1st, the 15th **and** every Friday |
| `@reboot` | Once when `cron` starts |

`crontab` refuses an invalid schedule when it installs the file:

```bash
printf "61 * * * * /opt/jobs/nightly.sh\n" > /tmp/bad.cron; su - laborant -c "crontab /tmp/bad.cron"; echo "rc=$?"
```

Output:

```text
"/tmp/bad.cron":1: bad minute
Invalid crontab file, can't install.
rc=1
```

---

## User and System Crontabs

A user crontab has no user field; files in `/etc/cron.d/` and `/etc/crontab` need one. A `cron.d` file without it fails at load time, not when it is written.

=== "RHEL / Rocky"

    ```bash
    grep -v "^#" /etc/crontab | grep .; cat /etc/cron.d/0hourly | grep -v "^#"; grep -v "^#" /etc/anacrontab | grep .
    ```

    Output:

    ```text
    SHELL=/bin/bash
    PATH=/sbin:/bin:/usr/sbin:/usr/bin
    MAILTO=root
    SHELL=/bin/bash
    PATH=/sbin:/bin:/usr/sbin:/usr/bin
    MAILTO=root
    01 * * * * root run-parts /etc/cron.hourly
    SHELL=/bin/sh
    PATH=/sbin:/bin:/usr/sbin:/usr/bin
    MAILTO=root
    RANDOM_DELAY=45
    START_HOURS_RANGE=3-22
    1	5	cron.daily		nice run-parts /etc/cron.daily
    7	25	cron.weekly		nice run-parts /etc/cron.weekly
    @monthly 45	cron.monthly		nice run-parts /etc/cron.monthly
    ```

    `/etc/crontab` holds only variables and comments on RHEL. `0hourly` runs `cron.hourly`, whose `0anacron` script starts anacron, and anacron runs the daily, weekly and monthly directories between 03:00 and 22:00 with a random delay.

=== "Ubuntu / Debian"

    ```bash
    grep -v "^#" /etc/crontab | grep .
    ```

    Output:

    ```text
    SHELL=/bin/sh
    17 *	* * *	root	cd / && run-parts --report /etc/cron.hourly
    25 6	* * *	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
    47 6	* * 7	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.weekly; }
    52 6	1 * *	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.monthly; }
    ```

    `/etc/crontab` runs the periodic directories only when anacron is absent; on this host `anacron.timer` runs them.

---

## The Cron Environment

The job below records the environment cron gives a user job on Rocky. Compared with a login shell, `PATH` lacks `/usr/local/bin`, and no profile or `.bashrc` is read.

```bash
su - laborant -c 'crontab /tmp/lab.cron; crontab -l'
cat /tmp/cron-env.txt
```

Output:

```text
* * * * * env > /tmp/cron-env.txt
* * * * * /opt/jobs/nightly.sh
* * * * * echo "run $(date +%F)" >> /tmp/cron-date.txt
* * * * * /opt/jobs/crlf.sh
SHELL=/bin/sh
PWD=/home/laborant
LOGNAME=laborant
# ... (trimmed: XDG_* session variables)
HOME=/home/laborant
LANG=C.UTF-8
USER=laborant
SHLVL=1
PATH=/usr/bin:/bin:/usr/sbin:/sbin
# ... (trimmed: DBUS_SESSION_BUS_ADDRESS)
_=/usr/bin/env
```

The other three jobs each contain a classic mistake. cronie on a host without `sendmail` logs each job's output instead of mailing it, which makes the failures visible:

```bash
cat /var/log/cron
```

Output:

```text
# ... (trimmed: six lines of crond startup and the crontab install)
Sep 17 05:47:01 rocky-01 crond[930]: (CRON) bad command (/etc/cron.d/report)
Sep 17 05:47:01 rocky-01 CROND[2005]: (laborant) CMD (env > /tmp/cron-env.txt)
Sep 17 05:47:01 rocky-01 CROND[2006]: (laborant) CMD (echo "run $(date +)
Sep 17 05:47:01 rocky-01 CROND[2009]: (laborant) CMD (/opt/jobs/nightly.sh)
Sep 17 05:47:01 rocky-01 CROND[2010]: (laborant) CMD (/opt/jobs/crlf.sh)
Sep 17 05:47:01 rocky-01 CROND[1980]: (laborant) CMDOUT (/bin/sh: line 1: /opt/jobs/crlf.sh: cannot execute: required file not found)
Sep 17 05:47:01 rocky-01 CROND[1981]: (laborant) CMDOUT (/bin/sh: -c: line 2: unexpected EOF while looking for matching `)')
Sep 17 05:47:01 rocky-01 CROND[1981]: (laborant) CMDEND (echo "run $(date +)
Sep 17 05:47:01 rocky-01 CROND[1980]: (laborant) CMDEND (/opt/jobs/crlf.sh)
Sep 17 05:47:01 rocky-01 CROND[1982]: (laborant) CMDOUT (/opt/jobs/nightly.sh: line 2: db-backup: command not found)
Sep 17 05:47:01 rocky-01 CROND[1983]: (laborant) CMDEND (env > /tmp/cron-env.txt)
Sep 17 05:47:01 rocky-01 CROND[1982]: (laborant) CMDEND (/opt/jobs/nightly.sh)
```

| Log line | Cause | Fix |
|---|---|---|
| `db-backup: command not found` | `db-backup` is in `/usr/local/bin`, not in cron's `PATH` | Full paths in scripts, or `PATH=` at the top of the crontab |
| `(echo "run $(date +)` and `unexpected EOF` | `%` ended the command; the rest became standard input | `date +\%F` |
| `cannot execute: required file not found` | The script has CRLF line endings, so the interpreter is `/bin/bash\r` | `sed -i 's/\r$//' script` |
| `bad command (/etc/cron.d/report)` | The `cron.d` file has no user field | `* * * * * root /opt/jobs/nightly.sh` |

After the fixes (a `PATH` line, `\%`, and `sed -i 's/\r$//' /opt/jobs/crlf.sh`), the next run succeeded:

```bash
su - laborant -c "crontab /tmp/lab.cron; crontab -l"
head -1 /tmp/nightly.log /tmp/cron-date.txt /tmp/crlf.log
```

Output:

```text
Backup of laborant's previous crontab saved to /home/laborant/.cache/crontab/crontab.bak
PATH=/usr/local/bin:/usr/bin:/bin
* * * * * /opt/jobs/nightly.sh
* * * * * echo "run $(date +\%F)" >> /tmp/cron-date.txt
* * * * * /opt/jobs/crlf.sh
==> /tmp/nightly.log <==
backup ok 05:48:01

==> /tmp/cron-date.txt <==
run 2026-09-17

==> /tmp/crlf.log <==
crlf ran
```

cron mails a job's output to `MAILTO`. Without a mail transfer agent, cronie logs the output (as above) and Debian's cron discards it with the log line `(CRON) info (No MTA installed, discarding output)`, captured in [Cron Job Not Running](../interview/scenarios/cron-job-not-running.md). Redirecting inside the job (`>> /var/log/app/job.log 2>&1`) keeps the output regardless of mail.

!!! warning "Fixing the user crontab does not fix /etc/cron.d"
    The corrected `/etc/cron.d/report` (with `root`) still failed with `db-backup: command not found`, because a system crontab gets the same minimal `PATH` unless it sets its own.

On Ubuntu, the equivalent job in `/etc/cron.d/envjob` (shown in the next section) reports a longer `PATH`:

```bash
grep PATH /tmp/cron-env2.txt
cat /etc/environment; grep -v '^#' /etc/pam.d/cron | grep .
```

Output:

```text
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
@include common-auth
session    required     pam_loginuid.so
session       required   pam_env.so
session       required   pam_env.so envfile=/etc/default/locale
@include common-account
@include common-session-noninteractive 
session    required   pam_limits.so
```

Ubuntu's cron runs `pam_env`, which loads `PATH` from `/etc/environment`, so `/usr/local/bin` is found. A script that works under cron on Ubuntu can still fail on RHEL.

---

## Periodic Directories and run-parts

Scripts in `/etc/cron.daily` and the other directories must be executable. Debian's `run-parts` also ignores any name that contains a dot, which silently skips `report.sh`; RHEL's `run-parts` runs it.

=== "RHEL / Rocky"

    ```bash
    ls -l /etc/cron.daily; run-parts /etc/cron.daily
    ```

    Output:

    ```text
    total 8
    -rw-r--r-- 1 root root 27 Sep 17 05:47 cleanup
    -rwxr-xr-x 1 root root 28 Sep 17 05:47 report.sh
    /etc/cron.daily/report.sh:

    report ran
    ```

    `cleanup` is not executable, so it is skipped without a message.

=== "Ubuntu / Debian"

    ```bash
    run-parts --test /etc/cron.daily
    echo "* * * * * laborant env > /tmp/cron-env.txt" > /etc/cron.d/env.job; echo "* * * * * laborant env > /tmp/cron-env2.txt" > /etc/cron.d/envjob; ls /etc/cron.d
    grep CRON /var/log/syslog | tail -5
    ```

    Output:

    ```text
    /etc/cron.daily/0anacron
    /etc/cron.daily/apt-compat
    /etc/cron.daily/cleanup
    /etc/cron.daily/debsums
    /etc/cron.daily/dpkg
    /etc/cron.daily/logrotate
    /etc/cron.daily/man-db
    /etc/cron.daily/plocate
    /etc/cron.daily/sysstat
    anacron
    e2scrub_all
    env.job
    envjob
    sysstat
    2026-09-17T05:45:01.560287+00:00 ubuntu-01 CRON[1812]: (root) CMD (command -v debian-sa1 > /dev/null && debian-sa1 1 1)
    2026-09-17T05:48:01.565785+00:00 ubuntu-01 CRON[2077]: (laborant) CMD (env > /tmp/cron-env2.txt)
    2026-09-17T05:49:01.571479+00:00 ubuntu-01 CRON[2191]: (laborant) CMD (env > /tmp/cron-env2.txt)
    ```

    Both `report.sh` and `cleanup` were executable; only `cleanup` is listed. The same rule applies to `/etc/cron.d`: `env.job` never ran, `envjob` ran every minute.

!!! danger "A dot in the file name disables the job on Debian and Ubuntu"
    `backup.sh` in `/etc/cron.daily` or `backup.cron` in `/etc/cron.d` is ignored without any log line. Name files with letters, digits, hyphens and underscores only.

---

## Access Control

```bash
echo bob >> /etc/cron.deny; su - bob -c "crontab -l"
```

Output:

```text
You (bob) are not allowed to use this program (crontab)
See crontab(1) for more information
```

If `/etc/cron.allow` exists, only the users listed in it may use `crontab`, and `cron.deny` is ignored.

---

## One-Off Jobs with at

`at` reads commands from standard input and runs them once with `/bin/sh`; `batch` runs them when the load average is below the threshold set by `atd -l`. `atd` must be running. As root, with `bob` already listed in `/etc/at.deny`:

```bash
{ echo 'echo at-job ran > /tmp/at2.txt' | at now + 2 minutes; atq; } 2>&1
echo "uptime > /tmp/batch2.txt" | batch 2>&1
su - bob -c 'echo "date > /tmp/bob-at.txt" | at now' 2>&1
```

Output:

```text
warning: commands will be executed using /bin/sh
job 4 at Thu Sep 17 06:15:00 2026
4	Thu Sep 17 06:15:00 2026 a root
warning: commands will be executed using /bin/sh
job 5 at Thu Sep 17 06:13:00 2026
You do not have permission to use at.
```

`now + 2 minutes` rounds down to the start of the minute. `at -c <job>` prints the whole job script, including the environment saved from the submitting shell, which is why `at` jobs do not have cron's `PATH` problem. An earlier `at` job by `bob` ran, and its output could not be mailed: `atd` logged `Exec failed for mail command: No such file or directory`.

---

## Common Errors

### ``/bin/sh: -c: line 2: unexpected EOF while looking for matching `)'``

**Cause:** An unescaped `%` split the command.

**Fix:** Escape it as `\%`, or move the command into a script.

### `(CRON) bad command (/etc/cron.d/report)`

**Cause:** A system crontab line is missing the user field.

**Fix:** Add the user between the schedule and the command.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Write a crontab line that runs a backup at 02:30 on weekdays."
    **Say first:** `30 2 * * 1-5 /usr/local/bin/db-backup`.

    **Proof:** `crontab -l` after installing it; `journalctl -u crond` the next morning.

    **Follow-up:** What changes in `/etc/cron.d`? (A user field after the schedule.)

??? question "L1: Why does a script that works in the terminal fail under cron?"
    **Say first:** cron runs it with `/bin/sh`, a minimal `PATH`, no profile files, no terminal and a different working directory.

    **Proof:** `* * * * * env > /tmp/cron-env.txt`, then compare with `env` in the shell.

    **Follow-up:** Which character in a crontab line has a special meaning? (`%`.)

??? question "L1: What is the difference between cron and anacron?"
    **Say first:** cron runs at exact times and skips runs while the host is off; anacron runs daily, weekly and monthly jobs that were missed, once per period.

    **Proof:** `cat /etc/anacrontab`; `ls /var/spool/anacron`.

    **Follow-up:** Which one would you use on a laptop?
<!-- --8<-- [end:l1] -->

??? question "L2: Run a command once at 23:00 tonight and confirm it is queued."
    **Say first:** Use `at`.

    **Proof:** `echo "/usr/local/bin/db-backup" | at 23:00`; `atq`; `at -c <job>`.

    **Follow-up:** How do you cancel it? (`atrm <job>`.)

??? question "L3: A script in /etc/cron.daily on Ubuntu never runs, and there is no error. What do you check?"
    **Say first:** The file name and the execute bit, because `run-parts` skips both silently.

    **Proof:** `run-parts --test /etc/cron.daily` does not list it; `ls -l` shows the name or mode.

    **Follow-up:** How do you confirm anacron itself ran? (`journalctl -u anacron`.)

??? question "L3: A cron job runs (it appears in the log) but its work is not done. How do you find out why?"
    **Say first:** Get the job's output: from the log on RHEL, the mailbox, or a redirect added to the job.

    **Proof:** `grep CMDOUT /var/log/cron`; add `>> /tmp/job.log 2>&1`; `bash -x` the script with `env -i PATH=/usr/bin:/bin`.

    **Follow-up:** What does `env -i` simulate?

---

## Related

- [Systemd Timers](systemd-timers.md): the systemd alternative
- [Cron Job Not Running](../interview/scenarios/cron-job-not-running.md): the same failures as an interview drill
- [Variables and Environment](../01-shell-and-cli/variables-and-environment.md) and [Quoting and Expansion](../01-shell-and-cli/quoting-and-expansion.md): `PATH`, profile files and quoting

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
