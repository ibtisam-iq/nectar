# SSH Tunnels

SSH port forwarding carries TCP connections inside an existing SSH session, so a port that is closed to the network becomes reachable through the one port that is open. Operators use it to reach loopback-only admin pages, databases behind a bastion, and to publish a local service on a remote host for a short test.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `-L lport:host:hport` | Local forward: the client listens on `lport`, the server connects to `host:hport` | `ss -tlnp 'sport = :lport'` on the client |
| `-R rport:host:hport` | Remote forward: the server listens on `rport`, the client connects to `host:hport` | `ss -tln` on the server |
| `-D port` | Dynamic forward: a SOCKS proxy on the client; the server connects wherever the application asks | `curl --socks5-hostname 127.0.0.1:port URL` |
| Destination view | In `-L`, `host` is resolved and reached from the server, so `127.0.0.1` means the server itself | `ssh -L 9000:127.0.0.1:8008 web` |
| Bind address | Forwards listen on loopback by default; `GatewayPorts` (server) and `-g` or a bind address (client) change that | `ss -tln` |
| Background | `-f` goes to the background after authentication, `-N` runs no remote command | `pgrep -af 'ssh -f'` |
| Failure handling | A failed forward is only a warning unless `ExitOnForwardFailure=yes` | `echo $?` |
| Server switch | `AllowTcpForwarding` (default `yes`) and `PermitOpen` limit forwarding in `sshd` | `sudo sshd -T` |
| Config form | `LocalForward`, `RemoteForward` and `DynamicForward` in `~/.ssh/config` | `ssh -G host` |
<!-- --8<-- [end:facts] -->

---

## Local Forwarding to a Loopback-Only Service

On `web`, nginx serves an admin page on `127.0.0.1:8008` only, so the network cannot reach it. A local forward makes the client's port 9000 lead to that address as seen from `web`. The `web` and `gw` aliases come from the [client configuration file](ssh-client.md#the-client-configuration-file).

```bash
curl -sS -m3 http://172.16.1.3:8008/
ssh -f -N -L 9000:127.0.0.1:8008 web
curl -s http://127.0.0.1:9000/
ss -tlnp 'sport = :9000'
```

Output:

```text
curl: (7) Failed to connect to 172.16.1.3 port 8008 after 0 ms: Couldn't connect to server
admin page on web, loopback only, client=127.0.0.1
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                        
LISTEN 0      128        127.0.0.1:9000      0.0.0.0:*    users:(("ssh",pid=41168,fd=6))
LISTEN 0      128            [::1]:9000         [::]:*    users:(("ssh",pid=41168,fd=3))
```

The listener belongs to the `ssh` process on the client, and nginx sees the request coming from `127.0.0.1` on `web`. Other hosts cannot use port 9000, because the forward binds to loopback.

---

## Local Forwarding to a Third Host

The target of a forward does not have to be the SSH server. Here `gw` is the SSH server, and the connection to the API on `web` starts from `gw`.

```bash
ssh -f -N -L 9001:172.16.1.3:8080 gw
curl -s http://127.0.0.1:9001/
```

Output:

```text
shop-api on web (172.16.1.3:8080) client=172.16.1.2 xff=
```

The API logs `172.16.1.2`, the address of `gw` on the `dmz` network. This is the usual way to reach a database in a private subnet: `ssh -L 5432:db.internal:5432 bastion`.

!!! warning "The hop after the SSH server is not encrypted"
    SSH encrypts traffic between client and `gw`. The connection from `gw` to `web:8080` is plain TCP, as if `gw` had opened it.

---

## Remote Forwarding

A remote forward works the other way round: the SSH server opens the listening port, and connections to it come back to the client. The client runs its own copy of the API on port 8080.

```bash
curl -s http://127.0.0.1:8080/ | head -1
ssh -f -N -R 9080:127.0.0.1:8080 web
sleep 1
ssh web 'curl -s http://127.0.0.1:9080/; ss -tlnp "sport = :9080"'
```

Output:

```text
shop-api on client (127.0.0.1:8080) client=127.0.0.1 xff=
shop-api on client (127.0.0.1:8080) client=127.0.0.1 xff=
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      128        127.0.0.1:9080      0.0.0.0:*          
LISTEN 0      128            [::1]:9080         [::]:*          
```

A request made on `web` was answered by the client. The process column is empty because `deploy` cannot see the `sshd` process of root. The listener stays on loopback while `GatewayPorts` is `no`, the default.

!!! danger "A remote forward can publish a private service"
    With `GatewayPorts yes` on the server, `-R 0.0.0.0:9080:...` exposes a service from inside a private network to everyone who reaches the server. Security teams watch for long-running `ssh -R` processes for this reason.

---

## Dynamic Forwarding (SOCKS Proxy)

`-D` starts a SOCKS proxy on the client. Each application connection names its own destination, and the server opens it.

```bash
ssh -f -N -D 1080 gw
curl -s --socks5-hostname 127.0.0.1:1080 http://172.16.1.3:8080/
```

Output:

```text
shop-api on web (172.16.1.3:8080) client=172.16.1.2 xff=
```

`--socks5-hostname` makes the proxy resolve names too, so internal DNS names work through it. A browser pointed at `127.0.0.1:1080` reaches every internal web page that `gw` can reach.

---

## Listing and Closing Tunnels

Background tunnels are ordinary `ssh` processes. Starting a second forward on a used port shows why `ExitOnForwardFailure` belongs in scripts.

```bash
pgrep -af 'ssh -f'
ssh -f -N -L 9000:127.0.0.1:8008 web; echo "exit=$?"
ssh -f -N -o ExitOnForwardFailure=yes -L 9000:127.0.0.1:8008 web; echo "exit=$?"
pkill -f 'ssh -f -N'
pgrep -af 'ssh -f' || echo "no tunnels"
```

Output:

```text
41168 ssh -f -N -L 9000:127.0.0.1:8008 web
41178 ssh -f -N -L 9001:172.16.1.3:8080 gw
41184 ssh -f -N -R 9080:127.0.0.1:8080 web
41189 ssh -f -N -D 1080 gw
bind [127.0.0.1]:9000: Address already in use
channel_setup_fwd_listener_tcpip: cannot listen to port: 9000
Could not request local forwarding.
exit=0
bind [127.0.0.1]:9000: Address already in use
channel_setup_fwd_listener_tcpip: cannot listen to port: 9000
Could not request local forwarding.
exit=255
no tunnels
```

The first duplicate returned `0` and stayed in the background without a working forward. With `ExitOnForwardFailure=yes` the failure became exit status `255`.

---

## When the Server Forbids Forwarding

`AllowTcpForwarding no` in `sshd` still accepts the login, so the tunnel command starts without error. The failure appears only when a connection uses the forward.

```bash
timeout 4 ssh -N -L 9000:127.0.0.1:8008 web &
sleep 1.5
curl -s -m2 http://127.0.0.1:9000/; echo "curl exit=$?"
```

Output:

```text
channel 2: open failed: administratively prohibited: open failed
curl exit=56
client_loop: send disconnect: Broken pipe
```

A remote forward under the same setting fails at start-up with `Error: remote port forwarding failed for listen port 9080`.

---

## Common Errors

### `bind [127.0.0.1]:9000: Address already in use`

**Cause:** another process, often an earlier tunnel, already listens on the local port.

**Fix:** find it with `ss -tlnp 'sport = :9000'` and stop it, or pick another port; add `-o ExitOnForwardFailure=yes` to scripts.

### `channel 2: open failed: administratively prohibited: open failed`

**Cause:** the server has `AllowTcpForwarding no`, or `PermitOpen` does not list the destination.

**Fix:** check `sudo sshd -T | grep -E 'allowtcpforwarding|permitopen'` on the server and ask for the forward to be allowed.

### `Error: remote port forwarding failed for listen port 9080`

**Cause:** the server refused the remote listener: forwarding is disabled, or the port is in use on the server.

**Fix:** check `ss -tln` and `sshd -T` on the server.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between -L, -R and -D?"
    **Say first:** `-L` listens on the client and connects from the server, `-R` listens on the server and connects from the client, and `-D` is a SOCKS proxy on the client whose destinations the application chooses.

    **Proof:** `ss -tlnp` on the side that listens shows the `ssh` or `sshd` process.

    **Follow-up:** In `-L 9000:127.0.0.1:8008`, whose loopback is `127.0.0.1`?
<!-- --8<-- [end:l1] -->

??? question "L2: Open the admin page that listens only on 127.0.0.1:8008 of a remote server."
    **Say first:** forward a local port to the server's loopback address.

    **Proof:** `ssh -f -N -L 9000:127.0.0.1:8008 web`, then `curl http://127.0.0.1:9000/`.

    **Follow-up:** How do you close it again?

??? question "L2: Connect a local database client to PostgreSQL in a private subnet behind a bastion."
    **Say first:** use a local forward through the bastion to the database address.

    **Proof:** `ssh -N -L 5432:db.internal:5432 bastion`, then `psql -h 127.0.0.1`; the database sees the bastion as the client.

    **Follow-up:** Which part of the path is encrypted?

??? question "L2: Show a teammate a service running on your laptop through a shared server."
    **Say first:** a remote forward makes the server listen and send connections back to the laptop.

    **Proof:** `ssh -R 9080:127.0.0.1:8080 server`; others reach it only if `GatewayPorts` allows a non-loopback bind.

    **Follow-up:** Why do security teams restrict this?

??? question "L3: A tunnel command runs without errors, but connections through it fail. What do you check?"
    **Say first:** whether the forward was really set up, and whether the server allowed the connection.

    **Proof:** `ss -tlnp` for the local port and its owner; run `ssh -N -v` in the foreground and watch for `administratively prohibited` or `connect failed`; on the server, `sshd -T | grep allowtcpforwarding` and the target port with `ss -tln`.

    **Follow-up:** Why did `ssh -f` return `0` although the port was already taken?

??? question "L3: A script opens a tunnel before a database backup, and some nights the backup connects to the wrong database. Why?"
    **Say first:** the local port was already used by another tunnel or a local database, the new forward failed silently, and the backup connected to whatever held the port.

    **Proof:** `ExitOnForwardFailure=yes`, a dedicated local port, and `ss -tlnp 'sport = :PORT'` before the backup starts.

    **Follow-up:** How would a `ControlMaster` socket make the tunnel easier to manage?

---

## Related

- [SSH Client](ssh-client.md): keys and `~/.ssh/config`
- [sshd Server](sshd-server.md): `AllowTcpForwarding`, `GatewayPorts` and `Match` blocks
- [Ports and Sockets](../13-networking/ports-and-sockets.md): reading `ss` listeners
- [Accessing Private Machines](../../networking/accessing-private-machines.md): bastions and private subnets

Captured on Ubuntu 24.04.4 (OpenSSH 9.6p1) against Rocky Linux 10.2 (OpenSSH 9.9p1) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
