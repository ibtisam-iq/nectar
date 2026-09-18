# Command Index

Every command used across this folder, in one alphabetical list, with a one-line reminder of what it does and the topic that covers it. Use it to jump from a half-remembered name to the page that explains the flags.

---

## A to C

| Command | Does | Topic |
|---|---|---|
| `apt` | Install, remove and update packages (Ubuntu) | [dpkg and apt](../06-package-management/dpkg-and-apt.md) |
| `at` | Run a command once at a set time | [Cron and at](../10-scheduling/cron-and-at.md) |
| `auditctl`, `ausearch` | Configure and search the audit log | [auditd](../15-security/auditd.md) |
| `awk` | Field-based text processing and sums | [awk](../03-text-processing/awk.md) |
| `blkid` | Show filesystem UUIDs and types | [Disks and Devices](../12-storage/disks-and-devices.md) |
| `cat`, `less`, `head`, `tail` | View file contents | [Viewing and Comparing](../03-text-processing/viewing-and-comparing.md) |
| `chage` | Show and set password aging | [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| `chattr`, `lsattr` | Set and read file attributes (`+i`, `+a`) | [File Attributes](../05-permissions/file-attributes.md) |
| `chcon`, `restorecon` | Change and reset SELinux contexts | [SELinux](../15-security/selinux.md) |
| `chmod`, `chown`, `chgrp` | Change mode, owner and group | [Basic Permissions](../05-permissions/basic-permissions.md) |
| `chronyc`, `timedatectl` | Time sync and timezone | [Time and Timezones](../13-networking/time-and-timezones.md) |
| `chroot` | Run with a different root directory | [Overlayfs and chroot](../19-containers/overlayfs-and-chroot.md) |
| `cp`, `mv`, `rm` | Copy, move and remove files | [File Operations](../02-files-and-filesystem/file-operations.md) |
| `cron`, `crontab` | Schedule recurring jobs | [Cron and at](../10-scheduling/cron-and-at.md) |
| `curl`, `wget` | Fetch over HTTP and test endpoints | [Connectivity Testing](../13-networking/connectivity-testing.md) |
| `cut`, `sort`, `uniq`, `tr` | Column, sort and character transforms | [cut sort uniq tr](../03-text-processing/cut-sort-uniq-tr.md) |

---

## D to G

| Command | Does | Topic |
|---|---|---|
| `dd` | Block-level copy and image writing | [File Operations](../02-files-and-filesystem/file-operations.md) |
| `df`, `du` | Filesystem space and directory size | [Disk Usage](../12-storage/disk-usage.md) |
| `dig`, `host`, `resolvectl` | DNS lookups | [DNS Resolution](../13-networking/dns-resolution.md) |
| `dmesg` | Kernel ring buffer messages | [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md) |
| `dnf` | Install, remove and update packages (RHEL) | [rpm and dnf](../06-package-management/rpm-and-dnf.md) |
| `dpkg` | Low-level package queries (Ubuntu) | [dpkg and apt](../06-package-management/dpkg-and-apt.md) |
| `dracut` | Rebuild the initramfs | [Kernel Updates](../16-boot-and-recovery/kernel-updates.md) |
| `find` | Search the filesystem by many criteria | [Finding Files](../02-files-and-filesystem/finding-files.md) |
| `findmnt` | Show and verify mounts | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `firewall-cmd` | Manage firewalld zones and rules | [Firewalld and UFW](../15-security/firewalld-and-ufw.md) |
| `free` | Memory use, judged by `available` | [Memory](../17-performance-and-troubleshooting/memory.md) |
| `fuser`, `lsof` | Which process holds a file or mount | [Disk Usage](../12-storage/disk-usage.md) |
| `getcap`, `setcap` | Read and set file capabilities | [Capabilities](../15-security/capabilities.md) |
| `getenforce`, `setenforce`, `semanage` | SELinux mode and policy | [SELinux](../15-security/selinux.md) |
| `getent` | Query nsswitch databases | [Centralized Identity](../04-users-and-access/centralized-identity.md) |
| `getfacl`, `setfacl` | Read and set ACLs | [ACL](../05-permissions/acl.md) |
| `gpg` | Sign, verify and encrypt | [GPG](../15-security/gpg.md) |
| `grep` | Search text with regular expressions | [grep and regex](../03-text-processing/grep-and-regex.md) |
| `groupadd`, `gpasswd` | Create and manage groups | [Groups](../04-users-and-access/groups.md) |
| `grub2-mkconfig`, `update-grub` | Regenerate the GRUB config | [GRUB2](../16-boot-and-recovery/grub2.md) |

---

## H to N

| Command | Does | Topic |
|---|---|---|
| `hostnamectl` | Show and set the hostname | [Network Configuration](../13-networking/network-configuration.md) |
| `id`, `groups` | Show a user's IDs and groups | [Groups](../04-users-and-access/groups.md) |
| `ip` | Addresses, links, routes and neighbours | [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md) |
| `iostat`, `iotop` | Per-disk I/O statistics | [Disk I/O](../17-performance-and-troubleshooting/disk-io.md) |
| `iscsiadm`, `targetcli` | iSCSI initiator and target | [iSCSI and NBD](../18-network-storage/iscsi-and-nbd.md) |
| `journalctl` | Query the systemd journal | [journalctl](../09-logging/journalctl.md) |
| `kill`, `pkill`, `killall` | Send signals to processes | [Signals](../07-processes/signals.md) |
| `ln` | Create hard and symbolic links | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| `logrotate` | Rotate and compress logs | [logrotate](../09-logging/logrotate.md) |
| `losetup` | Attach a file as a loop device | [Storage and LVM Lab](../labs/storage-and-lvm-lab.md) |
| `lsblk` | Tree of block devices | [Disks and Devices](../12-storage/disks-and-devices.md) |
| `lscpu`, `lsmem`, `lshw`, `lspci` | Hardware inventory | [System Information](../00-foundations/system-information.md) |
| `lsns`, `unshare`, `nsenter` | Inspect and enter namespaces | [Namespaces](../19-containers/namespaces.md) |
| `lvcreate`, `lvextend`, `pvs`, `vgs` | Manage LVM | [LVM](../12-storage/lvm.md) |
| `mdadm` | Software RAID arrays | [RAID and Encryption](../12-storage/raid-and-encryption.md) |
| `mkfs`, `fsck`, `tune2fs` | Create, check and tune filesystems | [Filesystems](../12-storage/filesystems.md) |
| `modprobe`, `lsmod`, `modinfo` | Kernel modules | [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md) |
| `mount`, `umount` | Attach and detach filesystems | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `nft`, `iptables` | Packet filtering and NAT | [nftables and iptables](../15-security/nftables-and-iptables.md) |
| `nice`, `renice`, `ionice`, `chrt` | Process priority | [Priority and Nice](../07-processes/priority-and-nice.md) |
| `nmcli`, `nmtui` | NetworkManager configuration (RHEL) | [Network Configuration](../13-networking/network-configuration.md) |

---

## O to S

| Command | Does | Topic |
|---|---|---|
| `openssl` | Inspect certificates, keys and TLS | [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md) |
| `parted`, `fdisk`, `gdisk` | Partition disks | [Partitioning](../12-storage/partitioning.md) |
| `podman`, `skopeo` | Run and manage containers | [Podman and Quadlet](../19-containers/podman-and-quadlet.md) |
| `ps`, `pstree`, `top`, `htop` | View processes | [Viewing Processes](../07-processes/viewing-processes.md) |
| `rpm` | Low-level package queries (RHEL) | [rpm and dnf](../06-package-management/rpm-and-dnf.md) |
| `rsync` | Efficient copy and mirror | [File Transfer](../14-ssh-and-remote-access/file-transfer.md) |
| `sar` | Historical performance data | [Methodology](../17-performance-and-troubleshooting/methodology.md) |
| `scp`, `sftp` | Copy files over SSH | [File Transfer](../14-ssh-and-remote-access/file-transfer.md) |
| `sed` | Stream edit and in-place replace | [sed](../03-text-processing/sed.md) |
| `ss`, `netstat` | Sockets and listening ports | [Ports and Sockets](../13-networking/ports-and-sockets.md) |
| `ssh`, `ssh-keygen`, `ssh-copy-id` | Remote login and keys | [SSH Client](../14-ssh-and-remote-access/ssh-client.md) |
| `strace`, `ltrace` | Trace system and library calls | [System Calls and Tracing](../07-processes/system-calls-and-tracing.md) |
| `su`, `sudo`, `visudo` | Switch user and grant privilege | [Sudo and su](../04-users-and-access/sudo-and-su.md) |
| `swapon`, `mkswap` | Enable and create swap | [Swap](../12-storage/swap.md) |
| `sysctl` | Read and set kernel parameters | [sysctl](../11-kernel-and-hardware/sysctl.md) |
| `systemctl` | Control services and targets | [systemctl](../08-systemd-and-services/systemctl.md) |
| `systemd-analyze`, `systemd-cgls` | Inspect boot and cgroups | [systemd Toolbox](../08-systemd-and-services/systemd-toolbox.md) |

---

## T to Z

| Command | Does | Topic |
|---|---|---|
| `tar`, `gzip`, `xz`, `zstd` | Archive and compress | [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |
| `tcpdump` | Capture packets | [Packet Capture](../13-networking/packet-capture.md) |
| `tee` | Write to a file and stdout | [xargs and tee](../03-text-processing/xargs-and-tee.md) |
| `timedatectl` | Time and timezone | [Time and Timezones](../13-networking/time-and-timezones.md) |
| `tuned-adm` | Apply a performance profile | [Tuning](../17-performance-and-troubleshooting/tuning.md) |
| `type`, `which`, `command -v` | Resolve a command name | [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| `ulimit` | Per-shell resource limits | [Limits and File Descriptors](../17-performance-and-troubleshooting/limits-and-file-descriptors.md) |
| `umask` | Default permission mask | [umask](../05-permissions/umask.md) |
| `useradd`, `usermod`, `userdel` | Manage user accounts | [Users](../04-users-and-access/users.md) |
| `vmstat`, `mpstat`, `pidstat` | CPU, memory and per-process stats | [CPU and Load](../17-performance-and-troubleshooting/cpu-and-load.md) |
| `who`, `w`, `last` | Login sessions and history | [Login Sessions](../04-users-and-access/login-sessions.md) |
| `xargs` | Build command lines from input | [xargs and tee](../03-text-processing/xargs-and-tee.md) |

---

## Related

- [Cheatsheet](cheatsheet.md): the same commands grouped by task
- [Important Files](important-files.md): the files these commands manage
- [Glossary](glossary.md): the objects these commands act on
