# Kernel Updates

A kernel update installs a new kernel alongside the old one and rebuilds the initramfs, but the new kernel runs only after a reboot. Knowing the difference between the installed and the running kernel avoids the classic "I patched it but it is still vulnerable".

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Running kernel | The one booted now | `uname -r` |
| Installed kernels | Packages present, possibly newer than running | `rpm -q kernel` / `dpkg -l 'linux-image*'` |
| initramfs | Rebuilt per kernel on install | `dracut` / `update-initramfs` |
| `needs-restarting` | Reports whether a reboot is required (RHEL, `dnf-utils`) | `needs-restarting -r` |
| `/boot` full | Too many kernels fill a small `/boot`, breaking updates | `df -h /boot` |
| Livepatch | Applies some fixes without reboot | `kpatch` / Ubuntu Livepatch |
| Rollback | Boot the previous kernel from the GRUB menu | at the menu |
<!-- --8<-- [end:facts] -->

---

## Installed versus Running Kernel

`uname -r` shows the kernel running now, while the package tools show what is installed. After an update these differ until a reboot, which is why a security patch is not active the moment it installs.

```bash
uname -r
rpm -q kernel-tools          # or: dpkg -l 'linux-image*' | grep ^ii
```

Output:

```text
6.1.167
kernel-tools-6.12.0-211.55.1.el10_2.x86_64
```

Here the running kernel is 6.1.167 while a newer kernel package is present, so a reboot is required to run it. Treating "installed" as "active" is a common mistake in patch reporting.

!!! warning "A kernel patch is not live until reboot"
    Installing a new kernel changes the files in `/boot`, not the running kernel. Vulnerability scanners that read the package version may report fixed while the host still runs the old kernel; confirm with `uname -r` and reboot to activate.

---

## Multiple Kernels and Rollback

Both `dnf` and `apt` install a new kernel beside the current one and leave the previous entries in the GRUB menu, so a kernel that fails to boot can be rolled back by selecting the older entry. This is why the old kernel should not be removed immediately.

```bash
# RHEL: keep the last 2, remove older
dnf list --installed 'kernel-core*'
sudo dnf remove --oldinstallonly    # respects installonly_limit
```

The `installonly_limit` setting (default 3 on RHEL) caps how many kernels are kept. On Ubuntu, `apt autoremove` clears kernels no longer needed once a newer one is confirmed working.

!!! tip "Keep at least one known-good kernel for rollback"
    Removing every old kernel leaves no fallback if the new one fails to boot. Keep the previous working kernel until the new one has proven itself across a reboot.

---

## The initramfs and Reboot Check

Installing a kernel rebuilds its initramfs so it has the drivers to reach the root. After a storage or driver change on the current kernel, the initramfs is rebuilt manually.

```bash
sudo dracut -f                       # RHEL: rebuild current initramfs
sudo update-initramfs -u             # Ubuntu equivalent
needs-restarting -r                  # RHEL: is a reboot required?
```

Output:

```text
No core libraries or services have been updated since boot-up.
Reboot should not be necessary.
```

`needs-restarting -r` reports whether the running kernel or core libraries were replaced since boot. Livepatch (`kpatch` on RHEL, Livepatch on Ubuntu) applies selected fixes to the running kernel without reboot, but not every change qualifies.

---

## Common Errors

### `/boot` fills up and the next kernel update fails

**Cause:** old kernels and their initramfs images accumulated on a small `/boot` partition.

**Fix:** remove old kernels with `dnf remove --oldinstallonly` or `apt autoremove`, then re-run the update.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: You installed a kernel security update. Is the system protected yet?"
    **Say first:** not until it reboots into the new kernel; installing changes `/boot`, not the running kernel.

    **Proof:** `uname -r` still shows the old version; `needs-restarting -r` reports a reboot is required.

    **Follow-up:** what technology applies some fixes without a reboot? (livepatch / kpatch.)
??? question "L1: How do you tell which kernel is running versus which are installed?"
    **Say first:** `uname -r` shows the running kernel; the package tools list the installed ones, which can be newer.

    **Proof:** `uname -r` against `rpm -q kernel` or `dpkg -l 'linux-image*'`.

    **Follow-up:** why do they differ right after an update? (the new kernel runs only after reboot.)
<!-- --8<-- [end:l1] -->

??? question "L2: A new kernel fails to boot. How do you recover?"
    **Say first:** select the previous kernel from the GRUB menu, which the update left in place.

    **Proof:** boot the older entry; once up, investigate and set it as default with `grubby --set-default`.

    **Follow-up:** why not remove old kernels immediately after an update? (they are the rollback path.)

??? question "L2: A kernel update fails because /boot is full. Fix it."
    **Say first:** old kernels filled the partition; remove the surplus.

    **Proof:** `df -h /boot`; `sudo dnf remove --oldinstallonly` or `sudo apt autoremove`, then retry.

    **Follow-up:** how many kernels does RHEL keep by default? (`installonly_limit`, default 3.)

??? question "L3: A patched host still fails a kernel CVE scan. Why, and how do you confirm?"
    **Say first:** the fixed kernel is installed but the host has not rebooted, so the old kernel still runs.

    **Proof:** `uname -r` shows the old version; `needs-restarting -r` reports a reboot is required.

    **Follow-up:** how can some fixes apply without a reboot? (livepatch or kpatch, for eligible changes.)

??? question "L4: Why does Linux keep the old kernel installed after an update instead of replacing it?"
    **Say first:** the new kernel installs alongside the old so a kernel that fails to boot can be rolled back from the GRUB menu, which a replace-in-place scheme could not offer.

    **Proof:** `/boot` holds multiple kernels; the GRUB menu lists each; `installonly_limit` caps how many are kept.

    **Don't say:** that an update overwrites the running kernel's files.

---

## Related

- [Boot Process](boot-process.md): how the kernel and initramfs are loaded
- [GRUB2](grub2.md): choosing and rolling back kernels
- [rpm and dnf](../06-package-management/rpm-and-dnf.md): installing and removing kernel packages
- [Disk Usage](../12-storage/disk-usage.md): a full `/boot`

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The host uses direct kernel boot, so `dracut` and GRUB rollback steps run on a full VM.
