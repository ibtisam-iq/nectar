# High Memory and OOM

A host is low on memory, or a process keeps dying with exit 137. The interviewer watches whether the candidate reads `available` rather than `free`, finds the consumer, and recognises the OOM killer, including the container case where a cgroup limit fires.

---

## Symptom

> "This service keeps getting killed with exit code 137, and the box looks low on memory. Find out why."

---

## Clarifying Questions

- **Is it the whole host or one container?** A container's exit 137 usually means its cgroup `memory.max`, not host memory.
- **Is memory climbing steadily or spiking under load?** A steady climb is a leak; a spike at peak is undersizing.
- **What does the app do at the time it dies?** A batch or a request pattern may correlate with the growth.
- **Has anything changed, in the app or its memory limit?** A new version or a lowered limit lines up with the onset.

---

## Diagnostic Path

Exit 137 is 128 plus SIGKILL (9), the signal the OOM killer sends. The first job is to confirm memory pressure, then find the consumer, then read the kernel's verdict.

### 1. Read Real Available Memory

```bash
free -h | head -2
```

Output:

```text
               total        used        free      shared  buff/cache   available
Mem:           975Mi       525Mi       105Mi        18Mi       507Mi       449Mi
```

Judge by `available`, not `free`: `free` is low because `buff/cache` holds reclaimable page cache. When `available` also falls toward zero, the host is under real pressure, covered in [Memory](../../17-performance-and-troubleshooting/memory.md).

### 2. Find the Consumer

```bash
ps -eo pid,user,rss,vsz,comm --sort=-rss | head -4
```

Output:

```text
    PID USER       RSS    VSZ COMMAND
    755 root     151572 1381076 examiner
   4241 laborant 130612 135772 python3
    864 root      26856 256560 tuned
```

`RSS` is the resident memory a process actually holds, so sorting by it names the largest consumers. Watching a suspect's `VmRSS` in `/proc/PID/status` over time separates a leak (steady climb) from a process that is large but stable.

### 3. Read the OOM Killer's Verdict

```bash
sudo dmesg | grep -iE 'Out of memory|Killed process' | tail -1
```

Output:

```text
Memory cgroup out of memory: Killed process 1968 (python3) total-vm:94796kB, anon-rss:81328kB, file-rss:4924kB, shmem-rss:0kB, UID:0 pgtables:224kB oom_score_adj:0
```

`Memory cgroup out of memory` means a cgroup hit its `memory.max`, which is the container case: the process was killed at its limit, not because the host ran out. A host-level OOM instead reads `Out of memory: Killed process`. `memory.events` in the cgroup confirms it.

```bash
cat /sys/fs/cgroup/<path>/memory.events | grep '^oom'
```

Output:

```text
oom 1
oom_kill 1
```

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Container hit its limit | `Memory cgroup out of memory`, exit 137, `oom_kill` in `memory.events` | Raise `memory.max` if legitimate, or fix the leak |
| Application leak | RSS climbs steadily over time | Fix the leak; a higher limit only delays it |
| Undersized limit | RSS stable but above a low limit | Raise the memory request/limit to real usage |
| Host out of memory | `Out of memory: Killed process` (no cgroup) | Add RAM, add swap, or reduce load |
| No swap, spiky load | `available` hits zero at peaks, no `si`/`so` | Add swap headroom or cap the spiky worker |

---

## Fix

For a container killed at its limit, decide between raising the limit and fixing the cause using the RSS trend. A steady climb is a leak that a higher limit will not cure; a stable process above a low limit is undersizing.

```bash
# container: raise the limit only if usage is legitimate
podman update --memory 512m <container>
# or in Kubernetes, raise the pod's memory limit to real peak usage
```

If the trend shows a leak, the fix is in the application, not the limit. Buying headroom with a higher limit only moves the next kill later.

---

## Prevention

- Alert on `available` memory and on cgroup `memory.events` `oom_kill`, not on `free`.
- Set container memory limits to real peak usage plus headroom, informed by observed RSS.
- Watch RSS trends so a leak is caught as a slope, before it reaches the limit.

---

## Related

- [Memory](../../17-performance-and-troubleshooting/memory.md): `available` vs `free`, the OOM killer, exit 137
- [Cgroups](../../19-containers/cgroups.md): `memory.max`, `memory.events` and the cgroup OOM
- [Virtual Memory](../../17-performance-and-troubleshooting/virtual-memory.md): RSS vs VSZ and page reclaim
- [Process States](../../07-processes/process-states.md): signals and exit codes

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The OOM was produced with a memory-limited cgroup and a controlled allocator.
