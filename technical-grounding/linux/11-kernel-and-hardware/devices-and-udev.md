# Devices and udev

Every device the kernel knows has a node in `/dev`, identified by a major and minor number, and `systemd-udevd` names it, sets its permissions and creates stable symlinks. Custom udev rules give a disk a fixed name or let a non-root user access a device.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Type, major, minor | `b` block or `c` character; major selects the driver, minor the instance | `ls -l /dev/vda /dev/null`, `cat /proc/devices` |
| `/dev` | devtmpfs created by the kernel; udev adds permissions and symlinks | `mount -t devtmpfs` |
| Stable names | `/dev/disk/by-uuid`, `by-id`, `by-path`, `by-label` | `ls -l /dev/disk/by-uuid` |
| Device database | `udevadm info --name=<dev>` (properties), `--attribute-walk` (rule keys) | `udevadm info --name=/dev/vda` |
| Rules | `/usr/lib/udev/rules.d/` (vendor), `/etc/udev/rules.d/` (local, wins on same name) | `ls /etc/udev/rules.d` |
| Apply rules | `udevadm control --reload`, then `udevadm trigger` for existing devices | `ls -l /dev/<name>` |
| Hardware and events | `lspci -k`, `lsusb`, `udevadm monitor --udev`; `sensors` and `ipmitool` need physical hardware (`No sensors found!` in this VM) | `lspci -k` |
| Create a node by hand | `mknod <path> c <major> <minor>` | `sudo mknod /tmp/mynull c 1 3` |
<!-- --8<-- [end:facts] -->

---

## Device Nodes and Stable Names

```bash
ls -l /dev/vda /dev/null /dev/tty /dev/loop0
udevadm info --query=property --name=/dev/vda | grep -E "^(DEVNAME|DEVTYPE|ID_FS_TYPE|ID_FS_UUID|ID_PATH|SUBSYSTEM|MAJOR|MINOR)="
```

Output:

```text
brw-rw---- 1 root disk   7, 0 Sep 17 05:56 /dev/loop0
crw-rw-rw- 1 root root   1, 3 Sep 17 05:43 /dev/null
crw-rw-rw- 1 root tty    5, 0 Sep 17 05:43 /dev/tty
brw-rw---- 1 root disk 253, 0 Sep 17 05:43 /dev/vda
DEVNAME=/dev/vda
DEVTYPE=disk
MAJOR=253
MINOR=0
SUBSYSTEM=block
ID_PATH=pci-0000:00:01.0
ID_FS_UUID=0a80853f-1c24-4c13-8293-19cd53de6bbe
ID_FS_TYPE=ext4
```

The major and minor numbers, not the name, decide what a node does: a node made with `mknod /tmp/mynull c 1 3` discards writes like `/dev/null`.

!!! note "Kernel names are not stable"
    Names such as `sdb` depend on detection order and can change between boots, which is why `/etc/fstab` uses `UUID=` and udev creates `/dev/disk/by-*` links.

---

## Writing a Rule

`udevadm info --attribute-walk` prints the keys a rule can match. The rule below gives a loop device backed by a specific file a fixed name and an owner (a USB disk would match `ENV{ID_SERIAL}`); the link disappears with the device. `/dev/loop0` was already attached to `/var/tmp/udev.img`. As root:

```bash
cat /etc/udev/rules.d/90-backup-disk.rules
udevadm control --reload; udevadm trigger --action=change --sys-class=block --name=loop0 2>/dev/null || udevadm trigger --action=change /sys/block/loop0; udevadm settle; ls -l /dev/backupdisk /dev/loop0
losetup -d /dev/loop0; sleep 1; ls -l /dev/backupdisk
```

Output:

```text
SUBSYSTEM=="block", KERNEL=="loop*", ATTR{loop/backing_file}=="/var/tmp/udev.img", SYMLINK+="backupdisk", OWNER="laborant", MODE="0640"
lrwxrwxrwx 1 root     root    5 Sep 17 05:56 /dev/backupdisk -> loop0
brw-r----- 1 laborant disk 7, 0 Sep 17 05:56 /dev/loop0
ls: cannot access '/dev/backupdisk': No such file or directory
```

!!! warning "Match keys need == and assignments need = or +="
    A single `=` on a match key is an error; `udevadm verify` (systemd 254 and later) catches it before the rule is deployed:

    ```bash
    printf 'SUBSYSTEM=="block", KERNEL="loop*", SYMLINK+="backupdisk"\n' > /tmp/99-bad.rules; udevadm verify /tmp/99-bad.rules 2>&1; echo rc=$?
    ```

    Output:

    ```text
    /tmp/99-bad.rules:1 Invalid operator for KERNEL.
    /tmp/99-bad.rules: udev rules check failed.

    1 udev rules files have been checked.
      Success: 0
      Fail:    1
    rc=1
    ```

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What do the major and minor numbers of a device file mean?"
    **Say first:** The major number selects the driver and the minor number selects the device that driver handles.

    **Proof:** `ls -l /dev/null` shows `1, 3`; `grep -w 1 /proc/devices` shows `mem`.

    **Follow-up:** Why does `fstab` use UUIDs instead of `/dev/sdb1`?
<!-- --8<-- [end:l1] -->

??? question "L2: Give a disk a stable name that does not depend on detection order."
    **Say first:** Use an existing `/dev/disk/by-*` link, or a udev rule with `SYMLINK+=`.

    **Proof:** `ls -l /dev/disk/by-id/`; a rule matching `ENV{ID_SERIAL}`.

    **Follow-up:** Which vendor rule file creates the `by-id` links? (`60-persistent-storage.rules`.)

??? question "L2: Show what udev does when a device appears."
    **Say first:** Watch the event stream while attaching it.

    **Proof:** `udevadm monitor --udev --property`, then `losetup -f --show file.img`.

    **Follow-up:** Which command tests a rule against a device without applying it? (`udevadm test`.)

??? question "L2: Which kernel driver is bound to each PCI device?"
    **Say first:** `lspci -k`.

    **Proof:** `lspci -k` shows `Kernel driver in use: virtio-pci` for the disk and network controller.

    **Follow-up:** Where is the same information in sysfs? (`/sys/bus/pci/devices/*/driver`.)

??? question "L3: A device node has the wrong owner after every reboot although it was fixed with chown. Why?"
    **Say first:** `/dev` is recreated at boot and udev applies its rules, so manual changes do not persist.

    **Proof:** `udevadm info --name=<dev>` and `grep -r <name> /etc/udev/rules.d /usr/lib/udev/rules.d`.

    **Follow-up:** Write the `OWNER=` or `GROUP=` rule instead.

??? question "L2: Apply a new udev rule to a device that is already present."
    **Say first:** Reload the rules, then send the device a change event.

    **Proof:** `sudo udevadm control --reload`; `sudo udevadm trigger --action=change /sys/block/loop0`; `sudo udevadm settle`.

    **Follow-up:** How do you check a rule file for syntax errors first? (`udevadm verify`.)

---

## Related

- [proc and sys](proc-and-sys.md): `/sys/devices` and `/proc/devices`
- [File Types](../02-files-and-filesystem/file-types.md): block and character files

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
