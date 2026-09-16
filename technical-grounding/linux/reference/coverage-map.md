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
