# Disks and Devices

The kernel presents every disk, partition, loop file and logical volume as a block device under `/dev`. Identifying the right device before partitioning or formatting it is the step that prevents data loss.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| List block devices | `lsblk`; `lsblk -f` adds filesystem, label, UUID and usage | `lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS` |
| Filesystem signatures | `blkid` (as root for uncached devices) | `sudo blkid` |
| SATA, SAS, USB disks | `/dev/sda`, `/dev/sdb`; partitions `sda1` | `lsblk` |
| Virtio disks (KVM) | `/dev/vda`; partitions `vda1` | `lsblk -o NAME,TRAN` |
| NVMe | `/dev/nvme0n1` (controller 0, namespace 1); partitions `nvme0n1p1` | `nvme list` |
| Xen disks (older EC2) | `/dev/xvda` | `lsblk` |
| Other block devices | `loopN` (file), `dm-N` (LVM, LUKS), `mdN` (software RAID), `sr0` (optical) | `lsblk -o NAME,TYPE` |
| Stable names | `/dev/disk/by-uuid`, `by-id`, `by-path`, `by-label`, `by-partuuid` | `ls -l /dev/disk/by-uuid` |
| Rotational flag | `1` spinning disk (and most virtual disks), `0` SSD | `cat /sys/block/<dev>/queue/rotational` |
| Size in sectors | `/sys/block/<dev>/size`, always in 512-byte units | `cat /sys/block/vda/size` |
| MBR | 4 primary partitions (or 3 plus an extended one), 2 TiB limit | `fdisk -l` |
| GPT | 128 partitions by default, backup table at the end of the disk, needed above 2 TiB and for UEFI | `gdisk -l` |
| Disk health | `smartctl -H` (SATA, SAS), `nvme smart-log` (NVMe); physical or passthrough disks only | `sudo smartctl -i /dev/sda` |
| Loop device | Presents a file as a disk: `losetup -fP --show <file>` | `losetup -l` |
<!-- --8<-- [end:facts] -->

---

## Listing Block Devices

=== "RHEL / Rocky"

    ```bash
    lsblk -o NAME,MAJ:MIN,SIZE,TYPE,ROTA,TRAN,MOUNTPOINTS
    lsblk -f
    sudo blkid
    cat /sys/block/vda/queue/rotational /sys/block/vda/size /sys/block/vda/queue/logical_block_size
    ```

    Output:

    ```text
    NAME MAJ:MIN SIZE TYPE ROTA TRAN   MOUNTPOINTS
    vda  253:0    80G disk    1 virtio /
    NAME FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
    vda  ext4   1.0         0a80853f-1c24-4c13-8293-19cd53de6bbe   72.1G     3% /
    /dev/vda: UUID="0a80853f-1c24-4c13-8293-19cd53de6bbe" BLOCK_SIZE="4096" TYPE="ext4"
    1
    167772192
    512
    ```

=== "Ubuntu / Debian"

    ```bash
    lsblk -o NAME,MAJ:MIN,SIZE,TYPE,ROTA,TRAN,MOUNTPOINTS
    lsblk -f
    ```

    Output:

    ```text
    NAME  MAJ:MIN   SIZE TYPE ROTA TRAN   MOUNTPOINTS
    loop0   7:0   105.2M loop    1        /snap/core/17292
    loop1   7:1    50.3M loop    1        /snap/snapd/27738
    vda   253:0      80G disk    1 virtio /
    NAME  FSTYPE   FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
    loop0 squashfs 4.0                                                    0   100% /snap/core/17292
    loop1 squashfs 4.0                                                    0   100% /snap/snapd/27738
    vda   ext4     1.0         0dc9cc86-daa7-4fcf-825d-21da512ae1f8   71.6G     4% /
    ```

    The `loop` devices are snap packages, each a read-only squashfs image; they are always 100% full by design.

Both playgrounds format the whole Virtio disk as ext4 without a partition table, which is common for microVMs and rare on servers. The disk holds 167772192 sectors of 512 bytes, which is 80 GiB.

!!! note "A virtual disk reports ROTA 1 even on SSD storage"
    The Virtio driver does not know what backs the disk, so `ROTA` says rotational. Cloud providers publish the storage type in the volume settings instead.

---

## Stable Names

```bash
ls -l /dev/disk/by-uuid /dev/disk/by-path
```

Output:

```text
/dev/disk/by-path:
total 0
lrwxrwxrwx 1 root root 9 Sep 17 07:25 pci-0000:00:01.0 -> ../../vda
lrwxrwxrwx 1 root root 9 Sep 17 07:25 virtio-pci-0000:00:01.0 -> ../../vda

/dev/disk/by-uuid:
total 0
lrwxrwxrwx 1 root root 9 Sep 17 07:25 0a80853f-1c24-4c13-8293-19cd53de6bbe -> ../../vda
```

Kernel names follow detection order, so `sdb` can become `sdc` after a reboot or a hot-plug. `/etc/fstab` and scripts use the UUID of the filesystem, or the `by-id` name of the disk, which contains the model and serial number.

!!! warning "EC2 Nitro instances rename attached volumes"
    A volume attached as `/dev/sdf` in the AWS console appears as an NVMe device such as `/dev/nvme1n1` inside the instance. The volume ID is in the `by-id` link (`nvme-Amazon_Elastic_Block_Store_vol...`) and in the `nvme id-ctrl` serial number.

---

## Disk Health

`smartctl` reads SMART data from SATA and SAS disks, and `nvme` from NVMe drives. A virtual disk has no SMART data:

```bash
sudo smartctl -i /dev/vda; echo "rc=$?"
sudo nvme list; echo "rc=$?"
```

Output:

```text
smartctl 7.4 2023-08-01 r5530 [x86_64-linux-6.1.167] (local build)
Copyright (C) 2002-23, Bruce Allen, Christian Franke, www.smartmontools.org

/dev/vda: Unable to detect device type
Please specify device type with the -d option.

Use smartctl -h to get a usage summary

rc=1
Failed to scan topology: No such file or directory
rc=1
```

On a physical server, `sudo smartctl -H /dev/sda` prints the overall health result, and `sudo smartctl -A /dev/sda` lists attributes such as `Reallocated_Sector_Ct` and `Current_Pending_Sector`, whose growth predicts failure. `sudo nvme smart-log /dev/nvme0` reports `percentage_used` and `media_errors`. `smartd` from the same package watches disks and logs changes.

---

## Test Disks with Loop Devices

A loop device turns a file into a block device, so partitioning, LVM and RAID can be practised without spare disks. The rest of this module uses four 2 GiB sparse files:

```bash
mkdir -p /var/tmp/disks && cd /var/tmp/disks
truncate -s 2G disk1.img disk2.img disk3.img disk4.img
ls -ls
for f in disk?.img; do sudo losetup -fP --show "$f"; done
losetup -l
lsblk -o NAME,MAJ:MIN,SIZE,TYPE
```

Output:

```text
total 0
0 -rw-r--r-- 1 laborant laborant 2147483648 Sep 17 07:28 disk1.img
0 -rw-r--r-- 1 laborant laborant 2147483648 Sep 17 07:28 disk2.img
0 -rw-r--r-- 1 laborant laborant 2147483648 Sep 17 07:28 disk3.img
0 -rw-r--r-- 1 laborant laborant 2147483648 Sep 17 07:28 disk4.img
/dev/loop0
/dev/loop1
/dev/loop2
/dev/loop3
NAME       SIZELIMIT OFFSET AUTOCLEAR RO BACK-FILE                DIO LOG-SEC
/dev/loop1         0      0         0  0 /var/tmp/disks/disk2.img   0     512
/dev/loop2         0      0         0  0 /var/tmp/disks/disk3.img   0     512
/dev/loop0         0      0         0  0 /var/tmp/disks/disk1.img   0     512
/dev/loop3         0      0         0  0 /var/tmp/disks/disk4.img   0     512
NAME  MAJ:MIN SIZE TYPE
loop0   7:0     2G loop
loop1   7:1     2G loop
loop2   7:2     2G loop
loop3   7:3     2G loop
vda   253:0    80G disk
```

The files use no blocks until data is written (`0` in the first column of `ls -s`). `-f` takes the first free loop device, `-P` makes the kernel scan partitions, and `--show` prints the device name. `sudo losetup -d /dev/loop0` detaches one device; attachments do not survive a reboot.

---

## Common Errors

### `/dev/vda: Unable to detect device type`

**Cause:** the device is virtual or behind a controller that `smartctl` cannot identify.

**Fix:** on hardware RAID, pass the controller type (`-d megaraid,N`); on a VM, check disk health on the host or in the cloud console.

### `losetup: cannot find an unused loop device`

**Cause:** every loop device is in use and no new one could be created (common inside containers without `/dev/loop-control`).

**Fix:** `losetup -l` to find stale attachments and `sudo losetup -d` them; in a container, run the task on the host.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between /dev/sda, /dev/vda and /dev/nvme0n1?"
    **Say first:** they are disks on different drivers: SCSI layer (SATA, SAS, USB), Virtio in a KVM guest, and NVMe controller 0, namespace 1.

    **Proof:** `lsblk -o NAME,TRAN` shows `sata`, `virtio` or `nvme`.

    **Follow-up:** How are partitions on an NVMe disk named? (`nvme0n1p1`, because the name ends in a digit.)

??? question "L1: When must a disk use GPT instead of MBR?"
    **Say first:** above 2 TiB, with more than four primary partitions, and when the machine boots in UEFI mode.

    **Proof:** `sudo fdisk -l /dev/sda` shows `Disklabel type: gpt` or `dos`.

    **Follow-up:** Where does GPT keep its backup table? (In the last sectors of the disk.)
??? question "L1: Why does /etc/fstab use UUIDs instead of device names?"
    **Say first:** device names follow detection order and can change, while the filesystem UUID stays with the data.

    **Proof:** `ls -l /dev/disk/by-uuid`; `lsblk -f`.

    **Follow-up:** What changes the UUID? (Recreating the filesystem, or `tune2fs -U` and `xfs_admin -U`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Find the new disk that was attached to a running server."
    **Say first:** list block devices and pick the one with no partitions, no filesystem and no mount point, matching the expected size.

    **Proof:** `lsblk -f`; `sudo dmesg | tail` shows the new device; `ls -l /dev/disk/by-id`.

    **Follow-up:** How do you make it visible without a reboot on a SCSI bus? (`echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan`.)

??? question "L2: Create a practice disk without a spare device."
    **Say first:** create a sparse file and attach it as a loop device with partition scanning.

    **Proof:** `truncate -s 2G d.img; sudo losetup -fP --show d.img`.

    **Follow-up:** Why does `ls -ls` show 0 blocks for the file?

??? question "L2: Check whether a physical disk is failing."
    **Say first:** read its SMART health and the reallocated and pending sector counts, and check the kernel log for I/O errors.

    **Proof:** `sudo smartctl -H -A /dev/sda`; `sudo nvme smart-log /dev/nvme0`; `journalctl -k | grep -i 'i/o error'`.

    **Follow-up:** Which RAID layer hides SMART data, and how do you reach it?

??? question "L3: A volume was attached to an EC2 instance as /dev/sdf, but the device does not exist. What happened?"
    **Say first:** on Nitro instances, EBS volumes appear as NVMe devices, so the disk is `/dev/nvme1n1` or similar.

    **Proof:** `lsblk -o NAME,SIZE,SERIAL`; `ls -l /dev/disk/by-id/ | grep Elastic`.

    **Follow-up:** Why must `/etc/fstab` on such an instance use UUIDs?

---

## Related

- [Partitioning](partitioning.md): MBR and GPT tables on these disks
- [Devices and udev](../11-kernel-and-hardware/devices-and-udev.md): major and minor numbers and the `/dev/disk` links
- [Mounting and fstab](mounting-and-fstab.md): using UUIDs in `/etc/fstab`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
