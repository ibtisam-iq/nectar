# Virtual Memory

Every process sees a private virtual address space that the kernel maps to physical frames on demand, through page tables, faults and the page cache. Understanding this explains why RSS differs from VSZ, why a `malloc` can succeed and still kill the process later, and why the first read is slow and the second instant.

**Track:** Advanced · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Virtual address space | Per-process, mapped to physical frames lazily | `/proc/PID/maps` |
| Page | Fixed unit of memory, 4 KiB on x86_64 | `getconf PAGE_SIZE` |
| Page table + TLB | Maps virtual to physical; TLB caches recent translations | `/proc/PID/status` `VmPTE` |
| Minor fault | Page mapped without disk I/O (cache hit, zero page) | `/proc/PID/stat`, `time -v` |
| Major fault | Page required a disk read (file or swap-in) | `time -v`, `vmstat` `si` |
| Demand paging | RAM is assigned when a page is first touched, not at allocation | `smaps` after touching |
| RSS vs VSZ | RSS is mapped-and-resident; VSZ is the whole address space | `/proc/PID/status` |
| Overcommit | Kernel may promise more than RAM plus swap | `sysctl vm.overcommit_memory` |
| Committed_AS | Sum of memory promised; compared to `CommitLimit` | `grep Commit /proc/meminfo` |
| Page cache | File pages kept in RAM; `Dirty` awaits writeback | `grep Dirty /proc/meminfo` |
| fsync | Forces dirty pages to stable storage | `strace -e fsync` |
| THP | Transparent huge pages, 2 MiB, reduce TLB misses | `/sys/kernel/mm/transparent_hugepage/enabled` |
| Slab | Kernel object cache (inodes, dentries) | `slabtop -o` |
<!-- --8<-- [end:facts] -->

---

## The Virtual Address Space

A process address space is a set of mappings: code, data, heap, stack, shared libraries and anonymous regions, each mapped to physical frames only when touched. `/proc/PID/status` breaks the total (`VmSize`) into these parts, which is why VSZ overstates real memory.

```bash
MP=$(pgrep -n python3)
grep -E 'VmSize|VmRSS|VmData|VmStk|VmExe|VmPTE|RssAnon|RssFile' /proc/$MP/status
```

Output:

```text
VmSize:	   94684 kB
VmRSS:	   89556 kB
VmData:	   86588 kB
VmStk:	     132 kB
VmExe:	       4 kB
RssAnon:	   84752 kB
RssFile:	    4804 kB
```

`VmData` is the writable heap and data, `VmExe` the tiny executable text, and `RssFile` the file-backed pages (shared libraries) resident now. The heap grows through `brk` for small allocations and `mmap` for large ones, and neither consumes RAM until the pages are written.

---

## Page Faults

A page fault is the trap the CPU raises when a process touches a virtual page with no current mapping. A minor fault is resolved from memory (a zero page, page cache, or copy-on-write), while a major fault needs a disk read, which is orders of magnitude slower.

```bash
/usr/bin/time -v python3 -c "a=bytearray(60*1024*1024)" 2>&1 | grep -E 'resident|page faults'
grep -E '^pgfault|^pgmajfault' /proc/vmstat
```

Output:

```text
	Maximum resident set size (kbytes): 69252
	Major (requiring I/O) page faults: 0
	Minor (reclaiming a frame) page faults: 16232
```

Output:

```text
pgfault 537397
pgmajfault 912
```

Allocating and touching 60 MiB caused 16232 minor faults and zero major faults, because the pages came from the zero page, not disk. Major faults (`pgmajfault`) rising during a slowdown means the working set no longer fits in RAM and the system is paging from swap or re-reading files.

!!! warning "Allocation is a promise; the fault is the cost"
    `malloc` and a large `bytearray` return immediately and grow VSZ, but RAM is charged only when each page is first written and faulted in. This is why a program can allocate successfully and be OOM-killed seconds later while touching those pages.

---

## Page Cache, Dirty Pages and Writeback

Reads and writes to files go through the page cache, so the first read pays a major fault and the second is a memory copy. A write marks pages `Dirty`, and the kernel flushes them to disk asynchronously as writeback, unless `fsync` forces them.

```bash
grep -E 'Cached|Dirty|Writeback|AnonPages' /proc/meminfo
```

Output:

```text
Cached:           371556 kB
Dirty:                 4 kB
Writeback:             0 kB
AnonPages:        163612 kB
```

`Dirty` is data written by applications but not yet on disk, which is why a crash can lose recent writes that were never `fsync`ed. `AnonPages` is memory with no file backing (heap, stack), which can only go to swap, never be dropped like clean cache.

---

## Overcommit

By default the kernel lets processes reserve more virtual memory than physical RAM plus swap, because most reservations are never fully touched. `Committed_AS` tracks the total promised, and `CommitLimit` is the ceiling under strict accounting.

```bash
sysctl vm.overcommit_memory vm.overcommit_ratio
grep -E 'CommitLimit|Committed_AS' /proc/meminfo
```

Output:

```text
vm.overcommit_memory = 0
vm.overcommit_ratio = 50
```

Mode 0 (the default) uses a heuristic; mode 1 always allows; mode 2 refuses allocations past `CommitLimit`, trading some failed allocations for no OOM surprises. Servers that must never OOM sometimes set mode 2, accepting that `malloc` can fail so the killer never runs.

---

## Huge Pages and the Slab

Transparent huge pages back memory with 2 MiB pages instead of 4 KiB, cutting TLB misses for large working sets, at the cost of allocation stalls and fragmentation for some workloads. The slab is the kernel's own object cache, holding structures like inodes and dentries.

```bash
cat /sys/kernel/mm/transparent_hugepage/enabled
slabtop -o -s c | head -8
```

Output:

```text
always [madvise] never
```

Output:

```text
  OBJS ACTIVE  USE OBJ SIZE  SLABS OBJ/SLAB CACHE SIZE NAME
 16575  16575 100%    0.62K    663       25     10608K inode_cache
  3887   3887 100%    1.16K    299       13      4784K ext4_inode_cache
```

The bracket in the THP line marks the active mode: `[madvise]` enables huge pages only for regions that ask via `madvise`, the common default. A large `inode_cache` in `slabtop` is reclaimable kernel memory, not a leak, unless it grows without bound.

!!! tip "Databases often disable transparent huge pages"
    Some latency-sensitive services (several databases) recommend `never`, because THP compaction can pause the process. Check the vendor guidance rather than assuming huge pages always help.

---

## Common Errors

### `cannot allocate memory` from a large `mmap` while `free` shows RAM

**Cause:** strict overcommit (mode 2) refused the reservation because `Committed_AS` would exceed `CommitLimit`, even though physical RAM looks free.

**Fix:** raise `vm.overcommit_ratio`, add swap, or reduce the reservation; confirm the mode with `sysctl vm.overcommit_memory`.

### major page faults spike and latency rises

**Cause:** the working set exceeds RAM, so pages are read from swap or files on every access (thrashing).

**Fix:** add RAM or reduce the footprint; `vmstat` `si`/`so` and `pgmajfault` confirm paging is the cause.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a minor and a major page fault?"
    **Say first:** a minor fault is satisfied from memory (zero page, cache or copy-on-write); a major fault needs a disk read and is far slower.

    **Proof:** `/usr/bin/time -v` reports both counts; `/proc/vmstat` `pgmajfault` tracks major faults system-wide.

    **Follow-up:** which counter rising indicates the system is thrashing? (`pgmajfault` with `vmstat` `si`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Show that allocating memory does not consume RAM until it is touched."
    **Say first:** VSZ grows at allocation, but RSS grows only as pages are written and faulted in.

    **Proof:**

    ```bash
    grep VmRSS /proc/$PID/status   # before and after touching the buffer
    ```

    **Follow-up:** what backs the untouched pages until then? (the shared zero page, copy-on-write.)

??? question "L2: Why is the second read of a file much faster than the first?"
    **Say first:** the first read pays a major fault to load the file into page cache; the second is a memory copy from cache.

    **Proof:** `time cat bigfile >/dev/null` twice; drop caches with `echo 1 > /proc/sys/vm/drop_caches` to see the first cost again.

    **Follow-up:** which `/proc/meminfo` field holds those cached file pages? (`Cached`.)

??? question "L3: A service's latency spikes intermittently and `pgmajfault` climbs. What is happening?"
    **Say first:** the working set has grown past RAM, so accesses fault in from swap or disk, adding disk latency to memory access.

    **Proof:** `vmstat 1` shows `si`/`so`, `/proc/vmstat pgmajfault` rises, `free` shows swap in use.

    **Follow-up:** how would huge pages or more RAM change this? (fewer TLB misses; enough RAM removes the paging entirely.)

??? question "L4: A program calls malloc for 2 GB, it succeeds, then the process is killed. Explain."
    **Say first:** with overcommit, `malloc` only reserves address space and returns success; RAM is charged as each page is first written and faulted in, and if that exceeds RAM plus swap the OOM killer fires.

    **Proof:** VSZ jumps at `malloc`; RSS and `Committed_AS` climb as pages are touched; `dmesg` shows the OOM kill.

    **Don't say:** that `malloc` reserves physical memory up front or that success guarantees the memory is available.

??? question "L4: Walk through what happens when a process touches a never-accessed heap page."
    **Say first:** the CPU raises a page fault, the kernel finds the anonymous mapping, allocates a physical frame (often from the zero page via copy-on-write), updates the page table and TLB, and resumes the instruction.

    **Proof:** the fault counts as minor in `/usr/bin/time -v`; no disk I/O occurs.

    **Don't say:** that touching heap always causes a disk read.

---

## Related

- [Memory](memory.md): `free`, swap, leaks and the OOM killer
- [Disk I/O](disk-io.md): writeback and `fsync` reaching the device
- [Process Lifecycle](../07-processes/process-lifecycle.md): copy-on-write at `fork`
- [Round 4 Internals](../interview/round-4-internals.md): the malloc-to-page-fault walkthrough

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
