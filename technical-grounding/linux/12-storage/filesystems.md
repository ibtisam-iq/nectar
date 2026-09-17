# Filesystems

A filesystem organizes a block device into files, directories and metadata. The choice between ext4, XFS and Btrfs decides how a volume can be resized, checked and repaired later.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Defaults | RHEL: XFS; Ubuntu and Debian: ext4 | `findmnt -no FSTYPE /` |
| Create | `mkfs.ext4`, `mkfs.xfs`, `mkfs.vfat -F 32`, `mkfs.btrfs`; `-L` sets a label | `lsblk -f` |
| Existing signature | `mkfs.xfs` and `mkfs.btrfs` refuse without `-f`; `mke2fs` asks on a terminal | `wipefs <dev>` |
| Resize | ext4: `resize2fs`, grows online, shrinks offline; XFS: `xfs_growfs <mountpoint>` grows only (apart from an experimental trim of the last allocation group) | `df -h` |
| Check and repair | ext4: `e2fsck` (unmounted); XFS: `xfs_repair` (unmounted; `-n` checks only) | exit status |
| Inspect and label | `tune2fs -l`, `dumpe2fs -h`, `xfs_info`; `tune2fs -L`, `xfs_admin -L` (unmounted), `fatlabel` | `blkid` |
| Reserved blocks | ext4 keeps 5% for root; `tune2fs -m 1` lowers it | `tune2fs -l` |
| Inodes | ext4 fixes the count at creation (`mkfs.ext4 -i`, `-N`); XFS allocates them dynamically | `df -i` |
| Backup superblocks | ext4 keeps copies; `mke2fs -n` lists them, `e2fsck -b <block>` uses one | `dumpe2fs <dev>` |
| Btrfs | Copy-on-write, subvolumes, snapshots, checksums; Fedora and SUSE default; removed from RHEL 8 | `btrfs filesystem show` |
<!-- --8<-- [end:facts] -->

---

## Creating Filesystems

The partitions from [Partitioning](partitioning.md) get ext4, XFS and FAT32:

```bash
sudo mkfs.ext4 -L appdata /dev/loop0p3
sudo mkfs.xfs -L logs /dev/loop1p2
sudo mkfs.vfat -F 32 -n EFI /dev/loop1p1
lsblk -f /dev/loop0 /dev/loop1
sudo mkfs.xfs /dev/loop0p1; echo "rc=$?"
```

Output:

```text
mke2fs 1.47.1 (20-May-2024)
# ... (trimmed)
Creating filesystem with 307200 1k blocks and 76912 inodes
Filesystem UUID: 683f9429-6087-4267-a91e-79c8e5787e21
# ... (trimmed)
Creating journal (8192 blocks): done
# ... (trimmed)
meta-data=/dev/loop1p2           isize=512    agcount=4, agsize=65536 blks
# ... (trimmed)
mkfs.fat 4.2 (2021-01-31)
NAME      FSTYPE FSVER LABEL   UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
loop0                                                                              
├─loop0p3 ext4   1.0   appdata 683f9429-6087-4267-a91e-79c8e5787e21                
├─loop0p1 ext4   1.0           bba51a4b-2c75-451f-82d9-e24645d02771                
└─loop0p2                                                                          
loop1                                                                              
├─loop1p1 vfat   FAT32 EFI     7C6C-49E7                                           
├─loop1p2 xfs          logs    875008e0-8369-4a85-b33f-06333db4f59d                
└─loop1p3                                                                          
mkfs.xfs: /dev/loop0p1 appears to contain an existing filesystem (ext4).
mkfs.xfs: Use the -f option to force overwrite.
rc=1
```

`mke2fs` chose 1 KiB blocks because the partition is small; volumes above 512 MiB get 4 KiB blocks. XFS divided the volume into four allocation groups (`agcount=4`), which it can update in parallel. `mkfs.xfs` refused to overwrite the existing ext4 signature on `loop0p1`.

---

## Inspecting and Tuning

```bash
sudo tune2fs -l /dev/loop0p3 | grep -E '^(Filesystem volume name|Filesystem state|Inode count|Block count|Reserved block count|Block size|Filesystem features)'
sudo tune2fs -m 1 -L appdata2 /dev/loop0p3
sudo xfs_admin -L weblogs /dev/loop1p2
sudo blkid /dev/loop0p3 /dev/loop1p2
```

Output:

```text
Filesystem volume name:   appdata
Filesystem features:      has_journal ext_attr resize_inode dir_index filetype extent 64bit flex_bg sparse_super large_file huge_file dir_nlink extra_isize metadata_csum
Filesystem state:         clean
Inode count:              76912
Block count:              307200
Reserved block count:     15360
Block size:               1024
tune2fs 1.47.1 (20-May-2024)
Setting reserved blocks percentage to 1% (3072 blocks)
writing all SBs
new label = "weblogs"
/dev/loop0p3: LABEL="appdata2" UUID="683f9429-6087-4267-a91e-79c8e5787e21" BLOCK_SIZE="1024" TYPE="ext4" PARTUUID="285f8258-03"
/dev/loop1p2: LABEL="weblogs" UUID="875008e0-8369-4a85-b33f-06333db4f59d" BLOCK_SIZE="512" TYPE="xfs" PARTLABEL="data" PARTUUID="b7beaffc-d0cc-4a24-b644-b424ca268294"
```

`PARTUUID` and `PARTLABEL` belong to the partition table entry, `UUID` and `LABEL` to the filesystem. The 5% reserve (15360 blocks) lets root processes and the allocator work when users have filled the volume; on a large data volume, 1% is usually enough.

---

## Checking and Repairing

Repair tools need the filesystem unmounted. With it mounted, `e2fsck -n` only reads and `xfs_repair` refuses:

```bash
sudo mkdir -p /srv/app /srv/logs
sudo mount /dev/loop0p3 /srv/app
sudo mount /dev/loop1p2 /srv/logs
df -i /srv/app /srv/logs
sudo e2fsck -n /dev/loop0p3; echo "rc=$?"
sudo xfs_repair -n /dev/loop1p2; echo "rc=$?"
```

Output:

```text
Filesystem     Inodes IUsed  IFree IUse% Mounted on
/dev/loop0p3    76912    11  76901    1% /srv/app
/dev/loop1p2   524288     3 524285    1% /srv/logs
e2fsck 1.47.1 (20-May-2024)
Warning!  /dev/loop0p3 is mounted.
Warning: skipping journal recovery because doing a read-only filesystem check.
appdata2: clean, 11/76912 files, 29591/307200 blocks
rc=0
xfs_repair: /dev/loop1p2 contains a mounted and writable filesystem

fatal error -- couldn't initialize XFS library
rc=1
```

`df -i` shows the fixed ext4 inode count next to the XFS count, which grows with use. After unmounting the ext4 volume:

```bash
sudo umount /srv/app
sudo e2fsck -f /dev/loop0p3; echo "rc=$?"
sudo e2fsck -f -y /dev/loop0p3; echo "rc=$?"
```

Output:

```text
e2fsck 1.47.1 (20-May-2024)
e2fsck: need terminal for interactive repairs
rc=8
e2fsck 1.47.1 (20-May-2024)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
appdata2: 11/76912 files (0.0% non-contiguous), 29591/307200 blocks
rc=0
```

`e2fsck` exit codes are a bit mask: `0` clean, `1` errors corrected, `4` errors left, `8` operational error. `xfs_repair` without `-n` repairs; `-L` zeroes a damaged log and loses its last transactions, so it is the last resort after a mount has failed to replay the log.

!!! warning "Never repair a mounted filesystem"
    Writing to structures the kernel is also changing corrupts the volume. Unmount it, or check the root filesystem from rescue mode or at boot (`fsck.mode=force` on the kernel command line).

---

## Shrinking

The ext4 volume is unmounted and freshly checked, which `resize2fs` requires before shrinking; XFS stays mounted at `/srv/logs`:

```bash
sudo resize2fs /dev/loop0p3 200M; echo "rc=$?"
sudo xfs_growfs -D 200000 /srv/logs 2>&1 | tail -1
sudo xfs_growfs -D 150000 /srv/logs >/dev/null; echo "rc=$?"
```

Output:

```text
resize2fs 1.47.1 (20-May-2024)
Resizing the filesystem on /dev/loop0p3 to 204800 (1k) blocks.
The filesystem on /dev/loop0p3 is now 204800 (1k) blocks long.

rc=0
data blocks changed from 262144 to 200000
[EXPERIMENTAL] try to shrink unused space 150000, old size is 200000
xfs_growfs: XFS_IOC_FSGROWFSDATA xfsctl failed: Invalid argument
rc=1
```

XFS shrank only while the new end stayed inside the last allocation group (4 groups of 65536 blocks, so the last one starts at block 196608); the kernel refuses to remove a whole group.

!!! danger "Shrink the filesystem before the partition or volume under it"
    Reducing the device first cuts off the end of the filesystem. For XFS, the supported way to get a smaller volume is to back up, recreate and restore.

---

## Recovering from a Damaged Superblock

The first command zeroes the ext4 primary superblock on purpose:

```bash
sudo dd if=/dev/zero of=/dev/loop0p3 bs=1024 seek=1 count=1 status=none
sudo mount /dev/loop0p3 /srv/app; echo "rc=$?"
sudo dumpe2fs /dev/loop0p3 2>&1 | head -3
sudo mke2fs -n /dev/loop0p3 | tail -3
sudo e2fsck -y -b 8193 /dev/loop0p3 | tail -4; echo "rc=${PIPESTATUS[0]}"
sudo mount /dev/loop0p3 /srv/app && df -h /srv/app
```

Output:

```text
mount: /srv/app: wrong fs type, bad option, bad superblock on /dev/loop0p3, missing codepage or helper program, or other error.
       dmesg(1) may have more information after failed mount system call.
rc=32
dumpe2fs 1.47.1 (20-May-2024)
dumpe2fs: Bad magic number in super-block while trying to open /dev/loop0p3
Couldn't find valid filesystem superblock.
mke2fs 1.47.1 (20-May-2024)
Superblock backups stored on blocks: 
	8193, 24577, 40961, 57345, 73729, 204801, 221185

e2fsck 1.47.1 (20-May-2024)
FIXED.

appdata2: ***** FILE SYSTEM WAS MODIFIED *****
appdata2: 11/50600 files (0.0% non-contiguous), 22461/204800 blocks
rc=1
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0p3    179M   14K  173M   1% /srv/app
```

`mke2fs -n` prints what it would do without writing, so its backup locations are right only with the same options as the original `mkfs`. Exit status `1` means errors were corrected, and the kernel log shows that `mount` also probed the device as XFS (`XFS (loop0p3): Invalid superblock magic number`).

---

## Common Errors

### `e2fsck: need terminal for interactive repairs`

**Cause:** `e2fsck -f` wants to ask before each fix, and no terminal is attached (a script, cloud-init or Ansible).

**Fix:** `-p` repairs safe problems automatically, `-y` answers yes to everything, `-n` only checks.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between ext4 and XFS?"
    **Say first:** both are journaling filesystems; ext4 can shrink and fixes its inode count at creation, while XFS scales better for large files and parallel I/O, allocates inodes dynamically and cannot shrink.

    **Proof:** `df -i` on both; `xfs_info` shows allocation groups.

    **Follow-up:** Which one does RHEL install by default, and what does that mean for reducing a logical volume?

??? question "L1: What does the journal protect?"
    **Say first:** it records metadata changes before they are applied, so after a crash the kernel replays the journal instead of scanning the whole filesystem.

    **Proof:** `tune2fs -l` lists `has_journal`; `xfs_info` shows the internal log.

    **Follow-up:** Why does ext4's default `data=ordered` mode not journal file contents?
<!-- --8<-- [end:l1] -->

??? question "L2: Format a new partition with XFS, label it and find its UUID."
    **Say first:** `mkfs.xfs -L`, then read the UUID with `blkid` or `lsblk -f`.

    **Proof:** `sudo mkfs.xfs -L logs /dev/sdb2; sudo blkid /dev/sdb2`.

    **Follow-up:** How do you change the label later? (`xfs_admin -L`, unmounted.)

??? question "L2: Check an ext4 filesystem non-interactively from a script."
    **Say first:** unmount it and run `e2fsck -f -p`, or `-y` when every fix should be accepted.

    **Proof:** `sudo e2fsck -f -p /dev/sdb1; echo $?`.

    **Follow-up:** What does exit status 4 mean? (Errors were left uncorrected.)

??? question "L3: An ext4 volume will not mount: wrong fs type, bad superblock. What do you do?"
    **Say first:** confirm the type with `blkid`, read the kernel message, then check the filesystem against a backup superblock.

    **Proof:** `sudo dmesg | tail`; `sudo mke2fs -n <dev>`; `sudo e2fsck -b 32768 <dev>`.

    **Follow-up:** Why must `mke2fs -n` get the same options as the original `mkfs`?

??? question "L3: df shows free space, but creating files fails with No space left on device. Why?"
    **Say first:** the ext4 volume has run out of inodes.

    **Proof:** `df -i` shows `IUse% 100%`; `find <mount> -xdev -type f | cut -d/ -f2-3 | sort | uniq -c | sort -n` finds the directory with the most files.

    **Follow-up:** How do you prevent it on a volume for small files? (`mkfs.ext4 -i` with a smaller bytes-per-inode ratio, or XFS.)

---

## Related

- [Partitioning](partitioning.md): the partitions formatted here
- [Mounting and fstab](mounting-and-fstab.md): mounting by UUID or label
- [Resizing and Cloud Disks](resizing-and-cloud-disks.md): growing filesystems online
- [Disk Usage](disk-usage.md): blocks and inodes running out

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167, xfsprogs 6.16.0, e2fsprogs 1.47.1), 2026-09.
