# SSH Client

The OpenSSH client opens an encrypted session to a remote host, checks the host's identity against `known_hosts`, and proves the user's identity, usually with a key pair. Every remote task in operations (a shell, a command, a file copy, a tunnel) starts with this client and its configuration file.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Key type | `ed25519` is the default choice; RSA keys need 3072 bits or more | `ssh-keygen -l -f ~/.ssh/id_ed25519.pub` |
| Key files | Private key `~/.ssh/id_ed25519` (mode `600`), public key `.pub` (mode `644`), directory `~/.ssh` (mode `700`) | `ls -la ~/.ssh` |
| Server side | Public keys go into `~/.ssh/authorized_keys` of the target user | `ssh-copy-id user@host` |
| Host identity | First connection asks to trust the host key; the answer is stored in `~/.ssh/known_hosts` | `ssh-keygen -F host` |
| Hashed hosts | Ubuntu sets `HashKnownHosts yes`, so entries hold a hash instead of the host name; RHEL stores names in clear text | `ssh -G host` |
| Agent | `ssh-agent` holds decrypted keys; `ssh-add` loads them; `SSH_AUTH_SOCK` points to it | `ssh-add -l` |
| Config order | Command line, then `~/.ssh/config`, then `/etc/ssh/ssh_config`; the first value found wins | `ssh -G host` |
| Bastion | `ProxyJump` (`-J`) connects through a jump host without copying keys to it | `ssh -J gw web` |
| Scripts | `BatchMode=yes` fails instead of prompting; `ConnectTimeout` bounds the wait | `ssh -o BatchMode=yes host true` |
| Exit status | The remote command's status, or `255` for an SSH error | `ssh host false; echo $?` |
| Escape keys | `~.` kills a hung session, `~?` lists escapes; only after a newline | type `Enter ~ .` |
<!-- --8<-- [end:facts] -->

---

## Generating a Key Pair

The lab user `ops` on `client` (Ubuntu 24.04) creates an `ed25519` key and protects it with a passphrase. The passphrase encrypts the private key on disk, so a copied file is useless without it.

```bash
ssh-keygen -t ed25519 -C "ops@client"
ls -la ~/.ssh
```

Output:

```text
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/ops/.ssh/id_ed25519): 
Created directory '/home/ops/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/ops/.ssh/id_ed25519
Your public key has been saved in /home/ops/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc ops@client
The key's randomart image is:
# ... (trimmed)
total 16
drwx------ 2 ops ops 4096 Sep 17 13:11 .
drwxr-x--- 3 ops ops 4096 Sep 17 13:11 ..
-rw------- 1 ops ops  444 Sep 17 13:11 id_ed25519
-rw-r--r-- 1 ops ops   92 Sep 17 13:11 id_ed25519.pub
```

`ssh-keygen` created `~/.ssh` with mode `700` and the private key with mode `600`. The `-C` comment only labels the key in `authorized_keys`; it has no security meaning.

!!! warning "The private key never leaves the client"
    Only the `.pub` file is copied to servers. A private key pasted into a ticket, a chat or a CI log must be treated as leaked: remove its public half from every `authorized_keys` file and generate a new pair.

---

## Loading the Key into the Agent

`ssh-agent` keeps the decrypted key in memory, so the passphrase is typed once per session instead of once per connection.

```bash
eval "$(ssh-agent -s)"
ssh-add
ssh-add -l
```

Output:

```text
Agent pid 40959
Enter passphrase for /home/ops/.ssh/id_ed25519: 
Identity added: /home/ops/.ssh/id_ed25519 (ops@client)
256 SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc ops@client (ED25519)
```

`eval` exports `SSH_AUTH_SOCK` and `SSH_AGENT_PID` into the current shell. Desktop sessions start an agent automatically; on a server, `ssh-agent -k` stops the one started here.

---

## First Connection and Host Keys

On the first connection the client has no record of the server's host key and asks the user to confirm its fingerprint. The server `gw` (Rocky Linux 10.2) still allows password login, as a default RHEL install does.

```bash
ssh deploy@172.16.0.3 hostname
```

Output:

```text
The authenticity of host '172.16.0.3 (172.16.0.3)' can't be established.
ED25519 key fingerprint is SHA256:xb+ywcKDhWj9AOErdum+RyWaTDil1G4dbkXU6ViI0dQ.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.16.0.3' (ED25519) to the list of known hosts.
deploy@172.16.0.3's password: 
gw
```

The fingerprint must be compared with the one the server's owner publishes, or read on the server's console:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub    # run on web
```

Output:

```text
256 SHA256:eRhMpZF20pabpWe/Uw3mgf0WX9WjfR5jtw/WF83Ws98 sshd@web (ED25519)
```

This value matched the prompt shown later for `web`. Typing `yes` without checking defeats the protection against a man in the middle.

!!! danger "A changed host key is a stop sign"
    When a known host presents a different key, `ssh` refuses to connect with `REMOTE HOST IDENTIFICATION HAS CHANGED`. A rebuilt server explains it; an unexplained change does not. [SSH Troubleshooting](ssh-troubleshooting.md) shows the message and the safe way to replace the entry.

---

## Installing the Public Key

`ssh-copy-id` appends the public key to the remote `~/.ssh/authorized_keys` and fixes its permissions. It needs one working login, here the password.

```bash
ssh-copy-id deploy@172.16.0.3
ssh deploy@172.16.0.3 'hostname; id -un'
ssh -v deploy@172.16.0.3 true 2>&1 | grep -E 'Authentications that|Offering|Server accepts|Authenticated to'
```

Output:

```text
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
deploy@172.16.0.3's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'deploy@172.16.0.3'"
and check to make sure that only the key(s) you wanted were added.

gw
deploy
debug1: Authentications that can continue: publickey,gssapi-keyex,gssapi-with-mic,password
debug1: Offering public key: /home/ops/.ssh/id_ed25519 ED25519 SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc agent
debug1: Server accepts key: /home/ops/.ssh/id_ed25519 ED25519 SHA256:m3bfLnRraTXmk+Nhgs9GkaSIC4VaKbzPVWNPMrdK6uc agent
Authenticated to 172.16.0.3 ([172.16.0.3]:22) using "publickey".
```

The `-v` lines show the whole exchange: the server lists the methods it accepts, the client offers the key from the agent, and the server accepts it.

The iximiuz Labs images end `sshd_config` with `AuthenticationMethods publickey`, as many cloud images disable passwords. On `web` the key was therefore placed by root, the way cloud-init installs a key at first boot, and the first login only asks about the host key:

```bash
ssh deploy@172.16.1.3 hostname
```

Output:

```text
The authenticity of host '172.16.1.3 (172.16.1.3)' can't be established.
ED25519 key fingerprint is SHA256:eRhMpZF20pabpWe/Uw3mgf0WX9WjfR5jtw/WF83Ws98.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.16.1.3' (ED25519) to the list of known hosts.
web
```

---

## The known_hosts File

Ubuntu hashes host names in `known_hosts`, so the file does not reveal which servers a user reaches. `ssh-keygen -F` still finds an entry by name.

=== "RHEL / Rocky"

    ```bash
    ssh -G 172.16.1.3 2>/dev/null | grep -E '^(hashknownhosts|stricthostkeychecking|userknownhostsfile) '
    ```

    Output:

    ```text
    hashknownhosts no
    stricthostkeychecking ask
    userknownhostsfile /home/deploy/.ssh/known_hosts /home/deploy/.ssh/known_hosts2
    ```

=== "Ubuntu / Debian"

    ```bash
    ssh -G 172.16.1.3 2>/dev/null | grep -E '^(hashknownhosts|stricthostkeychecking|userknownhostsfile) '
    cut -c1-50 ~/.ssh/known_hosts
    ssh-keygen -F 172.16.1.3 | cut -c1-60
    ```

    Output:

    ```text
    hashknownhosts yes
    stricthostkeychecking ask
    userknownhostsfile /home/ops/.ssh/known_hosts /home/ops/.ssh/known_hosts2
    |1|o1h15kkau3czsup2LhmOuMw8IJU=|p1trVgl0FhMUY98HjV
    |1|X6mf62GQxpuwfHwbqnqaypmP5iU=|DyLhnq96IrqFprYcp6
    # Host 172.16.1.3 found: line 2 
    |1|X6mf62GQxpuwfHwbqnqaypmP5iU=|DyLhnq96IrqFprYcp6pfsvGapJU=
    ```

`StrictHostKeyChecking accept-new` stores unknown keys without asking but still refuses changed ones, which suits automation better than `no`.

---

## The Client Configuration File

`~/.ssh/config` turns long command lines into short host aliases. Here `web` is reached through `gw`, the pattern used for a bastion host in front of private servers.

```bash
cat > ~/.ssh/config <<'EOF'
Host gw
    HostName 172.16.0.3
    User deploy

Host web
    HostName 172.16.1.3
    User deploy
    ProxyJump gw

Host *
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 30
EOF
chmod 600 ~/.ssh/config
ssh -G web 2>/dev/null | grep -E '^(hostname|user|port|proxyjump|identityfile|identitiesonly|serveraliveinterval) '
ssh web 'echo $SSH_CONNECTION'
ssh gw 'echo $SSH_CONNECTION'
```

Output:

```text
user deploy
hostname 172.16.1.3
port 22
identitiesonly yes
serveraliveinterval 30
identityfile ~/.ssh/id_ed25519
proxyjump gw
172.16.1.2 39392 172.16.1.3 22
172.16.0.2 34440 172.16.0.3 22
```

`ssh -G` prints the final configuration without connecting, which settles questions about which block matched. `SSH_CONNECTION` on `web` shows the source `172.16.1.2`, the jump host's address, so the session really went through `gw`. Specific `Host` blocks come before `Host *`, because the first value found for each option wins.

!!! tip "ProxyJump instead of agent forwarding"
    `ProxyJump` carries the encrypted session through the bastion, and the key never leaves the client. `ForwardAgent yes` lets root on the bastion use the forwarded agent to log in anywhere the key is accepted, so it belongs only on trusted hosts.

---

## Remote Commands and Scripts

A command after the host name runs remotely and its exit status becomes the exit status of `ssh`. `bash -s` reads a whole script from standard input.

```bash
ssh web 'uptime; df -h / | tail -1'
ssh web 'bash -s' <<'EOF'
echo "running on $(hostname) as $(id -un)"
systemctl is-active nginx named
EOF
ssh -o BatchMode=yes -o ConnectTimeout=5 deploy@172.16.0.9 true; echo "exit=$?"
```

Output:

```text
 13:14:33 up 19 min,  1 user,  load average: 0.00, 0.02, 0.00
/dev/root        20G  1.9G   17G  10% /
running on web as deploy
active
active
ssh: connect to host 172.16.0.9 port 22: No route to host
exit=255
```

Quoting decides where expansion happens: single quotes send `$(hostname)` to the remote shell, double quotes expand it locally first. Exit status `255` marks an SSH failure, so scripts can tell it apart from a failing remote command.

---

## Common Errors

### `Permission denied (publickey)`

**Cause:** the server accepts only keys, and no offered key is in the target user's `authorized_keys` (or the file's permissions are wrong).

**Fix:** check `ssh -v` for the `Offering public key` lines, then the server log; [SSH Troubleshooting](ssh-troubleshooting.md) has the full ladder.

### `ssh: connect to host 172.16.0.9 port 22: No route to host`

**Cause:** no host answered ARP for the address, or a firewall rejected the packet with an ICMP message.

**Fix:** confirm the address and the route with `ip route get 172.16.0.9`, then test the port with `nc -vz`.

### `Bad owner or permissions on /home/ops/.ssh/config`

**Cause:** the client configuration file is writable by other users (here mode `666`). Mode `664` passed in the capture, because the `ops` group has no other members.

**Fix:** `chmod 600 ~/.ssh/config`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How does key-based SSH authentication work?"
    **Say first:** the server holds the public key in `authorized_keys`, and the client proves it owns the matching private key by signing session data; the private key never crosses the network.

    **Proof:** `ssh -v host` shows `Offering public key` and `Server accepts key`.

    **Follow-up:** What does a passphrase add, and how does `ssh-agent` keep that practical?

??? question "L1: What is known_hosts for?"
    **Say first:** it records each server's host key, so the client detects a different server answering on the same address.

    **Proof:** `ssh-keygen -F 172.16.1.3`

    **Follow-up:** When is `StrictHostKeyChecking accept-new` acceptable, and why not `no`?
<!-- --8<-- [end:l1] -->

??? question "L2: Set up passwordless login to a new server."
    **Say first:** generate a key pair, install the public key with `ssh-copy-id`, then confirm the key is used.

    **Proof:**

    ```bash
    ssh-keygen -t ed25519 -C "ops@client"
    ssh-copy-id deploy@172.16.0.3
    ssh -v deploy@172.16.0.3 true 2>&1 | grep Authenticated
    ```

    **Follow-up:** How is the first key installed when the server allows no passwords?

??? question "L2: Reach a private server through a bastion with one command."
    **Say first:** use `ProxyJump`, on the command line as `-J` or in `~/.ssh/config`.

    **Proof:** `ssh -J deploy@172.16.0.3 deploy@172.16.1.3`, or `ProxyJump gw` in the `web` block; `echo $SSH_CONNECTION` on the target shows the bastion as the source.

    **Follow-up:** Why is `ProxyJump` safer than agent forwarding?

??? question "L2: Show which settings ssh will use for a host without connecting."
    **Say first:** `ssh -G` prints the merged configuration.

    **Proof:** `ssh -G web | grep -E '^(hostname|user|proxyjump) '`

    **Follow-up:** Two `Host` blocks set `User`. Which one wins?

??? question "L2: A script runs ssh in a loop over 50 servers and hangs on one. How do you make it fail fast?"
    **Say first:** set `BatchMode=yes` so it never prompts and `ConnectTimeout` so it never waits long, then check for exit status `255`.

    **Proof:** `ssh -o BatchMode=yes -o ConnectTimeout=5 deploy@172.16.0.9 true; echo $?` prints `255`.

    **Follow-up:** How do you also stop it hanging on a new host key?

??? question "L3: ssh to a server worked yesterday and now asks for a password. What do you check?"
    **Say first:** find out whether the client still offers the key and whether the server still accepts it, before touching the server.

    **Proof:** `ssh -v` (is the key offered, from which file or agent); `ssh-add -l` (agent empty after a reboot); `ssh -G host | grep identityfile`; then on the server `authorized_keys` content and permissions and the `sshd` log.

    **Follow-up:** The log says `Authentication refused: bad ownership or modes`. What changed?

??? question "L3: A session over a VPN freezes after some idle minutes. What is happening and what fixes it?"
    **Say first:** a NAT device or firewall dropped the idle connection state, so packets from either side go nowhere.

    **Proof:** `ServerAliveInterval 30` in `~/.ssh/config` (or `ClientAliveInterval` on the server) keeps traffic flowing; `Enter ~ .` closes the frozen session.

    **Follow-up:** What does `ServerAliveCountMax` change?

---

## Related

- [SSH Deep Dive](../../ssh/ssh-deep-dive.md): the handshake and key exchange in detail
- [SSH Tunnels](ssh-tunnels.md): forwarding ports through the same connection
- [sshd Server](sshd-server.md): the server side of these settings
- [SSH Troubleshooting](ssh-troubleshooting.md): reading `ssh -v` and the server log

Captured on Ubuntu 24.04.4 (OpenSSH 9.6p1) and Rocky Linux 10.2 (OpenSSH 9.9p1) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
