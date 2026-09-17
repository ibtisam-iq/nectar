# RAID and Encryption

Linux software RAID (`mdadm`) combines disks for redundancy or speed, and LUKS (`cryptsetup`) encrypts a block device so its data is unreadable without a key. They stack with LVM and filesystems in any order the layout needs.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Levels | 0 striping, no redundancy; 1 mirror; 5 and 6 striping with one or two parity blocks | `mdadm --detail /dev/md0` |
| RAID 10 | Striped mirrors; common for databases | `mdadm --detail` |
| Status | `/proc/mdstat`: `[UU]` healthy, `[U_]` degraded | `cat /proc/mdstat` |
| Replace a disk | `--fail`, `--remove`, then `--add` the new one; rebuild runs online | `/proc/mdstat` |
| Persist the array | `mdadm --detail --scan` into `/etc/mdadm.conf` (Ubuntu: `/etc/mdadm/mdadm.conf`), then `dracut -f` (Ubuntu: `update-initramfs -u`) | `cat /proc/mdstat` after a reboot |
| LUKS2 | `cryptsetup luksFormat`, `open`, `close`; up to 32 keyslots (passphrases or key files) | `cryptsetup luksDump` |
| Open at boot | `/etc/crypttab`: name, device, key file or `none`, options; fstab then mounts `/dev/mapper/<name>` | `systemctl status systemd-cryptsetup@<name>` |
| Stratis and VDO | Removed from the RHCSA objectives; VDO now lives in LVM (`lvcreate --type vdo`) | `man lvmvdo` |
<!-- --8<-- [end:facts] -->

---

## A RAID 1 Array

Three 300 MiB loop devices (`loop6` to `loop8`) stand in for disks:

```bash
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 --bitmap=internal --run /dev/loop6 /dev/loop7
sudo mdadm /dev/md0 --fail /dev/loop7
grep -A2 md0 /proc/mdstat
sudo mdadm /dev/md0 --remove /dev/loop7
sudo mdadm /dev/md0 --add /dev/loop8
sleep 10; grep -A2 md0 /proc/mdstat
```

Output:

```text
mdadm: Note: this array has metadata at the start and
# ... (trimmed)
mdadm: array /dev/md0 started.
md0 : active raid1 loop7[1](F) loop6[0]
      306176 blocks super 1.2 [2/1] [U_]
      bitmap: 0/1 pages [0KB], 65536KB chunk
mdadm: hot removed /dev/loop7 from /dev/md0
mdadm: added /dev/loop8
md0 : active raid1 loop8[2] loop6[0]
      306176 blocks super 1.2 [2/2] [UU]
      bitmap: 0/1 pages [0KB], 65536KB chunk
```

`--run` skipped the confirmation prompts, which would otherwise ask about the write-intent bitmap and the metadata position. `(F)` marks the failed member, the rebuild onto `loop8` finished within the 10 seconds, and the kernel logged `md/raid1:md0: Disk failure on loop7, disabling device.` followed by `md: md0: recovery done.`

!!! warning "A degraded array keeps running silently"
    Nothing stops working when one mirror fails, so the failure goes unnoticed until the second disk dies. Set `MAILADDR` in the mdadm configuration and run `mdmonitor`, or alert on `[U_]` in `/proc/mdstat`.

---

## LUKS Encryption

A key file keeps the example non-interactive; without `--key-file`, `cryptsetup` asks for a passphrase:

```bash
sudo install -m 0400 /dev/null /root/secure.key && sudo dd if=/dev/urandom of=/root/secure.key bs=512 count=1 status=none
sudo cryptsetup luksFormat --batch-mode --type luks2 --key-file /root/secure.key /dev/md0
sudo cryptsetup open --key-file /root/secure.key /dev/md0 secure
sudo mkfs.ext4 -q /dev/mapper/secure
sudo mkdir -p /srv/secure && sudo mount /dev/mapper/secure /srv/secure
echo "card=4111-1111" | sudo tee /srv/secure/secret.txt >/dev/null; sync
sudo grep -c "card=4111" /dev/mapper/secure
sudo grep -c "card=4111" /dev/md0
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS /dev/loop6
```

Output:

```text
1
0
NAME        SIZE TYPE  FSTYPE            MOUNTPOINTS
loop6       300M loop  linux_raid_member 
└─md0       299M raid1 crypto_LUKS       
  └─secure  283M crypt ext4              /srv/secure
```

The text is found through the opened mapping and not on the RAID device beneath it. The LUKS2 header and keyslots took 16 MiB of the 299 MiB array, and `cryptsetup luksDump` shows the defaults: `aes-xts-plain64` with the `argon2id` key derivation.

At boot, the line `secure UUID=<LUKS UUID> /root/secure.key luks` in `/etc/crypttab` becomes `systemd-cryptsetup@secure.service`; mounting `/dev/md0` itself fails with `unknown filesystem type 'crypto_LUKS'`. With `none` instead of a key file, boot stops for the passphrase; `sudo cryptsetup luksAddKey` adds a second key, and `luksHeaderBackup` saves the header, without which the data is lost.

!!! danger "A lost LUKS key or damaged header cannot be recovered"
    There is no back door. Keep a header backup and a second keyslot in a safe place before storing data.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Compare RAID 0, 1, 5 and 10."
    **Say first:** 0 stripes for speed with no redundancy, 1 mirrors, 5 stripes with one parity block and survives one failure, 10 stripes across mirrors for speed and redundancy.

    **Proof:** `cat /proc/mdstat`; `sudo mdadm --detail /dev/md0`.

    **Follow-up:** Why is RAID not a backup?
<!-- --8<-- [end:l1] -->

??? question "L2: Replace a failed disk in a software RAID 1 array."
    **Say first:** mark it failed, remove it, add the replacement and watch the rebuild.

    **Proof:** `sudo mdadm /dev/md0 --fail /dev/sdb1 --remove /dev/sdb1; sudo mdadm /dev/md0 --add /dev/sdc1; watch cat /proc/mdstat`.

    **Follow-up:** What must be copied to the new disk first when it is also a boot disk? (The partition table and the boot loader.)

??? question "L2: Encrypt a new data disk and mount it at boot."
    **Say first:** format it with LUKS, open it, create a filesystem, and add crypttab and fstab lines.

    **Proof:** `sudo cryptsetup luksFormat /dev/sdb; sudo cryptsetup open /dev/sdb data; sudo mkfs.xfs /dev/mapper/data`; crypttab `data UUID=... none luks`; fstab `/dev/mapper/data /data xfs defaults 0 0`.

    **Follow-up:** How can a server open it without typing a passphrase? (A key file, TPM2 with `systemd-cryptenroll`, or Clevis and Tang.)

??? question "L3: /proc/mdstat shows [U_]. What do you do?"
    **Say first:** find the failed member, check the disk's health and logs, and replace it before the remaining disk fails.

    **Proof:** `sudo mdadm --detail /dev/md0`; `journalctl -k | grep md`; `sudo smartctl -H /dev/sdb`.

    **Follow-up:** Why can a rebuild trigger a second failure?

??? question "L2: Show which cipher and key derivation a LUKS volume uses."
    **Say first:** dump the LUKS header.

    **Proof:** `sudo cryptsetup luksDump /dev/sdb` shows `aes-xts-plain64` and `argon2id`.

    **Follow-up:** How do you add or remove a passphrase? (`luksAddKey`, `luksKillSlot`.)

??? question "L2: Check the health of every software RAID array in one command."
    **Say first:** read `/proc/mdstat`, or ask `mdadm` for a summary.

    **Proof:** `cat /proc/mdstat`; `sudo mdadm --detail --scan --verbose`.

    **Follow-up:** Which service sends the alerts? (`mdmonitor`.)

---

## Related

- [LVM](lvm.md): LVM on top of RAID or LUKS; [Disks and Devices](disks-and-devices.md): SMART health of members

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167, mdadm 4.4, cryptsetup 2.8.1), 2026-09.
