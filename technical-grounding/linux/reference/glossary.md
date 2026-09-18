# Glossary

One-line definitions of the Linux terms used across this folder. Each entry links to the topic that explains it in full.

---

## A to D

| Term | Definition |
|---|---|
| ACL | Access control list: per-user and per-group permissions beyond the owner, group and other bits. See [ACL](../05-permissions/acl.md). |
| Ambient capability | A capability an executable keeps across `execve` without a file capability, used to run a service without full root. See [Capabilities](../15-security/capabilities.md). |
| AppArmor | A path-based Linux Security Module, the default confinement on Ubuntu. See [AppArmor](../15-security/apparmor.md). |
| Backporting | Applying a security fix to an older package version while keeping its version number, common on RHEL. See [Compliance and Integrity](../15-security/compliance-and-integrity.md). |
| Bind mount | Mounting an existing directory at a second path so both show the same files. See [Mounting and fstab](../12-storage/mounting-and-fstab.md). |
| Capability | One slice of root's power (for example `CAP_NET_BIND_SERVICE`), granted to a process or file instead of full root. See [Capabilities](../15-security/capabilities.md). |
| cgroup | Control group: a kernel feature that limits and accounts CPU, memory and I/O for a set of processes. See [Cgroups](../19-containers/cgroups.md). |
| chroot | Running a process with a different root directory, an early form of filesystem isolation. See [Overlayfs and chroot](../19-containers/overlayfs-and-chroot.md). |
| COW | Copy-on-write: sharing a memory page or filesystem block until one side writes, then copying it. See [Process Lifecycle](../07-processes/process-lifecycle.md). |
| Daemon | A long-running background process, usually started by systemd and detached from a terminal. See [Process Lifecycle](../07-processes/process-lifecycle.md). |
| Demand paging | Loading a page of memory from disk only when it is first accessed. See [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md). |
| DORA | The DHCP handshake: Discover, Offer, Request, Acknowledge, by which a client leases an address. See [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md). |
| D state | Uninterruptible sleep: a process waiting on I/O that cannot be killed until the wait ends. See [Process States](../07-processes/process-states.md). |

---

## E to L

| Term | Definition |
|---|---|
| ELF | Executable and Linkable Format: the binary format of Linux programs and shared libraries. See [Shared Libraries](../06-package-management/shared-libraries.md). |
| Ephemeral port | A short-lived source port the kernel assigns to an outgoing connection. See [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md). |
| fd | File descriptor: a small integer a process uses to refer to an open file, socket or pipe. See [File Descriptors](../02-files-and-filesystem/file-descriptors.md). |
| FHS | Filesystem Hierarchy Standard: the agreed meaning of `/etc`, `/var`, `/usr` and the rest. See [Filesystem Hierarchy](../02-files-and-filesystem/filesystem-hierarchy.md). |
| fork | The system call that creates a new process by duplicating the caller. See [Process Lifecycle](../07-processes/process-lifecycle.md). |
| GID | Group ID: the numeric identifier of a group. See [Groups](../04-users-and-access/groups.md). |
| GPT | GUID Partition Table: the modern partition scheme that replaces MBR. See [Partitioning](../12-storage/partitioning.md). |
| Hard link | A second directory entry pointing at the same inode as an existing file. See [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md). |
| initramfs | A temporary root filesystem the kernel uses early in boot to find and mount the real root. See [Boot Process](../16-boot-and-recovery/boot-process.md). |
| inode | The on-disk structure holding a file's metadata and block pointers, but not its name. See [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md). |
| IQN | iSCSI Qualified Name: the identifier of an iSCSI target or initiator. See [iSCSI and NBD](../18-network-storage/iscsi-and-nbd.md). |
| Journaling | A filesystem technique that records pending changes so a crash leaves the filesystem consistent. See [Filesystems](../12-storage/filesystems.md). |
| Kernel space | The privileged execution mode where the kernel runs, separate from user space. See [Architecture](../00-foundations/architecture.md). |
| LSM | Linux Security Module: the kernel framework that SELinux and AppArmor plug into. See [SELinux](../15-security/selinux.md). |
| LUKS | Linux Unified Key Setup: the standard for block-device encryption. See [RAID and Encryption](../12-storage/raid-and-encryption.md). |
| LVM | Logical Volume Manager: an abstraction over disks that allows flexible, resizable volumes. See [LVM](../12-storage/lvm.md). |

---

## M to R

| Term | Definition |
|---|---|
| MBR | Master Boot Record: the legacy partition scheme, limited to 2 TiB and four primary partitions. See [Partitioning](../12-storage/partitioning.md). |
| mmap | Mapping a file or anonymous memory into a process address space. See [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md). |
| Namespace | A kernel feature that gives a process its own view of a resource such as PIDs, mounts or the network. See [Namespaces](../19-containers/namespaces.md). |
| netfilter | The kernel packet-filtering framework behind `nftables` and `iptables`. See [nftables and iptables](../15-security/nftables-and-iptables.md). |
| NFS | Network File System: a protocol for mounting a remote directory as a local filesystem. See [NFS](../18-network-storage/nfs.md). |
| OOM killer | The kernel routine that kills a process when memory is exhausted. See [Memory](../17-performance-and-troubleshooting/memory.md). |
| Orphan | A process whose parent has exited, reparented to PID 1. See [Process States](../07-processes/process-states.md). |
| Overcommit | The kernel granting more virtual memory than physically exists, on the bet that not all is used. See [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md). |
| overlayfs | A union filesystem that stacks a writable layer over read-only layers, the basis of container images. See [Overlayfs and chroot](../19-containers/overlayfs-and-chroot.md). |
| PAM | Pluggable Authentication Modules: the stack that decides how logins authenticate. See [PAM](../04-users-and-access/pam.md). |
| Page cache | Kernel memory holding recently read file data, counted as `buff/cache` in `free`. See [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md). |
| PID | Process ID: the numeric identifier of a running process. See [Process Fundamentals](../07-processes/process-fundamentals.md). |
| PID 1 | The first process, `init` or systemd, which adopts orphans and reaps them. See [Process Fundamentals](../07-processes/process-fundamentals.md). |
| PV, VG, LV | Physical volume, volume group and logical volume: the three LVM layers. See [LVM](../12-storage/lvm.md). |
| Reaping | A parent collecting a dead child's exit status with `wait`, clearing the zombie. See [Process Lifecycle](../07-processes/process-lifecycle.md). |
| RSS | Resident set size: the physical memory a process currently occupies. See [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md). |

---

## S to Z

| Term | Definition |
|---|---|
| SELinux | Security-Enhanced Linux: a label-based mandatory access control system, enforcing by default on RHEL. See [SELinux](../15-security/selinux.md). |
| setgid | A permission bit that runs a file with its group, or makes new files in a directory inherit the group. See [Special Permissions](../05-permissions/special-permissions.md). |
| setuid | A permission bit that runs a file with the owner's identity rather than the caller's. See [Special Permissions](../05-permissions/special-permissions.md). |
| Signal | An asynchronous notification sent to a process, such as `SIGTERM` or `SIGKILL`. See [Signals](../07-processes/signals.md). |
| Socket | An endpoint for communication, over the network or between local processes. See [Ports and Sockets](../13-networking/ports-and-sockets.md). |
| Soft link | A symbolic link: a small file holding the path of another file. See [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md). |
| Sticky bit | A directory bit that lets only a file's owner delete it, used on `/tmp`. See [Special Permissions](../05-permissions/special-permissions.md). |
| subuid, subgid | Ranges of host UIDs and GIDs mapped into a rootless container's user namespace. See [Podman and Quadlet](../19-containers/podman-and-quadlet.md). |
| Swap | Disk space used to hold memory pages when RAM is under pressure. See [Swap](../12-storage/swap.md). |
| Syscall | System call: the interface a program uses to ask the kernel for a service. See [System Calls and Tracing](../07-processes/system-calls-and-tracing.md). |
| systemd | The init system and service manager on modern distributions, PID 1 on boot. See [systemctl](../08-systemd-and-services/systemctl.md). |
| Target | A systemd unit that groups other units to reach a system state, replacing runlevels. See [Init and Targets](../08-systemd-and-services/init-and-targets.md). |
| tmpfs | A filesystem that lives in memory, used for `/run` and `/dev/shm`. See [proc and sys](../11-kernel-and-hardware/proc-and-sys.md). |
| UID | User ID: the numeric identifier of a user account. See [Users](../04-users-and-access/users.md). |
| Unit | The basic object systemd manages: a service, socket, mount, timer or target. See [Unit Files](../08-systemd-and-services/unit-files.md). |
| User space | The unprivileged execution mode where applications run, separate from kernel space. See [Architecture](../00-foundations/architecture.md). |
| UUID | Universally unique identifier, used to name a filesystem in `/etc/fstab` regardless of device order. See [Mounting and fstab](../12-storage/mounting-and-fstab.md). |
| veth | A virtual Ethernet pair, one end in a namespace and one on a bridge, that connects containers. See [Namespaces](../19-containers/namespaces.md). |
| VSZ | Virtual size: the total address space a process has mapped, most of it not resident. See [Virtual Memory](../17-performance-and-troubleshooting/virtual-memory.md). |
| Zombie | A process that has exited but whose exit status the parent has not yet reaped. See [Process States](../07-processes/process-states.md). |

---

## Related

- [Must-Know Facts](must-know-facts.md): the facts tables these terms come from
- [Command Index](command-index.md): the commands that manage these objects
- [Important Files](important-files.md): the configuration files behind these terms
