# Boot Failure

A host does not come up after a reboot. The interviewer watches whether the candidate localises the failure to one boot stage from the last message on screen, then recovers that stage instead of reinstalling.

---

## Symptom

> "The server was rebooted for patching and never came back. The console shows it stopped during boot. Get it up."

---

## Clarifying Questions

- **Where on screen did it stop?** A GRUB prompt, a kernel panic, and an emergency shell each point at a different stage.
- **What changed before the reboot?** A kernel update, an fstab edit, or a storage change are the usual triggers.
- **Is there console or rescue access?** Recovery needs the console or boot media, not SSH, which is not up yet.
- **Did it work on the previous kernel?** If so, the new kernel or its initramfs is the suspect.

---

## Diagnostic Path

Boot is a chain (firmware, GRUB, kernel and initramfs, then systemd), so the last message localises the fault. Work from where it stopped, as in [Boot Process](../../16-boot-and-recovery/boot-process.md).

### 1. Localise by the Last Message

| Last thing seen | Stage | Points at |
|---|---|---|
| GRUB prompt or `file not found` | Bootloader | Missing kernel entry, broken `grub.cfg` |
| `Kernel panic ... unable to mount root fs` | Kernel / initramfs | Wrong `root=`, missing driver |
| `dracut` emergency shell | initramfs | Root device not found |
| `You are in emergency mode` | systemd | A failed mount in `/etc/fstab` |
| `degraded`, but logged in | systemd | A non-critical unit failed |

### 2. A Bad fstab Entry

The most common self-inflicted boot failure is a wrong `/etc/fstab` line. Systemd cannot mount it and drops to emergency mode. The same fault is reproducible with `mount -a`, which boot runs.

```bash
echo "UUID=00000000-dead-beef-0000-000000000000 /data xfs defaults 0 2" >> /etc/fstab
mount -a
```

Output:

```text
mount: /data: can't find UUID=00000000-dead-beef-0000-000000000000.
```

That error at boot halts startup and drops to emergency mode. In recovery, remount root writable, fix or comment the line, and validate before rebooting.

```bash
mount -o remount,rw /
vi /etc/fstab            # correct or remove the bad line
mount -a                 # must return with no error
```

### 3. Prevent One Mount From Halting Boot

A non-critical mount should carry `nofail`, so a missing device is skipped rather than failing the boot. The same entry with `nofail` no longer errors.

```bash
sed -i 's# defaults 0 2# nofail 0 2#' /etc/fstab
mount -a; echo "exit=$?"
```

Output:

```text
exit=0
```

With `nofail`, `mount -a` returns success even though the device is absent, so boot continues. Reserve default (fail-on-error) mounts for filesystems the system genuinely cannot run without.

### 4. A Failed Unit After Boot

If the host does boot but reports `degraded`, a unit failed without stopping boot. Identify it and read its log.

```bash
systemctl is-system-running
systemctl --failed
```

Output:

```text
degraded
systemd-network-generator.service loaded failed failed Generate network units from Kernel command line
```

`journalctl -b -u <unit>` then shows why it failed on this boot. A `degraded` state is a working system with a fault to fix, not a boot failure.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Bad fstab | Emergency mode; `mount -a` errors | Fix the line, `mount -a`, add `nofail` |
| Wrong `root=` or initramfs | Kernel panic, cannot mount root | Correct `root=`, rebuild initramfs, boot older kernel |
| Broken GRUB entry | GRUB `file not found` | Boot older entry, reinstall kernel, regenerate `grub.cfg` |
| Failed unit | `degraded`, `systemctl --failed` | Read the journal, fix the unit |
| New kernel bad | Worked on previous kernel | Roll back from the GRUB menu |

---

## Fix

For the captured fstab case, recover through emergency mode: remount root writable, correct the entry, and confirm `mount -a` succeeds before rebooting.

```bash
mount -o remount,rw /
vi /etc/fstab
mount -a && systemctl reboot
```

For a bad kernel, select the previous entry at the GRUB menu; the update left it in place for exactly this.

---

## Prevention

- Add `nofail` to non-critical mounts, and always run `mount -a` after editing `/etc/fstab`.
- Keep at least one known-good kernel installed for rollback.
- Test reboots on a canary before patching a fleet, and keep console or rescue access available.

---

## Related

- [Boot Process](../../16-boot-and-recovery/boot-process.md): the boot chain and where each fault sits
- [Recovery](../../16-boot-and-recovery/recovery.md): rescue mode, `rd.break`, fixing fstab
- [Kernel Panic](../../16-boot-and-recovery/kernel-panic.md): cannot mount root and other panics
- [Mounting and fstab](../../12-storage/mounting-and-fstab.md): `nofail` and validating mounts

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The bad fstab entry was added and removed for the capture; GRUB and emergency-mode steps run on a full VM.
