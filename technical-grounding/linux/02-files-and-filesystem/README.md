# Files and Filesystem

Where things live in the Linux tree, what a file really is on disk and in the kernel, and the everyday commands that create, find and bundle files.

---

## Revision Card

| Fact | Value |
|---|---|
| `/etc`, `/var`, `/usr` | Configuration, changing data, installed software |
| usrmerge | `/bin`, `/sbin`, `/lib` are symlinks into `/usr` |
| `/run`, `/proc`, `/sys` | tmpfs runtime data, kernel process view, kernel device view |
| `/tmp` vs `/var/tmp` | Short-lived vs kept across reboots; both mode 1777 |
| File types | `-` `d` `l` `c` `b` `p` `s` as the first `ls -l` character |
| Inode | Metadata and block pointers; no file name |
| Hard link | Same inode, same filesystem, not for directories |
| Symlink | Own inode holding a path; breaks when the target goes |
| `rm` | Unlinks a name; space returns at link count 0 and no open descriptors |
| `ctime` | Inode change time, not creation time |
| Descriptors | Per-process table, shared offsets after `fork()`, limit `ulimit -n` |
| `mv` | Rename on one filesystem, copy and delete across filesystems |
| `cp -a` | Keeps owner, mode, timestamps and links |
| `tar -f` | Names the archive; extraction detects compression |

| Task | Command |
|---|---|
| Where is a path mounted | `findmnt -T <path>` |
| File type and real content | `stat -c %F <path>`, `file <path>` |
| Inode and link count | `ls -li`, `stat <path>` |
| Inodes used | `df -i` |
| Deleted but open files | `sudo lsof +L1` |
| Open files of a process | `ls -l /proc/<pid>/fd`, `lsof -p <pid>` |
| Large files | `sudo find / -xdev -type f -size +1G` |
| Old files | `find <dir> -type f -mtime +30` |
| SUID files | `sudo find / -xdev -perm -4000` |
| Safe bulk action | `find ... -print0` into `xargs -0` |
| Create and extract an archive | `tar -czf out.tgz dir/`, `tar -xf out.tgz -C /target` |
| Atomic symlink switch | `ln -sfn <target> <link>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Filesystem Hierarchy](filesystem-hierarchy.md) | FHS directories, usrmerge, virtual filesystems, `/tmp` cleanup, where services keep files | Core | High |
| [File Types](file-types.md) | The seven types, device numbers, `file`, FIFOs and sockets | Core | Med |
| [Navigation and Listing](navigation-and-listing.md) | `cd`, `pwd -P`, `ls` sorting and formats | Core | Low |
| [File Operations](file-operations.md) | `mkdir`, `touch`, `cp -a`, `mv`, `rm`, sparse files, `dd`, `install`, `curl -f` | Core | Med |
| [Inodes and Links](inodes-and-links.md) | Inodes, hard and soft links, timestamps, inode exhaustion, deleted open files | Core | High |
| [File Descriptors](file-descriptors.md) | Descriptor tables, shared offsets, `dup2`, close-on-exec, open-file limits | Advanced | High |
| [Finding Files](finding-files.md) | `find` tests and actions, `xargs -0`, `locate`, `which`, `whereis` | Core | High |
| [Archiving and Compression](archiving-and-compression.md) | `tar`, compressor comparison, `zip`, `cpio` | Core | Med |

---

## Scenarios and Labs

- [Disk Full](../interview/scenarios/disk-full.md): deleted files that stay allocated while open
- [Round 4: Internals](../interview/round-4-internals.md): descriptors across `fork()` and `exec()`, what `rm` does
- [Error Messages](../reference/error-messages.md): filesystem errors from this module and their causes
