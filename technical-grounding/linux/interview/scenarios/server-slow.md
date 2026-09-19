# Server Slow

A server is reported slow with no other detail. The interviewer watches whether the candidate clarifies what slow means, then runs an ordered checklist that places the bottleneck on a resource, rather than guessing or restarting blindly.

---

## Symptom

> "The server feels slow. Everything is sluggish. Figure out why."

---

## Clarifying Questions

- **Slow how, in numbers?** Higher request latency, a stalled batch job, and slow logins are different problems.
- **When did it start, and what changed?** A regression at a deploy time points at code, not capacity.
- **One host or many?** A fleet-wide slowdown points at a shared dependency, not this box.
- **Is it getting worse?** A rising load average means the cause is still active.

---

## Diagnostic Path

Run the 60-second checklist in order on `web` (Rocky Linux 10.2), letting each command rule a resource in or out. Read `dmesg` first, because a hardware or memory event names the cause outright.

### 1. Load and Recent Events

```bash
uptime
dmesg -T | tail -3
```

Output:

```text
 23:00:11 up 5 min,  0 user,  load average: 1.02, 0.24, 0.08
```

A load average rising across the three windows means the pressure is growing now. `dmesg` clean of OOM or I/O errors rules out the loudest causes.

### 2. Run Queue and CPU Split

```bash
vmstat 1 3
```

Output:

```text
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 4  0      0 343284  10780 430336    0    0   681   710  127    0  2  1 97  0  0
 3  0      0 343284  10780 430336    0    0     0     0  511  168 100  0  0  0  0
```

The run queue `r` is 3 to 4 on two CPUs, and `us` is 100 with `wa` and `st` at 0. This is CPU saturation in user code, not I/O or swap, so the memory and disk branches can be skipped for now.

### 3. Which Process, and Balance

```bash
mpstat -P ALL 1 1 | tail -3
pidstat 1 1 | head -6
```

Output:

```text
22:59:52       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
23:00:11        0      1466   61.39    0.00    0.00   38.61   61.39     1  stress-ng-cpu
23:00:11        0      1465   77.23    0.00    0.00   22.77   77.23     1  stress-ng-cpu
```

Both CPUs are pinned, and `pidstat` names the consumers with high `%wait`, meaning more runnable threads than cores. If instead one core were hot and the rest idle, the work would be single-threaded and more cores would not help.

### 4. Rule Out Memory and Disk

```bash
free -h | head -2
iostat -xz 1 1 | tail -3
```

Output:

```text
Mem:           975Mi       371Mi       344Mi       3.4Mi       400Mi       603Mi
vda             20.77    343.27      0.35   11.10    361.25      0.86     0.02   2.98
```

`available` memory is healthy and swap is not paging, so memory is not the limit. The disk shows `%util` 2.98 and `aqu-sz` 0.02, so I/O is idle. Both branches are clear, confirming the CPU finding.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| CPU saturated | `vmstat` `r` > cores, `us` high, `pidstat` names it | Scale out, optimise, or throttle the process |
| Single-threaded | One `mpstat` core at 100%, rest idle | Parallelise; more cores do not help |
| Memory | Low `available`, `vmstat` `si`/`so` active | Fix the leak or add RAM |
| Disk I/O | `iostat` `%util` near 100, high `aqu-sz`/`await` | Find the writer, reduce I/O |
| Steal | `st` non-zero and persistent | Move to a larger or dedicated instance |
| Application | Host resources clear, latency still high | Look at the app, locks, dependencies |

---

## Fix

For the captured CPU-bound case, identify and act on the process rather than rebooting. A CPU-heavy batch job can be reniced or moved; a runaway loop needs a code fix.

```bash
renice +10 -p $(pgrep -n stress-ng)     # lower its priority
# or cap it in a slice: systemd-run --scope -p CPUQuota=50% ...
```

If the checklist is clean but users still see slowness, the bottleneck is above the host: the application, a lock, or a downstream dependency.

---

## Prevention

- Keep `sar` history running, so a slowdown can be compared against a baseline.
- Alert on saturation (run queue, disk queue) and on user-facing latency, not on raw utilization.
- Set CPU and memory limits on batch and background work, so it cannot starve the main service.

---

## Related

- [Methodology](../../17-performance-and-troubleshooting/methodology.md): the full USE method and checklist
- [CPU and Load](../../17-performance-and-troubleshooting/cpu-and-load.md): reading run queue and the CPU split

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. Load was generated with `stress-ng` for the capture.
