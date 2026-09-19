# dmesg and Kernel Messages

The kernel writes driver, memory and hardware events to its ring buffer, which `dmesg` and `journalctl -k` read. OOM kills, segfaults, I/O errors and hung tasks all leave a kernel line, often the only record of why a process died.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Ring buffer | Fixed size; old messages are overwritten; the journal keeps a copy | `dmesg` |
| Readable times | `dmesg -T` (can drift after suspend); `journalctl -k` has real timestamps | `dmesg -T` |
| Filter by level | `dmesg -l err,warn`; `journalctl -k -p warning` | `dmesg -l err` |
| Show level and facility | `dmesg -x` | `dmesg -x` |
| Follow | `dmesg -w`, `journalctl -kf` | New messages appear |
| Previous boot | Only the journal: `journalctl -k -b -1` | `journalctl --list-boots` |
| Access | `kernel.dmesg_restrict = 1` limits `dmesg` to root (0 on both playgrounds) | `sysctl kernel.dmesg_restrict` |
| Console level | `kernel.printk`: messages below the first number reach the console | `sysctl kernel.printk` |
| OOM kill | `Out of memory: Killed process` or `Memory cgroup out of memory` | `journalctl -k -g "Killed process"` |
| Segfault | `<prog>[pid]: segfault at <addr> ip ... error N in <binary>` | `journalctl -k -g segfault` |
| I/O error | `Buffer I/O error on dev ...`, `I/O error, dev sdb, sector ...` | `dmesg -l err` |
| Hung task | `INFO: task <name>:<pid> blocked for more than N seconds` | `sysctl kernel.hung_task_timeout_secs` |
| Core dumps | `systemd-coredump` stores them; `coredumpctl list`, `info`, `debug` | `sysctl kernel.core_pattern` |
<!-- --8<-- [end:facts] -->

---

## Reading the Ring Buffer

```bash
dmesg --version; sysctl kernel.printk kernel.core_pattern
dmesg -T | tail -3
dmesg -l err,warn | head -5
```

Output:

```text
dmesg from util-linux 2.40.2
kernel.printk = 7	4	1	7
kernel.core_pattern = |/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %h %d %F
[Thu Sep 17 05:48:37 2026] systemd-journald[2507]: Collecting audit messages is disabled.
[Thu Sep 17 05:48:37 2026] systemd[1]: Started systemd-journald.service - Journal Service.
[Thu Sep 17 05:52:34 2026] sctp: Hash tables configured (bind 256/256)
[    0.000000] [Firmware Bug]: TSC doesn't count with P0 frequency!
[    0.184695] SELinux: CONFIG_SECURITY_SELINUX_CHECKREQPROT_VALUE is non-zero.  This is deprecated and will be rejected in a future kernel release.
[    0.184695] SELinux: https://github.com/SELinuxProject/selinux-kernel/wiki/DEPRECATE-checkreqprot
[    0.790086] software IO TLB: No low mem
```

Without `-T`, the number in brackets is seconds since boot. The core pattern pipes crashes to `systemd-coredump`.

!!! warning "The ring buffer does not survive a reboot"
    After an unexpected reboot, `dmesg` holds only the new boot's messages. Use `journalctl -k -b -1` (with a persistent journal) or a serial or network console for panics that never reached the disk.

---

## Segmentation Faults and Core Dumps

A program that dereferences a NULL pointer is killed with `SIGSEGV`; the shell reports exit status 139 (128 + 11), and the kernel logs the address and binary.

```bash
/usr/local/bin/parse-config; echo "exit=$?"
dmesg | tail -2
coredumpctl info parse-config --no-pager | sed -n "1,20p"
```

Output:

```text
parsing config
/root/c/d1.sh: line 2:  4369 Segmentation fault      (core dumped) /usr/local/bin/parse-config
exit=139
[  733.285906] parse-config[4369]: segfault at 0 ip 0000000000401163 sp 00007ffd294110a0 error 6 in parse-config[401000+1000] likely on CPU 1 (core 1, socket 0)
[  733.287276] Code: e5 48 83 ec 10 48 c7 45 f8 00 00 00 00 bf 10 20 40 00 e8 e0 fe ff ff 48 8b 05 c1 2e 00 00 48 89 c7 e8 e1 fe ff ff 48 8b 45 f8 <c7> 00 2a 00 00 00 b8 00 00 00 00 c9 c3 f3 0f 1e fa 48 83 ec 08 48
           PID: 4369 (parse-config)
           UID: 0 (root)
           GID: 0 (root)
        Signal: 11 (SEGV)
     Timestamp: Thu 2026-09-17 05:55:22 UTC (20s ago)
  Command Line: /usr/local/bin/parse-config
    Executable: /usr/local/bin/parse-config
 Control Group: /user.slice/user-0.slice/session-c33.scope
          Unit: session-c33.scope
         Slice: user-0.slice
       Session: c33
     Owner UID: 0 (root)
       Boot ID: 9977b4c094c543d1adee466cf7cd4b89
    Machine ID: 0edc75cd1dd1440c9cb5984b45402cdb
      Hostname: rocky-01
       Storage: /var/lib/systemd/coredump/core.parse-config.0.9977b4c094c543d1adee466cf7cd4b89.4369.1789624522000000.zst (present)
  Size on Disk: 15.7K
       Message: Process 4369 (parse-config) of user 0 dumped core.
                
                Stack trace of thread 4369:
```

| Part of the segfault line | Meaning |
|---|---|
| `segfault at 0` | The faulting address: 0 is a NULL pointer |
| `ip 0000000000401163` | Instruction pointer at the fault |
| `error 6` | Page-fault flags: 4 user mode + 2 write, page not present |
| `in parse-config[401000+1000]` | The binary (or library) and its mapped range |

With debug symbols, the core dump points to the source line:

```bash
coredumpctl debug parse-config --debugger-arguments="-batch -ex bt" 2>&1 | tail -3
```

Output:

```text
#0  0x0000000000401163 in main () at /root/c/crash.c:6
6	    *p = 42;
#0  0x0000000000401163 in main () at /root/c/crash.c:6
```

---

## The OOM Killer

When memory runs out, in the whole system or in a cgroup, the kernel kills a process and logs a report. The service below has a 64 MiB limit and allocates in a loop. As root:

```bash
systemd-run --unit=leaky -p MemoryMax=64M -p MemorySwapMax=0 /usr/bin/python3 -c "b=[]
while True: b.append(bytearray(8*1024*1024))"; sleep 3; systemctl status leaky --no-pager | sed -n "1,4p"
dmesg | grep -E "oom|Killed process|Memory cgroup" | tail -4
dmesg | grep -A3 "invoked oom-killer" | head -8
```

Output:

```text
Running as unit: leaky.service; invocation ID: 8d5e080257154e46807e97a8d3cabafb
× leaky.service - [systemd-run] /usr/bin/python3 -c "b=[]\nwhile True: b.append(bytearray(8*1024*1024))"
     Loaded: loaded (/run/systemd/transient/leaky.service; transient)
  Transient: yes
     Active: failed (Result: oom-kill) since Thu 2026-09-17 05:55:22 UTC; 2s ago
[  733.453455] Memory cgroup stats for /system.slice/leaky.service:
[  733.462739] [  pid  ]   uid  tgid total_vm      rss pgtables_bytes swapents oom_score_adj name
[  733.464394] oom-kill:constraint=CONSTRAINT_MEMCG,nodemask=(null),cpuset=/,mems_allowed=0,oom_memcg=/system.slice/leaky.service,task_memcg=/system.slice/leaky.service,task=python3,pid=4383,uid=0
[  733.465913] Memory cgroup out of memory: Killed process 4383 (python3) total-vm:78352kB, anon-rss:65184kB, file-rss:5304kB, shmem-rss:0kB, UID:0 pgtables:192kB oom_score_adj:0
[  733.436988] python3 invoked oom-killer: gfp_mask=0xcc0(GFP_KERNEL), order=0, oom_score_adj=0
[  733.437830] CPU: 3 PID: 4383 Comm: python3 Not tainted 6.1.167 #1
[  733.438419] Call Trace:
[  733.438671]  <TASK>
```

`constraint=CONSTRAINT_MEMCG` says the limit of a cgroup was reached, not the host's memory; a host-wide OOM shows `CONSTRAINT_NONE` and `Out of memory: Killed process`. systemd records the result as `oom-kill`, and a container runtime reports exit code 137 for the same event.

---

## I/O Errors and Hung Tasks

A device-mapper `error` target returns an error for every read, which reproduces the messages a failing disk produces. A frozen filesystem reproduces a hung task.

```bash
dmsetup create baddisk --table "0 20480 error"; ls -l /dev/mapper/baddisk
dd if=/dev/mapper/baddisk of=/dev/null bs=4k count=1
dmesg | tail -3
```

Output:

```text
lrwxrwxrwx 1 root root 7 Sep 17 05:55 /dev/mapper/baddisk -> ../dm-0
dd: error reading '/dev/mapper/baddisk': Input/output error
0+0 records in
0+0 records out
0 bytes copied, 0.000602384 s, 0.0 kB/s
[  753.852390] Code: e5 48 83 ec 10 48 c7 45 f8 00 00 00 00 bf 10 20 40 00 e8 e0 fe ff ff 48 8b 05 c1 2e 00 00 48 89 c7 e8 e1 fe ff ff 48 8b 45 f8 <c7> 00 2a 00 00 00 b8 00 00 00 00 c9 c3 f3 0f 1e fa 48 83 ec 08 48
[  754.045959] Buffer I/O error on dev dm-0, logical block 2544, async page read
[  754.051985] Buffer I/O error on dev dm-0, logical block 0, async page read
```

The hung task detector reports a task stuck in `D` state longer than `kernel.hung_task_timeout_secs` (120 by default, lowered to 10 for this demo). The loop-mounted image is the one used in [Process States](../07-processes/process-states.md):

```bash
mountpoint /mnt/frz || mount -o loop /var/tmp/frz.img /mnt/frz; sysctl -w kernel.hung_task_timeout_secs=10; fsfreeze -f /mnt/frz; (nohup sh -c 'echo data > /mnt/frz/report.csv' >/dev/null 2>&1 </dev/null &); sleep 25; dmesg | tail -12
dmesg | grep -A12 "blocked for more than" | head -16; fsfreeze -u /mnt/frz; sleep 1; cat /mnt/frz/report.csv; umount /mnt/frz; sysctl -w kernel.hung_task_timeout_secs=120
```

Output:

```text
/mnt/frz is not a mountpoint
kernel.hung_task_timeout_secs = 10
# ... (trimmed: the last 12 lines of the same report)
[  785.811762] INFO: task sh:4577 blocked for more than 10 seconds.
[  785.812355]       Not tainted 6.1.167 #1
[  785.812727] "echo 0 > /proc/sys/kernel/hung_task_timeout_secs" disables this message.
[  785.813462] task:sh              state:D stack:0     pid:4577  ppid:1      flags:0x00000002
[  785.814228] Call Trace:
[  785.814475]  <TASK>
[  785.814687]  __schedule+0x1e7/0x5f0
[  785.815032]  schedule+0x61/0xb0
[  785.815342]  percpu_rwsem_wait+0x118/0x140
[  785.815747]  ? __percpu_rwsem_trylock.part.0+0x60/0x60
[  785.816233]  __percpu_down_read+0x6a/0x130
[  785.816616]  mnt_want_write+0x98/0xc0
[  785.816973]  open_last_lookups+0x2cb/0x3b0
--
[  796.051737] INFO: task sh:4577 blocked for more than 20 seconds.
[  796.052362]       Not tainted 6.1.167 #1
data
kernel.hung_task_timeout_secs = 120
```

After `fsfreeze -u`, the blocked write completed. The stack names the wait (`mnt_want_write` on a frozen filesystem); on real hosts the same message usually names NFS, a storage driver or a stuck block device. `Not tainted` means no proprietary or out-of-tree module was loaded.

!!! note "Kernel messages point to hardware before monitoring does"
    Repeated `I/O error` or `blk_update_request` lines for one device usually precede a disk failure; check `smartctl -a` and plan the replacement before the filesystem remounts read-only.

---

## Common Errors

### `dmesg: read kernel buffer failed: Operation not permitted`

**Cause:** `kernel.dmesg_restrict = 1` and the user is not root. Not reproduced here, because both playgrounds set 0.

**Fix:** `sudo dmesg`, or `journalctl -k` as a member of `adm` or `systemd-journal`.

### `Buffer I/O error on dev dm-0, logical block 0, async page read`

**Cause:** The block device returned an error for a read.

**Fix:** Identify the device (`lsblk`, `dmsetup ls`), check hardware health, and restore from backup if the errors persist.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: A process disappeared without an error in its own log. Where do you look?"
    **Say first:** The kernel log, for an OOM kill or a segfault.

    **Proof:** `journalctl -k -g "Killed process|segfault"`; `dmesg -T | grep -i oom`.

    **Follow-up:** How do you tell a cgroup OOM from a host OOM?

??? question "L1: What is the difference between dmesg and journalctl -k?"
    **Say first:** `dmesg` reads the current ring buffer; `journalctl -k` reads the kernel messages the journal stored, with real timestamps and earlier boots.

    **Proof:** `journalctl -k -b -1`

    **Follow-up:** Why can `dmesg -T` show the wrong time?
<!-- --8<-- [end:l1] -->

??? question "L2: Read the segfault line and find the faulting source line."
    **Say first:** The address and flags come from the kernel line; the source line comes from the core dump with debug symbols.

    **Proof:** `journalctl -k -g segfault`; `coredumpctl debug <prog>` and `bt` in gdb.

    **Follow-up:** What does `segfault at 0` usually mean?

??? question "L2: Show only warnings and errors from the kernel, with readable times, and keep following."
    **Say first:** Filter by level and follow.

    **Proof:** `dmesg -T -l err,warn -w`

    **Follow-up:** What is the journal equivalent? (`journalctl -kf -p warning`.)

??? question "L2: A container exited with code 137. Confirm the cause."
    **Say first:** 137 is 128 + 9, a `SIGKILL`; check the kernel log for an OOM kill in the container's cgroup.

    **Proof:** `journalctl -k -g "Memory cgroup out of memory"`; `docker inspect -f '{{.State.OOMKilled}}' <id>`.

    **Follow-up:** Which limit triggered it? (`memory.max` of the container's cgroup.)

??? question "L3: Applications on a server hang, and load average rises while CPU is idle. What do the kernel messages tell you?"
    **Say first:** Look for hung task warnings and I/O errors that name the device or filesystem the tasks wait on.

    **Proof:** `dmesg -T | grep -E "blocked for more than|I/O error|nfs: server"`; the stack in the hung task report.

    **Follow-up:** Why does `kill -9` not remove those tasks?

??? question "L3: A server rebooted and dmesg shows nothing about the cause. Where else can the kernel's last words be?"
    **Say first:** The previous boot's journal, a serial or network console, or a kdump crash dump.

    **Proof:** `journalctl -k -b -1 -n 50`; `ls /var/crash`; the hypervisor's console log.

    **Follow-up:** Why can a panic leave nothing in the journal? (The disk write never happened.)

---

## Related

- [journalctl](../09-logging/journalctl.md): `-k`, `-b -1` and priorities
- [Process States](../07-processes/process-states.md): `D` state and load average
- [Signals](../07-processes/signals.md): `SIGSEGV` and `SIGKILL`
- [sysctl](sysctl.md): `kernel.printk`, `hung_task_timeout_secs`, `dmesg_restrict`

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
