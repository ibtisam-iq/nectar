# ACL

Access control lists add permissions for specific users and groups beyond the single owner and group of the classic model. They solve "this one extra person needs read access" without changing ownership, and default ACLs make shared directories grant the same access to every new file.

**Track:** RHCSA · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Show | `getfacl <path>` | `getfacl f` |
| Add or change | `setfacl -m u:<user>:<perms>` or `g:<group>:<perms>` | `setfacl -m u:amor:r f` |
| Remove | `setfacl -x u:<user>` (one entry), `setfacl -b` (all) | `setfacl -x u:amor f` |
| Marker in `ls -l` | A `+` after the mode | `ls -l` |
| Mask | Upper limit for named users, named groups and the owning group | `getfacl f` |
| `chmod` on group bits | Changes the mask, not the owning group entry, once an ACL exists | `chmod 600 f; getfacl f` |
| Default ACL | `setfacl -d -m ...` on a directory; inherited by new files and subdirectories | `getfacl dir` |
| Recursive | `setfacl -R`; capital `X` adds execute to directories only | `setfacl -R -m g:ops:rX dir` |
| Backup and restore | `getfacl -R dir > file`; `setfacl --restore=file` | `getfacl -R` |
| Copies | `cp` drops ACLs; `cp -a`, `rsync -A`, `tar --acls` keep them | `ls -l` |
<!-- --8<-- [end:facts] -->

---

## Adding Entries

`secret.conf` is owned by root with mode `640`. User `amor` needs read access, and group `ops` needs read and write:

```bash
getfacl secret.conf
sudo setfacl -m u:amor:r secret.conf
sudo setfacl -m g:ops:rw secret.conf
ls -l secret.conf
getfacl secret.conf
sudo -u amor cat secret.conf
sudo -u bob cat secret.conf
```

Output:

```text
# file: secret.conf
# owner: root
# group: root
user::rw-
group::r--
other::---

-rw-rw----+ 1 root root 12 Sep 16 14:38 secret.conf
# file: secret.conf
# owner: root
# group: root
user::rw-
user:amor:r--
group::r--
group:ops:rw-
mask::rw-
other::---

db password
cat: secret.conf: Permission denied
```

After the ACL was added, the group column of `ls -l` shows the mask (`rw-`), not the owning group's `r--`. `user::` and `group::` without a name are the owner and owning group.

---

## The Mask

The mask caps every named entry and the owning group. `chmod` on a file with an ACL changes the mask:

```bash
sudo chmod 600 secret.conf
getfacl secret.conf
sudo -u amor cat secret.conf
sudo chmod 640 secret.conf
sudo setfacl -m m::r secret.conf
getfacl secret.conf | grep -E 'group:ops|mask'
```

Output:

```text
# file: secret.conf
# owner: root
# group: root
user::rw-
user:amor:r--	#effective:---
group::r--	#effective:---
group:ops:rw-	#effective:---
mask::---
other::---

cat: secret.conf: Permission denied
group:ops:rw-	#effective:r--
mask::r--
```

`#effective:` shows what the entry grants after the mask. A `chmod 600`, often run by a deployment script "to secure a file", silently disabled every ACL entry.

!!! warning "chmod and ACLs interact"
    `chmod g-w` on a file with ACLs removes write from all named users and groups through the mask. Check with `getfacl` after any `chmod`, and restore with `setfacl -m m::rwx`.

---

## Default ACLs on Directories

```bash
sudo mkdir project
sudo setfacl -m g:ops:rwx project
sudo setfacl -d -m g:ops:rwx project
getfacl project
sudo touch project/new.txt; sudo mkdir project/subdir
getfacl --omit-header project/new.txt
getfacl --omit-header project/subdir | grep default
```

Output:

```text
# file: project
# owner: root
# group: root
user::rwx
group::r-x
group:ops:rwx
mask::rwx
other::r-x
default:user::rwx
default:group::r-x
default:group:ops:rwx
default:mask::rwx
default:other::r-x

user::rw-
group::r-x	#effective:r--
group:ops:rwx	#effective:rw-
mask::rw-
other::r--

default:user::rwx
default:group::r-x
default:group:ops:rwx
default:mask::rwx
default:other::r-x
```

The access entry (`-m g:ops:rwx`) lets `ops` use the directory itself; the default entry (`-d`) is copied to new files and subdirectories. The new file's mask is `rw-` because `touch` requested no execute bit. Default ACLs also replace the creating process's umask for group access, which keeps a shared directory group-writable whatever each user's umask is.

---

## Recursion, Backup and Removal

```bash
sudo setfacl -R -m u:bob:rX project
getfacl -R --omit-header project | grep -c bob
getfacl -R project > /tmp/project.acl
sudo setfacl -R -b project
sudo setfacl --restore=/tmp/project.acl
getfacl --omit-header project | head -4
sudo setfacl -x u:amor secret.conf
sudo setfacl -b secret.conf
getfacl --omit-header secret.conf
ls -l secret.conf
```

Output:

```text
3
Warning: option --restore=file is unsafe without option -P (--physical) as it traverses symbolic links in pathnames
user::rwx
user:bob:r-x
group::r-x
group:ops:rwx
user::rw-
group::r--
other::---

-rw-r----- 1 root root 12 Sep 16 14:38 secret.conf
```

---

## Copies Lose ACLs

```bash
sudo setfacl -m u:amor:r secret.conf
sudo cp secret.conf copy1.conf
sudo cp -a secret.conf copy2.conf
ls -l secret.conf copy1.conf copy2.conf
```

Output:

```text
-rw-r-----  1 root root 12 Sep 16 14:38 copy1.conf
-rw-r-----+ 1 root root 12 Sep 16 14:38 copy2.conf
-rw-r-----+ 1 root root 12 Sep 16 14:38 secret.conf
```

!!! tip "Backups must ask for ACLs explicitly"
    Backups and migrations need `cp -a`, `rsync -aAX` or `tar --acls` to keep the entries.

---

## Common Errors

```bash
setfacl -m u:bob:r secret.conf; echo "rc=$?"
sudo setfacl -m u:nosuchuser:r secret.conf; echo "rc=$?"
```

Output:

```text
setfacl: secret.conf: Operation not permitted
rc=1
setfacl: Option -m: Invalid argument near character 3
rc=2
```

### `setfacl: secret.conf: Operation not permitted`

**Cause:** only the owner or root can change a file's ACL.

**Fix:** `sudo setfacl ...`.

### `setfacl: Option -m: Invalid argument near character 3`

**Cause:** the user or group name after `u:` or `g:` does not exist, or the entry is malformed.

**Fix:** `getent passwd <user>`; check the `type:name:perms` format.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: When do you need an ACL instead of normal permissions?"
    **Say first:** when more than one specific user or group needs different access to the same file, which one owner and one group cannot express.

    **Proof:** `setfacl -m u:amor:r,g:ops:rw secret.conf`

    **Follow-up:** How do you see that a file has an ACL? (The `+` in `ls -l`.)

??? question "L1: What is the ACL mask?"
    **Say first:** the maximum permission for named users, named groups and the owning group; entries above it are cut down to it.

    **Proof:** after `chmod 600`, `getfacl` shows `#effective:---` on every named entry.

    **Follow-up:** Which command changes the mask indirectly?
<!-- --8<-- [end:l1] -->

??? question "L2: Give user amor read-only access to one log file without changing its owner or group."
    **Say first:** add a named user entry.

    **Proof:** `sudo setfacl -m u:amor:r /var/log/app/app.log; getfacl /var/log/app/app.log`

    **Follow-up:** What happens to that entry when `logrotate` creates a new file?

??? question "L2: Make every new file in /srv/project writable by group ops."
    **Say first:** access and default ACL on the directory.

    **Proof:**

    ```bash
    sudo setfacl -m g:ops:rwx /srv/project
    sudo setfacl -d -m g:ops:rwx /srv/project
    ```

    **Follow-up:** How do you apply it to files that already exist? (`setfacl -R -m g:ops:rwX`.)

??? question "L3: A user listed in getfacl still gets permission denied."
    **Say first:** check the effective permission after the mask, then the parent directories.

    **Proof:** `getfacl` shows `user:amor:r--  #effective:---` because a `chmod 600` set the mask to `---`.

    **Follow-up:** How do you restore it without editing every entry? (`setfacl -m m::r`.)

??? question "L3: After a server migration, a team lost access to its shared files."
    **Say first:** check whether the copy kept the ACLs.

    **Proof:** `ls -l` shows no `+`; the migration used `cp -r` or `rsync -a` without `-A`.

    **Follow-up:** Which options preserve ACLs and extended attributes? (`cp -a`, `rsync -aAX`, `tar --acls --xattrs`.)

---

## Related

- [Basic Permissions](basic-permissions.md): the owner, group and other bits
- [Special Permissions](special-permissions.md): SGID directories for shared groups
- [umask](umask.md): the default that default ACLs override
- [File Operations](../02-files-and-filesystem/file-operations.md): `cp -a` and metadata

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
