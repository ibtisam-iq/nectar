# Network Storage

Sharing storage between hosts, over files (NFS, Samba) and over blocks (iSCSI, NBD). NFS is the core skill for RHCSA and LFCS, and a hung NFS mount is a frequent production incident.

---

## Revision Card

| Fact | Value |
|---|---|
| NFS exports | Files; many clients share one filesystem |
| iSCSI exports | Blocks; one host owns the raw disk |
| Exports file | `/etc/exports`, applied with `exportfs -rav` |
| NFS version | NFSv4.2 over TCP, single port 2049 |
| hard vs soft | hard blocks forever (safe); soft fails (risks corruption) |
| Hang signature | `D` state, `WCHAN` `rpc_wait_bit_killable`, load up, CPU idle |
| root_squash | Client root maps to `nobody` on the export |
| Autofs | Mounts on access, unmounts when idle |
| Samba/CIFS | SMB protocol; mount `-t cifs` with a credentials file |
| iSCSI ports | TCP 3260; target with `targetcli`, initiator with `iscsiadm` |

| Task | Command |
|---|---|
| Export a directory | edit `/etc/exports`; `sudo exportfs -rav` |
| Show server exports | `exportfs -s`; `showmount -e SERVER` |
| Mount NFS | `mount -t nfs SERVER:/path /mnt` |
| Find a hung NFS process | `ps -eo stat,wchan,comm | grep '^D'` |
| Autofs on demand | master map + map file; `systemctl restart autofs` |
| Mount CIFS safely | `mount -t cifs //srv/share /mnt -o credentials=FILE` |
| iSCSI discover/login | `iscsiadm -m discovery`; `iscsiadm -m node --login` |
| New iSCSI disk | `lsblk -S` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [NFS](nfs.md) | Exports, mounts, hard vs soft, the D-state hang, `root_squash` | Core | Med |
| [Autofs](autofs.md) | Master and map files, on-demand mount, idle timeout | RHCSA | Low |
| [Samba and CIFS](samba-cifs.md) | Serving SMB, client mount with a credentials file | RHCSA | Low |
| [iSCSI and NBD](iscsi-and-nbd.md) | Block export, target and initiator, IQN, ACL, NBD | Advanced | Low |

---

## Scenarios and Labs

- [High Load, Low CPU](../interview/scenarios/high-load-low-cpu.md): a hung NFS mount driving load with idle CPUs
