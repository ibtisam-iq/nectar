# File Attributes

Extended file attributes are filesystem flags that apply even to root. The immutable flag (`i`) blocks every change to a file, and the append-only flag (`a`) allows only appends, which explains the classic puzzle "root gets Operation not permitted".

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Show | `lsattr <file>`; `lsattr -d <dir>` for the directory itself | `lsattr f` |
| Set and clear | `chattr +i`, `chattr -i` (root or `CAP_LINUX_IMMUTABLE` only) | `sudo chattr +i f` |
| `i` immutable | No write, delete, rename, link or `chmod`, even for root | `lsattr f` |
| `a` append-only | Opens for append only; no truncate, overwrite or delete | `lsattr log` |
| `i` on a directory | No entries created, removed or renamed; existing files stay writable | `lsattr -d dir` |
| `e` | Extents in use (ext4); informational | `lsattr` |
| Error text | `Operation not permitted` (`EPERM`), not `Permission denied` | `strace` |
| Package | `e2fsprogs`; works on ext4, XFS and btrfs, not on `/proc` | `rpm -qf /usr/bin/chattr` |
| Not shown by `ls -l` | Mode bits look normal | `ls -l` |
<!-- --8<-- [end:facts] -->

---

## Immutable Files

```bash
echo "nameserver 192.0.2.53" | sudo tee resolv.conf >/dev/null
lsattr resolv.conf
sudo chattr +i resolv.conf
lsattr resolv.conf
ls -l resolv.conf
echo "nameserver 198.51.100.53" | sudo tee resolv.conf
sudo rm -f resolv.conf
sudo mv resolv.conf moved.conf
sudo chmod 600 resolv.conf
sudo ln resolv.conf hardlink.conf
```

Output:

```text
--------------e------- resolv.conf
----i---------e------- resolv.conf
-rw-r--r-- 1 root root 22 Sep 16 14:40 resolv.conf
tee: resolv.conf: Operation not permitted
nameserver 198.51.100.53
rm: cannot remove 'resolv.conf': Operation not permitted
mv: cannot move 'resolv.conf' to 'moved.conf': Operation not permitted
chmod: changing permissions of 'resolv.conf': Operation not permitted
ln: failed to create hard link 'hardlink.conf' => 'resolv.conf': Operation not permitted
```

`tee` still printed its input to stdout even though it could not write the file. `ls -l` shows nothing unusual, so `lsattr` is the only way to see the flag.

```bash
sudo chattr -i resolv.conf
echo "nameserver 198.51.100.53" | sudo tee resolv.conf
```

Output:

```text
nameserver 198.51.100.53
```

!!! warning "Immutable files break updates and automation"
    `chattr +i /etc/resolv.conf` is a common way to stop DHCP or NetworkManager from rewriting DNS settings, but package updates and configuration management then fail on that file. Fix the tool that rewrites the file instead, and document any immutable flag that stays.

---

## Append-Only Files

```bash
echo "line 1" | sudo tee audit.log >/dev/null
sudo chattr +a audit.log
lsattr audit.log
echo "line 2" | sudo tee -a audit.log >/dev/null
echo "overwrite" | sudo tee audit.log
sudo truncate -s 0 audit.log
sudo rm audit.log
cat audit.log
```

Output:

```text
-----a--------e------- audit.log
tee: audit.log: Operation not permitted
overwrite
truncate: cannot open 'audit.log' for writing: Operation not permitted
rm: cannot remove 'audit.log': Operation not permitted
line 1
line 2
```

Appending worked; overwriting, truncating and deleting did not. An attacker with root can still remove the flag, so append-only raises the bar rather than guaranteeing integrity; remote logging protects logs properly.

!!! tip "logrotate and append-only logs"
    Rotation renames and truncates files, which `a` forbids. A log with `+a` needs a `prerotate` script that removes the flag and a `postrotate` script that sets it again.

---

## Immutable Directories

```bash
sudo mkdir locked-dir && sudo touch locked-dir/existing
sudo chattr +i locked-dir
sudo touch locked-dir/new
echo "change" | sudo tee locked-dir/existing
lsattr -d locked-dir
```

Output:

```text
touch: cannot touch 'locked-dir/new': Operation not permitted
change
----i---------e------- locked-dir
```

The directory's entries are frozen, but `existing` could still be written: the flag protects the directory, not the files inside it.

---

## Finding Attributes

```bash
lsattr /etc/passwd /usr/bin/ls
lsattr -d /tmp
sudo lsattr -R /srv/attr
sudo find /etc -xdev -type f -exec lsattr {} + 2>/dev/null | grep -- '-i-'
```

Output:

```text
--------------e------- /etc/passwd
--------------e------- /usr/bin/ls
--------------e------- /tmp
--------------e------- /srv/attr/resolv.conf
-----a--------e------- /srv/attr/audit.log
--------------e------- /srv/attr/locked-dir

/srv/attr/locked-dir:
--------------e------- /srv/attr/locked-dir/existing

```

The last command found no immutable files in `/etc`, which is the expected result on a clean system; any hit deserves an explanation.

| Flag | Meaning |
|---|---|
| `i` | Immutable |
| `a` | Append only |
| `e` | Uses extents (set by ext4, cannot be removed) |
| `A` | Do not update access time |
| `d` | Skip in `dump` backups |
| `C` | No copy-on-write (btrfs; useful for VM images and databases) |

---

## Common Errors

```bash
chattr +i resolv.conf
lsattr /proc/cpuinfo
```

Output:

```text
chattr: Operation not permitted while setting flags on resolv.conf
lsattr: Operation not supported While reading flags on /proc/cpuinfo
```

### `rm: cannot remove 'resolv.conf': Operation not permitted`

**Cause:** when root gets this, the file has the `i` or `a` attribute.

**Fix:** `lsattr resolv.conf`, then `sudo chattr -i resolv.conf` (or `-a`) if the change is intended.

### `chattr: Operation not permitted while setting flags on resolv.conf`

**Cause:** only root (with `CAP_LINUX_IMMUTABLE`) can set or clear `i` and `a`.

**Fix:** run it with `sudo`.

### `lsattr: Operation not supported While reading flags on /proc/cpuinfo`

**Cause:** the filesystem does not support these flags.

**Fix:** use them on ext4, XFS or btrfs.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Root cannot delete or edit a file. What could cause that?"
    **Say first:** an extended attribute such as immutable (`i`) or append-only (`a`); also a read-only mount, and on RHEL an SELinux denial.

    **Proof:** `lsattr file` shows `----i---`; the error is `Operation not permitted`, not `Permission denied`.

    **Follow-up:** How do you tell a read-only filesystem apart? (`Read-only file system` error, `findmnt -no OPTIONS`.)

??? question "L1: What is the difference between the i and a attributes?"
    **Say first:** `i` forbids every change; `a` allows only appending, which suits logs.

    **Proof:** `echo x >> f` works with `+a` and fails with `+i`.

    **Follow-up:** Why does `a` break `logrotate`?
<!-- --8<-- [end:l1] -->

??? question "L2: Protect a configuration file from being changed by any process, including package updates."
    **Say first:** set the immutable flag and verify it.

    **Proof:** `sudo chattr +i /etc/app.conf; lsattr /etc/app.conf`

    **Follow-up:** What must be done before the next legitimate change?

??? question "L2: Find all immutable files under /etc."
    **Say first:** run `lsattr` over the files and filter on `i`.

    **Proof:** `sudo find /etc -xdev -type f -exec lsattr {} + 2>/dev/null | grep -- '-i-'`

    **Follow-up:** Why would an attacker set `+i` on a file?

??? question "L3: A DNS change keeps failing: the new /etc/resolv.conf is never written."
    **Say first:** check who manages the file and whether it can be written at all.

    **Proof:** `lsattr /etc/resolv.conf` shows `i`; NetworkManager logs a write failure; `ls -l` looked normal.

    **Follow-up:** What is the right way to pin DNS servers with NetworkManager? (`nmcli con mod ... ipv4.dns`, `ipv4.ignore-auto-dns yes`.)

??? question "L3: After an incident, a startup script cannot be removed even by root."
    **Say first:** treat it as a persistence technique and check attributes before removing.

    **Proof:** `lsattr` shows `i`; `chattr -i` then removal; `ausearch -k` or the shell history shows who set it.

    **Follow-up:** What else would you check for persistence? (Cron, systemd units, `authorized_keys`, SUID files.)

---

## Related

- [Basic Permissions](basic-permissions.md): the mode bits that `ls -l` does show
- [Special Permissions](special-permissions.md): other bits that security audits check
- [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md): where attributes are stored

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
