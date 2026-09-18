# CPU and Load

Load average and per-CPU statistics tell whether a host is compute-bound, and if so which processes are responsible. Reading `us`, `sy`, `wa` and `st` correctly separates a real CPU limit from I/O, kernel work or a noisy cloud neighbour.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Load average | Runnable plus uninterruptible (`D`) tasks, averaged over 1, 5, 15 min | `uptime`, `cat /proc/loadavg` |
| Load vs cores | Load equal to core count is full; above it, tasks wait | `nproc` |
| Run queue | `vmstat` `r` above CPU count means CPU saturation | `vmstat 1` |
| `us` | User-space CPU time (application code) | `mpstat -P ALL 1` |
| `sy` | Kernel CPU time (syscalls, drivers) | `mpstat` |
| `wa` | Idle CPU waiting on I/O; high `wa` is a disk problem | `vmstat`, `iostat` |
| `st` | Steal: time the hypervisor gave to another guest | `vmstat`, `top` |
| `id` | Idle: CPU with nothing to run | `mpstat` |
| Context switch | `cswch/s` voluntary (blocked), `nvcswch/s` involuntary (preempted) | `pidstat -w 1` |
| High `sy` | Excessive syscalls, interrupts or lock contention | `pidstat`, `strace -c` |
| cgroup throttling | `cpu.max` caps a group; throttling appears in `cpu.stat` | `cat /sys/fs/cgroup/.../cpu.stat` |
| `/proc/loadavg` | Load trio, running/total tasks, last PID | `cat /proc/loadavg` |
<!-- --8<-- [end:facts] -->

---

## Load Average, Really

Load average is the number of tasks that are either running or waiting to run, plus those in uninterruptible sleep, averaged over one, five and fifteen minutes. Compared against the CPU count it shows headroom: a load of 2.0 on two CPUs is fully used, and the same load on eight CPUs is quiet.

```bash
nproc
cat /proc/loadavg
```

Output:

```text
2
1.02 0.24 0.08 4/100 1509
```

The three averages here rise from 0.08 to 1.02, so demand is climbing. The `4/100` field is running over total tasks, and the last number is the most recent PID.

!!! warning "Load average alone cannot tell CPU from I/O"
    Because uninterruptible (`D` state) tasks count toward load, a stuck disk raises it with idle CPUs. Confirm the cause with `vmstat` `r` (CPU) versus `b` and `wa` (I/O) before acting.

---

## The vmstat CPU Columns

`vmstat` splits CPU time into `us`, `sy`, `id`, `wa` and `st`, and shows the run queue in `r`. A run queue above the core count with high `us` is the clearest sign of a compute limit.

```bash
vmstat 1 3
```

Output:

```text
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 343284  10780 430336    0    0   681   710  127    0  2  1 97  0  0  0
 3  0      0 343284  10780 430336    0    0     0     0  511  168 100  0  0  0  0  0
 3  0      0 343284  10780 430336    0    0     0     0  509  162 100  0  0  0  0  0
```

With `r` at 3 to 4 on two CPUs and `us` at 100, this host is CPU-bound in user code. If `sy` were high instead, the load would be kernel work; if `wa` were high, the disk would be the limit despite the busy CPU line.

---

## Per-CPU Balance with mpstat

A total that reads 50% busy can hide one saturated core and one idle core, which happens with single-threaded work. `mpstat -P ALL` breaks the total into per-CPU rows.

```bash
mpstat -P ALL 1 1
```

Output:

```text
22:59:51     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
22:59:52     all  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
22:59:52       0  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
22:59:52       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
```

Both CPUs sit at 100% user here, so the work parallelises. A single hot core with the rest idle would point at a single-threaded bottleneck that more cores cannot help.

---

## Per-Process CPU with pidstat and top

Once the host is known to be CPU-bound, the next question is which process. `pidstat` attributes CPU per process each interval, including `%wait`, the time a runnable task spent off-CPU waiting for a core.

```bash
pidstat 1 1
```

Output:

```text
23:00:11        0      1464   59.41    0.00    0.00   38.61   59.41     0  stress-ng-cpu
23:00:11        0      1465   77.23    0.00    0.00   22.77   77.23     1  stress-ng-cpu
23:00:11        0      1466   61.39    0.00    0.00   38.61   61.39     1  stress-ng-cpu
```

Three CPU-bound threads share two CPUs, so each runs 59 to 77% of the time and waits (`%wait`) the rest for a core. A `top` snapshot sorted by CPU shows the same processes with per-core percentages that can exceed 100 on multiple cores.

```bash
top -b -n1 -o %CPU | head -8
```

Output:

```text
top - 23:00:11 up 5 min,  0 user,  load average: 1.02, 0.24, 0.08
Tasks:  95 total,   4 running,  91 sleeping,   0 stopped,   0 zombie
%Cpu(s): 95.2 us,  4.8 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1466 root      20   0   66176   7076   4228 R  90.0   0.7   0:18.20 stress-+
   1464 root      20   0   66176   7048   4228 R  60.0   0.7   0:18.34 stress-+
```

---

## Context Switches and High System Time

High `sy` time or a high context-switch rate means the CPU is busy with kernel work, not application progress. `pidstat -w` separates voluntary switches (a task blocked and yielded) from involuntary ones (the scheduler preempted it).

```bash
pidstat -w 1 1
```

Output:

```text
23:07:48      UID       PID   cswch/s nvcswch/s  Command
23:07:49        0        15      7.00      0.00  rcu_preempt
23:07:49        0        16      1.00      0.00  migration/0
23:07:49        0        20      1.00      0.00  migration/1
```

Many involuntary switches (`nvcswch/s`) point at more runnable threads than cores, while many voluntary switches (`cswch/s`) point at frequent blocking, often on locks or I/O. `strace -c` then shows which syscall dominates.

!!! tip "High %sys is a lead, not a verdict"
    Kernel time comes from syscalls, interrupts and lock contention. Profile it with `strace -c` for one process or `perf top` for the system, rather than assuming the kernel itself is slow.

---

## Steal and cgroup Throttling

On a shared host, `st` (steal) is time the hypervisor ran another guest instead of this one, so the CPU line looks idle while work stalls. Inside a container or systemd slice, a `cpu.max` quota throttles the group even when the host has spare CPU.

```bash
cat /sys/fs/cgroup/system.slice/cpu.max      # "quota period" or "max period"
grep -E 'nr_throttled|throttled_usec' /sys/fs/cgroup/system.slice/cpu.stat
```

Persistent steal means a noisy neighbour or an oversubscribed instance; rising `nr_throttled` means the cgroup quota is too tight for the workload. Both look like a slow application while the host CPU appears free.

---

## Common Errors

### `load average` high but `top` shows CPUs mostly idle

**Cause:** tasks in `D` (uninterruptible) state count toward load; the bottleneck is I/O, not CPU.

**Fix:** check `vmstat` `b` and `wa` and `iostat -xz 1`; find the blocked tasks with `ps -eo state,pid,cmd | grep '^D'`.

### `%steal` consistently above a few percent

**Cause:** the hypervisor is scheduling other guests onto this vCPU; the instance is oversubscribed or throttled.

**Fix:** move to a dedicated or larger instance; steal is not fixable from inside the guest.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does a load average of 8 mean on a 4-CPU host?"
    **Say first:** on average eight tasks wanted to run while only four cores existed, so the host was oversubscribed by roughly two times.

    **Proof:** compare `uptime` against `nproc`; `vmstat` `r` shows the current run queue.

    **Follow-up:** would the same load of 8 be a problem on a 16-CPU host? (no, there is headroom.)

??? question "L1: What is the difference between us, sy, wa and st in the CPU line?"
    **Say first:** `us` is user code, `sy` is kernel code, `wa` is idle time waiting on I/O, and `st` is time the hypervisor gave to another guest.

    **Proof:** `mpstat -P ALL 1` shows all four per CPU.

    **Follow-up:** which of these means the CPU is not actually the bottleneck? (`wa` and `st`.)
<!-- --8<-- [end:l1] -->

??? question "L2: The host is slow; show it is CPU-bound and name the process."
    **Say first:** confirm the run queue exceeds cores, then attribute CPU per process.

    **Proof:**

    ```bash
    vmstat 1 3          # r > nproc, high us
    pidstat 1 1         # per-process %CPU
    ```

    **Follow-up:** what does a high `%wait` in `pidstat` tell you? (the task was runnable but waiting for a core.)

??? question "L2: The total CPU reads 50% but the app is slow. What do you check?"
    **Say first:** per-CPU balance, because one saturated core can hide behind an idle one in the average.

    **Proof:** `mpstat -P ALL 1` shows a single core at 100% with others idle for single-threaded work.

    **Follow-up:** how do you make that workload use more cores? (parallelise it; more cores alone do not help.)

??? question "L3: Load is 20 on a 4-CPU box but CPU shows 90% idle. What is happening?"
    **Say first:** load counts uninterruptible tasks, so this is I/O or a stuck resource, not CPU.

    **Proof:** `vmstat` `b` and `wa` non-zero, `iostat -xz 1` shows a saturated disk, `ps -eo state,cmd | grep '^D'` lists the blocked tasks.

    **Follow-up:** what if the `D`-state tasks are all on an NFS mount? (the server or network is the cause; see the NFS hang case.)

??? question "L4: A container's CPU line looks idle but the app is throttled. Why?"
    **Say first:** the cgroup `cpu.max` quota caps the group's CPU regardless of host idle time, so it is throttled while the host looks free.

    **Proof:** `cpu.stat` shows rising `nr_throttled` and `throttled_usec`.

    **Don't say:** that host `%idle` proves the container has CPU to spare.

---

## Related

- [Methodology](methodology.md): where CPU fits in the 60-second checklist
- [Process States](../07-processes/process-states.md): why `D` state raises load
- [Server Slow](../interview/scenarios/server-slow.md): CPU as one branch of a slow host
- [Priority and Nice](../07-processes/priority-and-nice.md): changing how the scheduler shares CPU

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
