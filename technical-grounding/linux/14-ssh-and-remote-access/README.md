# SSH and Remote Access

How operators reach Linux servers: the OpenSSH client and its keys, port forwarding, the `sshd` server and its hardening, file transfer over SSH, and a ladder for failed logins. The protocol itself (key exchange and the two phases of a connection) is covered in the [SSH deep dive](../../ssh/ssh-deep-dive.md).

---

## Revision Card

| Fact | Value |
|---|---|
| Keys | `ssh-keygen -t ed25519`; private `600`, `~/.ssh` `700`, `authorized_keys` `600` |
| Install a key | `ssh-copy-id user@host` (needs one working login) |
| Host keys | Stored in `~/.ssh/known_hosts`; a change stops the login with `REMOTE HOST IDENTIFICATION HAS CHANGED` |
| Client config | `~/.ssh/config` `Host` blocks; first value wins; `ssh -G host` prints the result |
| Bastion | `ProxyJump` (`-J`), not agent forwarding |
| Tunnels | `-L` listens on the client, `-R` on the server, `-D` is a SOCKS proxy; `-f -N` for background |
| Server config | Drop-ins in `sshd_config.d/` are read first and win; `sshd -t` checks, `sshd -T` shows |
| Units | RHEL `sshd.service`; Ubuntu 24.04 `ssh.socket` (port changes need `daemon-reload`) |
| RHEL port change | `semanage port -a -t ssh_port_t -p tcp PORT` plus a firewall rule |
| SFTP jail | `Match Group` + `ChrootDirectory` (root-owned) + `ForceCommand internal-sftp` |
| rsync | Trailing slash copies contents; `-n --delete` to preview deletions |
| Failed login | `ssh -v` shows the stage; the server log shows the reason |
| Refused vs timeout | Refused: nothing listens; timeout: dropped on the way |
| Key rejected | StrictModes (group-writable home), SELinux label (`ssh_home_t`), `AllowUsers`/`AllowGroups` |
| Penalties | OpenSSH 9.8+ refuses sources that keep failing (`kex_exchange_identification: ... reset`) |
| Slow login | `UseDNS yes` or GSSAPI with broken DNS |

| Task | Command |
|---|---|
| New key and agent | `ssh-keygen -t ed25519 -C "me@laptop"; eval "$(ssh-agent -s)"; ssh-add` |
| Through a bastion | `ssh -J deploy@bastion deploy@10.0.1.5` |
| Reach a loopback-only port | `ssh -f -N -L 9000:127.0.0.1:8008 host` |
| Remove an old host key | `ssh-keygen -R host` |
| Test sshd config | `sudo sshd -t && sudo systemctl reload sshd` |
| Effective settings for a user | `sudo sshd -T -C user=partner,host=h,addr=10.0.0.5` |
| Debug a login | `ssh -v user@host`; `sudo journalctl -u sshd -n 30` |
| Mirror a directory | `rsync -a --delete src/ host:/dst/` |
| Copy without rsync | `tar czf - dir` piped into `ssh host 'tar xzf - -C /dst'` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [SSH Client](ssh-client.md) | Keys, agent, host keys, `~/.ssh/config`, `ProxyJump`, remote commands | Core | High |
| [SSH Tunnels](ssh-tunnels.md) | `-L`, `-R`, `-D`, background tunnels, `AllowTcpForwarding` | Core | Med |
| [sshd Server](sshd-server.md) | Drop-ins and precedence, hardening, SFTP chroot, port changes | Core | Med |
| [File Transfer](file-transfer.md) | `scp`, `rsync`, `sftp`, `tar` over SSH | Core | Med |
| [SSH Troubleshooting](ssh-troubleshooting.md) | `ssh -v` stages, refused vs timeout, host keys, key rejection, penalties, slow logins | Core | High |

---

## Scenarios and Labs

- [Cannot SSH](../interview/scenarios/cannot-ssh.md): a login that fails at the network, the key, the account and SELinux in turn
- [Security Lab](../labs/security-lab.md): keys and a bastion, sshd hardening, firewalls, SELinux, TLS and auditing on three VMs

The lab network: `client` (Ubuntu, `172.16.0.2`, user `ops`), `gw` (Rocky, `172.16.0.3` and `172.16.1.2`) and `web` (Rocky, `172.16.1.3`), with the user `deploy` on both Rocky hosts.
