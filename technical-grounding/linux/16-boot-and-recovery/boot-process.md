# Boot Process

Boot is a handoff chain: firmware loads a bootloader, the bootloader loads the kernel and an initramfs, the kernel mounts the real root, and systemd brings the system to its target. Knowing each stage tells you which one failed when a host does not come up.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Firmware | UEFI (modern) or BIOS (legacy) starts the bootloader | `[ -d /sys/firmware/efi ] && echo UEFI` |
| Bootloader | GRUB2 on most distributions; loads kernel and initramfs | `/boot/grub2/grub.cfg` |
| Kernel args | Passed by the bootloader, seen at runtime | `cat /proc/cmdline` |
| initramfs | Temporary root with drivers to reach the real root | `lsinitrd` / `lsinitramfs` |
| switch_root | Pivot from initramfs to the real root filesystem | in `/proc/cmdline` `root=` |
| init | PID 1 is systemd; brings the system to a target | `ps -p 1 -o comm=` |
| Default target | The target booted by default | `systemctl get-default` |
| Boot timing | Kernel plus userspace startup time | `systemd-analyze` |
| Slowest units | Per-unit startup time | `systemd-analyze blame` |
| Critical path | The dependency chain that gated boot | `systemd-analyze critical-chain` |
| Secure Boot | Firmware verifies the bootloader and kernel signatures | `mokutil --sb-state` |
<!-- --8<-- [end:facts] -->

---

## The Boot Sequence

Each stage loads and hands control to the next, and a failure stops the chain at that point. Reading the sequence backward from where boot halts localises the fault.

```mermaid
flowchart LR
    FW[Firmware<br/>UEFI or BIOS] --> BL[Bootloader<br/>GRUB2]
    BL --> K[Kernel<br/>+ initramfs]
    K --> SR[switch_root<br/>to real root]
    SR --> SD[systemd<br/>PID 1]
    SD --> T[default target<br/>multi-user or graphical]
```

Firmware finds a boot device and runs the bootloader; the bootloader loads the kernel and initramfs; the kernel initialises hardware, mounts the initramfs, then pivots to the real root; systemd takes over as PID 1 and reaches the default target.

---

## Firmware and the Bootloader

UEFI firmware reads an EFI system partition and runs a signed bootloader, while legacy BIOS runs code from the disk's boot sector. GRUB2 is the common bootloader; it presents a menu, loads the chosen kernel and initramfs into memory, and passes the kernel command line.

```bash
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"
cat /proc/cmdline
```

Output:

```text
console=ttyS0 reboot=k panic=1 systemd.random_seed=SEED net.ifnames=0 ip=172.16.1.3::172.16.1.1:255.255.255.0::eth0:off::: root=/dev/vda rw
```

`/proc/cmdline` is exactly what the bootloader passed, including `root=/dev/vda` (the real root device) and kernel parameters. Editing this line at the GRUB menu is how recovery and single-user boots are triggered, covered in [Recovery](recovery.md).

!!! note "This capture host uses direct kernel boot, not GRUB"
    These microVMs load the kernel directly from the hypervisor, so `/proc/cmdline` is real but there is no GRUB menu or initramfs on disk. GRUB and initramfs commands on this page and in [GRUB2](grub2.md) are shown without captured output; they run on a full VM or bare metal.

---

## The Kernel and initramfs

The kernel cannot always reach the real root directly, because the root filesystem may live on LVM, RAID, an encrypted volume or a network device whose drivers are modules. The initramfs is a small temporary root, loaded into memory, that contains those drivers and the logic to find and mount the real root, then `switch_root` onto it.

```bash
# on a full VM: inspect what the initramfs contains
lsinitrd /boot/initramfs-$(uname -r).img | head        # RHEL family
lsinitramfs /boot/initrd.img-$(uname -r) | head        # Ubuntu family
```

A missing driver in the initramfs, or a wrong `root=`, gives the classic `Cannot open root device` or `dracut` emergency shell. Rebuilding the initramfs after a storage change is what prevents that, shown in [Kernel Updates](kernel-updates.md).

---

## systemd and Targets

Once the real root is mounted, the kernel starts PID 1, which is systemd. systemd activates units until it reaches the default target, usually `multi-user.target` (console) or `graphical.target` (with a display manager).

```bash
ps -p 1 -o comm=
systemctl get-default
```

Output:

```text
systemd
graphical.target
```

Targets replace the old SysV runlevels: `multi-user.target` is the server default (old runlevel 3), and `graphical.target` adds the GUI (runlevel 5). `systemctl set-default multi-user.target` changes what boots.

---

## Measuring Boot Time

`systemd-analyze` splits boot into kernel and userspace time, `blame` ranks the slowest units, and `critical-chain` shows the dependency path that actually gated startup. The critical chain matters more than `blame`, because a slow unit off the critical path does not delay boot.

```bash
systemd-analyze
systemd-analyze critical-chain
```

Output:

```text
Startup finished in 798ms (kernel) + 1.089s (userspace) = 1.888s
graphical.target reached after 1.064s in userspace.
graphical.target @1.064s
└─multi-user.target @1.063s
  └─nginx.service @1.001s +60ms
    └─network-online.target @999ms
      └─NetworkManager-wait-online.service @944ms +53ms
```

The chain shows `graphical.target` waited on `multi-user.target`, which waited on `nginx.service`, which waited on `network-online.target`. Here `NetworkManager-wait-online.service` is the long pole, a common cause of slow boots that block on the network.

!!! tip "Read the critical chain, not the blame list"
    `systemd-analyze blame` lists slow units, but many run in parallel and do not delay boot. `critical-chain` shows the serial dependency path, which is what to shorten to speed up boot.

---

## Common Errors

### `Cannot open root device "..." or unknown-block(0,0)`

**Cause:** the initramfs lacks the driver for the root device, or `root=` names the wrong device or UUID.

**Fix:** boot a working kernel or rescue media, correct `root=`, and rebuild the initramfs with the needed drivers.

### boot hangs at `A start job is running for ...`

**Cause:** a unit is waiting on a dependency that never becomes ready, often a network target or a missing mount.

**Fix:** check `systemctl list-jobs` and the unit's timeout; fix the dependency or the fstab entry (see [Recovery](recovery.md)).

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What are the stages of the Linux boot process, in order?"
    **Say first:** firmware, bootloader, kernel with initramfs, switch to the real root, then systemd reaching the default target.

    **Proof:** `/proc/cmdline` shows the bootloader's handoff; `systemd-analyze` shows kernel and userspace phases.

    **Follow-up:** which stage does `Cannot open root device` fail at? (initramfs or `root=`.)

??? question "L1: What is the initramfs for, if the kernel can already run?"
    **Say first:** it is a temporary in-memory root holding the drivers needed to reach the real root, such as LVM, RAID, encryption or network storage.

    **Proof:** `lsinitrd` lists its contents; `/proc/cmdline` `root=` names the real root it pivots to.

    **Follow-up:** when must you rebuild it? (after a storage or driver change; see kernel updates.)
<!-- --8<-- [end:l1] -->

??? question "L2: Find what made the last boot slow."
    **Say first:** read the critical chain rather than the blame list.

    **Proof:**

    ```bash
    systemd-analyze; systemd-analyze critical-chain
    ```

    **Follow-up:** why can a unit near the top of `blame` still not slow boot? (it runs in parallel, off the critical path.)

??? question "L2: Switch a server to boot without the graphical target."
    **Say first:** set the default target to multi-user.

    **Proof:** `sudo systemctl set-default multi-user.target`; confirm with `systemctl get-default`.

    **Follow-up:** how does this map to old runlevels? (multi-user is 3, graphical is 5.)

??? question "L3: A host does not finish booting and drops to a shell. How do you localise the failure?"
    **Say first:** identify which stage stopped, working from the last message: firmware, GRUB, kernel or systemd.

    **Proof:** a kernel panic before init points at the kernel or root device; an emergency shell with a systemd prompt points at a failed mount or unit; `journalctl -b` after recovery shows the failing unit.

    **Follow-up:** the shell is a `dracut` emergency prompt: what does that tell you? (failure is in the initramfs, before the real root mounted.)

??? question "L4: What does switch_root do, and why is it needed instead of mounting the root directly?"
    **Say first:** the kernel first mounts the initramfs as a temporary root to load drivers, then `switch_root` pivots onto the real root and frees the initramfs, because the real root may need modules the kernel does not carry built in.

    **Proof:** `/proc/cmdline` `root=` names the real device the initramfs mounts and switches to.

    **Don't say:** that the initramfs stays mounted after boot; it is discarded once the real root is live.

---

## Related

- [GRUB2](grub2.md): the bootloader menu, kernel parameters and passwords
- [Recovery](recovery.md): rescue mode, root password reset, fixing a bad fstab
- [Kernel Panic](kernel-panic.md): oops versus panic and what stops the kernel
- [init and Targets](../08-systemd-and-services/init-and-targets.md): targets and runlevels
- [Boot Failure](../interview/scenarios/boot-failure.md): the boot-failure scenario

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The host uses direct kernel boot, so GRUB and initramfs commands are shown without captured output.
