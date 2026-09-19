# Profiling and Tracing

`strace`, `perf` and eBPF answer different questions: what a process asks the kernel, where the CPU spends cycles, and what the whole system is doing with low overhead. Choosing the right one is the difference between a diagnosis in minutes and a slowed-down production process.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `strace` | Traces syscalls of one process; high overhead | `strace -f -p PID` |
| `strace -c` | Summarises syscall counts, time and errors | `strace -c cmd` |
| `strace` cost | Stops the target on every syscall; not for hot production paths | measure before use |
| `perf stat` | Hardware and software counters for a command | `perf stat -- cmd` |
| `perf record` | Samples the CPU; `perf report` shows hot functions | `perf record -g -- cmd` |
| `perf top` | Live system-wide CPU profile | `perf top` |
| Sampling vs tracing | `perf` samples periodically (low overhead); `strace` traces every event | choose by overhead |
| eBPF | In-kernel programs for low-overhead tracing | `bpftrace`, `bcc` tools |
| bcc tools | `execsnoop`, `opensnoop`, `biolatency`, `tcplife` | `execsnoop-bpfcc` |
| Flame graph | Folded `perf` stacks rendered as nested bars | `perf script` + FlameGraph |
| Which tool | syscalls → `strace`; CPU → `perf`; system-wide, low cost → eBPF | match to the question |
| Symbols | Profiling needs debug symbols to name functions | `-debuginfo`/`-dbgsym` |
<!-- --8<-- [end:facts] -->

---

## When to Use What

The three tools overlap but suit different questions and cost very different amounts. Reach for the cheapest one that answers the question.

| Question | Tool | Why |
|---|---|---|
| **What is this process asking the kernel?** | `strace` | Shows every syscall, arguments and errors |
| **Which files or configs does it try to open?** | `strace -e openat` | Filters to one syscall, spots `ENOENT` |
| **Where is the CPU time going?** | `perf record` / `perf top` | Samples stacks with low overhead |
| **Why is a hardware metric bad (cache, branches)?** | `perf stat` | Reads CPU performance counters |
| **What is the whole system doing, in production?** | eBPF (`bpftrace`, bcc) | In-kernel, minimal overhead |

!!! warning "strace stops the target on every syscall"
    `strace` intercepts each syscall, which can slow a busy process by an order of magnitude. Use it on a reproduction or a quiet instance, and prefer `perf` or eBPF for anything on a hot production path.

---

## Counting Syscalls with strace

`strace -c` runs a command and prints a summary: how many times each syscall ran, how long it took, and how many returned errors. It is the fastest way to see whether a program is dominated by I/O, memory mapping or something unexpected.

```bash
strace -c cat /etc/os-release >/dev/null
```

Output:

```text
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
  0.00    0.000000           0        10           read
  0.00    0.000000           0         1           write
  0.00    0.000000           0        25           close
  0.00    0.000000           0        24           fstat
  0.00    0.000000           0        46           mmap
  0.00    0.000000           0         8           mprotect
```

The `mmap` count (46) is the dynamic linker mapping shared libraries at startup, normal for any dynamically linked program. A high `errors` column on one syscall points straight at the problem, such as repeated `ENOENT` while searching for a missing file.

---

## Tracing Specific Syscalls

Filtering to one syscall with `-e trace=` cuts the noise. Tracing `openat` shows every path a program tries and which ones fail, which explains "it works on my machine" configuration and library problems.

```bash
strace -e trace=openat cat /etc/hostname 2>&1 | grep ENOENT | head -2
```

Output:

```text
openat(AT_FDCWD, "/usr/lib/locale/locale-archive", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/usr/lib/locale/C.UTF-8/LC_IDENTIFICATION", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```

Each `-1 ENOENT` is a file the program looked for and did not find. For a failing binary or a config that "is not being read", this names the exact path being tried.

---

## CPU Profiling with perf

`perf stat` reads hardware counters for a command, giving instructions, cycles, the instructions-per-cycle ratio and branch misses. These reveal whether code is CPU-bound on computation, stalled on memory, or mispredicting branches.

```bash
perf stat -- bash -c 'for i in $(seq 1 200000); do :; done'
```

Output:

```text
        1965647998      instructions                     #    3.73  insn per cycle
         526859940      cycles                           #    5.343 GHz
          11796986      stalled-cycles-frontend          #    2.24% frontend cycles idle
                 0      branch-misses
       0.105447602 seconds time elapsed
```

An IPC of 3.73 is high, meaning the CPU is doing real work rather than stalling. To find which functions burn the time, `perf record` samples stacks and `perf report` ranks them.

```bash
perf record -g -- bash -c 'a=0; for i in $(seq 1 500000); do a=$((a+i)); done'
perf report -i perf.data --stdio | grep -vE '^#|^$' | head -5
```

Output:

```text
    21.72%     0.00%  bash     [unknown]             [k] 0000000000000000
               |--9.93%--__strlen_evex
               |--4.90%--_int_malloc
```

The call graph shows time in `__strlen_evex` and `_int_malloc`, the C library string and allocation routines the shell loop drives. Folding these stacks into a flame graph turns the same data into a visual where wide bars are the hot paths.

!!! tip "Install debug symbols before profiling"
    Without matching debug symbols, `perf report` shows raw addresses instead of function names, making a profile unreadable. Install the `-debuginfo` (RHEL) or `-dbgsym` (Ubuntu) packages for the binary and its libraries first.

---

## eBPF for Low-Overhead Tracing

eBPF runs small verified programs inside the kernel, so it can trace events across the whole system with far less overhead than `strace`. The bcc and bpftrace toolkits ship ready-made tracers.

```bash
execsnoop-bpfcc          # every new process, system-wide
opensnoop-bpfcc          # every file open and its result
biolatency-bpfcc         # block I/O latency as a histogram
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[comm] = count(); }'
```

These answer "which process keeps exec'ing", "what is opening this file", and "what is the I/O latency distribution" on a live production host, where `strace` would be too costly. The bcc tools require a kernel built with BPF and the matching headers.

---

## Common Errors

### `perf report` shows only addresses, no function names

**Cause:** the profiled binary or its libraries have no debug symbols installed.

**Fix:** install the matching `-debuginfo` (RHEL) or `-dbgsym` (Ubuntu) packages, then re-run `perf record`.

### `strace` makes the process too slow to reproduce the issue

**Cause:** `strace` traps every syscall, adding large overhead to syscall-heavy code.

**Fix:** switch to sampling with `perf record`, or to eBPF tools that trace in-kernel with minimal cost.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: When would you reach for strace instead of perf?"
    **Say first:** `strace` when the question is which syscalls a process makes and why they fail; `perf` when the question is where CPU time goes.

    **Proof:** `strace -e openat` finds a missing file; `perf top` finds a hot function.

    **Follow-up:** why is `strace` a poor choice on a busy production process? (it traps every syscall and slows it heavily.)
<!-- --8<-- [end:l1] -->

??? question "L2: A program starts slowly and you suspect a missing file. Prove it."
    **Say first:** trace `openat` and look for `ENOENT`.

    **Proof:**

    ```bash
    strace -f -e trace=openat -p $(pgrep -n app) 2>&1 | grep ENOENT
    ```

    **Follow-up:** what if the failing calls are `stat`, not `openat`? (add them: `-e trace=openat,stat`.)

??? question "L2: Summarise which syscall dominates a command's time."
    **Say first:** the `strace -c` summary ranks syscalls by count, time and errors.

    **Proof:** `strace -c -f ./app` and read the `% time` and `errors` columns.

    **Follow-up:** how would you get the same for CPU functions rather than syscalls? (`perf record` then `perf report`.)

??? question "L4: How does perf sampling differ from strace tracing, and why does overhead differ so much?"
    **Say first:** `perf` interrupts the CPU at a fixed frequency and records the current stack, so cost is bounded by the sample rate; `strace` uses `ptrace` to stop the target on every syscall, so cost scales with syscall count.

    **Proof:** `perf stat` shows near-native runtime; the same workload under `strace` runs far slower.

    **Don't say:** that `perf` records every event like `strace` does; it samples.

??? question "L4: Why can eBPF trace production safely where strace cannot?"
    **Say first:** eBPF programs run in the kernel, are verified for safety, and aggregate in place, so they avoid the per-event context switches and stop-the-target cost of `ptrace`.

    **Proof:** bcc tools like `opensnoop` and `biolatency` run on live hosts with negligible impact.

    **Don't say:** that eBPF is merely a faster `strace`; it runs a different mechanism entirely.

??? question "L3: A process runs fine alone but stalls under load, and CPU looks idle. How do you find where it waits?"
    **Say first:** sampling off-CPU or syscall time, since the cost is in waiting, not burning CPU.

    **Proof:** `strace -c -f` shows which syscall dominates; `perf` off-CPU or eBPF `offcputime` shows where it blocks.

    **Follow-up:** why would `perf top` alone miss this? (it profiles on-CPU time, not time spent blocked.)

---

## Related

- [System Calls and Tracing](../07-processes/system-calls-and-tracing.md): the syscall path and `strace` basics
- [CPU and Load](cpu-and-load.md): when high `%sys` points at profiling
- [Methodology](methodology.md): where profiling fits after the checklist
- [Round 4 Internals](../interview/round-4-internals.md): sampling versus tracing

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The eBPF tool commands are shown without captured output, since the bcc toolkit is not installed on the capture host.
