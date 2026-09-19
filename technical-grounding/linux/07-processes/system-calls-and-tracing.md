# System Calls and Tracing

A system call is the only way a process asks the kernel to do something: open a file, allocate memory, create a process, send a packet. Tracing those calls with `strace` shows what a program really does and which call failed with which `errno`, which often answers a problem faster than reading logs or source code.

**Track:** Advanced · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| System call | Controlled entry from user mode into the kernel (the `syscall` instruction on x86_64) | `strace true` |
| Return value | `-1` plus `errno` on failure; `strace` prints the symbolic name | `strace cat /nonexistent` |
| Common `errno` | `ENOENT` 2, `EACCES` 13, `EPERM` 1, `EAGAIN` 11, `EMFILE` 24, `ENOSPC` 28, `ECONNREFUSED` 111 | `python3 -c 'import os; print(os.strerror(13))'` |
| `EACCES` vs `EPERM` | Permission bits or ACL denied vs operation not allowed for this identity (ownership, capability) | `strace` output |
| vDSO | Kernel code mapped into every process so time calls avoid a real system call | `grep vdso /proc/self/maps` |
| `strace -f` | Follow children and threads | `strace -f bash -c 'ls; true'` |
| `strace -e trace=` | Filter by name or class: `%file`, `%network`, `%process`, `%memory` | `strace -e trace=%file` |
| `strace -p <pid>` | Attach to a running process; needs the same user or root | `timeout 5 strace -p <pid>` |
| `strace -c` | Count calls, errors and time per call | `strace -c ls` |
| Useful flags | `-o file`, `-tt` timestamps, `-T` time in call, `-y` file names for fds, `-s 200` longer strings, `-P path` | `man strace` |
| Overhead | `strace` stops the target on every traced call; it can slow a busy service many times over | `strace -c` on a hot path |
| `ltrace` | Traces calls into shared libraries (`malloc`, `getenv`) | `ltrace -c ls` |
| Stack of a hung process | `/proc/<pid>/wchan`, `/proc/<pid>/stack` (root), `gdb -p` or `gstack` for user space | `sudo cat /proc/<pid>/stack` |
| Ptrace restrictions | Yama `kernel.yama.ptrace_scope=1` on Ubuntu allows tracing only of children without root | `sysctl kernel.yama.ptrace_scope` |
<!-- --8<-- [end:facts] -->

---

## How a System Call Works

1. The C library places the call number in `rax` and the arguments in registers, then executes the `syscall` instruction.
2. The CPU switches to kernel mode and jumps to the kernel's entry point, which looks up the handler in the system call table.
3. The handler checks the arguments and permissions, does the work, and places a return value in `rax`.
4. The CPU returns to user mode; glibc turns a negative return into `-1` and sets `errno`.

The kernel stack of any blocked process shows this path from the bottom up: `entry_SYSCALL_64` and `do_syscall_64` are steps 2 and 3.

```bash
sleep 300 >/dev/null 2>&1 &
sleep 0.3
cat /proc/3039/wchan; echo; cat /proc/3039/syscall
sudo cat /proc/3039/stack
cat /proc/3039/stack
```

Output:

```text
__do_sys_restart_syscall
219 0x0 0x0 0x7ffc22f9c8f0 0x7ffc22f9c8e0 0x0 0x12c00000000000 0x7ffc22f9c8a8 0x7f8d05f03847
[<0>] __do_sys_restart_syscall+0x22/0x30
[<0>] x64_sys_call+0x19a4/0x1fd0
[<0>] do_syscall_64+0x35/0x80
[<0>] entry_SYSCALL_64_after_hwframe+0x6e/0xd8
cat: /proc/3039/stack: Permission denied
```

`/proc/<pid>/syscall` prints the call number (219 is `restart_syscall` on x86_64), its arguments, and the stack and instruction pointers.

### The vDSO

Calls such as `clock_gettime()` and `gettimeofday()` run in user space through the vDSO, a small shared object the kernel maps into every process. `strace` does not see them:

```bash
strace -e trace=getpid,clock_gettime,gettimeofday python3 -c "import os,time; os.getpid(); time.time()" 2>&1 | tail -3
grep vdso /proc/self/maps; ldd /usr/bin/true | head -1
```

Output:

```text
getpid()                                = 3031
+++ exited with 0 +++
7ffcb7de5000-7ffcb7de7000 r-xp 00000000 00:00 0                          [vdso]
	linux-vdso.so.1 (0x00007ffc03d4d000)
```

`time.time()` produced no trace line, while `getpid()` entered the kernel.

---

## Reading strace Output

Each line is `name(arguments) = return value`, with the error name and text on failure. `-P` limits the trace to calls on one path.

```bash
strace -e trace=openat -P /etc/hostname-missing cat /etc/hostname-missing
strace -e trace=openat,read -P /etc/hostname cat /etc/hostname 2>&1 >/dev/null
```

Output:

```text
openat(AT_FDCWD, "/etc/hostname-missing", O_RDONLY) = -1 ENOENT (No such file or directory)
cat: /etc/hostname-missing: No such file or directory
+++ exited with 1 +++
openat(AT_FDCWD, "/etc/hostname", O_RDONLY) = 3
read(3, "rocky-01", 262144)             = 8
read(3, "", 262144)                     = 0
+++ exited with 0 +++
```

`openat` returned file descriptor 3; the first `read` returned 8 bytes and the second returned 0, which means end of file.

| `errno` | Number | Typical cause |
|---|---|---|
| `EPERM` | 1 | Not the owner, missing capability, `chattr +i` |
| `ENOENT` | 2 | Path or a directory in it does not exist |
| `EAGAIN` | 11 | Resource temporarily unavailable (limits, non-blocking I/O) |
| `EACCES` | 13 | Permission bits, ACL or SELinux denied access |
| `EMFILE` | 24 | Too many open files for the process |
| `ENOSPC` | 28 | No space (blocks or inodes) on the device |
| `ETIMEDOUT` | 110 | Connection attempt timed out |
| `ECONNREFUSED` | 111 | Nothing listening on the port |

---

## Finding What a Program Looks For

A program that fails with a vague message often shows the missing file in `strace`. This script exits with "config missing" without saying where it looked:

```bash
python3 app.py; echo rc=$?
strace -f -e trace=%file -e status=failed python3 app.py 2>&1 | grep myapp
```

Output:

```text
config missing
rc=1
newfstatat(AT_FDCWD, "/etc/myapp/config.yml", 0x7ffc6dc2efe0, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "/home/laborant/.config/myapp.yml", 0x7ffc6dc2f060, 0) = -1 ENOENT (No such file or directory)
```

`-e status=failed` prints only failing calls, and `%file` selects every call that takes a path.

Permission problems show as `EACCES`:

```bash
strace -f -e trace=openat -e status=failed bash -c "cat /etc/shadow" 2>&1 | grep -E 'shadow|exited'
```

Output:

```text
openat(AT_FDCWD, "/etc/shadow", O_RDONLY) = -1 EACCES (Permission denied)
cat: /etc/shadow: Permission denied
+++ exited with 1 +++
```

---

## Network Calls

```bash
strace -e trace=connect bash -c 'echo > /dev/tcp/127.0.0.1/81' 2>&1 | grep -v '^+++'
strace -e trace=%network -f curl -s -o /dev/null http://127.0.0.1/ 2>&1 | grep -E 'socket|connect|sendto' | head -4
```

Output:

```text
connect(3, {sa_family=AF_INET, sin_port=htons(81), sin_addr=inet_addr("127.0.0.1")}, 16) = -1 ECONNREFUSED (Connection refused)
bash: connect: Connection refused
bash: line 1: /dev/tcp/127.0.0.1/81: Connection refused
socket(AF_INET, SOCK_STREAM|SOCK_NONBLOCK, IPPROTO_TCP) = 4
connect(4, {sa_family=AF_INET, sin_port=htons(80), sin_addr=inet_addr("127.0.0.1")}, 16) = -1 EINPROGRESS (Operation now in progress)
sendto(4, "GET / HTTP/1.1\r\nHost: 127.0.0.1\r"..., 73, MSG_NOSIGNAL, NULL, 0) = 73
```

`curl` uses non-blocking sockets, so `connect()` returns `EINPROGRESS` and the result arrives later through `poll()`. `-tt -T` shows where the time goes when a connection hangs:

```bash
strace -tt -T -e trace=connect,poll,recvfrom -f curl -s -m 3 -o /dev/null http://10.255.255.1/ 2>&1 | tail -4
```

Output:

```text
19:27:20.057051 poll([{fd=4, events=POLLOUT}, {fd=3, events=POLLIN}], 2, 1000) = 0 (Timeout) <1.001110>
19:27:21.058283 poll([{fd=4, events=POLLPRI|POLLOUT|POLLWRNORM}], 1, 0) = 0 (Timeout) <0.000012>
19:27:21.058373 poll([{fd=4, events=POLLOUT}, {fd=3, events=POLLIN}], 2, 999) = 0 (Timeout) <1.000108>
19:27:22.059329 +++ exited with 28 +++
```

Each `poll()` waits about one second (`<1.001110>`) for the socket to become writable, which never happens: the SYN gets no answer, and `curl` gives up with exit 28 after `-m 3`.

---

## Summaries

`strace -c` counts calls and errors, which shows where a program spends its kernel time:

```bash
strace -c ls /usr/share >/dev/null
```

Output:

```text
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 27.13    0.000067           1        34        13 openat
 20.65    0.000051          25         2           getdents64
 17.00    0.000042           1        35           mmap
 15.79    0.000039           1        23           close
 13.77    0.000034           1        22           fstat
# ... (trimmed)
------ ----------- ----------- --------- --------- ----------------
100.00    0.000247           1       156        21 total
```

The 13 failed `openat` calls are locale files that do not exist, which is normal.

!!! warning "strace slows the traced process"
    Every traced call stops the process twice for the tracer. On a busy database or web server this can multiply latency; limit the trace with `-e trace=`, keep it short with `timeout`, or use `perf trace` or eBPF tools, which do not stop the process.

---

## Attaching to a Running Process

`strace -p` shows what a hung process is waiting for. A reader stuck on a FIFO with no writer blocks inside `openat`:

```bash
mkfifo /tmp/jobq
(cat /tmp/jobq > /dev/null &)
sleep 0.5
timeout 2 strace -y -p 3204
cat /proc/3204/wchan; echo
```

Output:

```text
strace: Process 3204 attached
openat(AT_FDCWD</home/laborant/c>, "/tmp/jobq", O_RDONLY
strace: Process 3204 detached
 <detached ...>
wait_for_partner
```

!!! tip "An unfinished strace line is the blocked call"
    A line that ends without `= result` is a system call that has not returned. It names the file, socket or pipe the process waits on, which `-y` resolves from the descriptor number.

For a user-space stack, `gdb` attaches and prints a backtrace; `gstack` wraps the same command.

=== "RHEL / Rocky"

    ```bash
    sudo gdb -batch -p 3039 -ex bt 2>&1 | grep -E '^#'
    gstack 3039 2>&1 | head -5
    ```

    Output:

    ```text
    #0  0x00007f8d05f03847 in clock_nanosleep@GLIBC_2.2.5 () from /lib64/libc.so.6
    #1  0x00007f8d05f0f1c7 in nanosleep () from /lib64/libc.so.6
    #2  0x00005591c4e35a08 in main ()
    Thread 1 (Thread 0x7f8d05e30740 (LWP 3039) "sleep"):
    #0  0x00007f8d05f03847 in clock_nanosleep@GLIBC_2.2.5 () from /lib64/libc.so.6
    #1  0x00007f8d05f0f1c7 in nanosleep () from /lib64/libc.so.6
    #2  0x00005591c4e35a08 in main ()
    ```

    `gstack` and `pstack` come with the `gdb` package.

=== "Ubuntu / Debian"

    ```bash
    sudo gdb -batch -p <pid> -ex 'thread apply all bt'
    sysctl kernel.yama.ptrace_scope
    ```

    Ubuntu's `gdb` package has no `gstack`. Ubuntu sets `kernel.yama.ptrace_scope = 1` in `/etc/sysctl.d/10-ptrace.conf`, so `strace -p` and `gdb -p` on a process that is not a child need `sudo`; the playground kernel has no Yama module, so the restriction was not active there.

---

## Library Calls with ltrace

`ltrace` intercepts calls from a program into shared libraries, which shows behavior that never reaches the kernel.

```bash
ltrace -c -o lt.txt ls >/dev/null; head -8 lt.txt
```

Output:

```text
% time     seconds  usecs/call     calls      function
------ ----------- ----------- --------- --------------------
 20.65    0.003446          56        61 __errno_location
 14.05    0.002345          55        42 strcoll
 11.38    0.001899          57        33 strlen
  9.11    0.001521        1521         1 setlocale
  7.37    0.001230          58        21 malloc
  7.00    0.001168          61        19 readdir
```

| Tool | Sees | Use it for |
|---|---|---|
| `strace` | System calls and signals | Files, permissions, sockets, hangs |
| `ltrace` | Shared library calls | `getenv`, `malloc`, string handling |
| `gdb` / `gstack` | User-space stack | Where a program is stuck |
| `/proc/<pid>/stack` | Kernel stack | Where a `D`-state process waits |
| `perf trace`, `bpftrace` | System calls and kernel events with low overhead | Busy production services |

---

## Common Errors

### `sudo: effective uid is not 0, is /usr/bin/sudo on a file system with the 'nosuid' option set or an NFS file system without root privileges?`

**Cause:** `strace sudo ...` traces `sudo` as the calling user; `ptrace` disables the setuid bit, so `sudo` starts without root.

**Fix:** put `sudo` first: `sudo strace -f -o trace.txt <command>`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a system call?"
    **Say first:** a controlled request from a user-space process to the kernel, such as `openat`, `read`, `clone` or `connect`; it switches the CPU to kernel mode and back.

    **Proof:** `strace cat /etc/hostname` lists every call and its return value.

    **Follow-up:** Why can't a program open a file without one?

??? question "L1: What does strace show, and when do you use it?"
    **Say first:** the system calls and signals of a process with their arguments, results and `errno`; it answers "what is this program trying to do and what fails".

    **Proof:** `strace -e trace=%file -e status=failed <cmd>` lists the paths a program could not find.

    **Follow-up:** What is the risk of running it on a production service?

??? question "L1: What is the difference between ENOENT, EACCES and EPERM?"
    **Say first:** the path does not exist; the permission check on the path failed; the operation is not allowed for this identity even though the path is fine.

    **Proof:** `strace cat /nonexistent` gives `ENOENT`; `strace cat /etc/shadow` as a user gives `EACCES`; `kill 1` as a user gives `EPERM`.

    **Follow-up:** Which one does `chattr +i` cause for root?
<!-- --8<-- [end:l1] -->

??? question "L2: A program exits with an unhelpful error. Find which files it could not open."
    **Say first:** trace path-based calls and show only failures.

    **Proof:** `strace -f -e trace=%file -e status=failed ./app 2>&1 | grep -v locale`

    **Follow-up:** How do you capture the trace of a program started by systemd? (`sudo strace -f -p <MainPID>` or `ExecStart=/usr/bin/strace -f -o /tmp/t ...`.)

??? question "L2: Show what a running process is blocked on."
    **Say first:** attach briefly and read its wait channel.

    **Proof:** `sudo timeout 5 strace -y -p <pid>`; `cat /proc/<pid>/wchan`; `sudo gdb -batch -p <pid> -ex 'thread apply all bt'`

    **Follow-up:** What does an unfinished `strace` line mean?

??? question "L3: A service starts but every request takes exactly 5 seconds."
    **Say first:** a fixed delay usually means a timeout, often DNS or a connection attempt; trace the time spent in network calls.

    **Proof:** `sudo strace -f -tt -T -e trace=%network -p <pid>` shows a `poll()` or `recvfrom()` on port 53 lasting `<5.00...>`; `cat /etc/resolv.conf` shows an unreachable first nameserver.

    **Follow-up:** How would you confirm it without `strace`? (`getent hosts <name>` with `time`.)

??? question "L3: strace -p fails on an Ubuntu server even for the user's own process."
    **Say first:** Yama restricts `ptrace` to child processes by default on Ubuntu.

    **Proof:** `sysctl kernel.yama.ptrace_scope` returns 1; `sudo strace -p` works.

    **Follow-up:** Why does Ubuntu restrict it?

??? question "L4: What happens at the CPU and kernel level when a program calls read()?"
    **Say first:** glibc loads the call number and arguments into registers and executes `syscall`; the CPU enters kernel mode at `entry_SYSCALL_64`, `do_syscall_64` dispatches to `ksys_read`, which goes through the VFS to the filesystem or page cache, copies data to the user buffer, and returns the byte count in `rax`.

    **Proof:** `/proc/<pid>/stack` of a blocked reader shows `entry_SYSCALL_64_after_hwframe` and `do_syscall_64` at the bottom; `strace` shows `read(3, ...) = 8`.

    **Don't say:** "The C library reads the disk directly."

??? question "L4: Why don't time functions appear in strace output?"
    **Say first:** `clock_gettime()` and `gettimeofday()` run in the vDSO, kernel-provided code mapped into user space, so no mode switch happens.

    **Proof:** `grep vdso /proc/self/maps`; `strace -e trace=clock_gettime python3 -c 'import time; time.time()'` prints nothing for the call.

    **Don't say:** "strace filters them out."

---

## Related

- [Architecture](../00-foundations/architecture.md): user space, kernel space and the system call boundary
- [Process States](process-states.md): `wchan` and kernel stacks of blocked processes
- [Shared Libraries](../06-package-management/shared-libraries.md): what `ltrace` hooks into
- [File Descriptors](../02-files-and-filesystem/file-descriptors.md): the numbers `openat` returns

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
