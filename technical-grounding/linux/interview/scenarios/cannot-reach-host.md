# Cannot Reach Host

One host cannot reach another on the network. The interviewer watches whether the candidate climbs the layers in order (link, address, route, ARP, then the path and the firewall) and reads what ping and a port test each rule out.

---

## Symptom

> "This host can't reach another one on the network. Ping sometimes works, but the application still fails."

---

## Clarifying Questions

- **Ping by IP or by name?** A name failure is DNS ([DNS Not Resolving](dns-not-resolving.md)); this scenario is about the IP path.
- **Same subnet or through a router?** A router adds forwarding, return routes and firewalls.
- **Does ping work but a port fail?** That points past routing to a firewall on the port, not the host.
- **Refused, timed out, or no route?** Each is a different layer.

---

## Diagnostic Path

The client is `client` (`172.16.0.2`, Ubuntu 24.04); the target is `web` (`172.16.1.3`) on the far subnet, reached through the router `gw`.

### 1. Route and Reachability

```bash
ip route get 172.16.1.3
ping -c2 -W1 172.16.1.3 | tail -3
```

Output:

```text
172.16.1.3 via 172.16.0.3 dev eth0 src 172.16.0.2 uid 1002 
    cache 
--- 172.16.1.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1027ms
```

`ip route get` shows which gateway and interface a packet would use, before any packet is sent. Ping proves the whole L3 path in both directions works. No route at all prints `RTNETLINK answers: Network is unreachable`.

### 2. The First Hop (ARP)

```bash
ip neigh show 172.16.0.3
```

Output:

```text
172.16.0.3 dev eth0 lladdr 02:00:ac:10:00:03 REACHABLE 
```

`REACHABLE` with a MAC address means the gateway answered ARP. `FAILED` or `INCOMPLETE` means the next hop is down or the address is wrong, and nothing leaves the subnet.

### 3. A Port That Fails While Ping Works

```bash
ping -c1 -W1 172.16.1.3 | tail -1
curl -s -o /dev/null -w '%{http_code}\n' -m3 http://172.16.1.3:8080/; echo "curl exit=$?"
```

Output:

```text
rtt min/avg/max/mdev = 0.392/0.392/0.392/0.000 ms
000
curl exit=28
```

Ping (ICMP) succeeds while the TCP port times out (`curl` exit 28). Something filters that port on the path, not the host. Here a rule on the router `gw` dropped forwarded traffic to `web:8080`:

```bash
sudo nft list chain inet crlab forward | grep counter    # on gw
sudo journalctl -k --since -1min | grep 'cr-drop' | tail -1
```

Output:

```text
	ip saddr 172.16.0.2 ip daddr 172.16.1.3 tcp dport 8080 counter packets 2 bytes 120 log prefix "cr-drop " drop
Sep 17 17:05:57 gw kernel: cr-drop IN=eth0 OUT=eth1 MAC=... SRC=172.16.0.2 DST=172.16.1.3 LEN=60 ... PROTO=TCP SPT=49976 DPT=8080 ... SYN
```

The counter and the logged SYN with `IN=eth0 OUT=eth1` show the router dropping the forwarded packet. A missing return route on `web` produces the same client-side timeout: the SYN arrives, the reply has nowhere to go.

### 4. MTU on the Path

```bash
ping -c1 -M do -s 1472 172.16.1.3 | tail -2
ping -c1 -M do -s 2000 -W1 172.16.1.3 | tail -2
```

Output:

```text
rtt min/avg/max/mdev = 0.137/0.137/0.137/0.000 ms
ping: local error: message too long, mtu=1500
1 packets transmitted, 0 received, +1 errors, 100% packet loss
```

A 1472-byte payload (1500 with headers) passes; 2000 with "don't fragment" is refused. When large packets hang while small ones and ping work, and a tunnel or VPN is on the path, MTU is the suspect.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| No route | `ip route get`: `Network is unreachable` | Add the route or default gateway |
| Dead next hop | `ip neigh`: `FAILED`/`INCOMPLETE` | Fix the gateway address or the link |
| Forwarding off on router | Ping to router works, through it fails; `net.ipv4.ip_forward=0` | `sysctl -w net.ipv4.ip_forward=1`, persist it |
| Forwarding firewall | Port times out, ping works; `drop` in the router's `forward` chain | Allow the flow on the router |
| Missing return route | Server sees the SYN, client times out | Add a route back to the source subnet on the server |
| MTU | Large packets fail, small ones pass; `message too long` | Lower the MTU or fix path MTU discovery |
| Cloud security group | Timeout from another subnet only | Open the port and protocol in the security group |

---

## Fix

For the router-drop case, allow the flow (or remove the stray rule) on `gw`:

```bash
sudo nft delete table inet crlab    # on gw, remove the dropping table
curl -s -o /dev/null -w '%{http_code}\n' -m3 http://172.16.1.3:8080/    # from client
```

---

## Prevention

- Persist `ip_forward` and routes in `sysctl.d` and the network configuration, not with runtime commands.
- Keep router firewall rules stateful (`ct state established,related accept`) so replies are not dropped.
- Document the MTU when a tunnel is in the path, and test with `ping -M do` after changes.

---

## Related

- [Troubleshooting Ladder](../../13-networking/troubleshooting-ladder.md): the full layer-by-layer version
- [Routing](../../13-networking/routing.md): forwarding and return paths
- [nftables and iptables](../../15-security/nftables-and-iptables.md): the `forward` chain and counters
- [Connectivity Testing](../../13-networking/connectivity-testing.md): ping, MTU probes and `nc`

Captured on Ubuntu 24.04.4 and Rocky Linux 10.2 on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
