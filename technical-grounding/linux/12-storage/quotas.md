# Quotas

Disk quotas cap the blocks and inodes a user, group or project may use on one filesystem. They stop one account or tenant from filling a shared volume.

**Track:** RHCSA · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Limits | Soft (may be exceeded for the grace period, 7 days by default) and hard (never exceeded) | `quota -s <user>` |
| XFS | Mount options `uquota`, `gquota`, `pquota` at mount time; managed with `xfs_quota -x` | `findmnt -no OPTIONS <dir>` |
| ext4 | `tune2fs -O quota -Q usrquota,grpquota` (unmounted), mount with `usrquota,grpquota` | `quotaon -p <dir>` |
| Set limits | `xfs_quota -x -c 'limit bsoft=50m bhard=60m <user>'`; `setquota -u <user> <bsoft> <bhard> <isoft> <ihard> <dir>`; `edquota -u <user>` opens an editor | `quota -s <user>` |
| Reports and grace | `xfs_quota -x -c 'report -h'`, `repquota -s <dir>`; grace with `xfs_quota -x -c 'timer ...'` or `setquota -t` | as root |
<!-- --8<-- [end:facts] -->

---

## XFS Quotas

XFS reads quota options only when the filesystem is mounted, so a remount ignores them without an error:

```bash
sudo mount -o remount,uquota /srv/web; echo "rc=$?"
findmnt -no OPTIONS /srv/web
sudo umount /srv/web
sudo mount -o uquota,gquota /dev/vgdata/lvweb /srv/web
findmnt -no OPTIONS /srv/web
sudo mkdir /srv/web/uploads && sudo chown laborant: /srv/web/uploads
sudo xfs_quota -x -c 'limit bsoft=50m bhard=60m isoft=900 ihard=1000 laborant' /srv/web
dd if=/dev/zero of=/srv/web/uploads/a.bin bs=1M count=80 status=none; echo "rc=$?"
sudo xfs_quota -x -c 'report -h -u' /srv/web
```

Output:

```text
rc=0
rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota
rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,usrquota,grpquota
dd: error writing '/srv/web/uploads/a.bin': Disk quota exceeded
rc=1
User quota on /srv/web (/dev/mapper/vgdata-lvweb)
                        Blocks              
User ID      Used   Soft   Hard Warn/Grace   
---------- --------------------------------- 
root            0      0      0  00 [------]
laborant      60M    50M    60M  00 [------]
```

The write stopped at the 60 MiB hard limit. The permanent form is `defaults,uquota,gquota` in the fstab line; for the root filesystem, `rootflags=uquota` goes on the kernel command line.

!!! warning "Quota options on an XFS remount are ignored"
    `mount -o remount,uquota` returns 0 and leaves `noquota` in place. Unmount and mount again, or reboot after editing fstab.

---

## ext4 Quotas

```bash
sudo umount /srv/db
sudo tune2fs -O quota -Q usrquota,grpquota /dev/vgdata/lvdb | tail -1
sudo mount -o usrquota,grpquota /dev/vgdata/lvdb /srv/db
sudo mkdir -p /srv/db/home && sudo chown laborant: /srv/db/home
sudo setquota -u laborant 20M 25M 0 0 /srv/db
dd if=/dev/zero of=/srv/db/home/b.bin bs=1M count=22 status=none; echo "rc=$?"
dd if=/dev/zero of=/srv/db/home/c.bin bs=1M count=10 status=none; echo "rc=$?"
sudo repquota -s /srv/db
```

Output:

```text
tune2fs 1.47.1 (20-May-2024)
rc=0
dd: error writing '/srv/db/home/c.bin': Disk quota exceeded
rc=1
*** Report for user quotas on device /dev/mapper/vgdata-lvdb
Block grace time: 7days; Inode grace time: 7days
                        Space limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root      --     24K      0K      0K              3     0     0       
laborant  +-  25600K  20480K  25600K  7days       3     0     0       
```

In `repquota`, `+-` means over the block soft limit and within the inode limits. The `quota` feature keeps usage in hidden inodes, so the old `quotacheck` and `aquota.user` files are not needed.

!!! note "Passing the soft limit starts the grace period"
    The first file passed the soft limit and succeeded, which started the 7-day grace period; the second hit the hard limit. After the grace time, the soft limit is enforced like a hard one.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a soft and a hard quota?"
    **Say first:** the hard limit is never exceeded; the soft limit may be exceeded for the grace period, after which it is enforced like a hard limit.

    **Proof:** `quota -s <user>` shows usage, both limits and the grace time.

    **Follow-up:** What error does a program get at the limit? (`EDQUOT`, `Disk quota exceeded`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Limit user dev to 500 MiB on the XFS volume /data."
    **Say first:** mount with `uquota`, then set the limit with `xfs_quota`.

    **Proof:** fstab `defaults,uquota`; `sudo umount /data; sudo mount /data`; `sudo xfs_quota -x -c 'limit bsoft=450m bhard=500m dev' /data`.

    **Follow-up:** Why did `mount -o remount,uquota` not work?

??? question "L2: Show every user's usage and limits on an ext4 filesystem."
    **Say first:** `repquota`.

    **Proof:** `sudo repquota -s /home`.

    **Follow-up:** How do you copy one user's limits to others? (`edquota -p <proto> <user>...`.)

??? question "L2: Limit a directory tree rather than a user on XFS."
    **Say first:** use a project quota: mount with `pquota`, assign the directory a project ID and set the limit on the project.

    **Proof:** `sudo xfs_quota -x -c 'project -s -p /data/app 42' -c 'limit -p bhard=1g 42' /data`.

    **Follow-up:** Which container runtimes use XFS project quotas? (Docker and CRI-O for per-container storage limits on `overlay2` over XFS.)

??? question "L3: A user gets Disk quota exceeded, but df shows plenty of space. What do you check?"
    **Say first:** the user's quota on that filesystem, including files owned in other directories and the grace time.

    **Proof:** `quota -s <user>`; `sudo find <mount> -xdev -user <user> -size +10M`.

    **Follow-up:** Which group quota could also cause it?

??? question "L2: Enable quotas on an existing ext4 volume."
    **Say first:** unmount, turn on the quota feature with `tune2fs`, and mount with the quota options.

    **Proof:** `sudo tune2fs -O quota -Q usrquota /dev/<dev>`; `usrquota` in fstab; `sudo quotaon -p <mount>`.

    **Follow-up:** What did older setups need instead? (`quotacheck -cug` and `quotaon`.)

---

## Related

- [Disk Usage](disk-usage.md): full filesystems and inodes; [Mounting and fstab](mounting-and-fstab.md): mount options

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167, quota 4.09), 2026-09.
