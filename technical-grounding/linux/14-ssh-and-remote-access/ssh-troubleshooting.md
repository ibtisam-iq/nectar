# SSH Troubleshooting

A failed SSH login breaks at one of four stages: the TCP connection, the host key check, authentication, or the session after it. The client (`ssh -v`) shows which stage failed, and the server log (`journalctl -u sshd`, `/var/log/secure` or `/var/log/auth.log`) shows why.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Client debug | `-v`, `-vv`, `-vvv` add detail; the last `debug1` line before the error names the stage | `ssh -v host true` |
| Server log | RHEL: unit `sshd`, file `/var/log/secure`; Ubuntu: unit `ssh`, file `/var/log/auth.log` | `sudo journalctl -u sshd -n 20` |
| `Connection refused` | The host answered, nothing listens on the port (or a firewall rejects) | `nc -vz host 22` |
| `Connection timed out` | No answer: a firewall drops the packets, or the route is broken | `ssh -o ConnectTimeout=5 host` |
| `Host key verification failed` | The stored key does not match; check why before `ssh-keygen -R host` | `ssh-keygen -F host` |
| `Permission denied (publickey)` | No offered key was accepted; the list in brackets is what the server allows | `ssh -v` |
| StrictModes | Home, `~/.ssh` and `authorized_keys` not writable by group or others: `755` or stricter, `700`, `600` | `namei -l ~/.ssh/authorized_keys` |
| SELinux | `authorized_keys` must be labeled `ssh_home_t`; `mv` keeps the old label | `ls -Z ~/.ssh` |
| Too many keys | Each offered key counts against `MaxAuthTries` | `ssh-add -l` |
| Slow login | Reverse DNS (`UseDNS yes`) or GSSAPI waiting on an unreachable server | `sudo sshd -T` |
| Penalties | OpenSSH 9.8 and later refuse connections from a source that keeps failing | `sudo journalctl -u sshd -g penalty` |
<!-- --8<-- [end:facts] -->

---

## Reading ssh -v

A successful login from `client` (Ubuntu 24.04) to `web` (Rocky Linux 10.2) shows every stage in order. The failure cases below stop at one of these lines.

```bash
ssh -v deploy@172.16.1.3 true 2>&1 | grep -E 'Connecting to|Connection established|Remote protocol|Server host key|Host .* is known|Authentications that|Offering|Server accepts|Authenticated to|Exit status'
```

Output:

```text
debug1: Connecting to 172.16.1.3 [172.16.1.3] port 22.
debug1: Connection established.
debug1: Remote protocol version 2.0, remote software version OpenSSH_9.9
debug1: Server host key: ssh-ed25519 SHA256:eRhMpZF20pabpWe/Uw3mgf0WX9WjfR5jtw/WF83Ws98
debug1: Host '172.16.1.3' is known and matches the ED25519 host key.
debug1: Authentications that can continue: publickey
debug1: Offering public key: /home/ops/.ssh/id_ed25519 ED25519 SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc explicit agent
debug1: Server accepts key: /home/ops/.ssh/id_ed25519 ED25519 SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc explicit agent
Authenticated to 172.16.1.3 ([172.16.1.3]:22) using "publickey".
debug1: Exit status 0
```

| Last line reached | Stage that failed | Look at |
|---|---|---|
| `Connecting to` | TCP connection | route, firewall, `sshd` running and listening |
| `Remote protocol version` | Key exchange | crypto policies, old algorithms, penalties |
| `Server host key` | Host key check | `known_hosts`, a rebuilt or different server |
| `Offering public key` | Authentication | `authorized_keys`, modes, SELinux, `AllowUsers`, the server log |
| `Authenticated to` | Session | shell, PAM account checks, `ForceCommand`, profile scripts |

---

## Refused or Timed Out

The two network errors point to different causes. On `web`, `sshd` was stopped for the first test; for the second, it ran again and an nftables rule dropped port 22 from `client`.

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

```bash
time ssh -o ConnectTimeout=5 deploy@172.16.1.3 true; echo "exit=$?"
nc -vz -w3 172.16.1.3 22
```

Output:

```text
ssh: connect to host 172.16.1.3 port 22: Connection timed out

real	0m5.008s
user	0m0.000s
sys	0m0.003s
exit=255
nc: connect to 172.16.1.3 port 22 (tcp) timed out: Operation now in progress
```

Refused answers at once: check `systemctl status sshd` and `ss -tlnp` on the server. Timed out waits for `ConnectTimeout`: check security groups, firewalls and routes, as in the [Troubleshooting Ladder](../13-networking/troubleshooting-ladder.md).

---

## Host Key Changed

`web` got a new host key, as happens after a rebuild. The client refuses to connect and names the stored line.

```bash
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub    # on web
ssh deploy@172.16.1.3 true; echo "exit=$?"               # on client
```

Output:

```text
256 SHA256:6eIBSyf00uZxZaJOSrOLN4WV0mhQIu63a3xOOEkT1sU sshd@web (ED25519)
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:6eIBSyf00uZxZaJOSrOLN4WV0mhQIu63a3xOOEkT1sU.
Please contact your system administrator.
Add correct host key in /home/ops/.ssh/known_hosts to get rid of this message.
Offending ED25519 key in /home/ops/.ssh/known_hosts:2
  remove with:
  ssh-keygen -f '/home/ops/.ssh/known_hosts' -R '172.16.1.3'
Host key for 172.16.1.3 has changed and you have requested strict checking.
Host key verification failed.
exit=255
```

The fingerprint in the warning matches the one read on the server's console, so the change is explained. Only then is the old entry removed with `ssh-keygen -R 172.16.1.3`, which printed `/home/ops/.ssh/known_hosts updated.` and kept a copy in `known_hosts.old`; the next login asked to trust the new key.

!!! danger "Never disable host key checking to make the warning go away"
    `StrictHostKeyChecking no` or `UserKnownHostsFile /dev/null` removes the only protection against a man in the middle, and the password or agent is then offered to whoever answers.

---

## Permission denied (publickey)

The client log shows only that the offered key was not accepted. Here the home directory of `deploy` on `web` had become group-writable (`chmod 775`).

```bash
ssh -v deploy@172.16.1.3 true 2>&1 | grep -E 'Authentications that|Offering|No more authentication|Permission denied'
```

Output:

```text
debug1: Authentications that can continue: publickey
debug1: Offering public key: /home/ops/.ssh/id_ed25519 ED25519 SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc explicit agent
debug1: Authentications that can continue: publickey
debug1: No more authentication methods to try.
deploy@172.16.1.3: Permission denied (publickey).
```

The server log has the reason, and `namei -l` shows every directory on the path:

```bash
sudo journalctl -u sshd --since -1min | grep -v 'Connection closed'
namei -l /home/deploy/.ssh/authorized_keys
sudo chmod 755 /home/deploy
```

Output:

```text
# ... (trimmed)
Sep 17 15:59:34 web sshd-session[89810]: Authentication refused: bad ownership or modes for directory /home/deploy
Sep 17 15:59:44 web sshd-session[89816]: Authentication refused: bad ownership or modes for directory /home/deploy
f: /home/deploy/.ssh/authorized_keys
drwxr-xr-x root   root   /
drwxr-xr-x root   root   home
drwxrwxr-x deploy deploy deploy
drwx------ deploy deploy .ssh
-rw------- deploy deploy authorized_keys
```

The second case is SELinux. After the fix, `deploy` replaced the key file with one prepared in `/tmp`. The modes were correct, but `mv` kept the SELinux label of `/tmp`.

```bash
cp ~/.ssh/authorized_keys /tmp/keys.new
mv /tmp/keys.new ~/.ssh/authorized_keys
ls -lZ ~/.ssh/authorized_keys
```

Output:

```text
-rw-------. 1 deploy deploy system_u:object_r:tmp_t:s0 92 Sep 17 16:00 /home/deploy/.ssh/authorized_keys
```

The client again printed `Permission denied (publickey)`. On the server:

```bash
sudo journalctl -u sshd --since -1min | grep -v 'Connection closed'
sudo ausearch -m AVC -ts recent | grep -o 'avc: .*' | head -2
sudo restorecon -v /home/deploy/.ssh/authorized_keys
```

Output:

```text
# ... (trimmed)
Sep 17 16:00:12 web sshd-session[89924]: Could not open user 'deploy' authorized keys '/home/deploy/.ssh/authorized_keys': Permission denied
Sep 17 16:00:12 web sshd-session[89927]: Could not open user 'deploy' authorized keys '/home/deploy/.ssh/authorized_keys': Permission denied
avc:  denied  { open } for  pid=89924 comm="sshd-session" path="/home/deploy/.ssh/authorized_keys" dev="vda" ino=19132 scontext=system_u:system_r:sshd_session_t:s0-s0:c0.c1023 tcontext=system_u:object_r:tmp_t:s0 tclass=file permissive=0
avc:  denied  { open } for  pid=89927 comm="sshd-session" path="/home/deploy/.ssh/authorized_keys" dev="vda" ino=19132 scontext=system_u:system_r:sshd_session_t:s0-s0:c0.c1023 tcontext=system_u:object_r:tmp_t:s0 tclass=file permissive=0
Relabeled /home/deploy/.ssh/authorized_keys from system_u:object_r:tmp_t:s0 to system_u:object_r:ssh_home_t:s0
```

`Permission denied` while the modes are right points to SELinux. `restorecon` resets the label from the policy; `cp` into the directory would have created the right label in the first place.

---

## Account Problems After Authentication

A valid key does not guarantee a session. Three account changes on `web`, each tested from `client` with the same command:

```bash
ssh deploy@172.16.1.3 hostname; echo "exit=$?"
```

| Change on `web` | Client output | Result |
|---|---|---|
| `sudo usermod -s /sbin/nologin deploy` | `This account is currently not available.` then `exit=1` | Authenticated; the shell refused |
| `sudo passwd -l deploy` | `web` then `exit=0` | Key login still works |
| `sudo chage -E 0 deploy` | `Your account has expired; please contact your system administrator.` and `Connection closed by 172.16.1.3 port 22` | Refused by PAM |

The expired account leaves a clear server log entry:

```bash
sudo journalctl -u sshd --since -1min | grep -i -E 'expired|deploy' | tail -3
```

Output:

```text
Sep 17 16:07:48 web sshd-session[91075]: pam_unix(sshd:session): session closed for user deploy
Sep 17 16:08:04 web sshd-session[91179]: pam_unix(sshd:account): account deploy has expired (account expired)
Sep 17 16:08:04 web sshd-session[91179]: fatal: Access denied for user deploy by PAM account configuration [preauth]
```

!!! warning "passwd -l does not block key logins"
    `passwd -l` locks only the password hash (`passwd -S` showed `deploy L`). To stop all logins, expire the account (`chage -E 0`), set a `nologin` shell, or remove the keys, as in [Passwords and Aging](../04-users-and-access/passwords-and-aging.md).

---

## Too Many Authentication Failures

The agent held four keys: `old-laptop`, `ci-runner`, `github` and the real one. `gw` has `MaxAuthTries 3`, and each rejected key counts as a failure.

```bash
ssh -F /dev/null -v -o IdentityFile=/tmp/k/github deploy@172.16.0.3 true 2>&1 | grep -E 'Offering|Received disconnect|Too many|Authenticated'
```

Output:

```text
debug1: Offering public key: /tmp/k/github ED25519 SHA256:MVWmwDVyGmZ1f8CY5cRjbJB0/6Tj1UgsJTLTuDOtLuE explicit agent
debug1: Offering public key: old-laptop ED25519 SHA256:BnbOZ3lnlvyiQXCMWbdCsL1kvzGlBgGAnmhBPtawIzg agent
debug1: Offering public key: ci-runner ED25519 SHA256:Wt0m9XMoB7wC9UBL5zMMUynuhLlZpW5r8Xk09QtOsVg agent
Received disconnect from 172.16.0.3 port 22:2: Too many authentication failures
```

The server closed the connection before the right key was offered. `IdentitiesOnly yes` with one `IdentityFile` per host sends only the intended key.

---

## Refused After Repeated Failures

OpenSSH 9.8 added `PerSourcePenalties`: a source that keeps failing is refused for a while, before any authentication. Eight logins from `client` with no usable key triggered it on `web`.

```bash
for i in 1 2 3 4 5 6 7 8; do ssh -o BatchMode=yes deploy@172.16.1.3 -i /dev/null -o IdentitiesOnly=yes -o IdentityAgent=none true 2>&1 | tail -1; done
ssh deploy@172.16.1.3 hostname; echo "exit=$?"
sudo journalctl -u sshd --since -1min | grep -E 'penalty|drop' | tail -4    # on web
```

Output:

```text
deploy@172.16.1.3: Permission denied (publickey).
deploy@172.16.1.3: Permission denied (publickey).
deploy@172.16.1.3: Permission denied (publickey).
deploy@172.16.1.3: Permission denied (publickey).
deploy@172.16.1.3: Permission denied (publickey).
Connection reset by 172.16.1.3 port 22
Connection closed by 172.16.1.3 port 22
Connection closed by 172.16.1.3 port 22
kex_exchange_identification: read: Connection reset by peer
Connection reset by 172.16.1.3 port 22
exit=255
Sep 17 16:00:42 web sshd[2011]: drop connection #1 from [172.16.0.2]:50982 on [172.16.1.3]:22 penalty: failed authentication
Sep 17 16:00:42 web sshd[2011]: drop connection #0 from [172.16.0.2]:50986 on [172.16.1.3]:22 penalty: failed authentication
Sep 17 16:00:42 web sshd[2011]: drop connection #0 from [172.16.0.2]:51000 on [172.16.1.3]:22 penalty: failed authentication
Sep 17 16:00:42 web sshd[2011]: drop connection #0 from [172.16.0.2]:51010 on [172.16.1.3]:22 penalty: failed authentication
```

Even the correct key failed with `kex_exchange_identification`, a message that usually suggests a firewall or `MaxStartups`. Less than a minute later the same login printed `web` again. Monitoring checks and scripts that retry with a wrong key can lock out a whole NAT address this way; `PerSourcePenaltyExemptList` excludes trusted sources.

---

## Slow Login

For this test, `web` had `UseDNS yes`, an unreachable DNS server, and no `/etc/hosts` entry for the client. Timestamps on each debug line show where the time goes.

```bash
ssh -v deploy@172.16.1.3 true 2>&1 | while IFS= read -r l; do echo "$(date +%T) $l"; done | grep -E 'Connecting to|Connection established|Remote protocol|SSH2_MSG_SERVICE_ACCEPT|Authentications that can continue|Authenticated to|Exit status'
```

Output:

```text
16:05:42 debug1: Connecting to 172.16.1.3 [172.16.1.3] port 22.
16:05:42 debug1: Connection established.
16:05:42 debug1: Remote protocol version 2.0, remote software version OpenSSH_9.9
16:05:42 debug1: SSH2_MSG_SERVICE_ACCEPT received
16:05:48 debug1: Authentications that can continue: publickey
16:05:54 Authenticated to 172.16.1.3 ([172.16.1.3]:22) using "publickey".
16:06:07 debug1: Exit status 0
```

The connection was instant, and the waits of 6, 6 and 13 seconds came during and after authentication. A single `getent hosts 172.16.0.2` on `web` took 6.2 seconds in this state. With the `UseDNS yes` drop-in removed (`UseDNS no` is the default), the same login took `0m0.161s`, although DNS was still broken.

On a slow server, `sudo sshd -T | grep -E 'usedns|gssapi'` and `time getent hosts <client-ip>` confirm the cause. `GSSAPIAuthentication yes`, the RHEL default, can add its own wait, and `ssh -o GSSAPIAuthentication=no` tests that from the client.

---

## Common Errors

### `Authentication refused: bad ownership or modes for directory /home/deploy`

**Cause:** `StrictModes yes` and a home, `.ssh` or key file writable by group or others.

**Fix:** `chmod 755 ~` (or stricter), `chmod 700 ~/.ssh`, `chmod 600 ~/.ssh/authorized_keys`, owner the user.

### `Could not open user 'deploy' authorized keys '/home/deploy/.ssh/authorized_keys': Permission denied`

**Cause:** with correct modes, an SELinux label other than `ssh_home_t`.

**Fix:** `sudo restorecon -Rv ~deploy/.ssh`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between Connection refused and Connection timed out for SSH?"
    **Say first:** refused means the host answered but nothing listens (or a firewall rejects); timed out means nothing answered, usually a dropping firewall or a routing problem.

    **Proof:** `nc -vz -w3 host 22`; `ss -tlnp` on the server for refused, security groups and `nft list ruleset` for timeouts.

    **Follow-up:** Which one does a cloud security group produce?

??? question "L1: Why does sshd reject a key when the home directory is group-writable?"
    **Say first:** `StrictModes` refuses keys that another user could have written, because that user could add their own key.

    **Proof:** the log line `Authentication refused: bad ownership or modes for directory`.

    **Follow-up:** Which files and directories does it check?
<!-- --8<-- [end:l1] -->

??? question "L2: A server was rebuilt and ssh now refuses to connect with a host key warning. Fix it safely."
    **Say first:** confirm the new fingerprint through another channel, then remove the old entry and accept the new key.

    **Proof:** `sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` on the console; `ssh-keygen -R host`.

    **Follow-up:** How do you avoid this for a fleet of rebuilt servers?

??? question "L2: You locked an account with passwd -l, but the user still logs in over SSH. Why, and what do you do?"
    **Say first:** `passwd -l` locks only the password; key authentication does not use it.

    **Proof:** `sudo passwd -S deploy` shows `L`, and the key login still printed `web`; `sudo chage -E 0 deploy` blocked it.

    **Follow-up:** Which log line confirms that PAM refused the login?

??? question "L3: A user gets Permission denied (publickey) on a server where their key is in authorized_keys. Walk through it."
    **Say first:** confirm the client offers the right key, then read the server log, then check modes, ownership, SELinux labels and access rules.

    **Proof:** `ssh -v` (`Offering public key`); `sudo journalctl -u sshd` (`bad ownership or modes`, `Could not open user ... authorized keys`, `not allowed because`); `namei -l`; `ls -Z`; `sudo sshd -T | grep -E 'allowusers|allowgroups|authorizedkeysfile'`.

    **Follow-up:** Modes are correct and the log says `Permission denied` opening the file. What is left?

??? question "L3: SSH logins to one server take 20 seconds, then work. Where is the time going?"
    **Say first:** time each stage with `ssh -v`; waits after `SSH2_MSG_SERVICE_ACCEPT` point to the server's name lookups.

    **Proof:** timestamps show 6-second gaps; `sudo sshd -T | grep usedns` shows `yes`; `time getent hosts <client-ip>` on the server is slow.

    **Follow-up:** Why did the delay persist after authentication?

---

## Related

- [SSH Client](ssh-client.md) and [sshd Server](sshd-server.md): keys, `sshd -T`, `AllowGroups` and `MaxAuthTries`
- [SELinux](../15-security/selinux.md): labels, `restorecon` and AVC messages
- [Cannot SSH](../interview/scenarios/cannot-ssh.md): the interview scenario built on these failures

Captured on Ubuntu 24.04.4 (OpenSSH 9.6p1) and Rocky Linux 10.2 (OpenSSH 9.9p1, SELinux enforcing) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09. The host fingerprints are from disposable lab machines.
