# Disk I/O

`iostat` shows whether a disk is the bottleneck, and `iotop` shows which process is driving it. Reading `%util`, `await` and the queue together separates a busy disk from a saturated one.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Tool | `iostat -xz` (extended, skip idle devices), from `sysstat` | `iostat -xz 1` |
| `r/s` `w/s` | Reads and writes completed per second (IOPS) | `iostat -xz 1` |
| `rkB/s` `wkB/s` | Throughput in KB per second | `iostat -xz 1` |
| `r_await` `w_await` | Average ms per read/write, including queue time | `iostat -xz 1` |
| `aqu-sz` | Average queue depth; high means requests are waiting | `iostat -xz 1` |
| `%util` | Fraction of time the device had at least one request | `iostat -xz 1` |
| `%util` caveat | 100% is not saturation on SSDs and arrays that serve in parallel | pair with `aqu-sz` |
| Per-process I/O | `iotop` needs `task_delayacct` enabled | `iotop -o` |
| `iowait` | CPU idle time waiting on I/O; a symptom, not a cause | `iostat`, `vmstat` `wa` |
| First check | `iostat -xz 1`, then find the writer with `iotop` or `pidstat -d` | run in order |
| Deleted open file | Space held by a process still writing to an unlinked file | `lsof +L1` |
<!-- --8<-- [end:facts] -->

---

## Reading iostat

`iostat -xz 1` prints per-device extended statistics each second and hides idle devices. An idle disk shows low `%util` and near-zero `await`, the baseline to compare against under load.

```bash
iostat -xz 1 1
```

Output:

```text
Device            r/s     rkB/s   r_await     w/s     wkB/s   w_await   aqu-sz  %util
vda             20.77    343.27      0.35   11.10    361.25      0.86     0.02   2.98
```

`%util` of 2.98 and `aqu-sz` of 0.02 mean the device is almost always free. The `await` columns are the round-trip time per request, which is what an application actually feels.

---

## A Saturated Disk

Under a heavy writer, the same device shows the signature of saturation: `%util` near 100, a deep queue, and `await` climbing well above idle. The CPU line then shows high `iowait`.

```bash
# a sustained writer on another shell drives this
iostat -xz 1 2 | tail -6
```

Output:

```text
avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.00    0.00    1.01   49.49    0.00   49.49

Device            r/s     rkB/s   r_await     w/s     wkB/s   w_await   aqu-sz  %util
vda              0.00      0.00      0.00 17038.00  69784.00      8.37   142.60  99.60
```

Here `%util` is 99.60, `aqu-sz` is 142.60, and `w_await` has risen to 8.37ms: requests are queuing deep and waiting. The `%iowait` of 49.49 confirms CPUs are idle only because they are blocked on this disk.

!!! warning "iowait is a symptom, not the disk's fault"
    High `%iowait` means CPUs are idle waiting on I/O, which can come from a slow disk, too much concurrency, or `fsync`-heavy code. Confirm with `iostat` `aqu-sz` and `await`, and find the writer before blaming the hardware.

---

## Finding the Process

`iostat` names the device, not the process. `iotop` attributes read and write bandwidth per process, but it needs kernel delay accounting enabled first.

```bash
echo 1 > /proc/sys/kernel/task_delayacct
iotop -b -n2 -d1 -o -k | tail -3
```

Output:

```text
  Total DISK READ:   38.49 K/s |   Total DISK WRITE: 38485.22 K/s
Current DISK READ:    0.00 K/s | Current DISK WRITE: 68602.96 K/s
```

The totals confirm a heavy writer, and the per-process rows (shown with `-o` for active tasks) name it. `pidstat -d 1` gives the same per-process view without delay accounting and works well in scripts.

!!! tip "Use pidstat -d when iotop is unavailable"
    `iotop` needs a terminal and delay accounting, which is awkward in scripts and minimal images. `pidstat -d 1` reports per-process read and write rates from the same counters and runs headless.

---

## Common Errors

### `iotop` prints `CONFIG_TASK_DELAY_ACCT not enabled`

**Cause:** per-process I/O accounting is off, so `iotop` cannot attribute bandwidth.

**Fix:** enable it with `echo 1 > /proc/sys/kernel/task_delayacct`, or use `pidstat -d 1`, which does not need it.

### disk shows `%util` 100 but latency is fine

**Cause:** SSDs and RAID arrays serve many requests in parallel, so `%util` reaches 100 while still keeping up.

**Fix:** judge saturation by `await` and `aqu-sz` rising, not by `%util` alone.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does %util mean in iostat, and why can it mislead?"
    **Say first:** `%util` is the fraction of time the device had at least one request in flight; on SSDs and arrays that serve requests in parallel, 100% does not mean saturated.

    **Proof:** `iostat -xz 1` with `%util` at 100 but low `aqu-sz` and `await` is still healthy.

    **Follow-up:** which two fields better indicate saturation? (`aqu-sz` and `await`.)
<!-- --8<-- [end:l1] -->

??? question "L2: The disk is suspected slow. Show it and name the process."
    **Say first:** confirm saturation with extended iostat, then attribute bandwidth per process.

    **Proof:**

    ```bash
    iostat -xz 1        # aqu-sz, await, %util
    pidstat -d 1        # per-process read/write
    ```

    **Follow-up:** why is `iotop` sometimes empty even under load? (delay accounting is off, or the writer is short-lived.)

??? question "L2: iowait is high but the application is not doing much disk work. What else could it be?"
    **Say first:** another process, a background flush, or swap paging can drive the disk while your application waits behind it.

    **Proof:** `iostat -xz 1` shows the busy device; `pidstat -d 1` names the real writer; `vmstat` `si`/`so` reveals swap.

    **Follow-up:** how does deep concurrency raise `await` without a hardware fault? (requests queue, adding wait time per request.)

??? question "L3: Disk usage keeps growing but du finds nothing. What is happening?"
    **Say first:** a process is writing to a file that was deleted while still open, so the space is held until the process closes it.

    **Proof:** `lsof +L1` lists open files with a link count of zero and their sizes.

    **Follow-up:** how do you reclaim the space without killing the process? (truncate the fd via `/proc/PID/fd`, or restart the service.)

??? question "L2: Confirm iowait is caused by a specific disk and process."
    **Say first:** find the busy device, then the process driving it.

    **Proof:** `iostat -xz 1` for the device with high `%util` and `await`; `pidstat -d 1` for the process.

    **Follow-up:** why is `iostat` alone not enough to blame an application? (it names the device, not the process.)

??? question "L4: Why can a disk read 100% util yet still not be the bottleneck?"
    **Say first:** SSDs and RAID arrays serve many requests in parallel, so `%util` (time with at least one request in flight) saturates while latency stays low.

    **Proof:** `%util` 100 with a small `aqu-sz` and flat `await` is healthy; a rising queue and `await` is real saturation.

    **Don't say:** that `%util` 100 always means the disk cannot keep up.

---

## Related

- [Methodology](methodology.md): disk in the USE table
- [Virtual Memory](virtual-memory.md): writeback, dirty pages and `fsync`
- [Disk Usage](../12-storage/disk-usage.md): `df`, `du` and deleted-but-open files
- [Server Slow](../interview/scenarios/server-slow.md): disk as one branch of a slow host

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
