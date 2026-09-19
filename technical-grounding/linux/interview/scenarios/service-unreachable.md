# Service Unreachable

A service answers on the server itself but not from other hosts. The interviewer checks whether the candidate reads the bind address first, then works outward through the firewall, SELinux and the network, instead of restarting the service.

---

## Symptom

> "The service works on the server (`curl localhost` is fine), but clients can't connect. What do you check?"

---

## Clarifying Questions

- **Refused or timed out from the client?** Refused or `No route to host` is a host answering (bind address or a rejecting firewall); a timeout is a silent drop further out.
- **Does `curl localhost` on the server really work?** That confirms the application is up and the problem is reachability.
- **New service, or one that changed?** A new port needs a firewall rule and, on RHEL, a SELinux port label.
- **Same subnet or across a router?** A router adds forwarding and return-path questions ([Cannot Reach Host](cannot-reach-host.md)).

---

## Diagnostic Path

The server is `web` (Rocky Linux 10.2) with firewalld on; the client is `client` (Ubuntu 24.04).

### 1. Read the Bind Address on the Server

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8008/
sudo ss -tlnp '( sport = :8008 or sport = :8080 )'
```

Output:

```text
200
LISTEN 0      511          0.0.0.0:8080      0.0.0.0:*    users:(("nginx",pid=94068,fd=7),...)
LISTEN 0      511        127.0.0.1:8008      0.0.0.0:*    users:(("nginx",pid=94068,fd=6),...)
```

Port 8008 listens on `127.0.0.1` only: reachable from the server, never from the network. Port 8080 listens on `0.0.0.0`, so it can be reached if the firewall allows it.

### 2. Try Each Port From the Client

```bash
curl -s -o /dev/null -w 'admin(8008)=%{http_code}\n' -m3 http://172.16.1.3:8008/; echo "curl exit=$?"
curl -s -o /dev/null -w 'api(8080)=%{http_code}\n' -m3 http://172.16.1.3:8080/
nc -vz -w3 172.16.1.3 9090; echo "9090 exit=$?"
```

Output:

```text
admin(8008)=000
curl exit=7
api(8080)=200
nc: connect to 172.16.1.3 port 9090 (tcp) failed: No route to host
9090 exit=1
```

Three different results tell three different stories: 8008 could not connect (loopback bind), 8080 answered (bound wide and allowed), and 9090 (an `nc` listener on `0.0.0.0`) gave `No route to host`, firewalld's ICMP reject for a port with no rule.

### 3. Confirm the Firewall on the Server

```bash
sudo ss -tlnp 'sport = :9090'
sudo firewall-cmd --list-ports
```

Output:

```text
LISTEN 0      1            0.0.0.0:9090      0.0.0.0:*    users:(("nc",pid=95305,fd=3))
8080/tcp 8443/tcp
```

The process listens on all addresses, but only 8080 and 8443 are open. The missing rule, not the service, blocks 9090.

### 4. On RHEL, Check the SELinux Port Label

A service that binds a nonstandard port can fail to start with `bind() ... Permission denied` even when the firewall is open, because SELinux has no label for the port. [SELinux](../../15-security/selinux.md#port-labels) shows the capture; the fix is `semanage port -a -t <type> -p tcp <port>`.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Loopback bind | `ss` shows `127.0.0.1:port`; client gets refused or couldn't connect | Bind `0.0.0.0` (or the LAN address) in the app config |
| Firewall rule missing | Client times out or gets `No route to host`; port not in `firewall-cmd --list-ports` | Add the port/service, `--permanent` and reload |
| SELinux port label | Service fails to start, `bind() ... Permission denied`, AVC `name_bind` | `semanage port -a -t TYPE -p tcp PORT` |
| SELinux connect boolean | Proxy returns 502, AVC `name_connect` | `setsebool -P httpd_can_network_connect on` |
| Cloud security group | Timeout from outside, works within the subnet | Open the port in the security group |
| Wrong subnet or route | Cross-subnet timeout | See [Cannot Reach Host](cannot-reach-host.md) |

---

## Fix

For the loopback-bind case, change the listener; for the firewall case:

```bash
sudo firewall-cmd --permanent --add-port=9090/tcp    # on web
sudo firewall-cmd --reload
nc -vz -w3 172.16.1.3 9090    # from client, confirm
```

---

## Prevention

- Decide the bind address on purpose: loopback for admin endpoints, the LAN address or `0.0.0.0` for shared services.
- Ship the firewall rule and the SELinux port label with the service (configuration management), not by hand afterward.
- Add an external check (from another host) to monitoring, so "works on localhost" is never the only test.

---

## Related

- [Ports and Sockets](../../13-networking/ports-and-sockets.md): reading `ss` bind addresses
- [firewalld and ufw](../../15-security/firewalld-and-ufw.md): opening ports, reject versus drop
- [SELinux](../../15-security/selinux.md): port labels and the `httpd_can_network_connect` boolean

Captured on Rocky Linux 10.2 (firewalld 2.4.3, SELinux enforcing) and Ubuntu 24.04.4 on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
