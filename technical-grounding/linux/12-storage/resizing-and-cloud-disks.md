# Resizing and Cloud Disks

Growing a disk in a cloud console changes only the block device; the partition, the LVM physical volume and the filesystem above it each need their own step. The full sequence is a common operations ticket and a common interview task.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Layers to grow | Disk → partition → PV (if LVM) → LV → filesystem | `lsblk` |
| See the new disk size | NVMe and Virtio: automatic; SCSI: `echo 1 > /sys/class/block/sdX/device/rescan` | `lsblk` |
| Grow a partition | `growpart <disk> <number>` (package `cloud-utils-growpart` on RHEL, `cloud-guest-utils` on Ubuntu) | `lsblk` |
| Grow a PV | `pvresize <partition>` | `pvs` |
| Grow an LV and its filesystem | `lvextend -r -l +100%FREE <vg>/<lv>` | `df -h` |
| Grow a filesystem | ext4: `resize2fs <device>`; XFS: `xfs_growfs <mountpoint>` | `df -h` |
| Online | Every step above works on mounted filesystems, including `/` | `findmnt /` |
| Shrinking | Cloud volumes cannot shrink; create a smaller volume and copy the data | provider console |
| Boot-time growth | cloud-init `growpart` and `resize_rootfs` grow the root partition and filesystem on first boot | `cloud-init status --long` |
| Partition position | Only the last partition, or one followed by free space, can grow in place | `sudo parted <disk> print free` |
| MBR limit | A partition on an MBR disk cannot use space beyond 2 TiB | `sudo fdisk -l` |
| AWS | `aws ec2 modify-volume --size`; repeated modifications of one volume are rate-limited | `aws ec2 describe-volumes-modifications` |
<!-- --8<-- [end:facts] -->

---

## Growing a Partition and Its Filesystem

`cloud1.img` stands in for a 1 GiB cloud volume with one GPT partition holding XFS:

```bash
cd /var/tmp/disks
truncate -s 1G cloud1.img
sudo losetup -fP --show cloud1.img
sudo parted -s /dev/loop4 mklabel gpt mkpart data 1MiB 100%
sudo mkfs.xfs -q /dev/loop4p1
sudo mkdir -p /srv/cloud && sudo mount /dev/loop4p1 /srv/cloud
df -h /srv/cloud
```

Output:

```text
/dev/loop4
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop4p1    958M   51M  908M   6% /srv/cloud
```

Enlarging the file plays the part of the console resize. A loop device needs `losetup -c` to notice, which matches the SCSI rescan on a physical or VMware disk:

```bash
truncate -s 3G cloud1.img
lsblk /dev/loop4
sudo losetup -c /dev/loop4
lsblk /dev/loop4
```

Output:

```text
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop4       7:4    0    1G  0 loop 
└─loop4p1 259:3    0 1022M  0 part /srv/cloud
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop4       7:4    0    3G  0 loop 
└─loop4p1 259:3    0 1022M  0 part /srv/cloud
```

Then the partition and the filesystem, each in its own step:

```bash
sudo growpart /dev/loop4 1
sudo growpart /dev/loop4 1; echo "rc=$?"
lsblk /dev/loop4
df -h /srv/cloud
sudo xfs_growfs /srv/cloud | tail -1
df -h /srv/cloud
```

Output:

```text
CHANGED: partition=1 start=2048 old: size=2093056 end=2095103 new: size=6289375 end=6291422
NOCHANGE: partition 1 is size 6289375. it cannot be grown
rc=1
NAME      MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
loop4       7:4    0   3G  0 loop 
└─loop4p1 259:3    0   3G  0 part /srv/cloud
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop4p1    958M   51M  908M   6% /srv/cloud
data blocks changed from 261632 to 786171
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop4p1    3.0G   91M  2.9G   4% /srv/cloud
```

`growpart` takes the disk and the partition number as separate arguments, keeps the start sector and moves the end. The partition was 3 GiB while `df` still showed 958 MiB, until `xfs_growfs` grew the filesystem. On ext4, the last step is `sudo resize2fs /dev/loop4p1`.

!!! warning "growpart /dev/loop4p1 is wrong"
    Passing the partition as one argument prints the usage text and `must supply partition-number` (exit 2); the syntax is `growpart /dev/nvme0n1 1` or `growpart /dev/xvda 1`. On NVMe the partition is `nvme0n1p1`, but `growpart` still takes `nvme0n1` and `1`.

---

## Growing an LVM Root Layout

RHEL images put the root filesystem in LVM on the last partition. `cloud2.img` reproduces that with `vgroot/root` on `loop5p1`, created with `parted`, `vgcreate`, `lvcreate -l 100%FREE` and `mkfs.ext4`, and mounted at `/srv/root`:

```bash
truncate -s 2G cloud2.img
sudo losetup -c /dev/loop5
sudo growpart /dev/loop5 1
sudo pvs /dev/loop5p1
sudo pvresize /dev/loop5p1
sudo lvextend -r -l +100%FREE vgroot/root
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS /dev/loop5
df -h /srv/root
```

Output:

```text
CHANGED: partition=1 start=2048 old: size=2093056 end=2095103 new: size=4192223 end=4194270
  PV           VG     Fmt  Attr PSize  PFree
  /dev/loop5p1 vgroot lvm2 a--  <2.00g 1.00g
  Physical volume "/dev/loop5p1" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized
  File system ext4 found on vgroot/root mounted at /srv/root.
  Size of logical volume vgroot/root changed from 1020.00 MiB (255 extents) to <2.00 GiB (511 extents).
  Extending file system ext4 to <2.00 GiB (2143289344 bytes) on vgroot/root...
resize2fs /dev/vgroot/root
resize2fs 1.47.1 (20-May-2024)
Filesystem at /dev/vgroot/root is mounted on /srv/root; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 1
The filesystem on /dev/vgroot/root is now 523264 (4k) blocks long.

resize2fs done
  Extended file system ext4 on vgroot/root.
  Logical volume vgroot/root successfully resized.
NAME            SIZE TYPE MOUNTPOINTS
loop5             2G loop 
└─loop5p1         2G part 
  └─vgroot-root   2G lvm  /srv/root
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/vgroot-root  2.0G   24K  1.9G   1% /srv/root
```

`pvresize` records the new partition size in the PV metadata, and `lvextend -r` takes the free extents and resizes ext4 while it stays mounted. On a real RHEL instance the same commands read `sudo growpart /dev/nvme0n1 3`, `sudo pvresize /dev/nvme0n1p3` and `sudo lvextend -r -l +100%FREE rhel/root`.

!!! tip "Snapshot the cloud volume before resizing"
    Growing is safe on current tools, but a snapshot in the provider console costs little and covers a mistyped device name.

---

## When the Partition Cannot Grow

| Situation | Approach |
|---|---|
| Swap or another partition follows the one to grow | Move or remove that partition, or add a new disk to the VG instead |
| Filesystem directly on the disk (no partition), as on these playgrounds | Skip `growpart`; run `resize2fs` or `xfs_growfs` after the rescan |
| MBR disk growing past 2 TiB | Convert to GPT with `sgdisk -g` (needs free space at the end for the backup table) |
| XFS must become smaller | New smaller volume, copy with `rsync -aHAX` or `xfsdump`, switch mount points |

---

## Common Errors

### `NOCHANGE: partition 1 is size 6289375. it cannot be grown`

**Cause:** there is no free space after the partition: the disk resize has not reached the kernel yet, or the partition was already grown.

**Fix:** check `lsblk` for the new disk size; rescan the device (`echo 1 | sudo tee /sys/class/block/sdb/device/rescan`) or wait for the provider's modification to finish.

### `sudo: growpart: command not found`

**Cause:** the tool comes in a separate package.

**Fix:** `sudo dnf install cloud-utils-growpart` or `sudo apt install cloud-guest-utils`; `sudo parted /dev/sdb resizepart 1 100%` does the same job.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: An EBS volume was enlarged from 20 to 50 GiB, but df still shows 20 GiB. Why?"
    **Say first:** the volume grew, but the partition and filesystem on it keep their old size until they are grown too.

    **Proof:** `lsblk` shows a 50 GiB disk with a 20 GiB partition; `df -h` shows the filesystem.

    **Follow-up:** Which commands finish the job for XFS on a partition?

??? question "L1: Can a cloud volume be shrunk?"
    **Say first:** no; the data must be copied to a new, smaller volume.

    **Proof:** the provider rejects a smaller size in `modify-volume`.

    **Follow-up:** Which filesystem also rules out shrinking in place?
<!-- --8<-- [end:l1] -->

??? question "L2: Grow the root filesystem of an Ubuntu EC2 instance after enlarging its volume."
    **Say first:** grow partition 1 of the NVMe disk, then the ext4 filesystem.

    **Proof:** `lsblk`; `sudo growpart /dev/nvme0n1 1`; `sudo resize2fs /dev/nvme0n1p1`; `df -h /`.

    **Follow-up:** Why can this run while `/` is mounted?

??? question "L2: Grow the LVM root filesystem of a RHEL VM after its disk was enlarged."
    **Say first:** rescan if needed, grow the partition, resize the PV, then extend the LV with its filesystem.

    **Proof:** `sudo growpart /dev/sda 3; sudo pvresize /dev/sda3; sudo lvextend -r -l +100%FREE rhel/root`.

    **Follow-up:** What is the alternative when the partition is not the last one? (A new partition or disk added with `vgextend`.)

??? question "L2: A VMware disk was enlarged, but lsblk shows the old size."
    **Say first:** SCSI disks need a rescan before the kernel sees the new capacity.

    **Proof:** `echo 1 | sudo tee /sys/class/block/sdb/device/rescan`; `lsblk /dev/sdb`.

    **Follow-up:** Which command does the same for a loop device? (`losetup -c`.)

??? question "L3: After growpart and xfs_growfs, df still shows the old size. What do you check?"
    **Say first:** whether each layer changed: disk, partition, PV and LV, and whether `xfs_growfs` ran against the right mount point.

    **Proof:** `lsblk`; `sudo pvs`; `sudo lvs`; `xfs_info <mountpoint>`; for LVM, `sudo lvextend -r` was probably skipped.

    **Follow-up:** Why does `xfs_growfs` take a mount point and `resize2fs` a device?

---

## Related

- [LVM](lvm.md): `pvresize`, `lvextend` and adding disks
- [Partitioning](partitioning.md): partition layout and table types
- [Filesystems](filesystems.md): which filesystems grow and shrink
- [Disk Usage](disk-usage.md): finding what filled the volume first

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167, cloud-utils-growpart, LVM 2.03.36), 2026-09.
