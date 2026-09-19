# Systemd Timers

A systemd timer is a `.timer` unit that starts a matching `.service` unit on a calendar or after an interval. Timers replace most cron jobs on current distributions because each run gets the journal, resource limits, dependencies and a recorded last-run time.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Pairing | `name.timer` starts `name.service` unless `Unit=` says otherwise | `systemctl cat name.timer` |
| Calendar | `OnCalendar=Mon..Fri *-*-* 09:00:00`; shortcuts `hourly`, `daily`, `weekly` | `systemd-analyze calendar "..."` |
| Monotonic | `OnBootSec=`, `OnUnitActiveSec=`, `OnActiveSec=` (relative to boot, last run, timer start) | `man systemd.timer` |
| Missed runs | `Persistent=true` runs a missed calendar job at the next boot | `ls /var/lib/systemd/timers` |
| Spread load | `RandomizedDelaySec=` adds a random delay | `systemctl list-timers` |
| Precision | `AccuracySec=` (default 1 minute) lets systemd batch wake-ups | `systemctl show -p AccuracyUSec x.timer` |
| Enable | Enable and start the **timer**, not the service | `systemctl enable --now name.timer` |
| Service type | Usually `Type=oneshot`; no `[Install]` needed in the service | `systemctl status name.service` |
| Run now | `systemctl start name.service` | `journalctl -u name` |
| List | `systemctl list-timers --all` shows next and last run | `systemctl list-timers` |
| One-off | `systemd-run --on-active=30s` or `--on-calendar=` creates a transient timer | `systemd-run --on-active=1m /bin/true` |
| User timers | `~/.config/systemd/user/`, `systemctl --user`, lingering for no-login runs | `loginctl show-user $USER -p Linger` |
<!-- --8<-- [end:facts] -->

---

## A Timer and Its Service

The service describes the work and the timer describes when. Both files live in `/etc/systemd/system/`.

```ini
# /etc/systemd/system/db-dump.service
[Unit]
Description=Dump the application database

[Service]
Type=oneshot
ExecStart=/usr/local/bin/db-dump
```

```ini
# /etc/systemd/system/db-dump.timer
[Unit]
Description=Dump the database every night

[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
```

As root:

```bash
systemd-analyze verify /etc/systemd/system/db-dump.timer /etc/systemd/system/db-dump.service; echo rc=$?
systemctl daemon-reload; systemctl enable --now db-dump.timer
systemctl list-timers db-dump.timer --no-pager
```

Output:

```text
rc=0
Created symlink '/etc/systemd/system/timers.target.wants/db-dump.timer' → '/etc/systemd/system/db-dump.timer'.
NEXT                        LEFT LAST PASSED UNIT          ACTIVATES
Fri 2026-09-18 02:37:55 UTC  20h -         - db-dump.timer db-dump.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
```

`RandomizedDelaySec=10min` places the trigger between 02:30 and 02:40; this listing shows 02:37:55 and the status below shows 02:31:11.

### Running and checking the job

```bash
systemctl start db-dump.service; systemctl status db-dump.service --no-pager | sed -n "1,4p"; journalctl -u db-dump -o cat --no-pager | tail -4
systemctl status db-dump.timer --no-pager | sed -n "1,5p"
ls /var/lib/systemd/timers/
```

Output:

```text
○ db-dump.service - Dump the application database
     Loaded: loaded (/etc/systemd/system/db-dump.service; static)
     Active: inactive (dead) since Thu 2026-09-17 05:57:18 UTC; 8ms ago
 Invocation: 0623f3b3c8a64e58952bf712fdb4bbca
Starting db-dump.service - Dump the application database...
wrote /var/backups/db-2026-09-17-0557.sql
db-dump.service: Deactivated successfully.
Finished db-dump.service - Dump the application database.
● db-dump.timer - Dump the database every night
     Loaded: loaded (/etc/systemd/system/db-dump.timer; enabled; preset: disabled)
     Active: active (waiting) since Thu 2026-09-17 05:57:18 UTC; 68ms ago
 Invocation: 502b69d8920d43bc9734e73cd5dc61e8
    Trigger: Fri 2026-09-18 02:31:11 UTC; 20h left
stamp-db-dump.timer
stamp-fstrim.timer
stamp-logrotate.timer
stamp-plocate-updatedb.timer
```

A `oneshot` service is `inactive (dead)` after a successful run, which is its normal state. The service is `static` because the timer, not `[Install]`, pulls it in.

!!! note "Stamp files make Persistent= work"
    Each persistent timer keeps its last trigger time in `/var/lib/systemd/timers/stamp-<name>`. `systemctl clean --what=state <name>.timer` removes it.

---

## Calendar Expressions

`systemd-analyze calendar` normalizes an expression and prints the next run times, which catches mistakes before the timer is enabled.

```bash
systemd-analyze calendar "*-*-* 02:30:00" "Mon..Fri 09:00" "*:0/15" hourly "Sat,Sun *-*-1..7 04:00" --iterations=2
```

Output:

```text
Normalized form: *-*-* 02:30:00
    Next elapse: Fri 2026-09-18 02:30:00 UTC
       From now: 20h left
   Iteration #2: Sat 2026-09-19 02:30:00 UTC
       From now: 1 day 20h left

  Original form: Mon..Fri 09:00
Normalized form: Mon..Fri *-*-* 09:00:00
    Next elapse: Thu 2026-09-17 09:00:00 UTC
       From now: 3h 2min left
   Iteration #2: Fri 2026-09-18 09:00:00 UTC
       From now: 1 day 3h left

  Original form: *:0/15
Normalized form: *-*-* *:00/15:00
    Next elapse: Thu 2026-09-17 06:00:00 UTC
       From now: 2min 41s left
   Iteration #2: Thu 2026-09-17 06:15:00 UTC
       From now: 17min left

  Original form: hourly
Normalized form: *-*-* *:00:00
    Next elapse: Thu 2026-09-17 06:00:00 UTC
       From now: 2min 41s left
   Iteration #2: Thu 2026-09-17 07:00:00 UTC
       From now: 1h 2min left

  Original form: Sat,Sun *-*-1..7 04:00
Normalized form: Sat,Sun *-*-01..07 04:00:00
    Next elapse: Sat 2026-10-03 04:00:00 UTC
       From now: 2 weeks 1 day left
   Iteration #2: Sun 2026-10-04 04:00:00 UTC
       From now: 2 weeks 2 days left
```

| cron | `OnCalendar=` |
|---|---|
| `30 2 * * *` | `*-*-* 02:30:00` |
| `*/15 * * * *` | `*:0/15` |
| `0 9 * * 1-5` | `Mon..Fri 09:00` |
| `0 4 1-7 * 6,0` | `Sat,Sun *-*-1..7 04:00` (weekend day in the first week; cron would run on every day 1 to 7 **or** every weekend) |

!!! tip "systemd ANDs the day fields where cron ORs them"
    In cron, a line with both day of month and day of week runs when either matches. In `OnCalendar=`, both must match, which is what "first Saturday or Sunday of the month" needs.

---

## Transient Timers

`systemd-run` creates a timer and service without writing files, which suits one-off or test schedules.

```bash
systemd-run --on-active=30s --unit=cache-warm /usr/bin/true; systemctl list-timers cache-warm.timer --no-pager | sed -n "1,2p"
systemd-run --on-calendar="*:*:0/20" --unit=probe /usr/bin/curl -s -o /dev/null localhost; sleep 21; journalctl -u probe -o cat --no-pager | tail -2; systemctl stop probe.timer
```

Output:

```text
Running timer as unit: cache-warm.timer
Will run service as unit: cache-warm.service
NEXT                        LEFT LAST PASSED UNIT             ACTIVATES
Thu 2026-09-17 05:57:48 UTC  29s -         - cache-warm.timer cache-warm.service
Running timer as unit: probe.timer
Will run service as unit: probe.service
Started probe.service - [systemd-run] /usr/bin/curl -s -o /dev/null localhost.
probe.service: Deactivated successfully.
```

---

## Timers vs cron

| | cron | systemd timer |
|---|---|---|
| **Files** | One line | Two units |
| **Logs** | Mail or syslog lines | Full output in `journalctl -u` |
| **Missed runs** | anacron, daily granularity | `Persistent=true`, any schedule |
| **Environment** | Minimal, differs by distribution | Defined by the unit (`Environment=`, `User=`) |
| **Overlap** | Two runs can overlap | A running service is not started again |
| **Limits and sandboxing** | None | `MemoryMax=`, `CPUQuota=`, `ProtectSystem=` |
| **Dependencies** | None | `After=`, `Requires=` (for example `network-online.target`) |
| **Last result** | Not recorded | `systemctl status`, `list-timers` `LAST` column |
| **Seconds precision** | Minutes only | Seconds (with `AccuracySec=`) |

---

## Common Errors

### `Failed to start broken.timer: Unit broken.timer has a bad unit file setting.`

**Cause:** The `[Timer]` section has no trigger; the journal says `Timer unit lacks value setting. Refusing.`

**Fix:** Add `OnCalendar=` or an `On*Sec=` setting.

### `orphan.timer: Refusing to start, unit orphan.service to trigger not loaded.`

**Cause:** No service with the timer's name exists, and `Unit=` is not set. `systemctl start` printed only `Job failed. See "journalctl -xe" for details.`

**Fix:** Create the service, or point the timer at an existing one with `Unit=`.

### `Failed to parse calendar specification 'Mon..Fri 25:00': Invalid argument`

**Cause:** An invalid time in the expression.

**Fix:** Test every expression with `systemd-analyze calendar` before using it.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are the two units behind a systemd timer, and which one do you enable?"
    **Say first:** A `.timer` and the `.service` it starts; you enable and start the timer.

    **Proof:** `systemctl enable --now db-dump.timer`; `systemctl list-timers`.

    **Follow-up:** Why does the service have no `[Install]` section?

??? question "L1: What does Persistent=true do?"
    **Say first:** If the host was off at the scheduled time, the job runs once soon after the next boot.

    **Proof:** `ls /var/lib/systemd/timers/` holds the stamp files that record the last run.

    **Follow-up:** Which cron component provides the same behavior? (anacron.)
<!-- --8<-- [end:l1] -->

??? question "L2: Convert the crontab line */15 * * * * /usr/local/bin/sync-reports to a timer."
    **Say first:** A oneshot service with the command and a timer with `OnCalendar=*:0/15`.

    **Proof:** `systemd-analyze calendar "*:0/15"`; `systemctl enable --now sync-reports.timer`.

    **Follow-up:** How do you make it run 15 minutes after each finished run instead? (`OnUnitInactiveSec=15min`.)

??? question "L2: Run a command once, ten minutes from now, with its output in the journal."
    **Say first:** A transient timer.

    **Proof:** `sudo systemd-run --on-active=10min --unit=reindex /opt/app/bin/reindex`; `journalctl -u reindex`.

    **Follow-up:** How is this different from `at`?

??? question "L2: When did a timer last run, and did it succeed?"
    **Say first:** `list-timers` for the time, the service's status and journal for the result.

    **Proof:** `systemctl list-timers db-dump.timer`; `systemctl status db-dump.service`; `journalctl -u db-dump -n 20`.

    **Follow-up:** How do you get alerted when it fails? (`OnFailure=` in the service.)

??? question "L2: Why would you choose a timer over cron for a backup job?"
    **Say first:** Full logs in the journal, no overlapping runs, resource limits, dependencies on the network or a mount, and catch-up after downtime.

    **Proof:** The comparison table above; `systemctl show db-dump.service -p Result`.

    **Follow-up:** When is cron still the simpler choice?

??? question "L3: A timer shows in list-timers, but the job never did its work. How do you investigate?"
    **Say first:** Check whether the service ran and how it ended, then run it by hand.

    **Proof:** `systemctl list-timers --all` for `LAST`; `journalctl -u name.service`; `systemctl start name.service`; `systemctl cat name.timer` for a wrong `Unit=`.

    **Follow-up:** What would the timer show if the host was down at the scheduled time and `Persistent=` was not set?

---

## Related

- [cron and at](cron-and-at.md): the traditional scheduler
- [Unit Files](../08-systemd-and-services/unit-files.md): `[Unit]` and `[Service]` settings
- [Systemd Toolbox](../08-systemd-and-services/systemd-toolbox.md): `systemd-run`
- [logrotate](../09-logging/logrotate.md): a vendor timer in daily use

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
