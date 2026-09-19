# Source Inventory

Every item in the Red Hat diploma material, mapped to where its topic lives in the Linux tool folder. Force-tracked (the rest of `_sources/` is git-ignored) and excluded from the site, so `scripts/audit-tool.py` (check 9) can run on a fresh checkout.

Status values: `mapped` (topic covered by the target file), `fact` (becomes a Must-Know Facts row in the target), `deferred` (belongs to another tool folder), `dropped` (reason given). Wording from these sources is never copied; only topics are used. Paths are relative to `technical-grounding/linux/`.

---

## Session Handouts

| Source | Topic | Status | Target |
|---|---|---|---|
| rhcsa/02. Lab setup req tools.txt | VirtualBox, RHEL 9 ISO, developer account | mapped | labs/README.md |
| rhcsa/02.1 Linux Lab Setup Troubleshooting.txt | VT-x in BIOS, kernel panic on VM start (vCPU, Core Isolation, hypervisorlaunchtype) | mapped | labs/README.md |
| rhcsa/05. Session Notes.txt | mkdir -p, brace expansion, touch, rm, globs | mapped | 02-files-and-filesystem/file-operations.md; 01-shell-and-cli/quoting-and-expansion.md |
| rhcsa/06. Session Notes.txt | cat redirection, cp, mv, vim modes and keys | mapped | 02-files-and-filesystem/file-operations.md; 01-shell-and-cli/text-editors.md |
| rhcsa/07. Session Notes.txt | UID ranges, passwd, shadow, useradd, usermod, userdel, su | mapped | 04-users-and-access/users.md; 04-users-and-access/passwords-and-aging.md; 04-users-and-access/sudo-and-su.md |
| rhcsa/08. Session Notes.txt | Primary and secondary groups, group and gshadow, gpasswd, chown, chgrp | mapped | 04-users-and-access/groups.md; 05-permissions/basic-permissions.md |
| rhcsa/09. Session Notes.txt | chmod symbolic and octal | mapped | 05-permissions/basic-permissions.md |
| rhcsa/10. Session Notes.txt | getfacl, setfacl | mapped | 05-permissions/acl.md |
| rhcsa/11. Session Notes.txt | SUID, SGID, sticky bit; changing a home directory | mapped | 05-permissions/special-permissions.md; 04-users-and-access/users.md |
| rhcsa/12. Session Notes.txt | grep options, find by name/perm/user/size with -exec, head, tail, wc, man, info | mapped | 03-text-processing/grep-and-regex.md; 02-files-and-filesystem/finding-files.md; 03-text-processing/viewing-and-comparing.md; 01-shell-and-cli/getting-help.md |
| rhcsa/13. Session Notes .txt | tar with gzip/bzip2/xz, du -sh, at/atq/atrm, timedatectl, chronyd | mapped | 02-files-and-filesystem/archiving-and-compression.md; 10-scheduling/cron-and-at.md; 13-networking/time-and-timezones.md |
| rhcsa/14. Session Notes.txt | crontab syntax, cron.deny, /var/log/cron | mapped | 10-scheduling/cron-and-at.md |
| rhcsa/15. Session Notes.txt | Device naming, MBR partition types, fdisk, mkfs.xfs, mount, fstab, blkid, filesystem comparison | mapped | 12-storage/disks-and-devices.md; 12-storage/partitioning.md; 12-storage/filesystems.md; 12-storage/mounting-and-fstab.md |
| rhcsa/16. Session Notes.txt | ext4 and xfs resize, swap partitions | mapped | 12-storage/resizing-and-cloud-disks.md; 12-storage/swap.md |
| rhcsa/Session 17 Notes.txt | LVM create, extend, reduce, remove; SSD check with rota | mapped | 12-storage/lvm.md |
| rhcsa/Session 17.1 LVM Diagram.png | LVM layering diagram | mapped | 12-storage/lvm.md (redrawn as mermaid) |
| rhcsa/Session 18 LVM Exam Practice Que.txt | LVM sizing tasks with PE maths | mapped | labs/rhcsa-style-tasks.md |
| rhcsa/Session 19 Notes.txt | sudoers rules, runlevels to targets, root password reset | mapped | 04-users-and-access/sudo-and-su.md; 08-systemd-and-services/init-and-targets.md; 16-boot-and-recovery/recovery.md |
| rhcsa/Session 20 Notes.txt | GRUB password, ip addr, nmcli connection lifecycle, hostnamectl, nmtui | mapped | 16-boot-and-recovery/grub2.md (corrected to grub2-setpassword); 13-networking/interfaces-and-addresses.md; 13-networking/network-configuration.md |
| rhcsa/Session 20.1 Two Comp Network.png | Two-host lab network | mapped | labs/networking-lab.md |
| rhcsa/Session 21 Notes.txt | sshd_config options, ssh-keygen, ssh-copy-id, systemctl basics | mapped | 14-ssh-and-remote-access/sshd-server.md; 14-ssh-and-remote-access/ssh-client.md; 08-systemd-and-services/systemctl.md |
| rhcsa/Session 22 Notes.txt | scp, rsync, firewalld zones and rules | mapped | 14-ssh-and-remote-access/file-transfer.md; 15-security/firewalld-and-ufw.md |
| rhcsa/Session 23 Notes.txt | rpm queries and installs, yum/dnf, .repo files | mapped | 06-package-management/rpm-and-dnf.md; 06-package-management/repositories.md |
| rhcsa/Session 24 Notes.txt | Local HTTP repository server; NFS server and client | mapped | 06-package-management/repositories.md; 18-network-storage/nfs.md |
| rhcsa/Session 25 Notes.txt | DHCP server and DORA | deferred | Future network services folder; DORA as one line in reference/glossary.md |
| rhcsa/Session 25 Notes.txt | SELinux modes, getenforce, setenforce | mapped | 15-security/selinux.md |
| rhcsa/Session 26 Notes.txt | Apache virtual hosts | deferred | Future web servers folder (servers/) |
| rhcsa/Session 26 Notes.txt | SELinux contexts, chcon, restorecon, semanage fcontext, booleans | mapped | 15-security/selinux.md |
| rhcsa/Session 27 Notes.txt | HTTPS with mod_ssl, self-signed certificate, redirect | mapped | 15-security/openssl-and-trust-store.md (certificate commands); Apache config deferred to servers/ |
| NOTES/Session 28 Notes.txt | MariaDB installation and SQL basics | deferred | Future databases folder |
| NOTES/Session 28 Notes.txt | NIC teaming | mapped | 13-networking/bridges-bonds-vlans.md (documented as deprecated in RHEL 9) |
| NOTES/Session 29 Notes.txt to Session 36 Note.txt | Ansible (inventory, ad-hoc, ansible.cfg, playbooks, variables, handlers, vault, templates, roles) | deferred | Future Ansible tool folder |
| NOTES/29. ansible lab setup.png | Ansible lab diagram | deferred | Future Ansible tool folder |
| NOTES/Session 34.1 Note - subscription manager.txt | subscription-manager register, attach, unregister | mapped | 06-package-management/repositories.md |
| NOTES/Session 36.1 Notes - samba server config.txt | Samba server, smbpasswd, CIFS client with credentials file | mapped | 18-network-storage/samba-cifs.md (corrected to hosts allow) |
| NOTES/Session 37 Note.txt | Containers vs VMs, podman lifecycle | mapped | 19-containers/containers-vs-vms.md; 19-containers/podman-and-quadlet.md |
| NOTES/Session 38 Note.txt | podman commit, bind mounts, env vars; /var/log map | mapped | 19-containers/podman-and-quadlet.md; 09-logging/log-locations.md |
| NOTES/Session 39 Note.txt | tuned-adm, ps variants, top, kill, netstat, tcpdump, os-release, lshw, lscpu | mapped | 17-performance-and-troubleshooting/tuning.md; 07-processes/viewing-processes.md; 07-processes/signals.md; 13-networking/ports-and-sockets.md; 13-networking/packet-capture.md; 00-foundations/system-information.md |
| NOTES/Session 39 Note.txt | Resume points, mock interview notes | dropped | Career material, not Linux content |

---

## Assignments and Exam Practice

| Source | Topic | Status | Target |
|---|---|---|---|
| NOTES/Assignments/01. Assignment 1 .txt (+ Ans) | UIDs, users, groups, ACL, SGID collaboration directory | mapped | labs/users-and-permissions-lab.md; labs/rhcsa-style-tasks.md |
| NOTES/Assignments/02. Assignment 2 .txt (+ Ans) | Users, ACL, grep, find -exec, tar bz2 | mapped | labs/rhcsa-style-tasks.md |
| NOTES/Assignments/03. Assignment 3.txt | LVM and swap tasks | mapped | labs/storage-and-lvm-lab.md; labs/rhcsa-style-tasks.md |
| rhcsa/exam/Linux Notes/19.1 Assignment 1.txt | Hostname, users, tar, grep, ACL, SGID, find, cron, swap, LVM | mapped | labs/rhcsa-style-tasks.md |
| rhcsa/exam/44. Exam Practice Que.txt (RHCSA half) | 19 RHCSA tasks | mapped | labs/rhcsa-style-tasks.md |
| rhcsa/exam/44. Exam Practice Que.txt (RHCE half) | 15 Ansible tasks | deferred | Future Ansible tool folder |

---

## Slide PDFs and Extracted Notes Folder

| Source | Topic | Status | Target |
|---|---|---|---|
| rhcsa/01. Introduction To Linux.pdf | Linux history, advantages, client vs server OS, Red Hat | mapped | 00-foundations/what-is-linux.md; 00-foundations/distributions.md |
| rhcsa/03. File System Hierarchy.pdf | FHS directories, uname, whoami, history | mapped | 02-files-and-filesystem/filesystem-hierarchy.md |
| rhcsa/06.1 vim command.png | vim key reference | mapped | 01-shell-and-cli/text-editors.md |
| rhcsa/09.1basic permission.png | Permission bits diagram | mapped | 05-permissions/basic-permissions.md |
| Linux Notes/04, 05 (PDF) | mkdir, touch; vim | mapped | 02-files-and-filesystem/file-operations.md; 01-shell-and-cli/text-editors.md |
| Linux Notes/06 to 11 (PDF, txt) | Users, groups, permissions, ACL, special permissions, home directory change | mapped | 04-users-and-access/; 05-permissions/ |
| Linux Notes/12, 13, 14 (PDF) | Regular expressions, archives, job automation | mapped | 03-text-processing/grep-and-regex.md; 02-files-and-filesystem/archiving-and-compression.md; 10-scheduling/cron-and-at.md |
| Linux Notes/15 to 18 (PDF, png) | Disk management, swap, LVM, resize | mapped | 12-storage/ |
| Linux Notes/19 Sudo Command.pdf | sudo | mapped | 04-users-and-access/sudo-and-su.md |
| Linux Notes/20 Boot Process.pdf | Boot stages, targets | mapped | 16-boot-and-recovery/boot-process.md; 08-systemd-and-services/init-and-targets.md |
| Linux Notes/21 Grub Password.pdf | GRUB password | mapped | 16-boot-and-recovery/grub2.md |
| Linux Notes/22 Managing RHEL Networking.pdf | nmcli | mapped | 13-networking/network-configuration.md |
| Linux Notes/23 ssh config.pdf | sshd_config | mapped | 14-ssh-and-remote-access/sshd-server.md |
| Linux Notes/24 service and daemon.pdf | Process, daemon, service definitions | mapped | 07-processes/process-lifecycle.md; 08-systemd-and-services/systemctl.md |
| Linux Notes/25 Remote file transfer.pdf | scp, rsync | mapped | 14-ssh-and-remote-access/file-transfer.md |
| Linux Notes/26 Firewall Management.pdf | firewalld zones | mapped | 15-security/firewalld-and-ufw.md |
| Linux Notes/27 Package Management.pdf | rpm naming, install methods | mapped | 06-package-management/packaging-concepts.md |
| Linux Notes/28 yum server config.txt | Local repository server | mapped | 06-package-management/repositories.md |
| Linux Notes/29 NFS.pdf | NFS | mapped | 18-network-storage/nfs.md |
| Linux Notes/30 dhcp server.pdf | DHCP server | deferred | Future network services folder |
| Linux Notes/31, 36 (PDF) | SELinux basics and advanced | mapped | 15-security/selinux.md |
| Linux Notes/32 to 35, 34.1 (PDF, txt) | Apache, virtual hosting, HTTPS, redirect | deferred | Future web servers folder (servers/); certificate commands mapped to 15-security/openssl-and-trust-store.md |
| Linux Notes/37 MariaDB Configuration updated.pdf | MariaDB | deferred | Future databases folder |
| Linux Notes/38 NIC Teaming.pdf | Bonding vs teaming | mapped | 13-networking/bridges-bonds-vlans.md |
| Linux Notes/39 to 51 (PDF, png, txt) | Ansible | deferred | Future Ansible tool folder |
| Linux Notes/52, 53 (PDF, txt) | Running containers, container management steps | mapped | 19-containers/podman-and-quadlet.md |
| Linux Notes/54 Install and Update Package Using Official Repo.txt | Official repositories | mapped | 06-package-management/repositories.md |
| Linux Notes/55 System Log.pdf | /var/log map | mapped | 09-logging/log-locations.md |
| Linux Notes/56 Samba configuration.txt | Samba | mapped | 18-network-storage/samba-cifs.md |
| Linux Notes/57 System Tuning and Performance Monitor.pdf | tuned, ps, kill | mapped | 17-performance-and-troubleshooting/tuning.md; 07-processes/viewing-processes.md |
| Linux Notes/58 to 62 | Duplicates of exam/40, 41, 42, 43, 44 | dropped | Duplicates (verified with cmp) |
| Linux Notes/01, 02, 02.1, 03 | Duplicates of rhcsa/ files | dropped | Duplicates |

---

## Question Banks and Topic Lists

| Source | Topic | Status | Target |
|---|---|---|---|
| rhcsa/exam/40. Linux short interview questions.pdf | About 170 short questions in course order | mapped | Rewritten per topic into Interview Checkpoints and Must-Know Facts; Ansible, DHCP, MariaDB and Apache items deferred with their topics |
| rhcsa/exam/41. Linux InterviewQuestions.pdf: partitions, LVM, RAID, users, networking, SELinux, boot, jobs, SSH, swap, packages, backup, services, processes, NFS, autofs, Samba, NTP, troubleshooting sections | Long-form questions | mapped | Rewritten into checkpoints of the matching modules (12, 04, 05, 13, 15, 16, 10, 14, 06, 08, 07, 18, 17) and interview/scenarios/ |
| rhcsa/exam/41. Linux InterviewQuestions.pdf: Veritas VxVM/VCS, Red Hat Cluster, mail, FTP, LDAP server, DNS server, iSCSI target admin, Kickstart/PXE server | Legacy or server-admin sections | dropped | RHEL 6/7-era or out of scope; iSCSI client and Kickstart concepts covered in 18-network-storage/iscsi-and-nbd.md and 20-virtualization-and-provisioning/cloud-init-and-kickstart.md |
| rhcsa/exam/41. Linux InterviewQuestions.pdf: general, HR and incident management sections | Behavioural questions | dropped | Not Linux content |
| rhcsa/exam/42. Red Hat Imp Topics.pdf | RHCSA and RHCE objective list | mapped | reference/coverage-map.md |

---

## Other Files

| Source | Topic | Status | Target |
|---|---|---|---|
| rhcsa/exam/45. Linux Notes-2025.zip | Archive of the extracted Linux Notes folder | dropped | Duplicate of rhcsa/exam/Linux Notes/; kept here until the owner deletes it |
| rhcsa/exam/43. MG Resume fresher for cross check .docx (and Linux Notes/61) | Third-party resume | dropped | Not Linux content; to be moved out of the repository by the owner |
| Old Linux.md (removed) | LWN distribution list link (https://lwn.net/Distributions/) | mapped | 00-foundations/distributions.md |
