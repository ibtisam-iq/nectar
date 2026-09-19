# iSCSI and NBD

iSCSI presents a remote block device over the network, so the client sees a raw disk (`/dev/sd*`) rather than a shared filesystem. NBD does the same with less setup, and both differ from NFS by exporting blocks, not files.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Exports | A block device, not a filesystem | `lsblk -S` on the client |
| Target / initiator | Server side / client side | `targetcli` / `iscsiadm` |
| IQN | Name identifying a target or initiator | `/etc/iscsi/initiatorname.iscsi` |
| ACL | Restricts a target to specific initiator IQNs (TCP 3260) | `targetcli .../acls` |
<!-- --8<-- [end:facts] -->

---

## Creating a Target

`targetcli` builds the server side: a backstore (the storage), a target with an IQN, a LUN over the backstore, and an ACL naming which initiator may connect.

```bash
sudo targetcli <<'EOF'
/backstores/fileio create disk01 /var/lib/iscsi_disk.img
/iscsi create iqn.2026-09.local.web:target01
/iscsi/iqn.2026-09.local.web:target01/tpg1/luns create /backstores/fileio/disk01
/iscsi/iqn.2026-09.local.web:target01/tpg1/acls create iqn.1994-05.com.redhat:gw-init
saveconfig
EOF
sudo targetcli ls /iscsi | head -5
```

Output:

```text
o- iqn.2026-09.local.web:target01 ...................................... [TPGs: 1]
  o- tpg1 .................................................. [gen-acls, no-auth]
    o- iqn.1994-05.com.redhat:gw-init .................... [Mapped LUNs: 1]
```

The ACL ties the LUN to the initiator's IQN, from the client's `/etc/iscsi/initiatorname.iscsi`. Only that initiator may log in and see the disk.

---

## Connecting from the Initiator

The client discovers targets on the server's portal, then logs in; a new SCSI disk appears, partitioned and formatted like any local disk.

```bash
sudo iscsiadm -m discovery -t sendtargets -p 172.16.1.3
sudo iscsiadm -m node -T iqn.2026-09.local.web:target01 -p 172.16.1.3 --login
lsblk -S
```

Output:

```text
172.16.1.3:3260,1 iqn.2026-09.local.web:target01
Login to [iface: default, target: iqn.2026-09.local.web:target01, portal: 172.16.1.3,3260] successful.
NAME HCTL       TYPE VENDOR   MODEL   TRAN
sda  0:0:0:0    disk LIO-ORG  disk01  iscsi
```

The new `/dev/sda` has transport `iscsi` and vendor `LIO-ORG` (the Linux target). Because it is a raw block device, only one host should put a normal filesystem on it, unlike NFS which many clients share.

!!! warning "An iSCSI disk is not a shared filesystem"
    Mounting one LUN read-write from two hosts with a normal filesystem corrupts it, because each host caches independently. Sharing needs a cluster filesystem (GFS2, OCFS2), or use NFS.

!!! note "Persist the session or the disk vanishes on reboot"
    Set `node.startup = automatic` and enable `iscsid` so the session re-establishes at boot, and use `_netdev` in `/etc/fstab` for any filesystem on the LUN.

NBD exports a block device over TCP with far less setup than iSCSI: a server offers a device or file, and the client attaches it as `/dev/nbd0` (`sudo qemu-nbd --connect=/dev/nbd0 disk.qcow2`). It is common in virtualization for mounting a VM disk image, and lacks iSCSI's authentication and multipath.

---

## Common Errors

### `iscsiadm: no records found` after discovery

**Cause:** the initiator's IQN is not in the target's ACL, or discovery hit the wrong portal.

**Fix:** add the client's IQN to the ACL, and rediscover the correct portal IP.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between iSCSI and NFS?"
    **Say first:** iSCSI exports a raw block device that one host owns and formats; NFS exports a filesystem that many clients share.

    **Proof:** an iSCSI login adds a `/dev/sd*` disk; an NFS mount is a filesystem of type `nfs`.

    **Follow-up:** why can two hosts share one NFS mount but not one iSCSI LUN? (NFS coordinates access; a raw block device does not.)

??? question "L1: What are the target and initiator in iSCSI?"
    **Say first:** the target is the server exporting the LUN; the initiator is the client that logs in and uses it.

    **Proof:** `targetcli` builds the target; `iscsiadm` drives the initiator; each has an IQN.

    **Follow-up:** what restricts which client may connect? (the target's ACL, by initiator IQN.)
<!-- --8<-- [end:l1] -->

??? question "L2: Connect a client to an iSCSI target and find the new disk."
    **Say first:** discover the portal, log in, then list SCSI disks.

    **Proof:**

    ```bash
    sudo iscsiadm -m discovery -t st -p SERVER
    sudo iscsiadm -m node -T IQN -p SERVER --login
    lsblk -S
    ```

    **Follow-up:** how do you make the session persist across reboot? (`node.startup = automatic`.)

??? question "L3: Two hosts mounted the same iSCSI LUN and the filesystem is corrupt. Explain."
    **Say first:** a raw block device with a normal filesystem cannot be shared read-write, because each host caches independently and overwrites the other's metadata.

    **Proof:** the LUN is a single disk; sharing needs a cluster filesystem or a file protocol like NFS.

    **Follow-up:** what should have been used for shared read-write access? (NFS, or GFS2.)

??? question "L2: How does NBD differ from iSCSI?"
    **Say first:** NBD exports a block device over TCP with much less setup, but without iSCSI's authentication, ACLs and multipath.

    **Proof:** `qemu-nbd --connect` attaches an image as `/dev/nbd0`; common for VM disks.

    **Follow-up:** where is NBD most used? (virtualization, mounting VM disk images.)

??? question "L2: Restrict an iSCSI target so only one client can use it."
    **Say first:** add that client's IQN to the target's ACL.

    **Proof:** `targetcli .../acls create iqn...`; only that initiator can log in.

    **Follow-up:** where does the client's IQN come from? (`/etc/iscsi/initiatorname.iscsi`.)

---

## Related

- [NFS](nfs.md): the file-sharing alternative to block export
- [Disks and Devices](../12-storage/disks-and-devices.md): the `/dev/sd*` devices iSCSI adds
- [VM Images and Cloning](../20-virtualization-and-provisioning/vm-images-and-cloning.md): `qemu-nbd` and disk images

Captured on Rocky Linux 10.2 servers on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The NBD block is command-only; NBD was not set up on the capture host.
