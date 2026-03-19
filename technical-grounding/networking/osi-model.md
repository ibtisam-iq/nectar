# OSI Model — The Complete Packet Journey

> This is not a memorization document. This is a **systems thinking** document.
> After reading this, every Kubernetes/Docker networking doc will make sense.

---

## 1. Why OSI Exists

Before OSI, every vendor built proprietary systems — IBM, HP, Cisco — none could communicate with each other. [web:91]
**ISO** created the **OSI (Open Systems Interconnection)** model in 1984 as a **universal blueprint** for network communication.

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

**Sender side (top → bottom):** Each layer adds its own header → wrapping the data further.

```
[HTTP Data]
[TCP Header][HTTP Data]                        ← Segment
[IP Header][TCP Header][HTTP Data]             ← Packet
[ETH Header][IP Header][TCP Header][HTTP Data][ETH Trailer]  ← Frame
→ converted to Bits → transmitted
```

**Receiver side (bottom → top):** Each layer strips its header → passes up.

```
Bits → Frame → Packet → Segment → Data (reaches application)
```

---

## 4. The Full Journey: `google.com` → Response

You open Chrome, type `https://google.com`, press Enter.
Here is **everything** that happens — in exact order.

---

### Phase 1 — DNS Resolution (Before any data is sent) ⭐

Your browser only knows `google.com`. It needs an IP. This is a **pre-connection step**.

**DNS lookup order (macOS/Linux):** [web:87]

```
1. Browser DNS cache         → Chrome stores recent lookups (~60s TTL)
2. OS DNS cache              → mDNSResponder (macOS) / nscd (Linux)
3. /etc/hosts file           → static override table on your machine
4. Configured DNS Resolver   → your ISP's DNS or 8.8.8.8 (set in Wi-Fi settings)
5. Recursive DNS resolution  → DNS resolver queries on your behalf:
      → Root Nameserver      (knows where .com lives)
      → TLD Nameserver       (knows where google.com lives)
      → Authoritative NS     (holds actual A record: google.com → 142.250.x.x)
```

**Result:** `google.com` → `142.250.64.46` (example)

> **Your VPN DNS issue explained:**
> VPN hijacks your DNS resolver (Step 4). When you close VPN, it sometimes leaves behind a broken DNS config pointing to a dead VPN server. Your browser can't resolve any domain → "no internet" even though Wi-Fi works.
> Fix: edit `/etc/resolv.conf` (Linux) or flush DNS cache on macOS:
> ```bash
> sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
> ```

---

### Phase 2 — TCP 3-Way Handshake (Layer 4) ⭐

Before sending any HTTP data, a **reliable connection** must be established.
This happens at **Layer 4 (Transport)** using TCP. [web:90]

```
Client                          Server (142.250.64.46:443)
  |                                  |
  |-------- SYN (seq=x) ---------->  |   "I want to connect. My seq# is x"
  |                                  |
  |<---- SYN-ACK (seq=y, ack=x+1) --|   "OK. My seq# is y. Got your x."
  |                                  |
  |-------- ACK (ack=y+1) -------->  |   "Got your y. Connection established."
  |                                  |
         CONNECTION ESTABLISHED
```

**Why 3-way?** Both sides need to confirm they can **send AND receive**. [web:90]
After this, port `443` is open and both sides have agreed on sequence numbers for ordering data.

---

### Phase 3 — TLS Handshake (Layer 5/6) ⭐

HTTPS requires **encryption** before any HTTP data is sent.
This happens at **Layer 5/6** (Session + Presentation).

```
Client                              Server
  |                                    |
  |------ ClientHello ---------------> |   "I support TLS 1.3, here are my cipher suites"
  |                                    |
  |<----- ServerHello + Certificate -- |   "Use AES-256. Here is my SSL cert."
  |                                    |
  | [Client verifies cert with CA]     |
  |                                    |
  |------ Key Exchange -------------> |   "Here's the pre-master secret (encrypted)"
  |                                    |
  | [Both sides derive session keys]   |
  |                                    |
  |------ Finished ----------------> |
  |<----- Finished ------------------|
  |                                    |
         ENCRYPTED TUNNEL ESTABLISHED
```

Now all HTTP data travels **encrypted** through this tunnel.

---

### Phase 4 — HTTP Request Built (Layer 7)

Browser constructs:
```
GET / HTTP/1.1
Host: google.com
User-Agent: Chrome/...
Accept: text/html
```
This is your **Application layer data**.

---

### Phase 5 — Encapsulation (Data Travels DOWN Your MacBook's Stack)

This all happens in milliseconds inside your OS network stack:

| Layer | What Happens | Added Header |
|-------|-------------|-------------|
| **L7 Application** | HTTP request created | — |
| **L6 Presentation** | Data encrypted by TLS | — |
| **L5 Session** | Session tracked (cookies, session ID) | — |
| **L4 Transport** | Data broken into **Segments**; TCP header added | Src Port: 52341, Dst Port: 443, Seq#, ACK# |
| **L3 Network** | **Packet** created; IP header added | Src IP: 192.168.1.10, Dst IP: 142.250.64.46 |
| **L2 Data Link** | ARP resolves router's MAC; **Frame** created | Src MAC: your NIC, Dst MAC: your router's MAC |
| **L1 Physical** | Frame converted to **bits** → electrical/radio signal | — |

> **Important:** At L2, destination MAC = **your router's MAC**, NOT Google's MAC.
> MAC addresses only travel hop-to-hop. IP addresses travel end-to-end.

---

### Phase 6 — Data Leaves Your MacBook

The bits leave via:
- **Wi-Fi** → radio waves to your router
- **Ethernet** → electrical signals on cable

Your MacBook's job is **done**. The packet is now in the network.

---

### Phase 7 — At Your Home Router (CRITICAL)

The router operates at **Layer 2 and Layer 3**. Here is exactly what it does:

```
Incoming Frame:
  [ETH: Src=YourMAC, Dst=RouterMAC][IP: Src=192.168.1.10, Dst=142.250.64.46][TCP][HTTP]

Step 1 — L2: Router strips Ethernet frame (reads its own MAC → accepts it)
Step 2 — L3: Router reads IP packet → Dst IP = 142.250.64.46 (needs to go to internet)
Step 3 — NAT: Router rewrites Src IP from 192.168.1.10 → YOUR_PUBLIC_IP (e.g. 39.x.x.x)
             (stores mapping in NAT table: 192.168.1.10:52341 ↔ 39.x.x.x:52341)
Step 4 — L2: Router builds NEW Ethernet frame:
             Src MAC = Router's WAN MAC
             Dst MAC = ISP's gateway MAC (next hop)
Step 5 — L1: Sends bits out to ISP

Outgoing Frame:
  [ETH: Src=RouterWAN_MAC, Dst=ISP_GW_MAC][IP: Src=39.x.x.x, Dst=142.250.64.46][TCP][HTTP]
```

**Key insight:** IP header was modified (NAT). MAC header was completely replaced. TCP/HTTP untouched. [web:91]

---

### Phase 8 — Internet Journey

Packet hops through multiple routers across the internet.
**Each router** does the same thing:

```
1. Strip incoming L2 frame (reads its MAC)
2. Read L3 IP → check routing table → find next hop
3. Build new L2 frame with next hop's MAC
4. Forward
```

> Only **Layer 3** matters on the internet. Each router replaces L2 entirely at every hop.
> You can trace this: `traceroute google.com`

---

### Phase 9 — At Google's Server (Decapsulation)

Data travels **UP** the stack — reverse of encapsulation: [web:94][web:97]

| Layer | What Happens |
|-------|-------------|
| **L1 Physical** | Bits received → electrical signal converted back to frame |
| **L2 Data Link** | Frame's MAC verified → Ethernet header stripped → Packet extracted |
| **L3 Network** | Packet's Dst IP verified (matches server) → IP header stripped → Segment extracted |
| **L4 Transport** | TCP reassembles segments in order → checks for missing segments → ACKs back → HTTP data extracted |
| **L5 Session** | Session identified and tracked |
| **L6 Presentation** | Data decrypted using TLS session key |
| **L7 Application** | HTTP request parsed → Google processes it → builds HTTP response |

---

### Phase 10 — Response Returns (Same Path, Reversed)

Google's server:
1. Builds HTTP response (HTML page)
2. Encrypts it (TLS)
3. Encapsulates → Segment → Packet → Frame → Bits
4. Sends back to your public IP

Your router:
- Receives packet, checks NAT table
- Rewrites Dst IP from `39.x.x.x` → `192.168.1.10` (reverse NAT)
- Forwards to your MacBook

Your MacBook decapsulates → Chrome renders the page. ✅

---

## 5. Complete Timeline (Everything in Order)

```
User types google.com
        ↓
[DNS] Browser cache → OS cache → /etc/hosts → DNS Resolver → Recursive DNS
        ↓
IP resolved: 142.250.64.46
        ↓
[L4] TCP 3-Way Handshake (SYN → SYN-ACK → ACK)
        ↓
[L5/6] TLS Handshake (encrypt tunnel established)
        ↓
[L7] HTTP GET request built
        ↓
[L6] Data encrypted
[L5] Session tracked
[L4] Segmented + TCP header (port 443, seq#)
[L3] IP header added (src: 192.168.1.10, dst: 142.250.64.46)
[L2] ARP → router MAC → Ethernet frame built
[L1] Bits → Wi-Fi radio waves
        ↓
[Router] NAT + MAC rewrite → forwards to ISP
        ↓
[Internet] Multiple routers: L3 routing only, L2 rebuilt at every hop
        ↓
[Google Server] L1→L2→L3→L4→L5→L6→L7 → request processed
        ↓
Response follows same path in reverse
        ↓
Chrome renders page ✅
```

---

## 6. TCP vs UDP

| | TCP | UDP |
|--|-----|-----|
| Connection | ✅ Connection-oriented (3-way handshake) | ❌ Connectionless |
| Reliability | ✅ Retransmits lost segments | ❌ Fire and forget |
| Order | ✅ Sequence numbers ensure order | ❌ No ordering |
| Speed | ❌ Slower (overhead) | ✅ Faster |
| Use cases | HTTP/S, Email (SMTP), SSH, FTP | DNS, Video streaming, Gaming, VoIP |

> **DNS uses UDP** for regular queries (fast, small). Uses TCP when response > 512 bytes (zone transfers).

---

## 7. OSI vs TCP/IP Model

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
> TCP/IP = practical model used in real internet (4 layers).
> When engineers say "Layer 3", they always mean the **OSI numbering**.

---

## 8. Devices by Layer

| Device | OSI Layer | Works on | Job |
|--------|-----------|---------|-----|
| **Hub** | Layer 1 | Bits | Broadcasts to all ports (dumb, legacy) |
| **Switch** | Layer 2 | MAC address | Forwards frames to correct port only |
| **Router** | Layer 3 | IP address | Routes packets between networks |
| **Firewall** | Layer 3–4 (basic) / Layer 7 (NGFW) | IP + Port / Payload | Filters traffic by rules |
| **Load Balancer** | Layer 4 or Layer 7 | Port / HTTP headers | Distributes traffic across servers |
| **NIC** | Layer 1–2 | Bits + MAC | Sends/receives signals, has MAC address |
| **Cable / Wi-Fi** | Layer 1 | Bits | Physical medium |

> **L4 Load Balancer** → routes by IP:Port.
> **L7 Load Balancer** → routes by HTTP host header, URL path (e.g., Nginx, AWS ALB).

---

## 9. Protocols by Layer

| Layer | Protocols |
|-------|----------|
| 7 | HTTP, HTTPS, DNS, FTP, SMTP, IMAP, SSH, DHCP, SNMP |
| 6 | TLS/SSL, JPEG, MPEG, ASCII encoding |
| 5 | NetBIOS, RPC, PPTP (session establishment) |
| 4 | TCP, UDP |
| 3 | IP (IPv4/IPv6), ICMP (`ping`), OSPF, BGP |
| 2 | Ethernet, ARP, Wi-Fi (802.11), PPP |
| 1 | Ethernet cable, Fiber optic, Wi-Fi radio, Bluetooth |

---

## 10. Why This Matters for Kubernetes/Docker

Every K8s networking concept maps directly to OSI layers: [web:91]

| K8s/Docker Concept | OSI Layer | Why |
|-------------------|-----------|-----|
| Pod IP, Node IP | L3 | IP routing between pods/nodes |
| Service (ClusterIP) | L3–L4 | kube-proxy routes by IP:Port |
| Ingress / Nginx | L7 | Routes by HTTP host/path |
| Network Policy | L3–L4 | Firewall rules on IP + Port |
| CNI plugin (Flannel, Calico) | L2–L3 | Virtual network overlay |
| Docker bridge network | L2 | Virtual switch between containers |
| NodePort / LoadBalancer | L4 | TCP port exposure |
| iptables rules | L3–L4 | Packet filtering + NAT |

> When K8s docs say "L3 routing" or "L7 load balancing" — now you know exactly what that means.

---

## 11. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| DNS runs at L3 | DNS runs at L7 (Application layer) |
| MAC address travels end-to-end | MAC is hop-to-hop; rebuilt at every router |
| IP changes at every router | IP stays same end-to-end (except NAT) |
| TCP handshake happens before DNS | DNS happens first, THEN TCP handshake |
| TLS = L4 | TLS operates at L5/L6 (Session + Presentation) |
| Router only does L3 | Router does L2 (strips/rebuilds frame) + L3 (routes) + NAT |
| OSI = TCP/IP | OSI is the reference model; TCP/IP is the practical implementation |

---

## 12. Interview Questions Checklist ✅

- [ ] What is the OSI model and why was it created?
- [ ] Name all 7 layers and the PDU at each layer
- [ ] What is encapsulation? What is decapsulation?
- [ ] Walk through the complete journey of typing `google.com` (end-to-end)
- [ ] What is DNS? What is the DNS resolution order?
- [ ] What is the TCP 3-way handshake? Why 3 steps?
- [ ] What is the TLS handshake? At which layer does it happen?
- [ ] What does a router do at which layers?
- [ ] What is NAT? Why is it needed? Where does it happen?
- [ ] Does MAC address change at every hop? Does IP change?
- [ ] TCP vs UDP — when to use each?
- [ ] OSI vs TCP/IP — map the layers
- [ ] L4 vs L7 load balancer — difference?
- [ ] What layer does a Switch / Router / Firewall operate at?
- [ ] Why does VPN sometimes break DNS? How to fix it?
