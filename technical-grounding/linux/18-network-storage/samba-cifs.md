# Samba and CIFS

Samba serves files to Windows and Linux clients using the SMB protocol, and Linux mounts SMB shares with the `cifs` filesystem type. The common DevOps task is the client side: mounting a share with a credentials file.

**Track:** RHCSA · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Protocol | SMB (formerly CIFS); default SMB3 | `mount -o vers=3.0` |
| Client package | `cifs-utils` on both families | `rpm -q cifs-utils` |
| Server config | `/etc/samba/smb.conf`, one section per share | `testparm -s` |
| Samba user | A separate password store, not `/etc/passwd` | `smbpasswd -a` |
| Mount type | `-t cifs`, with `credentials=` for the password | `findmnt -t cifs` |
| Credentials file | `username=`/`password=`, mode 600 | `chmod 600` |
<!-- --8<-- [end:facts] -->

---

## Serving a Share

A share is a section in `smb.conf` naming a path and who may access it. Samba keeps its own password database, so a user is added with `smbpasswd` even if they exist in `/etc/passwd`. `testparm` validates the config.

```bash
sudo smbpasswd -a smbuser            # set the Samba password
sudo systemctl enable --now smb
testparm -s 2>/dev/null | grep -E '\[|path|valid users'
```

Output:

```text
[global]
[public]
	path = /srv/samba/public
	valid users = smbuser
```

The `[public]` section exposes `/srv/samba/public` to `smbuser`.

!!! note "A Samba user is not a system login"
    `smbpasswd -a` writes to Samba's own password store, separate from `/etc/shadow`. A user in `/etc/passwd` still cannot use a share until given a Samba password.

---

## Mounting on the Client

The client mounts a share with `-t cifs`. Putting the credentials in a root-only file keeps the password out of the command line and `/etc/fstab`.

```bash
sudo tee /etc/samba/creds >/dev/null <<'EOF'
username=smbuser
password=REDACTED
EOF
sudo chmod 600 /etc/samba/creds
sudo mount -t cifs //172.16.1.3/public /mnt/smb -o credentials=/etc/samba/creds,vers=3.0
findmnt -no TARGET,SOURCE,FSTYPE /mnt/smb
```

Output:

```text
/mnt/smb //172.16.1.3/public cifs
```

The share is mounted as a `cifs` filesystem and used like a local directory. For a permanent mount, an `/etc/fstab` line uses the same `credentials=` option so no password appears in the file.

!!! warning "Never put a Samba password on the command line or in world-readable fstab"
    A password in `mount -o password=` shows in the process list and shell history, and one in a readable `/etc/fstab` is exposed to every user. Use a `credentials=` file with mode 600.

---

## Common Errors

### `mount error(13): Permission denied` mounting a CIFS share

**Cause:** wrong username or password, or the wrong SMB protocol version negotiated.

**Fix:** check the credentials file, add `vers=3.0`, and confirm the user exists with `smbpasswd`. A `mount error(112): Host is down` usually means the same version mismatch (an old client asking for disabled SMB1).

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between NFS and Samba?"
    **Say first:** NFS is the native Unix network filesystem; Samba serves the SMB protocol used by Windows, mounted on Linux as `cifs`.

    **Proof:** NFS mounts are `-t nfs`; SMB mounts are `-t cifs`.

    **Follow-up:** which would you pick for a mixed Windows and Linux environment? (Samba, for SMB compatibility.)

??? question "L1: Why does Samba need its own user password?"
    **Say first:** Samba keeps a separate password database from `/etc/shadow`, so a system user must also be given a Samba password.

    **Proof:** `smbpasswd -a user` sets it; `/etc/passwd` alone is not enough to log in over SMB.

    **Follow-up:** where is the SMB password stored? (Samba's own database, not `/etc/shadow`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Mount an SMB share without exposing the password."
    **Say first:** put the credentials in a mode-600 file and reference it with `credentials=`.

    **Proof:**

    ```bash
    sudo mount -t cifs //srv/share /mnt -o credentials=/etc/samba/creds,vers=3.0
    ```

    **Follow-up:** why not use `-o password=`? (it appears in the process list and history.)

??? question "L2: List the shares a Samba server offers before mounting."
    **Say first:** browse them with `smbclient -L`.

    **Proof:** `smbclient -L 172.16.1.3 -U smbuser`; enter the password when prompted.

    **Follow-up:** what does this confirm? (the server is reachable and the share name is correct.)

??? question "L3: A CIFS mount fails with permission denied but the credentials are correct. What else do you check?"
    **Say first:** confirm the negotiated SMB version, since an unsupported or disabled version (like SMB1) fails even with valid credentials.

    **Proof:** add `vers=3.0`; check the server's `smb.conf` for the minimum protocol and the user's `valid users`.

    **Follow-up:** why is SMB1 usually disabled? (it is insecure and deprecated.)

??? question "L2: Validate an smb.conf before restarting the service."
    **Say first:** run `testparm`, which parses the file and reports errors.

    **Proof:** `testparm -s` prints the effective config; fix any reported error before restart.

    **Follow-up:** what does `testparm` not check? (whether the paths and users actually exist and are reachable.)

---

## Related

- [NFS](nfs.md): the Unix-native alternative
- [Mounting and fstab](../12-storage/mounting-and-fstab.md): permanent mounts and options
- [Passwords and Aging](../04-users-and-access/passwords-and-aging.md): why Samba keeps a separate password store

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. The credentials file password is redacted.
