# Important Files

The configuration and state files that matter most on a Linux server: what each holds, its format, and the command that manages it rather than a hand edit. Paths are the same on RHEL and Ubuntu unless a row says otherwise.

---

## Users and Authentication

| File | Purpose | Format | Managed with |
|---|---|---|---|
| `/etc/passwd` | User accounts | `name:x:UID:GID:comment:home:shell`, colon-separated | `useradd`, `usermod`, `userdel`. See [Users](../04-users-and-access/users.md). |
| `/etc/shadow` | Password hashes and aging | `name:hash:lastchange:min:max:warn:...`, root-only | `passwd`, `chage`. See [Passwords and Aging](../04-users-and-access/passwords-and-aging.md). |
| `/etc/group` | Group definitions and members | `name:x:GID:members` | `groupadd`, `usermod -aG`, `gpasswd`. See [Groups](../04-users-and-access/groups.md). |
| `/etc/gshadow` | Group passwords and admins | Root-only companion to `group` | `gpasswd` |
| `/etc/sudoers`, `/etc/sudoers.d/` | Who may run `sudo` and as whom | Rule lines; drop-ins preferred | `visudo -f`. See [Sudo and su](../04-users-and-access/sudo-and-su.md). |
| `/etc/login.defs` | UID and GID ranges, password aging defaults | `KEY value` | Edited directly. See [Users](../04-users-and-access/users.md). |
| `/etc/skel/` | Template copied into a new home directory | Directory of files | Populated directly |
| `/etc/nsswitch.conf` | Lookup order for users, groups and hosts | `database: source source` | Edited directly. See [Centralized Identity](../04-users-and-access/centralized-identity.md). |
| `/etc/pam.d/` | Per-service authentication stacks | `type control module args` | Edited directly. See [PAM](../04-users-and-access/pam.md). |

---

## Filesystems and Storage

| File | Purpose | Format | Managed with |
|---|---|---|---|
| `/etc/fstab` | Filesystems mounted at boot | `source mountpoint type options dump pass` | Edited directly; test with `findmnt --verify` and `mount -a`. See [Mounting and fstab](../12-storage/mounting-and-fstab.md). |
| `/etc/crypttab` | Encrypted volumes opened at boot | `name device key options` | Edited directly. See [RAID and Encryption](../12-storage/raid-and-encryption.md). |
| `/etc/mdadm.conf` | Software RAID array definitions | `ARRAY` lines | `mdadm --detail --scan`. See [RAID and Encryption](../12-storage/raid-and-encryption.md). |
| `/proc/mounts` | Kernel view of current mounts | Live, read-only | Read with `findmnt`, `mount`. See [Mounting and fstab](../12-storage/mounting-and-fstab.md). |
| `/proc/mdstat` | Software RAID status | Live, read-only | Read directly. See [RAID and Encryption](../12-storage/raid-and-encryption.md). |

---

## Services and Boot

| File | Purpose | Format | Managed with |
|---|---|---|---|
| `/etc/systemd/system/` | Local and overriding unit files | INI-style `[Unit] [Service] [Install]` | `systemctl edit`, `systemctl daemon-reload`. See [Unit Files](../08-systemd-and-services/unit-files.md). |
| `/usr/lib/systemd/system/` | Unit files shipped by packages | INI-style | Not hand-edited; override in `/etc`. See [Unit Files](../08-systemd-and-services/unit-files.md). |
| `/etc/default/grub` | GRUB defaults and kernel command line | `KEY="value"` | Edit, then `grub2-mkconfig` (RHEL) or `update-grub` (Ubuntu). See [GRUB2](../16-boot-and-recovery/grub2.md). |
| `/boot/` | Kernels, initramfs, GRUB configuration | Binary and generated | `dracut`, `grub2-mkconfig`. See [Kernel Updates](../16-boot-and-recovery/kernel-updates.md). |
| `/etc/crontab`, `/etc/cron.d/` | System scheduled jobs | `min hour dom mon dow user command` | Edited directly. See [Cron and at](../10-scheduling/cron-and-at.md). |

---

## Networking

| File | Purpose | Format | Managed with |
|---|---|---|---|
| `/etc/hostname` | The system hostname | One line | `hostnamectl set-hostname`. See [Network Configuration](../13-networking/network-configuration.md). |
| `/etc/hosts` | Static name-to-address entries | `address name alias` | Edited directly. See [DNS Resolution](../13-networking/dns-resolution.md). |
| `/etc/resolv.conf` | DNS resolvers | `nameserver`, `search` | Often a symlink managed by `systemd-resolved` or NetworkManager. See [DNS Resolution](../13-networking/dns-resolution.md). |
| `/etc/NetworkManager/system-connections/` | Connection profiles (RHEL) | Keyfile INI | `nmcli`, `nmtui`. See [Network Configuration](../13-networking/network-configuration.md). |
| `/etc/netplan/*.yaml` | Network configuration (Ubuntu) | YAML | Edit, then `netplan apply`. See [Network Configuration](../13-networking/network-configuration.md). |
| `/etc/ssh/sshd_config` | SSH server settings | `Keyword value` | Edit, then `sshd -t` and reload. See [sshd Server](../14-ssh-and-remote-access/sshd-server.md). |
| `~/.ssh/config` | Per-user SSH client shortcuts | `Host` blocks | Edited directly. See [SSH Client](../14-ssh-and-remote-access/ssh-client.md). |
| `~/.ssh/authorized_keys` | Public keys allowed to log in | One key per line | `ssh-copy-id`. See [SSH Client](../14-ssh-and-remote-access/ssh-client.md). |

---

## Packages, Logs and Kernel

| File | Purpose | Format | Managed with |
|---|---|---|---|
| `/etc/yum.repos.d/*.repo` | DNF repositories (RHEL) | INI-style | `dnf config-manager`. See [Repositories](../06-package-management/repositories.md). |
| `/etc/apt/sources.list`, `/etc/apt/sources.list.d/` | APT repositories (Ubuntu) | `deb` lines or `deb822` | `add-apt-repository`. See [Repositories](../06-package-management/repositories.md). |
| `/etc/sysctl.conf`, `/etc/sysctl.d/` | Persistent kernel parameters | `key = value` | `sysctl -p`, `sysctl --system`. See [sysctl](../11-kernel-and-hardware/sysctl.md). |
| `/etc/security/limits.conf`, `/etc/security/limits.d/` | Per-user resource limits | `domain type item value` | Edited directly. See [Limits and File Descriptors](../17-performance-and-troubleshooting/limits-and-file-descriptors.md). |
| `/var/log/messages` (RHEL), `/var/log/syslog` (Ubuntu) | General system log | Text, when `rsyslog` runs | Read with `less`, `grep`; also `journalctl`. See [Log Locations](../09-logging/log-locations.md). |
| `/var/log/secure` (RHEL), `/var/log/auth.log` (Ubuntu) | Authentication and `sudo` events | Text | Read directly. See [Log Locations](../09-logging/log-locations.md). |
| `/etc/logrotate.conf`, `/etc/logrotate.d/` | Log rotation rules | Per-file blocks | Test with `logrotate -d`. See [logrotate](../09-logging/logrotate.md). |
| `/etc/os-release` | Distribution name and version | `KEY=value` | Read directly. See [System Information](../00-foundations/system-information.md). |

---

## Related

- [Command Index](command-index.md): the commands that read and write these files
- [Glossary](glossary.md): the objects these files define
- [RHEL vs Ubuntu](rhel-vs-ubuntu.md): where the paths and tools differ between families
