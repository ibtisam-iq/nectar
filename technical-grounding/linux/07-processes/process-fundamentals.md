# Process Fundamentals

A process is a running instance of a program: an address space, one or more threads, open files, credentials and a PID. Every command, service and container on a Linux host is a process in one tree rooted at PID 1, so reading that tree is the first step of most troubleshooting.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Program vs process | A program is a file on disk; a process is a running instance with its own PID and memory | `ps -C sleep` |
| PID | Unique number for a running process; reused after the process is reaped | `echo $$` |
| PPID | PID of the parent that created the process | `ps -o pid,ppid -p $$` |
| PID 1 | `systemd` on RHEL and Ubuntu; adopts orphans and cannot be killed by a stray signal | `ps -p 1 -o comm` |
| PID 2 | `kthreadd`, parent of every kernel thread (shown in `[brackets]`) | `ps -o ppid,comm --ppid 2` |
| PID limit | `kernel.pid_max`, 4194304 on 64-bit systems with systemd | `cat /proc/sys/kernel/pid_max` |
| Thread | A task that shares memory and file descriptors with its process; has its own TID | `ps -T -p <pid>` |
| Thread count | `NLWP` column, `Threads:` in `/proc/<pid>/status` | `ps -o nlwp -p <pid>` |
| `$$` vs `$BASHPID` | `$$` stays the script's PID in subshells; `$BASHPID` is the current process | `( echo $$ $BASHPID )` |
| `/proc/<pid>/` | Kernel view of one process: `status`, `cmdline`, `exe`, `cwd`, `fd/`, `environ`, `maps` | `ls /proc/$$` |
| Other users' processes | `cwd`, `exe`, `fd/` and `environ` are readable only by the owner or root | `ls -l /proc/1/cwd` |
| Process tree | `pstree -p`, `ps -ef --forest`, `systemd-cgls` | `pstree -p 1` |
| Process credentials | Real, effective, saved and filesystem UID and GID, stored per process | `grep Uid /proc/$$/status` |
<!-- --8<-- [end:facts] -->

---

## Program vs Process

One program file can run as many processes at once; each has its own PID, memory and state. The kernel records where each process came from in `/proc/<pid>/exe` and `/proc/<pid>/cmdline`.

```bash
sleep 300 &
sleep 300 &
ps -o pid,ppid,stat,comm,args -C sleep
readlink /proc/1704/exe
tr '\0' ' ' < /proc/1704/cmdline; echo
```

Output:

```text
    PID    PPID STAT COMMAND         COMMAND
   1704    1703 S    sleep           sleep 300
   1705    1703 S    sleep           sleep 300
/usr/bin/sleep
sleep 300
```

Both processes run `/usr/bin/sleep` and share the parent `1703`, the shell that started them. `comm` is the 15-character name the kernel stores; `args` is the full command line.

!!! note "Deleting the program file does not stop the process"
    A running process holds a reference to its executable. After `rm` or a package upgrade, `readlink /proc/<pid>/exe` ends in `(deleted)`, and the old version keeps running until the process restarts.

---

## PIDs and the Process Tree

Every process except PID 0 (the kernel's idle task) has a parent. `systemd` is PID 1 and starts user space; `kthreadd` is PID 2 and starts kernel threads.

```bash
ps -o pid,ppid,comm -p 1,2
ps -o pid,ppid,comm --ppid 2 | head -5
ps -eo comm= --ppid 2 | wc -l
cat /proc/sys/kernel/pid_max
```

Output:

```text
    PID    PPID COMMAND
      1       0 systemd
      2       0 kthreadd
    PID    PPID COMMAND
      3       2 rcu_gp
      4       2 rcu_par_gp
      5       2 slub_flushwq
      6       2 netns
118
4194304
```

`pstree` draws the same parent links; `-p` adds PIDs and `-A` uses ASCII lines.

```bash
pstree -p -A 1 | head -12
```

Output:

```text
systemd(1)-+-agetty(935)
           |-agetty(936)
           |-crond(933)
           |-dbus-broker-lau(934)---dbus-broker(944)
           |-examiner(843)-+-su(1653)---bash(1668)---bash(1703)-+-head(1721)
           |               |                                    |-pstree(1720)
           |               |                                    |-sleep(1704)
           |               |                                    `-sleep(1705)
           |               |-{examiner}(847)
           |               |-{examiner}(848)
           |               |-{examiner}(849)
           |               |-{examiner}(850)
```

Names in braces, such as `{examiner}`, are threads of the process above them. On this playground `examiner` is the agent that runs the capture shell, so the shell's ancestry goes through it instead of `sshd`.

!!! tip "Walk up the tree to explain a mystery process"
    `ps -o ppid= -p <pid>` repeated until PID 1, or `pstree -s -p <pid>`, shows which service or session started a process. A PPID of 1 means the original parent exited and `systemd` adopted it.

---

## The Shell's Own PID

Commands in parentheses and pipelines run in subshells, which are separate processes. `$$` still expands to the top-level shell's PID there, so scripts that write PID files from a subshell must use `$BASHPID`.

```bash
echo "$$ $BASHPID"; ( echo "subshell: $$ $BASHPID" )
```

Output:

```text
1703 1703
subshell: 1703 1706
```

---

## Reading /proc/PID

`/proc/<pid>/status` is the readable summary; the other files expose one aspect each.

```bash
grep -E '^(Name|State|Pid|PPid|Uid|Threads|VmRSS)' /proc/1704/status
```

Output:

```text
Name:	sleep
State:	S (sleeping)
Pid:	1704
PPid:	1703
Uid:	1001	1001	1001	1001
VmRSS:	    1012 kB
Threads:	1
```

The four `Uid` columns are the real, effective, saved and filesystem UIDs. They differ for SUID programs and for daemons that drop privileges after starting as root.

| File | Contents |
|---|---|
| `status` | Name, state, PPID, UIDs, memory, threads, signal masks |
| `cmdline` | Arguments separated by NUL bytes |
| `exe` | Symlink to the executable |
| `cwd` | Symlink to the working directory |
| `fd/` | One symlink per open file descriptor |
| `environ` | Environment at `exec` time, NUL-separated |
| `maps` | Memory mappings: binary, libraries, heap, stack |
| `limits` | Resource limits (`ulimit`) in effect |
| `cgroup` | Control group, which names the systemd unit |
| `task/` | One directory per thread |

Access to the sensitive entries is checked against the process owner:

```bash
ls -l /proc/$(pgrep -o nginx)/cwd
sudo ls -l /proc/$(pgrep -o nginx)/cwd
```

Output:

```text
ls: cannot read symbolic link '/proc/2102/cwd': Permission denied
lrwxrwxrwx 1 root root 0 Sep 16 19:00 /proc/2102/cwd
lrwxrwxrwx 1 root root 0 Sep 16 19:00 /proc/2102/cwd -> /
```

---

## Threads

Linux creates threads and processes with the same system call, `clone()`, and the flags decide what the new task shares. A thread shares memory, file descriptors and signal handlers with its process; `ps` groups threads under the thread group ID, which is the PID.

```bash
python3 -c "import threading,time,os; [threading.Thread(target=time.sleep,args=(60,),daemon=True).start() for _ in range(3)]; p=os.getpid(); print(p, flush=True); os.system(\"ls /proc/%d/task; ps -T -o pid,spid,comm -p %d\" % (p, p))"
```

Output:

```text
1802
1802
1803
1804
1805
    PID    SPID COMMAND
   1802    1802 python3
   1802    1803 python3
   1802    1804 python3
   1802    1805 python3
```

| | Process | Thread |
|---|---|---|
| **Memory** | Own address space | Shared with the process |
| **File descriptors** | Own table (copied at `fork`) | Shared |
| **Identifier** | PID (TGID) | TID, shown as `SPID` or `LWP` |
| **Crash impact** | Only that process | The whole process dies |
| **Created by** | `fork()` / `clone()` without sharing flags | `pthread_create()` / `clone(CLONE_VM ...)` |

`top -H` and `ps -eLf` list threads individually, which finds the one thread burning CPU in a Java or Go service.

```bash
ps -eLf | head -1; ps -eLf | grep -m3 [e]xaminer
```

Output:

```text
UID          PID    PPID     LWP  C NLWP STIME TTY          TIME CMD
root         843       1     843  0    7 18:54 ?        00:00:00 /usr/local/bin/examiner
root         843       1     847  0    7 18:54 ?        00:00:00 /usr/local/bin/examiner
root         843       1     848  0    7 18:54 ?        00:00:00 /usr/local/bin/examiner
```

---

## Kernel Threads

Kernel threads run only in kernel space, have no user memory and appear in brackets in `ps aux`. They handle work such as RCU callbacks, block I/O flushing and memory reclaim (`kswapd0`).

```bash
ps aux | head -4
```

Output:

```text
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.5  0.1  22992 13992 ?        Ss   18:54   0:01 /sbin/init
root           2  0.0  0.0      0     0 ?        S    18:54   0:00 [kthreadd]
root           3  0.0  0.0      0     0 ?        I<   18:54   0:00 [rcu_gp]
```

A `VSZ` and `RSS` of 0 identify a kernel thread. They cannot be killed from user space, and high CPU in one (`kswapd0`, `ksoftirqd/N`) points to memory pressure or interrupt load, not to a runaway application.

---

## Common Errors

### `ls: cannot read symbolic link '/proc/2102/cwd': Permission denied`

**Cause:** the process belongs to another user, and `cwd`, `exe`, `fd/` and `environ` are restricted to the owner and root.

**Fix:** read it with `sudo`, or use `ps` and `/proc/<pid>/status`, which are world-readable.

### `bash: fork: retry: Resource temporarily unavailable`

**Cause:** the user reached its process limit (`ulimit -u`, `TasksMax=` of the unit) or the system reached `kernel.pid_max` or `kernel.threads-max`.

**Fix:** count the user's tasks with `ps -L -u <user> --no-headers | wc -l`, find the runaway parent with `pstree -p`, and raise the limit only after the leak is fixed.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a program, a process and a thread?"
    **Say first:** a program is an executable file; a process is a running instance with its own address space and PID; a thread is an execution path inside a process that shares its memory and open files.

    **Proof:** two `sleep 300` commands give two PIDs for one file; `ps -T -p <pid>` lists a process's threads.

    **Follow-up:** Why does one crashing thread take down the whole process?

??? question "L1: What is PID 1, and why is it special?"
    **Say first:** PID 1 is the first user-space process the kernel starts (`systemd` on modern distributions); it starts services and adopts orphaned processes.

    **Proof:** `ps -p 1 -o comm,args`; an orphan shows `PPID 1` in `ps -o pid,ppid`.

    **Follow-up:** What happens to the system if PID 1 exits?

??? question "L1: What are the entries in brackets in ps aux?"
    **Say first:** kernel threads, children of `kthreadd` (PID 2), which run only in kernel space and have no user memory.

    **Proof:** `ps -o pid,ppid,vsz,comm --ppid 2 | head`

    **Follow-up:** What does high CPU in `kswapd0` tell you?
<!-- --8<-- [end:l1] -->

??? question "L2: Find which service or session started a given process."
    **Say first:** walk up the parent chain, then read the control group.

    **Proof:**

    ```bash
    pstree -s -p 2103
    cat /proc/2103/cgroup
    ```

    **Follow-up:** Why does the cgroup answer the question even after the parent has exited?

??? question "L2: List the threads of a busy process and find the one using CPU."
    **Say first:** show per-thread CPU with `top -H` or `ps -L`.

    **Proof:** `top -H -p <pid>` or `ps -L -o tid,pcpu,comm -p <pid> --sort=-pcpu | head`

    **Follow-up:** How do you map that TID to a Java thread in a thread dump? (Convert it to hex and match `nid=`.)

??? question "L2: Show where a running process was started from and what it is running."
    **Say first:** read the `cwd`, `exe` and `cmdline` entries under `/proc`.

    **Proof:** `sudo ls -l /proc/<pid>/cwd /proc/<pid>/exe; tr '\0' ' ' < /proc/<pid>/cmdline`

    **Follow-up:** What does `(deleted)` after the `exe` target mean?

??? question "L3: A server refuses new logins with fork: Resource temporarily unavailable."
    **Say first:** the process table or a per-user limit is full; find who owns the tasks before raising anything.

    **Proof:** from an existing root shell, `ps -eLo user= | sort | uniq -c | sort -rn | head`, then `ulimit -u` and `sysctl kernel.pid_max kernel.threads-max`; `pstree -p <user>` shows the runaway parent.

    **Follow-up:** How do you investigate when `ps` itself cannot start? (Shell builtins and `/proc`.)

??? question "L4: Why can Linux use one system call for both processes and threads?"
    **Say first:** the kernel schedules tasks; `clone()` flags such as `CLONE_VM`, `CLONE_FILES` and `CLONE_SIGHAND` decide which resources the new task shares, so a thread is a task that shares everything with its group.

    **Proof:** `strace -f -e trace=clone3,clone python3 -c 'import threading; threading.Thread(target=print).start()'` shows `CLONE_VM|CLONE_THREAD`; `fork()` in `bash` shows `clone()` with only `SIGCHLD`.

    **Don't say:** "Threads are lighter processes that the kernel does not see."

---

## Related

- [Process Lifecycle](process-lifecycle.md): how processes are created and reaped
- [Viewing Processes](viewing-processes.md): `ps`, `top` and `pgrep` in detail
- [Architecture](../00-foundations/architecture.md): user space, kernel space and system calls
- [File Descriptors](../02-files-and-filesystem/file-descriptors.md): the `fd/` entries under `/proc`

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
