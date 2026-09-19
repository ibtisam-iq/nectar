# High Load, Low CPU

Load average is high but the CPUs are idle, which rules out CPU saturation and points at uninterruptible sleep. The interviewer watches whether the candidate knows load counts `D`-state tasks, and can trace them to blocked I/O such as a hung NFS mount.

---

## Symptom

> "Load average is 40 on this box but top shows the CPUs almost idle. What is going on?"

---

## Clarifying Questions

- **What is the core count?** Load must be read against `nproc`; 40 means different things on 4 cores and 64.
- **Any network storage mounted?** A hung NFS or iSCSI mount is the classic cause of high load with idle CPUs.
- **When did it start, and did anything change on the storage or network?** A server outage or firewall change lines up with the onset.
- **Are commands hanging too?** A command that touches the stuck mount will itself block, which confirms the direction.

---

## Diagnostic Path

Load average counts runnable tasks plus tasks in uninterruptible sleep (`D`), so high load with idle CPUs means processes are blocked, not computing. Run the checks on the affected host.

### 1. Confirm Load Is High but CPU Idle

```bash
uptime
vmstat 1 2 | tail -1
```

Output:

```text
 06:33:53 up 6 min,  0 user,  load average: 0.74, 0.38, 0.15
 0  0      0 666604   9960 108956    0    0     0     0   63   51  0  0 100  0  0  0
```

Load is rising across the windows, but `vmstat` shows `id` at 100 and the run queue `r` at 0. The CPUs are idle, so the load is coming from tasks that are not runnable, which means uninterruptible sleep.

### 2. Find the D-State Tasks

```bash
ps -eo pid,stat,wchan:20,comm | awk '$2 ~ /^D/'
```

Output:

```text
   1576 D    rpc_wait_bit_killabl dd
```

The task is in `D` state, and its wait channel `rpc_wait_bit_killable` names an NFS RPC wait. A `D` task consumes no CPU but counts toward load, which is exactly the reported pattern.

### 3. Confirm the Cause in the Kernel Stack

```bash
sudo cat /proc/1576/stack | head -3
```

Output:

```text
[<0>] rpc_wait_bit_killable+0x11/0x80
[<0>] __rpc_execute+0x17e/0x320
[<0>] nfs4_call_sync_sequence+0x74/0xb0 [nfsv4]
```

The `nfsv4` frames confirm the process is blocked inside an NFS call. The next check is whether the NFS server is reachable, with `showmount -e <server>` or a ping, covered in [NFS](../../18-network-storage/nfs.md).

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Hung NFS mount | `D` tasks, `rpc_wait_bit_killable`, `nfsv4` in stack | Restore the server or network; remount |
| iSCSI/SAN path down | `D` tasks blocked on block I/O, SCSI errors in `dmesg` | Restore the path; check multipath |
| Failing local disk | `D` tasks, I/O errors in `dmesg`, high `await` in `iostat` | Replace the disk; check SMART |
| Heavy uninterruptible I/O | Many `D` tasks under a real I/O storm | Throttle the writer; see [Disk I/O](../../17-performance-and-troubleshooting/disk-io.md) |

---

## Fix

For the NFS case, the blocked processes cannot be killed while the mount hangs, so the fix is to restore the server or network path. Once the server answers, the `D` tasks complete and load falls.

```bash
showmount -e 172.16.1.3          # is the server answering again?
# restore the server or firewall rule, then:
sudo umount -f /mnt/nfs || sudo umount -l /mnt/nfs   # force or lazy if still stuck
```

A `hard` mount blocks forever by design, so `kill -9` does nothing until the RPC returns. A lazy unmount detaches the tree so new access does not block, while existing blocked tasks clear when the server responds.

---

## Prevention

- Mount network filesystems with `_netdev` and `nofail`, and consider `soft` with a timeout for non-critical data.
- Alert on `D`-state task count and on load relative to `nproc`, not on CPU alone.
- Monitor NFS server reachability, so a storage outage is caught before it drives client load.

---

## Related

- [NFS](../../18-network-storage/nfs.md): the hung-mount signature and hard vs soft
- [Process States](../../07-processes/process-states.md): why `D` cannot be killed and counts toward load
- [CPU and Load](../../17-performance-and-troubleshooting/cpu-and-load.md): load average including uninterruptible tasks
- [Disk I/O](../../17-performance-and-troubleshooting/disk-io.md): the local-disk branch

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The hang was produced by dropping NFS traffic to the server.
