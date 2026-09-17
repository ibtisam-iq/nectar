# Roadmap

A progress tracker for the whole Linux folder. Tick topics in your own copy as you learn them; the Track and Weight after each entry show what to prioritise before an interview.

---

## 00 Foundations

- [ ] [What Is Linux](00-foundations/what-is-linux.md) (Core, Low)
- [ ] [Kernel vs OS vs Distro](00-foundations/kernel-vs-os-vs-distro.md) (Core, Med)
- [ ] [Distributions](00-foundations/distributions.md) (Core, Low)
- [ ] [Linux vs Windows](00-foundations/linux-vs-windows.md) (Core, Low)
- [ ] [Architecture](00-foundations/architecture.md) (Core, High)
- [ ] [System Information](00-foundations/system-information.md) (Core, Med)

---

## 01 Shell and CLI

- [ ] [Shell Basics](01-shell-and-cli/shell-basics.md) (Core, Med)
- [ ] [Getting Help](01-shell-and-cli/getting-help.md) (Core, Low)
- [ ] [Command Resolution](01-shell-and-cli/command-resolution.md) (Core, Med)
- [ ] [Variables and Environment](01-shell-and-cli/variables-and-environment.md) (Core, High)
- [ ] [Locale and Encoding](01-shell-and-cli/locale-and-encoding.md) (Core, Low)
- [ ] [Quoting and Expansion](01-shell-and-cli/quoting-and-expansion.md) (Core, Med)
- [ ] [Streams and Redirection](01-shell-and-cli/streams-and-redirection.md) (Core, High)
- [ ] [Exit Codes and Chaining](01-shell-and-cli/exit-codes-and-chaining.md) (Core, High)
- [ ] [Text Editors](01-shell-and-cli/text-editors.md) (Core, Low)
- [ ] [Scripting Essentials](01-shell-and-cli/scripting-essentials.md) (RHCSA, Med)

---

## 02 Files and Filesystem

- [ ] [Filesystem Hierarchy](02-files-and-filesystem/filesystem-hierarchy.md) (Core, High)
- [ ] [File Types](02-files-and-filesystem/file-types.md) (Core, Med)
- [ ] [Navigation and Listing](02-files-and-filesystem/navigation-and-listing.md) (Core, Low)
- [ ] [File Operations](02-files-and-filesystem/file-operations.md) (Core, Med)
- [ ] [Inodes and Links](02-files-and-filesystem/inodes-and-links.md) (Core, High)
- [ ] [File Descriptors](02-files-and-filesystem/file-descriptors.md) (Advanced, High, internals)
- [ ] [Finding Files](02-files-and-filesystem/finding-files.md) (Core, High)
- [ ] [Archiving and Compression](02-files-and-filesystem/archiving-and-compression.md) (Core, Med)

---

## 03 Text Processing

- [ ] [Viewing and Comparing](03-text-processing/viewing-and-comparing.md) (Core, Med)
- [ ] [grep and Regex](03-text-processing/grep-and-regex.md) (Core, High)
- [ ] [sed](03-text-processing/sed.md) (Core, High)
- [ ] [awk](03-text-processing/awk.md) (Core, High)
- [ ] [Cut, Sort, Uniq and Tr](03-text-processing/cut-sort-uniq-tr.md) (Core, High)
- [ ] [xargs and tee](03-text-processing/xargs-and-tee.md) (Core, Med)
- [ ] [JSON and YAML on the CLI](03-text-processing/json-and-yaml-on-cli.md) (Core, Med)

---

## 04 Users and Access

- [ ] [Users](04-users-and-access/users.md) (Core, High)
- [ ] [Groups](04-users-and-access/groups.md) (Core, High)
- [ ] [Passwords and Aging](04-users-and-access/passwords-and-aging.md) (Core, Med)
- [ ] [Sudo and Su](04-users-and-access/sudo-and-su.md) (Core, High, internals)
- [ ] [PAM](04-users-and-access/pam.md) (Core, Low)
- [ ] [Login Sessions](04-users-and-access/login-sessions.md) (Core, Low)
- [ ] [Centralized Identity](04-users-and-access/centralized-identity.md) (Advanced, Low)

---

## 05 Permissions

- [ ] [Basic Permissions](05-permissions/basic-permissions.md) (Core, High)
- [ ] [umask](05-permissions/umask.md) (Core, Med)
- [ ] [Special Permissions](05-permissions/special-permissions.md) (Core, High)
- [ ] [ACL](05-permissions/acl.md) (RHCSA, Med)
- [ ] [File Attributes](05-permissions/file-attributes.md) (Core, Med)

---

## 06 Package Management

- [ ] [Packaging Concepts](06-package-management/packaging-concepts.md) (Core, Med)
- [ ] [rpm and dnf](06-package-management/rpm-and-dnf.md) (Core, Med)
- [ ] [dpkg and apt](06-package-management/dpkg-and-apt.md) (Core, Med)
- [ ] [Repositories](06-package-management/repositories.md) (Core, Low)
- [ ] [Flatpak and Snap](06-package-management/flatpak-and-snap.md) (RHCSA, Low)
- [ ] [Shared Libraries](06-package-management/shared-libraries.md) (Advanced, Med, internals)
- [ ] [Other Install Methods](06-package-management/other-install-methods.md) (Core, Low)

---

## 07 Processes

- [ ] [Process Fundamentals](07-processes/process-fundamentals.md) (Core, High)
- [ ] [Process Lifecycle](07-processes/process-lifecycle.md) (Advanced, High, internals)
- [ ] [Viewing Processes](07-processes/viewing-processes.md) (Core, High)
- [ ] [Process States](07-processes/process-states.md) (Core, High)
- [ ] [Signals](07-processes/signals.md) (Core, High, internals)
- [ ] [Job Control](07-processes/job-control.md) (Core, Med)
- [ ] [Priority and Nice](07-processes/priority-and-nice.md) (Core, Med)
- [ ] [System Calls and Tracing](07-processes/system-calls-and-tracing.md) (Advanced, High, internals)

---

## 08 Systemd and Services

- [ ] [Init and Targets](08-systemd-and-services/init-and-targets.md) (Core, Med)
- [ ] [systemctl](08-systemd-and-services/systemctl.md) (Core, High)
- [ ] [Unit Files](08-systemd-and-services/unit-files.md) (Core, High)
- [ ] [Writing a Service](08-systemd-and-services/writing-a-service.md) (Core, Med)
- [ ] [Systemd Toolbox](08-systemd-and-services/systemd-toolbox.md) (Core, Low)

---

## 09 Logging

- [ ] [Log Locations](09-logging/log-locations.md) (Core, High)
- [ ] [journalctl](09-logging/journalctl.md) (Core, High)
- [ ] [rsyslog](09-logging/rsyslog.md) (Core, Low)
- [ ] [logrotate](09-logging/logrotate.md) (Core, Med)
- [ ] [Log Parsing Recipes](09-logging/log-parsing-recipes.md) (Core, High)

---

## 10 Scheduling

- [ ] [cron and at](10-scheduling/cron-and-at.md) (Core, High)
- [ ] [Systemd Timers](10-scheduling/systemd-timers.md) (Core, Med)

---

## 11 Kernel and Hardware

- [ ] [proc and sys](11-kernel-and-hardware/proc-and-sys.md) (Core, High)
- [ ] [sysctl](11-kernel-and-hardware/sysctl.md) (Core, High)
- [ ] [Kernel Modules](11-kernel-and-hardware/kernel-modules.md) (Core, Med)
- [ ] [Devices and udev](11-kernel-and-hardware/devices-and-udev.md) (Advanced, Low)
- [ ] [dmesg and Kernel Messages](11-kernel-and-hardware/dmesg-and-kernel-messages.md) (Core, Med)

---

## 12 Storage

- [ ] [Disks and Devices](12-storage/disks-and-devices.md) (Core, Med)
- [ ] [Partitioning](12-storage/partitioning.md) (RHCSA, Med)
- [ ] [Filesystems](12-storage/filesystems.md) (Core, Med)
- [ ] [Mounting and fstab](12-storage/mounting-and-fstab.md) (Core, High)
- [ ] [Swap](12-storage/swap.md) (Core, Med)
- [ ] [LVM](12-storage/lvm.md) (Core, High)
- [ ] [Resizing and Cloud Disks](12-storage/resizing-and-cloud-disks.md) (Core, Med)
- [ ] [Disk Usage](12-storage/disk-usage.md) (Core, High)
- [ ] [Quotas](12-storage/quotas.md) (RHCSA, Low)
- [ ] [Backup and Restore](12-storage/backup-and-restore.md) (Core, Med)
- [ ] [RAID and Encryption](12-storage/raid-and-encryption.md) (Advanced, Low)

---

## 13 Networking

- [ ] Interfaces and Addresses (Core, High)
- [ ] Network Configuration (Core, Med)
- [ ] Routing (Core, High)
- [ ] DNS Resolution (Core, High)
- [ ] Ports and Sockets (Core, High)
- [ ] Sockets and TCP States (Advanced, Med, internals)
- [ ] Connectivity Testing (Core, High)
- [ ] Packet Capture (Core, Med)
- [ ] Bridges, Bonds and VLANs (Advanced, Low)
- [ ] Time and Timezones (Core, Med)
- [ ] Reverse Proxy and Load Balancing (Core, Med)
- [ ] VPN (WireGuard) (Advanced, Low)
- [ ] Troubleshooting Ladder (Core, High)

---

## 14 SSH and Remote Access

- [ ] SSH Client (Core, High)
- [ ] SSH Tunnels (Core, Med)
- [ ] sshd Server (Core, Med)
- [ ] File Transfer (Core, Med)
- [ ] SSH Troubleshooting (Core, High)

---

## 15 Security

- [ ] firewalld and ufw (Core, Med)
- [ ] nftables and iptables (Core, Med)
- [ ] SELinux (RHCSA, Med, internals)
- [ ] AppArmor (Core, Low)
- [ ] Capabilities (Advanced, Med)
- [ ] auditd (Advanced, Low)
- [ ] GPG (Core, Low)
- [ ] OpenSSL and Trust Store (Core, Med)
- [ ] Compliance and Integrity (Advanced, Low)
- [ ] Hardening Checklist (Core, Med)

---

## 16 Boot and Recovery

- [ ] Boot Process (Core, High)
- [ ] GRUB2 (RHCSA, Med)
- [ ] Recovery (RHCSA, Med)
- [ ] Kernel Panic (Advanced, Med, internals)
- [ ] Kernel Updates (Core, Low)

---

## 17 Performance and Troubleshooting

- [ ] Methodology (Core, High)
- [ ] CPU and Load (Core, High)
- [ ] Memory (Core, High)
- [ ] Virtual Memory (Advanced, High, internals)
- [ ] Disk I/O (Core, Med)
- [ ] Limits and File Descriptors (Core, High)
- [ ] Profiling and Tracing (Advanced, Med, internals)
- [ ] Monitoring and Capacity (Core, Low)
- [ ] Tuning (RHCSA, Low)

---

## 18 Network Storage

- [ ] NFS (Core, Med)
- [ ] autofs (RHCSA, Low)
- [ ] Samba and CIFS (RHCSA, Low)
- [ ] iSCSI and NBD (Advanced, Low)

---

## 19 Containers

- [ ] Namespaces (Core, High, internals)
- [ ] cgroups (Core, High, internals)
- [ ] overlayfs and chroot (Core, Med)
- [ ] Containers vs VMs (Core, High)
- [ ] Podman and Quadlet (RHCSA, Med)

---

## 20 Virtualization and Provisioning

- [ ] KVM and libvirt (Advanced, Low)
- [ ] VM Images and Cloning (Advanced, Low)
- [ ] cloud-init and Kickstart (Core, Low)

---

## Labs

- [ ] [Users and Permissions Lab](labs/users-and-permissions-lab.md)
- [ ] [Processes and Services Lab](labs/processes-and-services-lab.md)
- [ ] [Storage and LVM Lab](labs/storage-and-lvm-lab.md)
- [ ] Networking Lab
- [ ] Security Lab
- [ ] Containers by Hand Lab
- [ ] RHCSA-Style Tasks
- [ ] Break-Fix Lab

---

## Scenarios

- [ ] [Cannot Log In or Use Sudo](interview/scenarios/cannot-login-or-sudo.md)
- [ ] [Binary Won't Execute](interview/scenarios/binary-wont-execute.md)
- [ ] [Process Won't Die](interview/scenarios/process-wont-die.md)
- [ ] [Service Won't Start](interview/scenarios/service-wont-start.md)
- [ ] [Cron Job Not Running](interview/scenarios/cron-job-not-running.md)
- [ ] [Disk Full](interview/scenarios/disk-full.md)
- [ ] DNS Not Resolving
- [ ] Cannot SSH
- [ ] Service Unreachable
- [ ] Cannot Reach Host
- [ ] TLS Certificate Errors
- [ ] Permission Denied
- [ ] Suspected Compromise
- [ ] Server Slow
- [ ] Too Many Open Files
- [ ] Cannot Fork
- [ ] Boot Failure
- [ ] High Load, Low CPU
- [ ] High Memory and OOM
