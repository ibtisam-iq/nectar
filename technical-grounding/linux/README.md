# Linux

Linux administration and internals for DevOps work, organised so one folder serves four uses: learning a topic in depth, revising before an interview, preparing for interview rounds, and day-to-day lookup. Commands are distro-neutral first; where RHEL and Ubuntu differ, both appear side by side.

---

## How the Folder Works

| Layer | Where | Use it for |
|---|---|---|
| **Learn** | Numbered modules below, one focused file per topic | Depth and daily lookup |
| **Revise** | Each module's Revision Card, and [Must-Know Facts](reference/must-know-facts.md) | The night before, or a one-hour sweep |
| **Interview** | Checkpoints at the end of every topic, and [Interview](interview/README.md) | Round-by-round preparation |
| **Practice** | [Labs](labs/README.md), and the [Roadmap](roadmap.md) tracker | Hands-on repetition and break-fix |

Every topic file declares a **Track** (Core, RHCSA, Advanced) and an **Interview weight** (High, Med, Low). High-weight topics go deep; Low-weight topics stay short. Command output on these pages was captured on real machines (Rocky Linux 10.2 and Ubuntu 24.04 LTS), never written by hand.

---

## Modules

| # | Module | Covers |
|---|---|---|
| 00 | [Foundations](00-foundations/README.md) | History, kernel vs distribution, distributions, architecture, system information |
| 01 | [Shell and CLI](01-shell-and-cli/README.md) | Shell basics, help, command lookup, environment, quoting, redirection, exit codes, editors, scripting essentials |
| 02 | [Files and Filesystem](02-files-and-filesystem/README.md) | Hierarchy, file types, file operations, inodes and links, file descriptors, finding files, archives |
| 03 | Text Processing | Viewing, `grep`, `sed`, `awk`, pipeline tools, `xargs`, JSON and YAML on the command line |
| 04 | [Users and Access](04-users-and-access/README.md) | Users, groups, passwords, `sudo` and `su`, PAM, login records, central identity |
| 05 | Permissions | Modes, `umask`, special bits, ACLs, attributes |
| 06 | Package Management | `rpm`/`dnf`, `dpkg`/`apt`, repositories, Flatpak, shared libraries |
| 07 | Processes | Lifecycle, states, signals, job control, priorities, system calls and tracing |
| 08 | Systemd and Services | Targets, `systemctl`, unit files, writing a service |
| 09 | Logging | Log locations, `journalctl`, `rsyslog`, `logrotate`, log parsing |
| 10 | Scheduling | `cron`, `at`, systemd timers |
| 11 | Kernel and Hardware | `/proc` and `/sys`, `sysctl`, modules, devices, kernel messages |
| 12 | Storage | Disks, partitions, filesystems, mounts, swap, LVM, resizing, usage, backup |
| 13 | Networking | Interfaces, configuration, routing, DNS, sockets, testing, capture, time |
| 14 | SSH and Remote Access | Client, tunnels, server, file transfer, troubleshooting |
| 15 | Security | Firewalls, SELinux, AppArmor, capabilities, auditing, GPG, TLS, hardening |
| 16 | Boot and Recovery | Boot sequence, GRUB, recovery, kernel panic, kernel updates |
| 17 | Performance and Troubleshooting | Method, CPU, memory, virtual memory, disk I/O, limits, profiling |
| 18 | Network Storage | NFS, autofs, Samba, iSCSI |
| 19 | Containers | Namespaces, cgroups, overlayfs, containers vs VMs, Podman |
| 20 | Virtualization and Provisioning | KVM and libvirt, VM images, cloud-init and Kickstart |

Modules without a link are planned and appear as they are completed.

---

## Out of Scope

- Desktop topics: X11 and Wayland configuration, accessibility, printing.
- Running mail, DNS, DHCP, web, directory and FTP servers (client-side use is covered).
- Kernel compilation.
- Git, Python, Ansible and full shell scripting, which have their own folders in this knowledge base.
