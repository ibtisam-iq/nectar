# RHCSA-Style Tasks

Timed, exam-shaped tasks drawn from the RHCSA objectives: no hints during the task, a worked solution behind each one. Do them on a fresh `rockylinux` playground or a RHEL 9 or 10 VM, set a 90-minute timer for a full pass, and check `findmnt --verify` and a reboot before trusting any storage change.

---

## How to Use These

Read the task, do it in a live shell, then open the solution to compare. The exam grades the end state after a reboot, not the commands typed, so every persistent task here is written to survive one. A solution is one correct path; the notes call out the mistakes that lose marks.

!!! warning "The exam reboots your machine before grading"
    A change that works now but is missing from `/etc/fstab`, a unit that is started but not enabled, or a `sysctl` set only at runtime all score zero after the reboot. Finish each storage task with `findmnt --verify` and `mount -a`, and each service task with `systemctl is-enabled`.

---

## Users, Groups and Permissions

### 1. Accounts and a Shared Directory

Create the group `contractors` and users `mary`, `alice` and `bob` in it. Give `bob` UID 1234 and a shell that cannot log in interactively. Create `/srv/project` owned by group `contractors`, group-writable, with new files inheriting the group, and readable by no one outside the group.

??? tip "Solution"
    ```bash
    sudo groupadd contractors
    sudo useradd -G contractors mary
    sudo useradd -G contractors alice
    sudo useradd -u 1234 -s /sbin/nologin -G contractors bob
    sudo install -d -g contractors -m 2770 /srv/project
    ls -ld /srv/project
    ```

    Mode `2770` sets the setgid bit (new files take the `contractors` group) and denies all access to others. `install -d` creates the directory with the mode and group in one step; `-s /sbin/nologin` blocks interactive login while leaving the account usable for a service.

### 2. ACL for One Extra User

On `/srv/project`, let the user `auditor` (not in the group) read and enter the directory and read new files, without adding `auditor` to `contractors`.

??? tip "Solution"
    ```bash
    sudo useradd auditor
    sudo setfacl -m u:auditor:rx /srv/project
    sudo setfacl -d -m u:auditor:r /srv/project
    getfacl /srv/project
    ```

    The first rule grants access to the directory itself; the default ACL (`-d`) applies to files created later. A `+` now shows in `ls -ld`.

---

## Text, Search and Archives

### 3. Find and Report

Find every file under `/etc` larger than 1 MB that was modified in the last 30 days, and save a long listing of them to `/root/bigfiles.txt`.

??? tip "Solution"
    ```bash
    sudo find /etc -type f -size +1M -mtime -30 -exec ls -lh {} + | sudo tee /root/bigfiles.txt
    ```

    `-size +1M` is over 1 MB, `-mtime -30` is within 30 days, and `-exec ... +` batches the matches into few `ls` calls. Using `+` instead of `\;` runs `ls` once per batch, not once per file.

### 4. Extract and Compress

Extract `/root/data.tar.gz` into `/opt/data`, then create `/root/etc-backup.tar.bz2` of `/etc` with bzip2 compression.

??? tip "Solution"
    ```bash
    sudo mkdir -p /opt/data
    sudo tar xzf /root/data.tar.gz -C /opt/data
    sudo tar cjf /root/etc-backup.tar.bz2 /etc
    ```

    `-C` sets the extraction directory. In `cjf`, `c` creates, `j` is bzip2, `f` names the file; `z` would be gzip and `J` would be xz.

---

## Scheduling and Time

### 5. A Recurring Job

Schedule `/usr/local/bin/report.sh` to run as `mary` every weekday at 14:30, and set the system timezone to `Asia/Karachi`.

??? tip "Solution"
    ```bash
    sudo timedatectl set-timezone Asia/Karachi
    echo '30 14 * * 1-5 /usr/local/bin/report.sh' | sudo tee /var/spool/cron/mary
    sudo chown mary:mary /var/spool/cron/mary
    sudo crontab -lu mary
    ```

    The five cron fields are minute, hour, day of month, month, day of week; `1-5` is Monday to Friday. Editing with `crontab -eu mary` sets the ownership automatically; writing the spool file by hand needs the `chown`.

---

## Storage: Partitions, Swap and LVM

### 6. A Partition Mounted at Boot

On a spare 2 GiB disk, create a 512 MiB partition, format it XFS, and mount it at `/data` by UUID so a missing disk does not break the boot.

??? tip "Solution"
    ```bash
    DISK=/dev/vdb              # confirm with lsblk before running
    sudo parted -s "$DISK" mklabel gpt mkpart data xfs 1MiB 513MiB
    sudo mkfs.xfs "${DISK}1"
    sudo mkdir -p /data
    echo "UUID=$(sudo blkid -s UUID -o value ${DISK}1) /data xfs defaults,nofail 0 0" | sudo tee -a /etc/fstab
    sudo systemctl daemon-reload && sudo mount -a && findmnt /data
    ```

    `nofail` lets the boot continue if the disk is absent. `daemon-reload` after editing fstab avoids the systemd warning that the mount units are stale.

### 7. Swap Sizing with PE Maths

Add a 500 MiB swap logical volume from a volume group with a 4 MiB physical extent size. State how many extents that is, create it, and enable it permanently.

??? tip "Solution"
    ```bash
    # 500 MiB / 4 MiB per extent = 125 extents
    sudo lvcreate -l 125 -n swaplv myvg
    sudo mkswap /dev/myvg/swaplv
    echo '/dev/myvg/swaplv none swap defaults 0 0' | sudo tee -a /etc/fstab
    sudo swapon -a && swapon --show
    ```

    `-l` counts extents; `-L 500M` would round to the nearest extent and reach the same size. The exam often specifies a size in extents, so knowing that size divided by PE size gives the extent count avoids a rounding mistake.

### 8. Grow a Logical Volume

Extend the logical volume `/dev/myvg/data` and its XFS filesystem by 300 MiB while it stays mounted.

??? tip "Solution"
    ```bash
    sudo lvextend -r -L +300M /dev/myvg/data
    df -h /data
    ```

    `-r` resizes the filesystem in the same step (`xfs_growfs` for XFS, `resize2fs` for ext4). XFS grows but never shrinks, so a shrink task means ext4 or a rebuild.

---

## Boot, Services and Network

### 9. Reset the Root Password

The root password is unknown. Reset it from the boot loader without external media.

??? tip "Solution"
    Layout:

    ```text
    1. At the GRUB menu, press e on the default entry.
    2. On the line starting linux, append: rd.break
    3. Ctrl-x to boot into the initramfs shell.
    4. mount -o remount,rw /sysroot
    5. chroot /sysroot
    6. passwd root
    7. touch /.autorelabel        # so SELinux relabels /etc/shadow
    8. exit; exit
    ```

    The `.autorelabel` step matters on RHEL: without it, `/etc/shadow` keeps the wrong SELinux label and login fails after the change. See [Recovery](../16-boot-and-recovery/recovery.md).

### 10. A Persistent Service and Open Port

Enable and start `httpd`, and open port 80 permanently in firewalld.

??? tip "Solution"
    ```bash
    sudo systemctl enable --now httpd
    sudo firewall-cmd --add-service=http --permanent
    sudo firewall-cmd --reload
    systemctl is-enabled httpd; sudo firewall-cmd --list-services
    ```

    `enable --now` both starts the service and marks it for boot. `--permanent` writes the firewall rule; without `--reload` it does not apply to the running firewall.

---

## Related

- [Users and Permissions Lab](users-and-permissions-lab.md): deeper practice on tasks 1 and 2
- [Storage and LVM Lab](storage-and-lvm-lab.md): deeper practice on tasks 6 to 8
- [Break-Fix Lab](break-fix-lab.md): the same skills applied to a broken system
- [Coverage Map](../reference/coverage-map.md): the RHCSA objectives these tasks map to
