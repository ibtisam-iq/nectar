# Memory

`free` and `/proc/meminfo` show how much memory is truly available, and the OOM killer decides what dies when it runs out. Reading available memory correctly, and reading an OOM report, separates a real leak from healthy cache use.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| available vs free | `available` estimates what a new process can get, including reclaimable cache; `free` is unused | `free -h` |
| buff/cache | Page cache and buffers; reclaimable under pressure, not waste | `free -h`, `/proc/meminfo` |
| Low `free` is normal | Linux uses spare RAM for cache; judge by `available` | `free -h` |
| Swap | Overflow to disk; `si`/`so` in `vmstat` show active paging | `vmstat 1`, `free -h` |
| swappiness | 0 to 200, higher favours swapping anon pages; default 60 | `cat /proc/sys/vm/swappiness` |
| RSS | Resident set: physical RAM a process uses now | `/proc/PID/status` `VmRSS` |
| VSZ | Virtual size: address space reserved, not all backed by RAM | `/proc/PID/status` `VmSize` |
| PSS | Proportional set: RSS with shared pages divided among sharers | `/proc/PID/smaps_rollup` |
| OOM killer | Frees memory by killing a task; picks by `oom_score` | `dmesg`, `/proc/PID/oom_score` |
| oom_score_adj | -1000 (never kill) to 1000 (kill first) | `cat /proc/PID/oom_score_adj` |
| Exit 137 | 128 + 9 (SIGKILL); a container OOM shows this | `echo $?` after a kill |
| Committed_AS | Total memory promised to all processes | `grep Committed /proc/meminfo` |
<!-- --8<-- [end:facts] -->

---

## Reading free

`free` splits memory into used, free and `buff/cache`, but the column that matters is `available`: the kernel's estimate of what a new process could allocate without swapping. Low `free` with high `available` is a healthy system using spare RAM for cache.

```bash
free -h
```

Output:

```text
               total        used        free      shared  buff/cache   available
Mem:           975Mi       371Mi       344Mi       3.4Mi       400Mi       603Mi
Swap:          511Mi          0B       511Mi
```

Here `free` is 344Mi but `available` is 603Mi, because most of `buff/cache` (400Mi) is reclaimable. A monitoring alert on low `free` fires constantly and means nothing; alert on `available` instead.

!!! warning "buff/cache is not wasted memory"
    Page cache holds recently read files so the next read skips the disk. The kernel drops it instantly under pressure, so counting it as used memory makes a well-tuned host look starved.

---

## meminfo and Swap

`/proc/meminfo` is the source `free` summarises, with the reclaimable slab, dirty pages awaiting writeback, and the commit accounting. Swap extends memory onto disk, and `vmstat` `si`/`so` show whether it is actively paging, which is what hurts, rather than merely occupied.

```bash
grep -E 'MemAvailable|Buffers|Cached|SwapTotal|SwapFree|Dirty|AnonPages|SReclaimable|Committed_AS|CommitLimit' /proc/meminfo
cat /proc/sys/vm/swappiness
```

Output:

```text
MemAvailable:     617936 kB
Buffers:           10848 kB
Cached:           371556 kB
SwapTotal:        524284 kB
SwapFree:         524284 kB
Dirty:                 4 kB
AnonPages:        163612 kB
SReclaimable:      27404 kB
CommitLimit:     1023672 kB
Committed_AS:     297508 kB
60
```

Swap that is used but not paging (`si`/`so` near zero) is idle overflow and harmless; constant `si`/`so` is thrashing and slows everything. `swappiness` biases how readily anonymous pages move to swap versus dropping cache.

---

## Finding a Leak

A leak shows as resident memory (RSS) that climbs and never falls across the same process. `/proc/PID/status` gives the totals, and `smaps_rollup` adds PSS, which charges shared library pages only once across sharers.

```bash
MP=$(pgrep -n python3)
grep -E 'VmPeak|VmSize|VmRSS|RssAnon|RssFile|VmSwap' /proc/$MP/status
grep -E 'Rss:|Pss:|Private_Dirty|Shared_Clean' /proc/$MP/smaps_rollup
```

Output:

```text
VmPeak:	   94684 kB
VmSize:	   94684 kB
VmRSS:	   89556 kB
RssAnon:	   84752 kB
RssFile:	    4804 kB
VmSwap:	       0 kB
Rss:               89868 kB
Pss:               88187 kB
Private_Dirty:     84936 kB
Shared_Clean:       1780 kB
```

`VmSize` (VSZ) is 94684 kB of address space, but `VmRSS` of 89556 kB is the RAM actually in use, and `Pss` of 88187 kB is lower still because shared pages are split among users. A real leak grows `RssAnon` and `Private_Dirty` steadily; watch them over time rather than reading one snapshot.

!!! tip "Compare RSS and PSS across processes, not VSZ"
    VSZ counts reserved address space that may never be touched, so it overstates memory. Sum PSS to attribute shared libraries fairly when many copies of a process run.

---

## The OOM Killer

When memory and swap are exhausted, the kernel's OOM killer terminates a task to recover, choosing by `oom_score`, which `oom_score_adj` biases. A cgroup with a memory limit triggers a local OOM even while the host has free RAM.

```bash
mkdir -p /sys/fs/cgroup/oomdemo
echo 80M > /sys/fs/cgroup/oomdemo/memory.max
echo 0 > /sys/fs/cgroup/oomdemo/memory.swap.max
bash -c 'echo $BASHPID > /sys/fs/cgroup/oomdemo/cgroup.procs
         exec python3 -c "b=[]
while True: b.append(bytearray(5*1024*1024))"'; echo "exit=$?"
dmesg | grep -iE 'Killed process|oom-kill:constraint' | tail -2
```

Output:

```text
exit=137
oom-kill:constraint=CONSTRAINT_MEMCG,nodemask=(null),cpuset=/,mems_allowed=0,oom_memcg=/oomdemo,task_memcg=/oomdemo,task=python3,pid=1972,uid=0
Memory cgroup out of memory: Killed process 1972 (python3) total-vm:94744kB, anon-rss:81580kB, file-rss:4828kB, shmem-rss:0kB, UID:0 pgtables:216kB oom_score_adj:0
```

The exit code 137 is 128 + 9, the signature of a SIGKILL, and it is what a container runtime reports when a pod is OOM-killed. The `dmesg` line names the constraint (`CONSTRAINT_MEMCG`, a cgroup limit rather than the whole host), the killed process, and its resident size.

---

## Common Errors

### `Out of memory: Killed process N (name)`

**Cause:** the host ran out of memory and swap; the kernel killed the highest-scoring task to recover.

**Fix:** find the memory consumer with `dmesg` and RSS trends, cap it with a cgroup or fix the leak; raise `oom_score_adj` on tasks that must survive.

### container exits with code 137 and no application error

**Cause:** a cgroup memory limit was hit and the kernel OOM-killed the process, which the runtime reports as 137.

**Fix:** raise the memory limit or reduce the workload's footprint; confirm with `dmesg | grep oom-kill` on the node.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why is low free memory usually not a problem on Linux?"
    **Say first:** Linux uses otherwise-idle RAM for page cache, which is reclaimable, so `available` matters more than `free`.

    **Proof:** `free -h` shows large `buff/cache` and an `available` value well above `free`.

    **Follow-up:** which metric should a memory alert watch? (`available`, or active swap-in.)

??? question "L1: What is the difference between RSS, VSZ and PSS?"
    **Say first:** VSZ is reserved address space, RSS is physical RAM the process holds, and PSS is RSS with shared pages divided among the processes sharing them.

    **Proof:** `/proc/PID/status` for VmSize and VmRSS; `smaps_rollup` for Pss.

    **Follow-up:** why can the sum of RSS across processes exceed physical RAM? (shared pages counted multiple times.)
<!-- --8<-- [end:l1] -->

??? question "L2: Show that a process is leaking memory."
    **Say first:** watch resident and private-dirty memory over time for the same PID.

    **Proof:**

    ```bash
    watch -n5 "grep -E 'VmRSS|RssAnon' /proc/$(pgrep -n app)/status"
    ```

    **Follow-up:** why is VSZ a poor leak signal? (it counts untouched reserved space.)

??? question "L2: A container keeps dying with exit code 137. What is the cause?"
    **Say first:** 137 is 128 plus SIGKILL, the OOM killer hitting the cgroup memory limit.

    **Proof:** `dmesg | grep oom-kill` on the node names the cgroup and process.

    **Follow-up:** how do you keep a critical process from being chosen? (lower its `oom_score_adj`.)

??? question "L3: The host has free RAM but one service is being OOM-killed. Why?"
    **Say first:** the service runs in a cgroup with its own `memory.max`, so it hits a local limit while the host is fine.

    **Proof:** the `dmesg` OOM line shows `CONSTRAINT_MEMCG` and the cgroup path; `cat /sys/fs/cgroup/.../memory.max` shows the cap.

    **Follow-up:** where does systemd set this for a service? (`MemoryMax=` in the unit.)

??? question "L4: How does the kernel decide which process to OOM-kill?"
    **Say first:** it scores every task mainly by memory footprint, adjusted by `oom_score_adj`, and kills the highest score in the constrained scope.

    **Proof:** `/proc/PID/oom_score` and `oom_score_adj`; the `dmesg` report lists candidates and the victim.

    **Don't say:** that it always kills the newest or the largest process by VSZ.

---

## Related

- [Virtual Memory](virtual-memory.md): page cache, faults, overcommit and THP
- [Methodology](methodology.md): memory in the USE table
- [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md): reading the OOM report

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
