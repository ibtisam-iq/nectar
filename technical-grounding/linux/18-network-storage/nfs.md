# NFS

NFS shares a directory from a server to clients over the network, mounted so it looks like a local filesystem. It is the default network filesystem on Linux, and a hung NFS mount is a classic cause of high load with idle CPUs.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Server package | `nfs-utils` (RHEL), `nfs-kernel-server` (Ubuntu) | `rpm -q nfs-utils` |
| Client package | `nfs-utils` (RHEL), `nfs-common` (Ubuntu) | `mount.nfs -V` |
| Exports file | `/etc/exports` defines shared directories and who may mount | `cat /etc/exports` |
| Apply exports | Re-read and show the export table | `exportfs -rav` |
| Current exports | What the server is exporting now | `exportfs -s` |
| List from client | Show a server's exports | `showmount -e SERVER` |
| Default version | NFSv4.2 over TCP on modern distros | `findmnt -o FSTYPE,OPTIONS` |
| Port | NFSv4 uses a single port, 2049 | `ss -tlnp | grep 2049` |
| hard mount | Retries forever if the server stops; process blocks in `D` | mount option `hard` |
| soft mount | Fails I/O after retries; risks data corruption | mount option `soft` |
| Hang signature | `D` state, `WCHAN` `rpc_wait_bit_killable`, load rising | `ps -o stat,wchan` |
| Boot-safe mount | `_netdev` and `nofail` in `/etc/fstab` | `man nfs` |
<!-- --8<-- [end:facts] -->

---

## Exporting a Directory

The server lists shared directories in `/etc/exports`, each with the clients allowed to mount it and the options. `exportfs -rav` re-reads the file and applies it, and `exportfs -s` shows what is exported now.

```bash
echo '/srv/nfs/shared 172.16.0.0/16(rw,sync,no_subtree_check)' | sudo tee /etc/exports
sudo systemctl enable --now nfs-server
sudo exportfs -rav
sudo exportfs -s
```

Output:

```text
exporting 172.16.0.0/16:/srv/nfs/shared
/srv/nfs/shared  172.16.0.0/16(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

The server filled in defaults, including `root_squash`, which maps a client's root to `nobody` so a remote root cannot own server files. `sync` makes the server commit writes before replying, which is safer than `async` but slower.

!!! note "root_squash is on by default for a reason"
    With `root_squash`, a client's `root` becomes `nobody` on the export, so a compromised client cannot write files as root on the server. Turning it off with `no_root_squash` hands remote root real root on the share, and is rarely correct.

---

## Mounting on the Client

The client lists a server's exports with `showmount -e`, then mounts one like any filesystem. `findmnt` shows the negotiated protocol version and options.

```bash
showmount -e 172.16.1.3
sudo mount -t nfs 172.16.1.3:/srv/nfs/shared /mnt/nfs
findmnt -no FSTYPE,OPTIONS /mnt/nfs
```

Output:

```text
Export list for 172.16.1.3:
/srv/nfs/shared 172.16.0.0/16
nfs4 rw,relatime,vers=4.2,hard,proto=tcp,timeo=600,retrans=2,sec=sys
```

The mount negotiated NFSv4.2 over TCP with `hard` and `timeo=600` (a 60-second retransmit timeout). For a permanent mount, an `/etc/fstab` line with `_netdev` and `nofail` keeps a slow or absent server from blocking boot, covered in [Mounting and fstab](../12-storage/mounting-and-fstab.md).

---

## hard vs soft, and the Hang

A `hard` mount retries indefinitely if the server stops responding, so no data is lost but a process doing I/O blocks in uninterruptible sleep (`D`). A `soft` mount gives up after `retrans` retries and returns an error, which avoids the hang but can corrupt data mid-write.

When a `hard`-mounted server becomes unreachable, the writing process goes to `D`, load average climbs, yet the CPUs stay idle because a `D` task consumes no CPU.

```bash
# server unreachable; a write to the mount blocks
ps -o pid,stat,wchan:20,comm -p <writer-pid>
cat /proc/<writer-pid>/stack | head -3
```

Output:

```text
    PID STAT WCHAN                COMMAND
   1576 D    rpc_wait_bit_killabl dd
[<0>] rpc_wait_bit_killable+0x11/0x80
[<0>] __rpc_execute+0x17e/0x320
[<0>] nfs4_call_sync_sequence+0x74/0xb0 [nfsv4]
```

The `D` state, the `rpc_wait_bit_killable` wait channel, and the NFS frames in the kernel stack together name the cause: the process is blocked waiting for an NFS RPC to complete. This is the signature behind the [High Load, Low CPU](../interview/scenarios/high-load-low-cpu.md) scenario.

!!! warning "A D-state NFS process cannot be killed, even with SIGKILL"
    A process in uninterruptible sleep on NFS ignores every signal until the RPC completes or the server returns. The fix is to restore the server or the network, or reboot; `kill -9` does nothing while it waits.

---

## Install Differences

=== "RHEL / Rocky"

    ```bash
    sudo dnf install -y nfs-utils          # server and client both
    sudo systemctl enable --now nfs-server # server side
    ```

=== "Ubuntu / Debian"

    ```bash
    sudo apt install -y nfs-kernel-server  # server
    sudo apt install -y nfs-common         # client only
    sudo systemctl enable --now nfs-server
    ```

---

## Common Errors

### `clnt_create: RPC: Program not registered` from showmount

**Cause:** the NFS server service is not running, or a firewall blocks the NFS port.

**Fix:** start `nfs-server` on the server, and allow the `nfs` service through the firewall (port 2049 for NFSv4).

### `mount.nfs: access denied by server while mounting`

**Cause:** the client's address does not match any entry in `/etc/exports`, or exports were not re-applied after an edit.

**Fix:** correct the client range in `/etc/exports` and run `sudo exportfs -rav`; confirm with `exportfs -s`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a hard and a soft NFS mount?"
    **Say first:** a hard mount retries forever if the server stops, blocking the process but never losing data; a soft mount fails I/O after a few retries, risking corruption.

    **Proof:** the mount options `hard` and `soft`; a hard-mounted hang shows processes in `D` state.

    **Follow-up:** which is the safe default for data? (hard, with `_netdev` and `nofail` in fstab.)

??? question "L1: How does root_squash protect an NFS server?"
    **Say first:** it maps a client's root to `nobody` on the export, so a remote root cannot own or overwrite files as root on the server.

    **Proof:** it is on by default; `exportfs -s` shows `root_squash` in the options.

    **Follow-up:** when would you disable it? (rarely, for a trusted management host, with the risk understood.)
<!-- --8<-- [end:l1] -->

??? question "L2: Export a directory read-write to one subnet and apply it."
    **Say first:** add the line to `/etc/exports` and re-read it.

    **Proof:**

    ```bash
    echo '/data 10.0.0.0/24(rw,sync)' | sudo tee -a /etc/exports
    sudo exportfs -rav
    ```

    **Follow-up:** how does the client see the export? (`showmount -e SERVER`.)

??? question "L3: Load average is climbing but every CPU is idle. What do you check first, and why NFS?"
    **Say first:** look for processes in `D` state, because uninterruptible sleep counts toward load but uses no CPU, and a hung `hard` NFS mount is a common cause.

    **Proof:** `ps -eo stat,wchan,comm | grep '^D'`; `rpc_wait_bit_killable` in `WCHAN` or the kernel stack points at NFS.

    **Follow-up:** why can you not kill the process? (it is in uninterruptible sleep until the RPC returns.)

??? question "L4: Why does a process on a hung hard NFS mount ignore SIGKILL?"
    **Say first:** it is in uninterruptible sleep (`D`) inside a kernel RPC wait, and the kernel does not deliver signals until that wait completes, to avoid leaving the filesystem in an inconsistent state.

    **Proof:** `/proc/PID/stack` shows `rpc_wait_bit_killable`; the state clears only when the server responds or the mount is forced down.

    **Don't say:** that `kill -9` will free it; only restoring the server or a reboot will.

??? question "L2: Make an NFS mount safe to have in fstab when the server may be down at boot."
    **Say first:** mark it as a network device that must not block boot.

    **Proof:** add `_netdev,nofail` (and often `x-systemd.automount`) to the fstab options.

    **Follow-up:** what does `nofail` change? (a failed mount no longer drops boot to emergency.)

---

## Related

- [Autofs](autofs.md): mount NFS on demand instead of at boot
- [Mounting and fstab](../12-storage/mounting-and-fstab.md): `_netdev`, `nofail` and mount options
- [High Load, Low CPU](../interview/scenarios/high-load-low-cpu.md): the D-state NFS hang end to end
- [Process States](../07-processes/process-states.md): why `D` cannot be killed and feeds load
- [Firewalld and UFW](../15-security/firewalld-and-ufw.md): allowing the NFS service

Captured on Rocky Linux 10.2 servers on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The hang was produced by dropping NFS traffic to the server.
