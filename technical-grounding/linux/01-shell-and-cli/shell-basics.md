# Shell Basics

The shell reads a command line, expands it, and asks the kernel to run programs; the terminal only carries characters between the keyboard, the screen and the shell. Separating terminal, shell and console explains most "works in my SSH session, fails in cron" surprises.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Terminal | Device that carries input and output (`/dev/pts/N` for SSH, `/dev/ttyN` for consoles) | `tty` |
| Shell | Program that parses and runs commands (`bash`, `dash`, `zsh`) | `echo $0` |
| Login shell of a user | Field 7 of `/etc/passwd` | `getent passwd $USER` |
| Allowed login shells | `/etc/shells` | `cat /etc/shells` |
| `/bin/sh` | `bash` on RHEL, `dash` on Ubuntu | `readlink -f /bin/sh` |
| Virtual consoles | `getty@ttyN` services; `Ctrl+Alt+F2` switches on physical machines | `systemctl list-units 'getty@*'` |
| Interactive shell | `$-` contains `i` | `echo $-` |
| Login shell | Started by `login`, `sshd` or `bash -l`; reads profile files | `shopt login_shell` |
| History file | `~/.bash_history`, written when the shell exits | `echo $HISTFILE` |
| Trace a command line | `set -x` prints each command after expansion | `bash -x script.sh` |
<!-- --8<-- [end:facts] -->

---

## Terminal, Shell and Console

| Term | What it is | Example |
|---|---|---|
| Terminal emulator | Graphical program that draws a terminal | GNOME Terminal, iTerm2 |
| Pseudo-terminal (pty) | Kernel device pair used by SSH and terminal emulators | `/dev/pts/0` |
| Virtual console | Text terminal on the machine's own screen | `/dev/tty1` |
| Serial console | Terminal over a serial line; used by VMs and cloud consoles | `/dev/ttyS0` |
| Shell | Command interpreter running inside a terminal | `bash` |

```bash
script -qc 'tty; ps -o pid,tty,comm -p $$' /dev/null </dev/null
ps -o pid,tty,comm -p $$
systemctl list-units --no-legend 'getty@*' 'serial-getty@*'
```

Output:

```text
/dev/pts/0
    PID TT       COMMAND
   3036 pts/0    ps
    PID TT       COMMAND
   3030 ?        bash
  getty@tty1.service         loaded active running Getty on tty1
  serial-getty@ttyS0.service loaded active running Serial Getty on ttyS0
```

`script` allocates a pseudo-terminal, so `tty` reports `/dev/pts/0`. The same shell run by an automation agent has no terminal (`?`), which is also the situation inside cron jobs and systemd services.

---

## Which Shell Is Running

=== "RHEL / Rocky"

    ```bash
    echo "$SHELL"
    cat /etc/shells
    ls -l /bin/sh
    ```

    Output:

    ```text
    /bin/bash
    /bin/sh
    /bin/bash
    /usr/bin/sh
    /usr/bin/bash
    lrwxrwxrwx 1 root root 4 Oct 29  2024 /bin/sh -> bash
    ```

=== "Ubuntu / Debian"

    ```bash
    echo "$SHELL"
    cat /etc/shells
    ls -l /bin/sh
    ```

    Output:

    ```text
    /bin/bash
    # /etc/shells: valid login shells
    /bin/sh
    /usr/bin/sh
    /bin/bash
    /usr/bin/bash
    /bin/rbash
    /usr/bin/rbash
    /usr/bin/dash
    lrwxrwxrwx 1 root root 4 Mar 31  2024 /bin/sh -> dash
    ```

!!! warning "A #!/bin/sh script is not a bash script on Ubuntu"
    `dash` rejects bash features such as `[[ ]]`, arrays and `source`. A script that works when run as `bash script.sh` can fail as `./script.sh` or from cron; use `#!/bin/bash` when the script needs bash.

The failure can be silent. This script starts with `#!/bin/sh` and tests `[[ $name == web* ]]`:

```bash
./check.sh
echo "rc=$?"
bash check.sh
```

Output:

```text
./check.sh: 3: [[: not found
rc=0
matched
```

Under `dash`, the failed test makes the `if` false, and the script still exits 0.

`$SHELL` holds the login shell from `/etc/passwd`, not the shell that is currently running; `echo $0` and `ps -p $$` show the current one.

---

## Interactive and Login Shells

`$-` lists the shell's active options; `i` marks an interactive shell. The `login_shell` option shows whether profile files were read.

```bash
bash -c 'echo $0 $-'
bash -ic 'echo $0 $-'
bash -lc 'shopt -q login_shell && echo login'
```

Output:

```text
bash hBc
bash hiBHc
login
```

| Shell started by | Interactive | Login |
|---|---|---|
| SSH session, console login | Yes | Yes |
| New terminal tab on a desktop | Yes | No (most emulators) |
| `su -`, `sudo -i` | Yes | Yes |
| `bash script.sh`, cron, systemd | No | No |

Startup files per shell type are covered in [Variables and Environment](variables-and-environment.md).

---

## Command Anatomy

A command line is split into words: the first word is the command, words starting with `-` are options, and the rest are arguments. Short options can be combined (`ls -la`); long options use two dashes (`--all`); `--` ends option parsing.

```bash
echo 'ls -l /etc/hostname' | bash -x
```

Output:

```text
+ ls -l /etc/hostname
-rwxr-xr-x 1 root root 9 Sep 16 13:10 /etc/hostname
```

The `+` line is the command after expansion, which is the fastest way to see what a script really ran.

---

## History and Line Editing

```bash
set -o history -o histexpand
HISTTIMEFORMAT='%F %T '
ls -d /etc/ssh
echo !$
history 2
```

Output:

```text
/etc/ssh
echo /etc/ssh
/etc/ssh
    3  2026-09-16 13:35:51 echo /etc/ssh
    4  2026-09-16 13:35:51 history 2
```

Interactive shells enable history expansion by default; the `set` line is needed only in scripts.

| Keys or syntax | Action |
|---|---|
| `Ctrl+R` | Search history backwards |
| `!!` / `!$` / `!n` | Previous command / its last argument / history entry `n` |
| `Alt+.` | Insert the last argument of the previous command |
| `Ctrl+A` / `Ctrl+E` | Start / end of line |
| `Ctrl+W` / `Ctrl+U` / `Ctrl+K` | Delete word before cursor / to start / to end |
| `Ctrl+L` | Clear the screen |
| `Tab`, `Tab Tab` | Complete; list completions (`bash-completion` adds options) |
| `Ctrl+C` / `Ctrl+D` / `Ctrl+Z` | Interrupt / end of input / suspend |

!!! tip "Keep secrets out of history"
    With `HISTCONTROL=ignorespace` (included in Ubuntu's `ignoreboth`), a command that starts with a space is not saved. Passing tokens as arguments still exposes them in `ps` output, so prefer files or environment variables.

---

## Common Errors

### `./check.sh: 3: [[: not found`

**Cause:** the script runs under `dash` (`/bin/sh` on Ubuntu) and uses bash syntax; the format `<script>: <line>: <command>: not found` is dash's.

**Fix:** set the shebang to `#!/bin/bash` or run it with `bash script.sh`.

### `not a tty`

**Cause:** `tty` (exit code 1) or a prompting program runs without a terminal: cron, systemd, CI jobs, `ssh host cmd`.

**Fix:** remove interactive prompts from automation, or force a pseudo-terminal with `ssh -t` when a prompt is required.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a terminal, a shell and a console?"
    **Say first:** the terminal carries text in and out, the shell interprets the commands, and the console is the machine's own terminal (screen or serial line).

    **Proof:** `tty` shows `/dev/pts/0` over SSH; `ps -p $$` shows the shell.

    **Follow-up:** What changes for a program started by cron, which has no terminal?

??? question "L1: What is the difference between a login shell and an interactive shell?"
    **Say first:** a login shell is the first shell of a session and reads profile files; an interactive shell reads commands from a user; SSH gives both, a script gets neither.

    **Proof:** `echo $-` contains `i`; `shopt login_shell` reports `on` after `bash -l`.

    **Follow-up:** Which startup files does each type read?
<!-- --8<-- [end:l1] -->

??? question "L2: Find which shell you are running and which shell the account is configured with."
    **Say first:** the running shell and the configured login shell can differ.

    **Proof:**

    ```bash
    ps -o comm= -p $$
    getent passwd "$USER" | cut -d: -f7
    ```

    **Follow-up:** Why is `$SHELL` not reliable for the first question?

??? question "L2: Show exactly what a command line expands to before it runs."
    **Say first:** turn on execution tracing.

    **Proof:** `set -x; ls $HOME/*.conf; set +x`

    **Follow-up:** How do you trace a whole script without editing it? (`bash -x script.sh`.)

??? question "L2: Re-run the previous command with sudo without retyping it."
    **Say first:** history expansion.

    **Proof:** `sudo !!`

    **Follow-up:** How do you find a command you ran last week? (`Ctrl+R` or `history | grep`.)

??? question "L3: A script works when run by hand but fails with syntax errors from cron."
    **Say first:** compare the interpreter and the environment, starting with the shebang.

    **Proof:** `head -1 script.sh` shows `#!/bin/sh`; `readlink -f /bin/sh` shows `dash`; the failing line uses `[[`.

    **Follow-up:** Which other environment differences does cron introduce? (`PATH`, no terminal, no profile files.)

??? question "L4: What does the shell do when a command is typed and Enter is pressed?"
    **Say first:** it reads the line, splits it into tokens, performs expansions, sets up redirections, resolves the command, then forks a child that calls `execve` and waits for it.

    **Proof:** `strace -f -e trace=clone,execve,wait4 bash -c 'ls /tmp'`

    **Don't say:** "The terminal runs the command."

---

## Related

- [Command Resolution](command-resolution.md): how the shell finds the program
- [Quoting and Expansion](quoting-and-expansion.md): what happens to the words before execution
- [Variables and Environment](variables-and-environment.md): startup files per shell type
- [Architecture](../00-foundations/architecture.md): fork, exec and system calls

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
