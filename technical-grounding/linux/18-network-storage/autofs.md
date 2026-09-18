# Autofs

Autofs mounts a filesystem on first access and unmounts it after a period of disuse, instead of keeping it mounted from boot. It suits home directories and shares that are used occasionally, and it avoids a boot-time hang on an absent NFS server.

**Track:** RHCSA · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Package | `autofs` on both families | `rpm -q autofs` |
| Master map | `/etc/auto.master` and `/etc/auto.master.d/*` | `cat /etc/auto.master` |
| Mount point | Master map ties a directory to a map file | `ls /etc/auto.master.d` |
| Direct map | Absolute paths, key `/-` | `man 5 autofs` |
| Indirect map | A base directory with keys as subdirectories | the map file |
| On-demand | Mounts on access, not at boot | `findmnt` after `ls` |
| Idle timeout | Unmounts after inactivity (default 300s) | `--timeout` |
| Service | Reload maps by restarting the service | `systemctl restart autofs` |
<!-- --8<-- [end:facts] -->

---

## Master Map and a Map File

The master map connects a base directory to a map file. An indirect map lists keys that become subdirectories under that base, each with its mount options and source.

```bash
echo '/nfs  /etc/auto.nfs' | sudo tee /etc/auto.master.d/nfs.autofs
echo 'shared  -rw,soft  172.16.1.3:/srv/nfs/shared' | sudo tee /etc/auto.nfs
sudo systemctl restart autofs
```

This maps `/nfs/shared` to the NFS export, mounted only when something accesses it. Editing a map takes effect after `systemctl restart autofs`.

!!! note "The base directory is managed by autofs, not the filesystem"
    Autofs owns `/nfs` and populates subdirectories on demand, so `ls /nfs` may look empty until a specific key like `/nfs/shared` is accessed. Do not create real directories under an autofs base; they are shadowed by the automounts.

---

## Mount on Access

Nothing is mounted until the path is used. The first access to `/nfs/shared` triggers the mount, and `findmnt` then shows it.

```bash
findmnt /nfs/shared || echo "not mounted yet"
ls /nfs/shared                       # access triggers the mount
findmnt -no TARGET,SOURCE,FSTYPE /nfs/shared
```

Output:

```text
not mounted yet
README
/nfs/shared 172.16.1.3:/srv/nfs/shared nfs4
```

Before access the path is not mounted; after `ls` it is a live NFSv4 mount. It unmounts again once idle past the timeout, freeing the connection.

!!! tip "Autofs avoids the boot-time NFS hang"
    A static NFS entry in `/etc/fstab` can stall boot if the server is down. Autofs only touches the server on access, so a missing server delays the first use, not the whole boot.

---

## Common Errors

### an autofs path shows empty until it is accessed

**Cause:** this is expected: autofs mounts on demand, so the mount appears only after the path is used.

**Fix:** access the full path (`ls /nfs/shared`), not the parent alone; the parent is managed by autofs and stays empty.

### map changes have no effect

**Cause:** autofs caches maps and does not reload them automatically after an edit.

**Fix:** `sudo systemctl restart autofs` to re-read the master and map files.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What problem does autofs solve over a static fstab mount?"
    **Say first:** it mounts on demand and unmounts when idle, so shares are only connected when used and an absent server does not hang boot.

    **Proof:** the path is unmounted until accessed, then `findmnt` shows the mount.

    **Follow-up:** what is the default idle timeout? (300 seconds.)

??? question "L1: What is the difference between a direct and an indirect map?"
    **Say first:** a direct map uses absolute paths under the key `/-`; an indirect map has a base directory whose keys become subdirectories.

    **Proof:** the master map references `/-` for direct, a base path for indirect.

    **Follow-up:** which suits per-user home directories? (an indirect map with a wildcard key.)
<!-- --8<-- [end:l1] -->

??? question "L2: Configure autofs to mount an NFS export on access."
    **Say first:** add a master entry pointing at a map file, define the key, and restart the service.

    **Proof:**

    ```bash
    echo '/nfs /etc/auto.nfs' | sudo tee /etc/auto.master.d/nfs.autofs
    echo 'shared -rw 172.16.1.3:/srv/nfs/shared' | sudo tee /etc/auto.nfs
    sudo systemctl restart autofs
    ```

    **Follow-up:** how do you confirm it works? (`ls /nfs/shared`, then `findmnt`.)

??? question "L2: You edited a map but the change is not applied. Fix it."
    **Say first:** autofs caches maps, so restart the service to reload them.

    **Proof:** `sudo systemctl restart autofs`; access the path again.

    **Follow-up:** why not wait for it to reload? (maps are not re-read automatically.)

??? question "L3: A user reports their home directory is empty on login. How do you check if autofs is involved?"
    **Say first:** confirm the home path is an autofs mount and that accessing it triggers the mount rather than showing an empty directory.

    **Proof:** check `/etc/auto.master.d` and the map; `findmnt` the home path after the user accesses a file in it.

    **Follow-up:** what breaks this on a network share? (the NFS server being unreachable at first access.)

??? question "L2: How do you make autofs unmount an idle share sooner?"
    **Say first:** lower the timeout on the master entry.

    **Proof:** add `--timeout=60` to the master map line, then restart autofs.

    **Follow-up:** why unmount at all? (to release the server connection and avoid stale mounts.)

---

## Related

- [NFS](nfs.md): the export autofs mounts on demand
- [Mounting and fstab](../12-storage/mounting-and-fstab.md): the static alternative and mount options
- [Centralized Identity](../04-users-and-access/centralized-identity.md): NFS home directories with SSSD

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09.
