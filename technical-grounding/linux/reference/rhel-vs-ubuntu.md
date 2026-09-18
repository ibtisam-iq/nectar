# RHEL vs Ubuntu

Where the two dominant server families differ in command, file and default. RHEL rows cover Rocky and other rebuilds; Ubuntu rows cover Debian. Where a tool is identical on both, it is not listed here.

---

## Packages

| | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| **Install a package** | `dnf install pkg` | `apt install pkg` |
| **Remove a package** | `dnf remove pkg` | `apt remove pkg` |
| **Update the index** | Automatic on each `dnf` run | `apt update` first |
| **Upgrade everything** | `dnf upgrade` | `apt upgrade` |
| **Search** | `dnf search term` | `apt search term` |
| **Which package owns a file** | `rpm -qf /path`, `dnf provides /path` | `dpkg -S /path` |
| **List a package's files** | `rpm -ql pkg` | `dpkg -L pkg` |
| **Low-level package tool** | `rpm` | `dpkg` |
| **Repository files** | `/etc/yum.repos.d/*.repo` | `/etc/apt/sources.list.d/` |
| **Hold a version** | `dnf versionlock` | `apt-mark hold` |

See [rpm and dnf](../06-package-management/rpm-and-dnf.md) and [dpkg and apt](../06-package-management/dpkg-and-apt.md).

---

## Users and Account Creation

| | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| **Create a user (low-level)** | `useradd` (no home by default flags vary) | `useradd` (same tool) |
| **Create a user (interactive)** | Not shipped | `adduser` (Perl wrapper, prompts) |
| **Default admin group** | `wheel` | `sudo` |
| **Regular UID start** | 1000 | 1000 |

See [Users](../04-users-and-access/users.md) and [Sudo and su](../04-users-and-access/sudo-and-su.md).

---

## Networking

| | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| **Configure an interface** | `nmcli`, `nmtui` (NetworkManager) | `netplan` YAML, then `netplan apply` |
| **Connection storage** | `/etc/NetworkManager/system-connections/` | `/etc/netplan/*.yaml` |
| **Resolver stub** | `systemd-resolved` or NetworkManager | `systemd-resolved` |
| **Default firewall front end** | `firewalld` | `ufw` |

See [Network Configuration](../13-networking/network-configuration.md) and [Firewalld and UFW](../15-security/firewalld-and-ufw.md).

---

## Security

| | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| **Mandatory access control** | SELinux, enforcing by default | AppArmor, enforcing by default |
| **Policy tools** | `getenforce`, `semanage`, `restorecon`, `audit2allow` | `aa-status`, `aa-complain`, `aa-enforce` |
| **CA trust store** | `/etc/pki/ca-trust/`, `update-ca-trust` | `/usr/local/share/ca-certificates/`, `update-ca-certificates` |
| **Verify installed packages** | `rpm -Va` | `debsums` |

See [SELinux](../15-security/selinux.md), [AppArmor](../15-security/apparmor.md) and [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md).

---

## Logs and Boot

| | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| **General log file** | `/var/log/messages` | `/var/log/syslog` |
| **Authentication log** | `/var/log/secure` | `/var/log/auth.log` |
| **Journal** | `journalctl` (same on both) | `journalctl` (same on both) |
| **Regenerate GRUB** | `grub2-mkconfig -o /boot/grub2/grub.cfg` | `update-grub` |
| **Regenerate initramfs** | `dracut -f` | `update-initramfs -u` |

See [Log Locations](../09-logging/log-locations.md) and [GRUB2](../16-boot-and-recovery/grub2.md).

---

## Filesystems and Defaults

| | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| **Default root filesystem** | XFS | ext4 |
| **Default volume layout** | LVM on install | Plain partition or LVM (installer choice) |
| **Shrink the root filesystem** | Not possible (XFS cannot shrink) | Possible (ext4 shrinks) |

See [Filesystems](../12-storage/filesystems.md) and [LVM](../12-storage/lvm.md).

!!! note "The same software ships under different package names"
    The same software often ships under different package names, for example `cloud-utils-growpart` on RHEL and `cloud-guest-utils` on Ubuntu, or `openssh-server` present on both. A provisioning script that hard-codes one family's names fails on the other, so the topic pages use distro tabs wherever the name differs.

!!! tip "One habit works on both: ask the system, do not assume"
    `command -v tool`, `cat /etc/os-release` and `type -a name` report what is actually installed, so a runbook that checks before acting survives a move between families. This is why the folder leads with distro-neutral commands and only splits into tabs where output or syntax truly differs.

---

## Related

- [Important Files](important-files.md): the files these tools manage on each family
- [Command Index](command-index.md): the full A to Z of commands
- [Cheatsheet](cheatsheet.md): the same commands grouped by task
