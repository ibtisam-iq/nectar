# LVM

The Logical Volume Manager pools disks into volume groups and carves logical volumes out of them, so filesystems can grow across disks, move between disks and be snapshotted while in use. RHEL installs its root filesystem on LVM by default, and extending a full volume is a routine operations task.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Layers | Physical volume (PV) → volume group (VG) → logical volume (LV) → filesystem | `lsblk` |
| Extents | A VG is split into physical extents (PE, 4 MiB by default); an LV is a list of them | `vgdisplay` |
| Create | `pvcreate`, `vgcreate <vg> <pvs>`, `lvcreate -n <lv> -L <size> <vg>` (`-l 100%FREE` for extents) | `pvs`, `vgs`, `lvs` |
| Device paths | `/dev/<vg>/<lv>` and `/dev/mapper/<vg>-<lv>`, both links to `/dev/dm-N` | `ls -l /dev/mapper` |
| Grow | `vgextend` adds a PV; `lvextend -r` grows the LV and the filesystem together | `df -h` |
| Shrink | `lvreduce -r` (ext4 only; unmounts it); XFS cannot shrink | `lvs` |
| Snapshot | `lvcreate -s -L <size> -n <snap> <vg>/<lv>`; invalid when full; `lvconvert --merge` rolls back | `lvs` (`Data%`) |
| Move data | `pvmove <pv>` empties a PV online; then `vgreduce` and `pvremove` | `pvs` |
| Thin pools | `--type thin-pool`, `lvcreate -V <size> -T <vg>/<pool>`; allows overprovisioning | `lvs` (`Data%`, `Meta%`) |
| Devices file | RHEL 9 and later only use PVs listed in `/etc/lvm/devices/system.devices`; Ubuntu 24.04 does not use one | `lvmdevices` |
| Metadata backup | `/etc/lvm/backup/<vg>`, restored with `vgcfgrestore` | `vgcfgbackup` |
<!-- --8<-- [end:facts] -->

---

## Building a Volume Group

The empty disks `loop2` and `loop3` become one 4 GiB group (a partitioned disk or a mounted filesystem is refused):

```bash
sudo pvcreate /dev/loop2 /dev/loop3
sudo vgcreate vgdata /dev/loop2 /dev/loop3
sudo lvcreate -n lvweb -L 1G vgdata
sudo lvcreate -n lvdb -l 50%FREE vgdata
sudo pvs; sudo vgs; sudo lvs
lsblk -o NAME,SIZE,TYPE /dev/loop2 /dev/loop3
```

Output:

```text
  Physical volume "/dev/loop2" successfully created.
  Physical volume "/dev/loop3" successfully created.
  Creating devices file /etc/lvm/devices/system.devices
  Volume group "vgdata" successfully created
  Logical volume "lvweb" created.
  Logical volume "lvdb" created.
  PV         VG     Fmt  Attr PSize  PFree   
  /dev/loop2 vgdata lvm2 a--  <2.00g 1020.00m
  /dev/loop3 vgdata lvm2 a--  <2.00g  512.00m
  VG     #PV #LV #SN Attr   VSize VFree 
  vgdata   2   2   0 wz--n- 3.99g <1.50g
  LV    VG     Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lvdb  vgdata -wi-a----- <1.50g                                                    
  lvweb vgdata -wi-a-----  1.00g                                                    
NAME            SIZE TYPE
loop2             2G loop
└─vgdata-lvweb    1G lvm
loop3             2G loop
└─vgdata-lvdb   1.5G lvm
```

Each PV lost 4 MiB to LVM metadata (`<2.00g`). `-l 50%FREE` took half of the 2.99 GiB that was still free.

```bash
sudo vgdisplay vgdata | grep -E 'VG Size|PE Size|Total PE|Alloc PE|Free  PE'
sudo grep -v '^#' /etc/lvm/devices/system.devices
sudo mkfs.xfs -q /dev/vgdata/lvweb
sudo mkfs.ext4 -q /dev/vgdata/lvdb
sudo mkdir -p /srv/web /srv/db
sudo mount /dev/vgdata/lvweb /srv/web
sudo mount /dev/vgdata/lvdb /srv/db
df -h /srv/web /srv/db
```

Output:

```text
  VG Size               3.99 GiB
  PE Size               4.00 MiB
  Total PE              1022
  Alloc PE / Size       639 / <2.50 GiB
  Free  PE / Size       383 / <1.50 GiB
HOSTNAME=rocky-01
VERSION=1.1.2
IDTYPE=loop_file IDNAME=/var/tmp/disks/disk3.img DEVNAME=/dev/loop2 PVID=BuoqqfZvcQqJQTuVu0fkIe5j1epuWEzU
IDTYPE=loop_file IDNAME=/var/tmp/disks/disk4.img DEVNAME=/dev/loop3 PVID=eQ6g5k3W0Rj0bc2Vk1X5sNPLERtKHg4V
Filesystem                Size  Used Avail Use% Mounted on
/dev/mapper/vgdata-lvweb  960M   51M  910M   6% /srv/web
/dev/mapper/vgdata-lvdb   1.5G   24K  1.4G   1% /srv/db
```

!!! warning "A disk moved to a RHEL 9 or 10 host is invisible to LVM until it is added to the devices file"
    `pvcreate` and `vgcreate` add their devices automatically, but PVs created elsewhere are ignored. `sudo lvmdevices --adddev /dev/sdc` or `sudo vgimportdevices <vg>` adds them.

---

## Extending

```bash
sudo lvextend -r -L +500M vgdata/lvweb
sudo lvextend -L +2G vgdata/lvdb; echo "rc=$?"
sudo vgextend vgdata /dev/loop1p3
sudo lvextend -r -l +100%FREE vgdata/lvdb
sudo vgs; df -h /srv/db
```

Output:

```text
  File system xfs found on vgdata/lvweb mounted at /srv/web.
  Size of logical volume vgdata/lvweb changed from 1.00 GiB (256 extents) to <1.49 GiB (381 extents).
  Extending file system xfs to <1.49 GiB (1598029824 bytes) on vgdata/lvweb...
xfs_growfs /dev/vgdata/lvweb
# ... (trimmed)
data blocks changed from 262144 to 390144
xfs_growfs done
  Extended file system xfs on vgdata/lvweb.
  Logical volume vgdata/lvweb successfully resized.
  Insufficient free space: 512 extents needed, but only 258 available
rc=5
  Physical volume "/dev/loop1p3" successfully created.
  Volume group "vgdata" successfully extended
  File system ext4 found on vgdata/lvdb mounted at /srv/db.
  Size of logical volume vgdata/lvdb changed from <1.50 GiB (383 extents) to 3.30 GiB (846 extents).
  Extending file system ext4 to 3.30 GiB (3548381184 bytes) on vgdata/lvdb...
resize2fs /dev/vgdata/lvdb
# ... (trimmed)
resize2fs done
  Extended file system ext4 on vgdata/lvdb.
  Logical volume vgdata/lvdb successfully resized.
  VG     #PV #LV #SN Attr   VSize VFree
  vgdata   3   2   0 wz--n- 4.79g    0 
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/vgdata-lvdb  3.3G   24K  3.1G   1% /srv/db
```

`vgextend` ran `pvcreate` on the GPT partition by itself. Without `-r`, the most common mistake, `lvextend` grows only the volume, and `df` keeps showing the old size until `xfs_growfs /srv/web` or `resize2fs /dev/vgdata/lvdb` runs.

---

## Reducing

=== "RHEL / Rocky"

    LVM 2.03.36 checks the filesystem before reducing, and unmounts and remounts ext4 around `resize2fs`. `--yes` answers its prompt; the redirect keeps a script's input away from it:

    ```bash
    sudo lvreduce -r -L -300M vgdata/lvweb; echo "rc=$?"
    sudo lvreduce --yes -r -L -1G vgdata/lvdb < /dev/null; echo "rc=$?"
    ```

    Output:

    ```text
      File system xfs found on vgdata/lvweb mounted at /srv/web.
      File system size (<1.49 GiB) is larger than the requested size (<1.20 GiB).
      File system reduce is required and not supported (xfs).
    rc=5
      File system ext4 found on vgdata/lvdb mounted at /srv/db.
      File system size (3.30 GiB) is larger than the requested size (2.30 GiB).
      File system reduce is required using resize2fs.
      File system unmount is needed for reduce.
      File system fsck will be run before reduce.
      Reducing file system ext4 to 2.30 GiB (2474639360 bytes) on vgdata/lvdb...
    unmount /srv/db
    unmount done
    e2fsck /dev/vgdata/lvdb
    # ... (trimmed)
    remount /dev/vgdata/lvdb /srv/db
    remount done
      Reduced file system ext4 on vgdata/lvdb.
      Size of logical volume vgdata/lvdb changed from 3.30 GiB (846 extents) to 2.30 GiB (590 extents).
      Logical volume vgdata/lvdb successfully resized.
    rc=0
    ```

=== "Ubuntu / Debian"

    LVM 2.03.16 delegates to `fsadm`, which refuses XFS and asks before unmounting ext4 (`lvweb` is a 700 MiB XFS volume, `lvdb` a 500 MiB ext4 one):

    ```bash
    sudo lvreduce -r -L -100M vgdata/lvweb; echo "rc=$?"
    sudo lvreduce -r -L -100M vgdata/lvdb < /dev/null; echo "rc=$?"
    ```

    Output:

    ```text
    fsadm: Xfs filesystem shrinking is unsupported.
      /usr/sbin/fsadm failed: 1
      Filesystem resize failed.
    rc=5
    Do you want to unmount "/srv/db" ? [Y|n] n
    fsadm: Cannot proceed with mounted filesystem "/srv/db".
      /usr/sbin/fsadm failed: 1
      Filesystem resize failed.
    rc=5
    ```

!!! danger "lvreduce without -r destroys the end of the filesystem"
    Plain `lvreduce -L` cuts the volume regardless of the data on it. Always use `-r`, and take a backup or snapshot first.

---

## Snapshots

A snapshot records the original blocks as the origin changes, so its size limits how much change it can hold:

```bash
echo "orders v1" | sudo tee /srv/db/orders.txt
sudo lvcreate -s -n lvdb_snap -L 200M vgdata/lvdb
echo "orders v2 (bad migration)" | sudo tee /srv/db/orders.txt
sudo dd if=/dev/urandom of=/srv/db/blob bs=1M count=50 status=none; sync
sudo lvs -o lv_name,lv_size,origin,data_percent vgdata
sudo mkdir -p /mnt/snap
sudo mount -o ro /dev/vgdata/lvdb_snap /mnt/snap
cat /mnt/snap/orders.txt /srv/db/orders.txt
sudo umount /mnt/snap
sudo umount /srv/db
sudo lvconvert --merge vgdata/lvdb_snap
sudo mount /srv/db 2>/dev/null || sudo mount /dev/vgdata/lvdb /srv/db
cat /srv/db/orders.txt; ls /srv/db
```

Output:

```text
orders v1
  Logical volume "lvdb_snap" created.
orders v2 (bad migration)
  LV        LSize   Origin Data% 
  lvdb        2.30g              
  lvdb_snap 200.00m lvdb   25.13 
  lvweb      <1.49g              
orders v1
orders v2 (bad migration)
  Merging of volume vgdata/lvdb_snap started.
  vgdata/lvdb: Merged: 91.46%
  vgdata/lvdb: Merged: 100.00%
orders v1
lost+found
orders.txt
```

The merge rolled the origin back and removed the snapshot. A snapshot that fills up becomes unusable:

```bash
sudo lvcreate -s -n tiny_snap -L 20M vgdata/lvdb
sudo dd if=/dev/urandom of=/srv/db/blob2 bs=1M count=50 status=none; sync
sudo lvs -o lv_name,lv_attr,origin,data_percent vgdata/tiny_snap
sudo mount -o ro /dev/vgdata/tiny_snap /mnt/snap; echo "rc=$?"
```

Output:

```text
  Logical volume "tiny_snap" created.
  LV        Attr       Origin Data% 
  tiny_snap swi-I-s--- lvdb   100.00
mount: /mnt/snap: can't read superblock on /dev/mapper/vgdata-tiny_snap.
       dmesg(1) may have more information after failed mount system call.
rc=32
```

The `I` in the attributes marks an invalid snapshot, and the kernel logged `Invalidating snapshot: Unable to allocate exception`. A snapshot is a short-term safety net for an upgrade or a consistent backup, not a backup itself: it lives on the same disks as the origin. An XFS snapshot needs `-o nouuid` to be mounted next to its origin.

---

## Moving Data Off a Disk

```bash
sudo pvs -o pv_name,pv_size,pv_free,pv_used
sudo pvmove /dev/loop1p3
sudo vgreduce vgdata /dev/loop1p3
sudo pvremove /dev/loop1p3
sudo pvs
```

Output:

```text
  PV           PSize   PFree   Used   
  /dev/loop1p3 820.00m 504.00m 316.00m
  /dev/loop2    <2.00g 520.00m  <1.49g
  /dev/loop3    <2.00g      0   <2.00g
  /dev/loop1p3: Moved: 5.06%
  /dev/loop1p3: Moved: 100.00%
  Removed "/dev/loop1p3" from volume group "vgdata"
  Labels on physical volume "/dev/loop1p3" successfully wiped.
  PV         VG     Fmt  Attr PSize  PFree  
  /dev/loop2 vgdata lvm2 a--  <2.00g 204.00m
  /dev/loop3 vgdata lvm2 a--  <2.00g      0 
```

`pvmove` copied the 316 MiB in use to free extents on `loop2` while the filesystems stayed mounted. This is how a failing or undersized disk is replaced without downtime.

---

## Thin Provisioning

```bash
sudo lvcreate --type thin-pool -L 150M -n tpool vgdata
sudo lvcreate -V 1G -T vgdata/tpool -n thin1
```

Output:

```text
# ... (trimmed)
  Logical volume "tpool" created.
  WARNING: Sum of all thin volume sizes (1.00 GiB) exceeds the size of thin pool vgdata/tpool and the amount of free space in volume group (44.00 MiB).
  WARNING: You have not turned on protection against thin pools running out of space.
  WARNING: Set activation/thin_pool_autoextend_threshold below 100 to trigger automatic extension of thin pools before they get full.
  Logical volume "thin1" created.
```

A thin volume takes pool space only as data is written, and thin snapshots need no size. When the pool fills, writes to every thin volume in it fail, so `Data%` and `Meta%` in `lvs` need monitoring or `thin_pool_autoextend_threshold` in `lvm.conf`.

---

## Common Errors

### `Insufficient free space: 512 extents needed, but only 258 available`

**Cause:** the volume group has fewer free extents than requested.

**Fix:** `sudo vgs` to see `VFree`; add a disk with `vgextend`, or request what exists with `-l +100%FREE`.

### `Cannot use /dev/loop0: device is partitioned`

**Cause:** the disk has a partition table, so LVM will not take the whole disk.

**Fix:** use a partition (`/dev/sdb1`), or remove the table with `sudo wipefs -a` if the disk is really unused.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Explain PV, VG, LV and PE."
    **Say first:** physical volumes are disks or partitions initialized for LVM, a volume group pools them into extents, and logical volumes are allocations of those extents used like partitions.

    **Proof:** `sudo pvs; sudo vgs; sudo lvs`; `vgdisplay` shows `PE Size`.

    **Follow-up:** How does LVM map an LV to disk blocks? (Through device-mapper tables: `sudo dmsetup table`.)

??? question "L1: Why use LVM instead of plain partitions?"
    **Say first:** volumes can grow across disks, move between disks online and be snapshotted, without repartitioning.

    **Proof:** `lvextend -r`, `pvmove`, `lvcreate -s`.

    **Follow-up:** What does LVM not protect against? (Disk failure, unless the LV uses RAID or mirroring.)
<!-- --8<-- [end:l1] -->

??? question "L2: /var is 95% full. Extend it by 5 GiB using a new disk /dev/sdc."
    **Say first:** add the disk to the volume group, then grow the LV and filesystem in one step.

    **Proof:** `sudo pvcreate /dev/sdc; sudo vgextend <vg> /dev/sdc; sudo lvextend -r -L +5G <vg>/var; df -h /var`.

    **Follow-up:** What changes if the VG already has 5 GiB free?

??? question "L2: Take a consistent backup of a database volume with a snapshot."
    **Say first:** freeze or flush the application, create a snapshot, release it, back up from the mounted snapshot, then remove the snapshot.

    **Proof:** `sudo lvcreate -s -L 2G -n db_snap <vg>/db; sudo mount -o ro /dev/<vg>/db_snap /mnt/snap; tar -czf ... ; sudo umount /mnt/snap; sudo lvremove -y <vg>/db_snap`.

    **Follow-up:** How do you size the snapshot, and what happens if it fills?

??? question "L3: lvextend succeeded, but df still shows the old size. Why?"
    **Say first:** the logical volume grew but the filesystem did not.

    **Proof:** `lsblk` shows the new LV size; `df -h` the old one; fix with `sudo xfs_growfs <mountpoint>` or `sudo resize2fs /dev/<vg>/<lv>`.

    **Follow-up:** Which flag avoids this?

??? question "L3: A disk with an existing volume group was attached to a RHEL 9 server, but vgs does not show it."
    **Say first:** LVM on RHEL 9 and later ignores devices that are not in the devices file.

    **Proof:** `sudo lvmdevices`; `sudo vgimportdevices -a` or `sudo lvmdevices --adddev /dev/sdc`; then `sudo vgs` and `sudo vgchange -ay <vg>`.

    **Follow-up:** What else is needed if the VG name clashes with an existing one? (`vgimportclone`.)

---

## Related

- [Partitioning](partitioning.md): LVM partition types
- [Filesystems](filesystems.md): why XFS cannot shrink
- [Resizing and Cloud Disks](resizing-and-cloud-disks.md): growing a PV after a cloud volume resize
- [Backup and Restore](backup-and-restore.md): snapshot-based backups

Captured on Rocky Linux 10.2 (LVM 2.03.36) and Ubuntu 24.04.4 LTS (LVM 2.03.16), iximiuz Labs microVMs, kernel 6.1.167, 2026-09.
