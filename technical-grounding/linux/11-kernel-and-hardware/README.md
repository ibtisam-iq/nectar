# Kernel and Hardware

How the kernel exposes its state in `/proc` and `/sys`, how its parameters, modules and devices are managed, and how to read the messages it logs when something breaks.

---

## Revision Card

| Fact | Value |
|---|---|
| `/proc` | Processes plus system files; generated on read, size 0 |
| `/sys` | Devices, drivers, modules; one value per file |
| `sudo echo v > /proc/...` | Fails: the redirection runs as the user; use `sudo tee` or `sysctl -w` |
| sysctl persistence | `/etc/sysctl.d/NN-name.conf`, applied by `systemd-sysctl` and `sysctl --system` |
| sysctl order | Files sorted by name; the last value read wins; `99-sysctl.conf` is `/etc/sysctl.conf` |
| Module keys | Exist only after the module loads (`net.bridge.*` needs `br_netfilter`) |
| `vm.max_map_count` | Rocky 10.2 and Ubuntu 24.04 already set 1048576; a copied 262144 lowers it |
| `modprobe` vs `insmod` | Name with dependencies vs file path without |
| Blacklist | Stops automatic loading only; `install <name> /bin/false` blocks it |
| Boot loading | `/etc/modules-load.d/`; options in `/etc/modprobe.d/` |
| Built-in driver | Not in `lsmod`; parameters on the kernel command line |
| Device numbers | Major selects the driver, minor the device |
| udev rules | `/etc/udev/rules.d/`; `==` matches, `=` and `+=` assign; `udevadm verify` |
| Segfault exit | 139; kernel line `segfault at <addr> ... error N` |
| OOM | `Memory cgroup out of memory` (limit) or `Out of memory` (host); exit 137 in containers |
| Hung task | `blocked for more than N seconds` after `hung_task_timeout_secs` (120) |

| Task | Command |
|---|---|
| Kernel command line | `cat /proc/cmdline` |
| Change a parameter now | `sudo sysctl -w net.ipv4.ip_forward=1` |
| Make it permanent | File in `/etc/sysctl.d/`, then `sudo sysctl --system` |
| Find a key | `sysctl -a --pattern keepalive` |
| Module details | `modinfo <name>`, `modinfo -p <name>` |
| Load and unload | `sudo modprobe <name>`, `sudo modprobe -r <name>` |
| Device properties | `udevadm info --name=/dev/vda` |
| Watch device events | `udevadm monitor --udev` |
| Kernel errors with times | `dmesg -T -l err,warn`, `journalctl -k -p warning` |
| Previous boot's kernel log | `journalctl -k -b -1` |
| Core dumps | `coredumpctl list`, `coredumpctl debug <prog>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [proc and sys](proc-and-sys.md) | Virtual filesystems, system files, sysfs devices, writing values | Core | High |
| [sysctl](sysctl.md) | Reading, writing, persistence, file order, module keys, common parameters | Core | High |
| [Kernel Modules](kernel-modules.md) | `lsmod`, `modinfo`, `modprobe`, built-in drivers, parameters, blacklists, boot loading | Core | Med |
| [Devices and udev](devices-and-udev.md) | Device nodes, stable names, rules, `udevadm` | Advanced | Low |
| [dmesg and Kernel Messages](dmesg-and-kernel-messages.md) | Ring buffer, segfaults and core dumps, OOM killer, I/O errors, hung tasks | Core | Med |

---

## Scenarios and Labs

- [Process Won't Die](../interview/scenarios/process-wont-die.md): hung tasks and `D` state seen from the kernel side
