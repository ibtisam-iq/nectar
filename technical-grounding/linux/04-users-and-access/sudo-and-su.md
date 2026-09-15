# Sudo and Su

`su` switches to another account by proving that account's password; `sudo` runs one command as another account after proving the caller's own password against a policy in `/etc/sudoers`. Sudo gives per-command control and an audit trail, which is why shared root passwords are avoided.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Policy file | `/etc/sudoers`, mode 0440, edited only with `visudo` | `ls -l /etc/sudoers` |
| Drop-in directory | `/etc/sudoers.d/` (root-owned, mode 0440; names containing `.` or ending in `~` are skipped) | `ls -l /etc/sudoers.d` |
| Rule syntax | `who where=(as_whom) what` | `sudo grep -E '^%' /etc/sudoers` |
| Admin group | `%wheel` on RHEL, `%sudo` on Ubuntu | `id -Gn` |
| Syntax check | `visudo -c` (all files) or `visudo -cf <file>` | `sudo visudo -c` |
| What a user may run | `sudo -l` (self) or `sudo -l -U <user>` | `sudo -l -U <user>` |
| Password asked for | The caller's own password, not root's | `sudo -k whoami` |
| Credential cache | 5 minutes by default, per terminal | `ls /run/sudo/ts/` |
| Environment | Reset (`env_reset`) and `PATH` replaced by `secure_path` | `sudo env` |
| Mechanism | `sudo`, `su` and `passwd` are SUID-root binaries | `ls -l /usr/bin/sudo` |
| Audit trail | journald (tag `sudo`); `/var/log/secure` (RHEL) or `/var/log/auth.log` (Ubuntu) when rsyslog runs | `journalctl -t sudo` |
<!-- --8<-- [end:facts] -->

---

## Su, Su Dash, and Sudo Shells

`su <user>` keeps the current environment and directory; `su - <user>` starts a login shell with the target's environment. The same split exists in sudo as `-s` (shell) and `-i` (login shell).

```bash
cd /tmp
sudo su amor -c 'echo "PWD=$PWD HOME=$HOME USER=$USER"'
sudo su - amor -c 'echo "PWD=$PWD HOME=$HOME USER=$USER"'
```

Output:

```text
PWD=/tmp HOME=/home/amor USER=amor
PWD=/home/amor HOME=/home/amor USER=amor
```

Run as `laborant`, a user with a `NOPASSWD` rule:

```bash
cd /tmp
sudo -s /bin/bash -c 'echo shell: PWD=$PWD HOME=$HOME USER=$USER SUDO_USER=$SUDO_USER'
sudo -i /bin/bash -c 'echo login: PWD=$PWD HOME=$HOME USER=$USER SUDO_USER=$SUDO_USER'
```

Output:

```text
shell: PWD=/tmp HOME=/root USER=root SUDO_USER=laborant
login: PWD=/root HOME=/root USER=root SUDO_USER=laborant
```

| Command | Password asked | Environment | Directory |
|---|---|---|---|
| `su <user>` | Target's | Mostly kept | Unchanged |
| `su - <user>` | Target's | Target's login environment | Target's home |
| `sudo <cmd>` | Caller's | Reset, `secure_path` | Unchanged |
| `sudo -s` | Caller's | Reset, `HOME` set to the target's | Unchanged |
| `sudo -i` | Caller's | Target's login environment | Target's home |

`SUDO_USER` records who invoked sudo, which scripts use to act on the real user's behalf.

---

## Sudoers Rules

```bash
sudo grep -Ev '^\s*#|^$' /etc/sudoers
```

=== "RHEL / Rocky"

    Output:

    ```text
    Defaults   !visiblepw
    Defaults    always_set_home
    Defaults    match_group_by_gid
    Defaults    always_query_group_plugin
    Defaults    env_reset
    # ... (trimmed)
    Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin
    root	ALL=(ALL) 	ALL
    %wheel	ALL=(ALL)	ALL
    ```

    ```bash
    sudo grep -n includedir /etc/sudoers
    ```

    Output:

    ```text
    120:#includedir /etc/sudoers.d
    ```

=== "Ubuntu / Debian"

    Output:

    ```text
    Defaults	env_reset
    Defaults	mail_badpass
    Defaults	secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
    Defaults	use_pty
    root	ALL=(ALL:ALL) ALL
    %admin ALL=(ALL) ALL
    %sudo	ALL=(ALL:ALL) ALL
    @includedir /etc/sudoers.d
    ```

!!! warning "#includedir is a directive, not a comment"
    Older sudoers files write `#includedir`; sudo 1.9.1 added the `@includedir` spelling. Deleting the line "to clean up comments" silently disables every file in `/etc/sudoers.d/`.

A rule reads `user host=(runas_user:runas_group) command`:

| Rule | Meaning |
|---|---|
| `%wheel ALL=(ALL) ALL` | Members of `wheel`, on any host, as any user, any command |
| `deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx` | One exact command as root, no password |
| `amor ALL=(app) /usr/bin/python3 /srv/app/manage.py *` | Commands as `app`, arguments matched by glob |
| `Defaults:deploy !requiretty` | A default applied to one user |

---

## Delegating Specific Commands

A drop-in file keeps local rules out of the package-managed `/etc/sudoers`. Validate the file before installing it, because one syntax error disables sudo for everyone.

```bash
printf 'deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx\ndeploy ALL=(root) /usr/bin/journalctl -u nginx,\n' > /tmp/deploy
sudo visudo -cf /tmp/deploy
```

Output:

```text
/tmp/deploy:2:48: syntax error
deploy ALL=(root) /usr/bin/journalctl -u nginx,
                                               ^
```

```bash
printf 'deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx, /usr/bin/journalctl -u nginx\n' > /tmp/deploy
sudo visudo -cf /tmp/deploy
sudo install -m 0440 -o root -g root /tmp/deploy /etc/sudoers.d/deploy
sudo visudo -c
sudo -l -U deploy
```

Output:

```text
/tmp/deploy: parsed OK
/etc/sudoers: parsed OK
/etc/sudoers.d/deploy: parsed OK
/etc/sudoers.d/laborant: parsed OK

User deploy may run the following commands on rocky-01:
    (root) NOPASSWD: /usr/bin/systemctl restart nginx, /usr/bin/journalctl -u nginx
```

Arguments in a rule are matched exactly. As `deploy`:

```bash
sudo -n /usr/bin/journalctl -u nginx
sudo -n /usr/bin/journalctl -u nginx --no-pager
```

Output:

```text
-- No entries --
sudo: a password is required
```

The extra `--no-pager` made the command different from the rule, so sudo fell back to requiring a password (`-n` refuses to prompt). A trailing `*` in the rule allows extra arguments, which also allows dangerous ones.

!!! danger "Commands that can spawn a shell grant full root"
    Rules for `vi`, `less`, `find`, `tar`, `awk` or any interpreter let the user escape to a root shell. Delegate the narrow command (`systemctl restart nginx`), not a tool that can run other commands.

---

## Distribution Differences

=== "RHEL / Rocky"

    ```bash
    ls -l /usr/bin/sudo /usr/bin/su /usr/bin/passwd
    sudo --version | head -1
    ```

    Output:

    ```text
    -rwsr-xr-x 1 root root  91424 Feb 23  2026 /usr/bin/passwd
    -rwsr-xr-x 1 root root  57344 Jan 15  2026 /usr/bin/su
    ---s--x--x 1 root root 297744 Apr 10 00:00 /usr/bin/sudo
    Sudo version 1.9.17p2
    ```

    RHEL 10 ships `sudo` as mode 4111: executable and SUID, but not readable by ordinary users.

=== "Ubuntu / Debian"

    ```bash
    ls -l /usr/bin/sudo /usr/bin/su /usr/bin/passwd
    sudo --version | head -1
    ```

    Output:

    ```text
    -rwsr-xr-x 1 root root  64152 May 30  2024 /usr/bin/passwd
    -rwsr-xr-x 1 root root  55680 Mar  6  2026 /usr/bin/su
    -rwsr-xr-x 1 root root 277936 Mar  2  2026 /usr/bin/sudo
    Sudo version 1.9.15p5
    ```

---

## Sudo and Shell Builtins

`sudo` executes a program; `cd` is a shell builtin with no program behind it on most systems. The two families behave differently here.

=== "RHEL / Rocky"

    ```bash
    sudo cd /root; echo "exit $?"
    cat /usr/bin/cd
    ```

    Output:

    ```text
    exit 0
    #!/usr/bin/sh
    builtin cd "$@"
    ```

    The `bash` package installs POSIX wrapper scripts such as `/usr/bin/cd`. Sudo runs the wrapper in a child shell, which changes directory and exits, so the caller's directory never changes.

=== "Ubuntu / Debian"

    ```bash
    sudo cd /root; echo "exit $?"
    ```

    Output:

    ```text
    sudo: cd: command not found
    sudo: "cd" is a shell built-in command, it cannot be run directly.
    sudo: the -s option may be used to run a privileged shell.
    sudo: the -D option may be used to run a command in a specific directory.
    exit 1
    ```

To work inside a root-only directory, run a shell (`sudo -s`, `sudo -i`) or pass the path to the command (`sudo ls /root`, `sudo sh -c 'cd /root && ls'`). `sudo -D` works only when the rule grants `runcwd`; otherwise sudo answers `you are not permitted to use the -D option with /bin/ls`.

---

## How Sudo Gets Root

The kernel starts `sudo` with an effective UID of 0 because of the SUID bit. Sudo then applies its own policy before it runs anything as root:

1. Read `/etc/sudoers` and the drop-ins, and find a rule for the calling user (identified by the real UID).
2. Authenticate the caller through PAM (`/etc/pam.d/sudo`) unless the rule says `NOPASSWD` or a valid timestamp exists in `/run/sudo/ts/`.
3. Reset the environment, set `PATH` to `secure_path`, and log the command.
4. Fork; the child switches to the target UID and GID and executes the command. The parent `sudo` stays alive to relay signals and close the PAM session.

```bash
sudo -u amor sleep 30 &
ps -o user,pid,ppid,cmd -C sudo,sleep
sudo journalctl -t sudo --no-pager | grep COMMAND | tail -1
```

Output:

```text
USER         PID    PPID CMD
root        2928    2858 sudo -u amor sleep 30
amor        2931    2928 /usr/bin/coreutils --coreutils-prog-shebang=sleep /bin/sleep 30
Sep 15 12:32:06 rocky-01 sudo[2937]: laborant : PWD=/tmp ; USER=root ; COMMAND=/bin/journalctl -t sudo -n 3 --no-pager
```

`sleep` runs as `amor` (PID 2931) as a child of `sudo`, which stays root (PID 2928); the long command line is RHEL 10's multi-call `coreutils` binary. Each journal entry names the invoking user, the directory, the target user and the command. `passwd` uses the same SUID mechanism to let a normal user rewrite `/etc/shadow`, restricted by its own code to that user's entry.

---

## Common Errors

### `amor is not in the sudoers file.`

**Cause:** no rule matches the user, most often because the user is not in `wheel` or `sudo`, or the session started before the group was added.

**Fix:** `sudo usermod -aG wheel amor` (RHEL) or `sudo usermod -aG sudo amor` (Ubuntu), then a new login. The event is logged: `user NOT in sudoers ; PWD=/home/ibtisam ; USER=root ; COMMAND=/usr/bin/whoami`.

### `sudo: a password is required`

**Cause:** `-n` (non-interactive) was used and the command needs a password, often because arguments do not match a `NOPASSWD` rule exactly.

**Fix:** compare the command with `sudo -l` output character by character.

### `/etc/sudoers.d/deploy:2:48: syntax error`

**Cause:** invalid rule syntax; with a broken file installed, sudo refuses to run at all.

**Fix:** validate with `visudo -cf` before installing. If sudo is already broken, use a root console or `pkexec visudo` where polkit is installed.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between su and sudo?"
    **Say first:** `su` switches user by knowing the target's password; `sudo` runs a command as another user after checking the caller's own password against a policy, and logs it.

    **Proof:** `sudo -l` lists the policy; `journalctl -t sudo` shows each command with the invoking user.

    **Follow-up:** Why do teams disable root's password and rely on sudo?

??? question "L1: What is the difference between su and su -?"
    **Say first:** `su -` starts a login shell with the target's environment and home directory; plain `su` keeps the caller's environment and directory.

    **Proof:** `su amor -c 'echo $PWD'` prints the current directory; `su - amor -c 'echo $PWD'` prints `/home/amor`.

    **Follow-up:** Which sudo options map to the same two behaviours? (`-s` and `-i`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Let the deploy user restart nginx without a password and nothing else."
    **Say first:** a drop-in file with one exact command, validated before install.

    **Proof:**

    ```bash
    echo 'deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx' > /tmp/deploy
    sudo visudo -cf /tmp/deploy
    sudo install -m 0440 /tmp/deploy /etc/sudoers.d/deploy
    sudo -l -U deploy
    ```

    **Follow-up:** Why is `NOPASSWD: /usr/bin/vim /etc/nginx/nginx.conf` a bad rule?

??? question "L2: Show every command a user is allowed to run with sudo."
    **Say first:** `sudo -l -U <user>` as an admin.

    **Proof:** the output lists `(runas) [NOPASSWD:] command` entries, as in the `deploy` example.

    **Follow-up:** Where do those rules come from if `/etc/sudoers` has no line for the user?

??? question "L3: A NOPASSWD rule exists, yet the automation still fails with 'a password is required'."
    **Say first:** compare the exact command and arguments the job runs with the rule.

    **Proof:** `sudo -l -U deploy` shows `/usr/bin/journalctl -u nginx`; the job ran `journalctl -u nginx --no-pager`, which is a different command to sudo.

    **Follow-up:** How do you allow extra arguments without allowing everything?

??? question "L3: A user was added to wheel but still gets 'is not in the sudoers file'."
    **Say first:** check the live session's groups, then whether the rule and the include directive are intact.

    **Proof:** `id` in the user's shell (session groups), `sudo grep -E '^%wheel|includedir' /etc/sudoers`, `sudo visudo -c`.

    **Follow-up:** What happens to sudo if one file in `/etc/sudoers.d/` has a syntax error?

??? question "L3: sudo cd /root appears to succeed, but the directory does not change."
    **Say first:** `cd` is a shell builtin, so sudo cannot change the calling shell's directory.

    **Proof:** on RHEL, `/usr/bin/cd` is a wrapper that runs `builtin cd` in a child shell; on Ubuntu sudo prints `"cd" is a shell built-in command`.

    **Follow-up:** How do you list a root-only directory? (`sudo ls /root`.)

??? question "L4: How does sudo get root privileges, and how does passwd update a root-only file?"
    **Say first:** both are SUID-root binaries: the kernel sets the effective UID to 0 at `exec`, and the program's own checks (sudoers and PAM for sudo, "own entry only" for passwd) decide what to allow.

    **Proof:** `ls -l /usr/bin/sudo /usr/bin/passwd` shows the `s` bit; `ps -o user,pid,ppid,cmd` shows the command running as a child of `sudo`.

    **Don't say:** "sudo temporarily adds the user to the root group."

---

## Related

- [Groups](groups.md): `wheel` and `sudo` membership and when it takes effect
- [PAM](pam.md): the authentication stack sudo and su call
- [Passwords and Aging](passwords-and-aging.md): what `passwd` writes to `/etc/shadow`
- [Users](users.md): service accounts that commands run as

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
