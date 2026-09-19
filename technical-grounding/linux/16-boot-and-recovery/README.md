# Boot and Recovery

How a Linux host goes from firmware to a running system, and how to recover when it does not: the boot chain, GRUB2, rescue and password reset, kernel panics, and kernel updates. The theme is localising a failure to one stage and fixing that stage.

---

## Revision Card

| Fact | Value |
|---|---|
| Boot chain | firmware → GRUB2 → kernel + initramfs → switch_root → systemd → target |
| Kernel args | `/proc/cmdline` shows what the running kernel got |
| grub.cfg | Generated; edit `/etc/default/grub`, then `grub2-mkconfig` / `update-grub` |
| Default target | `systemctl get-default`; set with `set-default` |
| Boot timing | `systemd-analyze`, `blame`, `critical-chain` |
| Rescue vs emergency | Rescue mounts local FS and prompts root; emergency is barer |
| Reset root password | GRUB `rd.break` → remount `/sysroot` rw → `passwd` → `.autorelabel` |
| Bad fstab | Boots to emergency; fix, then `mount -a` before reboot |
| Failed unit | `systemctl --failed`, `status`, `journalctl -b -u` |
| Oops vs panic | Oops logs and may continue; panic halts the kernel |
| Panic sysctls | `kernel.panic` (reboot delay), `kernel.panic_on_oops` |
| Magic SysRq | `R E I S U B` for a hung box, if enabled beforehand |
| Kernel patch | Installed is not active until reboot; check `uname -r` |
| Rollback | Boot the previous kernel from the GRUB menu |

| Task | Command |
|---|---|
| Kernel command line | `cat /proc/cmdline` |
| What made boot slow | `systemd-analyze critical-chain` |
| Boot without GUI | `sudo systemctl set-default multi-user.target` |
| Boot into rescue | append `systemd.unit=rescue.target` at GRUB |
| Reset root password | `rd.break`, then remount, chroot, `passwd`, `.autorelabel` |
| Validate fstab | `sudo mount -a` |
| List failed units | `systemctl --failed` |
| Panic auto-reboot | `kernel.panic=30` in `/etc/sysctl.d` |
| Reboot required | `needs-restarting -r` |
| Rebuild initramfs | `sudo dracut -f` / `sudo update-initramfs -u` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Boot Process](boot-process.md) | Firmware, GRUB2, kernel, initramfs, systemd targets, boot timing | Core | High |
| [GRUB2](grub2.md) | Generated config, kernel parameters, default kernel, menu password | RHCSA | Med |
| [Recovery](recovery.md) | Rescue and emergency, root password reset, bad fstab, failed units | RHCSA | Med |
| [Kernel Panic](kernel-panic.md) | Oops versus panic, triggers, SysRq, kdump and netconsole | Advanced | Med |
| [Kernel Updates](kernel-updates.md) | Installed versus running, rollback, initramfs, reboot check | Core | Low |

---

## Scenarios and Labs

- [Boot Failure](../interview/scenarios/boot-failure.md): bad fstab, broken GRUB, kernel panic
