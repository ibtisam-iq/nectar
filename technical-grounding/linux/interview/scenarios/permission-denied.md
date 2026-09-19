# Permission Denied

An application logs `Permission denied` on a file it should be able to use. The interviewer checks whether the candidate goes past file modes to ACLs, attributes, mount options and mandatory access control, and reads which layer actually refused.

---

## Symptom

> "The app logs Permission denied on a file it should be able to read (or on a binary it should run), but the owner and mode look right."

---

## Clarifying Questions

- **Read, write or execute?** Each maps to different causes (`w` blocked by a read-only mount or immutability, `x` by `noexec`).
- **Which user, and is it a confined service?** An unconfined shell user is limited by DAC; a service like nginx is also limited by SELinux.
- **File or a directory on the path?** A missing `x` on a parent directory blocks access to everything inside.
- **On RHEL or Ubuntu?** Points to SELinux or AppArmor for the mandatory-access layer.

---

## Diagnostic Path

On `web` (Rocky Linux 10.2), the user `deploy` reads `/srv/app/config`.

### 1. File Mode

```bash
ls -l /srv/app/config
sudo -u deploy cat /srv/app/config; echo "exit=$?"
```

Output:

```text
-rw-r-----. 1 root root 12 Sep 17 17:08 /srv/app/config
cat: /srv/app/config: Permission denied
exit=1
```

Mode `640`, owner `root:root`: `deploy` is neither owner nor in group `root`, so `other` (no bits) applies. This is ordinary discretionary access control.

### 2. An ACL Grants One User

```bash
sudo setfacl -m u:deploy:r /srv/app/config
getfacl -pt /srv/app/config | grep -vE '^$'
ls -l /srv/app/config
sudo -u deploy cat /srv/app/config; echo "exit=$?"
```

Output:

```text
# file: /srv/app/config
USER   root      rw-     
user   deploy    r--     
GROUP  root      r--     
mask             r--     
other            ---     
-rw-r-----+ 1 root root 12 Sep 17 17:09 /srv/app/config
secret data
after-acl exit=0
```

The `+` in `ls -l` marks an ACL. `getfacl` shows the extra `user:deploy:r--`, which grants access the mode bits alone would deny. An ACL can also hide access: check `getfacl` when the mode looks permissive but access fails.

### 3. A Directory on the Path

```bash
sudo chmod 750 /srv/app; sudo chown root:root /srv/app
sudo -u deploy cat /srv/app/config; echo "exit=$?"
```

Output:

```text
cat: /srv/app/config: Permission denied
no-traverse exit=1
```

The file is readable, but `/srv/app` is `750` and owned by `root:root`, so `deploy` cannot traverse it. On a directory, `x` means "enter"; without it, nothing inside is reachable whatever the file's own mode.

### 4. An Immutable File

```bash
sudo chmod 777 /srv/app/config
sudo chattr +i /srv/app/config
lsattr /srv/app/config
echo more | sudo tee -a /srv/app/config; echo "exit=$?"
sudo chattr -i /srv/app/config
```

Output:

```text
----i---------e------- /srv/app/config
tee: /srv/app/config: Operation not permitted
root-append exit=1
```

Mode `777` and still `Operation not permitted`, even for root: the immutable attribute (`chattr +i`) blocks every write until it is cleared. `Operation not permitted` (EPERM), not `Permission denied` (EACCES), is the tell.

### 5. A noexec Mount

```bash
sudo mount -t tmpfs -o noexec,nosuid tmpfs /mnt/apps
sudo install -m 755 /dev/stdin /mnt/apps/run.sh <<< $'#!/bin/sh\necho ran'
/mnt/apps/run.sh; echo "direct exit=$?"
sh /mnt/apps/run.sh; echo "via-sh exit=$?"
findmnt -no OPTIONS /mnt/apps
```

Output:

```text
bash: line 1: /mnt/apps/run.sh: Permission denied
direct exit=126
ran
via-sh exit=0
rw,nosuid,noexec,relatime,seclabel
```

Executing the script directly fails with exit 126, although the mode is `755`, because the filesystem is mounted `noexec`. Running it through an interpreter (`sh script`) works, which distinguishes `noexec` from a mode problem. A read-only mount gives `touch: ... Read-only file system` for writes.

### 6. Mandatory Access Control for Services

For a confined service (not an unconfined shell user), SELinux or AppArmor can deny access even when DAC allows it: nginx reading a file with the wrong label logs `Permission denied` while `ls -Z` and an AVC record show the cause. [SELinux](../../15-security/selinux.md#a-denied-file) captures this case.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| File mode | `ls -l`; user not owner/group | `chmod`/`chown`, or add an ACL |
| ACL | `+` in `ls -l`; `getfacl` entry | `setfacl -m`/`-x` |
| Directory traversal | File readable, parent lacks `x` | `chmod o+x`/`g+x` on the directory, or an ACL |
| Immutable attribute | `Operation not permitted` for root; `lsattr` `i` | `chattr -i` |
| `noexec` mount | Exit 126 on run, `sh script` works | Move the binary, or remount without `noexec` |
| Read-only mount | `Read-only file system` on write | Remount `rw`, fix the underlying cause |
| SELinux/AppArmor | Service denied, DAC fine; AVC or `apparmor="DENIED"` | Fix the label/profile, not `setenforce 0` |

---

## Fix

Depends on the branch. For the captured mode case, grant access narrowly with an ACL rather than opening the mode:

```bash
sudo setfacl -m u:deploy:r /srv/app/config
sudo -u deploy cat /srv/app/config    # confirm
```

---

## Prevention

- Prefer group ownership or ACLs over widening modes; never `chmod 777` a shared file.
- Keep `x` on the directories an application must traverse, and check the whole path with `namei -l`.
- Document `noexec`, `nosuid` and read-only mounts, so a deploy to `/tmp` or `/var` fails visibly, not silently.
- On RHEL, fix labels with `restorecon`/`semanage`, and read AVCs before touching enforcement.

---

## Related

- [Basic Permissions](../../05-permissions/basic-permissions.md) and [ACL](../../05-permissions/acl.md): modes and ACLs
- [File Attributes](../../05-permissions/file-attributes.md): `chattr +i`
- [Mounting and fstab](../../12-storage/mounting-and-fstab.md): `noexec`, `nosuid`, read-only
- [SELinux](../../15-security/selinux.md): denied access for confined services

Captured on Rocky Linux 10.2 (SELinux enforcing) on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
