# Viewing Processes

`ps` takes a snapshot of the process table, `top` refreshes it, and `pgrep` finds PIDs by name or attribute. Reading their columns correctly (state, CPU, resident memory, elapsed time) answers most "what is this server doing" questions.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `ps aux` | BSD syntax: all processes, user-oriented columns, `%CPU` and `%MEM` | `ps aux` |
| `ps -ef` | UNIX syntax: all processes with `PPID` and full command | `ps -ef` |
| Custom columns | `-o pid,ppid,user,stat,%cpu,rss,etime,cmd`; `=` after a name removes the header | `ps -o pid= -p 1` |
| Sorting | `--sort=-%cpu`, `--sort=-rss` | `ps -eo pid,rss,comm --sort=-rss` |
| Select by name | `-C nginx` matches the command name exactly | `ps -C nginx -o pid,args` |
| Tree view | `ps -ef --forest`, `pstree -p` | `pstree -p <pid>` |
| `%CPU` in `ps` | CPU time divided by lifetime, not current usage | `top` for current usage |
| `RSS` vs `VSZ` | Resident memory in KiB vs virtual address space size | `ps -o rss,vsz` |
| `pgrep` / `pkill` | Match the name (15 chars); `-f` matches the full command line; exit 1 when nothing matches | `pgrep -a nginx` |
| `pidof` | PIDs of an exact program name, space-separated | `pidof nginx` |
| `top` batch mode | `top -b -n 1` prints one screen for scripts and tickets | `top -b -n 1` |
| `top` keys | `P` CPU, `M` memory, `1` per-CPU, `H` threads, `c` full command, `k` kill | inside `top` |
| Load average | Runnable plus uninterruptible (`D`) tasks, averaged over 1, 5 and 15 minutes | `uptime` |
| `watch` | Reruns a command every 2 seconds (`-n` to change, `-d` to highlight changes) | `watch -n 1 'ps -C nginx'` |
<!-- --8<-- [end:facts] -->

---

## ps aux and ps -ef

`procps` `ps` accepts BSD options (no dash), UNIX options (one dash) and GNU options (two dashes). The two common forms show the same processes with different columns.

```bash
ps aux | head -4
ps -ef | head -4
```

Output:

```text
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.5  0.1  22992 13992 ?        Ss   18:54   0:01 /sbin/init
root           2  0.0  0.0      0     0 ?        S    18:54   0:00 [kthreadd]
root           3  0.0  0.0      0     0 ?        I<   18:54   0:00 [rcu_gp]
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 18:54 ?        00:00:01 /sbin/init
root           2       0  0 18:54 ?        00:00:00 [kthreadd]
root           3       2  0 18:54 ?        00:00:00 [rcu_gp]
```

| Column | Meaning |
|---|---|
| `VSZ` | Virtual memory size in KiB, including mapped but unused regions |
| `RSS` | Resident set size in KiB: pages in RAM now, including shared libraries |
| `TTY` | Controlling terminal; `?` for daemons |
| `STAT` | State plus flags, see [Process States](process-states.md) |
| `START` / `STIME` | Start time |
| `TIME` | Total CPU time consumed |
| `C` | CPU utilization over the process lifetime, as an integer |

---

## Custom Columns and Sorting

`-o` selects columns, and `--sort` orders by any of them; a leading `-` sorts descending. This form is the most useful in scripts and incident notes.

```bash
ps -eo pid,ppid,user,%cpu,%mem,rss,etime,comm --sort=-%cpu | head -5
ps -eo pid,user,rss,vsz,comm --sort=-rss | head -5
```

Output:

```text
    PID    PPID USER     %CPU %MEM   RSS     ELAPSED COMMAND
   2113    2109 laborant  100  0.0  6960       00:02 stress-ng-cpu
   2114    2112 laborant  100  3.7 309308      00:02 stress-ng-vm
   2056       1 root      0.6  0.0  5812       00:03 systemd-hostnam
   2040       1 laborant  0.5  0.1 11460       00:03 systemd
    PID USER       RSS    VSZ COMMAND
   2114 laborant 309308 373372 stress-ng-vm
    843 root     165904 1381140 examiner
   2110 laborant 39460  66164 stress-ng
   2109 laborant 39408  66164 stress-ng
```

Time columns answer "when did this start" and "how much CPU has it used":

```bash
ps -o pid,lstart,etime,etimes,time,comm -p 1
```

Output:

```text
    PID                  STARTED     ELAPSED ELAPSED     TIME COMMAND
      1 Wed Sep 16 18:54:51 2026       05:13     313 00:00:01 systemd
```

`etimes` gives elapsed seconds, which scripts can compare numerically.

---

## Selecting Processes

```bash
ps -C nginx -o pid,ppid,user,args
ps -ef --forest | grep -A2 "[n]ginx: master"
```

Output:

```text
    PID    PPID USER     COMMAND
   2102       1 root     nginx: master process /usr/sbin/nginx
   2103    2102 nginx    nginx: worker process
   2104    2102 nginx    nginx: worker process
   2105    2102 nginx    nginx: worker process
   2107    2102 nginx    nginx: worker process
root        2102       1  0 19:00 ?        00:00:00 nginx: master process /usr/sbin/nginx
nginx       2103    2102  0 19:00 ?        00:00:00  \_ nginx: worker process
nginx       2104    2102  0 19:00 ?        00:00:00  \_ nginx: worker process
```

nginx rewrites its own `argv`, so `args` shows `nginx: worker process` instead of the binary path. The master runs as root to bind port 80; the workers run as `nginx`.

!!! tip "The bracket trick keeps grep out of its own results"
    `grep nginx` matches the `grep nginx` process too. The pattern `[n]ginx` still matches "nginx" but not the literal text "[n]ginx" in grep's own command line. `pgrep` avoids the problem entirely.

```bash
ps aux | grep nginx
```

Output:

```text
root        2102  0.0  0.0  13988  1484 ?        Ss   19:00   0:00 nginx: master process /usr/sbin/nginx
nginx       2103  0.0  0.0  14344  3536 ?        S    19:00   0:00 nginx: worker process
nginx       2104  0.0  0.0  14344  3536 ?        S    19:00   0:00 nginx: worker process
nginx       2105  0.0  0.0  14344  3536 ?        S    19:00   0:00 nginx: worker process
nginx       2107  0.0  0.0  14344  3536 ?        S    19:00   0:00 nginx: worker process
laborant    2141  0.0  0.0   3856  1892 ?        S    19:00   0:00 grep nginx
```

---

## pgrep, pidof and pstree

```bash
pgrep -a nginx; pgrep -u root -l nginx; pidof nginx
pgrep -c sshd; echo "rc=$?"
pstree -A -p $(pgrep -o nginx)
```

Output:

```text
2102 nginx: master process /usr/sbin/nginx
2103 nginx: worker process
2104 nginx: worker process
2105 nginx: worker process
2107 nginx: worker process
2102 nginx
2107 2105 2104 2103 2102
0
rc=1
nginx(2102)-+-nginx(2103)
            |-nginx(2104)
            |-nginx(2105)
            `-nginx(2107)
```

| Option | Effect |
|---|---|
| `-a` | Print the full command line |
| `-l` | Print the name |
| `-f` | Match against the full command line |
| `-x` | Exact name match |
| `-u user` | Only this effective user |
| `-o` / `-n` | Oldest / newest match only |
| `-P ppid` | Only children of this parent |
| `-c` | Count matches |

`pgrep` exits 1 when nothing matches, which makes it a process check in scripts: `pgrep -x nginx >/dev/null || echo down`. The count is 0 because this playground starts SSH through `sshd.socket`, so no `sshd` process exists until a client connects; a default RHEL install runs `sshd.service` instead.

---

## top

`top` shows current usage, refreshed every 3 seconds. Batch mode prints a screen that can be pasted into a ticket.

```bash
top -b -n 1 -o %CPU | head -12
```

Output:

```text
top - 19:00:05 up 5 min,  0 user,  load average: 0.34, 0.09, 0.03
Tasks: 127 total,   3 running, 124 sleeping,   0 stopped,   0 zombie
%Cpu(s): 50.0 us,  2.4 sy,  0.0 ni, 47.6 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :   8020.4 total,   7074.1 free,    851.3 used,    402.1 buff/cache     
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   7169.1 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   2113 laborant  20   0   66164   6960   4148 R 100.0   0.1   0:03.26 stress-+
   2114 laborant  20   0  373372 309308   1004 R 100.0   3.8   0:03.25 stress-+
      1 root      20   0   22992  13992  10068 S   0.0   0.2   0:01.64 systemd
      2 root      20   0       0      0      0 S   0.0   0.0   0:00.00 kthreadd
      3 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 rcu_gp
```

Two processes each use a full CPU on a 4-CPU machine, which `%Cpu(s)` reports as 50% user time overall.

| Header field | Meaning |
|---|---|
| `load average` | 1, 5 and 15-minute averages of runnable plus `D`-state tasks |
| `us` / `sy` | User and kernel CPU time |
| `ni` | User time of processes with positive nice values |
| `wa` | Idle time while I/O was pending |
| `hi` / `si` | Hardware and software interrupt time |
| `st` | Time stolen by the hypervisor for other guests |
| `avail Mem` | Memory available for new work without swapping, including reclaimable cache |
| `PR` / `NI` | Kernel priority and nice value |
| `RES` / `SHR` | Resident memory and the shared part of it |
| `TIME+` | CPU time in hundredths of a second |

!!! warning "Compare load average with the CPU count, not with 1"
    A load of 4 on this 4-CPU machine means full use; on one CPU it means 3 tasks waiting. Load also counts `D`-state tasks, so a high load with idle CPUs points to I/O or a hung mount, not to CPU demand. `nproc` gives the CPU count.

`htop` adds colors, a tree view (`F5`), per-thread display and mouse selection; it comes from EPEL on RHEL and from the main archive on Ubuntu.

---

## Reading /proc Directly

`ps` and `top` read `/proc/<pid>/stat` and `status`. When `ps` is unavailable (a minimal container, or a fork limit), the same data is in the files:

```bash
cat /proc/$(pgrep -o nginx)/status | head -9
```

Output:

```text
Name:	nginx
Umask:	0000
State:	S (sleeping)
Tgid:	2102
Ngid:	0
Pid:	2102
PPid:	1
TracerPid:	0
Uid:	0	0	0	0
```

A shell-only process list: `for p in /proc/[0-9]*; do printf '%s %s\n' "${p#/proc/}" "$(< "$p/comm")"; done`.

---

## Common Errors

### `error: list of process IDs must follow -p`

**Cause:** the command substitution after `-p` was empty, usually because `pgrep` matched nothing.

**Fix:** check the match first: `pid=$(pgrep -x nginx) && ps -o pid,cmd -p "$pid"`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between ps aux and ps -ef?"
    **Say first:** both list every process; `aux` is BSD style with `%CPU`, `%MEM`, `VSZ` and `RSS`, and `-ef` is UNIX style with `PPID` and start time.

    **Proof:** `ps aux | head -2; ps -ef | head -2`

    **Follow-up:** Which command gives exactly the columns you choose? (`ps -eo`.)

??? question "L1: What does load average measure?"
    **Say first:** the average number of tasks that are running, waiting for a CPU, or in uninterruptible sleep, over 1, 5 and 15 minutes.

    **Proof:** `uptime`; compare with `nproc`.

    **Follow-up:** How can load be high while the CPUs are idle?

??? question "L1: What is the difference between RSS and VSZ?"
    **Say first:** `VSZ` is the size of the virtual address space, and `RSS` is the part currently in physical memory, including shared libraries.

    **Proof:** `ps -o pid,vsz,rss,comm -p <pid>`; a Java process often shows a `VSZ` many times its `RSS`.

    **Follow-up:** Why does summing `RSS` over all processes overcount memory? (Shared pages; `PSS` in `smaps_rollup` divides them.)
<!-- --8<-- [end:l1] -->

??? question "L2: Show the five processes using the most memory."
    **Say first:** sort by resident memory.

    **Proof:** `ps -eo pid,user,rss,comm --sort=-rss | head -6`

    **Follow-up:** How do you show the same for CPU right now instead of over the lifetime? (`top -b -n 1 -o %CPU`.)

??? question "L2: Print how long a process has been running, in seconds."
    **Say first:** use the `etimes` column without a header.

    **Proof:** `ps -o etimes= -p $(pgrep -o nginx)`

    **Follow-up:** Where does `ps` get the start time? (Field 22 of `/proc/<pid>/stat`, in clock ticks since boot.)

??? question "L2: Write a check that restarts nothing but reports when nginx is not running."
    **Say first:** use `pgrep` with an exact name and its exit status.

    **Proof:** `pgrep -x nginx >/dev/null || echo "nginx down"`

    **Follow-up:** Why is `systemctl is-active nginx` a better check on a systemd host?

??? question "L3: Users report slowness; top shows load average 12 on a 4-CPU server but CPU is 70% idle."
    **Say first:** the load comes from tasks in uninterruptible sleep, so look for `D`-state processes and I/O wait.

    **Proof:** `ps -eo pid,stat,wchan:30,cmd | awk '$2 ~ /^D/'`, then `vmstat 1` for `b` and `wa`, `iostat -x 1` for device latency, `findmnt -t nfs,nfs4` for hung mounts.

    **Follow-up:** What does `wchan` tell you about where they are blocked?

??? question "L3: ps shows a process using 100% CPU, but top shows it at 0%."
    **Say first:** `ps` reports average CPU over the process lifetime, and `top` reports usage in the last interval; the process was busy earlier.

    **Proof:** `ps -o pid,%cpu,time,etime -p <pid>` against `top -b -n 2 -d 2 -p <pid>`

    **Follow-up:** Which tool shows per-interval history? (`pidstat 1` from `sysstat`.)

---

## Related

- [Process States](process-states.md): the `STAT` column
- [Signals](signals.md): `kill`, `pkill` and `killall`
- [Process Fundamentals](process-fundamentals.md): `/proc/<pid>` files
- [Finding Files](../02-files-and-filesystem/finding-files.md): `lsof` and open files

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
