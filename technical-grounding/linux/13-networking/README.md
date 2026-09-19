# Networking

How a Linux host gets its addresses and routes, resolves names, opens and tracks sockets, and how to test, capture and troubleshoot traffic between hosts, including time sync, reverse proxies and WireGuard. Protocol theory lives in the [networking notes](../../networking/Networking.md).

---

## Revision Card

| Fact | Value |
|---|---|
| Tools | `ip` (addr, link, route, neigh), `ss`, `nmcli`, `netplan`, `resolvectl`, `tcpdump` |
| Link flags | `UP` admin up; `LOWER_UP` carrier; `NO-CARRIER` cable or vNIC down |
| Persistence | RHEL: NetworkManager keyfiles; Ubuntu Server: netplan to systemd-networkd |
| Route choice | Longest prefix, then lowest metric; `ip route get <ip>` shows the answer |
| Router | `net.ipv4.ip_forward = 1`, and a return route on the far side |
| Name lookup | `nsswitch.conf` (`files dns`); `/etc/hosts` wins; Ubuntu stub `127.0.0.53` |
| `dig` vs `getent` | `dig @server` asks DNS only; `getent hosts` follows the application path |
| DNS results | `NXDOMAIN` no such name, `SERVFAIL` server failed, `REFUSED` policy |
| Listening | `0.0.0.0` all addresses, `127.0.0.1` local only |
| Refused vs timeout | Refused: RST, nothing listens; timeout: dropped by a firewall or path |
| TCP states | `CLOSE_WAIT` = application did not close; `TIME_WAIT` = normal, 60 s on the active closer |
| Accept queue | `ss -ltn` `Recv-Q` near `Send-Q`; `nstat -az TcpExtListenOverflows` |
| MTU | 1500 Ethernet, 1472-byte ping payload; WireGuard 1420 |
| Time | `timedatectl`, chrony; `makestep` steps large offsets; wrong time breaks TLS |
| Proxy errors | `502` backend refused or failed; `504` backend too slow |
| Ladder | Link, IP, route, gateway, ping, DNS, port, server, application |

| Task | Command |
|---|---|
| Addresses and routes | `ip -br addr; ip route` |
| Route for one destination | `ip route get 10.0.0.5` |
| Static address on RHEL | `sudo nmcli con add type ethernet con-name lan ifname eth0 ipv4.method manual ipv4.addresses 10.0.0.10/24 ipv4.gateway 10.0.0.1` |
| Apply netplan safely | `sudo netplan try` |
| Enable forwarding now | `sudo sysctl -w net.ipv4.ip_forward=1` (persist in `/etc/sysctl.d/`) |
| Resolver state | `resolvectl status` |
| Query one server | `dig @10.0.0.53 app.internal +short` |
| Who listens on a port | `sudo ss -tlpn 'sport = :8080'` |
| Test a port | `nc -vz -w3 10.0.0.5 5432` |
| Path MTU | `tracepath -n 10.0.0.5` |
| Capture a port | `sudo tcpdump -nn -i any port 443` |
| NTP status | `chronyc sources; chronyc tracking` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Interfaces and Addresses](interfaces-and-addresses.md) | `ip addr`/`link`/`neigh`, names, ARP, `ethtool`, net-tools mapping | Core | High |
| [Network Configuration](network-configuration.md) | NetworkManager and `nmcli`, netplan, hostnames | Core | Med |
| [Routing](routing.md) | Route lookup, forwarding, return paths, persistence, policy routing | Core | High |
| [DNS Resolution](dns-resolution.md) | nsswitch, `/etc/hosts`, systemd-resolved, `dig`, status codes, split DNS | Core | High |
| [Ports and Sockets](ports-and-sockets.md) | `ss`, `lsof`, bind addresses, well-known ports, `/proc/net/tcp` | Core | High |
| [Sockets and TCP States](sockets-and-tcp-states.md) | System calls, accept queue, `CLOSE_WAIT`, `TIME_WAIT`, conntrack | Advanced | Med |
| [Connectivity Testing](connectivity-testing.md) | `ping`, `traceroute`, `mtr`, MTU, `nc`, `/dev/tcp`, `curl`, `iperf3` | Core | High |
| [Packet Capture](packet-capture.md) | `tcpdump` filters, flags, payloads, pcap files, `tshark` | Core | Med |
| [Bridges, Bonds and VLANs](bridges-bonds-vlans.md) | Bridges and veth, bonding, 802.1Q | Advanced | Low |
| [Time and Timezones](time-and-timezones.md) | `timedatectl`, chrony, stepping, clock skew and TLS | Core | Med |
| [Reverse Proxy and Load Balancing](reverse-proxy-and-load-balancing.md) | nginx upstreams, HAProxy health checks, 502 and 504 | Core | Med |
| [VPN (WireGuard)](vpn-wireguard.md) | Keys, `AllowedIPs`, `wg-quick`, handshakes | Advanced | Low |
| [Troubleshooting Ladder](troubleshooting-ladder.md) | Layer-by-layer checks, a worked firewall case, fallbacks without tools | Core | High |

---

## Scenarios and Labs

- [DNS Not Resolving](../interview/scenarios/dns-not-resolving.md): internal zone, stale `/etc/hosts`, a zone that failed to load
- [Networking Lab](../labs/networking-lab.md): routing through a Linux router, NetworkManager, netplan, DNS, ports, capture, NTP and a load balancer on three VMs

The lab network used on every page: `client` (Ubuntu, `172.16.0.2`) on `lan`, `gw` (Rocky, `172.16.0.3` and `172.16.1.2`) between `lan` and `dmz`, and `web` (Rocky, `172.16.1.3`) on `dmz`.
