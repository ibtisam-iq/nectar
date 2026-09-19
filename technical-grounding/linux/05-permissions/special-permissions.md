# Special Permissions

Three extra bits sit above `rwx`: SUID runs a program with its owner's identity, SGID runs it with its group or makes a directory pass its group to new files, and the sticky bit stops users from deleting each other's files in shared directories. They power `passwd`, `sudo` and `/tmp`, and they are a standard target of security audits.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| SUID (4000) | Executable runs with the file owner's effective UID | `ls -l /usr/bin/passwd` |
| SGID on a file (2000) | Executable runs with the file group's effective GID | `ls -l /usr/bin/write` |
| SGID on a directory | New files and subdirectories inherit the directory's group; subdirectories also get SGID | `ls -ld /srv/team` |
| Sticky bit (1000) | In a writable directory, only the file owner, directory owner or root may delete or rename a file | `ls -ld /tmp` |
| Display | `s` in the user or group execute position, `t` in the other position | `ls -l` |
| Capital `S` or `T` | The special bit is set but the execute bit under it is not | `chmod 4644 f` |
| Octal | Fourth digit in front: `4755`, `2770`, `1777` | `stat -c %a f` |
| Real vs effective UID | Real is who started the process; effective is used for permission checks | `/proc/<pid>/status` |
| Scripts | Linux ignores SUID and SGID on interpreted scripts | `ls -l script` |
| `chown` | Clears SUID and SGID on the file | `ls -l` |
| `nosuid` mount option | Disables SUID and SGID for the whole filesystem | `findmnt -no OPTIONS <mount>` |
| Audit | `find / -perm -4000` and `-perm -2000` | `sudo find / -xdev -perm /6000` |
<!-- --8<-- [end:facts] -->

---

## Where the Bits Appear

```bash
ls -l /usr/bin/passwd /usr/bin/su /usr/bin/sudo /usr/bin/write
ls -ld /tmp /var/tmp
stat -c '%a %A %n' /usr/bin/passwd /usr/bin/sudo /tmp
```

Output:

```text
-rwsr-xr-x 1 root root  91424 Feb 23  2026 /usr/bin/passwd
-rwsr-xr-x 1 root root  57344 Jan 15  2026 /usr/bin/su
---s--x--x 1 root root 297744 Apr 10 00:00 /usr/bin/sudo
-rwxr-sr-x 1 root tty   24152 Jan 15  2026 /usr/bin/write
drwxrwxrwt 11 root root 4096 Sep 16 14:36 /tmp
drwxrwxrwt  6 root root 4096 Sep 16 14:36 /var/tmp
4755 -rwsr-xr-x /usr/bin/passwd
4111 ---s--x--x /usr/bin/sudo
1777 drwxrwxrwt /tmp
```

`passwd` must update `/etc/shadow`, which only root can write, so it runs as root for every caller. `write` is SGID `tty` so it can write to other users' terminals.

| Setting | Octal | Symbolic |
|---|---|---|
| SUID | `chmod 4755 f` | `chmod u+s f` |
| SGID | `chmod 2755 f` | `chmod g+s f` |
| Sticky | `chmod 1777 d` | `chmod +t d` |
| Remove all three | `chmod 0755 f` (GNU `chmod` keeps directory SGID unless given five digits or `g-s`) | `chmod ug-s,-t f` |

---

## SUID: Real and Effective UID

A small C program prints both user IDs. Compiled on Rocky and installed as root with the SUID bit:

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    printf("real uid=%d effective uid=%d\n", getuid(), geteuid());
    return 0;
}
```

```bash
gcc -o showid showid.c
sudo install -o root -m 4755 showid /usr/local/bin/showid
ls -l /usr/local/bin/showid
sudo -u amor /usr/local/bin/showid
sudo chmod u-s /usr/local/bin/showid
sudo -u amor /usr/local/bin/showid
```

Output:

```text
-rwsr-xr-x 1 root root 16816 Sep 16 14:37 /usr/local/bin/showid
real uid=1002 effective uid=0
real uid=1002 effective uid=1002
```

The real UID still identifies `amor`, which is how `passwd` knows whose password to change; the effective UID 0 passes the permission check on `/etc/shadow`.

!!! danger "A writable SUID-root binary is a root shell"
    If any user can write to a SUID-root program, or the program can be told to run other commands (`find -exec`, `vim :!sh`, `less !`), it hands out root. Keep SUID binaries owned by root, mode `4755` or stricter, and audit them regularly.

Two kernel rules limit the damage:

```bash
sudo chmod 4755 /usr/local/bin/showid
sudo chown amor /usr/local/bin/showid
ls -l /usr/local/bin/showid
printf '#!/bin/bash\nid -un\n' | sudo tee /usr/local/bin/suid-script >/dev/null
sudo chmod 4755 /usr/local/bin/suid-script
ls -l /usr/local/bin/suid-script
sudo -u amor /usr/local/bin/suid-script
```

Output:

```text
-rwxr-xr-x 1 amor root 16816 Sep 16 14:37 /usr/local/bin/showid
-rwsr-xr-x 1 root root 19 Sep 16 14:36 /usr/local/bin/suid-script
amor
```

`chown` cleared the SUID bit, and the SUID script still ran as `amor`: Linux ignores the bit on files started through an interpreter line.

A filesystem mounted `nosuid` disables the bits entirely:

```bash
sudo mkdir -p /mnt/ns
sudo mount -t tmpfs -o nosuid tmpfs /mnt/ns
sudo install -o root -m 4755 /tmp/showid /mnt/ns/showid
ls -l /mnt/ns/showid
sudo -u amor /mnt/ns/showid
findmnt -no OPTIONS /mnt/ns
```

Output:

```text
-rwsr-xr-x 1 root root 16816 Sep 16 14:37 /mnt/ns/showid
real uid=1002 effective uid=1002
rw,nosuid,relatime
```

---

## Capital S and T

```bash
sudo touch s-file
sudo chmod 4644 s-file; ls -l s-file
sudo chmod 4755 s-file; ls -l s-file
sudo chmod 2644 s-file; ls -l s-file
sudo chmod 1644 s-file; ls -l s-file
```

Output:

```text
-rwSr--r-- 1 root root 0 Sep 16 14:36 s-file
-rwsr-xr-x 1 root root 0 Sep 16 14:36 s-file
-rw-r-Sr-- 1 root root 0 Sep 16 14:36 s-file
-rw-r--r-T 1 root root 0 Sep 16 14:36 s-file
```

A capital letter means the special bit has no effect, because nothing can execute the file (or, for `T`, others cannot enter the directory). It usually points to a mistake.

---

## SGID Directories for Team Collaboration

```bash
sudo mkdir -p /srv/team
sudo chgrp devs /srv/team
sudo chmod 2770 /srv/team
ls -ld /srv/team
sudo -u amor touch /srv/team/by-amor.txt
sudo -u amor mkdir /srv/team/sub
sudo -u amor touch /tmp/by-amor-tmp.txt
sudo ls -l /srv/team
ls -l /tmp/by-amor-tmp.txt
```

Output:

```text
drwxrws--- 2 root devs 4096 Sep 16 14:36 /srv/team
total 4
-rw-r--r-- 1 amor devs    0 Sep 16 14:37 by-amor.txt
drwxr-sr-x 2 amor devs 4096 Sep 16 14:36 sub
-rw-r--r-- 1 amor amor 0 Sep 16 14:37 /tmp/by-amor-tmp.txt
```

Files in `/srv/team` got group `devs`, and the subdirectory inherited the SGID bit; the same user's file in `/tmp` got their primary group `amor`. The file is still `644`, so teammates can read it but not edit it: combine the SGID directory with umask `002` or a default ACL.

---

## The Sticky Bit

With mode `3770`, members of `devs` can create files but only delete their own:

```bash
sudo usermod -aG devs ibtisam
sudo chmod 3770 /srv/team
ls -ld /srv/team
sudo -u ibtisam rm /srv/team/by-amor.txt; echo "rc=$?"
sudo -u amor rm /srv/team/by-amor.txt; echo "rc=$?"
```

Output:

```text
drwxrws--T 3 root devs 4096 Sep 16 14:36 /srv/team
rm: cannot remove '/srv/team/by-amor.txt': Operation not permitted
rc=1
rc=0
```

`T` is capital because others have no `x` on the directory; the bit still works for group members.

!!! tip "The standard shared-directory recipe"
    `chgrp team dir; chmod 3770 dir` gives group ownership of new files (SGID), protection against deleting others' files (sticky) and no access for anyone else. Add `setfacl -d -m g:team:rwX dir` if teammates must edit each other's files.

---

## Auditing Special Bits

```bash
sudo find / -xdev -perm -4000 -type f 2>/dev/null | sort | head -12
sudo find / -xdev -perm -2000 -type f 2>/dev/null | sort
```

Output:

```text
/usr/bin/chage
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/crontab
/usr/bin/fusermount3
/usr/bin/gpasswd
/usr/bin/mount
/usr/bin/newgrp
/usr/bin/passwd
/usr/bin/pkexec
/usr/bin/su
/usr/bin/sudo
/usr/bin/plocate
/usr/bin/write
/usr/libexec/utempter/utempter
```

The list should only contain files from packages (`rpm -Vf` or `dpkg -S` confirms the owner). `ping` is not in it: on Rocky 10.2 it is an ordinary binary, and unprivileged ICMP is allowed by `net.ipv4.ping_group_range = 0 2147483647`.

---

## Common Errors

### `rm: cannot remove '/srv/team/by-amor.txt': Operation not permitted`

**Cause:** the directory has the sticky bit, and the caller owns neither the file nor the directory.

**Fix:** the file's owner or root removes it; this is the intended behavior. When a SUID program instead runs as the caller, check for a script, a `nosuid` mount (`findmnt -no OPTIONS -T <file>`) or a `chown` that cleared the bit.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do SUID, SGID and the sticky bit do?"
    **Say first:** SUID runs a program as its owner, SGID runs it as its group or makes a directory pass on its group, and the sticky bit limits deletion in shared directories to each file's owner.

    **Proof:** `ls -l /usr/bin/passwd /usr/bin/write; ls -ld /tmp`

    **Follow-up:** Why does `passwd` need SUID?

??? question "L1: What is the difference between s and S in ls output?"
    **Say first:** lowercase means the special bit and the execute bit are both set; uppercase means the special bit is set without execute, so it has no effect.

    **Proof:** `chmod 4644 f` shows `-rwSr--r--`.

    **Follow-up:** What does `T` mean on a directory?

??? question "L1: What is the difference between the real and the effective UID?"
    **Say first:** the real UID is the user who started the process; the effective UID is the one the kernel uses for permission checks, and SUID changes only the effective one.

    **Proof:** the SUID `showid` program prints `real uid=1002 effective uid=0`.

    **Follow-up:** Where can you see both for a running process? (`Uid:` line in `/proc/<pid>/status`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Create a directory where the team shares files and nobody deletes others' work."
    **Say first:** group ownership, SGID and sticky, no access for others.

    **Proof:**

    ```bash
    sudo mkdir /srv/team && sudo chgrp devs /srv/team && sudo chmod 3770 /srv/team
    ```

    **Follow-up:** How do teammates get write access to each other's files? (Default ACL or umask `002`.)

??? question "L2: List every SUID and SGID file on the root filesystem."
    **Say first:** permission test with the any-bit form.

    **Proof:** `sudo find / -xdev -type f -perm /6000 -ls 2>/dev/null`

    **Follow-up:** How do you check that each one came from a package?

??? question "L3: A security scan flags a SUID binary in /usr/local/bin."
    **Say first:** find out what it is, who owns it, and whether it can run other commands.

    **Proof:** `ls -l`, `rpm -qf` or `dpkg -S` (no package), `strings` or `--help` for exec options; GTFOBins lists common escapes.

    **Follow-up:** How do you prevent SUID binaries on data filesystems? (`nosuid` in `/etc/fstab`.)

??? question "L3: New files in a shared project directory keep getting the wrong group."
    **Say first:** check for the SGID bit on the directory and on its subdirectories.

    **Proof:** `ls -ld` shows `drwxrwx---` without `s`; `chmod g+s` fixes new files, and `find dir -type d -exec chmod g+s {} +` fixes existing subdirectories.

    **Follow-up:** Does SGID change the group of files moved in with `mv`? (No; `mv` keeps the original group.)

??? question "L4: How does passwd update /etc/shadow when a normal user runs it?"
    **Say first:** `execve` sees the SUID bit and sets the process's effective UID to the file owner (root) while keeping the real UID; `passwd` then checks the real UID to decide which account the user may change.

    **Proof:** `ls -l /usr/bin/passwd` shows `rws`; during a change, `/proc/<pid>/status` shows `Uid: 1002 0 0 0`.

    **Don't say:** "passwd asks sudo for permission."

---

## Related

- [Basic Permissions](basic-permissions.md): the `rwx` bits underneath
- [ACL](acl.md): default ACLs for shared directories
- [Sudo and Su](../04-users-and-access/sudo-and-su.md): the SUID `sudo` binary
- [File Attributes](file-attributes.md): another layer that can block root

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
