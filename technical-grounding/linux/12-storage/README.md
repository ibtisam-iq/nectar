# Storage

How Linux finds disks, divides them into partitions and logical volumes, puts filesystems on them and mounts them, and how to grow, protect, back up and troubleshoot that stack when a volume fills up.

---

## Revision Card

| Fact | Value |
|---|---|
| Stack | Disk → partition → (RAID, LUKS) → PV → VG → LV → filesystem → mount point |
| Disk names | `sda` (SCSI/SATA), `vda` (Virtio), `nvme0n1` (NVMe, partitions `p1`), `xvda` (Xen) |
| Stable names | Filesystem `UUID=` in fstab; `/dev/disk/by-id` for disks |
| MBR vs GPT | MBR: 4 primary, 2 TiB; GPT: 128 partitions, backup table, needed for UEFI |
| New partition not visible | `partprobe <disk>` or `partx -a <disk>` |
| ext4 vs XFS | ext4 shrinks offline; XFS grows only (mounted); RHEL default XFS, Ubuntu ext4 |
| fsck | Unmounted only; `e2fsck -f`, `xfs_repair -n`; pass `0` for XFS in fstab |
| fstab fields | device, mount point, type, options, dump, pass; test with `findmnt --verify` and `mount -a` |
| `nofail` | Missing device does not block boot; default device wait is 90 s |
| Busy unmount | `fuser -vm <dir>`, `lsof +f -- <dir>` |
| Swap file | No holes (`dd` or `fallocate`), mode `0600`, `mkswap`, `swapon`; `swapon -a` for fstab |
| LVM grow | `vgextend`, then `lvextend -r` (grows the filesystem too) |
| LVM shrink | `lvreduce -r`, ext4 only |
| Snapshot | Invalid when full (`Data%` 100); `lvconvert --merge` rolls back |
| RHEL 9+ LVM | Devices file: foreign PVs need `lvmdevices --adddev` or `vgimportdevices` |
| Cloud resize | Rescan if needed, `growpart <disk> <n>`, `pvresize`, then grow the LV or filesystem |
| `df` vs `du` | Differ for deleted open files (`lsof -a +L1`) and files under mount points |
| Full with free space | Inodes (`df -i`), quota, or read-only remount |
| Quotas | XFS: `uquota` at mount time, `xfs_quota`; ext4: `tune2fs -O quota`, `setquota`, `repquota` |
| Backups | Full, incremental, differential; `rsync -aHAX --delete -n` first; test restores |
| RAID status | `/proc/mdstat`: `[UU]` healthy, `[U_]` degraded |
| xfsprogs 6.16 | Refuses to create XFS below 300 MB |

| Task | Command |
|---|---|
| List disks and filesystems | `lsblk -f` |
| Partition non-interactively | `sudo parted -s /dev/sdb mklabel gpt mkpart data 1MiB 100%` |
| Format and label | `sudo mkfs.xfs -L data /dev/sdb1` |
| Mount permanently | UUID line in `/etc/fstab`, `sudo systemctl daemon-reload`, `sudo mount -a` |
| Build LVM | `sudo pvcreate /dev/sdc; sudo vgcreate vg /dev/sdc; sudo lvcreate -n lv -L 5G vg` |
| Grow LV and filesystem | `sudo lvextend -r -L +5G vg/lv` |
| Add swap file | `sudo dd if=/dev/zero of=/swapfile bs=1M count=2048; sudo chmod 600 /swapfile; sudo mkswap /swapfile; sudo swapon /swapfile` |
| Grow a cloud root disk | `sudo growpart /dev/nvme0n1 1; sudo resize2fs /dev/nvme0n1p1` |
| Find what fills a volume | `sudo du -xh --max-depth=1 /var` |
| Deleted but open files | `sudo lsof -a +L1 /var` |
| Snapshot backup | `sudo lvcreate -s -n snap -L 1G vg/lv` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Disks and Devices](disks-and-devices.md) | Device names, `lsblk`, `blkid`, stable names, SMART, loop devices | Core | Med |
| [Partitioning](partitioning.md) | MBR and GPT, `fdisk`, `parted`, `gdisk`, re-reading tables, layout design | RHCSA | Med |
| [Filesystems](filesystems.md) | ext4, XFS, Btrfs, `mkfs`, tuning, checking, superblock recovery, shrinking | Core | Med |
| [Mounting and fstab](mounting-and-fstab.md) | Mount options, fstab, generated units, broken entries, busy targets, mount units | Core | High |
| [Swap](swap.md) | Swap partitions and files, priorities, swappiness, swap per process and cgroup | Core | Med |
| [LVM](lvm.md) | PV, VG, LV, extending, reducing, snapshots, `pvmove`, thin pools, devices file | Core | High |
| [Resizing and Cloud Disks](resizing-and-cloud-disks.md) | Rescan, `growpart`, `pvresize`, online filesystem growth | Core | Med |
| [Disk Usage](disk-usage.md) | `df`, `du`, sparse files, inodes, reserved blocks, deleted open files, hidden files | Core | High |
| [Quotas](quotas.md) | XFS and ext4 user quotas, soft and hard limits | RHCSA | Low |
| [Backup and Restore](backup-and-restore.md) | Backup types, `rsync`, hard-link snapshots, `tar` incrementals, LVM snapshots, verification | Core | Med |
| [RAID and Encryption](raid-and-encryption.md) | `mdadm` RAID 1, failure and rebuild, LUKS2, crypttab | Advanced | Low |

---

## Scenarios and Labs

- [Disk Full](../interview/scenarios/disk-full.md): blocks, deleted open files, a runaway log and inodes
- [Storage and LVM Lab](../labs/storage-and-lvm-lab.md): partitions, filesystems, fstab, LVM, swap and a cloud-style resize on loop devices
