# Performance and Troubleshooting

How to find the one resource that limits a host, in a fixed order, and read the tools that measure CPU, memory, disk and limits. The method turns "the server is slow" into a named, measured bottleneck.

---

## Revision Card

| Fact | Value |
|---|---|
| Method | USE: for each resource check Utilization, Saturation, Errors |
| 60-second checklist | `uptime`, `dmesg`, `vmstat 1`, `mpstat -P ALL 1`, `pidstat 1`, `iostat -xz 1`, `free -m`, `sar -n DEV 1` |
| Load average | Runnable plus uninterruptible (`D`) tasks; compare to `nproc` |
| CPU split | `us` user, `sy` kernel, `wa` I/O wait, `st` steal, `id` idle |
| CPU saturated | `vmstat` `r` above core count with high `us` |
| Memory | Judge by `available`, not `free`; `buff/cache` is reclaimable |
| OOM | Exit 137 (128+9); `dmesg` names the killed process and constraint |
| RSS vs VSZ vs PSS | Resident, address space, shared-adjusted resident |
| Disk saturated | `iostat` `%util` near 100 with high `aqu-sz` and `await` |
| Too many open files | Per-process `-n` limit (`EMFILE`), not `fs.file-max` |
| fork fails | `EAGAIN`: `RLIMIT_NPROC` (`ulimit -u`) or `pid_max` |
| systemd limits | Services use `LimitNOFILE=`, not shell `ulimit` |
| Tools when | syscalls → `strace`; CPU → `perf`; system-wide low cost → eBPF |
| History | `sar` reads `/var/log/sa` if the `sysstat` collector ran |

| Task | Command |
|---|---|
| Is it CPU-bound | `vmstat 1 3` (r > nproc, high us), `pidstat 1` |
| Per-CPU balance | `mpstat -P ALL 1` |
| Memory and swap | `free -h`, `vmstat 1` (si/so) |
| Find a leak | watch `/proc/PID/status` `VmRSS` over time |
| Disk bottleneck | `iostat -xz 1`, then `pidstat -d 1` |
| Open descriptors | `ls /proc/PID/fd` count, `cat /proc/PID/limits` |
| Raise a service fd limit | `systemctl edit UNIT` → `LimitNOFILE=65536` |
| Profile CPU | `perf record -g -- cmd; perf report` |
| Trace a missing file | `strace -f -e openat -p PID`, grep ENOENT |
| Apply a tuned profile | `sudo tuned-adm profile throughput-performance` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Methodology](methodology.md) | USE method, the 60-second checklist, `sar` history, first questions | Core | High |
| [CPU and Load](cpu-and-load.md) | Load average, `us`/`sy`/`wa`/`st`, per-CPU balance, context switches, steal | Core | High |
| [Memory](memory.md) | `free` and `available`, swap, leaks, the OOM killer and exit 137 | Core | High |
| [Virtual Memory](virtual-memory.md) | Address space, page faults, page cache, overcommit, THP, slab | Advanced | High |
| [Disk I/O](disk-io.md) | `iostat` fields, `await`, `%util`, `aqu-sz`, finding the writer | Core | Med |
| [Limits and File Descriptors](limits-and-file-descriptors.md) | Soft and hard limits, `EMFILE`, `EAGAIN`, systemd and PAM layers | Core | High |
| [Profiling and Tracing](profiling-and-tracing.md) | `strace`, `perf`, eBPF and when to use each | Advanced | Med |
| [Monitoring and Capacity](monitoring-and-capacity.md) | SLI/SLO/SLA, health checks, agent vs agentless, thresholds | Core | Low |
| [Tuning](tuning.md) | `tuned` profiles and `sysctl` tunables | RHCSA | Low |

---

## Scenarios and Labs

- [Server Slow](../interview/scenarios/server-slow.md): the checklist applied end to end
- [Too Many Open Files](../interview/scenarios/too-many-open-files.md): descriptor exhaustion
- [Cannot Fork](../interview/scenarios/cannot-fork.md): recovering with builtins when `fork` fails
