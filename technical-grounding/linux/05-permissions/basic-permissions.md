# Basic Permissions

Every file has an owner, a group and three permission sets (user, group, other), each with read, write and execute bits. Most "Permission denied" errors come from the directory bits, not the file bits, because `x` on a directory controls access to everything inside it.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Permission string | Type, then `rwx` for user, group, other | `ls -l` |
| Octal values | `r` 4, `w` 2, `x` 1; `640` = `rw-r-----` | `stat -c '%a %A' f` |
| File `r`, `w`, `x` | Read content, change content, run as a program | `cat`, `echo >>`, `./f` |
| Directory `r` | List names | `ls dir` |
| Directory `w` | Create, delete and rename entries (with `x`) | `touch dir/f` |
| Directory `x` | Enter and reach entries by name | `cd dir` |
| Deleting a file | Needs `w` and `x` on the directory, not on the file | `rm dir/f` |
| Check order | Owner match, else group match, else other; only the first match applies | `ls -l` |
| Root | Bypasses read and write checks; needs at least one `x` bit to execute | `sudo cat f` |
| `chown` | Only root changes the owner | `sudo chown user:group f` |
| `chgrp` | Owner may change to a group they belong to | `chgrp devs f` |
| Capital `X` | Execute only for directories and already-executable files | `chmod -R u=rwX,go=rX dir` |
| Every parent matters | Each directory on the path needs `x` | `namei -l /path/to/file` |
<!-- --8<-- [end:facts] -->

---

## Reading and Changing Modes

```bash
sudo touch report.txt
ls -l report.txt
stat -c '%A %a %U %G %n' report.txt
sudo chmod 640 report.txt; ls -l report.txt
sudo chmod u+x,g-r,o=r report.txt; ls -l report.txt
sudo chmod a=r report.txt; ls -l report.txt
```

Output:

```text
-rw-r--r-- 1 root root 0 Sep 16 14:33 report.txt
-rw-r--r-- 644 root root report.txt
-rw-r----- 1 root root 0 Sep 16 14:33 report.txt
-rwx---r-- 1 root root 0 Sep 16 14:33 report.txt
-r--r--r-- 1 root root 0 Sep 16 14:33 report.txt
```

| Octal | Symbolic | Typical use |
|---|---|---|
| `644` | `rw-r--r--` | Normal files |
| `640` | `rw-r-----` | Config files readable by a service group |
| `600` | `rw-------` | Private keys, credentials |
| `755` | `rwxr-xr-x` | Programs, normal directories |
| `750` | `rwxr-x---` | Directories shared with one group |
| `700` | `rwx------` | Home directories, `~/.ssh` |
| `777` | `rwxrwxrwx` | Almost never correct |

Symbolic mode uses `u`, `g`, `o`, `a` with `+`, `-` or `=`, and changes only what it names; octal mode sets all bits at once.

---

## Ownership

```bash
sudo chown amor report.txt
sudo chown amor:devs report.txt
sudo chgrp devs report.txt
ls -l report.txt
chown ibtisam report.txt
echo "rc=$?"
```

Output:

```text
-rw-r----- 1 amor devs 0 Sep 16 14:33 report.txt
chown: changing ownership of 'report.txt': Operation not permitted
rc=1
```

Only root can give a file away; otherwise users could evade disk quotas or plant files that appear to belong to someone else.

---

## Directory Permissions

User `ibtisam` falls into "other" for three directories owned by root: `d-rw` (other `rw-`), `d-x` (other `--x`) and `d-rx` (other `r-x`). Each holds a readable file `f`.

```bash
sudo -u ibtisam ls -l d-rw
sudo -u ibtisam cat d-rw/f
sudo -u ibtisam ls d-x
sudo -u ibtisam cat d-x/f
sudo -u ibtisam ls d-rx
sudo -u ibtisam cat d-rx/f
```

Output:

```text
ls: cannot access 'd-rw/f': Permission denied
total 0
-????????? ? ? ? ?            ? f
cat: d-rw/f: Permission denied
ls: cannot open directory 'd-x': Permission denied
secret
f
secret
```

| Directory bits for the user | `ls dir` | `cat dir/f` (known name) | `touch dir/new` |
|---|---|---|---|
| `r--` or `rw-` | Names only, metadata shown as `?` | Denied | Denied |
| `--x` | Denied | Allowed | Denied |
| `r-x` | Allowed | Allowed | Denied |
| `-wx` | Denied | Allowed | Allowed |
| `rwx` | Allowed | Allowed | Allowed |

!!! warning "Write on a directory lets anyone delete files in it"
    In a directory with mode `777`, `ibtisam` deleted a file owned by `amor` with mode `400`: the file's own permissions do not matter for deletion. The sticky bit (`/tmp`) prevents this; see [Special Permissions](special-permissions.md).

```bash
sudo mkdir shared && sudo chmod 777 shared
sudo -u amor touch shared/amor.txt
sudo chmod 400 shared/amor.txt
sudo -u ibtisam rm -f shared/amor.txt; echo "rc=$?"
ls shared
```

Output:

```text
rc=0
```

`namei -l` shows every directory on a path, which finds the component that blocks access:

```bash
namei -l /srv/perm/d-x/f
```

Output:

```text
f: /srv/perm/d-x/f
drwxr-xr-x root root /
drwxr-xr-x root root srv
drwxr-xr-x root root perm
drwx-----x root root d-x
-rw-r--r-- root root f
```

---

## How the Kernel Chooses a Permission Set

Only one set applies: the owner set if the UID matches, otherwise the group set if any group matches, otherwise the other set. An owner with fewer rights than the group is still limited to the owner bits.

```bash
sudo touch order.txt; sudo chown amor:devs order.txt; sudo chmod 070 order.txt
sudo -u amor cat order.txt; echo "rc=$?"
sudo install -d -m 755 -o amor dir-owner
sudo -u amor touch dir-owner/f
sudo chmod 000 dir-owner/f; ls -l dir-owner/f
sudo -u amor cat dir-owner/f
sudo -u amor chmod 600 dir-owner/f; sudo -u amor cat dir-owner/f; echo "rc=$?"
sudo cat dir-owner/f; echo "root rc=$?"
```

Output:

```text
cat: order.txt: Permission denied
rc=1
---------- 1 amor amor 0 Sep 16 14:33 dir-owner/f
cat: dir-owner/f: Permission denied
rc=0
root rc=0
```

`amor` is in `devs`, but as the owner only the empty owner bits applied. An owner can always `chmod` their own file back; root reads it regardless of mode.

---

## Recursive Changes and Execute

```bash
sudo chmod -R 644 tree
sudo -u amor ls -l tree
sudo -u amor cat tree/sub/b.txt
sudo chmod -R u=rwX,go=rX tree
sudo -u amor cat tree/sub/b.txt && echo "readable again"
ls -ld tree tree/a.sh
```

Output:

```text
ls: cannot access 'tree/a.sh': Permission denied
ls: cannot access 'tree/sub': Permission denied
total 0
-????????? ? ? ? ?            ? a.sh
d????????? ? ? ? ?            ? sub
cat: tree/sub/b.txt: Permission denied
readable again
drwxr-xr-x 3 root root 4096 Sep 16 14:33 tree
-rw-r--r-- 1 root root    0 Sep 16 14:33 tree/a.sh
```

!!! danger "chmod -R 644 removes execute from directories"
    Directories without `x` cannot be entered, so the whole tree becomes unusable. Use capital `X`, or `find dir -type d -exec chmod 755 {} +` and `find dir -type f -exec chmod 644 {} +`.

A script without `x` fails when run directly, but works through its interpreter, which only needs to read it:

```bash
printf '#!/bin/bash\necho hi\n' | sudo tee run.sh >/dev/null
sudo chmod 644 run.sh
sudo -u amor bash -c 'cd /srv/perm && ./run.sh'; echo "rc=$?"
sudo -u amor bash /srv/perm/run.sh
```

Output:

```text
bash: line 1: ./run.sh: Permission denied
rc=126
hi
```

---

## Common Errors

### `chown: changing ownership of 'report.txt': Operation not permitted`

**Cause:** a non-root user tried to change the owner.

**Fix:** `sudo chown`.

### `ls: cannot access 'd-rw/f': Permission denied`

**Cause:** the directory has `r` but not `x` for the caller, so names are readable but metadata is not; the listing shows `-?????????`.

**Fix:** add `x` on the directory (`chmod o+x`), or `u=rwX` recursively.

### `bash: line 1: ./run.sh: Permission denied`

**Cause:** the file lacks `x` for the caller, or its filesystem is mounted `noexec`; the exit status is 126.

**Fix:** `chmod +x`, or check `findmnt -no OPTIONS -T <file>`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do read, write and execute mean on a directory?"
    **Say first:** `r` lists names, `w` creates and deletes entries (together with `x`), and `x` lets a process enter the directory and reach entries by name.

    **Proof:** with `--x`, `ls dir` fails but `cat dir/f` works.

    **Follow-up:** Which permission is needed to delete a file?

??? question "L1: What does chmod 750 mean?"
    **Say first:** owner `rwx`, group `r-x`, others nothing: 7 = 4+2+1, 5 = 4+1, 0.

    **Proof:** `chmod 750 dir; stat -c '%a %A' dir`

    **Follow-up:** Why is `750` a common mode for application directories?

??? question "L1: If a user is the owner and also in the file's group, which permissions apply?"
    **Say first:** only the owner bits; the kernel stops at the first matching class.

    **Proof:** mode `070` with owner `amor` in group `devs`: `amor` gets `Permission denied`.

    **Follow-up:** How can the owner regain access? (`chmod u+r`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Give group devs read and write access to /srv/app without giving it to others."
    **Say first:** set the group, then the mode.

    **Proof:**

    ```bash
    sudo chgrp -R devs /srv/app
    sudo chmod -R u=rwX,g=rwX,o= /srv/app
    ```

    **Follow-up:** How do you make new files there inherit the group? (SGID on the directory.)

??? question "L2: Fix a tree where someone ran chmod -R 644."
    **Say first:** restore `x` on directories only.

    **Proof:** `sudo find /srv/app -type d -exec chmod 755 {} +`

    **Follow-up:** Why is `chmod -R 755` wrong for the files?

??? question "L2: Find which directory on a long path blocks access."
    **Say first:** list each component's permissions.

    **Proof:** `namei -l /var/www/app/static/index.html`

    **Follow-up:** What else besides mode bits can deny access? (ACLs, SELinux, `chattr`, mount options.)

??? question "L3: A web server returns 403 for a file whose mode is 644."
    **Say first:** check every parent directory, then ownership and the security layers.

    **Proof:** `namei -l` shows a home directory with mode `700` on the path; the `nginx` user cannot traverse it.

    **Follow-up:** What is the safer fix than `chmod 755 /home/user`?

??? question "L3: Files a user wrote to a shared directory keep disappearing."
    **Say first:** check the directory mode for world or group write without the sticky bit.

    **Proof:** `ls -ld /shared` shows `drwxrwxrwx`; anyone with `w` on the directory can delete any file in it.

    **Follow-up:** Which bit fixes it?

---

## Related

- [Special Permissions](special-permissions.md): SUID, SGID and the sticky bit
- [umask](umask.md): the default mode of new files
- [ACL](acl.md): permissions for more than one user or group
- [Groups](../04-users-and-access/groups.md): group membership that the group bits check

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
