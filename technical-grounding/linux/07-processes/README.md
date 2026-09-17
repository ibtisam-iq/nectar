# Processes

How processes are created, observed, prioritized, signaled and traced, from `fork()` and `exec()` to reading `D` states and `strace` output.

---

## Revision Card

| Fact | Value |
|---|---|
| PID 1 / PID 2 | `systemd` / `kthreadd` (parent of kernel threads in brackets) |
| Creation | `fork()` (copy-on-write) then `execve()` (same PID, new program) |
| Reaping | Parent calls `wait()`; until then the child is a zombie (`Z`) |
| Orphans | Adopted by PID 1 or the nearest subreaper |
| States | `R` run, `S` sleep, `D` uninterruptible, `T` stopped, `Z` zombie, `I` idle kernel thread |
| Ignores `kill -9` | `Z` (already dead) and `D` (signal waits for the kernel call) |
| Load average | Counts `R` and `D` tasks; compare with `nproc` |
| `ps` `%CPU` | Lifetime average; `top` shows the current interval |
| Default `kill` signal | `SIGTERM` (15); `SIGKILL` (9) cannot be caught |
| Exit codes | 128 + signal: 130 INT, 137 KILL, 143 TERM; `timeout` returns 124 |
| Hangup | Closed terminal sends `SIGHUP`; `nohup`, `setsid`, `disown` survive it |
| Nice | -20 to 19; users may only raise it; matters only under contention |
| Tracing | `strace -f -e trace=%file -e status=failed`; `strace -p` attaches |
| Blocked process | `wchan`, `/proc/<pid>/stack` (root), `gdb -p` |

| Task | Command |
|---|---|
| Top memory users | `ps -eo pid,user,rss,comm --sort=-rss` |
| Process tree of a PID | `pstree -s -p <pid>` |
| Zombies and parents | `ps -eo pid,ppid,stat,comm`, rows with `Z` |
| Blocked tasks | `ps -eo pid,stat,wchan:30,cmd`, rows with `D` |
| Signals a process catches | `grep SigCgt /proc/<pid>/status` |
| Check a PID is alive | `kill -0 <pid>` |
| Survive logout | `nohup cmd > log 2>&1 &` or `systemd-run` |
| Lower priority | `nice -n 19 ionice -c 3 cmd` |
| Files a program cannot find | `strace -f -e trace=%file -e status=failed cmd` |
| Threads of a process | `ps -T -p <pid>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Process Fundamentals](process-fundamentals.md) | Program vs process vs thread, PIDs, the tree, `/proc/<pid>` | Core | High |
| [Process Lifecycle](process-lifecycle.md) | `fork`, `exec`, `wait`, copy-on-write, zombies, orphans, sessions, daemons | Advanced | High |
| [Viewing Processes](viewing-processes.md) | `ps`, `pgrep`, `pstree`, `top` columns, load average | Core | High |
| [Process States](process-states.md) | `R S D T Z I`, `wchan`, `D` state and load | Core | High |
| [Signals](signals.md) | Common signals, `kill` and `pkill`, `trap`, masks, stop sequences, delivery | Core | High |
| [Job Control](job-control.md) | `&`, `jobs`, `fg`, `bg`, hangups, `nohup`, `disown`, `tmux` | Core | Med |
| [Priority and Nice](priority-and-nice.md) | `nice`, `renice`, `ionice`, `chrt`, autogroup, unit settings | Core | Med |
| [System Calls and Tracing](system-calls-and-tracing.md) | System call path, `errno`, vDSO, `strace`, `ltrace`, `gdb` | Advanced | High |

---

## Scenarios and Labs

- [Process Won't Die](../interview/scenarios/process-wont-die.md): trapped signals, zombies, `D` state and restarting services
- [Processes and Services Lab](../labs/processes-and-services-lab.md): tasks for this module and module 08
- [Disk Full](../interview/scenarios/disk-full.md): finding the process that holds a deleted file
- [Round 4: Internals](../interview/round-4-internals.md): `fork`, signals and system calls
