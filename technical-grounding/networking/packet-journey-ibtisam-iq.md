# OSI Model — The Complete Packet Journey

> This is not a memorization document. This is a **systems thinking** document.
> After reading this, every Kubernetes/Docker networking doc will make sense.

---

## 1. Why OSI Exists

Before OSI, every vendor built proprietary systems — IBM, HP, Cisco — none could communicate
with each other. **ISO** created the **OSI (Open Systems Interconnection)** model in 1984
as a **universal blueprint** for network communication.

> It defines: what job gets done, at which layer, by which protocol.

---

## 2. The 7 Layers — Overview

| Layer | Name | PDU Name | Key Job |
|-------|------|----------|---------|
| 7 | Application | Data | User-facing protocols (HTTP, DNS, SMTP) |
| 6 | Presentation | Data | Encryption, compression, format conversion |
| 5 | Session | Data | Session open/close/track |
| 4 | Transport | **Segment** (TCP) / **Datagram** (UDP) | Reliable delivery, ports, flow control |
| 3 | Network | **Packet** | IP addressing, routing |
| 2 | Data Link | **Frame** | MAC addressing, local delivery |
| 1 | Physical | **Bits** | Electrical/light/radio signal transmission |

> **PDU = Protocol Data Unit** — what the data is called at each layer.
> Each layer **wraps** the layer above it. This is called **Encapsulation**.

---

## 3. Encapsulation vs Decapsulation

**Sender side (top → bottom):** Each layer adds its own header.

```
[HTTP Data]
[TCP Header][HTTP Data]                                              ← Segment
[IP Header][TCP Header][HTTP Data]                                   ← Packet
[ETH Header][IP Header][TCP Header][HTTP Data][ETH Trailer]          ← Frame
→ converted to Bits → transmitted
```

**Receiver side (bottom → top):** Each layer strips its header and passes up.

```
Bits → Frame → Packet → Segment → Data (reaches application)
```

---

## 4. Your Actual Setup (ibtisam-iq.com)

Before the journey, understand the infrastructure:

```
ibtisam-iq.com
      ↓ registered on
  GoDaddy  (domain registrar only — no DNS control)
      ↓ nameservers delegated to
  Cloudflare  (authoritative DNS + reverse proxy + CDN)
      ↓ DNS A record / CNAME points to
  GitHub Pages  (actual static file server — the true origin)
```

**Cloudflare has two modes:**

| Mode | Icon | IP returned by DNS | Where request goes |
|------|------|--------------------|--------------------|
| **Proxied** (recommended) | 🟠 Orange cloud | Cloudflare edge IP | Browser → Cloudflare → GitHub Pages |
| **DNS Only** | ☁️ Grey cloud | GitHub Pages IP directly | Browser → GitHub Pages directly |

> In Proxied mode, your real origin IP (GitHub Pages) stays hidden.
> All examples below assume **Proxied mode** (the real-world path).

---

## 5. The Full Journey: `ibtisam-iq.com` → Response

You open Chrome, type `https://ibtisam-iq.com`, press Enter.
Here is **everything** that happens — in exact order.

---

### Phase 1 — DNS Resolution (Before any data is sent) ⭐

Your browser only knows `ibtisam-iq.com`. It needs an IP. This is a **pre-connection step**.

**DNS lookup order (macOS):**

```
1. Browser DNS cache
       Chrome stores recent lookups (~60s TTL)
       Hit? → skip everything below.

2. OS DNS cache
       macOS mDNSResponder holds recent lookups
       Hit? → skip below.

3. /etc/hosts file
       Static override table on your machine
       e.g. if you added:  127.0.0.1  ibtisam-iq.com  → it goes to localhost
       Hit? → use that IP directly, no DNS query.

4. Configured DNS Resolver
       Your Wi-Fi DNS (ISP or custom like 8.8.8.8 / 1.1.1.1)
       This resolver now does Recursive Resolution on your behalf:

5. Recursive DNS Resolution
       Resolver → Root Nameserver
                  "Who handles .com?"
       Root NS  → .com TLD Nameserver
                  "Who handles ibtisam-iq.com?"
       TLD NS   → Cloudflare Nameserver (e.g. ns1.cloudflare.com)
                  ← because YOU set Cloudflare NS in GoDaddy dashboard
       Cloudflare NS → returns Cloudflare edge IP (NOT GitHub Pages IP)
                       because proxy is ON 🟠
```

**Result:** `ibtisam-iq.com` → Cloudflare edge IP (e.g. `104.21.x.x`)

> **Note:** Nobody except you and Cloudflare knows that GitHub Pages is behind this.
> The entire internet sees only Cloudflare's IP.

---

**Your VPN DNS bug — explained:**

> You tested VPNs → closed them → browser stopped working despite Wi-Fi being connected.

VPN hijacks Step 4 (your DNS resolver) and points it to the VPN's internal DNS server.
When you close the VPN, the DNS config is left broken — pointing to a dead server.
Browser tries to resolve `ibtisam-iq.com` → DNS timeout → "site can't be reached".

Fix on macOS:
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Or manually reset DNS in: System Settings → Wi-Fi → DNS → restore to 8.8.8.8 or 1.1.1.1.

---

### Phase 2 — TCP 3-Way Handshake (Layer 4) ⭐

Before sending any HTTP data, a **reliable connection** must be established with Cloudflare.
This happens at **Layer 4 (Transport)** using TCP.

```
Your MacBook (Port 52341)           Cloudflare Edge (Port 443)
        |                                     |
        |-------- SYN (seq=x) -------------->|   "I want to connect. My seq# is x"
        |                                     |
        |<------- SYN-ACK (seq=y, ack=x+1) --|   "OK. My seq# is y. I got your x."
        |                                     |
        |-------- ACK (ack=y+1) ------------>|   "Got y. Connection established."
        |                                     |
               TCP CONNECTION OPEN
```

**Why 3 steps?** Both sides must confirm they can send AND receive independently.
After this, both sides have agreed on **sequence numbers** — used to reorder segments and
detect missing ones.

---

### Phase 3 — TLS Handshake (Layer 5/6) ⭐

HTTPS requires an **encrypted tunnel** before any real data is sent.
This happens at **Layer 5/6 (Session + Presentation)** between your browser and Cloudflare.

```
Your MacBook                        Cloudflare Edge
        |                                     |
        |------ ClientHello ---------------->|   "I support TLS 1.3. Here are my cipher suites."
        |                                     |
        |<----- ServerHello + Certificate ---|   "Use AES-256-GCM. Here is my SSL cert
        |                                     |    (issued by Cloudflare for ibtisam-iq.com)"
        |                                     |
        | [Browser verifies cert with CA]     |
        |                                     |
        |------ Key Exchange --------------->|   "Here's info to derive a shared session key"
        |                                     |
        | [Both sides independently derive    |
        |  the same symmetric session key]    |
        |                                     |
        |------ Finished ----------------->  |
        |<----- Finished ------------------- |
        |                                     |
               ENCRYPTED TUNNEL ESTABLISHED
```

> Cloudflare handles TLS termination — the SSL cert your browser sees is Cloudflare's,
> not GitHub's. This is by design in proxied mode.

---

### Phase 4 — HTTP Request Built (Layer 7)

Browser constructs the HTTP request inside the encrypted tunnel:

```
GET / HTTP/1.1
Host: ibtisam-iq.com
User-Agent: Chrome/...
Accept: text/html,application/xhtml+xml
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
```

This is your **Application layer data**.

---

### Phase 5 — Encapsulation (Data Travels DOWN Your MacBook's Stack)

Everything below happens in milliseconds inside your OS network stack:

| Layer | What Happens | Header/Info Added |
|-------|-------------|-------------------|
| **L7 Application** | HTTP GET request created | — |
| **L6 Presentation** | Data encrypted by TLS session key | — |
| **L5 Session** | Session tracked (session ID, keep-alive) | — |
| **L4 Transport** | Broken into **Segments**; TCP header added | Src Port: 52341, Dst Port: 443, Seq#, ACK# |
| **L3 Network** | **Packet** created; IP header added | Src IP: 192.168.1.x, Dst IP: Cloudflare edge IP |
| **L2 Data Link** | ARP resolves router's MAC → **Frame** built | Src MAC: your NIC MAC, Dst MAC: router's MAC |
| **L1 Physical** | Frame → bits → radio waves (Wi-Fi) or electrical (Ethernet) | — |

> **Key:** At L2, destination MAC = your **home router's MAC**, not Cloudflare's.
> MAC is always hop-to-hop. IP is end-to-end.

---

### Phase 6 — Data Leaves Your MacBook

The bits leave via:
- **Wi-Fi** → radio waves to your home router
- **Ethernet** → electrical signal on cable

Your MacBook's job is done for now. Packet is in the network.

---

### Phase 7 — At Your Home Router

Your router operates at **L2 and L3**. Exact steps:

```
Incoming Frame (from your MacBook):
  [ETH: Src=YourMAC, Dst=RouterMAC]
  [IP: Src=192.168.1.x, Dst=Cloudflare_IP]
  [TCP Segment][Encrypted HTTP Data]

Step 1 — L2: Router strips Ethernet frame (it was addressed to router's MAC ✅)
Step 2 — L3: Reads IP packet → Dst = Cloudflare IP → needs internet
Step 3 — NAT: Rewrites Src IP from 192.168.1.x → YOUR PUBLIC IP (e.g. 39.57.x.x)
              Stores in NAT table: 192.168.1.x:52341 ↔ 39.57.x.x:52341
Step 4 — L2: Builds NEW Ethernet frame for next hop (ISP gateway):
              Src MAC = Router WAN MAC
              Dst MAC = ISP Gateway MAC
Step 5 — L1: Sends bits out toward ISP

Outgoing Frame:
  [ETH: Src=RouterWAN_MAC, Dst=ISP_GW_MAC]
  [IP: Src=39.57.x.x, Dst=Cloudflare_IP]
  [TCP Segment][Encrypted HTTP Data]
```

> IP modified (NAT). MAC completely replaced. TCP + HTTP data untouched.

---

### Phase 8 — Internet Journey (Multiple Router Hops)

Packet travels through multiple routers across the internet.
Every router does the same 3 steps:

```
1. Strip incoming L2 frame
2. Read L3 IP → check routing table → find next hop
3. Build new L2 frame for next hop → forward
```

Only **Layer 3** matters on the internet.
L2 (MAC) is completely rebuilt at every single hop.

You can see every hop live:
```bash
traceroute ibtisam-iq.com
```

---

### Phase 9 — At Cloudflare Edge

This is where your setup becomes unique — **Cloudflare is not the final destination**.

```
Request arrives at Cloudflare edge (anycast IP — nearest datacenter to you)

Cloudflare does:

Step 1 — TLS Termination
         Decrypts the request using your session key
         Now Cloudflare can read: GET / HTTP/1.1 Host: ibtisam-iq.com

Step 2 — Cache Check
         Is this page cached? (HTML, CSS, JS, images)
         ✅ Cache HIT  → serve directly from Cloudflare edge, never touches GitHub
         ❌ Cache MISS → must fetch from origin (GitHub Pages)

Step 3 — Forward to GitHub Pages (on cache miss)
         New TCP connection: Cloudflare → 185.199.108.153 (GitHub Pages IP)
         New TLS handshake: Cloudflare ↔ GitHub Pages
         HTTP request forwarded: GET / HTTP/1.1 Host: ibtisam-iq.com

Step 4 — GitHub Pages responds
         Finds your repo (ibtisam-iq/portfolio-site or whatever is linked)
         Serves index.html + assets

Step 5 — Cloudflare receives response
         Optionally caches it for next request
         Re-encrypts it using YOUR browser's session key
         Sends response back to you
```

**Two separate TLS tunnels exist:**

```
Browser ←──── TLS ────→ Cloudflare       (Cloudflare's SSL cert)
              Cloudflare ←── TLS ──→ GitHub Pages  (GitHub's SSL cert)
```

---

### Phase 10 — Decapsulation at Your MacBook

Response travels back → your router reverse-NATs it → your MacBook receives it.

Data travels **UP** your OS network stack:

| Layer | What Happens |
|-------|-------------|
| **L1 Physical** | Bits received → converted back to Frame |
| **L2 Data Link** | Frame's Dst MAC verified (it's yours ✅) → ETH header stripped → Packet extracted |
| **L3 Network** | Dst IP verified (your IP ✅) → IP header stripped → Segment extracted |
| **L4 Transport** | TCP reassembles all segments in correct order → checks missing ones → sends ACKs → HTTP data extracted |
| **L5 Session** | Session identified → keep-alive tracked |
| **L6 Presentation** | Data decrypted using TLS session key |
| **L7 Application** | HTTP response parsed → Chrome renders HTML → ibtisam-iq.com displays ✅ |

---

## 6. Complete Timeline (Everything in Order)

```
You type: ibtisam-iq.com → Enter
              ↓
[DNS Phase]
Browser cache → OS cache → /etc/hosts → DNS Resolver
→ Root NS → .com TLD NS → Cloudflare NS
→ Returns: Cloudflare edge IP (104.21.x.x)
              ↓
[L4] TCP 3-Way Handshake
     Your MacBook ←→ Cloudflare edge
     SYN → SYN-ACK → ACK
              ↓
[L5/L6] TLS Handshake
     ClientHello → ServerHello+Cert → KeyExchange → Finished
     Encrypted tunnel: Browser ↔ Cloudflare
              ↓
[L7] HTTP GET / built inside tunnel
[L6] Encrypted by TLS
[L5] Session tracked
[L4] TCP Segment (src:52341, dst:443, seq#)
[L3] IP Packet (src:192.168.1.x, dst:Cloudflare IP)
[L2] ARP → Router MAC → Ethernet Frame
[L1] Bits → Wi-Fi radio waves
              ↓
[Home Router]
NAT: 192.168.1.x → 39.57.x.x
MAC header replaced (Router WAN MAC → ISP Gateway MAC)
              ↓
[Internet]
Multiple router hops — L3 only, L2 rebuilt at every hop
(traceroute ibtisam-iq.com to see them)
              ↓
[Cloudflare Edge]
TLS termination → read HTTP request
Cache hit? → serve from edge ✅
Cache miss? → new TCP+TLS → GitHub Pages (185.199.108.153)
GitHub Pages serves your static files
Cloudflare re-encrypts → sends back
              ↓
[Return Path]
Cloudflare → Internet → Router (reverse NAT) → Your MacBook
              ↓
[MacBook Decapsulation]
L1→L2→L3→L4→L5→L6→L7
Chrome renders ibtisam-iq.com ✅
```

---

## 7. TCP vs UDP

| | TCP | UDP |
|--|-----|-----|
| Connection | ✅ Connection-oriented (3-way handshake) | ❌ Connectionless |
| Reliability | ✅ Retransmits lost segments | ❌ Fire and forget |
| Order | ✅ Sequence numbers ensure order | ❌ No ordering |
| Speed | ❌ Slower (overhead) | ✅ Faster |
| Use cases | HTTP/S, SSH, Email (SMTP), FTP | DNS queries, Video streaming, Gaming, VoIP |

> **DNS uses UDP** for regular queries (fast, small packets).
> Switches to TCP when response > 512 bytes (e.g. full zone transfers).

---

## 8. OSI vs TCP/IP Model

| OSI Layer | OSI Name | TCP/IP Layer | TCP/IP Name |
|-----------|---------|-------------|------------|
| 7 | Application | 4 | Application |
| 6 | Presentation | 4 | Application |
| 5 | Session | 4 | Application |
| 4 | Transport | 3 | Transport |
| 3 | Network | 2 | Internet |
| 2 | Data Link | 1 | Network Access |
| 1 | Physical | 1 | Network Access |

> OSI = theoretical reference model (7 layers).
> TCP/IP = practical model used in the real internet (4 layers).
> When engineers say "Layer 3" — they always mean the **OSI numbering**.

---

## 9. Devices by Layer

| Device | OSI Layer | Works on | Job |
|--------|-----------|---------|-----|
| **Hub** | Layer 1 | Bits | Broadcasts to all ports — dumb, legacy |
| **Switch** | Layer 2 | MAC address | Forwards frames to correct port only |
| **Router** | Layer 3 | IP address | Routes packets between networks |
| **Firewall** | L3–L4 (basic) / L7 (NGFW) | IP+Port / Payload | Filters traffic by rules |
| **L4 Load Balancer** | Layer 4 | IP:Port | Distributes TCP connections across servers |
| **L7 Load Balancer** | Layer 7 | HTTP headers/URL | Routes by Host header, path, cookies |
| **Cloudflare (proxy)** | Layer 7 | HTTP/HTTPS | CDN + DDoS protection + TLS termination |
| **NIC** | Layer 1–2 | Bits + MAC | Sends/receives signals, has MAC address |
| **Cable / Wi-Fi** | Layer 1 | Bits | Physical medium |

---

## 10. Protocols by Layer

| Layer | Protocols |
|-------|----------|
| 7 | HTTP, HTTPS, DNS, FTP, SMTP, IMAP, SSH, DHCP, SNMP |
| 6 | TLS/SSL, JPEG, MPEG, ASCII, gzip encoding |
| 5 | NetBIOS, RPC, PPTP (session establishment) |
| 4 | TCP, UDP |
| 3 | IP (IPv4/IPv6), ICMP (`ping`, `traceroute`), OSPF, BGP |
| 2 | Ethernet, ARP, Wi-Fi (802.11), PPP |
| 1 | Ethernet cable, Fiber optic, Wi-Fi radio, Bluetooth |

---

## 11. Why This Matters for Kubernetes/Docker

Every K8s and Docker networking concept maps directly to OSI layers:

| K8s/Docker Concept | OSI Layer | Why |
|-------------------|-----------|-----|
| Pod IP, Node IP | L3 | IP routing between pods/nodes |
| Service (ClusterIP) | L3–L4 | kube-proxy routes by IP:Port |
| Ingress / Nginx | L7 | Routes by HTTP Host header or URL path |
| Network Policy | L3–L4 | Firewall rules on IP + Port |
| CNI plugin (Flannel, Calico) | L2–L3 | Virtual network overlay |
| Docker bridge (`docker0`) | L2 | Virtual switch between containers |
| NodePort / LoadBalancer | L4 | TCP port exposure to outside |
| iptables rules | L3–L4 | Packet filtering + NAT inside nodes |
| Cloudflare in front of K8s | L7 | Same as above — TLS termination + CDN |

> When K8s docs say "L3 routing" or "L7 load balancing" — you now know exactly what that means.

---

## 12. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| DNS runs at L3 | DNS is an L7 (Application layer) protocol |
| MAC address travels end-to-end | MAC is hop-to-hop — rebuilt at every router |
| IP changes at every router | IP stays same end-to-end (except at NAT) |
| TCP handshake happens before DNS | DNS resolves IP first, THEN TCP handshake |
| TLS = Layer 4 | TLS operates at L5/L6 (Session + Presentation) |
| Router only does L3 | Router strips/rebuilds L2 frame + does L3 routing + NAT |
| OSI = TCP/IP | OSI is the reference model; TCP/IP is the real-world implementation |
| Cloudflare = just DNS | Cloudflare is also a reverse proxy, CDN, TLS terminator (L7) |
| GitHub Pages IP is exposed | In Proxied mode, Cloudflare edge IP is shown — GitHub IP hidden |

---

## 13. Interview Questions Checklist ✅

- [ ] What is the OSI model and why was it created?
- [ ] Name all 7 layers — PDU name at each layer?
- [ ] What is encapsulation? What is decapsulation?
- [ ] Walk through the complete journey of a request end-to-end
- [ ] What is DNS? What is the full DNS resolution order?
- [ ] What is a recursive DNS resolver?
- [ ] What is an authoritative nameserver?
- [ ] What is the TCP 3-way handshake? Why 3 steps?
- [ ] What is the TLS handshake? At which OSI layer?
- [ ] What does a router do at which layers?
- [ ] What is NAT? Why is it needed? Where does it happen?
- [ ] Does MAC change at every hop? Does IP change?
- [ ] TCP vs UDP — when to use each?
- [ ] OSI vs TCP/IP — map the layers
- [ ] L4 vs L7 load balancer — what is the difference?
- [ ] Switch / Router / Firewall / Load Balancer — which OSI layer?
- [ ] What is Cloudflare proxy mode vs DNS-only?
- [ ] How many TLS connections exist when Cloudflare proxies GitHub Pages?
- [ ] Why does VPN break DNS? How to fix it?
