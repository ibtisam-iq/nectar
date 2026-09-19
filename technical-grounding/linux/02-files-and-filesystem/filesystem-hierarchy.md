# Filesystem Hierarchy

Linux uses one directory tree rooted at `/`, with each top-level directory reserved for a kind of data: configuration, logs, binaries, runtime state. The layout follows the Filesystem Hierarchy Standard (FHS) and systemd's `file-hierarchy(7)`, so the same paths work on every distribution.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| One tree | Disks, partitions and network shares are mounted into `/`; no drive letters | `findmnt` |
| `/etc` | Host-specific configuration, plain text | `ls /etc` |
| `/var` | Data that changes: logs, caches, spools, databases | `ls /var` |
| `/var/log` | Log files | `ls /var/log` |
| `/var/lib` | Persistent application state (package databases, Docker, databases) | `ls /var/lib` |
| `/usr` | Installed software, read-only in normal operation | `du -sh /usr` |
| usrmerge | `/bin`, `/sbin`, `/lib`, `/lib64` are symlinks into `/usr` | `ls -l /bin` |
| `/usr/local`, `/opt` | Software installed outside the package manager | `ls /usr/local` |
| `/tmp` vs `/var/tmp` | Both world-writable with the sticky bit; `/var/tmp` survives reboots and is cleaned less often, or never | `ls -ld /tmp /var/tmp` |
| `/run` | tmpfs for runtime data (PID files, sockets); emptied at boot | `findmnt /run` |
| `/proc`, `/sys` | Virtual filesystems exposing kernel and device state | `findmnt /proc` |
| `/dev` | Device files, created by the kernel and `udev` | `ls -l /dev/null` |
| `/boot` | Kernel, initramfs, bootloader files | `ls /boot` |
| `/root` vs `/home` | Root's home (mode 700) vs regular users' homes | `ls -ld /root /home` |
| References | `man 7 hier`, `man 7 file-hierarchy` | `man -w 7 hier` |
<!-- --8<-- [end:facts] -->

---

## Top-Level Directories

| Directory | Holds | Example |
|---|---|---|
| `/` | Root of the tree | |
| `/bin`, `/sbin` | Links to `/usr/bin`, `/usr/sbin` | `ls`, `ip` |
| `/boot` | Kernels, initramfs, GRUB | `vmlinuz-*`, `grub2/grub.cfg` |
| `/dev` | Device nodes | `/dev/sda`, `/dev/null` |
| `/etc` | Configuration | `/etc/ssh/sshd_config`, `/etc/fstab` |
| `/home` | User home directories | `/home/amor` |
| `/lib`, `/lib64` | Links to shared libraries and kernel modules in `/usr` | `libc.so.6` |
| `/media`, `/mnt` | Mount points for removable media / temporary mounts | `/mnt/backup` |
| `/opt` | Self-contained third-party software | `/opt/google/chrome` |
| `/proc` | Processes and kernel tunables | `/proc/cpuinfo`, `/proc/sys` |
| `/root` | Root user's home | `/root/.bashrc` |
| `/run` | Runtime state since boot | `/run/sshd.pid`, `/run/docker.sock` |
| `/srv` | Data served by the host | `/srv/www`, `/srv/nfs` |
| `/sys` | Devices, drivers, cgroups | `/sys/class/net`, `/sys/fs/cgroup` |
| `/tmp` | Short-lived temporary files | Build scratch files |
| `/usr` | Programs, libraries, documentation | `/usr/bin`, `/usr/share/man` |
| `/var` | Variable data | `/var/log`, `/var/lib`, `/var/spool` |

---

## usrmerge

Both families moved `/bin`, `/sbin` and `/lib` into `/usr` and left symlinks behind, so `/bin/bash` and `/usr/bin/bash` are the same file.

```bash
ls -l / | grep -E ' (bin|sbin|lib|lib64)( |$)'
```

Output:

```text
lrwxrwxrwx   1 root root     7 Apr 22  2024 bin -> usr/bin
lrwxrwxrwx   1 root root     7 Apr 22  2024 lib -> usr/lib
lrwxrwxrwx   1 root root     9 Apr 22  2024 lib64 -> usr/lib64
lrwxrwxrwx   1 root root     8 Apr 22  2024 sbin -> usr/sbin
```

A read-only or separately snapshotted `/usr` now contains every system binary, which image-based systems (RHEL image mode, Fedora CoreOS) rely on.

---

## Virtual Filesystems

Several top-level paths are not on disk. The kernel generates their contents on read.

```bash
for d in / /boot /tmp /var/tmp /run /dev /dev/shm /proc /sys; do findmnt -n -o TARGET,FSTYPE -T "$d"; done | sort -u
```

Output:

```text
/      ext4
/dev   devtmpfs
/dev/shm tmpfs
/proc  proc
/run   tmpfs
/sys   sysfs
```

On this machine `/boot`, `/tmp` and `/var/tmp` belong to the root filesystem, so they do not appear as separate mounts.

| Filesystem | Mounted on | Backed by | Survives reboot |
|---|---|---|---|
| `proc` | `/proc` | Kernel process table | No (generated) |
| `sysfs` | `/sys` | Kernel device model | No (generated) |
| `devtmpfs` | `/dev` | Kernel device list | No |
| `tmpfs` | `/run`, `/dev/shm`, often `/tmp` | RAM and swap | No |

!!! warning "Files in a tmpfs use memory"
    A large file written to `/dev/shm`, `/run` or a tmpfs `/tmp` consumes RAM and counts against memory limits. `df -h /run` shows the size cap (by default half of RAM for `/dev/shm`).

---

## /tmp and /var/tmp

```bash
ls -ld /tmp /var/tmp /run /root /home
```

Output:

```text
drwxr-xr-x  4 root root 4096 Aug 29 18:08 /home
drwx------  5 root root 4096 Aug 29 18:08 /root
drwxr-xr-x 15 root root  440 Sep 16 13:24 /run
drwxrwxrwt 12 root root 4096 Sep 16 13:50 /tmp
drwxrwxrwt  5 root root 4096 Sep 16 13:41 /var/tmp
```

The trailing `t` is the sticky bit: anyone can create files, but only the owner can delete them. `systemd-tmpfiles-clean.timer` removes old files daily, following the rules in `tmpfiles.d`:

=== "RHEL / Rocky"

    ```bash
    grep -v '^#' /usr/lib/tmpfiles.d/tmp.conf | grep .
    systemctl is-enabled tmp.mount
    ```

    Output:

    ```text
    q /tmp 1777 root root 10d
    q /var/tmp 1777 root root 30d
    disabled
    ```

=== "Ubuntu / Debian"

    ```bash
    grep -v '^#' /usr/lib/tmpfiles.d/tmp.conf | grep .
    ```

    Output:

    ```text
    D /tmp 1777 root root 30d
    ```

    `D` also empties `/tmp` at every boot. Ubuntu ships the `/var/tmp` line commented out (`#q /var/tmp 1777 root root 30d`), so files in `/var/tmp` never age out by default.

Files older than the age column (`10d`, `30d`) are removed. `tmp.mount` disabled means `/tmp` is on disk here; when it is enabled, `/tmp` is a tmpfs and empties at every reboot.

---

## Where a Service Keeps Its Files

A package spreads one service across the tree by purpose:

=== "RHEL / Rocky"

    ```bash
    rpm -ql openssh-server | grep -E '^/(etc/ssh/sshd_config|usr/sbin/sshd|usr/lib/systemd/system/sshd.service|usr/share/man/man8/sshd.8)'
    ```

    Output:

    ```text
    /etc/ssh/sshd_config
    /etc/ssh/sshd_config.d
    /etc/ssh/sshd_config.d/40-redhat-crypto-policies.conf
    /etc/ssh/sshd_config.d/50-redhat.conf
    /usr/lib/systemd/system/sshd.service
    /usr/sbin/sshd
    /usr/share/man/man8/sshd.8.gz
    ```

=== "Ubuntu / Debian"

    ```bash
    dpkg -L openssh-server | grep -E '^/(etc/ssh/sshd_config|usr/sbin/sshd|usr/lib/systemd/system/ssh.service|usr/share/man/man8/sshd)'
    dpkg -S /etc/ssh/sshd_config
    ```

    Output:

    ```text
    /etc/ssh/sshd_config.d
    /usr/lib/systemd/system/ssh.service
    /usr/sbin/sshd
    /usr/share/man/man8/sshd.8.gz
    dpkg-query: no path found matching pattern /etc/ssh/sshd_config
    ```

    Ubuntu generates `sshd_config` from a template during installation, so no package owns it.

| Kind of file | Location | Example for nginx |
|---|---|---|
| Binary | `/usr/sbin`, `/usr/bin` | `/usr/sbin/nginx` |
| Configuration | `/etc/<app>` | `/etc/nginx/nginx.conf` |
| Vendor unit file | `/usr/lib/systemd/system` | `nginx.service` |
| Admin unit override | `/etc/systemd/system` | `nginx.service.d/override.conf` |
| Logs | `/var/log/<app>` | `/var/log/nginx/access.log` |
| State and caches | `/var/lib/<app>`, `/var/cache/<app>` | `/var/lib/nginx` |
| Runtime files | `/run/<app>` | `/run/nginx.pid` |
| Served content | `/srv`, `/var/www` | `/usr/share/nginx/html` (RHEL default) |

`systemd-path` prints the canonical locations:

```bash
systemd-path | grep -E '^(system-configuration|system-state-private|system-state-logs|system-runtime|system-shared|temporary|temporary-large|system-binaries|user-configuration):'
```

Output:

```text
temporary: /tmp
temporary-large: /var/tmp
system-binaries: /usr/bin
system-shared: /usr/share
system-configuration: /etc
system-runtime: /run
system-state-private: /var/lib
system-state-logs: /var/log
user-configuration: /home/laborant/.config
```

!!! tip "Back up /etc and /var/lib, not /usr"
    `/usr` can be reinstalled from packages. Host identity and data live in `/etc`, `/var/lib`, `/home`, `/srv` and `/opt`, which is what a backup or migration plan must cover.

---

## Space by Directory

```bash
sudo du -xsh /usr /var /etc /opt
ls /var
```

Output:

```text
1.6G	/usr
88M	/var
2.9M	/etc
24K	/opt
backups
cache
lib
local
lock
log
mail
opt
run
spool
tmp
```

`/var` is the directory that grows. Servers often give `/var` or `/var/log` their own filesystem, so runaway logs cannot fill `/`.

---

## Common Errors

### `No space left on device` while `df -h /` shows free space

**Cause:** the write went to a different filesystem (a small `/var`, `/tmp` or `/boot`), or the filesystem ran out of inodes.

**Fix:** `df -h <path>` and `df -i <path>` for the exact directory being written.

### `dpkg-query: no path found matching pattern /etc/ssh/sshd_config`

**Cause:** the file is created by a maintainer script, so the package database does not list it.

**Fix:** find the package through its directory (`dpkg -S /etc/ssh/sshd_config.d`) or through `debsums -c`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between /etc, /var and /usr?"
    **Say first:** `/etc` holds configuration, `/var` holds data that changes at runtime, and `/usr` holds installed programs and libraries that change only on updates.

    **Proof:** `ls /etc/ssh`, `ls /var/log`, `rpm -qf /usr/sbin/sshd`.

    **Follow-up:** Which of them do you need to back up?

??? question "L1: What is the difference between /tmp and /var/tmp?"
    **Say first:** both are world-writable with the sticky bit; `/tmp` is for short-lived files and may be a tmpfs, while `/var/tmp` persists across reboots and is cleaned less often.

    **Proof:** `grep -v '^#' /usr/lib/tmpfiles.d/tmp.conf`

    **Follow-up:** What does the sticky bit prevent?

??? question "L1: What are /proc and /sys?"
    **Say first:** virtual filesystems generated by the kernel: `/proc` exposes processes and tunables, `/sys` exposes devices, drivers and cgroups.

    **Proof:** `findmnt -T /proc`, `cat /proc/loadavg`, `ls /sys/class/net`.

    **Follow-up:** Why does `du -sh /proc` report nothing useful?
<!-- --8<-- [end:l1] -->

??? question "L2: Find where a service keeps its configuration, logs and unit file."
    **Say first:** ask the package manager, then systemd.

    **Proof:** `rpm -ql openssh-server` or `dpkg -L openssh-server`; `systemctl cat sshd`.

    **Follow-up:** Which files in that list are safe to edit, and which are overwritten on update?

??? question "L2: Where should a manually installed binary go, and why?"
    **Say first:** `/usr/local/bin` for a single binary, `/opt/<app>` for a self-contained bundle; the package manager never touches either.

    **Proof:** `echo $PATH` contains `/usr/local/bin` before `/usr/bin`.

    **Follow-up:** Why not `/usr/bin`?

??? question "L3: The root filesystem is full on a web server."
    **Say first:** find which directory grew, starting with `/var`, and whether it is a separate filesystem.

    **Proof:** `df -h`, then `sudo du -xh --max-depth=1 / | sort -h`, then `du` inside `/var/log` and `/var/lib`.

    **Follow-up:** How would you prevent a repeat? (A separate `/var/log`, log rotation, journal size limits.)

??? question "L3: An application loses its PID and socket files after every reboot."
    **Say first:** it writes them to `/run`, which is a tmpfs recreated at boot.

    **Proof:** `findmnt /run` shows `tmpfs`; the unit needs `RuntimeDirectory=` or a `tmpfiles.d` entry to recreate its directory.

    **Follow-up:** Where should data that must survive a reboot go?

??? question "L4: Why did distributions merge /bin into /usr/bin?"
    **Say first:** splitting early-boot tools from `/usr` stopped making sense once an initramfs mounts `/usr` before switching root; merging lets `/usr` be one read-only, snapshottable unit.

    **Proof:** `ls -l /bin` shows `bin -> usr/bin` on RHEL since version 7 and on Ubuntu installs since 19.04.

    **Don't say:** "To save disk space."

---

## Related

- [File Types](file-types.md): device files in `/dev`
- [Inodes and Links](inodes-and-links.md): what the `usrmerge` symlinks are
- [System Information](../00-foundations/system-information.md): reading `/proc` and `/sys`

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
