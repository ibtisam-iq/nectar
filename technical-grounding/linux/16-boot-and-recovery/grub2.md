# GRUB2

GRUB2 is the bootloader that loads the kernel and initramfs and passes the kernel command line. Its configuration is generated, not hand-edited, so changing a setting means editing a source file and regenerating.

**Track:** RHCSA · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Config file | `grub.cfg` is generated; do not edit it directly | `head /boot/grub2/grub.cfg` |
| Source | `/etc/default/grub` plus scripts in `/etc/grub.d` | `cat /etc/default/grub` |
| Regenerate (RHEL) | `grub2-mkconfig -o` the active `grub.cfg` | after editing defaults |
| Regenerate (Ubuntu) | `update-grub` (wraps `grub2-mkconfig`) | after editing defaults |
| Persistent kernel args | `GRUB_CMDLINE_LINUX` in `/etc/default/grub` | `grep CMDLINE /etc/default/grub` |
| One-boot edit | Press `e` at the menu, edit the `linux` line, `Ctrl-x` | at the console |
| Active args | What the running kernel actually got | `cat /proc/cmdline` |
| Default entry | `GRUB_DEFAULT`, or `grub2-editenv list` for saved | `grub2-editenv list` |
| Change default | `grubby --set-default` (RHEL) | `grubby --default-kernel` |
| Menu password | `grub2-setpassword` protects editing entries | `/boot/grub2/user.cfg` |
| Timeout | `GRUB_TIMEOUT` seconds before the default boots | `/etc/default/grub` |
<!-- --8<-- [end:facts] -->

---

## grub.cfg Is Generated

The file GRUB reads at boot, `grub.cfg`, is assembled by a tool from `/etc/default/grub` and the scripts in `/etc/grub.d`. Editing `grub.cfg` directly is lost on the next kernel update, which regenerates it, so all changes go into the source and are regenerated.

=== "RHEL / Rocky"

    ```bash
    sudo vi /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg     # BIOS
    # UEFI path: /boot/efi/EFI/rocky/grub.cfg on some releases
    ```

=== "Ubuntu / Debian"

    ```bash
    sudo vi /etc/default/grub
    sudo update-grub                                # wraps grub2-mkconfig
    ```

!!! warning "Never edit grub.cfg directly"
    `grub.cfg` carries a header saying it is auto-generated. A kernel update runs `grub2-mkconfig` and overwrites it, so a hand edit disappears. Change `/etc/default/grub` or a file in `/etc/grub.d`, then regenerate.

---

## Kernel Parameters

Persistent kernel arguments live in `GRUB_CMDLINE_LINUX` in `/etc/default/grub`, and take effect after regenerating and rebooting. The running kernel's actual arguments are always readable at `/proc/cmdline`, which is the truth regardless of what the config says.

```bash
grep GRUB_CMDLINE_LINUX /etc/default/grub
cat /proc/cmdline
```

Output:

```text
console=ttyS0 reboot=k panic=1 systemd.random_seed=SEED net.ifnames=0 ip=172.16.1.3::172.16.1.1:255.255.255.0::eth0:off::: root=/dev/vda rw
```

To test a parameter for a single boot, press `e` at the GRUB menu, edit the line beginning `linux`, and boot with `Ctrl-x`; the change is not saved. This is how `systemd.unit=rescue.target` or `rd.break` is added for recovery, shown in [Recovery](recovery.md).

!!! note "The running command line is the source of truth"
    `/proc/cmdline` shows what the bootloader actually passed, which can differ from `/etc/default/grub` if the config was edited but not regenerated. Always confirm a parameter took effect by reading `/proc/cmdline` after reboot.

---

## The Default Kernel

After an update, several kernels are installed and GRUB boots the newest by default. `grubby` reports and changes the default without regenerating the whole config on RHEL.

```bash
sudo grubby --default-kernel
sudo grubby --info=ALL | grep -E '^kernel|^index'
sudo grubby --set-default /boot/vmlinuz-<version>
```

On Ubuntu the default follows `GRUB_DEFAULT` in `/etc/default/grub`, set to a menu index or `saved` with `grub-set-default`. Keeping the previous kernel installed is what lets a bad update be rolled back from the menu.

---

## A GRUB Menu Password

Anyone at the console can edit a boot entry to add `rd.break` and reset the root password, so a physically exposed machine locks GRUB editing with a password. `grub2-setpassword` sets it without storing a plaintext secret.

```bash
sudo grub2-setpassword          # prompts, writes /boot/grub2/user.cfg
```

This protects editing and choosing non-default entries, while still allowing the default to boot unattended. It does not encrypt the disk, so it is one layer, not full protection against physical access.

---

## Common Errors

### edits to `/etc/default/grub` have no effect after reboot

**Cause:** the config was changed but `grub.cfg` was not regenerated, so GRUB still reads the old generated file.

**Fix:** run `grub2-mkconfig -o /boot/grub2/grub.cfg` (RHEL) or `update-grub` (Ubuntu), then reboot; confirm with `/proc/cmdline`.

### `error: file '/vmlinuz-...' not found` at the GRUB prompt

**Cause:** the kernel file the menu entry references was removed, or `/boot` moved.

**Fix:** boot an older entry or rescue media, reinstall the kernel, and regenerate `grub.cfg`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Why should you not edit grub.cfg directly?"
    **Say first:** `grub.cfg` is generated from `/etc/default/grub` and `/etc/grub.d`, and a kernel update regenerates it, discarding hand edits.

    **Proof:** the file header marks it auto-generated; changes belong in the source, applied with `grub2-mkconfig` or `update-grub`.

    **Follow-up:** where do persistent kernel parameters go? (`GRUB_CMDLINE_LINUX`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Add a persistent kernel parameter and apply it."
    **Say first:** edit the command-line variable, regenerate, and reboot.

    **Proof:**

    ```bash
    sudo sed -i 's/GRUB_CMDLINE_LINUX="/&audit=1 /' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg   # or update-grub
    ```

    **Follow-up:** how do you test a parameter for one boot only? (edit the entry with `e` at the menu.)

??? question "L2: The system booted the wrong kernel after an update. Set the default."
    **Say first:** point the default at the intended kernel.

    **Proof:** `sudo grubby --set-default /boot/vmlinuz-<version>`; confirm with `grubby --default-kernel`.

    **Follow-up:** why keep the old kernel installed? (so a bad update can be rolled back from the menu.)

??? question "L3: Someone reset the root password from the GRUB menu. How do you prevent it?"
    **Say first:** anyone at the console can edit the boot line, so lock GRUB editing and control physical access.

    **Proof:** `grub2-setpassword` requires a password to edit entries; full protection needs disk encryption and a locked console.

    **Follow-up:** why is a GRUB password not enough on its own? (it does not encrypt the disk; media can be removed.)

??? question "L2: Show the kernel parameters the running system actually booted with."
    **Say first:** read them from the kernel, not the config, since the two can differ.

    **Proof:** `cat /proc/cmdline`; compare against `GRUB_CMDLINE_LINUX` in `/etc/default/grub`.

    **Follow-up:** why trust `/proc/cmdline` over the config file? (it is what the bootloader really passed.)

??? question "L4: How does GRUB find and load the kernel before any filesystem driver is running?"
    **Say first:** GRUB has its own filesystem drivers built into its modules, loaded by the firmware from the boot partition, so it can read `/boot` and load the kernel and initramfs before the kernel exists.

    **Proof:** the EFI system partition or boot sector holds GRUB; `grub.cfg` lists the kernel and initramfs paths it loads.

    **Don't say:** that the Linux kernel loads GRUB; it is the other way around.

---

## Related

- [Boot Process](boot-process.md): where GRUB sits in the boot chain
- [Recovery](recovery.md): editing the boot line for `rd.break` and rescue
- [Kernel Updates](kernel-updates.md): multiple kernels and rollback
- [Boot Failure](../interview/scenarios/boot-failure.md): a broken bootloader or entry

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The host uses direct kernel boot with no GRUB installed, so only `/proc/cmdline` is captured; GRUB commands run on a full VM or bare metal.
