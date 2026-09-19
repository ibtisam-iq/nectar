# Storage and LVM Lab

Partition two practice disks, create filesystems and permanent mounts, build and resize LVM volumes, add swap, roll back a snapshot, grow a disk the way a cloud resize does, and find space held by a deleted file. Run it on a `rockylinux` playground; tasks that differ on Ubuntu say so.

---

## Setup

Install the tools and attach two 2 GiB sparse files as loop devices. The variables `D1` and `D2` hold the device names for the rest of the lab; set them again if the shell is restarted (`losetup -j /var/tmp/lab/lab1.img`).

```bash
sudo dnf install -y lvm2 xfsprogs parted cloud-utils-growpart psmisc lsof
mkdir -p /var/tmp/lab && cd /var/tmp/lab
truncate -s 2G lab1.img lab2.img
D1=$(sudo losetup -fP --show lab1.img); D2=$(sudo losetup -fP --show lab2.img)
echo "$D1 $D2"
```

On Ubuntu, install `lvm2 xfsprogs parted cloud-guest-utils psmisc lsof` with `apt-get`.

---

## Partitions and Filesystems

### 1. Partition the First Disk

Give `$D1` a GPT label with a 500 MiB partition named `data` and a partition using the rest of the disk, flagged for LVM. Show the result with sizes in MiB.

??? tip "Solution"
    ```bash
    sudo parted -s "$D1" mklabel gpt mkpart data 1MiB 501MiB mkpart pv 501MiB 100% set 2 lvm on
    sudo parted "$D1" unit MiB print
    lsblk "$D1"
    ```

    The partitions are `${D1}p1` and `${D1}p2`. If they do not appear, run `sudo partprobe "$D1"`.

### 2. Create a Filesystem and Mount It Permanently

Format partition 1 as XFS labelled `labdata` and mount it at `/lab/data` from `/etc/fstab` by UUID, so that a missing disk does not stop the boot. Prove the entry works without rebooting.

??? tip "Solution"
    ```bash
    sudo mkfs.xfs -L labdata "${D1}p1"
    sudo mkdir -p /lab/data
    echo "UUID=$(sudo blkid -s UUID -o value "${D1}p1") /lab/data xfs defaults,nofail 0 0" | sudo tee -a /etc/fstab
    sudo systemctl daemon-reload
    sudo findmnt --verify
    sudo mount -a
    findmnt /lab/data
    ```

    `findmnt --verify` must report no errors before `mount -a` is trusted; util-linux 2.40 also prints a warning for swap files listed in fstab (`non-bind mount source /swapfile is a directory or regular file`), which is harmless. `nofail` makes the unit wanted, not required, by `local-fs.target`.

### 3. Find Out Why the Filesystem Will Not Unmount

Start `sleep 600` with its working directory in `/lab/data`, try to unmount the filesystem, identify the blocking process with two different tools, stop it and unmount.

??? tip "Solution"
    ```bash
    (cd /lab/data && sleep 600) &
    sudo umount /lab/data          # target is busy
    sudo fuser -vm /lab/data
    sudo lsof +f -- /lab/data
    kill %1
    sudo umount /lab/data && sudo mount /lab/data
    ```

---

## LVM

### 4. Build a Volume Group and a Logical Volume

Create the volume group `labvg` from partition 2 of `$D1` and the whole disk `$D2`. Create a 1 GiB logical volume `app` with ext4, mounted at `/lab/app` through fstab.

??? tip "Solution"
    ```bash
    sudo pvcreate "${D1}p2" "$D2"
    sudo vgcreate labvg "${D1}p2" "$D2"
    sudo lvcreate -n app -L 1G labvg
    sudo mkfs.ext4 -q /dev/labvg/app
    sudo mkdir -p /lab/app
    echo '/dev/labvg/app /lab/app ext4 defaults 0 2' | sudo tee -a /etc/fstab
    sudo systemctl daemon-reload && sudo mount -a
    sudo pvs; sudo vgs; sudo lvs; df -h /lab/app
    ```

    A logical volume path such as `/dev/labvg/app` is stable, so it can stand in fstab instead of a UUID.

### 5. Grow and Shrink the Volume

Grow `app` by 500 MiB, filesystem included, while it is mounted. Then shrink it back to 1 GiB.

??? tip "Solution"
    ```bash
    sudo lvextend -r -L +500M labvg/app
    df -h /lab/app
    sudo lvreduce --yes -r -L 1G labvg/app
    df -h /lab/app
    ```

    `lvreduce -r` unmounts, checks, shrinks and remounts the ext4 filesystem. The same command on XFS fails, because XFS cannot shrink. LVM 2.03.16 on Ubuntu 24.04 asks before unmounting and accepts `-y` for the answer.

### 6. Add Swap from the Volume Group

Create a 256 MiB logical volume `swap`, use it as swap with priority 5, and make it permanent.

??? tip "Solution"
    ```bash
    sudo lvcreate -n swap -L 256M labvg
    sudo mkswap -L labswap /dev/labvg/swap
    echo '/dev/labvg/swap none swap defaults,pri=5 0 0' | sudo tee -a /etc/fstab
    sudo systemctl daemon-reload
    sudo swapon -a
    swapon --show
    ```

### 7. Roll Back a Change with a Snapshot

Write `v1` to `/lab/app/config.txt`, take a 100 MiB snapshot of `app`, overwrite the file with `v2`, and restore `v1` by merging the snapshot.

??? tip "Solution"
    ```bash
    echo v1 | sudo tee /lab/app/config.txt
    sudo lvcreate -s -n app_snap -L 100M labvg/app
    echo v2 | sudo tee /lab/app/config.txt
    sudo umount /lab/app
    sudo lvconvert --merge labvg/app_snap
    sudo mount /lab/app
    cat /lab/app/config.txt
    ```

    With the origin unmounted, the merge starts at once. `lvs` no longer lists `app_snap` afterwards.

### 8. Grow a Disk the Cloud Way

Pretend the volume behind `$D2` was enlarged from 2 GiB to 3 GiB. Make the kernel see the new size, then give all new space to `app` and its filesystem.

??? tip "Solution"
    ```bash
    truncate -s 3G /var/tmp/lab/lab2.img
    sudo losetup -c "$D2"
    lsblk "$D2"
    sudo pvresize "$D2"
    sudo lvextend -r -l +100%FREE labvg/app
    sudo vgs; df -h /lab/app
    ```

    `$D2` is a whole-disk PV, so `growpart` is not needed. With a partitioned PV, `sudo growpart <disk> <number>` comes before `pvresize`.

---

## Troubleshooting

### 9. Find Space That du Cannot See

Run a process that writes 200 MiB to `/lab/app/big.log` and keeps it open, delete the file, and show that `df` still counts it while `du` does not. Free the space without stopping the process.

??? tip "Solution"
    ```bash
    sudo chown "$USER" /lab/app
    python3 -c 'import time; f = open("/lab/app/big.log", "w"); f.write("x" * 200 * 1024 * 1024); f.flush(); time.sleep(600)' &
    sleep 3; rm /lab/app/big.log
    df -h /lab/app; sudo du -sh /lab/app
    sudo lsof -a +L1 /lab/app
    : > /proc/$!/fd/3
    df -h /lab/app
    kill $!
    ```

    The descriptor number comes from the `FD` column of `lsof` (`3w`).

---

## Cleanup

Remove the fstab lines before the volumes, so a later reboot does not wait for devices that no longer exist.

```bash
sudo swapoff /dev/labvg/swap
sudo umount /lab/app /lab/data
sudo sed -i '/labvg\|\/lab\/data/d' /etc/fstab
sudo systemctl daemon-reload
sudo vgremove -y labvg
sudo pvremove "${D1}p2" "$D2"
sudo losetup -d "$D1" "$D2"
rm -rf /var/tmp/lab; sudo rmdir /lab/app /lab/data /lab
```

---

## Related

- [Storage](../12-storage/README.md): the module this lab practises
- [Disk Full](../interview/scenarios/disk-full.md): the interview scenario for task 9
