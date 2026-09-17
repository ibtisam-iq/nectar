# sshd Server

`sshd` is the OpenSSH server: it reads `/etc/ssh/sshd_config` and its drop-in files, listens on port 22, and decides who may log in and how. A wrong line can lock every administrator out, so changes are tested with `sshd -t` and read back with `sshd -T` before a reload.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Files | `/etc/ssh/sshd_config`, drop-ins in `/etc/ssh/sshd_config.d/*.conf` (included near the top), host keys `/etc/ssh/ssh_host_*_key` | `grep -n Include /etc/ssh/sshd_config` |
| Precedence | The first value read for an option wins, so an early drop-in beats the main file | `sudo sshd -T` |
| Test and dump | `sshd -t` checks syntax; `sshd -T` prints the effective settings; `-C user=,host=,addr=` evaluates `Match` blocks | `sudo sshd -t && echo ok` |
| Apply | `systemctl reload sshd` (RHEL) or `ssh` (Ubuntu 24.04, started by `ssh.socket`); existing sessions survive a reload | `systemctl list-sockets` |
| Key settings | `PermitRootLogin` (default `prohibit-password`, shown as `without-password`), `PasswordAuthentication` (default `yes`), `AllowUsers`, `AllowGroups`, `MaxAuthTries` (default 6) | `sudo sshd -T` |
| Penalties | OpenSSH 9.8 and later delay sources that fail authentication (`PerSourcePenalties`) | `sudo sshd -T` |
| SFTP jail | `Match Group` with `ChrootDirectory` and `ForceCommand internal-sftp`; the chroot path must be owned by root and not group- or world-writable | `ls -ld /srv/sftp/*` |
| Brute force | Key-only login, then `fail2ban` bans repeated failures (EPEL on RHEL) | `sudo fail2ban-client status sshd` |
<!-- --8<-- [end:facts] -->

---

## Where the Configuration Comes From

On `gw` (Rocky Linux 10.2), the main file includes the drop-ins at line 15 and the playground image appends two lines at the end.

```bash
grep -n -E '^(Include|AuthenticationMethods|Subsystem)' /etc/ssh/sshd_config
ls /etc/ssh/sshd_config.d/
sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|maxauthtries|x11forwarding) '
```

Output:

```text
15:Include /etc/ssh/sshd_config.d/*.conf
123:Subsystem	sftp	/usr/libexec/openssh/sftp-server
132:AuthenticationMethods publickey
00-lab-auth.conf
40-redhat-crypto-policies.conf
50-redhat.conf
port 22
maxauthtries 50
permitrootlogin without-password
passwordauthentication yes
x11forwarding yes
```

`00-lab-auth.conf` sets `AuthenticationMethods any` for the lab, so line 132 never takes effect: the drop-in is read first. `maxauthtries 50` also comes from the playground image (line 136); the OpenSSH default is 6. `50-redhat.conf` turns on `X11Forwarding`, which the hardening below turns off again.

`sshd -t` parses every file and names the file and line of an error. A reload with a broken file fails, and a restart leaves no daemon at all.

```bash
printf 'PermitRootLogin no\nPasswordAuthentcation no\n' | sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null
sudo sshd -t; echo "exit=$?"
```

Output:

```text
/etc/ssh/sshd_config.d/10-hardening.conf: line 2: Bad configuration option: PasswordAuthentcation
/etc/ssh/sshd_config.d/10-hardening.conf: terminating, 1 bad configuration options
exit=255
```

!!! warning "Keep a second session open while changing sshd"
    Reloading does not end existing sessions, so a root shell that stays open can undo a mistake. Test a new login from another terminal before closing it, and keep console access (cloud serial console, iximiuz terminal, IPMI) in mind.

---

## A Hardening Drop-In

The corrected file disables root and password logins and limits SSH to one group. A later file that sets `PasswordAuthentication yes` shows the first-value rule.

```bash
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
X11Forwarding no
AllowGroups sshusers
EOF
echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/99-late.conf >/dev/null
sudo groupadd sshusers
sudo usermod -aG sshusers deploy
sudo sshd -t && sudo systemctl reload sshd
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|maxauthtries|x11forwarding|allowgroups) '
```

Output:

```text
maxauthtries 3
permitrootlogin no
passwordauthentication no
x11forwarding no
allowgroups sshusers
```

`99-late.conf` lost to `10-hardening.conf`, and `X11Forwarding no` beat `50-redhat.conf` the same way. From `client`, a password login and a user outside the group fail with the same message (key logins for `deploy` still work), and only the server log tells them apart:

```bash
ssh -o PubkeyAuthentication=no deploy@172.16.0.3 true; echo "exit=$?"    # on client
ssh alice@172.16.0.3 id -un
sudo journalctl -u sshd --since -2min | grep alice    # on gw
```

Output:

```text
deploy@172.16.0.3: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
exit=255
alice@172.16.0.3: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
Sep 17 15:54:48 gw sshd-session[4751]: User alice from 172.16.0.2 not allowed because none of user's groups are listed in AllowGroups
Sep 17 15:54:48 gw sshd-session[4751]: Connection closed by invalid user alice 172.16.0.2 port 51302 [preauth]
```

`password` disappeared from the list of methods the server offers. `alice` has a valid key, but `AllowGroups` rejects her before the key is checked.

---

## An SFTP-Only Chroot

A `Match` block applies settings to some users only. Here members of `sftponly` get a jail at `/srv/sftp/<user>`, no shell, and keys from a root-owned file.

```bash
sudo groupadd sftponly
sudo useradd -M -d /upload -g sftponly -G sshusers -s /sbin/nologin partner
sudo mkdir -p /srv/sftp/partner/upload /etc/ssh/authorized_keys
sudo chown partner:sftponly /srv/sftp/partner /srv/sftp/partner/upload
sudo install -m 644 /home/deploy/.ssh/authorized_keys /etc/ssh/authorized_keys/partner
sudo tee /etc/ssh/sshd_config.d/30-sftp.conf >/dev/null <<'EOF'
Match Group sftponly
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    AuthorizedKeysFile /etc/ssh/authorized_keys/%u
    AllowTcpForwarding no
    X11Forwarding no
EOF
sudo sshd -t && sudo systemctl reload sshd
```

The first `sftp` login from `client` ended with `Connection closed`. The server log gives the reason, and the fix is ownership of the chroot directory:

```bash
sudo journalctl -u sshd --since -1min | grep partner | tail -3
sudo chown root:root /srv/sftp/partner
sudo chmod 755 /srv/sftp/partner
```

Output:

```text
Sep 17 15:55:15 gw sshd-session[4931]: pam_unix(sshd:session): session opened for user partner(uid=1004) by partner(uid=0)
Sep 17 15:55:15 gw sshd-session[4931]: fatal: bad ownership or modes for chroot directory "/srv/sftp/partner" [postauth]
Sep 17 15:55:15 gw sshd-session[4931]: pam_unix(sshd:session): session closed for user partner
```

After the fix the login worked; [File Transfer](file-transfer.md#sftp-sessions) shows the jailed session.

---

## Changing the Port

=== "RHEL / Rocky"

    SELinux allows `sshd` to bind only ports labeled `ssh_port_t`. `sshd -t` passes, and only the log shows the failed bind.

    ```bash
    printf 'Port 22\nPort 2222\n' | sudo tee /etc/ssh/sshd_config.d/05-port.conf >/dev/null
    sudo systemctl reload sshd
    sleep 1
    sudo journalctl -u sshd --since -10s | grep -i -E 'bind|listening'
    sudo semanage port -a -t ssh_port_t -p tcp 2222
    sudo semanage port -l | grep ^ssh_port_t
    sudo systemctl reload sshd
    sleep 1
    sudo ss -tlnp | grep sshd
    ```

    Output:

    ```text
    Sep 17 15:55:39 gw sshd[4582]: error: Bind to port 2222 on 0.0.0.0 failed: Permission denied.
    Sep 17 15:55:39 gw sshd[4582]: error: Bind to port 2222 on :: failed: Permission denied.
    Sep 17 15:55:39 gw sshd[4582]: Server listening on 0.0.0.0 port 22.
    Sep 17 15:55:39 gw sshd[4582]: Server listening on :: port 22.
    ssh_port_t                     tcp      2222, 22
    LISTEN 0      128          0.0.0.0:2222       0.0.0.0:*    users:(("sshd",pid=4582,fd=7))
    LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=4582,fd=9))
    # ... (trimmed)
    ```

    With firewalld running, `sudo firewall-cmd --permanent --add-port=2222/tcp` and a reload open the port as well.

=== "Ubuntu / Debian"

    Ubuntu 24.04 starts `sshd` from `ssh.socket`, so systemd holds the listening socket. A generator turns `Port` lines into socket addresses, and it runs only on `daemon-reload`.

    ```bash
    printf 'Port 22\nPort 2222\n' | sudo tee /etc/ssh/sshd_config.d/05-port.conf >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart ssh.socket
    sudo ss -tlnp '( sport = :22 or sport = :2222 )'
    cat /run/systemd/generator/ssh.socket.d/addresses.conf
    ```

    Output:

    ```text
    State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
    LISTEN 0      4096         0.0.0.0:2222      0.0.0.0:*    users:(("systemd",pid=1,fd=56))
    LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*    users:(("systemd",pid=1,fd=61))
    LISTEN 0      4096            [::]:2222         [::]:*    users:(("systemd",pid=1,fd=57))
    LISTEN 0      4096            [::]:22           [::]:*    users:(("systemd",pid=1,fd=62))
    # Automatically generated by sshd-socket-generator

    [Socket]
    ListenStream=
    ListenStream=0.0.0.0:2222
    ListenStream=[::]:2222
    ListenStream=0.0.0.0:22
    ListenStream=[::]:22
    ```

    With ufw active, `sudo ufw allow 2222/tcp` opens the port.

!!! warning "Restarting ssh does not apply a port change on Ubuntu 24.04"
    In an earlier run, `sudo systemctl restart ssh` without the `daemon-reload` left `ss` showing port 22 only, because systemd, not `sshd`, owns the listening sockets.

---

## Common Errors

### `Bad configuration option: PasswordAuthentcation`

**Cause:** a misspelled or unsupported option in the named file and line.

**Fix:** correct the line, then `sudo sshd -t` before any reload.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do you apply an sshd change safely?"
    **Say first:** check the syntax with `sshd -t`, confirm the effective value with `sshd -T`, reload instead of restart, and test a new login while the old session stays open.

    **Proof:** `sudo sshd -t && sudo systemctl reload sshd`

    **Follow-up:** Why can a drop-in file silently override your change?
<!-- --8<-- [end:l1] -->

??? question "L2: Disable root and password logins on a server."
    **Say first:** set both in an early drop-in and verify with `sshd -T`.

    **Proof:** `PermitRootLogin no` and `PasswordAuthentication no` in `/etc/ssh/sshd_config.d/10-hardening.conf`; `sudo sshd -T | grep -E 'permitroot|passwordauth'`.

    **Follow-up:** A later file sets `PasswordAuthentication yes`. Which value applies?

??? question "L2: Give an external partner SFTP access to one directory only."
    **Say first:** a `Match Group` block with `ChrootDirectory`, `ForceCommand internal-sftp` and forwarding disabled, with a root-owned chroot and a writable subdirectory.

    **Proof:** `sudo sshd -T -C user=partner,host=client,addr=172.16.0.2 | grep chroot`; `sftp partner@host` lands in `/upload`.

    **Follow-up:** What does the log say when the chroot directory belongs to the user?

??? question "L2: Move SSH to port 2222 on RHEL."
    **Say first:** add the `Port` line, label the port for SELinux, open it in firewalld, reload, and test before removing port 22.

    **Proof:** `sudo semanage port -a -t ssh_port_t -p tcp 2222`; `sudo firewall-cmd --permanent --add-port=2222/tcp`; `sudo ss -tlnp | grep sshd`.

    **Follow-up:** What differs on Ubuntu 24.04?

??? question "L3: After an sshd_config change, nobody can log in, but port 22 is open. How do you recover and find the cause?"
    **Say first:** use an existing session or the console, then read the effective configuration and the log instead of guessing.

    **Proof:** `sudo sshd -T | grep -E 'allow|authenticationmethods|passwordauth'`; `sudo journalctl -u sshd -n 30` (for example `not allowed because none of user's groups are listed`); remove the drop-in and reload.

    **Follow-up:** How would `sshd -T -C user=...` have caught it before the reload?

??? question "L3: The auth log shows thousands of failed logins from many addresses. What do you do?"
    **Say first:** confirm no login succeeded, then make guessing useless and reduce the noise.

    **Proof:** `sudo journalctl -u sshd | grep Accepted`; `last`; disable passwords, restrict `AllowGroups` or source addresses in the firewall, add fail2ban.

    **Follow-up:** What does OpenSSH 9.8's `PerSourcePenalties` change for an attacker?

---

## Related

- [SSH Client](ssh-client.md): keys and host keys from the client side
- [SSH Troubleshooting](ssh-troubleshooting.md): reading the server log for failed logins
- [SELinux](../15-security/selinux.md): port labels and denials; the [Hardening Checklist](../15-security/hardening-checklist.md) adds fail2ban

Captured on Rocky Linux 10.2 (OpenSSH 9.9p1) and Ubuntu 24.04.4 (OpenSSH 9.6p1, fail2ban 1.0.2) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
