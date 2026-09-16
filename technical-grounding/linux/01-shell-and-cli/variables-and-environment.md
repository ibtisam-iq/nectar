# Variables and Environment

A shell variable lives only in the current shell; an environment variable is copied into every program the shell starts. Most "works in my terminal, fails in cron, sudo or systemd" problems are environment differences, so knowing where each variable comes from is a daily troubleshooting skill.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Shell variable | Visible only in the current shell | `set` |
| Environment variable | Exported; copied to child processes at `exec` | `env`, `printenv` |
| Export | `export VAR=value` or `declare -x VAR` | `declare -p VAR` |
| One-command variable | `VAR=value command` sets it for that command only | `LOG_LEVEL=debug env` |
| Children cannot change parents | A child's `export` never reaches the parent shell | `bash -c 'export X=1'; echo $X` |
| Process environment | Fixed at `exec`; later `export` does not change a running process | `tr '\0' '\n' < /proc/<pid>/environ` |
| `PATH` | Colon-separated directories searched in order; `.` is not included | `echo $PATH` |
| Login shell files | `/etc/profile`, `/etc/profile.d/*.sh`, then the first of `~/.bash_profile`, `~/.bash_login`, `~/.profile` | `bash -l` |
| Non-login interactive files | `~/.bashrc` (which sources `/etc/bashrc` on RHEL) | `bash -i` |
| Scripts, cron, systemd | Read no startup files | `bash -c env` |
| System-wide static variables | `/etc/environment`, read by `pam_env` at login | `cat /etc/environment` |
| `sudo` | Resets the environment and sets `PATH` from `secure_path` | `sudo printenv PATH` |
| Read-only variable | `readonly VAR=value`; cannot be changed or unset | `readonly -p` |
<!-- --8<-- [end:facts] -->

---

## Shell Variables and Exported Variables

```bash
APP_ENV=staging
bash -c 'echo "child sees: [$APP_ENV]"'
export APP_ENV
bash -c 'echo "child sees: [$APP_ENV]"'
declare -p APP_ENV
```

Output:

```text
child sees: []
child sees: [staging]
declare -x APP_ENV="staging"
```

`declare -x` marks the variable as exported. A variable set on the same line as a command reaches that command only:

```bash
unset APP_ENV
LOG_LEVEL=debug bash -c 'echo "one command: [$LOG_LEVEL]"'
echo "shell after: [$LOG_LEVEL]"
```

Output:

```text
one command: [debug]
shell after: []
```

A subshell `( ... )` gets a copy of every variable, exported or not, and its changes stay inside it:

```bash
x=1; ( x=2; echo "subshell x=$x" ); echo "parent x=$x"
```

Output:

```text
subshell x=2
parent x=1
```

| Command | Shows |
|---|---|
| `set` | Every shell variable and function |
| `env`, `printenv` | Exported variables only |
| `declare -p VAR` | One variable with its attributes |
| `export -p` | Every exported variable |
| `unset VAR` | Removes a variable |
| `env -i command` | Runs a command with an empty environment |

```bash
env -i bash -c 'env'
```

Output:

```text
PWD=/home/laborant
SHLVL=0
_=/usr/bin/env
```

Even with `env -i`, bash sets `PWD`, `SHLVL` and `_` itself.

---

## The Environment of a Running Process

Each process receives its environment in the `execve` call and keeps that copy. A later `export` in the parent changes the parent only:

```bash
export STAGE=blue
sleep 60 &
pid=$!
export STAGE=green
tr '\0' '\n' < /proc/$pid/environ | grep STAGE
echo "shell now: $STAGE"
```

Output:

```text
STAGE=blue
shell now: green
```

!!! warning "Changing an environment file does not change running services"
    A service started before `/etc/environment` or a unit's `Environment=` was edited keeps the old values. Restart the service, then confirm with `/proc/<pid>/environ` (root is needed for other users' processes).

---

## PATH

```bash
echo "$PATH" | tr ':' '\n'
```

Output:

```text
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
/usr/games
/usr/local/games
/snap/bin
```

Directories are searched left to right, and the first match wins. Prepend to prefer a directory; append to use it as a fallback:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

!!! danger "Never put . or an empty entry in PATH"
    `PATH=:/usr/bin` or `PATH=.:$PATH` makes the shell run a file named `ls` from whatever directory is current, including world-writable ones such as `/tmp`.

---

## Startup Files

`strace` shows which files bash opens for a login shell:

```bash
strace -f -e trace=openat -o /tmp/login.txt bash -l -i -c true 2>/dev/null
grep -v ENOENT /tmp/login.txt | grep -oE '"(/etc/[^"]*(profile|bashrc|environment)[^"]*|/home/laborant/\.[a-z_]+)"' | uniq
```

=== "RHEL / Rocky"

    Output:

    ```text
    "/etc/profile"
    "/etc/profile.d/"
    "/etc/profile.d/70-systemd-shell-extra.sh"
    "/etc/profile.d/bash_completion.sh"
    # ... (trimmed)
    "/etc/profile.d/which2.sh"
    "/etc/profile.d/sh.local"
    "/etc/bashrc"
    "/home/laborant/.bash_profile"
    "/home/laborant/.bashrc"
    "/etc/bashrc"
    ```

=== "Ubuntu / Debian"

    Output:

    ```text
    "/etc/profile"
    "/etc/bash.bashrc"
    "/etc/profile.d/"
    "/etc/profile.d/01-locale-fix.sh"
    "/etc/profile.d/bash_completion.sh"
    "/home/laborant/.profile"
    "/home/laborant/.bashrc"
    "/home/laborant/.bash_history"
    ```

The same trace for `bash -i -c true` (interactive, non-login) opens only `~/.bashrc` and the files it sources, and `bash -c true` opens none.

| Shell type | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| Login (SSH, `su -`, `bash -l`) | `/etc/profile` (sources `profile.d` and `/etc/bashrc`), `~/.bash_profile` (sources `~/.bashrc`) | `/etc/profile` (sources `/etc/bash.bashrc` and `profile.d`), `~/.profile` (sources `~/.bashrc`) |
| Interactive non-login (new terminal tab) | `~/.bashrc` (sources `/etc/bashrc`, which sources `profile.d`) | `/etc/bash.bashrc`, `~/.bashrc` |
| Non-interactive (scripts, cron, systemd) | None (`$BASH_ENV` if set) | None (`$BASH_ENV` if set) |

| Change | Where to put it |
|---|---|
| Aliases, functions, prompt for one user | `~/.bashrc` |
| Environment for one user's logins | `~/.bash_profile` (RHEL) or `~/.profile` (Ubuntu) |
| Environment for every user's shells | A new file in `/etc/profile.d/` |
| Static `KEY=value` for every session, any shell | `/etc/environment` |
| A service | `Environment=` or `EnvironmentFile=` in the unit |
| A cron job | Variables at the top of the crontab, or in the script |

!!! tip "Editing a startup file does not affect the current shell"
    `source ~/.bashrc` (or `. ~/.bashrc`) re-reads it in the current shell. Running `bash ~/.bashrc` would load it into a child that exits immediately.

---

## Environments Without Startup Files

=== "RHEL / Rocky"

    ```bash
    grep -E '^(SHELL|PATH|MAILTO)' /etc/crontab
    sudo printenv PATH
    sudo grep -E '^Defaults\s+(env_reset|secure_path)' /etc/sudoers
    ```

    Output:

    ```text
    SHELL=/bin/bash
    PATH=/sbin:/bin:/usr/sbin:/usr/bin
    MAILTO=root
    /sbin:/bin:/usr/sbin:/usr/bin
    Defaults    env_reset
    Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin
    ```

=== "Ubuntu / Debian"

    ```bash
    cat /etc/environment
    export APP_ENV=staging
    sudo bash -c 'echo "sudo sees: [$APP_ENV]"'
    sudo -E bash -c 'echo "sudo -E sees: [$APP_ENV]"'
    sudo printenv PATH
    ```

    Output:

    ```text
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
    sudo sees: []
    sudo -E sees: [staging]
    /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
    ```

A systemd service gets only what the unit defines, plus systemd's default `PATH`:

```bash
sudo systemd-run --unit=envdemo --wait -q -p Environment=STAGE=svc bash -c 'echo "service sees STAGE=[$STAGE] PATH=$PATH"'
sudo journalctl -u envdemo -o cat --no-pager | grep sees
```

Output:

```text
service sees STAGE=[svc] PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
```

`sudo -E` keeps the caller's variables only when the sudoers policy allows it; `sudo VAR=value command` passes one variable if `setenv` or the `env_keep` list permits it.

---

## Read-Only Variables

Inside a script:

```bash
readonly DB_PORT=5432
DB_PORT=5433
echo "rc=$?"
```

Output:

```text
/tmp/var.sh: line 19: DB_PORT: readonly variable
rc=1
```

`readonly` cannot be undone in the running shell. `TMOUT` is often made read-only in `/etc/profile.d/` to force idle logouts that users cannot disable.

---

## Common Errors

### `sudo: mytool: command not found`

**Cause:** `sudo` replaces `PATH` with `secure_path`, which does not contain `/usr/local/bin` on RHEL or the user's `~/.local/bin`.

**Fix:** call the tool by full path (`sudo "$(command -v mytool)"`), or add the directory to `secure_path` with `visudo`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a shell variable and an environment variable?"
    **Say first:** a shell variable stays in the current shell; an exported variable is copied into the environment of every program the shell starts.

    **Proof:** `X=1; bash -c 'echo $X'` prints nothing; after `export X`, it prints `1`.

    **Follow-up:** Can a child process change a variable in its parent?

??? question "L1: What is the difference between .bashrc and .bash_profile?"
    **Say first:** login shells read `~/.bash_profile` (or `~/.profile` on Ubuntu); interactive non-login shells read `~/.bashrc`; the profile usually sources `.bashrc` so both get the same aliases.

    **Proof:** `strace -e trace=openat bash -l -i -c true` lists the files opened.

    **Follow-up:** Which of them does a cron job read? (Neither.)

??? question "L1: Why is the current directory not in PATH?"
    **Say first:** a file named like a system command in a writable directory would run instead of the real one.

    **Proof:** `echo $PATH` has no `.`; local files run as `./name`.

    **Follow-up:** What does an empty entry (`::`) in `PATH` mean?
<!-- --8<-- [end:l1] -->

??? question "L2: Add ~/bin to PATH permanently for one user."
    **Say first:** prepend it in a startup file that every interactive shell reads.

    **Proof:**

    ```bash
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    command -v mytool
    ```

    **Follow-up:** How would you set it for every user? (`/etc/profile.d/custom-path.sh`.)

??? question "L2: Show the environment of a running process, not of your shell."
    **Say first:** read `/proc/<pid>/environ`, which is NUL-separated.

    **Proof:** `sudo tr '\0' '\n' < /proc/$(pgrep -o nginx)/environ`

    **Follow-up:** Why can this differ from the service's current unit file?

??? question "L2: Run one command with a variable set, without changing the shell."
    **Say first:** put the assignment in front of the command.

    **Proof:** `LOG_LEVEL=debug ./app`

    **Follow-up:** How do you run a command with no inherited environment? (`env -i`.)

??? question "L3: A script works in an SSH session but fails in cron with command not found."
    **Say first:** compare `PATH` in both; cron reads no startup files.

    **Proof:** a job line `* * * * * env > /tmp/cron-env` shows `PATH=/usr/bin:/bin` or the value in `/etc/crontab`; the tool lives in `/usr/local/bin` or `~/.local/bin`.

    **Follow-up:** Name two fixes. (Full paths, or `PATH=` at the top of the crontab.)

??? question "L3: An application reads a new value from /etc/environment in a shell, but the service still uses the old one."
    **Say first:** services do not read `/etc/environment` through a login, and a running process keeps its original environment.

    **Proof:** `sudo tr '\0' '\n' < /proc/<pid>/environ` shows the old value; `systemctl show <unit> -p Environment` shows what the unit sets.

    **Follow-up:** Where should the value go? (`Environment=` or `EnvironmentFile=`, then restart.)

??? question "L3: sudo mytool says command not found, but mytool works without sudo."
    **Say first:** `sudo` swaps `PATH` for `secure_path`.

    **Proof:** `sudo printenv PATH` lacks the directory that `command -v mytool` reports.

    **Follow-up:** Why is `secure_path` a security control?

??? question "L4: How does a program receive its environment, and why can't a child change the parent's?"
    **Say first:** the kernel copies the argument and environment strings passed to `execve` onto the new process's stack; each process owns its copy, and no system call writes into another process's environment.

    **Proof:** `strace -e trace=execve -v bash -c 'env >/dev/null'` shows the environment array; `/proc/<pid>/environ` stays fixed after `export` in the parent.

    **Don't say:** "Environment variables are global to the system."

---

## Related

- [Shell Basics](shell-basics.md): login and interactive shells
- [Command Resolution](command-resolution.md): how `PATH` is searched
- [Quoting and Expansion](quoting-and-expansion.md): `${VAR:-default}` and quoting variables
- [Sudo and Su](../04-users-and-access/sudo-and-su.md): `env_reset` and `secure_path`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
