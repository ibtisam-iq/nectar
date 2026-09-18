# Round 4: Internals

Senior, SRE and production engineering loops ask what happens underneath a command: which system calls run, which kernel structures change, and why the design trades one property for another. Each question links to the topic file that answers it.

---

## Foundations

| Question | Answered in |
|---|---|
| What happens between typing `ls` and seeing the output? | [Architecture](../00-foundations/architecture.md) |
| A container needs a kernel feature the host lacks. What happens? | [Kernel vs OS vs Distro](../00-foundations/kernel-vs-os-vs-distro.md) |

---

## Shell and CLI

| Question | Answered in |
|---|---|
| What does the shell do when a command is typed and Enter is pressed? | [Shell Basics](../01-shell-and-cli/shell-basics.md) |
| What does the kernel do when `execve` gets a text file? | [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| How does a program receive its environment, and why can't a child change the parent's? | [Variables and Environment](../01-shell-and-cli/variables-and-environment.md) |
| In what order does bash expand a command line? | [Quoting and Expansion](../01-shell-and-cli/quoting-and-expansion.md) |
| How does the shell implement `2>&1` and a pipe? | [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md) |
| How does a parent process learn a child's exit status? | [Exit Codes and Chaining](../01-shell-and-cli/exit-codes-and-chaining.md) |

---

## Files and Filesystem

| Question | Answered in |
|---|---|
| What happens to open files across `fork()` and `exec()`? | [File Descriptors](../02-files-and-filesystem/file-descriptors.md) |
| What are the kernel structures behind a file descriptor? | [File Descriptors](../02-files-and-filesystem/file-descriptors.md) |
| What happens on disk when `rm` runs on a file that a process still has open? | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| Why did distributions merge `/bin` into `/usr/bin`? | [Filesystem Hierarchy](../02-files-and-filesystem/filesystem-hierarchy.md) |

---

## Users and Access

| Question | Answered in |
|---|---|
| How does `sudo` get root privileges, and how does `passwd` update a root-only file? | [Sudo and Su](../04-users-and-access/sudo-and-su.md) |
| `ls -l` prints owner names, but inodes store only UIDs. Where do the names come from? | [Users](../04-users-and-access/users.md) |
| Where does a process get its group list, and why can't it see a new group? | [Groups](../04-users-and-access/groups.md) |
| Why do modern systems hash passwords with yescrypt instead of a fast hash? | [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| What is the difference between `required` and `requisite` in PAM? | [PAM](../04-users-and-access/pam.md) |
| Why does `/var/log/lastlog` look large on a server with three users? | [Login Sessions](../04-users-and-access/login-sessions.md) |
| Why keep a local admin account when all users come from LDAP? | [Centralized Identity](../04-users-and-access/centralized-identity.md) |

---

## Permissions

| Question | Answered in |
|---|---|
| How does `passwd` update `/etc/shadow` when a normal user runs it? | [Special Permissions](../05-permissions/special-permissions.md) |

---

## Package Management

| Question | Answered in |
|---|---|
| What happens between `execve` and `main` for a dynamically linked program? | [Shared Libraries](../06-package-management/shared-libraries.md) |

---

## Processes

| Question | Answered in |
|---|---|
| What happens between typing `ls` and the prompt returning? | [Process Lifecycle](../07-processes/process-lifecycle.md) |
| Why does `fork()` not double memory usage? | [Process Lifecycle](../07-processes/process-lifecycle.md) |
| Why can Linux use one system call for both processes and threads? | [Process Fundamentals](../07-processes/process-fundamentals.md) |
| What happens in the kernel between `kill -TERM` and the handler running? | [Signals](../07-processes/signals.md) |
| Why does Linux count D-state tasks in the load average? | [Process States](../07-processes/process-states.md) |
| What happens at the CPU and kernel level when a program calls `read()`? | [System Calls and Tracing](../07-processes/system-calls-and-tracing.md) |
| Why don't time functions appear in `strace` output? | [System Calls and Tracing](../07-processes/system-calls-and-tracing.md) |

---

## Systemd and Services

| Question | Answered in |
|---|---|
| How does systemd know which processes belong to a service? | [Unit Files](../08-systemd-and-services/unit-files.md) |

---

## Networking

| Question | Answered in |
|---|---|
| What does the kernel do between a client's `connect()` and the server's `accept()`? | [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md) |
| Why does `TIME_WAIT` exist, and why does it last 60 seconds on Linux? | [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md) |
| Why can a server have established connections that the application never accepted? | [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md) |

## Security

| Question | Answered in |
|---|---|
| What happens inside the kernel when nginx opens a file on an SELinux system? | [SELinux](../15-security/selinux.md) |
| How does a service end up in its own SELinux domain? | [SELinux](../15-security/selinux.md) |

---

## Boot and Recovery

| Question | Answered in |
|---|---|
| What is the difference between a kernel oops and a kernel panic, and when does one become the other? | [Kernel Panic](../16-boot-and-recovery/kernel-panic.md) |
| A panic leaves nothing in `journalctl`: how do you still capture the cause? | [Kernel Panic](../16-boot-and-recovery/kernel-panic.md) |

---

## Performance and Troubleshooting

| Question | Answered in |
|---|---|
| A program `malloc`s 2 GB, it succeeds, then the process is killed: explain. | [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md) |
| What happens in the kernel when a process touches a never-accessed heap page? | [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md) |
| How does `perf` sampling differ from `strace` tracing, and why does overhead differ? | [Profiling and Tracing](../17-performance-and-troubleshooting/profiling-and-tracing.md) |

---

## Containers

| Question | Answered in |
|---|---|
| How does a rootless container let root inside map to a normal user outside? | [Namespaces](../19-containers/namespaces.md) |
| What keeps a namespace alive after the process that created it exits? | [Namespaces](../19-containers/namespaces.md) |
| How does the kernel enforce a memory limit, and what happens at the cap? | [Cgroups](../19-containers/cgroups.md) |
| Why can a kernel vulnerability affect every container on a host but not every VM? | [Containers vs VMs](../19-containers/containers-vs-vms.md) |

---

## How to Answer

- Start from the mechanism (the SUID bit, the NSS lookup, the credentials stored per process), then show the evidence (`ls -l`, `/proc/<pid>/status`).
- Name the trade-off: speed against safety, caching against freshness.
- Stop when the interviewer stops asking; depth on request beats a lecture.
