# firewalld and ufw

firewalld (RHEL family) and ufw (Ubuntu) are front ends that write netfilter rules for the administrator. A service that works on the server but not from other hosts often has a missing firewall rule, so reading their state is part of every connectivity check.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Defaults | RHEL: firewalld on, zone `public` allows `ssh`, `dhcpv6-client`, `cockpit`; Ubuntu: ufw installed but inactive | `sudo firewall-cmd --list-all`, `sudo ufw status` |
| Backend | Both write nftables rules (firewalld table `inet firewalld`; ufw through `iptables-nft`) | `sudo nft list tables` |
| Runtime vs permanent | `firewall-cmd` changes runtime only; `--permanent` changes the saved config; `--reload` drops runtime-only rules; `--runtime-to-permanent` saves them | `sudo firewall-cmd --permanent --list-all` |
| Zones | A packet uses the zone of its source address first, then the zone of its interface, then the default zone | `sudo firewall-cmd --get-active-zones` |
| Services | Named port sets in `/usr/lib/firewalld/services/*.xml` (263 on Rocky 10.2); zone config in `/etc/firewalld/zones/public.xml` | `sudo firewall-cmd --get-services` |
| Rich rules | Per-source or logged rules; deny rules run before allow rules unless `priority` is set | `sudo firewall-cmd --list-rich-rules` |
| Reject vs drop | firewalld rejects (clients see `refused` or `unreachable`); ufw `deny` drops (clients time out) | `nc -vz host port` |
| ufw rules | `ufw allow 22/tcp`, `ufw allow from 10.0.0.0/8 to any port 5432 proto tcp`, `ufw delete allow 22/tcp`; blocks are logged as `[UFW BLOCK]` | `sudo ufw status numbered` |
<!-- --8<-- [end:facts] -->

---

## firewalld Zones and Default State

On `web` (Rocky Linux 10.2), firewalld was installed but not running. Starting it applies the `public` zone to all traffic, because no interface or source is bound to another zone.

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
```

Output:

```text
# ... (trimmed)
public (default)
public (default, active)
  target: default
# ... (trimmed)
  interfaces: 
  sources: 
  services: cockpit dhcpv6-client ssh
# ... (trimmed)
```

From `client`, `curl` to port 8080 failed at once with `Couldn't connect to server`, `dig` reported `communications error to 172.16.1.3#53: host unreachable`, and `nc -vz` to port 22 succeeded. The failures were instant because firewalld answers blocked packets with an ICMP reject instead of dropping them.

---

## Runtime and Permanent Rules

A rule without `--permanent` works at once and disappears on the next reload or reboot. A rule with `--permanent` is saved and takes effect only after a reload.

```bash
sudo firewall-cmd --add-port=8080/tcp
sudo firewall-cmd --list-ports
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --list-services
sudo firewall-cmd --reload
sudo firewall-cmd --list-services
sudo firewall-cmd --list-ports
```

Output:

```text
success
8080/tcp
success

success
success
success
success
cockpit dhcpv6-client ssh
success
dhcpv6-client dns http ssh
8080/tcp
```

The runtime port vanished at the reload (empty line), and the permanent changes appeared only after it. The other order also works: change the runtime, test, then save it with `--runtime-to-permanent`.

```bash
sudo firewall-cmd --info-service=wireguard
sudo firewall-cmd --add-service=ntp --add-service=wireguard
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --permanent --list-services
```

Output:

```text
wireguard
  ports: 51820/udp
# ... (trimmed)
success
success
dhcpv6-client dns http ntp ssh wireguard
```

!!! warning "A reload removes untested runtime rules, and a forgotten --permanent is lost at reboot"
    After every change, compare `sudo firewall-cmd --list-all` with `sudo firewall-cmd --permanent --list-all`. A difference means the next reload or reboot changes the firewall.

---

## Rich Rules and Their Order

A metrics port (9100, here an `nc` listener) should accept only `gw` (`172.16.1.2`) and log everyone else. The first attempt added an accept rule and a logged reject rule:

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="172.16.1.2" port port="9100" protocol="tcp" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="9100" protocol="tcp" log prefix="fw-9100 " level="info" limit value="1/m" reject'
sudo firewall-cmd --reload
nc -vz -w3 172.16.1.3 9100    # on gw
sudo journalctl -k --since -10min | grep fw-9100    # on web
```

Output:

```text
success
success
success
nc: connect to 172.16.1.3 port 9100 (tcp) failed: Connection refused
Sep 17 16:15:24 web kernel: fw-9100 IN=eth0 OUT= MAC=02:00:ac:10:01:03:02:00:ac:10:01:02:08:00 SRC=172.16.1.2 DST=172.16.1.3 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=43799 DF PROTO=TCP SPT=37360 DPT=9100 WINDOW=64240 RES=0x00 SYN URGP=0 
# ... (trimmed)
```

`gw` was rejected too. firewalld places rich rules with `reject` or `drop` in a `deny` chain that runs before the `allow` chain, whatever the order of the commands. A negative `priority` moves the accept rule ahead:

```bash
sudo firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="172.16.1.2" port port="9100" protocol="tcp" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule priority="-10" family="ipv4" source address="172.16.1.2" port port="9100" protocol="tcp" accept'
sudo firewall-cmd --reload
nc -vz -w3 172.16.1.3 9100    # on gw
nc -vz -w3 172.16.1.3 9100    # on client
```

Output:

```text
success
success
success
Connection to 172.16.1.3 9100 port [tcp/jetdirect] succeeded!
nc: connect to 172.16.1.3 port 9100 (tcp) failed: Connection refused
```

---

## Source-Based Zones

Binding a source network to a zone gives that network the zone's rules instead of the default zone's. The runtime change below sent `client` into `internal`, which has no port 8080.

```bash
sudo firewall-cmd --zone=internal --add-source=172.16.0.0/24
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=internal --list-services
curl -sS -m3 http://172.16.1.3:8080/    # on client
sudo firewall-cmd --zone=internal --remove-source=172.16.0.0/24
```

Output:

```text
success
internal
  sources: 172.16.0.0/24
public (default)
cockpit dhcpv6-client mdns samba-client ssh
curl: (7) Failed to connect to 172.16.1.3 port 8080 after 0 ms: Couldn't connect to server
success
```

---

## ufw on Ubuntu

On `client` (Ubuntu 24.04), ufw was inactive. The rules below deny incoming traffic except SSH (the `OpenSSH` application profile from `ufw app list`) and port 8080 from the lab networks.

```bash
sudo ufw default deny incoming
sudo ufw allow OpenSSH
sudo ufw allow from 172.16.0.0/16 to any port 8080 proto tcp
sudo ufw enable
sudo ufw status numbered
```

Output:

```text
Default incoming policy changed to 'deny'
(be sure to update your rules accordingly)
Rules updated
Rules updated (v6)
Rules updated
Firewall is active and enabled on system startup
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] OpenSSH                    ALLOW IN    Anywhere
[ 2] 8080/tcp                   ALLOW IN    172.16.0.0/16
[ 3] OpenSSH (v6)               ALLOW IN    Anywhere (v6)
```

From `gw`, port 8080 answered and a blocked port timed out, because ufw drops instead of rejecting:

```bash
curl -s -m3 http://172.16.0.2:8080/    # on gw
nc -vz -w3 172.16.0.2 9001
sudo journalctl -k --since -2min | grep 'UFW BLOCK' | tail -1    # on client
```

Output:

```text
shop-api on client (172.16.0.2:8080) client=172.16.0.3 xff=
nc: connect to 172.16.0.2 port 9001 (tcp) failed: Connection timed out
Sep 17 16:17:53 client kernel: [UFW BLOCK] IN=eth0 OUT= MAC=02:00:ac:10:00:02:02:00:ac:10:00:03:08:00 SRC=172.16.0.3 DST=172.16.0.2 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=42355 DF PROTO=TCP SPT=33388 DPT=9001 WINDOW=64240 RES=0x00 SYN URGP=0 
```

!!! danger "Deleting ufw rules by number removes one address family"
    `sudo ufw allow 9000/tcp` created an IPv4 and an IPv6 rule. `sudo ufw delete 5` removed only the IPv6 one (`Rule deleted (v6)`), and IPv4 port 9000 stayed open. `sudo ufw delete allow 9000/tcp` removed the IPv4 rule and printed `Could not delete non-existent rule (v6)`.

---

## Common Errors

### `nc: connect to 172.16.0.2 port 9001 (tcp) failed: Connection timed out`

**Cause:** a firewall dropped the packet (ufw `deny`, a cloud security group, an nftables `drop`).

**Fix:** look for `[UFW BLOCK]` lines and `sudo ufw status`; then check cloud rules.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between a runtime and a permanent firewalld rule?"
    **Say first:** runtime rules apply at once and are lost on reload or reboot; permanent rules are saved and apply after a reload.

    **Proof:** `sudo firewall-cmd --add-port=8080/tcp` disappears after `sudo firewall-cmd --reload`.

    **Follow-up:** How do you keep a tested runtime rule?

??? question "L1: What is a firewalld zone?"
    **Say first:** a named rule set applied to traffic by source address or interface, with the default zone for everything else.

    **Proof:** `sudo firewall-cmd --get-active-zones`

    **Follow-up:** A source is in `internal` and the interface is in `public`. Which zone applies?
<!-- --8<-- [end:l1] -->

??? question "L2: Open HTTP and a custom port 8080 permanently on RHEL."
    **Say first:** add both with `--permanent`, reload, and verify.

    **Proof:** `sudo firewall-cmd --permanent --add-service=http --add-port=8080/tcp && sudo firewall-cmd --reload && sudo firewall-cmd --list-all`

    **Follow-up:** How do you allow 8080 only from one subnet?

??? question "L2: On Ubuntu, allow PostgreSQL only from the application subnet and enable the firewall without locking yourself out."
    **Say first:** allow SSH first, then the restricted rule, then enable.

    **Proof:** `sudo ufw allow OpenSSH`; `sudo ufw allow from 10.0.1.0/24 to any port 5432 proto tcp`; `sudo ufw enable`; `sudo ufw status numbered`.

    **Follow-up:** Why is deleting rules by number risky?

??? question "L3: A web server answers curl localhost but clients get Couldn't connect. The service listens on 0.0.0.0. What next?"
    **Say first:** check the host firewall, then anything between client and server.

    **Proof:** `sudo firewall-cmd --list-all` (port or service missing); `sudo ufw status`; `sudo nft list ruleset`; cloud security groups; `tcpdump` on the server to see whether packets arrive.

    **Follow-up:** How does a timeout change where you look?

??? question "L3: A rich rule allows a monitoring host, yet that host is still refused. Why?"
    **Say first:** firewalld evaluates deny and reject rich rules before allow rules, so a broader reject rule wins.

    **Proof:** `sudo firewall-cmd --list-rich-rules`; the kernel log shows the monitoring host's address with the reject rule's prefix; add `priority="-10"` to the accept rule.

    **Follow-up:** Where do you see the chains firewalld generated?

---

## Related

- [nftables and iptables](nftables-and-iptables.md): the rules underneath both tools
- [Troubleshooting Ladder](../13-networking/troubleshooting-ladder.md) and [Service Unreachable](../interview/scenarios/service-unreachable.md): the firewall in a connectivity check

Captured on Rocky Linux 10.2 (firewalld 2.4.3, nftables 1.1.5) and Ubuntu 24.04.4 (ufw 0.36.2) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
