# Connectivity Testing

Each test tool answers one question: `ping` whether IP packets come back, `tracepath` and `mtr` where they stop, `nc` and `/dev/tcp` whether a port accepts connections, and `curl` whether the application responds. Using them in that order narrows a failure to a layer in a few commands.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `ping` | ICMP echo request and reply; shows loss, RTT and the reply's TTL | `ping -c3 <host>` |
| ICMP blocked | A host that drops ping can still serve TCP; test the port instead | `nc -vz <host> <port>` |
| `traceroute` | Sends probes with TTL 1, 2, 3...; each router that drops one returns ICMP Time Exceeded | `traceroute -n <host>` |
| Probe types | `traceroute` UDP by default, `-I` ICMP, `-T` TCP (root); `tracepath` UDP without root | `man traceroute` |
| Markers | `* * *` no reply from that hop; `!H` host unreachable, `!N` network unreachable, `!X` prohibited | `traceroute -n` |
| `mtr` | Continuous traceroute with per-hop loss; loss only at a middle hop is ICMP rate limiting | `mtr -n -r -c 10 <host>` |
| MTU probe | `ping -M do -s <size>`: payload + 28 bytes of headers must fit the MTU (1472 for 1500) | `ping -M do -s 1472 <host>` |
| PMTU cache | The kernel remembers a lower path MTU per destination for 10 minutes | `ip route get <host>` |
| Port test | `nc -vz host port`; `timeout 2 bash -c '< /dev/tcp/host/port'` without `nc` | exit status |
| Refused vs timeout | Refused: RST (nothing listens or `reject`); timeout: dropped | `nc -vz -w3` |
| HTTP | `curl -v` (headers), `-I` (HEAD), `-w` (timings), `--resolve` (skip DNS), `-k` (skip TLS verify) | `curl -sv <url>` |
| Throughput | `iperf3 -s` on one side, `iperf3 -c` on the other; port 5201 | `iperf3 -c <host>` |
| `telnet` | Often not installed; `nc` or `curl telnet://host:port` replace it | `command -v telnet` |
<!-- --8<-- [end:facts] -->

---

## ping

From `client` to `web`, one router away:

```bash
ping -c3 -i0.2 172.16.1.3
```

Output:

```text
PING 172.16.1.3 (172.16.1.3) 56(84) bytes of data.
64 bytes from 172.16.1.3: icmp_seq=1 ttl=63 time=0.310 ms
64 bytes from 172.16.1.3: icmp_seq=2 ttl=63 time=0.325 ms
64 bytes from 172.16.1.3: icmp_seq=3 ttl=63 time=0.338 ms

--- 172.16.1.3 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 407ms
rtt min/avg/max/mdev = 0.310/0.324/0.338/0.011 ms
```

`56(84)` is the payload and the full IP packet size. `mdev` is the jitter; a high value or gaps in `icmp_seq` show an unstable path. For a regular user, iputils 20240117 refuses intervals below 2 ms (`cannot flood, minimal interval for user must be >= 2 ms`).

!!! warning "A failed ping proves little"
    Cloud security groups, host firewalls and many routers drop ICMP. A host that ignores ping can still answer on its service port, so follow a failed `ping` with `nc -vz` or `curl`.

---

## Where Packets Stop

```bash
traceroute -n -m 4 172.16.1.99
mtr -n -r -c 5 172.16.1.3
```

Output:

```text
traceroute to 172.16.1.99 (172.16.1.99), 4 hops max, 60 byte packets
 1  172.16.0.3  0.208 ms  0.178 ms  0.167 ms
 2  172.16.0.3  3056.059 ms !H  3056.044 ms !H  3056.031 ms !H
Start: 2026-09-17T12:09:15+0000
HOST: client                      Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 172.16.0.3                40.0%     5    0.2   0.2   0.2   0.3   0.1
  2.|-- 172.16.1.3                 0.0%     5    0.4   0.4   0.3   0.4   0.0
```

`172.16.1.99` does not exist, so `gw` waited three seconds for ARP and returned `!H` (host unreachable). In the `mtr` report, hop 1 shows 40% loss while the destination shows none: the router limits the ICMP errors it sends, and loss that does not continue to the final hop is not real loss.

!!! tip "Read mtr from the bottom up"
    Only loss that starts at one hop and persists through every later hop, including the destination, points to that hop. Send the report (`mtr -r -c 100`) to the network team rather than a single traceroute.

---

## MTU and Path MTU

The largest ICMP payload that fits a 1500-byte MTU with the Don't Fragment bit set is 1472 bytes:

```bash
ping -c1 -M do -s 1472 172.16.1.3 | head -2
ping -c1 -M do -s 1473 172.16.1.3
```

Output:

```text
PING 172.16.1.3 (172.16.1.3) 1472(1500) bytes of data.
1480 bytes from 172.16.1.3: icmp_seq=1 ttl=63 time=0.140 ms
PING 172.16.1.3 (172.16.1.3) 1473(1501) bytes of data.
ping: local error: message too long, mtu=1500

--- 172.16.1.3 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

```

With the MTU of `gw`'s `dmz` leg lowered to 1400 (`sudo ip link set eth1 mtu 1400`):

```bash
ping -c2 -M do -s 1472 172.16.1.3
ip route get 172.16.1.3
tracepath -n 172.16.1.3
ping -c1 -M do -s 1372 172.16.1.3 | head -2
```

Output:

```text
PING 172.16.1.3 (172.16.1.3) 1472(1500) bytes of data.
From 172.16.0.3 icmp_seq=1 Frag needed and DF set (mtu = 1400)
ping: local error: message too long, mtu=1400

--- 172.16.1.3 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1007ms

172.16.1.3 via 172.16.0.3 dev eth0 src 172.16.0.2 uid 1001 
    cache expires 597sec mtu 1400 
 1?: [LOCALHOST]                      pmtu 1500
 1:  172.16.0.3                                            0.189ms 
 1:  172.16.0.3                                            0.069ms 
 2:  172.16.0.3                                            0.060ms pmtu 1400
 2:  172.16.1.3                                            0.285ms reached
     Resume: pmtu 1400 hops 2 back 2 
PING 172.16.1.3 (172.16.1.3) 1372(1400) bytes of data.
1380 bytes from 172.16.1.3: icmp_seq=1 ttl=63 time=0.131 ms
```

The router answered the first probe with `Frag needed`, the client cached `mtu 1400` for the route, and the second probe failed locally. `tracepath` found the same value without root.

!!! danger "Blocked ICMP breaks large transfers"
    If a firewall drops the `Frag needed` messages, small requests work and large responses hang (TLS handshakes, `git clone`, `docker pull`). This PMTU black hole is common with VPNs and overlays; lower the MTU or enable MSS clamping on the tunnel.

---

## Testing a Port

On `web`, listeners run on ports 9200 and 9201; an nftables rule drops traffic to 9200 and rejects traffic to 9201. Nothing listens on 9202.

```bash
nc -vz -w3 172.16.1.3 9200
nc -vz -w3 172.16.1.3 9201
nc -vz -w3 172.16.1.3 9202
timeout 2 bash -c '</dev/tcp/172.16.1.3/8080' && echo open
timeout 2 bash -c '</dev/tcp/172.16.1.3/9200'; echo "rc=$?"
```

Output:

```text
nc: connect to 172.16.1.3 port 9200 (tcp) timed out: Operation now in progress
nc: connect to 172.16.1.3 port 9201 (tcp) failed: Connection refused
nc: connect to 172.16.1.3 port 9202 (tcp) failed: Connection refused
open
rc=124
```

| Result | Meaning |
|---|---|
| `timed out` (9200) | Something drops the SYN: a firewall `drop`, a security group, a routing problem |
| `refused` (9201) | A firewall `reject with tcp reset` looks exactly like a closed port |
| `refused` (9202) | The host is reachable and nothing listens |
| `rc=124` | `timeout` killed the Bash redirection: the same drop, tested without `nc` |

`/dev/tcp/<host>/<port>` is a Bash feature, not a file, so it works in containers that have Bash but no network tools.

---

## Testing HTTP with curl

```bash
curl -sv http://api.shop.internal:8080/health
```

Output:

```text
* Host api.shop.internal:8080 was resolved.
* IPv6: (none)
* IPv4: 172.16.1.3
*   Trying 172.16.1.3:8080...
* Connected to api.shop.internal (172.16.1.3) port 8080
> GET /health HTTP/1.1
> Host: api.shop.internal:8080
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Server: nginx/1.26.3
< Date: Thu, 17 Sep 2026 12:10:21 GMT
< Content-Type: text/plain
< Content-Length: 3
< Connection: keep-alive
< 
{ [3 bytes data]
* Connection #0 to host api.shop.internal left intact
ok
```

The `*` lines show resolution and connection, `>` the request, `<` the response. A failure stops at a visible stage: `Could not resolve host` (DNS), `Trying...` hanging (network), `Connection refused` (port), or an HTTP status (application).

```bash
curl -s -o /dev/null -w 'dns=%{time_namelookup} connect=%{time_connect} ttfb=%{time_starttransfer} total=%{time_total} code=%{http_code}\n' http://api.shop.internal:8080/
curl -sI http://172.16.1.3:8080/ | head -3
curl -s --resolve shop.example:8080:172.16.1.3 http://shop.example:8080/
curl -sS -m 3 http://172.16.1.3:9200/
```

Output:

```text
dns=0.000460 connect=0.000581 ttfb=0.000710 total=0.000732 code=200
HTTP/1.1 200 OK
Server: nginx/1.26.3
Date: Thu, 17 Sep 2026 12:10:05 GMT
shop-api on web (172.16.1.3:8080)
curl: (28) Connection timed out after 3002 milliseconds
```

The `-w` timings are cumulative seconds, so a large gap between `connect` and `ttfb` means a slow application rather than a slow network. `--resolve` sends a request with any `Host` name to a chosen IP, which tests a virtual host or a new server before DNS changes.

---

## Throughput

```bash
iperf3 -c 172.16.1.3 -t 3
```

Output:

```text
Connecting to host 172.16.1.3, port 5201
[  5] local 172.16.0.2 port 33606 connected to 172.16.1.3 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  43.5 MBytes   365 Mbits/sec    0   2.23 MBytes       
[  5]   1.00-2.00   sec  19.2 MBytes   161 Mbits/sec    0   3.09 MBytes       
[  5]   2.00-3.00   sec  19.1 MBytes   160 Mbits/sec    0   3.09 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-3.00   sec  81.9 MBytes   229 Mbits/sec    0             sender
[  5]   0.00-3.13   sec  80.6 MBytes   216 Mbits/sec                  receiver

iperf Done.
```

The server side ran `iperf3 -s -1` (one test, then exit). `Retr` counts TCP retransmissions; non-zero values with low throughput point to loss on the path. These microVMs share a host, so the numbers describe the lab, not a real network.

---

## Common Errors

### `ping: local error: message too long, mtu=1400`

**Cause:** the packet with Don't Fragment set is larger than the known path MTU.

**Fix:** send smaller packets; find the path MTU with `tracepath`.

### `From 172.16.0.3 icmp_seq=1 Frag needed and DF set (mtu = 1400)`

**Cause:** a router on the path has a smaller MTU than the packet.

**Fix:** align MTUs, or make sure these ICMP messages reach the sender.

### `nc: connect to 172.16.1.3 port 9200 (tcp) timed out: Operation now in progress`

**Cause:** the SYN or its answer is dropped.

**Fix:** check firewalls and security groups on both ends, then routing.

### `curl: (28) Connection timed out after 3002 milliseconds`

**Cause:** the same drop seen by `curl`, after the `-m` limit.

**Fix:** as above; compare with `curl` from a host on the same subnet.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How does traceroute work?"
    **Say first:** it sends probes with increasing TTL; each router that decrements TTL to zero returns ICMP Time Exceeded, which reveals its address.

    **Proof:** `traceroute -n <host>`; `tcpdump -n icmp` on the client shows the `time exceeded` replies.

    **Follow-up:** Why do some hops show `* * *` while later hops answer?

??? question "L1: Ping fails but the website works. How is that possible?"
    **Say first:** ICMP is filtered while TCP 80/443 is allowed; ping only tests ICMP.

    **Proof:** `ping -c2 <host>` fails; `curl -sI https://<host>` succeeds.

    **Follow-up:** Which test would you use instead of ping in a runbook?
<!-- --8<-- [end:l1] -->

??? question "L2: Test whether port 5432 on db01 accepts connections without installing anything."
    **Say first:** use Bash's `/dev/tcp` with a timeout.

    **Proof:** `timeout 2 bash -c '< /dev/tcp/db01/5432' && echo open || echo closed`.

    **Follow-up:** How do you tell "closed" from "filtered" with this method? (Immediate failure versus exit 124.)

??? question "L2: Find the path MTU to a host."
    **Say first:** probe with Don't Fragment set and lower the size, or use `tracepath`.

    **Proof:** `ping -M do -s 1472 <host>`; `tracepath -n <host>` prints `pmtu`.

    **Follow-up:** What MTU does a WireGuard tunnel usually get, and why?

??? question "L2: Show how long DNS, connect and the first byte take for a URL."
    **Say first:** `curl -w` with the timing variables.

    **Proof:** `curl -s -o /dev/null -w 'dns=%{time_namelookup} connect=%{time_connect} ttfb=%{time_starttransfer}\n' <url>`.

    **Follow-up:** What does a large `ttfb` with a small `connect` tell you?

??? question "L2: Read this mtr report: 40% loss at hop 1, 0% at the destination. Is there a problem?"
    **Say first:** no; the router limits ICMP replies to probes aimed at it, while forwarded traffic is fine.

    **Proof:** the destination row shows `0.0%`; `sysctl net.ipv4.icmp_ratelimit` on a Linux router.

    **Follow-up:** What pattern would indicate real loss?

??? question "L3: Small API calls work, but large responses hang. What do you suspect and how do you prove it?"
    **Say first:** a path MTU problem where `Frag needed` messages are blocked.

    **Proof:** `ping -M do -s 1472 <host>` fails while `-s 1200` works; `tracepath` shows a lower `pmtu`; `tcpdump` shows retransmitted full-size segments.

    **Follow-up:** How does MSS clamping fix it for all clients?

??? question "L3: A service is unreachable from one host but reachable from another. Walk through your tests."
    **Say first:** compare the two hosts layer by layer: resolution, route, reachability, port, then the application.

    **Proof:** `getent hosts`; `ip route get <ip>`; `ping`; `nc -vz -w3`; `curl -sv` on both hosts.

    **Follow-up:** Which result points to a firewall that filters by source address?

---

## Related

- [Routing](routing.md): what `traceroute` hops mean
- [Ports and Sockets](ports-and-sockets.md): the server side of a port test
- [Packet Capture](packet-capture.md): seeing the probes on the wire
- [Troubleshooting Ladder](troubleshooting-ladder.md): the order of these tests

Captured on Ubuntu 24.04.4 (curl 8.5.0, iperf3) and Rocky Linux 10.2 (nginx 1.26.3) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
