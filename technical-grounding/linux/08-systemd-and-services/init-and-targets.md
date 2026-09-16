# Init and Targets

The init system is PID 1: the first user-space process, which starts every service and brings the machine to a defined state. On RHEL 7+ and Ubuntu 15.04+ that is systemd, and its targets replace the numbered runlevels of SysV init.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Init on RHEL and Ubuntu | systemd; `/sbin/init` is a symlink to it | `ls -l /sbin/init` |
| SysV init | Ran `/etc/rc.d/rcN.d` scripts one after another; replaced in RHEL 7 and Ubuntu 15.04 | `man systemd-sysv-generator` |
| Target | A unit that groups other units into a system state | `systemctl list-units --type=target` |
| Default target | `/etc/systemd/system/default.target` symlink | `systemctl get-default` |
| Server default | `multi-user.target` (runlevel 3); desktops use `graphical.target` (runlevel 5) | `systemctl get-default` |
| Change the default | `systemctl set-default multi-user.target` (takes effect at next boot) | `ls -l /etc/systemd/system/default.target` |
| Switch now | `systemctl isolate multi-user.target`; only units with `AllowIsolate=yes` | `systemctl show -p AllowIsolate <target>` |
| Rescue / emergency | `rescue.target` (local filesystems, root shell) / `emergency.target` (root filesystem only, no services) | `systemctl cat rescue.target` |
| Boot into a target once | Kernel parameter `systemd.unit=rescue.target` | `cat /proc/cmdline` |
| Current runlevel | `runlevel`, `who -r` (compatibility) | `runlevel` |
| Power commands | `poweroff`, `reboot`, `halt`, `shutdown` are symlinks to `systemctl` | `ls -l /usr/sbin/reboot` |
| Scheduled shutdown | `shutdown -r +30 "msg"`; `shutdown -c` cancels; `--show` lists it | `shutdown --show` |
| System health | `systemctl is-system-running`: `running`, `degraded` (a unit failed), `starting` | `systemctl --failed` |
| Boot time | `systemd-analyze` | `systemd-analyze blame` |
<!-- --8<-- [end:facts] -->

---

## Why systemd Replaced SysV Init

| | SysV init | systemd |
|---|---|---|
| **Service definition** | Shell scripts in `/etc/init.d` | Declarative unit files |
| **Start order** | Numbered links (`S10network`), sequential | Dependencies, parallel start |
| **Process tracking** | PID files | cgroups: every process of a service is known |
| **Restart on failure** | External tools | `Restart=` |
| **Logging** | Each daemon writes its own files | The journal captures stdout and stderr |
| **On-demand start** | `inetd` | Socket, path and timer units |

---

## PID 1

```bash
ps -p 1 -o pid,comm,args; ls -l /sbin/init
systemctl --version | head -1
```

Output:

```text
    PID COMMAND         COMMAND
      1 systemd         /sbin/init
lrwxrwxrwx 1 root root 22 Jun 10 00:00 /sbin/init -> ../lib/systemd/systemd
systemd 257 (257-23.el10_2.2.rocky.0.1-gb237c67)
```

Rocky Linux 10.2 ships systemd 257 and Ubuntu 24.04 ships systemd 255. If PID 1 exits, the kernel panics, so systemd catches crashes in itself and freezes instead of exiting.

---

## Targets and Runlevels

```bash
systemctl get-default; who -r; runlevel
ls -l /usr/lib/systemd/system/runlevel*.target
```

Output:

```text
graphical.target
         run-level 5  2026-09-16 18:54
N 5
lrwxrwxrwx 1 root root 15 Jun 10 00:00 /usr/lib/systemd/system/runlevel0.target -> poweroff.target
lrwxrwxrwx 1 root root 13 Jun 10 00:00 /usr/lib/systemd/system/runlevel1.target -> rescue.target
lrwxrwxrwx 1 root root 17 Jun 10 00:00 /usr/lib/systemd/system/runlevel2.target -> multi-user.target
lrwxrwxrwx 1 root root 17 Jun 10 00:00 /usr/lib/systemd/system/runlevel3.target -> multi-user.target
lrwxrwxrwx 1 root root 17 Jun 10 00:00 /usr/lib/systemd/system/runlevel4.target -> multi-user.target
lrwxrwxrwx 1 root root 17 Jun 10 00:00 /usr/lib/systemd/system/runlevel5.target -> graphical.target
lrwxrwxrwx 1 root root 13 Jun 10 00:00 /usr/lib/systemd/system/runlevel6.target -> reboot.target
```

`N 5` means no previous runlevel and current runlevel 5.

!!! note "graphical.target on a server without a GUI"
    Both playgrounds default to `graphical.target` although no display manager is installed. `graphical.target` pulls in `multi-user.target`, so the server behaves the same, and `set-default multi-user.target` makes the intent explicit.

| Runlevel | Target | State |
|---|---|---|
| 0 | `poweroff.target` | Shut down |
| 1 | `rescue.target` | Single user, local filesystems, root shell |
| 2, 3, 4 | `multi-user.target` | Networking and services, no GUI |
| 5 | `graphical.target` | Multi-user plus display manager |
| 6 | `reboot.target` | Reboot |
| none | `emergency.target` | Root filesystem only, no other mounts or services |

A target is a unit file like any other:

```bash
systemctl cat multi-user.target | grep -v "^#" | grep -v "^$"
systemctl list-dependencies graphical.target --no-pager | head -12
```

Output:

```text
[Unit]
Description=Multi-User System
Documentation=man:systemd.special(7)
Requires=basic.target
Conflicts=rescue.service rescue.target
After=basic.target rescue.service rescue.target
AllowIsolate=yes
graphical.target
○ ├─display-manager.service
● ├─rtkit-daemon.service
○ ├─systemd-update-utmp-runlevel.service
● └─multi-user.target
●   ├─code-server-proxy.socket
●   ├─crond.service
●   ├─examiner.service
○   ├─sysstat.service
●   ├─systemd-ask-password-wall.path
●   ├─systemd-logind.service
○   ├─systemd-update-utmp-runlevel.service
```

`●` marks active units and `○` inactive ones. Services join a target through `WantedBy=multi-user.target` in their `[Install]` section, which `systemctl enable` turns into a symlink in `multi-user.target.wants/`.

---

## Changing the Target

`set-default` changes the next boot; `isolate` switches now and stops every unit the new target does not need.

```bash
sudo systemctl set-default multi-user.target; systemctl get-default; ls -l /etc/systemd/system/default.target
systemctl show -p AllowIsolate multi-user.target sockets.target
```

Output:

```text
Created symlink '/etc/systemd/system/default.target' → '/usr/lib/systemd/system/multi-user.target'.
multi-user.target
lrwxrwxrwx 1 root root 41 Sep 16 19:10 /etc/systemd/system/default.target -> /usr/lib/systemd/system/multi-user.target
AllowIsolate=yes

AllowIsolate=no
```

```bash
sudo systemctl isolate multi-user.target     # stop the GUI now
sudo systemctl isolate rescue.target         # drop to single-user mode (closes SSH sessions)
sudo systemctl rescue                        # same, with a wall message
```

!!! danger "Isolating rescue.target over SSH disconnects the session"
    `rescue.target` stops networking and `sshd`. Use it from a console, or schedule the change in a maintenance window with out-of-band access.

Booting into a target once, without changing the default, uses the kernel command line: add `systemd.unit=rescue.target` (or `emergency.target`) in the GRUB editor. Module 16 (Boot and Recovery) uses the same method for password resets.

---

## Shutdown and Reboot

```bash
ls -l /usr/sbin/reboot /usr/sbin/poweroff /usr/sbin/halt /usr/sbin/shutdown
sudo shutdown -r +30 "kernel update"; sudo shutdown --show; sudo shutdown -c; sudo shutdown --show
```

Output:

```text
lrwxrwxrwx 1 root root 16 Jun 10 00:00 /usr/sbin/halt -> ../bin/systemctl
lrwxrwxrwx 1 root root 16 Jun 10 00:00 /usr/sbin/poweroff -> ../bin/systemctl
lrwxrwxrwx 1 root root 16 Jun 10 00:00 /usr/sbin/reboot -> ../bin/systemctl
lrwxrwxrwx 1 root root 16 Jun 10 00:00 /usr/sbin/shutdown -> ../bin/systemctl
Reboot scheduled for Wed 2026-09-16 19:40:28 UTC, use 'shutdown -c' to cancel.
Reboot scheduled for Wed 2026-09-16 19:40:28 UTC, use 'shutdown -c' to cancel.
No scheduled shutdown.
```

| Command | Effect |
|---|---|
| `systemctl poweroff` / `poweroff` | Stop services and power off |
| `systemctl reboot` / `reboot` | Stop services and reboot |
| `shutdown -h now` | Power off now |
| `shutdown -r 23:00` | Reboot at 23:00, with warnings to logged-in users |
| `shutdown -c` | Cancel a scheduled shutdown |
| `wall "message"` | Write a message to every terminal |
| `systemctl soft-reboot` | Restart user space only, keeping the kernel (systemd 254+) |

---

## System State

```bash
systemctl is-system-running
systemctl list-units --type=service --state=failed --no-legend
systemd-analyze
```

Output:

```text
degraded
● systemd-network-generator.service loaded failed failed Generate network units from Kernel command line
Startup finished in 880ms (kernel) + 1.211s (userspace) = 2.092s 
multi-user.target reached after 1.185s in userspace.
```

`degraded` means at least one unit failed; `systemctl --failed` names it. On this playground the failing unit parses a kernel command line the microVM does not provide, which is harmless.

---

## Common Errors

### `Failed to start sshd.service: Interactive authentication required.`

**Cause:** `systemctl start`, `stop` or `isolate` ran without root, and polkit found no agent to ask for a password.

**Fix:** use `sudo systemctl ...`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a runlevel and a systemd target?"
    **Say first:** a runlevel was a numbered SysV state; a target is a named systemd unit that groups other units, and several targets can be active at once.

    **Proof:** `ls -l /usr/lib/systemd/system/runlevel3.target` points to `multi-user.target`.

    **Follow-up:** Which target does a headless server use?

??? question "L1: Why did distributions replace SysV init with systemd?"
    **Say first:** parallel start from declared dependencies, reliable process tracking with cgroups, built-in restart and logging, and on-demand activation.

    **Proof:** `systemd-cgls -u <service>` lists every process of a service, including forked children.

    **Follow-up:** What does a PID file miss that a cgroup does not?
<!-- --8<-- [end:l1] -->

??? question "L2: Make a server boot to text mode by default, and switch to it now."
    **Say first:** set the default target and isolate it.

    **Proof:** `sudo systemctl set-default multi-user.target && sudo systemctl isolate multi-user.target`

    **Follow-up:** Why does `isolate` refuse `sockets.target`?

??? question "L2: Schedule a reboot in 30 minutes with a message, then cancel it."
    **Say first:** use `shutdown` with a relative time.

    **Proof:** `sudo shutdown -r +30 "kernel update"`, `shutdown --show`, `sudo shutdown -c`

    **Follow-up:** How do users on other terminals learn about it?

??? question "L2: Boot once into rescue mode without changing the default target."
    **Say first:** add `systemd.unit=rescue.target` to the kernel line in the GRUB menu.

    **Proof:** after boot, `cat /proc/cmdline` shows the parameter and `systemctl list-units --type=target` shows `rescue.target`.

    **Follow-up:** When do you need `emergency.target` instead?

??? question "L3: systemctl is-system-running reports degraded after a reboot."
    **Say first:** a unit failed during boot; find it, read its log and decide whether it matters.

    **Proof:** `systemctl --failed`, then `systemctl status <unit>` and `journalctl -b -u <unit>`; `systemctl reset-failed` after fixing.

    **Follow-up:** How do you check it in a monitoring script? (Exit status of `systemctl is-system-running`.)

---

## Related

- [systemctl](systemctl.md): managing units
- [Unit Files](unit-files.md): `WantedBy=` and dependencies
- [Process Fundamentals](../07-processes/process-fundamentals.md): PID 1 in the process tree

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
