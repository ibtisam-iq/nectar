# Inodes and Links

An inode is the on-disk record of a file: its type, permissions, owner, size, timestamps and the location of its data. A file name is only a directory entry pointing to an inode, which explains hard links, why `mv` is instant, and why deleting a file does not always free space.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Inode holds | Type, mode, UID, GID, size, timestamps, link count, block pointers | `stat <file>` |
| Inode does not hold | The file name | `ls -i` |
| Directory | A table of name to inode number | `ls -li` |
| Hard link | Another name for the same inode; same filesystem only; not for directories | `ln a b` |
| Symbolic link | A small file containing a path; can cross filesystems and point to directories | `ln -s a b` |
| Link count | Number of names for an inode; a new directory starts at 2 | `stat -c %h <file>` |
| Deletion | `rm` removes a name; data is freed at link count 0 and no open descriptors | `lsof +L1` |
| Inode exhaustion | "No space left on device" with free blocks | `df -i` |
| `mtime` | Content changed | `stat -c %y` |
| `ctime` | Inode changed (content, mode, owner, links); cannot be set by `touch` | `stat -c %z` |
| `atime` | Last read; `relatime` updates it at most once a day | `findmnt -o OPTIONS /` |
| Root inode | 2 on ext4 (XFS uses a different number) | `stat -c %i /` |
<!-- --8<-- [end:facts] -->

---

## What stat Shows

```bash
echo "config v1" > app.conf
stat app.conf
```

Output:

```text
  File: app.conf
  Size: 10        	Blocks: 8          IO Block: 4096   regular file
Device: 253,0	Inode: 130338      Links: 1
Access: (0664/-rw-rw-r--)  Uid: ( 1001/laborant)   Gid: ( 1001/laborant)
Access: 2026-09-16 13:56:56.634849637 +0000
Modify: 2026-09-16 13:56:56.634849637 +0000
Change: 2026-09-16 13:56:56.634849637 +0000
 Birth: 2026-09-16 13:56:56.634849637 +0000
```

`Blocks: 8` counts 512-byte units: a 10-byte file occupies one 4096-byte filesystem block. `Birth` is the creation time, available on ext4, xfs and btrfs with recent `stat`.

---

## Hard Links and Symbolic Links

```bash
ln app.conf hard.conf
ln -s app.conf soft.conf
ls -li
echo "config v2" >> hard.conf
cat app.conf
```

Output:

```text
total 8
130338 -rw-rw-r-- 2 laborant laborant 10 Sep 16 13:56 app.conf
130338 -rw-rw-r-- 2 laborant laborant 10 Sep 16 13:56 hard.conf
130339 lrwxrwxrwx 1 laborant laborant  8 Sep 16 13:56 soft.conf -> app.conf
config v1
config v2
```

`app.conf` and `hard.conf` share inode 130338 and a link count of 2; neither is "the original". The symlink has its own inode and a size of 8, the length of the text `app.conf`.

Removing the first name leaves the data reachable through the hard link and breaks the symlink:

```bash
rm app.conf
ls -li
cat hard.conf
cat soft.conf
echo "rc=$?"
```

Output:

```text
total 4
130338 -rw-rw-r-- 1 laborant laborant 20 Sep 16 13:56 hard.conf
130339 lrwxrwxrwx 1 laborant laborant  8 Sep 16 13:56 soft.conf -> app.conf
config v1
config v2
cat: soft.conf: No such file or directory
rc=1
```

| | Hard link | Symbolic link |
|---|---|---|
| **Points to** | An inode | A path |
| **Own inode** | No | Yes |
| **Across filesystems** | No | Yes |
| **To a directory** | No | Yes |
| **Target deleted** | Data stays while any link remains | Link breaks (dangling) |
| **Permissions shown** | The file's | `lrwxrwxrwx`; the target's mode applies |
| **Typical use** | Backups with shared blocks (`rsync --link-dest`) | Version switching, `/etc/alternatives`, `usrmerge` |

The two restrictions of hard links produce these errors:

```bash
ln ~/links /tmp/dirlink
ln hard.conf /dev/shm/hard.conf
```

Output:

```text
ln: /home/laborant/links: hard link not allowed for directory
ln: failed to create hard link '/dev/shm/hard.conf' => 'hard.conf': Invalid cross-device link
```

Hard links to directories are refused because they could create loops that `find`, `du` and backups would follow forever.

---

## Working with Symlinks

```bash
ln -s /etc/nonexistent broken
find . -xtype l
readlink broken
readlink -f soft.conf
ln -sfn /opt/app-2.0 current
ls -l current
```

Output:

```text
./soft.conf
./broken
/etc/nonexistent
/home/laborant/links/app.conf
lrwxrwxrwx 1 laborant laborant 12 Sep 16 13:56 current -> /opt/app-2.0
```

`find -xtype l` lists dangling links. `ln -sfn` replaces an existing link in one step, which is how release directories switch versions (`current -> releases/2.0`); without `-n`, `ln` would create the new link inside the old target directory.

!!! warning "A relative symlink is relative to the link's directory"
    `ln -s app.conf /etc/app/current.conf` points to `/etc/app/app.conf`, not to `app.conf` in the directory where the command ran. Use an absolute target, or `ln -sr` to compute the relative path.

---

## Directory Link Counts

A directory has one link from its parent and one from its own `.` entry. Each subdirectory adds one more through its `..`.

```bash
ls -ld ~/links; mkdir sub; ls -ld ~/links
```

Output:

```text
drwxrwxr-x 2 laborant laborant 4096 Sep 16 13:56 /home/laborant/links
drwxrwxr-x 3 laborant laborant 4096 Sep 16 13:56 /home/laborant/links
```

---

## Timestamps

```bash
touch -d '2026-01-01' times.txt
stat --printf 'atime %x\nmtime %y\nctime %z\n' times.txt
sleep 2
chmod 640 times.txt
cat times.txt
stat --printf 'atime %x\nmtime %y\nctime %z\n' times.txt
```

Output:

```text
atime 2026-01-01 00:00:00.000000000 +0000
mtime 2026-01-01 00:00:00.000000000 +0000
ctime 2026-09-16 13:57:06.306620314 +0000
atime 2026-09-16 13:57:08.310614223 +0000
mtime 2026-01-01 00:00:00.000000000 +0000
ctime 2026-09-16 13:57:08.310614223 +0000
```

`touch -d` set atime and mtime but not ctime. `chmod` changed ctime only, and `cat` updated atime because it was older than mtime (the `relatime` rule).

| Timestamp | Updated when | Shown by |
|---|---|---|
| `mtime` (modify) | Content is written | `ls -l`, `find -mtime` |
| `ctime` (change) | Content or inode metadata changes | `ls -lc`, `find -ctime` |
| `atime` (access) | File is read, subject to mount options | `ls -lu`, `find -atime` |
| `btime` (birth) | File is created | `stat` |

!!! note "ctime is not creation time"
    `ctime` is the last inode change. Backup tools and intrusion checks use it because `touch` can fake `mtime` and `atime` but not `ctime`.

---

## Inode Numbers and Usage

```bash
ls -i /usr/bin/ls /bin/ls
stat -c '%i %n' / /proc /sys /home
df -i /
```

Output:

```text
1777 /bin/ls
1777 /usr/bin/ls
2 /
1 /proc
1 /sys
783 /home
Filesystem      Inodes IUsed   IFree IUse% Mounted on
/dev/root      5171200 51427 5119773    1% /
```

Inode numbers are unique only within one filesystem, so `/proc` and `/sys` can both have inode 1. ext4 fixes the inode count at `mkfs` time; millions of small files (mail queues, session files, container layers) can exhaust inodes while `df -h` still shows free space.

---

## Deleted but Open Files

Space is released only when the last name and the last open descriptor are gone.

```bash
dd if=/dev/zero of=big.log bs=1M count=500 status=none
df -h / | tail -1
sleep 300 < big.log &
pid=$!
rm big.log
df -h / | tail -1
lsof -a -p "$pid" +L1
ls -l /proc/$pid/fd/0
: > /proc/$pid/fd/0
df -h / | tail -1
kill $pid
```

Output:

```text
/dev/root        79G  2.3G   73G   4% /
/dev/root        79G  2.3G   73G   4% /
COMMAND  PID     USER   FD   TYPE DEVICE  SIZE/OFF NLINK   NODE NAME
sleep   4109 laborant    0r   REG  253,0 524288000     0 130345 /home/laborant/links/big.log (deleted)
lr-x------ 1 laborant laborant 64 Sep 16 13:57 /proc/4109/fd/0 -> /home/laborant/links/big.log (deleted)
/dev/root        79G  1.8G   73G   3% /
```

`NLINK 0` with `(deleted)` identifies the file. Truncating it through `/proc/<pid>/fd/<n>` frees the space without restarting the process; restarting the process also works.

---

## Common Errors

### `ln: failed to create hard link '/dev/shm/hard.conf' => 'hard.conf': Invalid cross-device link`

**Cause:** hard links cannot span filesystems (`EXDEV`).

**Fix:** use `ln -s`, or copy the file.

### `ln: /home/laborant/links: hard link not allowed for directory`

**Cause:** directories cannot have extra hard links.

**Fix:** use a symbolic link or a bind mount.

### `No space left on device` with free space in `df -h`

**Cause:** the filesystem has no free inodes.

**Fix:** `df -i` to confirm, then find directories with many files: `sudo du --inodes -x / | sort -n | tail`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is an inode, and what does it not contain?"
    **Say first:** the on-disk metadata record of a file (type, mode, owner, size, timestamps, block pointers); it does not contain the name, which lives in the directory.

    **Proof:** `stat file`; `ls -i` shows the inode number next to the name.

    **Follow-up:** Given that, what does `mv` change on the same filesystem?

??? question "L1: What is the difference between a hard link and a soft link?"
    **Say first:** a hard link is another name for the same inode; a symlink is a separate file that stores a path.

    **Proof:** `ls -li` shows the same inode and a link count of 2 for hard links, and a different inode with `->` for symlinks.

    **Follow-up:** What happens to each when the original name is deleted?

??? question "L1: What is the difference between mtime, ctime and atime?"
    **Say first:** mtime changes with content, ctime with any inode change including permissions, atime with reads.

    **Proof:** `chmod` changes only ctime in `stat` output.

    **Follow-up:** Why can `touch` not set ctime?
<!-- --8<-- [end:l1] -->

??? question "L2: Find all broken symlinks under /etc."
    **Say first:** `find -xtype l` matches links whose target does not exist.

    **Proof:** `sudo find /etc -xtype l`

    **Follow-up:** How do you show where one of them points? (`readlink`.)

??? question "L2: Switch a current symlink from release 1.0 to 2.0 without a gap."
    **Say first:** replace the link atomically.

    **Proof:** `ln -sfn /opt/app/releases/2.0 /opt/app/current`, or create a temporary link and `mv -T` it over the old one.

    **Follow-up:** Why is `mv -T` the strictly atomic version? (`rename()` is atomic; `ln -sf` unlinks first.)

??? question "L2: Find every name for a file that has several hard links."
    **Say first:** search by inode number on the same filesystem.

    **Proof:** `find / -xdev -samefile /path/to/file` or `find / -xdev -inum <n>`

    **Follow-up:** Why is `-xdev` required?

??? question "L3: df shows the disk 100 percent full, but du finds far less data."
    **Say first:** look for deleted files still held open, then for data hidden under a mount point.

    **Proof:** `sudo lsof +L1` lists `(deleted)` files with their size; truncating `/proc/<pid>/fd/<n>` or restarting the process frees the space.

    **Follow-up:** How can data be hidden under a mount point, and how do you check it? (Bind-mount `/` elsewhere and run `du`.)

??? question "L3: Writes fail with No space left on device, but df -h shows 40 percent used."
    **Say first:** check inode usage.

    **Proof:** `df -i` shows `IUse% 100%`; `du --inodes` finds the directory with millions of small files.

    **Follow-up:** How do you avoid it on a new filesystem? (`mkfs.ext4 -N` or `-i`, or XFS with dynamic inode allocation.)

??? question "L4: What happens on disk when you run rm on a file?"
    **Say first:** `rm` calls `unlink()`, which removes the directory entry and decrements the inode's link count; the kernel frees the inode and blocks only when the count is 0 and no process has the file open.

    **Proof:** `strace -e trace=unlinkat rm f`; `lsof +L1` shows files with link count 0 still in use.

    **Don't say:** "rm overwrites the data."

---

## Related

- [File Descriptors](file-descriptors.md): why open files survive deletion
- [File Operations](file-operations.md): `mv`, `rm` and sparse files
- [Finding Files](finding-files.md): searching by inode and timestamps
- [Filesystem Hierarchy](filesystem-hierarchy.md): the `usrmerge` symlinks

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
