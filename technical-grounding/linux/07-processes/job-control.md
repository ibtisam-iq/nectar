# Job Control

Job control lets an interactive shell run commands in the background, stop them and move them between foreground and background. It also decides what happens to those commands when the terminal or SSH session closes, which is where most "my job died when I logged out" problems start.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `cmd &` | Runs in the background; the shell prints `[job] PID` | `sleep 60 &` |
| `jobs -l` | Lists the shell's jobs with PIDs; `+` is current, `-` is previous | `jobs -l` |
| `Ctrl-Z` | Sends `SIGTSTP`; the job stops | `jobs` shows `Stopped` |
| `bg %n` / `fg %n` | Continue a job in the background / bring it to the foreground | `bg %1` |
| `Ctrl-C` | Sends `SIGINT` to the foreground process group; exit status 130 | `echo $?` |
| `Ctrl-D` | End of input (EOF), not a signal; closes the shell at an empty prompt | `cat` then `Ctrl-D` |
| Job specs | `%1`, `%+`, `%-`, `%sleep` (name prefix) | `kill %1` |
| Terminal hangup | The session leader gets `SIGHUP`; bash sends `SIGHUP` to all its jobs | close the terminal |
| `nohup` | Ignores `SIGHUP`; writes output to `nohup.out` if stdout is a terminal | `nohup cmd &` |
| `disown` | Removes a job from the shell's table, so bash does not send it `SIGHUP` | `disown %1` |
| `setsid` | Starts a command in a new session with no terminal | `setsid cmd` |
| `huponexit` | If set, bash sends `SIGHUP` to jobs on a normal `exit` too (off by default) | `shopt huponexit` |
| `tmux` / `screen` | Keep a whole terminal session alive on the server across disconnects | `tmux attach` |
<!-- --8<-- [end:facts] -->

---

## Background, Stop and Resume

The session below ran in an interactive `bash` on a pseudo-terminal; `^Z` and `^C` are the keys typed.

```bash
sleep 300 &
sleep 400 &
jobs -l
sleep 500
# Ctrl-Z
jobs
bg %3
jobs
kill %1
jobs
fg %2
# Ctrl-C
echo $?
jobs
disown %3
jobs; ps -o pid,ppid,stat,comm -C sleep
```

Output:

```text
$ sleep 300 &
[1] 2597
$ sleep 400 &
[2] 2598
$ jobs -l
[1]-  2597 Running                 sleep 300 &
[2]+  2598 Running                 sleep 400 &
$ sleep 500
^Z
[3]+  Stopped                 sleep 500
$ jobs
[1]   Running                 sleep 300 &
[2]-  Running                 sleep 400 &
[3]+  Stopped                 sleep 500
$ bg %3
[3]+ sleep 500 &
$ jobs
[1]   Running                 sleep 300 &
[2]-  Running                 sleep 400 &
[3]+  Running                 sleep 500 &
$ kill %1
$ jobs
[1]   Terminated              sleep 300
[2]-  Running                 sleep 400 &
[3]+  Running                 sleep 500 &
$ fg %2
sleep 400
^C
$ echo $?
130
$ jobs
[3]+  Running                 sleep 500 &
$ disown %3
$ jobs; ps -o pid,ppid,stat,comm -C sleep
    PID    PPID STAT COMMAND
   2599    2596 S    sleep
```

After `disown`, `jobs` no longer lists `sleep 500`, but the process keeps running as a child of the shell.

| Key or command | Effect |
|---|---|
| `Ctrl-Z` | Stop the foreground job (`SIGTSTP`) |
| `bg` | Resume the current job in the background (`SIGCONT`) |
| `fg` | Resume it in the foreground |
| `Ctrl-C` | Interrupt the foreground job (`SIGINT`) |
| `Ctrl-\` | Quit with a core dump (`SIGQUIT`) |
| `kill %n` | `SIGTERM` to every process of job n |
| `wait` | Block until all background jobs finish |

A background job that reads from the terminal receives `SIGTTIN` and stops at once:

```bash
cat &
jobs
```

Output:

```text
[1] 6329
[1]+  Stopped                 cat
```

!!! note "Give background jobs their own input"
    A job waiting on `SIGTTIN` does nothing until it is brought to the foreground. Redirect stdin from a file or `/dev/null` for anything started with `&`.

---

## What Survives a Closed Terminal

Four background jobs were started in an interactive shell, then the terminal was closed, which sends `SIGHUP` to the shell.

```bash
sleep 601 &
nohup sleep 602 > /dev/null 2>&1 &
setsid sleep 603 &
sleep 604 & disown
ps -o pid,ppid,sid,tty,comm -C sleep
echo '--- after the terminal closed ---'
ps -o pid,ppid,sid,tty,args -C sleep
```

Output:

```text
$ sleep 601 &
[1] 2645
$ nohup sleep 602 > /dev/null 2>&1 &
[2] 2646
$ setsid sleep 603 &
[3] 2647
$ sleep 604 & disown
[4] 2649
[3]   Done                    setsid sleep 603
$ ps -o pid,ppid,sid,tty,comm -C sleep
    PID    PPID     SID TT       COMMAND
   2645    2643    2643 pts/0    sleep
   2646    2643    2643 pts/0    sleep
   2648       1    2648 ?        sleep
   2649    2643    2643 pts/0    sleep
--- after the terminal closed ---
    PID    PPID     SID TT       COMMAND
   2646       1    2643 ?        sleep 602
   2648       1    2648 ?        sleep 603
   2649       1    2643 ?        sleep 604
```

| Job | Survived | Why |
|---|---|---|
| `sleep 601 &` | No | bash forwarded `SIGHUP`, and `sleep` has the default action |
| `nohup sleep 602 &` | Yes | `SIGHUP` is ignored |
| `setsid sleep 603 &` | Yes | Different session; no terminal to hang up |
| `sleep 604 & disown` | Yes | Not in bash's job table, so bash did not signal it |

`setsid` forked because the shell had made it a process group leader, so the job table reported `Done` for PID 2647 while the real `sleep` ran as PID 2648 in its own session.

!!! warning "nohup does not protect against a closed stdout"
    A `nohup` job that still writes to the terminal gets `EIO` or `SIGPIPE` after the disconnect. Redirect output to a file, as `nohup cmd > job.log 2>&1 &` does.

---

## tmux

`tmux` keeps shells running inside a server process that is independent of the SSH connection. It is the practical choice for long interactive work on a remote host.

| Command | Effect |
|---|---|
| `tmux new -s deploy` | New session named `deploy` |
| `Ctrl-b d` | Detach |
| `tmux ls` | List sessions |
| `tmux attach -t deploy` | Reattach |
| `Ctrl-b c` / `Ctrl-b n` | New window / next window |
| `Ctrl-b %` / `Ctrl-b "` | Split vertically / horizontally |
| `tmux kill-session -t deploy` | End the session |

!!! tip "Use a systemd unit for anything that must outlive a reboot"
    `nohup`, `disown` and `tmux` protect against a disconnect, not against a reboot or a crash. `systemd-run --unit=<name> <cmd>` gives a job logging, restart policy and a status command; see [Systemd Toolbox](../08-systemd-and-services/systemd-toolbox.md).

---

## Common Errors

### `bash: fg: current: no such job`

**Cause:** the job table of this shell is empty: the job finished, was disowned, or belongs to another shell.

**Fix:** find the process with `pgrep -a <name>`; a process from another shell cannot be brought to this terminal, but `reptyr <pid>` can move it on some systems.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does Ctrl-Z do, and how do you continue the job?"
    **Say first:** it sends `SIGTSTP` and stops the foreground job; `bg` continues it in the background and `fg` in the foreground.

    **Proof:** `jobs` shows `Stopped`, then `Running` after `bg %1`.

    **Follow-up:** Which signal do `bg` and `fg` send? (`SIGCONT`.)

??? question "L1: Why does a background job die when the SSH session closes?"
    **Say first:** the hangup sends `SIGHUP` to the shell, which forwards it to its jobs, and the default action of `SIGHUP` is to terminate.

    **Proof:** after closing the terminal, only the `nohup`, `setsid` and `disown` jobs remain in `ps`.

    **Follow-up:** Which of those still dies if it writes to the closed terminal?

??? question "L1: What is the difference between Ctrl-C and Ctrl-D?"
    **Say first:** `Ctrl-C` sends `SIGINT` to the foreground process group; `Ctrl-D` sends end-of-file to a program reading the terminal.

    **Proof:** `sleep 100` then `Ctrl-C` gives `$?` 130; `cat` then `Ctrl-D` exits 0.

    **Follow-up:** Why does `Ctrl-D` log out an empty shell?
<!-- --8<-- [end:l1] -->

??? question "L2: A long command is running in the foreground and the session must be left. Keep it running."
    **Say first:** stop it, resume it in the background, and remove it from the job table.

    **Proof:** `Ctrl-Z`, then `bg`, then `disown -h %1` (or `disown %1`).

    **Follow-up:** What happens to its output?

??? question "L2: Start a job that survives logout and keeps a log."
    **Say first:** ignore `SIGHUP` and redirect every stream.

    **Proof:** `nohup ./backup.sh > backup.log 2>&1 < /dev/null &`

    **Follow-up:** How would you do it with systemd instead? (`systemd-run --unit=backup ./backup.sh`.)

??? question "L2: Kill every job the current shell started."
    **Say first:** pass the job PIDs to `kill`.

    **Proof:** `kill $(jobs -p)`

    **Follow-up:** Why does this not touch disowned processes?

??? question "L3: A developer says their nohup job still stops after they disconnect."
    **Say first:** check what the process receives and where its output goes.

    **Proof:** `grep SigIgn /proc/<pid>/status` for bit 0; `ls -l /proc/<pid>/fd/1` for a terminal device; `journalctl --since` for `SIGPIPE` or an OOM kill.

    **Follow-up:** How does `tmux` avoid the problem?

---

## Related

- [Signals](signals.md): `SIGHUP`, `SIGTSTP` and `SIGCONT`
- [Process Lifecycle](process-lifecycle.md): sessions and process groups
- [Shell Basics](../01-shell-and-cli/shell-basics.md): terminals and shortcuts
- [Systemd Toolbox](../08-systemd-and-services/systemd-toolbox.md): `systemd-run` for long jobs

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
