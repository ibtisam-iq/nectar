# Recovery

When a host will not boot or a change locks you out, recovery means booting into a minimal environment, fixing the cause, and returning to normal. The common cases are a lost root password, a bad `/etc/fstab`, and a failed unit that stalls boot.

**Track:** RHCSA · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Rescue target | Minimal system, root shell, local mounts | `systemctl rescue` |
| Emergency target | Bare minimum, read-only root, no mounts | `systemctl emergency` |
| Boot into a target | Append `systemd.unit=rescue.target` at GRUB | at the menu |
| Reset root password | Append `rd.break`, remount, `passwd`, relabel | RHEL method |
| SELinux relabel | `.autorelabel` or `load_policy -i` after a chroot edit | `touch /.autorelabel` |
| Bad fstab | A missing device without `nofail` drops boot to emergency | `journalctl -b` |
| Test fstab | Validate before reboot | `sudo mount -a` |
| Failed units | List what did not start | `systemctl --failed` |
| System state | `running`, `degraded` (a unit failed), `maintenance` | `systemctl is-system-running` |
| Read boot logs | The last boot's journal | `journalctl -b` |
| kdump | Captures a kernel crash dump for analysis | `systemctl status kdump` |
<!-- --8<-- [end:facts] -->

---

## Rescue and Emergency Targets

Rescue mode starts a minimal system with local filesystems mounted and a root shell, enough to fix most problems. Emergency mode goes further down, with a read-only root and almost nothing started, for when even rescue fails.

```bash
sudo systemctl rescue          # switch a running system to rescue
sudo systemctl emergency       # or the barer emergency mode
```

To boot straight into one, append `systemd.unit=rescue.target` to the kernel line at the GRUB menu. Rescue asks for the root password, so it is not a password-reset path; that needs `rd.break`.

!!! note "Rescue needs the root password; rd.break does not"
    Rescue and emergency targets prompt for root, so they assume you know the password. Resetting a lost password requires interrupting earlier, at the initramfs with `rd.break`, before the root password check applies.

---

## Resetting the Root Password

A lost root password is reset by breaking into the initramfs before the real root is fully handed over, remounting it writable, and running `passwd`. On SELinux systems the changed `/etc/shadow` must be relabelled or the next boot fails logins.

```bash
# At the GRUB menu, press e, append to the linux line:  rd.break
# then Ctrl-x to boot into the initramfs shell:
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel            # SELinux: relabel on next boot
exit
exit                            # continues boot
```

The `rd.break` switch stops in the initramfs with the real root mounted read-only at `/sysroot`. Skipping `.autorelabel` on an SELinux host leaves `/etc/shadow` with the wrong label, and the reset password will not work until relabelled.

---

## Fixing a Bad fstab

A wrong or missing device in `/etc/fstab` fails the mount, and without `nofail` systemd drops to emergency mode at boot. The fix is to boot into emergency, remount the root writable, correct the file, and validate with `mount -a` before rebooting.

```bash
# in emergency mode:
mount -o remount,rw /
vi /etc/fstab                  # fix or comment the bad line
mount -a                       # must succeed with no error
systemctl reboot
```

Running `mount -a` before rebooting is the safeguard: if it errors, the entry is still wrong, and rebooting would drop back to emergency. Adding `nofail` to non-critical mounts prevents one bad device from blocking all of boot.

!!! warning "Always run mount -a after editing fstab"
    A typo in `/etc/fstab` that mounts fine interactively can still fail at boot ordering, and a missing device without `nofail` halts boot entirely. `mount -a` catches the error while you can still fix it.

---

## Diagnosing a Failed Unit

When the system boots but reports `degraded`, at least one unit failed. `systemctl --failed` lists them, and the unit's status and journal show why.

```bash
systemctl is-system-running
systemctl list-units --state=failed --no-legend --plain
systemctl status systemd-network-generator.service
```

Output:

```text
degraded
systemd-network-generator.service loaded failed failed Generate network units from Kernel command line
× systemd-network-generator.service - Generate network units from Kernel command line
     Active: failed (Result: exit-code) since Thu 2026-09-17 22:54:34 UTC; 14min ago
   Main PID: 336 (code=exited, status=1/FAILURE)
```

The status names the failure (`code=exited, status=1/FAILURE`) and when it happened. `journalctl -b -u <unit>` shows the unit's own log lines from this boot, which usually carry the exact error.

---

## Common Errors

### `You are in emergency mode`

**Cause:** a filesystem in `/etc/fstab` failed to mount, so systemd could not reach the normal target.

**Fix:** log in as root, `mount -o remount,rw /`, fix the fstab line, run `mount -a`, then reboot.

### root password reset but login still fails on RHEL

**Cause:** `/etc/shadow` was edited in a `chroot` without relabelling, so SELinux blocks the file.

**Fix:** boot with `enforcing=0` once, or ensure `touch /.autorelabel` ran; relabel and reboot.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between rescue and emergency mode?"
    **Say first:** rescue starts a minimal system with local filesystems mounted and a root shell; emergency is barer, with a read-only root and almost nothing started.

    **Proof:** `systemctl rescue` versus `systemctl emergency`; boot with `systemd.unit=rescue.target`.

    **Follow-up:** why can neither reset a lost root password? (both prompt for it; use `rd.break`.)
<!-- --8<-- [end:l1] -->

??? question "L2: A server boots to emergency after an fstab edit. Recover it."
    **Say first:** remount root writable, fix the entry, and validate before rebooting.

    **Proof:**

    ```bash
    mount -o remount,rw /
    vi /etc/fstab
    mount -a        # must succeed
    ```

    **Follow-up:** how do you stop one bad mount from halting boot in future? (`nofail`.)

??? question "L2: A booted host reports degraded. Find the failed unit."
    **Say first:** list failed units and read the status and journal.

    **Proof:** `systemctl --failed`; `systemctl status UNIT`; `journalctl -b -u UNIT`.

    **Follow-up:** what does `degraded` mean overall? (up, but at least one unit failed.)

??? question "L3: You lost the root password on a RHEL box with SELinux enforcing. Walk through the reset."
    **Say first:** interrupt at the initramfs with `rd.break`, remount `/sysroot` writable, chroot, reset the password, and schedule a relabel.

    **Proof:** `rd.break` at GRUB, then `mount -o remount,rw /sysroot; chroot /sysroot; passwd; touch /.autorelabel`.

    **Follow-up:** what breaks if you skip `.autorelabel`? (the new `/etc/shadow` label is wrong and login still fails.)

??? question "L2: Boot a system straight into rescue mode from the GRUB menu."
    **Say first:** append the rescue target to the kernel line at the menu.

    **Proof:** press `e`, add `systemd.unit=rescue.target` to the `linux` line, boot with `Ctrl-x`.

    **Follow-up:** why does rescue still ask for the root password? (it assumes you know it; use `rd.break` to reset it.)

??? question "L4: Why must /etc/shadow be relabelled after resetting the password in a chroot on SELinux?"
    **Say first:** files created or edited in the initramfs chroot can get the wrong SELinux label, and an incorrectly labelled `/etc/shadow` makes login fail even with the right password.

    **Proof:** `touch /.autorelabel` schedules a relabel on next boot; without it, login is denied by policy.

    **Don't say:** that changing the password alone is enough on an enforcing SELinux system.

---

## Related

- [Boot Process](boot-process.md): the stages recovery interrupts
- [GRUB2](grub2.md): editing the boot line for `rd.break` and rescue
- [Mounting and fstab](../12-storage/mounting-and-fstab.md): `nofail` and validating with `mount -a`
- [SELinux](../15-security/selinux.md): why relabelling matters after a chroot edit
- [Boot Failure](../interview/scenarios/boot-failure.md): the boot-failure scenario

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The `rd.break` and emergency-mode steps run on a full VM; the failed-unit output is from the capture host.
