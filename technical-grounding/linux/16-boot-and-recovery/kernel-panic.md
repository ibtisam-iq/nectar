# Kernel Panic

A kernel panic is the kernel stopping because it cannot safely continue, unlike an oops, which logs an error and tries to carry on. Knowing the difference, and how to capture the evidence, is what turns a dead console into a root cause.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Oops | Kernel error in one context; logs and may continue | `dmesg`, `journalctl -k` |
| Panic | Kernel halts; nothing runs after | on-console message |
| Common panic | `Unable to mount root fs`, init died, hardware fault | `/proc/cmdline` `root=` |
| Oops to panic | An oops in an atomic context escalates to a panic | `kernel.panic_on_oops` |
| `kernel.panic` | Seconds to auto-reboot after panic; 0 means halt | `sysctl kernel.panic` |
| `kernel.panic_on_oops` | 1 makes any oops a panic (fail fast) | `sysctl kernel.panic_on_oops` |
| Magic SysRq | Kernel-level key combos for a hung system | `cat /proc/sys/kernel/sysrq` |
| SysRq bitmask | A number enables a subset of functions | `sysctl kernel.sysrq` |
| kdump | Boots a capture kernel to save a crash dump | `systemctl status kdump` |
| netconsole | Streams kernel messages over UDP to another host | `modinfo netconsole` |
| Tainted | Flag showing non-standard modules loaded | `cat /proc/sys/kernel/tainted` |
<!-- --8<-- [end:facts] -->

---

## Oops versus Panic

An oops is the kernel detecting an internal error, such as a bad pointer, in a context where it can kill the offending task and keep running, though the system may be unstable afterward. A panic is a stop: the kernel cannot continue safely, prints a message with a backtrace, and halts or reboots.

```bash
dmesg --level=err,crit,alert,emerg | tail
```

An oops leaves a backtrace in `dmesg` and the journal, so it can be read after the fact. A panic often leaves nothing on disk, because the kernel stopped before logs were flushed, which is why capturing it needs `kdump` or `netconsole`.

!!! note "An oops can escalate to a panic"
    If an oops happens while the kernel holds a lock or runs in interrupt context, it cannot safely recover and becomes a panic. Setting `kernel.panic_on_oops=1` forces every oops to panic, preferred where a corrupted kernel must fail fast rather than limp on.

---

## What Triggers a Panic

The most common panic is at boot: the kernel cannot mount the root filesystem, because the initramfs lacks a driver or `root=` is wrong. Others are the init process dying, a hardware machine-check error, or a watchdog timeout.

The message `Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)` means the kernel loaded but found no usable root device, a boot-time fault handled in [Boot Process](boot-process.md) and [Recovery](recovery.md). A panic well after boot points instead at a driver, hardware, or the init process exiting.

---

## Panic Behaviour Sysctls

Two parameters control what happens on a panic: whether to reboot automatically and after how long, and whether an oops should escalate. Servers usually set an auto-reboot delay so a crashed host returns to service.

```bash
sysctl kernel.panic kernel.panic_on_oops
cat /proc/sys/kernel/sysrq
```

Output:

```text
kernel.panic = 1
kernel.panic_on_oops = 0
16
```

Here `kernel.panic = 1` reboots one second after a panic, and `panic_on_oops = 0` lets an oops try to continue. A value of `0` for `kernel.panic` would halt and wait, useful when someone must read the on-screen backtrace before reboot.

!!! tip "Set an auto-reboot delay on unattended servers"
    A headless server with `kernel.panic=0` halts on a panic and stays down until someone visits the console. A small non-zero delay returns it to service while still allowing a monitored crash dump to be captured.

---

## Magic SysRq

Magic SysRq is a kernel-level command channel that works even when userspace is hung, because the kernel handles the keys directly. The `/proc/sys/kernel/sysrq` value is a bitmask enabling a subset of functions.

```bash
cat /proc/sys/kernel/sysrq            # 16 = enable sync only, 1 = all, 0 = off
echo 1 | sudo tee /proc/sys/kernel/sysrq   # enable all functions
# then, at the console: Alt+SysRq+<key>
```

The safe shutdown sequence for a hung machine is `R E I S U B` (unraw, terminate, kill, sync, remount read-only, reboot), pressed as `Alt+SysRq` plus each letter with a pause. Enabling SysRq before an incident is what makes a clean reboot possible when nothing else responds.

---

## Capturing a Crash

Because a panic stops before logs flush, capturing it needs a mechanism that runs at crash time. `kdump` reserves memory to boot a small capture kernel that saves a dump of the crashed kernel; `netconsole` streams kernel messages over the network as they happen.

```bash
systemctl status kdump                 # RHEL: preconfigured with crashkernel=
modprobe netconsole netconsole=@/,@<collector-ip>/   # stream to a listener
```

`kdump` needs `crashkernel=` reserved on the kernel command line, so it is set up before the crash, not after. The saved `vmcore` is then analysed with `crash` or `makedumpfile` to find the faulting function.

---

## Common Errors

### `Kernel panic - not syncing: VFS: Unable to mount root fs`

**Cause:** the kernel cannot mount the root device: a missing initramfs driver or a wrong `root=`.

**Fix:** boot a working kernel or rescue media, correct `root=`, and rebuild the initramfs.

### panic leaves nothing in the logs to diagnose

**Cause:** the kernel halted before the journal was written to disk, so on-disk logs stop before the crash.

**Fix:** configure `kdump` to save a `vmcore`, or `netconsole` to stream messages to another host, before the next crash.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a kernel oops and a kernel panic?"
    **Say first:** an oops is a recoverable kernel error that logs and may continue; a panic is an unrecoverable stop where the kernel halts.

    **Proof:** an oops leaves a backtrace in `dmesg`; a panic prints to the console and stops, often with nothing on disk.

    **Follow-up:** when does an oops become a panic? (in atomic or interrupt context, or with `panic_on_oops=1`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Make a server reboot automatically 30 seconds after a panic."
    **Say first:** set the panic timeout sysctl and persist it.

    **Proof:** `echo 'kernel.panic=30' | sudo tee /etc/sysctl.d/99-panic.conf && sudo sysctl --system`.

    **Follow-up:** when would you set it to 0 instead? (to halt and read the backtrace before rebooting.)

??? question "L2: A machine is hung with no SSH and no console response. What can still work?"
    **Say first:** Magic SysRq, because the kernel handles it directly, if it was enabled.

    **Proof:** `Alt+SysRq+R E I S U B` for a clean shutdown; enabled via `kernel.sysrq`.

    **Follow-up:** why enable SysRq in advance? (it must already be on; you cannot enable it on a hung box.)

??? question "L4: A panic leaves nothing in journalctl. How do you still capture the cause?"
    **Say first:** the kernel stops before logs flush, so capture must happen at crash time via `kdump` (a reserved capture kernel that dumps memory) or `netconsole` (streaming messages over the network).

    **Proof:** `kdump` needs `crashkernel=` reserved beforehand and saves a `vmcore`; `netconsole` sends `dmesg` to a listener as it happens.

    **Don't say:** that you can read the panic from `journalctl -b -1` afterward; the journal usually stops before the crash.

??? question "L4: Why does the kernel panic instead of killing only the faulting process?"
    **Say first:** if the error is in kernel context (holding a lock, in an interrupt, or unable to mount root), there is no safe process to kill and no consistent state to continue from, so it must stop.

    **Proof:** a userspace fault kills the process (SIGSEGV); a kernel fault in atomic context escalates to panic.

    **Don't say:** that a panic is the same as a segfault; a segfault is a userspace signal, a panic is the kernel halting.

??? question "L2: Enable Magic SysRq and confirm it is on."
    **Say first:** set the sysctl and read it back.

    **Proof:** `echo 1 | sudo tee /proc/sys/kernel/sysrq; cat /proc/sys/kernel/sysrq`.

    **Follow-up:** why must this be done before an incident? (a hung box cannot enable it.)

---

## Related

- [Boot Process](boot-process.md): the boot-time "cannot mount root" panic
- [Recovery](recovery.md): fixing a root device or fstab after a panic
- [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md): reading oops backtraces
- [Boot Failure](../interview/scenarios/boot-failure.md): panic as one branch of a failed boot
- [Round 4 Internals](../interview/round-4-internals.md): oops versus panic and kernel context

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The panic message is a documented example; a panic was not triggered on the shared host.
