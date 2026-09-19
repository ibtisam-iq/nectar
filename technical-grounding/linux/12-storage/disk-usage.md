# Disk Usage

`df` reports what each filesystem has allocated, and `du` adds up the files it can reach. When the two disagree, the difference points to deleted files that are still open, files hidden under a mount point, or the inode table rather than the blocks.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Filesystem usage | `df -h`, `df -hT` (type), `df -x tmpfs` (exclude a type) | `df -h /` |
| Inode usage | `df -i` | `df -i /` |
| Directory totals | `du -sh <dir>`, `du -xh --max-depth=1 /` (`-x` stays on one filesystem) | `du -sh /var/log` |
| Sort sizes | `sort -h` orders human-readable sizes such as `1.2G` and `51M` | `sort --help` |
| Large files | `find / -xdev -type f -size +100M` | `ls -lh` |
| Interactive | `ncdu -x /` (EPEL on RHEL, `apt install ncdu`) | `ncdu --version` |
| Apparent vs allocated | `ls -l` and `du --apparent-size` show the length; `du` shows the blocks used | `du -h <sparse file>` |
| Deleted but open | Space is freed when the last process closes the file | `lsof -a +L1 <mountpoint>` |
| Free it without a restart | `: > /proc/<pid>/fd/<fd>` truncates the open file | `df -h` |
| Reserved blocks | ext4 keeps 5% for root, so users hit `No space left` at `Avail 0` before `Size` is used | `tune2fs -l <dev>` |
| Inode exhaustion | `No space left on device` with free blocks; ext4 inode count is fixed | `df -i` |
| Hidden files | Files written to a directory before a filesystem was mounted over it count in `df`, not in `du` | `mount --bind / /mnt/rootfs` |
| Usual growth | `/var/log`, the journal, package caches, container images, `/tmp`, core dumps, backups | `du -xh --max-depth=2 /var` |
| Journal size | `journalctl --disk-usage`, `--vacuum-size=`, `SystemMaxUse=` | `journalctl --disk-usage` |
<!-- --8<-- [end:facts] -->

---

## Filesystems and Directories

```bash
df -hT -x tmpfs -x devtmpfs
df -i /
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail -5
sudo du -sh /var/* 2>/dev/null | sort -h | tail -4
```

Output:

```text
Filesystem               Type  Size  Used Avail Use% Mounted on
/dev/root                ext4   79G  4.0G   71G   6% /
/dev/loop1p2             xfs   718M   47M  672M   7% /srv/logs
/dev/loop0p3             ext4  179M   16K  173M   1% /srv/app
/dev/mapper/vgdata-lvweb xfs   1.5G   61M  1.4G   5% /srv/web
/dev/mapper/vgdata-lvdb  ext4  2.3G   28K  2.2G   1% /srv/db
/dev/loop4p1             xfs   3.0G   91M  2.9G   4% /srv/cloud
/dev/mapper/vgroot-root  ext4  2.0G   24K  1.9G   1% /srv/root
Filesystem      Inodes IUsed   IFree IUse% Mounted on
/dev/root      5099520 42717 5056803    1% /
74M	/boot
126M	/tmp
1.2G	/var
2.1G	/usr
4.0G	/
12M	/var/lib
51M	/var/log
79M	/var/cache
1.1G	/var/tmp
```

`-x` keeps `du` on the root filesystem, so the volumes under `/srv` are not counted twice. The drill-down repeats one level at a time (`/var`, then `/var/tmp`) until the directory that grew is found.

---

## Large and Sparse Files

```bash
sudo find / -xdev -type f -size +100M -exec ls -lh {} + 2>/dev/null
ls -lh /var/tmp/disks/disk3.img; du -h /var/tmp/disks/disk3.img; du -h --apparent-size /var/tmp/disks/disk3.img
```

Output:

```text
-rw------- 1 root     root     512M Sep 17 07:39 /swapfile
-rw-r--r-- 1 laborant laborant 120M Sep 16 14:00 /tmp/fdemo/logs/app.log
# ... (trimmed)
-rw-r--r-- 1 laborant laborant 3.0G Sep 17 07:46 /var/tmp/disks/cloud1.img
-rw-r--r-- 1 laborant laborant 2.0G Sep 17 07:47 /var/tmp/disks/cloud2.img
-rw-r--r-- 1 laborant laborant 2.0G Sep 17 07:39 /var/tmp/disks/disk1.img
-rw-r--r-- 1 laborant laborant 2.0G Sep 17 07:43 /var/tmp/disks/disk2.img
-rw-r--r-- 1 laborant laborant 2.0G Sep 17 07:43 /var/tmp/disks/disk3.img
-rw-r--r-- 1 laborant laborant 2.0G Sep 17 07:43 /var/tmp/disks/disk4.img
# ... (trimmed)
-rw-r--r-- 1 laborant laborant 2.0G Sep 17 07:43 /var/tmp/disks/disk3.img
389M	/var/tmp/disks/disk3.img
2.0G	/var/tmp/disks/disk3.img
```

The loop-disk images look like 13 GiB in `ls`, while `du` counted 1.1 GiB for all of `/var/tmp`: they are sparse, and only written blocks use space. VM images, database files and core dumps are often sparse, so `du` is the number to trust for "what fills the disk".

---

## Where the Space Goes by Distribution

=== "RHEL / Rocky"

    ```bash
    journalctl --disk-usage
    sudo dnf clean all -q; echo rc=$?
    ```

    Output:

    ```text
    Archived and active journals take up 48M in the file system.
    rc=0
    ```

    `dnf` keeps metadata and, with `keepcache=1`, packages in `/var/cache/dnf`.

=== "Ubuntu / Debian"

    ```bash
    sudo journalctl --disk-usage
    sudo du -sh /var/lib/snapd /var/cache/apt /var/log
    sudo journalctl --vacuum-size=40M 2>&1 | tail -1; sudo journalctl --disk-usage
    ```

    Output:

    ```text
    Archived and active journals take up 69.8M in the file system.
    157M	/var/lib/snapd
    20K	/var/cache/apt
    72M	/var/log
    Vacuuming done, freed 0B of archived journals from /run/log/journal.
    Archived and active journals take up 39.7M in the file system.
    ```

    The journal shrank because a `--vacuum-size=50M` run a moment earlier deleted 22.4 MiB of archived files. `sudo apt-get clean` empties `/var/cache/apt/archives`; old snap revisions stay in `/var/lib/snapd` until removed (`snap set system refresh.retain=2` limits them).

---

## Running Out of Inodes

`loop0p1` was formatted with only 1000 inodes (`mkfs.ext4 -N 1000`) and mounted at `/srv/tiny`. A session directory fills it:

```bash
df -h /srv/tiny; df -i /srv/tiny
cd /srv/tiny/sessions && for i in $(seq 1 1100); do echo x > sess_$i || break; done
ls | wc -l
df -h /srv/tiny; df -i /srv/tiny
sudo find /srv/tiny -xdev -type f | cut -d/ -f1-4 | sort | uniq -c | sort -n | tail -3
```

Output:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p1    490M   15K  461M   1% /srv/tiny
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/loop0p1     1008    12   996    2% /srv/tiny
bash: line 8: sess_997: No space left on device
996
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p1    490M  1.1M  460M   1% /srv/tiny
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/loop0p1     1008  1008     0  100% /srv/tiny
    996 /srv/tiny/sessions
```

The error text is the same as for full blocks, so `df -i` belongs in the first check. Deleting with `find ... -delete` avoids the `Argument list too long` error that `rm sess_*` hits in large directories.

---

## Reserved Blocks

With the session files removed, an unprivileged user fills the volume:

```bash
dd if=/dev/zero of=/srv/tiny/sessions/big bs=1M count=600 status=none; echo "rc=$?"
df -h /srv/tiny
sudo sh -c 'echo root still writes > /srv/tiny/root-note'; echo "rc=$?"
sudo tune2fs -l /dev/loop0p1 | grep -E 'Reserved block count|Block count'
rm /srv/tiny/sessions/big
```

Output:

```text
dd: error writing '/srv/tiny/sessions/big': No space left on device
rc=1
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p1    490M  461M  2.0K 100% /srv/tiny
rc=0
Block count:              512000
Reserved block count:     25600
```

`df` reports 100% because `Use%` is calculated against the space users may take; the 25 MiB reserve (5%) is why `Used` plus `Avail` is smaller than `Size`. Root processes such as `journald` and `sshd` keep working in that reserve, which gives an administrator room to log in and clean up.

---

## Deleted but Still Open

A process keeps writing to a 300 MiB log, and the log is deleted instead of rotated:

```bash
cd /srv/tiny/sessions
python3 -c 'import time; f = open("app.log", "w"); f.write("x" * 300 * 1024 * 1024); f.flush(); time.sleep(600)' &
sleep 3
rm app.log
df -h /srv/tiny; sudo du -sh /srv/tiny
sudo lsof -a +L1 /srv/tiny
ls -l /proc/$!/fd | grep deleted
: > /proc/$!/fd/3
df -h /srv/tiny | tail -1
kill $!
```

Output:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p1    490M  301M  161M  66% /srv/tiny
41K	/srv/tiny
COMMAND  PID     USER   FD   TYPE DEVICE  SIZE/OFF NLINK NODE NAME
python3 7382 laborant    3w   REG  259,8 314572800     0  514 /srv/tiny/sessions/app.log (deleted)
l-wx------ 1 laborant laborant 64 Sep 17 07:49 3 -> /srv/tiny/sessions/app.log (deleted)
/dev/loop0p1    490M   42K  461M   1% /srv/tiny
```

`df` counted 301 MiB and `du` 41 KiB: the inode has no name left (`NLINK 0`) but still has an open descriptor. Truncating it through `/proc` freed the space at once; restarting the process or sending the signal that makes it reopen its log works too. `-a` makes `lsof` require both conditions; without it, `+L1` and the path are alternatives and the list fills with unrelated processes.

!!! warning "Deleting a log that a process holds open frees nothing"
    Empty an active log with `: > file` or `truncate -s 0 file`, or rotate it with `logrotate` (`copytruncate` or a reload), instead of `rm`.

---

## Files Hidden Under a Mount Point

A backup was written to `/srv/tiny` while the volume was not mounted, so it landed on the root filesystem:

```bash
sudo umount /srv/tiny
sudo dd if=/dev/zero of=/srv/tiny/old-backup.tar bs=1M count=200 status=none
sudo mount /dev/loop0p1 /srv/tiny
ls /srv/tiny; sudo du -sh /srv/tiny
sudo mkdir -p /mnt/rootfs && sudo mount --bind / /mnt/rootfs
sudo du -sh /mnt/rootfs/srv/tiny; ls -lh /mnt/rootfs/srv/tiny
sudo rm /mnt/rootfs/srv/tiny/old-backup.tar
sudo umount /mnt/rootfs
```

Output:

```text
lost+found
root-note
sessions
41K	/srv/tiny
201M	/mnt/rootfs/srv/tiny
total 200M
-rw-r--r-- 1 root root 200M Sep 17 07:49 old-backup.tar
```

A bind mount of `/` shows the root filesystem without the mounts on top of it, so the hidden file becomes visible and removable without unmounting the data volume.

!!! tip "When df and du disagree, check two things"
    `lsof -a +L1 <mountpoint>` for deleted open files, then a bind mount of the parent filesystem for files under mount points.

---

## Common Errors

### `No space left on device`

**Cause:** the filesystem has no free blocks for this user (including the reserve), or no free inodes.

**Fix:** `df -h` and `df -i` on the path; then `du -xh --max-depth=1`, `lsof -a +L1` and the checks above. See [Disk Full](../interview/scenarios/disk-full.md).

### `/usr/bin/rm: Argument list too long`

**Cause:** a glob such as `sess_*` expanded to more arguments than the kernel accepts for one command; the shell reports it with exit status 126.

**Fix:** `find <dir> -name 'sess_*' -delete`, or `find ... -print0 | xargs -0 rm`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between df and du?"
    **Say first:** `df` asks the filesystem how many blocks are allocated; `du` walks the directory tree and adds up the files it can reach.

    **Proof:** `df -h /var`; `sudo du -sh /var`.

    **Follow-up:** Name two reasons they can disagree.

??? question "L1: What does df -i show, and why does it matter?"
    **Say first:** inode usage; a filesystem with no free inodes cannot create files even with free space.

    **Proof:** `df -i`; many small files in one tree.

    **Follow-up:** Which filesystem fixes the inode count at creation?
<!-- --8<-- [end:l1] -->

??? question "L2: Find the ten largest directories under /var on the root filesystem."
    **Say first:** use `du` limited to one filesystem and one level, sorted by human-readable size.

    **Proof:** `sudo du -xh --max-depth=1 /var | sort -h | tail -10`.

    **Follow-up:** How do you find single files over 1 GiB? (`sudo find / -xdev -type f -size +1G`.)

??? question "L2: A deleted log still fills the disk. Free the space without restarting the service."
    **Say first:** find the process holding it and truncate the file through its descriptor.

    **Proof:** `sudo lsof -a +L1 /var`; `: | sudo tee /proc/<pid>/fd/<fd>`.

    **Follow-up:** How should the log have been cleared?

??? question "L2: Clean up journal space and keep it limited."
    **Say first:** vacuum the journal now and set a size cap in `journald.conf`.

    **Proof:** `sudo journalctl --vacuum-size=500M`; `SystemMaxUse=500M` in a drop-in under `/etc/systemd/journald.conf.d/`, then `sudo systemctl restart systemd-journald`.

    **Follow-up:** Where does the journal live when it is not persistent?

??? question "L3: df shows / at 100%, but du -sh / adds up to much less. What do you check?"
    **Say first:** deleted files still held open, then files hidden under mount points, then the reserved blocks.

    **Proof:** `sudo lsof -a +L1 /`; `sudo mount --bind / /mnt/rootfs; sudo du -xsh /mnt/rootfs/*`; `sudo tune2fs -l <dev> | grep Reserved`.

    **Follow-up:** Why does `du` without `-x` give a misleading total on `/`?

??? question "L3: Users cannot create files, but df -h shows 40% used. Why?"
    **Say first:** the filesystem is out of inodes, or a quota is reached, or it was remounted read-only.

    **Proof:** `df -i`; `quota -s <user>`; `findmnt -no OPTIONS <mount>`; the exact error text.

    **Follow-up:** How do you find which directory holds millions of files?

---

## Related

- [Disk Full](../interview/scenarios/disk-full.md): the full troubleshooting path
- [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md): why an unlinked file can stay allocated
- [logrotate](../09-logging/logrotate.md): rotating logs without deleting open files
- [journalctl](../09-logging/journalctl.md): journal size limits
- [Quotas](quotas.md): per-user limits

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
