# umask

The umask is a per-process mask of permission bits that new files and directories do not get. It decides whether files a user or service creates are readable by the group or by everyone, and the default differs between Rocky and Ubuntu.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Starting modes | Programs usually request `666` for files and `777` for directories | `strace -e trace=openat touch f` |
| Rule | Final mode = requested mode with the umask bits removed (bitwise, not subtraction) | `umask 0123; touch f` |
| Execute on files | Never added by the umask; files from `touch` get no `x` | `ls -l` |
| Scope | Per process, inherited by children | `grep Umask /proc/$$/status` |
| Show | `umask` (octal), `umask -S` (symbolic) | `umask -S` |
| Rocky 10.2 default | `0022` for root and regular users | `su - user -c umask` |
| Ubuntu 24.04 default | `0022` for root, `0002` for regular users (`pam_umask` with user private groups) | `su - user -c umask` |
| System setting | `UMASK` in `/etc/login.defs`, applied by `pam_umask` at login | `grep UMASK /etc/login.defs` |
| Per user | `umask` line in `~/.bashrc` or `~/.profile` | `umask` |
| Services | `UMask=` in the unit; PID 1 runs with `0000` | `systemctl show <unit> -p UMask` |
<!-- --8<-- [end:facts] -->

---

## How the Mask Applies

```bash
umask
umask -S
touch f022; mkdir d022
umask 027; touch f027; mkdir d027
umask 077; touch f077; mkdir d077
umask 022
ls -ld f0* d0*
```

Output:

```text
0022
u=rwx,g=rx,o=rx
drwxr-xr-x 2 laborant laborant 4096 Sep 16 14:35 d022
drwxr-x--- 2 laborant laborant 4096 Sep 16 14:35 d027
drwx------ 2 laborant laborant 4096 Sep 16 14:35 d077
-rw-r--r-- 1 laborant laborant    0 Sep 16 14:35 f022
-rw-r----- 1 laborant laborant    0 Sep 16 14:35 f027
-rw------- 1 laborant laborant    0 Sep 16 14:35 f077
```

| umask | New file | New directory | Use |
|---|---|---|---|
| `022` | `644` | `755` | General default |
| `002` | `664` | `775` | Group collaboration with user private groups |
| `027` | `640` | `750` | Servers: nothing for others |
| `077` | `600` | `700` | Secrets, private work |

The mask removes bits; it never subtracts digits. With `0123`, the file loses only the bits the program requested:

```bash
umask 0123; touch f123; mkdir d123; umask 022
ls -ld f123 d123
```

Output:

```text
drw-r-xr-- 2 laborant laborant 4096 Sep 16 14:35 d123
-rw-r--r-- 1 laborant laborant    0 Sep 16 14:35 f123
```

`666` minus `123` would be `543`, but the file is `644`: the owner `x` bit (`1`) was never requested, so removing it changes nothing.

!!! tip "Set a tight umask for one command"
    A subshell keeps the change local: `(umask 077; openssl genrsa -out app.key 4096)` creates the key as `600` without changing the shell's default.

```bash
(umask 077; touch private.key); ls -l private.key
umask
```

Output:

```text
-rw------- 1 laborant laborant 0 Sep 16 14:35 private.key
0022
```

---

## Defaults by Distribution

=== "RHEL / Rocky"

    ```bash
    grep -E '^(USERGROUPS_ENAB|UMASK)' /etc/login.defs
    grep -n pam_umask /etc/pam.d/*
    sudo su - amor -c umask
    sudo su - -c umask
    ```

    Output:

    ```text
    UMASK		022
    USERGROUPS_ENAB yes
    /etc/pam.d/postlogin:8:session     optional                   pam_umask.so silent
    0022
    0022
    ```

=== "Ubuntu / Debian"

    ```bash
    grep -iE '^\s*umask|^USERGROUPS' /etc/login.defs
    grep -n '^session.*pam_umask' /etc/pam.d/common-session
    sudo su - umtest -c umask
    sudo su - -c umask
    sudo -u umtest bash -c 'cd /tmp && touch umtest-file && mkdir umtest-dir && ls -ld umtest-file umtest-dir'
    ```

    Output:

    ```text
    UMASK		022
    USERGROUPS_ENAB yes
    26:session optional			pam_umask.so
    0002
    0022
    drwxrwxr-x 2 umtest umtest 4096 Sep 16 14:35 umtest-dir
    -rw-rw-r-- 1 umtest umtest    0 Sep 16 14:35 umtest-file
    ```

    With `USERGROUPS_ENAB yes`, `pam_umask` gives group write to users whose primary group has the same name as the user, because that group contains only them.

!!! warning "The same script creates different modes on each family"
    A deployment that creates files as a regular user produces `664` on Ubuntu and `644` on Rocky. Scripts that depend on a mode set it explicitly (`install -m`, `chmod`) or set `umask` at the top.

---

## Where the umask Comes From

```bash
grep -E '^Umask' /proc/$$/status
grep -E '^Umask' /proc/1/status
systemctl show sshd -p UMask
python3 -c 'import os; fd=os.open("/tmp/um/py600", os.O_CREAT|os.O_WRONLY, 0o666); print(oct(os.stat("/tmp/um/py600").st_mode & 0o777))'
```

Output:

```text
Umask:	0022
Umask:	0000
UMask=0022
0o644
```

| Source | Applies to |
|---|---|
| `UMASK` in `/etc/login.defs` via `pam_umask` | Login sessions (console, SSH, `su -`) |
| `umask` in `/etc/profile`, `/etc/bashrc`, `~/.bashrc` | Shells that read those files |
| `UMask=` in a systemd unit (default `0022`) | That service and its children |
| `umask()` system call | The process that calls it |

The kernel always applies the mask, even when a program asks for `0666` explicitly, as the Python example shows.

---

## Common Errors

### `bash: line 1: umask: 999: octal number out of range`

**Cause:** umask values are octal; `8` and `9` are invalid digits.

**Fix:** use digits 0 to 7, or symbolic form such as `umask u=rwx,g=rx,o=`. When a service's files lack group write instead, set `UMask=0002` in its unit or add a default ACL to the directory.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is umask, and what mode does a new file get with umask 022?"
    **Say first:** a mask of bits removed from newly created files; with `022`, files requested as `666` become `644` and directories requested as `777` become `755`.

    **Proof:** `umask 022; touch f; mkdir d; ls -ld f d`

    **Follow-up:** Why do new files never get the execute bit from `touch`?

??? question "L1: Is the umask subtracted from 666?"
    **Say first:** no, its bits are cleared with a bitwise AND of the complement; subtraction gives wrong answers when the mask removes bits that were not set.

    **Proof:** `umask 0123; touch f` gives `644`, not `543`.

    **Follow-up:** What mode does a directory get with the same mask?
<!-- --8<-- [end:l1] -->

??? question "L2: Make every file a user creates unreadable by others, permanently."
    **Say first:** set the umask in the user's shell startup file.

    **Proof:** `echo 'umask 027' >> ~/.bashrc`, then a new shell shows `umask` `0027`.

    **Follow-up:** Would that apply to cron jobs the user runs?

??? question "L2: Show the umask of a running service."
    **Say first:** read it from `/proc`.

    **Proof:** `grep Umask /proc/$(systemctl show -p MainPID --value nginx)/status`

    **Follow-up:** How do you change it? (`UMask=` in a drop-in.)

??? question "L2: Create a private key file that is never readable by others, even briefly."
    **Say first:** set the umask before the file is created.

    **Proof:** `(umask 077; openssl genrsa -out app.key 4096)`

    **Follow-up:** Why is `chmod 600` afterwards not equivalent? (A window where the key is world-readable.)

??? question "L3: Files uploaded through an application cannot be edited by the ops group."
    **Say first:** check the mode of new files and the service's umask.

    **Proof:** new files are `-rw-r--r--`; `/proc/<pid>/status` shows `Umask: 0022`; the unit sets no `UMask=`.

    **Follow-up:** Compare fixing it with `UMask=0002` and with a default ACL.

??? question "L3: A script creates group-writable files on one server and read-only files on another."
    **Say first:** compare the login umask on both.

    **Proof:** `su - user -c umask` prints `0002` on Ubuntu and `0022` on Rocky 10.2.

    **Follow-up:** How should the script make the result consistent?

---

## Related

- [Basic Permissions](basic-permissions.md): what the resulting bits mean
- [ACL](acl.md): default ACLs override the umask for group access
- [PAM](../04-users-and-access/pam.md): where `pam_umask` runs
- [Groups](../04-users-and-access/groups.md): user private groups

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
