# Partitioning

A partition table divides a disk into ranges that hold filesystems, swap or LVM physical volumes. `fdisk`, `gdisk` and `parted` write MBR or GPT tables, and the kernel must re-read the table before the new partitions can be used.

**Track:** RHCSA · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `fdisk` | Interactive, MBR and GPT; changes stay in memory until `w` | `sudo fdisk -l /dev/sdb` |
| `gdisk`, `sgdisk` | GPT only; type codes such as `8300`, `8E00`, `EF00`, `8200` | `sudo gdisk -l /dev/sdb` |
| `parted` | MBR and GPT, scriptable with `-s`; writes each command at once | `sudo parted /dev/sdb print free` |
| `sfdisk` | Dumps and restores a table as text | `sudo sfdisk -d /dev/sdb > sdb.dump` |
| MBR type IDs | `83` Linux, `82` swap, `8e` LVM, `fd` RAID, `ef` EFI | `fdisk` command `l` |
| MBR layout | 4 primary, or 3 primary plus 1 extended holding logical partitions (`5` and up) | `sudo fdisk -l` |
| Alignment | Partitions start at 1 MiB (sector 2048) | `sudo parted /dev/sdb align-check optimal 1` |
| Re-read the table | `partprobe <disk>`, or `partx -a` (add) and `partx -u` (update) | `lsblk <disk>` |
| Remove signatures | `wipefs -a <device>` (without `-a` it only lists them) | `sudo wipefs /dev/sdb` |
| ESP | GPT type `EF00` (ESP flag in `parted`), FAT32, mounted at `/boot/efi` | `lsblk -o NAME,PARTTYPENAME` |
| BIOS boot | GPT disk booting in BIOS mode needs a 1 MiB `EF02` partition for GRUB | `sudo gdisk -l` |
<!-- --8<-- [end:facts] -->

---

## MBR with fdisk

`fdisk` is interactive; the keys below are piped in here so the session can be repeated. `o` creates an empty MBR table, `n` a partition, `t` sets a type and `w` writes and exits (`q` quits without writing).

```bash
printf 'o\nn\np\n1\n\n+500M\nn\np\n2\n\n+1G\nt\n2\n82\nw\n' | sudo fdisk /dev/loop0
sudo fdisk -l /dev/loop0
```

Output:

```text
Welcome to fdisk (util-linux 2.40.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS (MBR) disklabel with disk identifier 0xd4efa3d4.

Command (m for help): Created a new DOS (MBR) disklabel with disk identifier 0x285f8258.
# ... (trimmed)
Created a new partition 1 of type 'Linux' and of size 500 MiB.
# ... (trimmed)
Created a new partition 2 of type 'Linux' and of size 1 GiB.

Command (m for help): Partition number (1,2, default 2): Hex code or alias (type L to list all):
Changed type of partition 'Linux' to 'Linux swap / Solaris'.

Command (m for help): The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

Disk /dev/loop0: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x285f8258

Device       Boot   Start     End Sectors  Size Id Type
/dev/loop0p1         2048 1026047 1024000  500M 83 Linux
/dev/loop0p2      1026048 3123199 2097152    1G 82 Linux swap / Solaris
```

An empty answer accepts the default: the next partition number and the first free sector. `+500M` sets the size relative to the start.

!!! warning "Partitioning the wrong disk destroys it"
    `fdisk` writes to whatever device it is given. Confirm the target with `lsblk -f` (no filesystem, no mount point, expected size) before pressing `w`.

---

## GPT with parted and gdisk

`parted -s` runs without prompts, which suits scripts and cloud-init. Sizes in `MiB` keep partitions aligned.

```bash
sudo parted -s /dev/loop1 mklabel gpt \
  mkpart esp fat32 1MiB 201MiB set 1 esp on \
  mkpart data xfs 201MiB 1225MiB \
  mkpart pv 1225MiB 100% set 3 lvm on
sudo parted /dev/loop1 unit MiB print free
sudo gdisk -l /dev/loop1 | tail -8
```

Output:

```text
Model: Loopback device (loopback)
Disk /dev/loop1: 2048MiB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start    End      Size     File system  Name  Flags
        0.02MiB  1.00MiB  0.98MiB  Free Space
 1      1.00MiB  201MiB   200MiB                esp   boot, esp
 2      201MiB   1225MiB  1024MiB               data
 3      1225MiB  2047MiB  822MiB                pv    lvm
        2047MiB  2048MiB  0.98MiB  Free Space

First usable sector is 34, last usable sector is 4194270
Partitions will be aligned on 2048-sector boundaries
Total free space is 4029 sectors (2.0 MiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048          411647   200.0 MiB   EF00  esp
   2          411648         2508799   1024.0 MiB  8300  data
   3         2508800         4192255   822.0 MiB   8E00  pv
```

The `xfs` and `fat32` words in `mkpart` only set the type code; `parted` does not create filesystems, so the `File system` column stays empty until `mkfs` runs. The last megabyte stays free because the backup GPT occupies the final 33 sectors.

!!! note "parted writes immediately"
    `fdisk` and `gdisk` keep changes in memory until `w`, while each `parted` command changes the disk at once. A mistyped `rm` or `mklabel` in `parted` has no undo.

---

## Making the Kernel See the Change

On a disk with a mounted partition, `fdisk` 2.40 warns (`This disk is currently in use - repartitioning is probably a bad idea.`) and still adds new partitions one by one. `loop0p1` already holds an ext4 filesystem (`sudo mkfs.ext4 -q /dev/loop0p1`):

```bash
sudo mount /dev/loop0p1 /mnt
printf 'n\np\n3\n\n+300M\nw\n' | sudo fdisk /dev/loop0 2>&1 | tail -8
lsblk /dev/loop0
sudo umount /mnt
```

Output:

```text
Select (default p): Partition number (3,4, default 3): First sector (3123200-4194303, default 3123200): Last sector, +/-sectors or +/-size{K,M,G,T,P} (3123200-4194303, default 4194303): 
Created a new partition 3 of type 'Linux' and of size 300 MiB.

Command (m for help): The partition table has been altered.
Syncing disks.

NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0       7:0    0    2G  0 loop 
├─loop0p3 259:0    0  300M  0 part 
├─loop0p1 259:8    0  500M  0 part /mnt
└─loop0p2 259:9    0    1G  0 part 
```

When the kernel refuses the re-read, the new table exists on disk but not in `/dev`. A loop device attached without `-P` shows the case:

```bash
truncate -s 1G /var/tmp/noscan.img
sudo losetup --show -f /var/tmp/noscan.img
printf 'o\nn\np\n1\n\n\nw\n' | sudo fdisk /dev/loop4 2>&1 | tail -4
lsblk /dev/loop4
sudo partprobe /dev/loop4; lsblk /dev/loop4
```

Output:

```text
/dev/loop4
Re-reading the partition table failed.: Invalid argument

The kernel still uses the old table. The new table will be used at the next reboot or after you run partprobe(8) or partx(8).

NAME  MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
loop4   7:4    0   1G  0 loop 
NAME      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop4       7:4    0    1G  0 loop 
└─loop4p1 259:1    0 1023M  0 part 
```

---

## Backing Up a Table

```bash
sudo sfdisk -d /dev/loop0 | tee loop0.sfdisk
sudo wipefs /dev/loop0
```

Output:

```text
label: dos
label-id: 0x285f8258
device: /dev/loop0
unit: sectors
sector-size: 512

/dev/loop0p1 : start=        2048, size=     1024000, type=83
/dev/loop0p2 : start=     1026048, size=     2097152, type=82
/dev/loop0p3 : start=     3123200, size=      614400, type=83
DEVICE OFFSET TYPE UUID LABEL
loop0  0x1fe  dos       
```

`sudo sfdisk /dev/loop0 < loop0.sfdisk` writes the same table back; `sgdisk --backup=file` and `--load-backup=file` do the same for GPT. Restoring the table restores access to the data only if the filesystems were not overwritten.

---

## Designing a Layout

| Mount point | Typical size | Reason |
|---|---|---|
| `/boot/efi` | 200 to 600 MiB, FAT32 | Required on UEFI systems |
| `/boot` | 1 GiB | Kernels and initramfs images; kept outside LVM for simpler boot and recovery |
| `/` | 20 GiB or more | Operating system and packages |
| `/var` or `/var/log` | Separate volume | A runaway log fills this volume instead of `/` |
| `/home`, `/srv`, `/opt` | Separate volumes where users or applications write | Limits the impact of a full volume |
| swap | Up to the RAM size on small hosts; a few GiB on large ones, more for hibernation | See [Swap](swap.md) |

RHEL installs put everything except `/boot` and `/boot/efi` into LVM. Cloud images usually ship one root partition that grows with the volume, as shown in [Resizing and Cloud Disks](resizing-and-cloud-disks.md).

---

## Common Errors

### `Re-reading the partition table failed.: Invalid argument`

**Cause:** the kernel refused the whole-table re-read: the device does not support partitions (a loop device without `-P`), or, with `Device or resource busy` instead, a partition is mounted or held by LVM or RAID.

**Fix:** `sudo partprobe <disk>` or `sudo partx -a <disk>`, which add partitions individually; unmount first if an existing partition changed size.

### `Error: /dev/sdb: unrecognised disk label`

**Cause:** `parted print` ran on a disk without a partition table (`Partition Table: unknown`, exit status 1).

**Fix:** `sudo parted -s /dev/sdb mklabel gpt` after confirming the disk is the new one.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between fdisk, gdisk and parted?"
    **Say first:** `fdisk` and `gdisk` are interactive and write on `w` (`gdisk` handles GPT only), while `parted` applies each command immediately and scripts well with `-s`.

    **Proof:** `sudo fdisk -l`, `sudo gdisk -l`, `sudo parted -s /dev/sdb print`.

    **Follow-up:** Which tool dumps a table as text for backup? (`sfdisk -d`.)

??? question "L1: Why do partitions start at sector 2048?"
    **Say first:** a 1 MiB start aligns partitions with the erase blocks of SSDs and the stripes of RAID arrays, and leaves room for boot code on MBR disks.

    **Proof:** `sudo fdisk -l` shows `Start 2048`; `sudo parted /dev/sdb align-check optimal 1`.

    **Follow-up:** What does misalignment cost? (Extra writes and lower performance on every I/O.)
<!-- --8<-- [end:l1] -->

??? question "L2: Create a 1 GiB LVM partition on a new GPT disk non-interactively."
    **Say first:** use `parted -s` with a label, a partition in MiB and the `lvm` flag.

    **Proof:** `sudo parted -s /dev/sdb mklabel gpt mkpart pv 1MiB 1025MiB set 1 lvm on`, then `sudo partprobe /dev/sdb; lsblk /dev/sdb`.

    **Follow-up:** Which `sgdisk` command does the same? (`sgdisk -n 1:0:+1G -t 1:8E00 /dev/sdb`.)

??? question "L2: A new partition was written but /dev/sdb2 does not exist. Fix it without a reboot."
    **Say first:** ask the kernel to re-read the table.

    **Proof:** `sudo partprobe /dev/sdb` or `sudo partx -a /dev/sdb`, then `lsblk /dev/sdb`.

    **Follow-up:** Why can a full re-read fail while `partx` works? (The whole-disk re-read refuses while any partition is busy.)

??? question "L2: Create a logical partition on an MBR disk that already has three primary partitions."
    **Say first:** create partition 4 as extended over the free space, then add logical partitions inside it, numbered from 5.

    **Proof:** in `fdisk`: `n`, `e`, then `n` again; `sudo fdisk -l` shows `Extended` and `sdb5`.

    **Follow-up:** Why is GPT simpler here?

??? question "L3: After someone ran fdisk on the wrong disk, the server's data partition is missing. What do you do?"
    **Say first:** stop writing to the disk, restore the old table from a backup or rebuild it with the same start sectors, and leave the filesystems untouched.

    **Proof:** `sudo sfdisk /dev/sdb < sdb.dump`; without a dump, `testdisk` searches for filesystem signatures; `sudo wipefs /dev/sdb1` then shows the old signature.

    **Follow-up:** Which command should run before any partitioning to make this recoverable?

---

## Related

- [Disks and Devices](disks-and-devices.md): identifying the disk and the loop devices used here
- [Filesystems](filesystems.md): formatting the new partitions
- [LVM](lvm.md): using partition 3 as a physical volume

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
