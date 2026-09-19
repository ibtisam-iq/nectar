# proc and sys

`/proc` and `/sys` are virtual filesystems through which the kernel exposes its state: processes, memory, devices, drivers and tunable parameters. Most monitoring tools (`ps`, `free`, `top`, `lsblk`, `ip`) only read and format these files, so they remain available when the tools are not.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `/proc` | procfs: one directory per PID plus system-wide files | `mount -t proc` |
| `/proc/sys` | Writable kernel parameters, managed by `sysctl` | `ls /proc/sys` |
| `/sys` | sysfs: the device and driver model, one value per file | `ls /sys/class/net` |
| `/dev` | devtmpfs: device nodes, populated by the kernel and udev | `mount -t devtmpfs` |
| `/run`, `/dev/shm` | tmpfs: memory-backed, cleared at reboot | `df -h -t tmpfs` |
| File sizes | Most files show size 0 (procfs) or 4096 (sysfs); content is generated on read | `ls -l /proc/meminfo` |
| Memory | `/proc/meminfo` (`free` reads it) | `grep MemAvailable /proc/meminfo` |
| CPU | `/proc/cpuinfo`, `/proc/loadavg`, `/proc/stat` | `nproc` |
| Kernel | `/proc/version`, `/proc/cmdline`, `/proc/modules`, `/proc/config.gz` if built in | `uname -r` |
| Storage | `/proc/partitions`, `/proc/mounts`, `/sys/block/<dev>/` | `lsblk` |
| Network | `/proc/net/tcp`, `/sys/class/net/<if>/` | `ss`, `ip link` |
| Writing | Needs root for most files; `sudo echo x > file` fails because the shell opens the file | `sudo tee file` with the value on standard input |
| Persistence | Writes last until reboot; persistent settings go in `sysctl.d` or udev rules | `sysctl --system` |
| Per-process files | `/proc/<pid>/status`, `cmdline`, `environ`, `fd/`, `limits`, `maps`, `cgroup` | `cat /proc/self/status` |
<!-- --8<-- [end:facts] -->

---

## The Virtual Filesystems

```bash
mount | grep -E "^(proc|sysfs|devtmpfs|tmpfs|cgroup)" 
df -h -t proc -t sysfs -t tmpfs -t devtmpfs
```

Output:

```text
devtmpfs on /dev type devtmpfs (rw,relatime,size=4102088k,nr_inodes=1025522,mode=755)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev)
tmpfs on /run type tmpfs (rw,nosuid,nodev,size=1642580k,nr_inodes=819200,mode=755)
cgroup2 on /sys/fs/cgroup type cgroup2 (rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot)
tmpfs on /run/user/1001 type tmpfs (rw,nosuid,nodev,relatime,size=821288k,nr_inodes=205322,mode=700,uid=1001,gid=1001)
tmpfs on /run/user/0 type tmpfs (rw,nosuid,nodev,relatime,size=821288k,nr_inodes=205322,mode=700)
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        4.0G     0  4.0G   0% /dev
tmpfs           4.0G     0  4.0G   0% /dev/shm
tmpfs           1.6G  268K  1.6G   1% /run
tmpfs           803M  8.0K  803M   1% /run/user/1001
tmpfs           803M  8.0K  803M   1% /run/user/0
```

`df` does not list `proc` and `sysfs` because they have no blocks. The `tmpfs` sizes are upper limits; the memory is used only when files are written.

| | `/proc` | `/sys` |
|---|---|---|
| **Filesystem** | procfs | sysfs |
| **Organized by** | Process ID, plus legacy system files | Kernel object: bus, class, device, module |
| **Format** | Multi-line text, often tables | One value per file |
| **Writable parts** | `/proc/sys/*`, some per-process files | Device and driver attributes, module parameters |
| **Typical readers** | `ps`, `top`, `free`, `sysctl` | `lsblk`, `ip`, `udevadm`, `lspci` |

---

## Size Zero Files

procfs files report size 0 because their content is generated at read time. Tools that trust the size, such as `ls -l` or a copy that preallocates, give misleading results.

```bash
ls -l /proc/meminfo; wc -c /proc/meminfo; stat -c "%s %n" /proc/version /sys/block/vda/size
grep -E "^(MemTotal|MemAvailable|SwapTotal|Dirty)" /proc/meminfo
cat /proc/version
```

Output:

```text
-r--r--r-- 1 root root 0 Sep 17 05:43 /proc/meminfo
1475 /proc/meminfo
0 /proc/version
4096 /sys/block/vda/size
MemTotal:        8212896 kB
MemAvailable:    7690660 kB
SwapTotal:             0 kB
Dirty:               496 kB
Linux version 6.1.167 (root@buildkitsandbox) (gcc (Ubuntu 11.5.0-1ubuntu1~24.04.1) 11.5.0, GNU ld (GNU Binutils for Ubuntu) 2.42) #1 SMP PREEMPT_DYNAMIC Thu Apr 16 10:07:08 UTC 2026
```

The playground kernel was built by iximiuz Labs, not by Rocky Linux, which is why `/proc/version` names an Ubuntu compiler.

---

## System-Wide Files in /proc

| File | Content | Tool that reads it |
|---|---|---|
| `/proc/meminfo` | Memory counters | `free`, `vmstat` |
| `/proc/cpuinfo` | One block per logical CPU | `lscpu`, `nproc` |
| `/proc/loadavg` | 1, 5, 15 minute load, running/total tasks, last PID | `uptime` |
| `/proc/uptime` | Seconds since boot, idle seconds summed over CPUs | `uptime` |
| `/proc/stat` | CPU time counters, context switches, boot time | `top`, `mpstat` |
| `/proc/cmdline` | Kernel boot parameters | GRUB checks |
| `/proc/mounts` | Mounted filesystems (link to `self/mounts`) | `findmnt`, `mount` |
| `/proc/partitions` | Block devices and sizes in 1K blocks | `lsblk` |
| `/proc/filesystems` | Filesystem types the kernel supports | `mount -t` |
| `/proc/interrupts` | Interrupts per CPU and device | `irqbalance` checks |
| `/proc/modules` | Loaded modules | `lsmod` |
| `/proc/net/tcp` | TCP sockets in hex | `ss`, `netstat` |
| `/proc/sys/fs/file-nr` | Allocated, unused and maximum file handles | `sysctl fs.file-nr` |

```bash
tr " " "\n" < /proc/cmdline | grep -v -e random_seed -e "^ip="
cat /proc/partitions; cat /sys/block/vda/size /sys/block/vda/queue/rotational /sys/block/vda/queue/scheduler
head -5 /proc/interrupts | cut -c1-90
```

Output:

```text
reboot=k
panic=1
i8042.noaux
i8042.nomux
i8042.dumbkbd
net.ifnames=0
bonding.max_bonds=0
dummy.numdummies=0
console=ttyS0
8250.nr_uarts=1
swiotlb=noforce
raid=noautodetect
random.trust_cpu=on
root=/dev/vda
rw
major minor  #blocks  name

 253        0   83886096 vda
167772192
1
[mq-deadline] kyber bfq none
           CPU0       CPU1       CPU2       CPU3       
 24:          0          0          0          0   IO-APIC   5-edge      ACPI:Ged
 25:          0          0          0          0   IO-APIC   6-edge      ACPI:Ged
 26:          0        350          0          0   IO-APIC   4-edge      ttyS0
 27:          0          0          0          0   IO-APIC   1-edge      i8042
```

The `grep -v` removes a random seed and the VM's address from the command line. `/sys/block/vda/size` counts 512-byte sectors (167772192 sectors is 80 GiB), and the brackets in `scheduler` mark the active I/O scheduler.

!!! note "/proc still answers when tools are missing"
    On a minimal container image without `ps` or `free`, `cat /proc/loadavg`, `grep MemAvailable /proc/meminfo` and `cat /proc/[0-9]*/comm` give the same answers.

---

## Devices and Drivers in /sys

`/sys/class` groups devices by type, and each entry is a symlink into `/sys/devices`, which follows the physical bus layout.

```bash
readlink /sys/class/net/eth0 /sys/block/vda
cat /sys/class/net/eth0/address /sys/class/net/eth0/mtu /sys/class/net/eth0/operstate /sys/class/net/eth0/statistics/rx_bytes | sed "1s/.*/xx:xx:xx:xx:xx:xx/"
cat /sys/module/nf_conntrack/parameters/hashsize 2>&1; ls /sys/module | wc -l
```

Output:

```text
../../devices/pci0000:00/0000:00:02.0/virtio1/net/eth0
../devices/pci0000:00/0000:00:01.0/virtio0/block/vda
xx:xx:xx:xx:xx:xx
1500
up
2720570
262144
93
```

`/sys/module/<name>/parameters/` shows the current parameters of loaded and built-in modules; see [Kernel Modules](kernel-modules.md).

---

## Writing Kernel Values

Writes to `/proc/sys` change the running kernel at once and are lost at reboot. Validation happens in the kernel, so a bad value fails with `Invalid argument`.

```bash
su - laborant -c "sudo echo 10 > /proc/sys/vm/swappiness"
su - laborant -c "echo 10 | sudo tee /proc/sys/vm/swappiness"
echo 1 > /proc/meminfo
```

Output:

```text
-bash: line 1: /proc/sys/vm/swappiness: Permission denied
10
/root/c/k1.sh: line 2: echo: write error: Input/output error
```

The first command fails because the user's shell, not `sudo`, opens the file for the redirection. The last one ran as root in a capture script, and `/proc/meminfo` is read-only even for root.

!!! warning "Use sysctl or tee, never sudo with a redirection"
    `sudo sysctl -w vm.swappiness=10` or `echo 10 | sudo tee /proc/sys/vm/swappiness` both work. `sudo sh -c 'echo 10 > ...'` also works but is harder to read in scripts.

---

## Common Errors

### `-bash: line 1: /proc/sys/vm/swappiness: Permission denied`

**Cause:** `sudo echo value > file` runs the redirection as the calling user.

**Fix:** `echo value | sudo tee file`, or `sudo sysctl -w key=value`.

### `echo: write error: Input/output error`

**Cause:** The file is read-only in the kernel, even for root.

**Fix:** Find the tunable under `/proc/sys` or `/sys` that controls the value.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is /proc, and why do its files show a size of 0?"
    **Say first:** A virtual filesystem generated by the kernel on each read; nothing is stored on disk, so there is no size to report.

    **Proof:** `ls -l /proc/meminfo` shows 0; `wc -c /proc/meminfo` shows the real length.

    **Follow-up:** Which command-line tools are wrappers around `/proc`?

??? question "L1: What is the difference between /proc and /sys?"
    **Say first:** `/proc` is process-centric with legacy system files; `/sys` models devices, drivers and modules with one value per file.

    **Proof:** `ls /proc/1`; `ls /sys/class/net/eth0`.

    **Follow-up:** Where do sysctl parameters live? (`/proc/sys`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Why does sudo echo 3 > /proc/sys/vm/drop_caches fail, and how do you fix it?"
    **Say first:** The shell performs the redirection before `sudo` runs, as the unprivileged user.

    **Proof:** `echo 3 | sudo tee /proc/sys/vm/drop_caches`, or `sudo sysctl vm.drop_caches=3`.

    **Follow-up:** Why is dropping caches rarely a real fix?

??? question "L2: Find the kernel command line and the active I/O scheduler of a disk without extra tools."
    **Say first:** Read `/proc/cmdline` and the disk's `queue/scheduler` in sysfs.

    **Proof:** `cat /proc/cmdline`; `cat /sys/block/vda/queue/scheduler` (the active one is in brackets).

    **Follow-up:** How do you change the scheduler at runtime? (`echo bfq | sudo tee .../scheduler`.)

??? question "L2: Show a network interface's MTU, state and received bytes from sysfs."
    **Say first:** Read the files under `/sys/class/net/<if>/`.

    **Proof:** `cat /sys/class/net/eth0/{mtu,operstate,statistics/rx_bytes}`

    **Follow-up:** Which command shows the same through netlink? (`ip -s link show eth0`.)

??? question "L2: Count processes and show the memory available without ps or free."
    **Say first:** Count numeric directories in `/proc` and read `MemAvailable`.

    **Proof:** `ls -d /proc/[0-9]* | wc -l`; `grep MemAvailable /proc/meminfo`.

    **Follow-up:** Why can the count differ from `ps -e | wc -l`?

??? question "L3: A monitoring agent reports wrong memory figures inside a container. Where do the numbers come from?"
    **Say first:** `/proc/meminfo` shows the host's memory, not the container's cgroup limit, unless something like LXCFS virtualizes it.

    **Proof:** Compare `grep MemTotal /proc/meminfo` with `cat /sys/fs/cgroup/memory.max` inside the container.

    **Follow-up:** Which file shows the container's current usage? (`memory.current`.)

??? question "L3: A value written to /proc/sys worked, but it was back to the default after a reboot. Why, and what is the fix?"
    **Say first:** `/proc/sys` holds the running state only; persistent values must be in a file under `/etc/sysctl.d/`.

    **Proof:** `echo "vm.swappiness = 10" | sudo tee /etc/sysctl.d/90-app.conf`; `sudo sysctl --system`.

    **Follow-up:** Which service applies those files at boot? (`systemd-sysctl.service`.)

---

## Related

- [sysctl](sysctl.md): managing `/proc/sys`
- [Kernel Modules](kernel-modules.md): `/sys/module`
- [Devices and udev](devices-and-udev.md): `/dev` and `/sys/devices`
- [Viewing Processes](../07-processes/viewing-processes.md): `/proc/<pid>`
- [System Information](../00-foundations/system-information.md): tools that read these files

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
