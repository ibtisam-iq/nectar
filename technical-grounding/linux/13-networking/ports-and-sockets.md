# Ports and Sockets

A socket is a kernel endpoint identified by protocol, local address and port, and a service is reachable only if a process holds a listening socket on an address the client can reach. `ss` shows every socket and the process behind it, which answers "is it listening, and where?" in one command.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Tool | `ss` (iproute2) replaced `netstat` (net-tools) | `ss -tulpn` |
| Flags | `-t` TCP, `-u` UDP, `-l` listening, `-p` process (needs root for other users), `-n` numeric, `-a` all | `sudo ss -tulpn` |
| Socket identity | Protocol + local IP:port + remote IP:port; many connections share one listening port | `ss -tn` |
| `0.0.0.0` / `[::]` / `*` | Listening on all addresses (IPv4, IPv6, both) | `ss -tln` |
| `127.0.0.1` | Reachable only from the same host (or the same network namespace) | `ss -tln` |
| Privileged ports | Below `ip_unprivileged_port_start` (1024) need root or `CAP_NET_BIND_SERVICE` | `sysctl net.ipv4.ip_unprivileged_port_start` |
| Ephemeral ports | Client source ports from `ip_local_port_range` (32768 to 60999) | `sysctl net.ipv4.ip_local_port_range` |
| Service names | `/etc/services` maps names to ports | `getent services 443` |
| Well-known ports | 22 SSH, 25 SMTP, 53 DNS, 80 HTTP, 123 NTP (UDP), 443 HTTPS, 3306 MySQL, 5432 PostgreSQL, 6379 Redis, 6443 Kubernetes API, 2379 etcd, 10250 kubelet | `ss -tlnp` |
| Who owns a port | `ss -tlpn 'sport = :8080'`, `lsof -i :8080`, `fuser -v 8080/tcp` | `sudo lsof -i :8080 -P -n` |
| Refused vs timeout | Refused: host answered with RST, nothing listens; timeout: packets dropped on the way | `nc -vz host port` |
| Raw source | `/proc/net/tcp` and `/proc/net/tcp6` in hex, host byte order | `cat /proc/net/tcp` |
| Socket activation | `systemd` can hold the listening socket (`sshd.socket` here) | `systemctl list-sockets` |
<!-- --8<-- [end:facts] -->

---

## Listing Listening Sockets

On `web`, nginx serves ports 80 and 8080, and two test listeners run with `nc`: one on loopback, one on all addresses.

```bash
nohup timeout 600 nc -lk 127.0.0.1 9000 >/dev/null 2>&1 </dev/null &
nohup timeout 600 nc -lk 0.0.0.0 9001 >/dev/null 2>&1 </dev/null &
sudo ss -tlpn '( sport = :9000 or sport = :9001 or sport = :80 or sport = :22 )'
```

Output:

```text
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                                         
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=1777,fd=7),("nginx",pid=1776,fd=7),("nginx",pid=1775,fd=7))
LISTEN 0      1          127.0.0.1:9000      0.0.0.0:*    users:(("nc",pid=2398,fd=3))                                                   
LISTEN 0      1            0.0.0.0:9001      0.0.0.0:*    users:(("nc",pid=2397,fd=3))                                                   
LISTEN 0      4096               *:22              *:*    users:(("systemd",pid=1,fd=135))                                               
LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=1777,fd=8),("nginx",pid=1776,fd=8),("nginx",pid=1775,fd=8))
```

| Column | Meaning for a listening socket |
|---|---|
| `Recv-Q` | Connections completed and waiting for `accept()` |
| `Send-Q` | The accept queue limit (the `listen()` backlog) |
| `Local Address:Port` | Where it listens; `*` covers IPv4 and IPv6 |
| `Process` | Name, PID and file descriptor of every process holding the socket |

Three nginx processes share one socket (the master and two workers inherited it). Port 22 belongs to `systemd` because this host uses `sshd.socket`, which starts `sshd` per connection. Without `sudo`, `ss` lists the same sockets but leaves the `Process` column empty for other users' sockets.

```bash
sudo ss -tulpn
```

Output:

```text
Netid State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess                                                                         
udp   UNCONN 0      0         172.16.1.3:53         0.0.0.0:*    users:(("named",pid=2276,fd=35))                                               
# ... (trimmed)
udp   UNCONN 0      0              [::1]:53            [::]:*    users:(("named",pid=2276,fd=39))                                               
tcp   LISTEN 0      10        172.16.1.3:53         0.0.0.0:*    users:(("named",pid=2276,fd=38))                                               
# ... (trimmed)
tcp   LISTEN 0      5          127.0.0.1:953        0.0.0.0:*    users:(("named",pid=2276,fd=44))                                               
# ... (trimmed)
tcp   LISTEN 0      511          0.0.0.0:8080       0.0.0.0:*    users:(("nginx",pid=1777,fd=6),("nginx",pid=1776,fd=6),("nginx",pid=1775,fd=6))
# ... (trimmed)
```

UDP sockets show `UNCONN` because UDP has no connection state. BIND listens only on the addresses in its `listen-on` list (`127.0.0.1` and `172.16.1.3`), with one socket per worker thread, and its control channel `953` on loopback only.

---

## Bind Address Decides Who Can Connect

From `client`:

```bash
nc -vz -w2 172.16.1.3 9000
nc -vz -w2 172.16.1.3 9001
nc -vz -w2 172.16.1.3 8080
```

Output:

```text
nc: connect to 172.16.1.3 port 9000 (tcp) failed: Connection refused
Connection to 172.16.1.3 9001 port [tcp/*] succeeded!
Connection to 172.16.1.3 8080 port [tcp/http-alt] succeeded!
```

Port 9000 is open, but only on `127.0.0.1`, so a remote client gets the same `Connection refused` as for a closed port. On `web` itself, `nc -vz 127.0.0.1 9000` succeeds.

!!! warning "Works on localhost is not works for clients"
    A service bound to `127.0.0.1` passes every local test with `curl localhost`. Check the `Local Address` column before blaming the firewall; the fix is the service's listen or bind setting (`listen`, `bind-address`, `--host 0.0.0.0`).

---

## Connections and Their Processes

With a client connected to port 9001:

```bash
sudo ss -tnp state established '( sport = :9001 )'
sudo lsof -i :9001 -P -n
sudo fuser -v 8080/tcp
```

Output:

```text
Recv-Q Send-Q Local Address:Port Peer Address:Port Process                      
0      0         172.16.1.3:9001   172.16.0.2:46910 users:(("nc",pid=2397,fd=4))
COMMAND  PID     USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
nc      2397 laborant    3u  IPv4  31244      0t0  TCP *:9001 (LISTEN)
nc      2397 laborant    4u  IPv4  31245      0t0  TCP 172.16.1.3:9001->172.16.0.2:46910 (ESTABLISHED)
                     USER        PID ACCESS COMMAND
8080/tcp:            root       1775 F.... nginx
                     nginx      1776 F.... nginx
                     nginx      1777 F.... nginx
```

The listening socket is fd 3 and the accepted connection fd 4: `accept()` returns a new socket for each client while the listener stays open. The client's port `46910` is an ephemeral port. `ss` filters use `sport`/`dport` and `src`/`dst`; `state` accepts names such as `established`, `time-wait` and `close-wait`.

The summary, taken a minute earlier before the client connected:

```bash
ss -s
```

Output:

```text
Total: 123
TCP:   19 (estab 0, closed 2, orphaned 0, timewait 1)

Transport Total     IP        IPv6
RAW	  0         0         0        
UDP	  6         4         2        
TCP	  17        11        6        
INET	  23        15        8        
FRAG	  0         0         0        
```

`ss -s` is the fast summary for "how many connections, how many in TIME_WAIT" on a busy server.

---

## Errors When Opening a Port

```bash
nc -l 8080
nc -l 80
```

Output:

```text
nc: Address already in use
nc: Permission denied
```

Port 8080 already has a listener (nginx), and port 80 is below 1024 while `laborant` is not root. `sudo`, a capability (`setcap cap_net_bind_service=+ep`, `AmbientCapabilities=` in a unit) or a reverse proxy solves the second.

```bash
getent services 443 ssh 53/udp
sysctl net.ipv4.ip_unprivileged_port_start net.ipv4.ip_local_port_range
```

Output:

```text
https                 443/tcp
ssh                   22/tcp
domain                53/udp
net.ipv4.ip_unprivileged_port_start = 1024
net.ipv4.ip_local_port_range = 32768	60999
```

---

## Without ss: /proc/net/tcp and netstat

`ss` reads the kernel through netlink; the older text files remain for minimal systems:

```bash
head -1 /proc/net/tcp
grep -i ':2329 ' /proc/net/tcp
printf '%d\n' 0x2329 0xB73E
python3 -c 'import socket,struct; print(socket.inet_ntoa(struct.pack("<I", 0x030110AC)), socket.inet_ntoa(struct.pack("<I", 0x020010AC)))'
```

Output:

```text
  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode                                                     
   6: 00000000:2329 00000000:0000 0A 00000000:00000000 00:00000000 00000000  1001        0 31244 1 0000000000000000 100 0 0 10 0                     
  12: 030110AC:2329 020010AC:B73E 01 00000000:00000000 00:00000000 00000000  1001        0 31245 1 0000000000000000 20 0 0 10 -1                     
9001
46910
172.16.1.3 172.16.0.2
```

Ports are big-endian hex, addresses are little-endian hex on x86, and `st` is the state (`0A` LISTEN, `01` ESTABLISHED). Without `ss`, `lsof` or `netstat`, this file still proves what listens.

```bash
sudo netstat -tulpn | head -8
```

Output:

```text
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 172.16.1.3:53           0.0.0.0:*               LISTEN      2276/named          
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1775/nginx: master  
tcp        0      0 127.0.0.1:953           0.0.0.0:*               LISTEN      2276/named          
tcp        0      0 127.0.0.1:53            0.0.0.0:*               LISTEN      2276/named          
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      1775/nginx: master  
tcp        0      0 0.0.0.0:50061           0.0.0.0:*               LISTEN      1/init              
```

`netstat` merges duplicate sockets and shows one PID; port `50061` is a playground agent.

!!! tip "Refused and timed out point to different layers"
    `Connection refused` means the host answered with a reset, so routing works and nothing listens on that address. `timed out` means packets or replies were dropped, usually by a firewall or a routing problem.

---

## Common Errors

### `nc: connect to 172.16.1.3 port 9000 (tcp) failed: Connection refused`

**Cause:** no socket listens on that address and port, or the service is bound to `127.0.0.1`.

**Fix:** `sudo ss -tlpn 'sport = :9000'` on the server; change the bind address or start the service.

### `nc: Address already in use`

**Cause:** another socket already listens on the port; services log the same errno 98 (`EADDRINUSE`).

**Fix:** `sudo ss -tlpn 'sport = :8080'` names the process; stop it or choose another port.

### `nc: Permission denied`

**Cause:** an unprivileged user tried to bind a port below 1024.

**Fix:** run with the right privilege, grant `CAP_NET_BIND_SERVICE`, or listen on a high port behind a proxy.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between listening on 0.0.0.0 and on 127.0.0.1?"
    **Say first:** `0.0.0.0` accepts connections on every address of the host; `127.0.0.1` accepts only connections from the host itself.

    **Proof:** `sudo ss -tlpn`; `nc -vz <server ip> 9000` from another host is refused.

    **Follow-up:** Why does a container publishing a port to `127.0.0.1` behave the same way?

??? question "L1: What is the difference between Connection refused and a timeout?"
    **Say first:** refused means the host replied with a TCP reset because nothing listens; a timeout means packets or replies are dropped on the way.

    **Proof:** `nc -vz -w2 host 9000` returns at once; a firewalled port waits for `-w`.

    **Follow-up:** Which firewall action produces a refusal instead of a timeout? (`reject`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Find which process listens on port 8080."
    **Say first:** `ss` with the process flag, filtered by source port.

    **Proof:** `sudo ss -tlpn 'sport = :8080'`; `sudo lsof -i :8080 -P -n`; `sudo fuser -v 8080/tcp`.

    **Follow-up:** Why does `ss -tlpn` without `sudo` show no process?

??? question "L2: Count established connections to port 443 by client IP."
    **Say first:** list established sockets for the port and aggregate the peer column.

    **Proof:** `ss -Htn state established '( sport = :443 )' | awk '{print $4}' | cut -d: -f1 | sort | uniq -c | sort -rn`.

    **Follow-up:** How would you spot one client opening thousands of connections?

??? question "L2: A minimal container has no ss or netstat. Prove that something listens on port 9001."
    **Say first:** read `/proc/net/tcp` and convert the hex port.

    **Proof:** `grep -i ':2329 ' /proc/net/tcp`, where `0x2329` is 9001 and state `0A` is LISTEN.

    **Follow-up:** How do you test an outbound connection without `nc`? (`bash`'s `/dev/tcp`.)

??? question "L3: An application works with curl localhost on the server but clients get connection refused. What do you check?"
    **Say first:** the bind address first, then whether the client reaches the right host and port, then the firewall.

    **Proof:** `sudo ss -tlpn 'sport = :<port>'` shows `127.0.0.1`; `ip -br addr`; `nc -vz <ip> <port>` from the client.

    **Follow-up:** Which result would you expect if the firewall were the cause?

??? question "L3: A service fails to start with Address already in use, but nothing seems to run. Where do you look?"
    **Say first:** find the socket's owner, including systemd socket units and other network namespaces or containers.

    **Proof:** `sudo ss -tlpn 'sport = :<port>'`; `systemctl list-sockets`; `sudo lsof -i :<port>`.

    **Follow-up:** What does `SO_REUSEADDR` allow and not allow?

---

## Related

- [Sockets and TCP States](sockets-and-tcp-states.md): what happens inside a socket
- [Connectivity Testing](connectivity-testing.md): `nc`, `curl` and `/dev/tcp` from the client side
- [File Descriptors](../02-files-and-filesystem/file-descriptors.md): sockets are file descriptors
- [Networking Inbound and Outbound](../../networking/networking-inbound-outbound.md): ports from the network's point of view

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 (iximiuz Labs FlexBox microVMs, kernel 6.1.167, iproute2 6.17 and 6.1), 2026-09.
