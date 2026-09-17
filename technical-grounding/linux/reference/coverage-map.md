# Coverage Map

Certification objectives mapped to the topic file that covers them. The map proves the folder's completeness and doubles as a study index for RHCSA, LFCS, LPIC-1 and Linux+. Objectives are paraphrased; rows are added as each module is written.

---

## Foundations

| Curriculum | Objective | Covered in |
|---|---|---|
| LPIC-1 101.1 | Determine and configure hardware settings (`lspci`, `lsusb`, `/proc`, `/sys`) | [System Information](../00-foundations/system-information.md), [Architecture](../00-foundations/architecture.md) |
| Linux+ XK0-006 | Linux fundamentals: distributions, kernel and userland, licensing | [What Is Linux](../00-foundations/what-is-linux.md), [Kernel vs OS vs Distro](../00-foundations/kernel-vs-os-vs-distro.md), [Distributions](../00-foundations/distributions.md) |
| Linux+ XK0-006 | Gather hardware and system information | [System Information](../00-foundations/system-information.md) |
| Interview sources | Kernel space vs user space, system calls, why servers run Linux | [Architecture](../00-foundations/architecture.md), [Linux vs Windows](../00-foundations/linux-vs-windows.md) |

---

## Shell and CLI

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Access a shell prompt and issue commands with correct syntax | [Shell Basics](../01-shell-and-cli/shell-basics.md), [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| RHCSA EX200 (RHEL 10) | Use input-output redirection | [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md) |
| RHCSA EX200 (RHEL 10) | Create and edit text files | [Text Editors](../01-shell-and-cli/text-editors.md) |
| RHCSA EX200 (RHEL 10) | Locate, read and use system documentation (`man`, `info`, `/usr/share/doc`) | [Getting Help](../01-shell-and-cli/getting-help.md) |
| RHCSA EX200 (RHEL 10) | Create simple shell scripts: conditionals, loops, script arguments, command output | [Scripting Essentials](../01-shell-and-cli/scripting-essentials.md), [Exit Codes and Chaining](../01-shell-and-cli/exit-codes-and-chaining.md) |
| LFCS | Use input and output redirection; write scripts to automate tasks | [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md), [Scripting Essentials](../01-shell-and-cli/scripting-essentials.md) |
| LPIC-1 103.1 | Work on the command line (quoting, history, environment, `type`, `which`) | [Shell Basics](../01-shell-and-cli/shell-basics.md), [Quoting and Expansion](../01-shell-and-cli/quoting-and-expansion.md), [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| LPIC-1 103.4 | Use streams, pipes and redirects (`tee`, `xargs`) | [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md) |
| LPIC-1 103.8 | Basic file editing (`vi`, `EDITOR`) | [Text Editors](../01-shell-and-cli/text-editors.md) |
| LPIC-1 105.1 | Customize and use the shell environment (profiles, `env`, `export`, aliases, functions) | [Variables and Environment](../01-shell-and-cli/variables-and-environment.md), [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| LPIC-1 105.2 | Customize or write simple scripts (`test`, loops, exit status) | [Scripting Essentials](../01-shell-and-cli/scripting-essentials.md), [Exit Codes and Chaining](../01-shell-and-cli/exit-codes-and-chaining.md) |
| LPIC-1 107.3 | Localisation and internationalisation (`locale`, `LANG`, `LC_ALL`, `iconv`) | [Locale and Encoding](../01-shell-and-cli/locale-and-encoding.md) |
| Linux+ XK0-006 | Shell scripting basics and environment variables | [Scripting Essentials](../01-shell-and-cli/scripting-essentials.md), [Variables and Environment](../01-shell-and-cli/variables-and-environment.md) |

---

## Files and Filesystem

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Archive, compress, unpack and uncompress files using `tar`, `gzip` and `bzip2` | [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |
| RHCSA EX200 (RHEL 10) | Create, delete, copy and move files and directories | [File Operations](../02-files-and-filesystem/file-operations.md) |
| RHCSA EX200 (RHEL 10) | Create hard and soft links | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| LFCS | Create, delete, copy and move files; manage links; archive and compress; search for files | [File Operations](../02-files-and-filesystem/file-operations.md), [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md), [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md), [Finding Files](../02-files-and-filesystem/finding-files.md) |
| LPIC-1 103.3 | Perform basic file management (`cp`, `mv`, `rm`, `find`, `tar`, `cpio`, `dd`, globbing) | [File Operations](../02-files-and-filesystem/file-operations.md), [Finding Files](../02-files-and-filesystem/finding-files.md), [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |
| LPIC-1 104.6 | Create and change hard and symbolic links | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| LPIC-1 104.7 | Find system files and place files in the correct location (FHS, `find`, `locate`, `whereis`, `type`) | [Filesystem Hierarchy](../02-files-and-filesystem/filesystem-hierarchy.md), [Finding Files](../02-files-and-filesystem/finding-files.md) |
| Linux+ XK0-006 | Filesystem hierarchy, file types, links, compression and archiving | [Filesystem Hierarchy](../02-files-and-filesystem/filesystem-hierarchy.md), [File Types](../02-files-and-filesystem/file-types.md), [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md), [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |
| Interview sources | File descriptors, deleted-but-open files, inode exhaustion | [File Descriptors](../02-files-and-filesystem/file-descriptors.md), [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |

---

## Text Processing

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Use `grep` and regular expressions to analyze text | [grep and Regex](../03-text-processing/grep-and-regex.md) |
| LFCS | Search and manipulate text with filters and regular expressions | [grep and Regex](../03-text-processing/grep-and-regex.md), [sed](../03-text-processing/sed.md), [awk](../03-text-processing/awk.md) |
| LPIC-1 103.2 | Process text streams using filters (`cut`, `sort`, `uniq`, `tr`, `paste`, `join`, `sed`, `head`, `tail`, `wc`, checksums) | [Cut, Sort, Uniq and Tr](../03-text-processing/cut-sort-uniq-tr.md), [Viewing and Comparing](../03-text-processing/viewing-and-comparing.md), [sed](../03-text-processing/sed.md) |
| LPIC-1 103.4 | Use streams, pipes and redirects (`xargs`, `tee`) | [xargs and tee](../03-text-processing/xargs-and-tee.md) |
| LPIC-1 103.7 | Search text files using regular expressions | [grep and Regex](../03-text-processing/grep-and-regex.md) |
| Linux+ XK0-006 | Text manipulation and structured data (`awk`, `sed`, `jq`, YAML) | [awk](../03-text-processing/awk.md), [JSON and YAML on the CLI](../03-text-processing/json-and-yaml-on-cli.md) |
| Interview sources | Log parsing one-liners: top IPs, status counts, time windows | [awk](../03-text-processing/awk.md), [Cut, Sort, Uniq and Tr](../03-text-processing/cut-sort-uniq-tr.md) |

---

## Users and Access

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Create, delete and modify local user accounts | [Users](../04-users-and-access/users.md) |
| RHCSA EX200 (RHEL 10) | Change passwords and adjust password aging for local accounts | [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| RHCSA EX200 (RHEL 10) | Create, delete and modify local groups and memberships | [Groups](../04-users-and-access/groups.md) |
| RHCSA EX200 (RHEL 10) | Configure privileged access | [Sudo and Su](../04-users-and-access/sudo-and-su.md) |
| RHCSA EX200 (RHEL 10) | Log in and switch users in multi-user targets | [Sudo and Su](../04-users-and-access/sudo-and-su.md) |
| LFCS | Create and manage local user and group accounts | [Users](../04-users-and-access/users.md), [Groups](../04-users-and-access/groups.md) |
| LFCS | Manage user accounts in LDAP | [Centralized Identity](../04-users-and-access/centralized-identity.md) |
| LPIC-1 107.1 | Manage user and group accounts and related system files | [Users](../04-users-and-access/users.md), [Groups](../04-users-and-access/groups.md), [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| LPIC-1 110.1 | Security administration: `sudo`, `su`, `chage`, `who`, `w`, `last` | [Sudo and Su](../04-users-and-access/sudo-and-su.md), [Login Sessions](../04-users-and-access/login-sessions.md) |
| Linux+ XK0-006 2.2 | Manage local accounts: `useradd`, `usermod`, `chage`, `/etc/skel`, UID and GID, service accounts | [Users](../04-users-and-access/users.md), [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| Linux+ XK0-006 3.1 | Authentication, authorization and accounting: PAM, SSSD, LDAP, Kerberos, polkit | [PAM](../04-users-and-access/pam.md), [Centralized Identity](../04-users-and-access/centralized-identity.md), [Sudo and Su](../04-users-and-access/sudo-and-su.md) |
| Linux+ XK0-006 3.4 | Account hardening: password quality, history, lockout, `nologin` | [PAM](../04-users-and-access/pam.md), [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |

---

## Permissions

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | List, set and change standard `ugo`/`rwx` permissions | [Basic Permissions](../05-permissions/basic-permissions.md) |
| RHCSA EX200 (RHEL 10) | Create and configure set-GID directories for collaboration | [Special Permissions](../05-permissions/special-permissions.md) |
| RHCSA EX200 (RHEL 10) | Diagnose and correct file permission problems | [Basic Permissions](../05-permissions/basic-permissions.md), [ACL](../05-permissions/acl.md), [File Attributes](../05-permissions/file-attributes.md) |
| LFCS | Manage file permissions, ownership and ACLs | [Basic Permissions](../05-permissions/basic-permissions.md), [ACL](../05-permissions/acl.md) |
| LPIC-1 104.5 | Manage file permissions and ownership (SUID, SGID, sticky, `umask`) | [Basic Permissions](../05-permissions/basic-permissions.md), [Special Permissions](../05-permissions/special-permissions.md), [umask](../05-permissions/umask.md) |
| Linux+ XK0-006 | File permissions, special bits, ACLs and attributes | [Special Permissions](../05-permissions/special-permissions.md), [ACL](../05-permissions/acl.md), [File Attributes](../05-permissions/file-attributes.md) |

---

## Package Management

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Install and update software packages from repositories and local files | [rpm and dnf](../06-package-management/rpm-and-dnf.md) |
| RHCSA EX200 (RHEL 10) | Configure access to RPM repositories | [Repositories](../06-package-management/repositories.md) |
| RHCSA EX200 (RHEL 10) | Install and update software using Flatpak | [Flatpak and Snap](../06-package-management/flatpak-and-snap.md) |
| LFCS | Manage software packages and repositories | [rpm and dnf](../06-package-management/rpm-and-dnf.md), [dpkg and apt](../06-package-management/dpkg-and-apt.md), [Repositories](../06-package-management/repositories.md) |
| LPIC-1 102.3 | Manage shared libraries | [Shared Libraries](../06-package-management/shared-libraries.md) |
| LPIC-1 102.4 | Use Debian package management | [dpkg and apt](../06-package-management/dpkg-and-apt.md) |
| LPIC-1 102.5 | Use RPM and YUM package management | [rpm and dnf](../06-package-management/rpm-and-dnf.md), [Packaging Concepts](../06-package-management/packaging-concepts.md) |
| Linux+ XK0-006 | Package management, repositories, sandboxed applications and building from source | [Packaging Concepts](../06-package-management/packaging-concepts.md), [Flatpak and Snap](../06-package-management/flatpak-and-snap.md), [Other Install Methods](../06-package-management/other-install-methods.md) |

---

## Processes

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Identify CPU and memory intensive processes and kill processes | [Viewing Processes](../07-processes/viewing-processes.md), [Signals](../07-processes/signals.md) |
| RHCSA EX200 (RHEL 10) | Adjust process scheduling | [Priority and Nice](../07-processes/priority-and-nice.md) |
| LFCS | Monitor, tune and troubleshoot processes | [Viewing Processes](../07-processes/viewing-processes.md), [Process States](../07-processes/process-states.md), [System Calls and Tracing](../07-processes/system-calls-and-tracing.md) |
| LPIC-1 103.5 | Create, monitor and kill processes (`ps`, `top`, `jobs`, `bg`, `fg`, `nohup`, `kill`, `pkill`, `screen`, `tmux`) | [Viewing Processes](../07-processes/viewing-processes.md), [Signals](../07-processes/signals.md), [Job Control](../07-processes/job-control.md) |
| LPIC-1 103.6 | Modify process execution priorities (`nice`, `renice`) | [Priority and Nice](../07-processes/priority-and-nice.md) |
| Linux+ XK0-006 | Process management: states, signals, priorities, job control | [Process States](../07-processes/process-states.md), [Signals](../07-processes/signals.md), [Job Control](../07-processes/job-control.md) |
| Interview sources | `fork`/`exec`/`wait`, zombies and orphans, system calls, `strace` | [Process Lifecycle](../07-processes/process-lifecycle.md), [Process Fundamentals](../07-processes/process-fundamentals.md), [System Calls and Tracing](../07-processes/system-calls-and-tracing.md) |

---

## Systemd and Services

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Boot, reboot and shut down a system normally | [Init and Targets](../08-systemd-and-services/init-and-targets.md) |
| RHCSA EX200 (RHEL 10) | Boot systems into different targets manually | [Init and Targets](../08-systemd-and-services/init-and-targets.md) |
| RHCSA EX200 (RHEL 10) | Start, stop and check the status of network services | [systemctl](../08-systemd-and-services/systemctl.md) |
| RHCSA EX200 (RHEL 10) | Start and stop services and configure services to start automatically at boot | [systemctl](../08-systemd-and-services/systemctl.md) |
| RHCSA EX200 (RHEL 10) | Configure systems to boot into a specific target automatically | [Init and Targets](../08-systemd-and-services/init-and-targets.md) |
| LFCS | Manage and configure systemd services and targets | [systemctl](../08-systemd-and-services/systemctl.md), [Unit Files](../08-systemd-and-services/unit-files.md), [Writing a Service](../08-systemd-and-services/writing-a-service.md) |
| LPIC-1 101.3 | Change runlevels / boot targets and shut down or reboot the system | [Init and Targets](../08-systemd-and-services/init-and-targets.md) |
| Linux+ XK0-006 | Service management with systemd: units, targets, overrides, troubleshooting | [systemctl](../08-systemd-and-services/systemctl.md), [Unit Files](../08-systemd-and-services/unit-files.md), [Systemd Toolbox](../08-systemd-and-services/systemd-toolbox.md) |

---

## Logging

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Locate and interpret system log files and journals | [Log Locations](../09-logging/log-locations.md), [journalctl](../09-logging/journalctl.md) |
| RHCSA EX200 (RHEL 10) | Preserve system journals | [journalctl](../09-logging/journalctl.md) |
| LFCS | Configure and manage system logging; analyze logs | [journalctl](../09-logging/journalctl.md), [rsyslog](../09-logging/rsyslog.md), [Log Parsing Recipes](../09-logging/log-parsing-recipes.md) |
| LPIC-1 108.2 | System logging: rsyslog, logrotate, journald, `logger`, `systemd-cat` | [rsyslog](../09-logging/rsyslog.md), [logrotate](../09-logging/logrotate.md), [journalctl](../09-logging/journalctl.md) |
| Linux+ XK0-006 | Logging and log analysis | [Log Locations](../09-logging/log-locations.md), [Log Parsing Recipes](../09-logging/log-parsing-recipes.md) |
| Interview sources | Parse access and authentication logs with `awk`, `sort`, `uniq` | [Log Parsing Recipes](../09-logging/log-parsing-recipes.md) |

---

## Scheduling

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Schedule tasks using `at` and `cron` | [cron and at](../10-scheduling/cron-and-at.md) |
| RHCSA EX200 (RHEL 10) | Schedule tasks with systemd timer units | [Systemd Timers](../10-scheduling/systemd-timers.md) |
| LFCS | Schedule tasks to run at a set date and time | [cron and at](../10-scheduling/cron-and-at.md), [Systemd Timers](../10-scheduling/systemd-timers.md) |
| LPIC-1 107.2 | Automate system administration tasks by scheduling jobs (`cron`, `at`, `anacron`, timers, access files) | [cron and at](../10-scheduling/cron-and-at.md), [Systemd Timers](../10-scheduling/systemd-timers.md) |
| Linux+ XK0-006 | Job scheduling | [cron and at](../10-scheduling/cron-and-at.md) |

---

## Kernel and Hardware

| Curriculum | Objective | Covered in |
|---|---|---|
| LFCS | Update and manage kernel parameters (`sysctl`); load and remove kernel modules | [sysctl](../11-kernel-and-hardware/sysctl.md), [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md) |
| LPIC-1 101.1 | Determine and configure hardware: sysfs, udev, procfs, `/dev`, `modprobe`, `lsmod`, `lspci`, `lsusb` | [proc and sys](../11-kernel-and-hardware/proc-and-sys.md), [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md), [Devices and udev](../11-kernel-and-hardware/devices-and-udev.md) |
| LPIC-1 101.2 | Kernel ring buffer and boot messages (`dmesg`, `journalctl -k`) | [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md) |
| Linux+ XK0-006 | Kernel modules, parameters and hardware devices | [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md), [sysctl](../11-kernel-and-hardware/sysctl.md), [Devices and udev](../11-kernel-and-hardware/devices-and-udev.md) |
| Interview sources | OOM killer, segfaults, hung tasks, `/proc` without tools | [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md), [proc and sys](../11-kernel-and-hardware/proc-and-sys.md) |

---

## Storage

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | List, create and delete partitions on MBR and GPT disks | [Partitioning](../12-storage/partitioning.md) |
| RHCSA EX200 (RHEL 10) | Create and remove physical volumes, assign them to volume groups, create and delete logical volumes | [LVM](../12-storage/lvm.md) |
| RHCSA EX200 (RHEL 10) | Configure systems to mount file systems at boot by UUID or label | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| RHCSA EX200 (RHEL 10) | Add new partitions, logical volumes and swap to a system non-destructively | [Partitioning](../12-storage/partitioning.md), [LVM](../12-storage/lvm.md), [Swap](../12-storage/swap.md) |
| RHCSA EX200 (RHEL 10) | Create, mount, unmount and use vfat, ext4 and xfs file systems | [Filesystems](../12-storage/filesystems.md), [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| RHCSA EX200 (RHEL 10) | Extend existing logical volumes | [LVM](../12-storage/lvm.md), [Resizing and Cloud Disks](../12-storage/resizing-and-cloud-disks.md) |
| LFCS | Configure and manage LVM storage; create, manage and troubleshoot filesystems | [LVM](../12-storage/lvm.md), [Filesystems](../12-storage/filesystems.md) |
| LFCS | Configure and manage swap space | [Swap](../12-storage/swap.md) |
| LPIC-1 102.1 | Design hard disk layout (partitions, swap, LVM basics) | [Partitioning](../12-storage/partitioning.md), [LVM](../12-storage/lvm.md) |
| LPIC-1 104.1 | Create partitions and filesystems (`fdisk`, `gdisk`, `parted`, `mkfs`, `mkswap`) | [Partitioning](../12-storage/partitioning.md), [Filesystems](../12-storage/filesystems.md), [Swap](../12-storage/swap.md) |
| LPIC-1 104.2 | Maintain the integrity of filesystems (`df`, `du`, `fsck`, `e2fsck`, `tune2fs`, `xfs_repair`) | [Filesystems](../12-storage/filesystems.md), [Disk Usage](../12-storage/disk-usage.md) |
| LPIC-1 104.3 | Control mounting and unmounting (`/etc/fstab`, `blkid`, `lsblk`, systemd mount units) | [Mounting and fstab](../12-storage/mounting-and-fstab.md), [Disks and Devices](../12-storage/disks-and-devices.md) |
| Linux+ XK0-006 | Storage: partitions, filesystems, LVM, RAID, quotas and encryption | [LVM](../12-storage/lvm.md), [RAID and Encryption](../12-storage/raid-and-encryption.md), [Quotas](../12-storage/quotas.md) |
| Linux+ XK0-006 | Backup and restore methods | [Backup and Restore](../12-storage/backup-and-restore.md) |
| Interview sources | Disk full, `df` versus `du`, inodes, deleted open files, extending a cloud volume | [Disk Usage](../12-storage/disk-usage.md), [Resizing and Cloud Disks](../12-storage/resizing-and-cloud-disks.md) |

---

## Networking

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Configure IPv4 and IPv6 addresses | [Network Configuration](../13-networking/network-configuration.md), [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md) |
| RHCSA EX200 (RHEL 10) | Configure hostname resolution | [DNS Resolution](../13-networking/dns-resolution.md), [Network Configuration](../13-networking/network-configuration.md) |
| RHCSA EX200 (RHEL 10) | Configure network services to start automatically at boot | [Network Configuration](../13-networking/network-configuration.md) |
| RHCSA EX200 (RHEL 10) | Configure time service clients | [Time and Timezones](../13-networking/time-and-timezones.md) |
| LFCS | Configure IPv4 and IPv6 networking and hostname resolution | [Network Configuration](../13-networking/network-configuration.md), [DNS Resolution](../13-networking/dns-resolution.md) |
| LFCS | Set and synchronize system time using time servers | [Time and Timezones](../13-networking/time-and-timezones.md) |
| LFCS | Monitor and troubleshoot networking | [Connectivity Testing](../13-networking/connectivity-testing.md), [Packet Capture](../13-networking/packet-capture.md), [Troubleshooting Ladder](../13-networking/troubleshooting-ladder.md) |
| LFCS | Configure bridge and bonding devices | [Bridges, Bonds and VLANs](../13-networking/bridges-bonds-vlans.md) |
| LFCS | Implement reverse proxies and load balancers | [Reverse Proxy and Load Balancing](../13-networking/reverse-proxy-and-load-balancing.md) |
| LFCS | Configure and verify network routes | [Routing](../13-networking/routing.md) |
| LPIC-1 108.1 | Maintain system time (`date`, `hwclock`, `timedatectl`, chrony) | [Time and Timezones](../13-networking/time-and-timezones.md) |
| LPIC-1 109.1 | Fundamentals of internet protocols (ports, TCP and UDP, IPv6) | [Ports and Sockets](../13-networking/ports-and-sockets.md), [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md) |
| LPIC-1 109.2 | Persistent network configuration (NetworkManager, `hostnamectl`, `/etc/hosts`, `nsswitch.conf`) | [Network Configuration](../13-networking/network-configuration.md), [DNS Resolution](../13-networking/dns-resolution.md) |
| LPIC-1 109.3 | Basic network troubleshooting (`ip`, `ss`, `ping`, `traceroute`, `tracepath`, `nc`) | [Connectivity Testing](../13-networking/connectivity-testing.md), [Routing](../13-networking/routing.md), [Ports and Sockets](../13-networking/ports-and-sockets.md) |
| LPIC-1 109.4 | Configure client side DNS (`resolv.conf`, `getent`, `dig`, `host`) | [DNS Resolution](../13-networking/dns-resolution.md) |
| Linux+ XK0-006 | Network configuration, tools and troubleshooting | [Network Configuration](../13-networking/network-configuration.md), [Connectivity Testing](../13-networking/connectivity-testing.md), [Packet Capture](../13-networking/packet-capture.md), [Troubleshooting Ladder](../13-networking/troubleshooting-ladder.md) |
| Linux+ XK0-006 | Tunnels and VPNs | [VPN (WireGuard)](../13-networking/vpn-wireguard.md) |
| Interview sources | `ss` and `netstat`, TCP states, DNS lookup order, `502` versus `504`, a layered troubleshooting answer | [Ports and Sockets](../13-networking/ports-and-sockets.md), [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md), [DNS Resolution](../13-networking/dns-resolution.md), [Reverse Proxy and Load Balancing](../13-networking/reverse-proxy-and-load-balancing.md), [Troubleshooting Ladder](../13-networking/troubleshooting-ladder.md) |

---

## SSH and Remote Access

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Access remote systems using SSH | [SSH Client](../14-ssh-and-remote-access/ssh-client.md), [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| RHCSA EX200 (RHEL 10) | Configure key-based authentication for SSH | [SSH Client](../14-ssh-and-remote-access/ssh-client.md), [sshd Server](../14-ssh-and-remote-access/sshd-server.md) |
| RHCSA EX200 (RHEL 10) | Securely transfer files between systems | [File Transfer](../14-ssh-and-remote-access/file-transfer.md) |
| LFCS | Configure SSH servers and clients | [ssh Client](../14-ssh-and-remote-access/ssh-client.md), [sshd Server](../14-ssh-and-remote-access/sshd-server.md) |
| LPIC-1 105 / 110.3 | Securing data with SSH, tunnels and known hosts | [SSH Client](../14-ssh-and-remote-access/ssh-client.md), [SSH Tunnels](../14-ssh-and-remote-access/ssh-tunnels.md) |
| Linux+ XK0-006 | Remote access (SSH keys, config, tunnels, SFTP) | [SSH Client](../14-ssh-and-remote-access/ssh-client.md), [SSH Tunnels](../14-ssh-and-remote-access/ssh-tunnels.md), [File Transfer](../14-ssh-and-remote-access/file-transfer.md) |
| Interview sources | `Permission denied (publickey)` ladder, slow login, bastions, `rsync` trailing slash | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md), [SSH Client](../14-ssh-and-remote-access/ssh-client.md), [File Transfer](../14-ssh-and-remote-access/file-transfer.md) |

---

## Security

| Curriculum | Objective | Covered in |
|---|---|---|
| RHCSA EX200 (RHEL 10) | Configure firewall settings using firewall-cmd | [firewalld and ufw](../15-security/firewalld-and-ufw.md) |
| RHCSA EX200 (RHEL 10) | Set enforcing and permissive modes for SELinux | [SELinux](../15-security/selinux.md) |
| RHCSA EX200 (RHEL 10) | List and identify SELinux file and process context | [SELinux](../15-security/selinux.md) |
| RHCSA EX200 (RHEL 10) | Restore default file contexts; use booleans | [SELinux](../15-security/selinux.md) |
| RHCSA EX200 (RHEL 10) | Diagnose and address routine SELinux policy violations | [SELinux](../15-security/selinux.md), [Hardening Checklist](../15-security/hardening-checklist.md) |
| LFCS | Configure firewalld / packet filtering | [firewalld and ufw](../15-security/firewalld-and-ufw.md), [nftables and iptables](../15-security/nftables-and-iptables.md) |
| LFCS | Configure and manage SELinux / AppArmor | [SELinux](../15-security/selinux.md), [AppArmor](../15-security/apparmor.md) |
| LFCS | Manage software and configure GPG-signed repositories | [GPG](../15-security/gpg.md) |
| LFCS | Configure and use auditing | [auditd](../15-security/auditd.md) |
| LPIC-1 110.1 | Perform security administration tasks (setuid, `find`, ports, `fail2ban`) | [Hardening Checklist](../15-security/hardening-checklist.md), [Capabilities](../15-security/capabilities.md) |
| LPIC-1 110.2 | Set up host security (services, TCP wrappers, updates) | [Hardening Checklist](../15-security/hardening-checklist.md), [Compliance and Integrity](../15-security/compliance-and-integrity.md) |
| LPIC-1 110 / GPG | Encrypt and sign with GnuPG; manage keys | [GPG](../15-security/gpg.md) |
| Linux+ XK0-006 | Firewalls, SELinux/AppArmor, capabilities, hardening | [firewalld and ufw](../15-security/firewalld-and-ufw.md), [SELinux](../15-security/selinux.md), [Capabilities](../15-security/capabilities.md), [Hardening Checklist](../15-security/hardening-checklist.md) |
| Linux+ XK0-006 | Certificates, PKI and the system trust store | [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md) |
| Linux+ XK0-006 | NAT, port forwarding and packet filtering | [nftables and iptables](../15-security/nftables-and-iptables.md) |
| Interview sources | SELinux denials with correct modes, capabilities vs setuid, reject vs drop, backported CVEs, TLS trust | [SELinux](../15-security/selinux.md), [Capabilities](../15-security/capabilities.md), [firewalld and ufw](../15-security/firewalld-and-ufw.md), [Compliance and Integrity](../15-security/compliance-and-integrity.md), [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md) |
