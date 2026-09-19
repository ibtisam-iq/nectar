# Signals

A signal is a small asynchronous notification the kernel delivers to a process: stop, continue, terminate, reload or a program-defined meaning. Stopping services cleanly, reloading configuration and reading exit codes such as 137 and 143 all depend on knowing which signal does what and which ones a process can catch.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `SIGHUP` (1) | Terminal hung up; daemons use it as "reload configuration" | `kill -HUP <pid>` |
| `SIGINT` (2) | `Ctrl-C` | `kill -INT <pid>` |
| `SIGQUIT` (3) | `Ctrl-\`; terminate with a core dump | `kill -QUIT <pid>` |
| `SIGKILL` (9) | Terminate immediately; cannot be caught, blocked or ignored | `kill -9 <pid>` |
| `SIGTERM` (15) | Polite termination; the default of `kill`, `pkill` and `systemctl stop` | `kill <pid>` |
| `SIGSTOP` (19) / `SIGCONT` (18) | Stop (uncatchable) and resume | `kill -STOP <pid>` |
| `SIGTSTP` (20) | `Ctrl-Z`; a catchable stop | `kill -TSTP <pid>` |
| `SIGCHLD` (17) | A child exited or stopped | `strace -e signal=SIGCHLD` |
| `SIGSEGV` (11) / `SIGPIPE` (13) | Invalid memory access / write to a pipe with no reader | `dmesg`, exit code 141 |
| `SIGUSR1` (10), `SIGUSR2` (12) | Application-defined (log reopen, debug toggle) | `man 7 signal` |
| Exit code | 128 + signal number: 130 INT, 137 KILL, 141 PIPE, 143 TERM | `kill -l 137` |
| `kill -0` | Sends nothing; tests existence and permission | `kill -0 <pid>; echo $?` |
| Permission | A user can signal only processes with the same real or effective UID; root can signal any | `kill 1` as a user |
| Masks | `SigBlk`, `SigIgn`, `SigCgt`, `ShdPnd` in `/proc/<pid>/status` (bit N-1 = signal N) | `grep Sig /proc/<pid>/status` |
| `trap` | Shell handler: `trap 'cmd' TERM`; `trap '' INT` ignores | `trap -p` |
<!-- --8<-- [end:facts] -->

---

## Listing and Naming Signals

```bash
kill -l | head -4
kill -l 15; kill -l TERM; kill -l 137
```

Output:

```text
 1) SIGHUP	 2) SIGINT	 3) SIGQUIT	 4) SIGILL	 5) SIGTRAP
 6) SIGABRT	 7) SIGBUS	 8) SIGFPE	 9) SIGKILL	10) SIGUSR1
11) SIGSEGV	12) SIGUSR2	13) SIGPIPE	14) SIGALRM	15) SIGTERM
16) SIGSTKFLT	17) SIGCHLD	18) SIGCONT	19) SIGSTOP	20) SIGTSTP
TERM
15
KILL
```

`kill -l` with an exit status above 128 translates it to the signal name, which decodes a container or job that ended with 137.

!!! note "Signal numbers differ between architectures"
    The numbers above are for x86_64 and arm64 Linux. Scripts should use names (`kill -TERM`, `trap ... TERM`), which are portable.

---

## Sending Signals

| Command | Sends | Selects by |
|---|---|---|
| `kill <pid>` | `SIGTERM` | PID (or `%job` in a shell) |
| `kill -9 <pid>`, `kill -s KILL <pid>` | `SIGKILL` | PID |
| `pkill <pattern>` | `SIGTERM` | Name, or full command with `-f` |
| `killall <name>` | `SIGTERM` | Exact name (psmisc) |
| `systemctl kill <unit>` | `SIGTERM` | Every process in the unit's cgroup |
| `timeout <secs> <cmd>` | `SIGTERM` after the time limit | The command it started |

```bash
sleep 100 & P=$!; kill $P; wait $P; echo "exit=$?"
sleep 100 & P=$!; kill -9 $P; wait $P; echo "exit=$?"
timeout 2 sleep 10; echo rc=$?; timeout -s KILL 2 sleep 10; echo rc=$?
```

Output:

```text
exit=143
/home/laborant/c/sig.sh: line 2:  2249 Killed                  sleep 100
exit=137
rc=124
/home/laborant/c/sig.sh: line 2:  2274 Killed                  timeout -s KILL 2 sleep 10
rc=137
```

`timeout` returns 124 when its own `SIGTERM` stopped the command; with `-s KILL` the shell sees 137 directly.

`pkill` and `killall` return 1 when nothing matched, which scripts must handle under `set -e`:

```bash
sleep 200 & sleep 201 & sleep 0.2; pkill -f "sleep 20[01]"; echo rc=$?; sleep 0.2; pgrep -a sleep; echo rc=$?
pkill -f nothing-matches; echo rc=$?
killall -v sleep; echo rc=$?
```

Output:

```text
rc=0
rc=1
rc=1
sleep: no process found
rc=1
```

!!! danger "pkill -f matches more than intended"
    `pkill -f java` stops every process whose command line contains "java", including editors and `tail` commands with it in an argument. Check the match with `pgrep -af <pattern>` first, and prefer `systemctl stop` for services.

---

## Permission and kill -0

`kill -0` performs the existence and permission checks without sending anything. A normal user cannot signal root's processes, and even root cannot kill PID 1 with an uncaught signal.

```bash
sleep 100 & P=$!; kill -0 $P && echo alive; kill $P; wait $P 2>/dev/null; kill -0 $P; echo rc=$?
kill -0 1; echo rc=$?
kill 1; echo rc=$?
```

Output:

```text
alive
/home/laborant/c/sig.sh: line 2: kill: (2251) - No such process
rc=1
/home/laborant/c/sig.sh: line 2: kill: (1) - Operation not permitted
rc=1
/home/laborant/c/sig.sh: line 2: kill: (1) - Operation not permitted
rc=1
```

`ESRCH` ("No such process") means the PID is gone; `EPERM` ("Operation not permitted") means it exists but belongs to someone else.

---

## Catching Signals with trap

A handler runs code when a signal arrives; `SIGKILL` and `SIGSTOP` cannot be caught, and `trap` on them has no effect. This script reloads on `HUP`, ignores `INT` and cleans up on `TERM`:

```bash
cat > trapper.sh <<'SHEND'
#!/bin/bash
trap 'echo "got TERM, cleaning up"; exit 0' TERM
trap 'echo "got HUP, reloading"' HUP
trap '' INT
echo "pid $$"
while :; do sleep 1; done
SHEND
chmod +x trapper.sh
./trapper.sh > trap.out 2>&1 &
sleep 0.5
grep -E '^Sig(Blk|Ign|Cgt)' /proc/2237/status
kill -HUP 2237; sleep 1.2; kill -INT 2237; sleep 1.2; ps -o pid,stat,comm -p 2237
kill 2237; sleep 1.5; cat trap.out; wait 2237; echo "exit=$?"
```

Output:

```text
SigBlk:	0000000000010000
SigIgn:	0000000000000006
SigCgt:	0000000000014001
    PID STAT COMMAND
   2237 S    trapper.sh
pid 2237
got HUP, reloading
got TERM, cleaning up
exit=0
```

The masks are hexadecimal bitmaps where bit N-1 stands for signal N. `SigCgt` `0x14001` decodes to the three signals with handlers:

```bash
python3 -c 'import signal; m=0x14001; print([signal.Signals(i).name for i in range(1,65) if m >> (i-1) & 1])'
```

Output:

```text
['SIGHUP', 'SIGTERM', 'SIGCHLD']
```

`SigIgn` `0x6` is `SIGINT` and `SIGQUIT`: a non-interactive shell starts background jobs with both ignored. `SIGKILL` never appears in these masks:

```bash
bash -c 'trap "echo never" KILL; echo trap-set'
```

Output:

```text
trap-set
```

!!! warning "Bash runs a trap only after the current foreground command ends"
    While `sleep 60` runs in the foreground, a `TERM` handler waits up to 60 seconds, and `systemctl stop` may time out and send `SIGKILL`. Long waits in services should run as `sleep 60 & wait $!`, because `wait` returns as soon as a trapped signal arrives.

---

## nohup and SIGHUP

When a terminal closes, the kernel sends `SIGHUP` to the session leader, and an interactive `bash` forwards it to its jobs. `nohup` sets `SIGHUP` to ignored before it execs the command, and ignored signals stay ignored across `exec`.

```bash
nohup sleep 100 >/dev/null 2>&1 &
grep SigIgn /proc/$!/status
kill -HUP $!; sleep 0.3; ps -o pid,stat,comm -p $!
```

Output:

```text
SigIgn:	0000000000000007
    PID STAT COMMAND
   2260 S    sleep
```

`0x7` adds `SIGHUP` (bit 0) to the inherited `SIGINT` and `SIGQUIT`, so the process survived the hangup. [Job Control](job-control.md) shows the same test with a real terminal.

---

## Graceful Stop Sequence

Service managers send `SIGTERM`, wait, then send `SIGKILL`. systemd waits `TimeoutStopSec=` (90 seconds by default), Docker waits 10 seconds, and Kubernetes waits `terminationGracePeriodSeconds` (30 by default).

A unit whose process ignores `SIGTERM` shows the sequence; this one sets `TimeoutStopSec=3`:

```bash
sudo tee /etc/systemd/system/stubborn.service >/dev/null <<'EOF'
[Unit]
Description=Ignores SIGTERM

[Service]
ExecStart=/usr/bin/bash -c 'trap "" TERM; while :; do sleep 1; done'
TimeoutStopSec=3
EOF
sudo systemctl daemon-reload; sudo systemctl start stubborn
time sudo systemctl stop stubborn
journalctl -u stubborn -o cat -n 7 --no-pager
```

Output:

```text

real	0m3.029s
user	0m0.006s
sys	0m0.006s
Stopping stubborn.service - Ignores SIGTERM...
stubborn.service: State 'stop-sigterm' timed out. Killing.
stubborn.service: Killing process 6170 (bash) with signal SIGKILL.
stubborn.service: Killing process 6180 (sleep) with signal SIGKILL.
stubborn.service: Main process exited, code=killed, status=9/KILL
stubborn.service: Failed with result 'timeout'.
Stopped stubborn.service - Ignores SIGTERM.
```

!!! tip "Try SIGTERM before SIGKILL"
    `SIGKILL` skips every handler: buffers are not flushed, lock and PID files stay behind, and child processes may be orphaned. Use it only after `SIGTERM` failed and the process state (`T`, `D` or a busy handler) has been checked.

---

## How Delivery Works

1. `kill()` sets the signal's bit in the target's pending set: per thread (`SigPnd`) or shared by the process (`ShdPnd`).
2. If the signal is not blocked, the kernel wakes the target from an interruptible sleep.
3. When the target next returns from the kernel to user space (after a system call, an interrupt or a reschedule), the kernel checks the pending set.
4. The default action runs in the kernel (terminate, core dump, stop, ignore), or the kernel builds a signal frame on the user stack and jumps to the handler.
5. The handler returns through `rt_sigreturn()`, which restores the saved registers, and an interrupted system call returns `EINTR` or restarts (`SA_RESTART`).

A process in `D` does not reach step 3 until its kernel operation completes, which is why `kill -9` waits. A stopped process keeps `SIGTERM` pending until `SIGCONT`; `SIGKILL` wakes it at once.

---

## Common Errors

### `kill: (1) - Operation not permitted`

**Cause:** the caller does not own the target process (`EPERM`).

**Fix:** use `sudo`, or signal the process as its owner; check the owner with `ps -o user,pid -p <pid>`.

### `kill: (2251) - No such process`

**Cause:** the PID no longer exists (`ESRCH`): the process exited, or a stale PID file points to an old PID.

**Fix:** find the current PID with `pgrep -a <name>` or `systemctl show -p MainPID <unit>`.

### `sleep: no process found`

**Cause:** `killall` found no process with that exact name; it exits 1.

**Fix:** check the name with `pgrep -a`, or use `pkill -f` for a command-line match.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between SIGTERM and SIGKILL?"
    **Say first:** `SIGTERM` asks a process to exit and can be caught for cleanup; `SIGKILL` ends it in the kernel with no chance to react.

    **Proof:** a script with `trap ... TERM` prints its cleanup message on `kill`, while `kill -9` gives exit 137 with no output.

    **Follow-up:** Why should `SIGKILL` be the last resort?

??? question "L1: What do exit codes 130, 137 and 143 mean?"
    **Say first:** 128 plus the signal number: `SIGINT` (Ctrl-C), `SIGKILL` and `SIGTERM`.

    **Proof:** `kill -l 137` prints `KILL`.

    **Follow-up:** A container exits with 137 and nobody ran `kill`. What sent it? (The OOM killer, or a stop timeout.)

??? question "L1: What does SIGHUP do to a daemon?"
    **Say first:** by convention a daemon reloads its configuration and reopens log files; a program with the default action terminates.

    **Proof:** `kill -HUP <nginx master PID>` reloads nginx with the same master PID.

    **Follow-up:** Why do terminal programs die when the SSH session drops?
<!-- --8<-- [end:l1] -->

??? question "L2: Check whether a PID is alive without affecting it."
    **Say first:** send signal 0 and check the status.

    **Proof:** `kill -0 "$pid" 2>/dev/null && echo alive`

    **Follow-up:** Why can `kill -0` fail for a process that is alive? (`EPERM`.)

??? question "L2: Make a shell script clean up its temporary files on Ctrl-C, kill and normal exit."
    **Say first:** trap `EXIT` for cleanup and convert `INT` and `TERM` to an exit.

    **Proof:**

    ```bash
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    ```

    **Follow-up:** Which signal still leaves the files behind?

??? question "L2: Decode which signals a running process catches."
    **Say first:** read `SigCgt` from `/proc/<pid>/status` and map each set bit to a signal.

    **Proof:** `grep SigCgt /proc/<pid>/status`, then decode `0x14001` to `HUP`, `TERM`, `CHLD`.

    **Follow-up:** What does a set bit in `SigBlk` mean?

??? question "L3: systemctl stop takes 90 seconds for a custom service, then it is killed."
    **Say first:** the main process ignores or handles `SIGTERM` slowly, so systemd waits `TimeoutStopSec` and sends `SIGKILL`.

    **Proof:** `journalctl -u <unit>` shows "State 'stop-sigterm' timed out. Killing."; `grep SigIgn /proc/<pid>/status` shows bit 15, or a shell wrapper runs a long foreground command.

    **Follow-up:** How do you fix a shell wrapper? (`exec` the application, or `sleep & wait`.)

??? question "L3: A backup job started over SSH stops every time the laptop disconnects."
    **Say first:** the hangup sends `SIGHUP` to the session, and the job has the default action.

    **Proof:** `grep SigIgn /proc/<pid>/status` shows bit 0 clear.

    **Follow-up:** Compare `nohup`, `setsid`, `tmux` and `systemd-run` for this job.

??? question "L4: What happens in the kernel between kill -TERM and the handler running?"
    **Say first:** the kernel marks the signal pending, wakes the target if it sleeps interruptibly, and on its next return to user space builds a frame on the user stack and jumps to the handler; `rt_sigreturn()` restores the context afterwards.

    **Proof:** `strace -p <pid>` shows `--- SIGTERM {si_signo=SIGTERM, ...} ---`, the handler's system calls, then `rt_sigreturn`.

    **Don't say:** "The sender's process runs the handler."

---

## Related

- [Process States](process-states.md): why `D` and `Z` ignore `kill -9`
- [Job Control](job-control.md): `Ctrl-C`, `Ctrl-Z` and `nohup`
- [Exit Codes and Chaining](../01-shell-and-cli/exit-codes-and-chaining.md): 128+N in scripts
- [Process Won't Die](../interview/scenarios/process-wont-die.md): signals that do not work

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
