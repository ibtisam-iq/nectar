# Performance Methodology

Performance work is a search for the one resource that limits the system, done in a fixed order so nothing is missed. A method turns "the server is slow" into a measured bottleneck instead of a guess.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| USE method | For each resource check Utilization, Saturation, Errors | `vmstat 1`, `iostat -xz 1`, `dmesg` |
| The four resources | CPU, memory, disk I/O, network | `top`, `free`, `iostat`, `ss -s` |
| 60-second checklist | `uptime`, `dmesg`, `vmstat 1`, `mpstat -P ALL 1`, `pidstat 1`, `iostat -xz 1`, `free -m`, `sar -n DEV 1`, `top` | run in order |
| Saturation signal | Work queued behind a busy resource: run queue, `aqu-sz`, swap-in | `vmstat` `r`, `iostat` `aqu-sz` |
| Utilization trap | 100% busy is not always the limit; a queue behind it is | `%util` with `aqu-sz` |
| Live vs history | `vmstat`/`iostat` show now; `sar` reads the archive from `sysstat` | `sar -f /var/log/sa/saNN` |
| sysstat collector | `sar` needs the collector enabled and running | `systemctl status sysstat` |
| Load average | Runnable plus uninterruptible (`D`) tasks over 1, 5, 15 min | `uptime`, `cat /proc/loadavg` |
| First move | Read `dmesg` for OOM, resets and errors before tuning anything | `dmesg -T` |
| Baseline | A number means nothing without the normal value to compare it to | keep `sar` history |
| Package | `sar`, `iostat`, `mpstat`, `pidstat` come from `sysstat` | `rpm -q sysstat` / `dpkg -l sysstat` |
<!-- --8<-- [end:facts] -->

---

## The First Questions

The fastest diagnosis starts before any command: what changed, when it started, and whether it affects one host or many. A regression that began at a deploy time points at code, not capacity.

Ask what "slow" means in numbers, since a request that went from 20ms to 60ms and a queue that stalls for seconds are different problems. Then read `dmesg` first, because a hardware or out of memory event names the cause outright.

```bash
dmesg -T | tail -3
```

Output:

```text
[Thu Sep 17 23:07:51 2026] perf: interrupt took too long (10177 > 10163), lowering kernel.perf_event_max_sample_rate to 19500
```

!!! tip "Name the bottleneck before touching a knob"
    Every tuning change is a hypothesis. Measure the limiting resource first, change one thing, then measure again. Untested tuning hides the real cause and adds new variables.

---

## The USE Method

Brendan Gregg's USE method checks every resource for three things: Utilization (how busy), Saturation (how much work is queued), and Errors. Utilization alone misleads, because a disk at 100% utilization with a short queue is fine while the same disk with a queue of 140 is the bottleneck.

| Resource | Utilization | Saturation | Errors |
|---|---|---|---|
| **CPU** | `mpstat` `%idle` | `vmstat` `r` above CPU count | `dmesg` MCE |
| **Memory** | `free` used | `vmstat` `si`/`so`, OOM kills | `dmesg` OOM |
| **Disk** | `iostat` `%util` | `iostat` `aqu-sz`, `w_await` | `dmesg` I/O errors |
| **Network** | `sar -n DEV` `%ifutil` | `ss -s` retransmits, drops | `ip -s link` errors |

---

## The 60-Second Checklist

A first pass runs ten commands that cover all four resources in about a minute. The point is coverage, not depth: each command rules a resource in or out.

```bash
uptime                 # load average trend
dmesg -T | tail        # recent errors, OOM, resets
vmstat 1 3             # run queue, swap, io, cpu split
mpstat -P ALL 1 1      # per-CPU balance
pidstat 1 1            # per-process CPU
iostat -xz 1 2         # per-disk utilization and queue
free -m                # memory and swap
sar -n DEV 1 1         # per-interface throughput
```

Output:

```text
 22:59:17 up 4 min,  0 user,  load average: 0.00, 0.00, 0.00
```

The load average trio reads left to right as now, five minutes ago, fifteen minutes ago. Rising numbers mean the problem is growing; falling numbers mean the worst has passed.

!!! warning "Load average includes I/O waiters as well as runnable tasks"
    Linux load includes processes in `D` state waiting on I/O, so a high load with idle CPUs points at disk or a stuck NFS mount, not at the processor. Read `vmstat` `b` and `wa` before blaming the CPU.

---

## Reading the Signals Together

No single number diagnoses a system; the pattern across commands does. A high run queue with 100% user CPU is a compute limit, while a high load with low CPU and high `wa` is an I/O limit.

```bash
vmstat 1 3
```

Output:

```text
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 343284  10780 430336    0    0   681   710  127    0  2  1 97  0  0  0
 3  0      0 343284  10780 430336    0    0     0     0  511  168 100  0  0  0  0  0
```

The `r` column is the run queue: four runnable tasks on two CPUs means work is waiting for a core. With `us` at 100 and `wa` at 0, this is CPU saturation, so the next step is [CPU and Load](cpu-and-load.md), not disk.

---

## Historical Data with sar

Live tools show the current second, which is useless for a slowdown that happened overnight. The `sysstat` package runs a collector that writes counters to `/var/log/sa`, and `sar` reads them back for any period.

```bash
sar -u 1 2         # live CPU, or -f /var/log/sa/saNN for a past day
```

Output:

```text
23:07:45        CPU     %user     %nice   %system   %iowait    %steal     %idle
23:07:46        all      0.00      0.00      0.00      0.00      0.00    100.00
Average:        all      0.00      0.00      0.00      0.00      0.00    100.00
```

The collector is off until enabled, so history exists only if `sysstat` was set up before the incident. Enabling it after the fact captures the next incident, not this one.

=== "RHEL / Rocky"

    ```bash
    sudo dnf install -y sysstat
    sudo systemctl enable --now sysstat
    ```

=== "Ubuntu / Debian"

    ```bash
    sudo apt install -y sysstat
    sudo sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
    sudo systemctl enable --now sysstat
    ```

---

## Common Errors

### `sar: Cannot open /var/log/sa/saNN: No such file or directory`

**Cause:** the `sysstat` collector never ran for that day, so no archive exists.

**Fix:** enable the collector for future incidents; for now, fall back to live `vmstat 1` and `iostat -xz 1`.

### `Command 'iostat' not found`

**Cause:** `iostat`, `mpstat`, `pidstat` and `sar` all ship in the `sysstat` package, which is not installed by default.

**Fix:** install `sysstat` (see the tabs above); `vmstat`, `top` and `free` from `procps` work without it.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does the USE method check, and why is utilization not enough?"
    **Say first:** for every resource it checks Utilization, Saturation and Errors; utilization alone hides a queue building behind a busy resource.

    **Proof:** a disk at `%util` 100 with `aqu-sz` near 1 is fine, while the same disk with `aqu-sz` 140 is the bottleneck.

    **Follow-up:** which single command shows both utilization and saturation for disks? (`iostat -xz`.)

??? question "L1: Why can load average be high while every CPU is idle?"
    **Say first:** Linux load counts uninterruptible (`D` state) tasks as well as runnable ones, so processes blocked on I/O raise it without using CPU.

    **Proof:** `uptime` high, `mpstat` `%idle` near 100, `vmstat` `b` and `wa` non-zero.

    **Follow-up:** what commonly puts many tasks into `D` state at once? (a stalled disk or NFS mount.)
<!-- --8<-- [end:l1] -->

??? question "L2: Run the 60-second checklist and say what each command rules out."
    **Say first:** ten commands covering CPU, memory, disk and network in order.

    **Proof:**

    ```bash
    uptime; dmesg -T | tail; vmstat 1 3; mpstat -P ALL 1 1
    pidstat 1 1; iostat -xz 1 2; free -m; sar -n DEV 1 1
    ```

    **Follow-up:** which command in the list is most likely to name the root cause outright? (`dmesg`.)

??? question "L2: You need CPU usage from 3am last night. How do you get it?"
    **Say first:** read the `sar` archive for that day, since live tools only show now.

    **Proof:** `sar -u -f /var/log/sa/sa$(date -d yesterday +%d) -s 03:00:00 -e 04:00:00`.

    **Follow-up:** what if `/var/log/sa` is empty? (the collector was never enabled; only future data can be captured.)

??? question "L3: A service is reported slow with no other detail. How do you start?"
    **Say first:** clarify what slow means in numbers and when it started, then run the 60-second checklist to place the bottleneck on a resource.

    **Proof:** `dmesg` for events, `vmstat 1` for run queue and swap, `iostat -xz 1` for disk queue, `sar` for the history around the reported time.

    **Follow-up:** the checklist is clean but users still complain: where do you look next? (the application and its dependencies, latency and locks, not host resources.)

??? question "L4: Why is a baseline essential to reading a single metric?"
    **Say first:** a metric is only meaningful against the normal value, because acceptable ranges vary by workload and hardware.

    **Proof:** 30% `%util` is idle for one disk and saturating for another; only history shows which.

    **Don't say:** that a fixed threshold (for example load above 1.0) is bad on every system.

---

## Related

- [CPU and Load](cpu-and-load.md): reading run queue, `us`/`sy`/`wa`/`st` and per-CPU balance
- [Memory](memory.md): `free`, swap and the OOM killer
- [Disk I/O](disk-io.md): `iostat` fields, `await` and `%util`
- [Server Slow](../interview/scenarios/server-slow.md): the checklist applied to one incident
- [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md): reading the kernel ring buffer

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
