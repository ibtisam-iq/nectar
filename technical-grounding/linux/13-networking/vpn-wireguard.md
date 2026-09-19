# VPN (WireGuard)

WireGuard is an in-kernel VPN that sends encrypted IP packets over UDP between peers identified by public keys. A tunnel is a `wg0` interface plus a short configuration file, and `wg show` explains most failures.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Transport | UDP, default port 51820; no TCP mode | `ss -ulpn 'sport = :51820'` |
| Identity | Each peer has a key pair; `wg genkey`, `wg pubkey`; private keys stay mode `0600` | `ls -l /etc/wireguard` |
| AllowedIPs | Routing table and access list in one: outgoing packets pick the peer by destination, incoming packets are accepted only from these sources | `wg show wg0 allowed-ips` |
| Handshake | Every two minutes while traffic flows; no handshake means no tunnel | `wg show wg0 latest-handshakes` |
| Keepalive | `PersistentKeepalive = 25` keeps NAT mappings open for a peer behind NAT | `wg show` |
| MTU | `wg-quick` sets 1420 (1500 minus 80 bytes of overhead) | `ip link show wg0` |
| Tooling | `wg-quick up wg0` reads `/etc/wireguard/wg0.conf`; `wg-quick@wg0.service` makes it permanent | `systemctl status wg-quick@wg0` |
<!-- --8<-- [end:facts] -->

---

## A Tunnel Between Two Hosts

`client` (`172.16.0.2`) and `web` (`172.16.1.3`) get tunnel addresses `10.99.99.1` and `10.99.99.2`. Keys were generated on each host with `umask 077; wg genkey | tee <name>.key | wg pubkey > <name>.pub`, and public keys on this page are replaced with placeholders. The configuration on `client`:

```bash
sudo sed 's/^PrivateKey = .*/PrivateKey = (hidden)/' /etc/wireguard/wg0.conf
```

Output:

```text
[Interface]
Address = 10.99.99.1/24
PrivateKey = (hidden)

[Peer]
PublicKey = WebPublicKeyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
Endpoint = 172.16.1.3:51820
AllowedIPs = 10.99.99.0/24
PersistentKeepalive = 25
```

The file on `web` has `ListenPort = 51820`, the client's public key and `AllowedIPs = 10.99.99.1/32`, and no `Endpoint`. So `web` accepts only `10.99.99.1` from that key, while `client` knows where `web` is and sends all of `10.99.99.0/24` to it. `web` started with `sudo systemctl enable --now wg-quick@wg0`, `client` by hand:

```bash
sudo wg-quick up wg0
ping -c2 10.99.99.2 | tail -2
sudo wg show
```

Output:

```text
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.99.1/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
2 packets transmitted, 2 received, 0% packet loss, time 1016ms
rtt min/avg/max/mdev = 0.293/0.382/0.471/0.089 ms
interface: wg0
  public key: ClientPublicKeyAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  private key: (hidden)
  listening port: 57109

peer: WebPublicKeyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  endpoint: 172.16.1.3:51820
  allowed ips: 10.99.99.0/24
  latest handshake: 1 second ago
  transfer: 348 B received, 436 B sent
  persistent keepalive: every 25 seconds
```

`wg-quick` printed the `ip` and `wg` commands it ran. The client's listening port (`57109`) is random because none was configured. Inside the tunnel, `ping` shows `ttl=64`: the inner packet is not routed by `gw`, only the outer UDP packet is.

!!! note "The router sees only UDP"
    A capture on `gw` (`sudo tcpdump -ni eth1 udp port 51820`) during an HTTP request through the tunnel showed only `UDP, length 96` packets between `172.16.0.2.57109` and `172.16.1.3.51820`, plus 32-byte keepalives.

!!! warning "Protect the private key and the config file"
    `wg0.conf` contains the private key. Keep `/etc/wireguard` readable only by root, and never paste `wg showconf` output into a ticket.

---

## Common Errors

### `ping: sendmsg: Required key not available`

**Cause:** no peer's `AllowedIPs` covers the destination (here `web` pinging `10.99.99.5`), so WireGuard has no key to encrypt with.

**Fix:** add the address to the right peer's `AllowedIPs`, or route it elsewhere.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does AllowedIPs do in WireGuard?"
    **Say first:** it is both the routing decision for outgoing packets (which peer gets them) and the filter for incoming packets (which source addresses a peer may use).

    **Proof:** `sudo wg show wg0 allowed-ips`; a ping outside every range fails with `Required key not available`.

    **Follow-up:** What happens if two peers list overlapping ranges?
<!-- --8<-- [end:l1] -->

??? question "L2: Check whether a WireGuard tunnel is actually up."
    **Say first:** look at the latest handshake and the transfer counters, then ping the peer's tunnel address.

    **Proof:** `sudo wg show` (`latest handshake: 1 second ago`); `ping 10.99.99.2`.

    **Follow-up:** Why does `ip link` show `wg0` as up even with no working peer?

??? question "L2: Make a WireGuard interface start at boot."
    **Say first:** enable the `wg-quick` template unit for the interface.

    **Proof:** `sudo systemctl enable --now wg-quick@wg0`.

    **Follow-up:** Which file does the unit read?

??? question "L2: A client should send all its traffic through the VPN server. What changes?"
    **Say first:** `AllowedIPs = 0.0.0.0/0` on the client, and forwarding plus NAT on the server.

    **Proof:** `sysctl net.ipv4.ip_forward=1`; a masquerade rule for the tunnel subnet on the server's uplink.

    **Follow-up:** How does `wg-quick` keep the tunnel's own UDP packets off the tunnel?

??? question "L3: A WireGuard client shows no handshake. What do you check, in order?"
    **Say first:** the endpoint address and port, UDP reachability and firewalls, then that each side has the other's correct public key.

    **Proof:** `sudo wg show` (no `latest handshake`); `sudo tcpdump -ni any udp port 51820` on both ends; compare `wg show wg0 public-key` with the peer's config.

    **Follow-up:** Why does a wrong key produce silence instead of an error?

??? question "L3: The tunnel works for ping and small requests, but web pages through it hang. Why?"
    **Say first:** the MTU: packets that fit the physical link do not fit inside the tunnel, and the path MTU discovery fails.

    **Proof:** `ip link show wg0` (`mtu 1420`); `ping -M do -s 1392 <peer tunnel address>`.

    **Follow-up:** Which MTU would you set when the underlay itself is 1450?

---

## Related

- [WireGuard VPN setup](../../../operations/wireguard/README.md): a full WireGuard server build on a VPS
- [Routing](routing.md): forwarding and return paths

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 (wireguard-tools v1.0.20250521 on Rocky) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09. Public keys are replaced with placeholders.
