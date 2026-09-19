# System Information

A handful of read-only commands identify the distribution, kernel, CPU, memory, disks and hardware of an unfamiliar server. They are the first commands to run on any machine before changing it, and the first facts an incident report asks for.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Distribution and version | `/etc/os-release` (standard on every systemd distribution) | `cat /etc/os-release` |
| Kernel release | Separate from the distribution version | `uname -r` |
| CPU architecture | `x86_64` or `aarch64` | `uname -m` |
| Logical CPUs | Count of schedulable CPUs | `nproc` |
| Memory that can be used now | `available` column, not `free` | `free -h` |
| Block devices and mounts | Tree of disks, partitions and mount points | `lsblk` |
| Uptime and load | Time since boot, 1/5/15-minute load averages | `uptime` |
| Virtualization | Hypervisor type, or `none` on bare metal | `systemd-detect-virt`, `hostnamectl` |
| Firmware tables | `dmidecode` reads SMBIOS; absent on some microVMs | `sudo dmidecode -t system` |
| Page size | 4096 bytes on x86_64 | `getconf PAGE_SIZE` |
<!-- --8<-- [end:facts] -->

---

## Distribution and Kernel

`/etc/os-release` names the distribution; `uname` reports the running kernel. The two are independent: both playgrounds below run the same 6.1.167 kernel.

```bash
uname -srm
uname -o
```

Output:

```text
Linux 6.1.167 x86_64
GNU/Linux
```

=== "RHEL / Rocky"

    ```bash
    grep -E '^(NAME|VERSION_ID|ID|ID_LIKE|PLATFORM_ID)=' /etc/os-release
    cat /etc/redhat-release
    ```

    Output:

    ```text
    NAME="Rocky Linux"
    ID="rocky"
    ID_LIKE="rhel centos fedora"
    VERSION_ID="10.2"
    PLATFORM_ID="platform:el10"
    Rocky Linux release 10.2 (Red Quartz)
    ```

=== "Ubuntu / Debian"

    ```bash
    grep -E '^(NAME|VERSION_ID|ID|ID_LIKE|VERSION_CODENAME)=' /etc/os-release
    lsb_release -a
    cat /etc/debian_version
    ```

    Output:

    ```text
    NAME="Ubuntu"
    VERSION_ID="24.04"
    VERSION_CODENAME=noble
    ID=ubuntu
    ID_LIKE=debian
    Distributor ID:	Ubuntu
    Description:	Ubuntu 24.04.4 LTS
    Release:	24.04
    Codename:	noble
    trixie/sid
    ```

    `/etc/debian_version` names the Debian branch Ubuntu was based on, not the Ubuntu release.

---

## CPU

```bash
lscpu | grep -E '^(Architecture|CPU\(s\)|Model name|Thread|Core|Socket|Hypervisor|Virtualization type)'
nproc
```

Output:

```text
Architecture:                            x86_64
CPU(s):                                  4
Model name:                              AMD EPYC
Thread(s) per core:                      1
Core(s) per socket:                      4
Socket(s):                               1
Hypervisor vendor:                       KVM
Virtualization type:                     full
4
```

!!! note "nproc can report fewer CPUs than lscpu"
    Logical CPUs equal sockets times cores per socket times threads per core. `nproc` respects CPU affinity and cgroup limits, so inside a restricted container it can report fewer CPUs than `lscpu`.

---

## Memory

```bash
free -h
grep -E '^(MemTotal|MemAvailable|SwapTotal)' /proc/meminfo
lsmem
```

Output:

```text
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       488Mi       7.3Gi       9.0Mi       336Mi       7.4Gi
Swap:             0B          0B          0B
MemTotal:        8212896 kB
MemAvailable:    7712652 kB
SwapTotal:             0 kB
RANGE                                 SIZE  STATE REMOVABLE BLOCK
0x0000000000000000-0x00000000bfffffff   3G online       yes  0-23
0x0000000100000000-0x000000023fffffff   5G online       yes 32-71
# ... (trimmed)
```

!!! warning "Low free memory is normal"
    The kernel fills idle RAM with page cache (`buff/cache`) and releases it on demand. `available` estimates what new programs can use without swapping; alerts built on `free` fire on healthy servers.

---

## Disks and Hardware

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
lspci
lsusb
echo "rc=$?"
```

Output:

```text
NAME SIZE TYPE FSTYPE MOUNTPOINTS
vda   80G disk ext4   /
00:00.0 Host bridge: Intel Corporation Device 0d57
00:01.0 Mass storage controller: Red Hat, Inc. Virtio 1.0 block device (rev 01)
00:02.0 Ethernet controller: Red Hat, Inc. Virtio 1.0 network device (rev 01)
00:03.0 Unassigned class [ffff]: Red Hat, Inc. Virtio 1.0 socket (rev 01)
00:04.0 Unassigned class [ffff]: Red Hat, Inc. Virtio 1.0 RNG (rev 01)
rc=1
```

The Virtio devices show a KVM guest; `vda` is a Virtio disk. `lsusb` prints nothing and exits 1 because this microVM has no USB bus.

`lshw` builds a hardware tree from `/proc`, `/sys` and PCI data. `dmidecode` reads the firmware's SMBIOS table (vendor, serial number, BIOS version), which lightweight microVMs do not provide:

```bash
sudo lshw -short
sudo dmidecode -t system
```

Output:

```text
H/W path    Device    Class          Description
================================================
                      system         Computer
/0                    bus            Motherboard
/0/0                  memory         8GiB System memory
/0/1                  processor      AMD EPYC
/0/100                bridge         Intel Corporation
/0/100/1              storage        Virtio 1.0 block device
/0/100/1/0  /dev/vda  volume         80GiB EXT4 volume
/0/100/2              network        Virtio 1.0 network device
# ... (trimmed)
# dmidecode 3.6
Scanning /dev/mem for entry point.
# No SMBIOS nor DMI entry point found, sorry.
```

| Tool | Package (RHEL / Ubuntu) | Reads |
|---|---|---|
| `lscpu`, `lsblk`, `lsmem` | `util-linux` | `/proc`, `/sys` |
| `lspci` | `pciutils` | PCI bus |
| `lsusb` | `usbutils` | USB bus |
| `lshw` | `lshw` | Combined hardware tree |
| `dmidecode` | `dmidecode` | SMBIOS firmware table |

---

## Uptime and Virtualization

```bash
uptime
who -b
cat /proc/loadavg
systemd-detect-virt
getconf PAGE_SIZE
```

Output:

```text
 13:25:13 up 1 min,  0 user,  load average: 0.26, 0.10, 0.03
         system boot  2026-09-16 13:23
0.26 0.10 0.03 1/112 1475
kvm
4096
```

In `/proc/loadavg`, `1/112` is running over total scheduling entities and `1475` is the most recently assigned PID.

---

## Common Errors

### `# No SMBIOS nor DMI entry point found, sorry.`

**Cause:** the machine (usually a microVM or container) exposes no SMBIOS table.

**Fix:** use `lscpu`, `lsmem` and `lspci` instead; cloud instances expose vendor data through their metadata service.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do you find which distribution and kernel a server runs?"
    **Say first:** `/etc/os-release` for the distribution and `uname -r` for the kernel; they are separate components with separate versions.

    **Proof:** `cat /etc/os-release; uname -r`

    **Follow-up:** Why can two different distributions report the same kernel release?

??? question "L1: Why is free memory low on a healthy server?"
    **Say first:** the kernel uses spare RAM as page cache and gives it back when programs need it; `available` is the number that matters.

    **Proof:** `free -h` shows a large `buff/cache` and an `available` close to `total`.

    **Follow-up:** When does low `available` become a problem?
<!-- --8<-- [end:l1] -->

??? question "L2: Report CPU count, memory, disks and uptime of a new server in one pass."
    **Say first:** four read-only commands.

    **Proof:**

    ```bash
    nproc; free -h; lsblk; uptime
    ```

    **Follow-up:** How do you tell if the machine is a VM? (`systemd-detect-virt`, `lscpu` hypervisor line.)

??? question "L2: A script must install packages on both Rocky and Ubuntu. How does it choose the package manager?"
    **Say first:** source `/etc/os-release` and branch on `ID_LIKE`.

    **Proof:**

    ```bash
    . /etc/os-release
    case "$ID_LIKE" in *rhel*) echo dnf ;; *debian*) echo apt ;; esac
    ```

    **Follow-up:** What is `ID_LIKE` on Debian itself, where it is not set?

??? question "L2: nproc reports 2 inside a container, lscpu reports 16. Which is right?"
    **Say first:** both; `nproc` honours the CPU affinity or cgroup limit applied to the process, `lscpu` reports the host CPUs.

    **Proof:** `nproc` versus `nproc --all`.

    **Follow-up:** Which value should a worker pool size itself from?

??? question "L3: A monitoring agent reports the wrong hardware vendor and serial on a VM."
    **Say first:** check whether the hypervisor exposes SMBIOS at all.

    **Proof:** `sudo dmidecode -t system` returns "No SMBIOS nor DMI entry point found"; `ls /sys/class/dmi` is missing; the agent falls back to defaults.

    **Follow-up:** Where else can the instance identity come from? (Cloud metadata service.)

---

## Related

- [Kernel vs OS vs Distro](kernel-vs-os-vs-distro.md): why kernel and distribution versions differ
- [Distributions](distributions.md): families and release models
- [Architecture](architecture.md): where `/proc` and `/sys` data comes from

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
