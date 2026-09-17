# Swap

Swap is disk space the kernel uses for memory pages that are not in active use, on a partition or in a file. It buys time under memory pressure, but a host that swaps heavily is already short of RAM.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Show swap | `swapon --show`, `free -h`, `/proc/swaps` | `swapon --show` |
| Prepare | `mkswap [-L label] <dev or file>` | `blkid` shows `TYPE="swap"` |
| Enable, disable | `swapon <dev>`, `swapoff <dev>`; `-a` for every fstab entry | `swapon --show` |
| fstab line | `UUID=... none swap defaults 0 0` (`pri=N` sets the priority) | `systemctl list-units -t swap` |
| Swap file | Created with `dd` or `fallocate` (no holes), mode `0600` | `ls -l /swapfile` |
| Priority | Higher is used first; equal priorities are used in round robin | `swapon --show` |
| `vm.swappiness` | 0 to 200, kernel default 60; lower values keep more anonymous memory in RAM | `sysctl vm.swappiness` |
| Per process | `VmSwap` in `/proc/<pid>/status` | `grep VmSwap /proc/*/status` |
| Per cgroup | `MemorySwapMax=`, `memory.swap.max`; `MemorySwapCurrent` | `systemctl show -p MemorySwapCurrent <unit>` |
| Sizing | Up to the RAM size on small hosts, a few GiB on large ones; RAM plus more for hibernation | `free -h` |
| Kubernetes | The kubelet refuses to start with swap on unless `failSwapOn: false` is set | `swapon --show` |
| zram | Compressed swap in RAM; the default on Fedora | `zramctl` |
<!-- --8<-- [end:facts] -->

---

## Swap on a Partition

Partition 2 of `loop0` has MBR type `82` from [Partitioning](partitioning.md):

```bash
swapon --show; free -h | grep Swap
sudo mkswap -L swap1 /dev/loop0p2
sudo swapon /dev/loop0p2
swapon --show
```

Output:

```text
Swap:             0B          0B          0B
Setting up swapspace version 1, size = 1024 MiB (1073737728 bytes)
LABEL=swap1, UUID=f449f488-566a-4ba6-b829-b19283d0b25c
NAME         TYPE       SIZE USED PRIO
/dev/loop0p2 partition 1024M   0B   -2
```

The playground had no swap, which is common for cloud images and container hosts. The partition type code is only a hint; `mkswap` writes the signature that `swapon` looks for.

---

## Swap in a File

A swap file must have every block allocated, so a sparse file from `truncate` fails:

```bash
sudo truncate -s 512M /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile >/dev/null
sudo swapon /swapfile; echo "rc=$?"
sudo rm /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1M count=512 status=none
sudo mkswap /swapfile
sudo swapon /swapfile
sudo chmod 600 /swapfile
ls -l /swapfile
swapon --show
free -h
```

Output:

```text

mkswap: /swapfile contains holes or other unsupported extents.
        This swap file can be rejected by kernel on swap activation!
        Use --verbose for more details.

swapon: /swapfile: skipping - it appears to have holes.
rc=255
mkswap: /swapfile: insecure permissions 0644, fix with: chmod 0600 /swapfile
Setting up swapspace version 1, size = 512 MiB (536866816 bytes)
no label, UUID=5be39615-dd49-4411-9468-43c77d1cc113
swapon: /swapfile: insecure permissions 0644, 0600 suggested.
-rw------- 1 root root 536870912 Sep 17 07:39 /swapfile
NAME         TYPE       SIZE USED PRIO
/dev/loop0p2 partition 1024M   0B   -2
/swapfile    file       512M   0B   -3
               total        used        free      shared  buff/cache   available
Mem:           7.8Gi       483Mi       6.7Gi       2.1Mi       878Mi       7.4Gi
Swap:          1.5Gi          0B       1.5Gi
```

The second file was created with the default mode `0644` and `chmod` ran late on purpose: both tools only warn, and the file was already active while any user could read it. `fallocate -l 512M /swapfile` is faster than `dd` on ext4 and XFS; on Btrfs, `btrfs filesystem mkswapfile` creates a usable file.

!!! warning "A world-readable swap file leaks memory contents"
    Swapped pages can hold passwords, keys and session tokens. Set mode `0600` before `mkswap`, not after `swapon`.

---

## Making It Permanent

```bash
sudo swapoff -a; swapon --show
sudo tee -a /etc/fstab <<'EOF'
LABEL=swap1   none  swap  defaults,pri=10  0 0
/swapfile     none  swap  defaults         0 0
EOF
sudo systemctl daemon-reload
sudo swapon -a
swapon --show
systemctl list-units --type=swap --no-legend
```

Output:

```text
LABEL=swap1   none  swap  defaults,pri=10  0 0
/swapfile     none  swap  defaults         0 0
NAME         TYPE       SIZE USED PRIO
/dev/loop0p2 partition 1024M   0B   10
/swapfile    file       512M   0B   -2
  dev-disk-by\x2dlabel-swap1.swap loaded active active /dev/disk/by-label/swap1
  swapfile.swap                   loaded active active /swapfile
```

`mount -a` ignores swap entries; `swapon -a` activates them, and at boot systemd creates a `.swap` unit for each line. With `pri=10`, the partition fills before the file.

---

## Swappiness and Who Is Swapping

`vm.swappiness` sets how readily the kernel reclaims anonymous memory (swap) compared with page cache. Rocky shows `30` because of the drop-ins from [sysctl](../11-kernel-and-hardware/sysctl.md); Ubuntu 24.04 runs with the kernel default:

=== "RHEL / Rocky"

    ```bash
    sysctl vm.swappiness
    grep -H swappiness /etc/sysctl.d/*.conf
    ```

    Output:

    ```text
    vm.swappiness = 30
    /etc/sysctl.d/90-app.conf:vm.swappiness = 10
    /etc/sysctl.d/95-db.conf:vm.swappiness = 30
    ```

=== "Ubuntu / Debian"

    ```bash
    sysctl vm.swappiness
    ```

    Output:

    ```text
    vm.swappiness = 60
    ```

A service limited to 100 MiB of RAM that allocates 300 MiB is pushed into swap instead of being killed. With swap forbidden for the cgroup, the same allocation ends in the OOM killer:

```bash
sudo systemd-run --unit=hog -p MemoryMax=100M python3 -c 'import time; b = bytearray(300 * 1024 * 1024); time.sleep(120)'
sleep 5
grep -E 'VmRSS|VmSwap' /proc/$(systemctl show -p MainPID --value hog)/status
systemctl show -p MemoryCurrent,MemorySwapCurrent hog
free -h | grep Swap
sudo systemd-run --wait --unit=hog2 -p MemoryMax=100M -p MemorySwapMax=0 python3 -c 'b = bytearray(300 * 1024 * 1024)'; echo "rc=$?"
```

Output:

```text
Running as unit: hog.service; invocation ID: 79e36b96b63045089ebef08c91a6ada6
VmRSS:	  102716 kB
VmSwap:	  212824 kB
MemoryCurrent=104677376
MemorySwapCurrent=218083328
Swap:          1.5Gi       208Mi       1.3Gi
Running as unit: hog2.service; invocation ID: 11286e5f1614403d8455f4c144eeb30e
Finished with result: oom-kill
Main processes terminated with: code=killed, status=9/KILL
Service runtime: 169ms
CPU time consumed: 150ms
Memory peak: 100M
rc=1
```

`VmSwap` in each process's status file shows who holds swapped memory. Sustained non-zero `si` and `so` columns in `vmstat 1` mean the system is swapping pages in and out now, which hurts far more than a static amount of used swap.

!!! note "swapoff needs enough free RAM for everything in swap"
    `swapoff` reads every swapped page back into memory. On a busy host it can take minutes or trigger the OOM killer; check `free -h` first.

---

## Common Errors

### `swapon: /swapfile: skipping - it appears to have holes.`

**Cause:** the file is sparse (created with `truncate` or copied with `cp --sparse`), so the kernel cannot map its blocks directly.

**Fix:** recreate it with `dd if=/dev/zero` or `fallocate`, then `chmod 600`, `mkswap` and `swapon`.

### `swapon: /dev/loop0p1: read swap header failed`

**Cause:** the device has no swap signature: `mkswap` was never run, or the device holds a filesystem (`loop0p1` is ext4).

**Fix:** confirm the device with `blkid`, then `sudo mkswap` it.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is swap, and is using swap bad?"
    **Say first:** swap holds memory pages the kernel moved out of RAM; some used swap is normal, while constant swapping in and out means the host needs more memory.

    **Proof:** `free -h`; `vmstat 1` shows `si` and `so`.

    **Follow-up:** What does `vm.swappiness` change?

??? question "L1: Swap partition or swap file: which is better?"
    **Say first:** performance is the same on current kernels; a file is easier to resize, while a partition needs no filesystem and suits hibernation setups.

    **Proof:** `swapon --show` lists `partition` or `file`.

    **Follow-up:** Why must a swap file have no holes?
<!-- --8<-- [end:l1] -->

??? question "L2: Add 2 GiB of swap to a running server without a new disk."
    **Say first:** create a fully allocated file with mode 0600, format it, enable it and add it to fstab.

    **Proof:** `sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`; `echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab`.

    **Follow-up:** How do you check it activates at boot? (`sudo swapoff /swapfile; sudo swapon -a; swapon --show`.)

??? question "L2: Find which processes are using swap."
    **Say first:** read `VmSwap` from each process's status file.

    **Proof:** `grep VmSwap /proc/[0-9]*/status | sort -k2 -n | tail`; `smem -s swap` if installed.

    **Follow-up:** How do you see swap per systemd service? (`systemctl show -p MemorySwapCurrent`.)

??? question "L3: A server is slow, load is high and free shows little free swap. What do you check?"
    **Say first:** whether it is actively swapping, which processes grew, and whether the OOM killer has run.

    **Proof:** `vmstat 1` (`si`, `so`, `wa`); `ps aux --sort=-rss | head`; `journalctl -k | grep -i 'out of memory'`.

    **Follow-up:** Why can adding more swap make this worse?

??? question "L2: Why does kubeadm fail with a swap-related preflight error, and what are the options?"
    **Say first:** the kubelet requires swap off by default, so disable it or configure swap support explicitly.

    **Proof:** `sudo swapoff -a` and comment out the fstab swap lines; or set `failSwapOn: false` and a `memorySwap` behavior in the kubelet configuration.

    **Follow-up:** Which systemd unit type would still activate swap after the fstab line is removed? (A `.swap` unit, or zram.)

---

## Related

- [Mounting and fstab](mounting-and-fstab.md): fstab fields and generated units
- [sysctl](../11-kernel-and-hardware/sysctl.md): setting `vm.swappiness` persistently
- [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md): OOM killer messages

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167, util-linux 2.40.2), 2026-09.
