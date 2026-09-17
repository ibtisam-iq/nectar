# Cannot SSH

A login to a server that worked before now fails. The interviewer watches whether the candidate splits the problem into stages (connection, host key, authentication, session) and reads `ssh -v` and the server log instead of guessing.

---

## Symptom

> "I can't SSH to a box that worked yesterday. What do you do?"

---

## Clarifying Questions

- **What is the exact message?** `Connection refused`, `timed out`, `Permission denied (publickey)` and a host-key warning each point to a different stage.
- **One user or everyone?** One user suggests a key or account; everyone suggests the daemon, the firewall or the network.
- **Did anything change?** A reboot, a rebuild, a deployment, a firewall or SELinux change, an expired account.
- **Does the port answer?** `nc -vz host 22` separates the network from authentication.

---

## Diagnostic Path

The client is `ops` on `client` (Ubuntu 24.04); the server is `deploy@172.16.1.3` (`web`, Rocky Linux 10.2).

### 1. Separate Network From Authentication

```bash
ssh -o ConnectTimeout=5 deploy@172.16.1.3 true; echo "exit=$?"
nc -vz -w3 172.16.1.3 22
```

Output:

```text
ssh: connect to host 172.16.1.3 port 22: Connection refused
exit=255
nc: connect to 172.16.1.3 port 22 (tcp) failed: Connection refused
```

`Connection refused` is instant: the host answered but nothing listens on 22 (`sshd` stopped or bound elsewhere). A `Connection timed out` instead means a firewall or a security group drops the packets, as in [Cannot Reach Host](cannot-reach-host.md).

### 2. Check the Daemon on the Server

```bash
systemctl is-active sshd
sudo ss -tlnp 'sport = :22'
```

Output:

```text
active
LISTEN 0      128          0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=1519,fd=7))
```

Once `sshd` is running and listening, the connection reaches authentication.

### 3. Read the Client's View of Authentication

```bash
ssh -v deploy@172.16.1.3 true 2>&1 | grep -E 'Offering|Authentications that|No more authentication|Permission denied'
```

Output:

```text
debug1: Authentications that can continue: publickey
debug1: Offering public key: /home/ops/.ssh/id_ed25519 ED25519 SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc explicit agent
debug1: Authentications that can continue: publickey
debug1: No more authentication methods to try.
deploy@172.16.1.3: Permission denied (publickey).
```

The client offered the key and the server refused it. The client cannot say why; the reason is in the server log.

### 4. Read the Server Log

```bash
sudo journalctl -u sshd --since -2min | grep -v 'Connection closed'
```

Output:

```text
Sep 17 15:59:34 web sshd-session[89810]: Authentication refused: bad ownership or modes for directory /home/deploy
```

`StrictModes` rejected the key because `/home/deploy` was group-writable. A different run showed `Could not open user 'deploy' authorized keys ... Permission denied`, which is the SELinux label case: the file was labeled `tmp_t` after a `mv` from `/tmp`.

### 5. Rule Out an Account Problem

```bash
ssh deploy@172.16.1.3 hostname; echo "exit=$?"
```

Output:

```text
Your account has expired; please contact your system administrator.
Connection closed by 172.16.1.3 port 22
exit=255
```

A valid key still fails if the account is expired (`chage -E 0`), the shell is `nologin`, or `AllowUsers`/`AllowGroups` excludes the user. The server log names each: `account ... has expired`, `not allowed because none of user's groups are listed`.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Daemon down or wrong port | `Connection refused`; `ss -tlnp` empty on 22 | Start `sshd`; check `Port` and `ss` |
| Firewall or security group | `Connection timed out`; `nc -vz` times out | Allow 22 in the firewall and cloud rules |
| Changed host key | `REMOTE HOST IDENTIFICATION HAS CHANGED` | Verify the new fingerprint, then `ssh-keygen -R host` |
| Home or `.ssh` permissions | Log: `bad ownership or modes for directory` | `chmod 755 ~`, `700 ~/.ssh`, `600 authorized_keys` |
| SELinux label | Log: `Could not open ... authorized keys ... Permission denied`, AVC | `restorecon -Rv ~/.ssh` |
| No/blocked key | `Permission denied (publickey)`; key not offered | Install the key, or fix `AllowUsers`/`AllowGroups` |
| Account state | Log: `account has expired`, `nologin` shell | `chage -E -1`, set a real shell |
| Too many keys / penalty | `Too many authentication failures`, `kex_exchange_identification: ... reset` | `IdentitiesOnly yes`; wait out the penalty |

---

## Fix

For the captured case (group-writable home):

```bash
sudo chmod 755 /home/deploy    # on web
sudo restorecon -Rv /home/deploy/.ssh    # if the label was also wrong
ssh deploy@172.16.1.3 hostname    # from client, confirm
```

---

## Prevention

- Keep console access (cloud serial console, IPMI) so a bad `sshd` change is recoverable.
- Change `sshd_config` with `sshd -t`, a reload (not restart), and a second open session.
- Manage keys and account state with configuration management, so permissions and labels stay correct.
- Publish host-key fingerprints, so a rebuild does not look like an attack.

---

## Related

- [SSH Troubleshooting](../../14-ssh-and-remote-access/ssh-troubleshooting.md): the full command-by-command version
- [sshd Server](../../14-ssh-and-remote-access/sshd-server.md): `AllowGroups`, `Match` and drop-ins
- [SELinux](../../15-security/selinux.md): `ssh_home_t` and `restorecon`

Captured on Ubuntu 24.04.4 (OpenSSH 9.6p1) and Rocky Linux 10.2 (OpenSSH 9.9p1, SELinux enforcing) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
