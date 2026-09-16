# Priority and Nice

The nice value tells the Linux scheduler how to share CPU time between competing processes; `ionice` does the same for disk I/O and `chrt` switches a process to a real-time policy. These controls matter when a backup, build or report job must not slow down a production service on the same host.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Nice range | -20 (highest priority) to 19 (lowest); default 0 | `nice` |
| Start with a nice value | `nice -n 10 cmd`; the default increment is 10 | `nice -n 10 nice` |
| Change a running process | `renice -n 5 -p <pid>`; also `-u user`, `-g pgrp` | `ps -o ni -p <pid>` |
| Unprivileged users | May only raise the nice value (lower priority) of their own processes | `renice -n 2` after `5` fails |
| Negative nice | Needs root, `CAP_SYS_NICE`, or a `nice` limit in `limits.conf` | `ulimit -e` |
| Weight | Each nice step changes CPU share by about 10% (weight ratio 1.25) | two CPU hogs on one core |
| `PR` in `top` | 20 + nice for normal tasks; `rt` or negative for real-time | `top` |
| I/O class | `ionice -c 1` realtime, `-c 2 -n 0..7` best-effort, `-c 3` idle | `ionice -p <pid>` |
| I/O priority effect | Honored by the BFQ scheduler; `mq-deadline` and `none` mostly ignore it | `cat /sys/block/<dev>/queue/scheduler` |
| Real-time policies | `SCHED_FIFO` and `SCHED_RR`, priority 1 to 99, root only | `chrt -p <pid>` |
| Scheduler | CFS up to Linux 6.5; EEVDF from 6.6 (RHEL 10 ships 6.12) | `uname -r` |
| Autogroup | When enabled, the scheduler groups tasks by session, so nice works only within a session | `cat /proc/sys/kernel/sched_autogroup_enabled` |
| systemd | `Nice=`, `CPUWeight=`, `IOSchedulingClass=`, `IOWeight=` in a unit | `systemctl show -p Nice <unit>` |
<!-- --8<-- [end:facts] -->

---

## nice and renice

```bash
nice; nice -n 10 nice; nice -n 25 nice
nice -n -5 true
sleep 300 >/dev/null 2>&1 &
renice -n 5 -p 2815; renice -n 2 -p 2815
sudo renice -n -5 -p 2815
ps -o pid,ni,pri,cls,rtprio,comm -p 2815
```

Output:

```text
0
10
19
nice: cannot set niceness: Permission denied
2815 (process ID) old priority 0, new priority 5
renice: failed to set priority for 2815 (process ID): Permission denied
2815 (process ID) old priority 5, new priority -5
    PID  NI PRI CLS RTPRIO COMMAND
   2815  -5  24  TS      - sleep
```

Values above 19 are clamped to 19. A user could raise the nice value from 0 to 5 but not lower it back to 2; only root can lower it.

Children inherit the nice value of their parent:

```bash
ps -o pid,ni,comm -p 2905; nice -n 5 bash -c 'ps -o pid,ni,comm -p $$'
```

Output:

```text
    PID  NI COMMAND
   2905   0 sleep
    PID  NI COMMAND
   2929   5 ps
```

`bash -c` with a single command execs `ps` directly, so `$$` is the PID of `ps`, which carries nice 5.

!!! note "renice changes one thread by default on Linux"
    Nice is a per-thread attribute. `renice -p <pid>` changes the main thread, and threads created afterwards inherit it; for an existing multithreaded service, renice each TID from `/proc/<pid>/task/`, or set `Nice=` in the unit and restart it.

---

## Nice Under CPU Contention

Nice only matters when tasks compete for the same CPU. Two CPU hogs pinned to CPU 0, one at nice 0 and one at nice 10, share it roughly 90/10:

```bash
taskset -c 0 stress-ng --cpu 1 --timeout 25 >/dev/null 2>&1 &
taskset -c 0 nice -n 10 stress-ng --cpu 1 --timeout 25 >/dev/null 2>&1 &
sleep 10
ps -o pid,ni,psr,%cpu,comm -C stress-ng-cpu
```

Output:

```text
    PID  NI PSR %CPU COMMAND
   2714   0   0 90.1 stress-ng-cpu
   2715  10   0  9.7 stress-ng-cpu
```

The weight of nice 0 is 1024 and of nice 10 is 110, so the expected split is 1024/1134 = 90%. On an idle multi-CPU host both would get 100%, and nice would change nothing.

!!! warning "Autogroup can make nice look ineffective"
    With `kernel.sched_autogroup_enabled=1` (the default on this kernel), the scheduler first divides CPU between sessions, then applies nice inside each session. A `nice 19` job in one SSH session still gets half the CPU against a busy process in another session; `systemd` services are grouped by cgroup, where `CPUWeight=` is the effective control.

---

## I/O Priority

`ionice` sets the I/O scheduling class; it has an effect only with an I/O scheduler that supports priorities (BFQ).

```bash
ionice -p 2905; ionice -c 3 -p 2905; ionice -p 2905
cat /sys/block/vda/queue/scheduler
```

Output:

```text
none: prio 0
idle
[mq-deadline] kyber bfq none
```

| Class | Option | Use |
|---|---|---|
| Realtime | `-c 1 -n 0..7` | Root only; can starve everything else |
| Best-effort | `-c 2 -n 0..7` | Default; `none` means best-effort derived from nice |
| Idle | `-c 3` | Gets disk time only when no one else needs it |

This virtual disk uses `mq-deadline` (in brackets), so the `idle` class is recorded but not enforced. For backups on such hosts, limit I/O with the unit's `IOReadBandwidthMax=` or with `rsync --bwlimit`.

---

## Real-Time Policies

`SCHED_FIFO` runs a task until it blocks or a higher real-time priority arrives, and `SCHED_RR` adds a time slice between tasks of equal priority. Both preempt every normal task, so only root can set them.

```bash
chrt -p 2905; chrt -m | head -3
chrt -f 10 true
sudo chrt -f 10 sleep 1 & sleep 0.3; ps -eo pid,cls,rtprio,ni,pri,comm | awk 'NR==1 || $2 == "FF"'
```

Output:

```text
pid 2905's current scheduling policy: SCHED_OTHER
pid 2905's current scheduling priority: 0
SCHED_OTHER min/max priority	: 0/0
SCHED_FIFO min/max priority	: 1/99
SCHED_RR min/max priority	: 1/99
chrt: failed to set pid 0's policy: Operation not permitted
    PID CLS RTPRIO  NI PRI COMMAND
     16  FF     99   - 139 migration/0
     20  FF     99   - 139 migration/1
     25  FF     99   - 139 migration/2
     30  FF     99   - 139 migration/3
     52  FF     50   -  90 watchdogd
    100  FF     50   -  90 irq/24-ACPI:Ged
    103  FF     50   -  90 irq/25-ACPI:Ged
   2917  FF     10   -  50 sleep
```

| `CLS` | Policy |
|---|---|
| `TS` | `SCHED_OTHER`, the normal time-sharing policy |
| `B` | `SCHED_BATCH`, CPU-bound work with fewer preemptions |
| `IDL` | `SCHED_IDLE`, runs only when nothing else wants the CPU |
| `FF` | `SCHED_FIFO` |
| `RR` | `SCHED_RR` |

!!! danger "A busy SCHED_FIFO task can lock up a CPU"
    The kernel reserves 5% of each second for normal tasks (`kernel.sched_rt_runtime_us` = 950000 of `sched_rt_period_us` = 1000000). Setting it to `-1` removes the safety margin.

---

## Priorities in systemd Units

A service's priority is set in its unit, which applies to every process it starts and survives restarts.

```bash
systemctl show -p Nice -p CPUWeight -p IOWeight crond
```

Output:

```text
CPUWeight=[not set]
IOWeight=[not set]
Nice=0
```

```ini
[Service]
Nice=10
IOSchedulingClass=idle
CPUWeight=20
```

`CPUWeight=` (1 to 10000, default 100) divides CPU between cgroups and works regardless of autogroup; it requires the `cpu` cgroup controller to be enabled for the unit's slice.

---

## Common Errors

### `nice: cannot set niceness: Permission denied`

**Cause:** an unprivileged user asked for a negative nice value.

**Fix:** run it with `sudo`, grant a limit in `/etc/security/limits.d/` (`@devs - nice -5`), or set `Nice=` in a unit.

### `renice: failed to set priority for 2815 (process ID): Permission denied`

**Cause:** a user tried to lower the nice value of a process, or to renice another user's process.

**Fix:** use `sudo renice`.

### `chrt: failed to set pid 0's policy: Operation not permitted`

**Cause:** real-time policies need `CAP_SYS_NICE` or an `RLIMIT_RTPRIO` limit.

**Fix:** `sudo chrt`, or `CPUSchedulingPolicy=fifo` in a unit.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does the nice value do, and what is its range?"
    **Say first:** it weights a process's share of CPU time when CPUs are contended, from -20 (most favored) to 19 (least), default 0.

    **Proof:** two pinned CPU hogs at nice 0 and 10 get about 90% and 10%.

    **Follow-up:** Why does nice change nothing on an idle machine?

??? question "L1: Why can a normal user increase but not decrease a nice value?"
    **Say first:** lowering nice takes CPU from other users' work, so it needs `CAP_SYS_NICE` or an explicit limit.

    **Proof:** `renice -n 2` after `renice -n 5` fails with `Permission denied`.

    **Follow-up:** Where do you grant a group permission to use negative nice values?
<!-- --8<-- [end:l1] -->

??? question "L2: Run a nightly compression job at the lowest CPU and I/O priority."
    **Say first:** combine `nice` and `ionice`.

    **Proof:** `nice -n 19 ionice -c 3 tar -czf /backup/app.tgz /srv/app`

    **Follow-up:** When does `ionice -c 3` have no effect?

??? question "L2: Lower the priority of every process of user reports."
    **Say first:** renice by user.

    **Proof:** `sudo renice -n 10 -u reports`

    **Follow-up:** Does this affect processes the user starts later? (No; use a limit or a slice.)

??? question "L2: Show the scheduling policy and real-time priority of all real-time tasks."
    **Say first:** print the class and `rtprio` columns and filter.

    **Proof:** `ps -eo pid,cls,rtprio,comm | awk '$2 != "TS"'`

    **Follow-up:** Why do `migration/N` threads run at `FF 99`?

??? question "L3: A batch job was started with nice 19, but the web service on the same host is still slow."
    **Say first:** nice only shares CPU, and may be undone by autogroup; check whether the contention is CPU at all.

    **Proof:** `top` for `us` and `wa`, `iostat -x 1` for disk latency, `cat /proc/sys/kernel/sched_autogroup_enabled`, then `CPUWeight=` or `IOWeight=` through `systemd-run --scope -p` for the job.

    **Follow-up:** Which cgroup settings cap the job instead of only weighting it? (`CPUQuota=`, `IOReadBandwidthMax=`.)

---

## Related

- [Viewing Processes](viewing-processes.md): the `NI` and `PR` columns
- [Unit Files](../08-systemd-and-services/unit-files.md): resource settings in a service
- [Signals](signals.md): stopping a job instead of slowing it

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
