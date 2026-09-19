# Backup and Restore

A backup is a copy that can be restored after the original is lost, kept on other storage and tested by restoring it. `rsync`, `tar`, LVM snapshots and block images cover most Linux server backups.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Full | Copies everything; slowest to take, one step to restore | backup size |
| Incremental | Copies changes since the last backup of any kind; restore needs the full plus every incremental in order | `tar --listed-incremental` |
| Differential | Copies changes since the last full; restore needs the full plus the latest differential | backup size |
| 3-2-1 rule | 3 copies, on 2 kinds of media, 1 off site | backup inventory |
| RPO and RTO | How much data may be lost; how long a restore may take | runbook |
| `rsync -a` | Recursive, keeps links, modes, times, owner and group; add `-H` (hard links), `-A` (ACLs), `-X` (xattrs, SELinux labels) | `rsync -aHAX` |
| Trailing slash | `src/` copies the contents; `src` copies the directory itself | `ls dest` |
| Dry run | `rsync -n -i` shows what would change; `--delete` removes files gone from the source | `rsync -ani --delete` |
| Snapshot-style copies | `rsync --link-dest=<previous>` hard-links unchanged files | `ls -li` |
| Consistent copy | LVM, cloud or filesystem snapshot, or the application's own dump (`pg_dump`, `mysqldump`) | `lvs` |
| Block image | `dd if=<dev> of=<file> bs=4M`; `ddrescue` for failing disks | `sha256sum` |
| Verify | `tar -d` (compare), `rsync -anc` (checksums), a real test restore | exit status |
<!-- --8<-- [end:facts] -->

---

## rsync Basics

```bash
rsync -a /srv/app/site /backup/a
rsync -a /srv/app/site/ /backup/b
ls /backup/a /backup/b
rm /srv/app/site/style.css; echo 'v2' >> /srv/app/site/index.html
rsync -aHAX --delete -n -i /srv/app/site/ /backup/b/
rsync -aHAX --delete -i /srv/app/site/ /backup/b/
ls /backup/b
```

Output:

```text
/backup/a:
site

/backup/b:
img
index.html
style.css
*deleting   style.css
>f.s....... index.html
*deleting   style.css
>f.s....... index.html
img
index.html
```

The dry run (`-n`) printed the same changes as the real run and touched nothing. In the `-i` codes, `>f` is a file sent to the receiver and `s` a size change.

!!! warning "rsync --delete with a wrong path empties the destination"
    Swapping source and destination, or missing a trailing slash, makes `--delete` remove the wrong files. Run the command with `-n -i` first and read the list.

Only the last directory of the destination is created:

```bash
rsync -a /srv/app/site/ /backup/daily/2026-09-16/
```

Output:

```text
rsync: [Receiver] mkdir "/backup/daily/2026-09-16" failed: No such file or directory (2)
rsync error: error in file IO (code 11) at main.c(808) [Receiver=3.5.0-g5c0688d4]
```

`mkdir -p /backup/daily` first, or `rsync --mkpath` (rsync 3.2.3 and later).

---

## tar Incrementals

```bash
cd /backup
tar --listed-incremental=site.snar -czf site-full.tgz -C /srv/app site
echo 'new page' > /srv/app/site/about.html; rm /srv/app/site/img/banner.png
tar --listed-incremental=site.snar -czf site-inc1.tgz -C /srv/app site
tar -tzvf site-inc1.tgz
mkdir -p /tmp/restore && cd /tmp/restore
tar --listed-incremental=/dev/null -xzf /backup/site-full.tgz
tar --listed-incremental=/dev/null -xzf /backup/site-inc1.tgz
find site -type f | sort
diff -r /srv/app/site /tmp/restore/site && echo identical
```

Output:

```text
drwxr-xr-x laborant/laborant 30 2026-09-17 07:53 site/
drwxr-xr-x laborant/laborant  1 2026-09-17 07:53 site/img/
-rw-r--r-- laborant/laborant  9 2026-09-17 07:53 site/about.html
site/about.html
site/index.html
identical
```

The incremental held only `about.html`, plus directory listings that record what existed. Extracting it with `--listed-incremental` deleted `banner.png` from the restored tree, so the result matched the source. A differential backup reuses a copy of the full backup's `.snar` file each time instead of the updated one.

---

## Daily Snapshots with Hard Links

`banner.png`, removed in the `tar` test, was copied back from `/backup/b` first:

```bash
mkdir -p /backup/daily
rsync -a /srv/app/site/ /backup/daily/2026-09-16/
echo 'v4' >> /srv/app/site/index.html
rsync -a --link-dest=/backup/daily/2026-09-16 /srv/app/site/ /backup/daily/2026-09-17/
ls -li /backup/daily/*/img/banner.png /backup/daily/*/index.html
du -sh /backup/daily/*
du -sh /backup/daily
```

Output:

```text
637460 -rw-r--r-- 2 laborant laborant 2097152 Sep 17 07:53 /backup/daily/2026-09-16/img/banner.png
637459 -rw-r--r-- 1 laborant laborant      20 Sep 17 07:53 /backup/daily/2026-09-16/index.html
637460 -rw-r--r-- 2 laborant laborant 2097152 Sep 17 07:53 /backup/daily/2026-09-17/img/banner.png
637463 -rw-r--r-- 1 laborant laborant      23 Sep 17 07:53 /backup/daily/2026-09-17/index.html
2.1M	/backup/daily/2026-09-16
12K	/backup/daily/2026-09-17
2.1M	/backup/daily
```

The unchanged image has one inode (`637460`) with two links, so the second day cost 12 KiB. Each directory is still a complete tree that restores with a plain copy, and deleting an old day frees only the files no other day links to. Tools such as `rsnapshot` automate this rotation; `restic` and `borg` add deduplication and encryption.

---

## Consistent Backups with LVM Snapshots

```bash
sudo lvcreate -s -n db_backup -L 100M vgdata/lvdb
sudo mount -o ro /dev/vgdata/db_backup /mnt/snap
sudo tar -czf /backup/db-$(date +%F).tgz -C /mnt/snap .
sudo umount /mnt/snap && sudo lvremove -y vgdata/db_backup
sudo tar -tzvf /backup/db-$(date +%F).tgz | head -5
```

Output:

```text
  Logical volume "db_backup" created.
  Logical volume "db_backup" successfully removed.
drwxr-xr-x root/root         0 2026-09-17 07:51 ./
-rw-r--r-- root/root        10 2026-09-17 07:42 ./orders.txt
drwxr-xr-x laborant/laborant 0 2026-09-17 07:53 ./home/
-rw-r--r-- laborant/laborant 23068672 2026-09-17 07:51 ./home/b.bin
-rw-r--r-- laborant/laborant        0 2026-09-17 07:53 ./home/ok
```

The snapshot froze the volume at one instant while the service kept writing, and it lived only for the length of the copy. A database still needs a flush or its own dump tool, because a filesystem-consistent copy can hold a half-written transaction.

!!! danger "Do not run fsfreeze before lvcreate -s"
    LVM freezes a mounted filesystem itself while it creates the snapshot. With the filesystem already frozen by `fsfreeze -f`, the first attempt here failed with `Unable to suspend vgdata-lvdb` and `Aborting. Manual intervention required.`, and left device-mapper entries that had to be removed with `lvremove` and `dmsetup remove`.

---

## Block Images and Verification

```bash
sudo umount /srv/app
sudo dd if=/dev/loop0p3 of=/backup/app.img bs=4M status=none
sudo sha256sum /dev/loop0p3 /backup/app.img
ls -lsh /backup/app.img
sudo mount /srv/app
tar -dzf /backup/site-full.tgz -C /srv/app; echo "rc=$?"
rsync -anci --delete /backup/daily/2026-09-17/ /srv/app/site/; echo "rc=$?"
```

Output:

```text
95714686463441b0fa7461684a2e165cb1663716fd81a3dec0d19e3f77b9539d  /dev/loop0p3
95714686463441b0fa7461684a2e165cb1663716fd81a3dec0d19e3f77b9539d  /backup/app.img
300M -rw-r--r-- 1 root root 300M Sep 17 07:53 /backup/app.img
site: Contents differ
site/index.html: Mod time differs
site/index.html: Size differs
site/img/banner.png: Mod time differs
rc=1
rc=0
```

The image was taken unmounted, so its checksum matches the device; `dd` copies every block, used or not, and writes a full-size file. `tar -d` reported what changed since the full backup, and `rsync -anc` found nothing to change against the latest daily copy. On a failing disk, `ddrescue` (EPEL, Ubuntu `gddrescue`) retries bad areas and keeps a map instead of stopping at the first error.

---

## Common Errors

### `rsync: [Receiver] mkdir "/backup/daily/2026-09-16" failed: No such file or directory (2)`

**Cause:** a parent of the destination directory does not exist.

**Fix:** `mkdir -p` the parent, or add `--mkpath`.

### ``tar: Removing leading `/' from member names``

**Cause:** the archive was created with absolute paths; `tar` stores them relative, which is the safe default.

**Fix:** none needed; use `-C /` to create and extract relative to the root. See [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md).

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between full, incremental and differential backups?"
    **Say first:** a full copies everything, an incremental copies changes since the last backup of any kind, and a differential copies changes since the last full.

    **Proof:** `tar --listed-incremental`; restore order full, then each incremental.

    **Follow-up:** Which one restores fastest, and which uses least space?

??? question "L1: Why is a RAID array or a snapshot not a backup?"
    **Say first:** both live on the same system; RAID copies deletions and corruption instantly, and an LVM snapshot is lost with its volume group.

    **Proof:** `lvs` shows the snapshot in the same VG as its origin.

    **Follow-up:** What is the 3-2-1 rule?
<!-- --8<-- [end:l1] -->

??? question "L2: Mirror /var/www to a backup host over SSH, deleting files removed at the source."
    **Say first:** `rsync` with archive mode, `--delete`, and a dry run first.

    **Proof:** `rsync -aHAX --delete -n -i /var/www/ backup@host:/srv/www/`, then without `-n`.

    **Follow-up:** What happens if the trailing slash is left off the source?

??? question "L2: Keep 7 daily copies of a directory without storing unchanged files 7 times."
    **Say first:** `rsync --link-dest` against the previous day, then delete the oldest directory.

    **Proof:** `rsync -a --link-dest=/backup/$(date -d yesterday +%F) /data/ /backup/$(date +%F)/`; `ls -li` shows shared inodes.

    **Follow-up:** Why does deleting an old day not break the others?

??? question "L2: Prove a backup can be restored."
    **Say first:** restore it to a separate location and compare it with the source or with recorded checksums.

    **Proof:** `tar -xzf backup.tgz -C /tmp/restore; diff -r /data /tmp/restore/data`; `rsync -anc`.

    **Follow-up:** How often should restores be tested, and who should run them?

??? question "L3: Nightly backups ran for months, but the restore fails. What went wrong, and how do you prevent it?"
    **Say first:** check what the job really captured: exit codes ignored, a full disk, a changed path, open database files or missing permissions and ACLs.

    **Proof:** the job's log and exit status; `tar -tzvf` or `restic snapshots`; a test restore.

    **Follow-up:** Which monitoring would have caught it? (Alert on job failure and on backup age.)

---

## Related

- [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md): `tar` options
- [LVM](lvm.md): snapshots
- [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md): how hard links share data
- [Filesystems](filesystems.md): repairing instead of restoring

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167, rsync 3.5.0, tar 1.35), 2026-09.
