# Foundations

What Linux is, how its layers fit together, and how to identify any machine before working on it.

---

## Revision Card

| Fact | Value |
|---|---|
| Linux | A kernel (Torvalds, 1991, GPL version 2); a distribution adds the userland |
| Layers | Hardware, kernel, system calls, C library, shell and applications |
| Kernel space vs user space | Privileged shared address space vs isolated unprivileged processes |
| System call | Only way into the kernel; failures return `-1` and an `errno` name |
| Kernel design | Monolithic with loadable modules |
| PID 1 and PID 2 | `systemd` (user space) and `kthreadd` (kernel threads) |
| Families | Red Hat (`rpm`, `dnf`) and Debian (`dpkg`, `apt`) |
| Rebuilds and upstream | Rocky and Alma rebuild RHEL; CentOS Stream is ahead of RHEL |
| Support | RHEL 10 years; Ubuntu LTS 5 years standard |
| Containers | Own userland, shared host kernel |
| Memory | Read `available`, not `free` |

| Task | Command |
|---|---|
| Distribution and version | `cat /etc/os-release` |
| Kernel release and build | `uname -r`, `cat /proc/version` |
| CPU, memory, disks | `lscpu`, `free -h`, `lsblk` |
| PCI devices and hardware tree | `lspci`, `sudo lshw -short` |
| Firmware data | `sudo dmidecode -t system` |
| VM or bare metal | `systemd-detect-virt` |
| Owning package of a file | `rpm -qf <file>`, `dpkg -S <file>` |
| Trace system calls | `strace -e trace=openat <command>` |
| Shared library dependencies | `ldd <binary>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [What Is Linux](what-is-linux.md) | History, GPL and copyleft, where Linux runs | Core | Low |
| [Kernel vs OS vs Distro](kernel-vs-os-vs-distro.md) | Kernel, userland, shell, distribution; GNU/Linux; backported versions | Core | Med |
| [Distributions](distributions.md) | Families, release models, architecture names | Core | Low |
| [Linux vs Windows](linux-vs-windows.md) | Security mechanisms, why servers run Linux | Core | Low |
| [Architecture](architecture.md) | Layers, kernel and user space, system calls, C library, kernel threads, monolithic design | Core | High |
| [System Information](system-information.md) | `os-release`, `uname`, `lscpu`, `free`, `lsblk`, `lspci`, `lshw`, `dmidecode`, uptime | Core | Med |

---

## Scenarios and Labs

- [Round 4: Internals](../interview/round-4-internals.md): what happens when a command runs
- [Error Messages](../reference/error-messages.md): errors from this module and their causes
