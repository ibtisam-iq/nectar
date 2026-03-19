# OSI Model — Reference Guide

> This is not a memorization document. It is a **systems thinking** document.
> After reading this, every Kubernetes/Docker networking doc will make sense.

---

## 1. Why OSI Exists

Before OSI, every vendor built proprietary systems — IBM, HP, Cisco — none could talk to each other. **ISO** created the **OSI (Open Systems Interconnection)** model in 1984 as a **universal blueprint** for network communication.

> It defines: what job gets done, at which layer, by which protocol.

**Benefits:** [web:114]
- Simplifies network design and troubleshooting
- Changes at one layer do not affect other layers (modularity)
- Enables different technologies/vendors to interoperate

---

## 2. The 7 Layers

| Layer | Name | PDU Name | Key Job |
|-------|------|----------|---------|
| 7 | Application | Data | User-facing protocols (HTTP, DNS, SMTP) |
| 6 | Presentation | Data | Encryption, compression, format conversion |
| 5 | Session | Data | Session open/close/track |
| 4 | Transport | **Segment** (TCP) / **Datagram** (UDP) | Reliable delivery, ports, flow control |
| 3 | Network | **Packet** | IP addressing, routing |
| 2 | Data Link | **Frame** | MAC addressing, local delivery |
| 1 | Physical | **Bits** | Electrical/light/radio signal transmission |

> **PDU = Protocol Data Unit** — what the data unit is called at each layer.

---

## 3. Encapsulation vs Decapsulation

**Sender (top → bottom):** Each layer adds its own header — wrapping data further.

```
[HTTP Data]
[TCP Header][HTTP Data]                                              ← Segment
[IP Header][TCP Header][HTTP Data]                                   ← Packet
[ETH Header][IP Header][TCP Header][HTTP Data][ETH Trailer]          ← Frame
→ Bits → transmitted over physical medium
```

**Receiver (bottom → top):** Each layer strips its own header — passing data up.

```
Bits → Frame → Packet → Segment → Data (reaches application)
```

---

## 4. Protocols by Layer

| Layer | Protocols |
|-------|----------|
| 7 Application | HTTP, HTTPS, DNS, FTP, SMTP, IMAP, SSH, DHCP, SNMP, NTP |
| 6 Presentation | TLS/SSL, JPEG, MPEG, ASCII, gzip |
| 5 Session | NetBIOS, RPC, NFS, PPTP |
| 4 Transport | TCP, UDP, GRE |
| 3 Network | IP (IPv4/IPv6), ICMP, IGMP, OSPF, BGP, RIP |
| 2 Data Link | Ethernet, ARP, Wi-Fi (802.11), PPP, STP |
| 1 Physical | Ethernet cable, Fiber optic, Wi-Fi radio, Bluetooth, ADSL |

---

## 5. Devices by Layer

| Device | OSI Layer | Works on | Job |
|--------|-----------|----------|-----|
| **Hub** | Layer 1 | Bits | Broadcasts to all ports — dumb, legacy |
| **Switch** | Layer 2 | MAC address | Forwards frames to correct port only |
| **Router** | Layer 3 | IP address | Routes packets between networks |
| **Firewall** | L3–L4 (basic) / L7 (NGFW) | IP+Port / Payload | Filters by rules |
| **L4 Load Balancer** | Layer 4 | IP:Port | Distributes TCP connections |
| **L7 Load Balancer** | Layer 7 | HTTP headers/URL | Routes by Host, path, cookies |
| **NIC** | Layer 1–2 | Bits + MAC | Sends/receives signals, holds MAC address |

---

## 6. TCP vs UDP

| | TCP | UDP |
|--|-----|-----|
| Connection | ✅ Connection-oriented (3-way handshake first) | ❌ Connectionless |
| Reliability | ✅ Retransmits lost segments | ❌ Fire and forget |
| Order | ✅ Sequence numbers ensure correct order | ❌ No ordering guarantee |
| Speed | Slower (overhead) | ✅ Faster |
| Use cases | HTTP/S, SSH, SMTP, FTP | DNS queries, Video streaming, Gaming, VoIP |

> **DNS uses UDP** by default (small, fast queries).
> Switches to TCP when response > 512 bytes (e.g. zone transfers).

---

## 7. TCP 3-Way Handshake ⭐

Must happen **before** any data is exchanged over TCP.

```
Client                        Server
  |                               |
  |---- SYN (seq=x) ------------>|   "I want to connect. My seq# is x."
  |                               |
  |<--- SYN-ACK (seq=y, ack=x+1)-|   "OK. My seq# is y. I got your x."
  |                               |
  |---- ACK (ack=y+1) ---------->|   "Got your y. We are connected."
  |                               |
        CONNECTION ESTABLISHED
```

**Why 3 steps?** Both sides independently confirm they can send AND receive.
Sequence numbers are agreed upon — used to reorder segments and detect missing ones.

---

## 8. TLS Handshake (Layer 5/6) ⭐

Required for HTTPS — establishes an encrypted tunnel **before** HTTP data is sent.

```
Client                              Server
  |------ ClientHello ------------>|  "I support TLS 1.3. Here are cipher suites."
  |<----- ServerHello + Cert ------|  "Use AES-256-GCM. Here's my SSL certificate."
  | [Client verifies cert with CA]  |
  |------ Key Exchange ----------->|  "Here's info to derive shared session key."
  | [Both derive same session key]  |
  |------ Finished --------------> |
  |<----- Finished ---------------|
        ENCRYPTED TUNNEL ESTABLISHED
```

---

## 9. DNS Resolution Order

When you type a domain, DNS resolves it in this exact order:

```
1. Browser DNS cache       (Chrome/Firefox stores recent lookups)
2. OS DNS cache            (mDNSResponder on macOS / nscd on Linux)
3. /etc/hosts file         (static override — checked before any network query)
4. Configured DNS Resolver (ISP DNS or custom: 8.8.8.8 / 1.1.1.1)
5. Recursive Resolution:
      Resolver → Root Nameserver    ("Who handles .com?")
      Root NS  → .com TLD NS        ("Who handles example.com?")
      TLD NS   → Authoritative NS   (holds actual A record: IP address)
```

---

## 10. What a Router Actually Does

A router operates at **L2 and L3** — not just L3:

```
1. Strip incoming L2 Ethernet frame (reads its own MAC — accepts it)
2. Read L3 IP header → check routing table → find next hop
3. NAT (if applicable): rewrite source IP (private → public)
4. Build NEW L2 frame for next hop (completely new MAC addresses)
5. Forward out correct interface
```

> **IP is end-to-end** — stays the same across the full path (except at NAT).
> **MAC is hop-to-hop** — completely rebuilt at every single router.

---

## 11. OSI vs TCP/IP Model

| OSI Layer | OSI Name | TCP/IP Layer | TCP/IP Name |
|-----------|---------|-------------|------------|
| 7 | Application | 4 | Application |
| 6 | Presentation | 4 | Application |
| 5 | Session | 4 | Application |
| 4 | Transport | 3 | Transport |
| 3 | Network | 2 | Internet |
| 2 | Data Link | 1 | Network Access |
| 1 | Physical | 1 | Network Access |

> OSI = theoretical reference model.
> TCP/IP = practical implementation used on the real internet.
> Engineers always use **OSI layer numbering** (L1–L7).

---

## 12. Common Network Problems by Layer ⭐

| Layer | Typical Problems |
|-------|----------------|
| L1 Physical | Damaged cables, loose connectors, signal interference |
| L2 Data Link | MAC conflicts, frame errors, switch misconfig |
| L3 Network | Wrong IP, routing loops, packet loss, ICMP blocked |
| L4 Transport | Port conflicts, connection timeouts, firewall blocking |
| L5 Session | Session hijacking, unexpected session drops |
| L6 Presentation | TLS cert errors, encoding mismatches |
| L7 Application | DNS failure, HTTP 4xx/5xx, protocol mismatch |

---

## 13. OSI in Kubernetes/Docker

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

---

## 14. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| DNS runs at L3 | DNS is an L7 (Application layer) protocol |
| MAC address travels end-to-end | MAC is hop-to-hop — rebuilt at every router |
| IP changes at every router | IP stays same end-to-end (except at NAT) |
| TCP handshake before DNS | DNS resolves IP first, THEN TCP handshake |
| TLS = Layer 4 | TLS operates at L5/L6 (Session + Presentation) |
| Router only does L3 | Router strips/rebuilds L2 + L3 routing + NAT |
| OSI = TCP/IP | OSI is the reference model; TCP/IP is the implementation |

---

## 15. Interview Questions Checklist ✅

- [ ] What is the OSI model? Why was it created?
- [ ] Name all 7 layers with PDU at each layer
- [ ] What is encapsulation? What is decapsulation?
- [ ] What is a PDU? What is it called at each layer?
- [ ] TCP vs UDP — differences and use cases
- [ ] Explain the TCP 3-way handshake
- [ ] Explain the TLS handshake — which OSI layer?
- [ ] What is DNS? Full resolution order (5 steps)?
- [ ] What does a router do at which layers?
- [ ] What is NAT? Why is it needed?
- [ ] Does MAC change at every hop? Does IP?
- [ ] OSI vs TCP/IP — map the layers
- [ ] L4 vs L7 load balancer — difference?
- [ ] Switch / Router / Firewall — which layer?
- [ ] What layer does `ping` work at? (`traceroute`?)
- [ ] What common problem occurs at each layer?
- [ ] What is the OSI layer for K8s Ingress? Network Policy?
