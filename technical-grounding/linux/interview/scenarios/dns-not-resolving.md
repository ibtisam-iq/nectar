# DNS Not Resolving

A service works by IP address but not by name. The interviewer checks whether the candidate follows the resolver path on the client (`nsswitch`, `/etc/hosts`, the stub resolver, the upstream servers) before blaming the DNS server, and knows which tools skip which part of that path.

---

## Symptom

> "The app on this Ubuntu host cannot reach api.shop.internal: Could not resolve host. The DNS team says their server answers fine. What do you do?"

---

## Clarifying Questions

- **Does it fail for every name or only internal ones?** Public names working points to routing of internal domains, not to the network.
- **Does the IP address work?** That separates DNS from connectivity.
- **Which server holds the zone, and should this host ask it?** Internal zones are invisible to public resolvers.
- **Did anything change?** A migration, a new VPN, a new resolver configuration or an edited `/etc/hosts`.
- **One host or many?** Many hosts at once suggests the DNS server; one host suggests its resolver configuration.

---

## Diagnostic Path

The `client` (Ubuntu 24.04) uses systemd-resolved with the public servers `1.1.1.1` and `8.8.8.8`. The zone `shop.internal` lives on a BIND server at `172.16.1.3` (Rocky Linux 10.2), which also runs the API on port 8080. An old `/etc/hosts` line for `www.shop.internal` was left behind by an earlier migration.

### 1. Reproduce and Separate DNS from Connectivity

```bash
curl -sS -m5 http://api.shop.internal:8080/
getent hosts api.shop.internal; echo "rc=$?"
ping -c1 api.shop.internal
curl -s -m3 http://172.16.1.3:8080/
```

Output:

```text
curl: (6) Could not resolve host: api.shop.internal
rc=2
ping: api.shop.internal: Name or service not known
shop-api on web (172.16.1.3:8080)
```

The same service answers by IP, so the network is fine. `getent` exit code 2 means the name was not found through any source in `nsswitch.conf`.

### 2. Find Out Which Resolver the Host Asks

```bash
grep ^hosts /etc/nsswitch.conf
ls -l /etc/resolv.conf
grep -v '^#' /etc/resolv.conf | grep .
resolvectl status | head -20
```

Output:

```text
hosts:          files dns
lrwxrwxrwx 1 root root 39 Sep 17 11:55 /etc/resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
nameserver 127.0.0.53
options edns0 trust-ad
search lab.internal
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub
Current DNS Server: 192.0.2.53
       DNS Servers: 192.0.2.53 8.8.8.8 1.1.1.1

Link 2 (eth0)
    Current Scopes: DNS
         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 1.1.1.1
       DNS Servers: 1.1.1.1 8.8.8.8
        DNS Domain: lab.internal
```

Applications ask the local stub at `127.0.0.53`, which forwards to public servers only (`192.0.2.53` is the scrubbed playground resolver). None of them knows `shop.internal`.

### 3. Ask the Internal Server Directly

```bash
dig api.shop.internal | grep -E 'status|SERVER'
resolvectl query api.shop.internal
dig @172.16.1.3 api.shop.internal +short
```

Output:

```text
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 1718
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
api.shop.internal: Name 'api.shop.internal' not found
172.16.1.3
```

The DNS team is right: their server answers. The client never asks it, so the public resolvers return `NXDOMAIN`.

### 4. Route the Internal Domain to the Internal Server

A routing domain (`~` prefix) sends only `shop.internal` queries to `172.16.1.3`:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nDNS=172.16.1.3\nDomains=~shop.internal\n' | sudo tee /etc/systemd/resolved.conf.d/shop.conf
sudo systemctl restart systemd-resolved
resolvectl status | head -8
getent hosts api.shop.internal
curl -sS -m5 http://api.shop.internal:8080/
```

Output:

```text
[Resolve]
DNS=172.16.1.3
Domains=~shop.internal
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub
       DNS Servers: 172.16.1.3
        DNS Domain: ~shop.internal

Link 2 (eth0)
    Current Scopes: DNS
172.16.1.3      api.shop.internal
shop-api on web (172.16.1.3:8080)
```

The restart also dropped the global servers that resolved had imported from the playground's old `resolv.conf` at boot; public names still resolve through `eth0`.

### 5. One Name Still Goes to the Wrong Address

```bash
curl -sS -m5 http://www.shop.internal:8080/
dig +short www.shop.internal
dig @172.16.1.3 +short www.shop.internal
grep shop /etc/hosts
```

Output:

```text
curl: (7) Failed to connect to www.shop.internal port 8080 after 3059 ms: Couldn't connect to server
172.16.1.99
api.shop.internal.
172.16.1.3
172.16.1.99     www.shop.internal
```

The error changed from "resolve" to "connect", so a name was found, but the wrong one. The zone says `www` is a CNAME for `api`; the stale `/etc/hosts` line wins because `files` comes first in `nsswitch.conf`, and systemd-resolved also serves `/etc/hosts` entries through `127.0.0.53`, which is why even `dig` without `@server` returned the old address.

```bash
sudo sed -i '/www.shop.internal/d' /etc/hosts
getent hosts www.shop.internal
sleep 5; getent hosts www.shop.internal
curl -sS -m5 http://www.shop.internal:8080/
```

Output:

```text
172.16.1.99     www.shop.internal
172.16.1.3      api.shop.internal www.shop.internal
shop-api on web (172.16.1.3:8080)
```

Directly after the edit, `getent` still returned the old address from resolved's copy of the file; five seconds later resolved had reloaded it.

!!! warning "dig and getent answer different questions"
    `getent hosts` follows `nsswitch.conf` like applications do. `dig @server` asks one DNS server and ignores `/etc/hosts`, so it is the tool to prove what the zone says, not what the application sees.

### 6. A New Record Does Not Resolve

The DNS team adds `cache.shop.internal` and bumps the serial, but clients get `NXDOMAIN`:

```bash
dig @172.16.1.3 cache.shop.internal | grep -E 'status|flags'
dig @172.16.1.3 shop.internal SOA +short
```

Output:

```text
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 7677
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
ns1.shop.internal. hostmaster.shop.internal. 2026091701 3600 600 604800 60
```

The serial is still the old one, so the server never loaded the edit. On the server:

```bash
sudo journalctl -u named --since -5min --no-pager -o cat | grep -i shop.internal | tail -4
```

Output:

```text
received control channel command 'reload shop.internal'
dns_rdata_fromtext: shop.internal.zone:15: near '172.16.1.256': bad dotted quad
zone shop.internal/IN: loading from master file shop.internal.zone failed: bad dotted quad
zone shop.internal/IN: not loaded due to errors.
```

A typo (`172.16.1.256`) made the reload fail, and BIND kept serving the previous version of the zone. Restarting it instead made things worse (the restart on the server, the queries on the client):

```bash
sudo systemctl restart named
dig @172.16.1.3 api.shop.internal +tries=1 +time=2
resolvectl query db.shop.internal
resolvectl query api.shop.internal | head -1
```

Output:

```text
Job for named.service failed because the control process exited with error code.
See "systemctl status named.service" and "journalctl -xeu named.service" for details.
;; communications error to 172.16.1.3#53: connection refused
# ... (trimmed)
;; no servers could be reached
db.shop.internal: resolve call failed: Lookup failed due to system error: Connection refused
api.shop.internal: 172.16.1.3                               -- link: eth0
```

The RHEL unit runs `named-checkconf -z` before starting, so one bad zone keeps the whole server down. `api` still resolved from the client's cache (TTL 300 s), which hides an outage for names looked up recently.

```bash
sudo sed -i 's/172.16.1.256/172.16.1.20/' /var/named/shop.internal.zone
sudo named-checkzone shop.internal /var/named/shop.internal.zone
sudo systemctl start named
resolvectl query cache.shop.internal | head -1
```

Output:

```text
zone shop.internal/IN: shop.internal/MX 'mail.shop.internal' has no address records (A or AAAA)
zone shop.internal/IN: loaded serial 2026091702
OK
cache.shop.internal: 172.16.1.20                            -- link: eth0
```

The MX warning is real but harmless here; the last command ran on the client, which now resolves the new record.

!!! danger "Check a zone before reloading or restarting"
    Run `named-checkzone` (and `named-checkconf -z`) before every reload. A failed reload leaves old data in service; a failed restart takes every zone on the server offline.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Internal domain sent to public resolvers | `dig @internal` works, `dig` via the stub gives `NXDOMAIN` | Routing domain in resolved (`Domains=~zone`), VPN or DHCP DNS settings |
| Stale `/etc/hosts` entry | `getent` differs from `dig @server`; `grep name /etc/hosts` | Remove the line; manage hosts files with configuration management |
| Wrong or missing nameserver | `resolvectl status` or `/etc/resolv.conf` lists nothing reachable | Fix netplan, NetworkManager or DHCP; do not edit a managed `resolv.conf` |
| DNS traffic blocked | `dig @server` times out; `tcpdump port 53` shows no reply | Open UDP and TCP 53 in the firewall or security group |
| Zone failed to load | Old SOA serial; `not loaded due to errors` in the server log | `named-checkzone`, fix, reload |
| Cached answers | Old address until the TTL expires | Wait for the TTL, `resolvectl flush-caches`, lower TTLs before a migration |
| Search domain confusion | Short name resolves to the wrong FQDN | Use FQDNs; check `search` in `resolv.conf` |
| Stub resolver down | `connection refused` on `127.0.0.53` | `systemctl status systemd-resolved` |
| Container or pod DNS | Works on the host, not in the container | Check the container's own `/etc/resolv.conf` and the runtime's DNS settings |

---

## Fix

Make the client ask the server that holds the zone (a routing domain, not a replacement of all resolvers), remove local overrides that shadow DNS, and repair the zone on the server with a checked reload.

---

## Prevention

- Configure DNS through the tool that owns it (netplan, NetworkManager, resolved drop-ins), never by editing a generated `resolv.conf`.
- Keep `/etc/hosts` to the host's own names; anything else belongs in DNS.
- Run `named-checkzone` in the change pipeline for zone files, and alert on the SOA serial on every secondary.
- Lower record TTLs a day before a planned address change.
- Monitor name resolution from client networks as well as from the DNS server itself.

---

## Related

- [DNS Resolution](../../13-networking/dns-resolution.md): `nsswitch`, systemd-resolved and `dig`
- [Network Configuration](../../13-networking/network-configuration.md): who writes `/etc/resolv.conf`
- [Connectivity Testing](../../13-networking/connectivity-testing.md): proving the service answers by IP
- [journalctl](../../09-logging/journalctl.md): reading the server log

Captured on Ubuntu 24.04.4 (systemd 255, dig 9.18.39) and Rocky Linux 10.2 (BIND 9.18.33) on iximiuz Labs FlexBox microVMs, kernel 6.1.167, 2026-09.
