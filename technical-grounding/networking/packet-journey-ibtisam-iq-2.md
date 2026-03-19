# Packet Journey — ibtisam-iq.com (Real Infrastructure)

> This document traces a real HTTP request through your actual setup:
> **MacBook → Home Router → Internet → Cloudflare → GitHub Pages**
> Read `osi-model.md` first for theory. This is the applied version.

---

## 1. Your Infrastructure Stack

```
ibtisam-iq.com
      ↓ registered on
  GoDaddy  (domain registrar only — no DNS control here)
      ↓ nameservers delegated to
  Cloudflare  (authoritative DNS + reverse proxy + CDN + TLS termination)
      ↓ DNS record points to
  GitHub Pages  (actual static file server — the true origin)
```

**Cloudflare proxy modes:**

| Mode | Icon | IP DNS returns | Where request actually goes |
|------|------|----------------|----------------------------|
| **Proxied** ✅ | 🟠 Orange cloud | Cloudflare edge IP | Browser → Cloudflare → GitHub Pages |
| **DNS Only** | ☁️ Grey cloud | GitHub Pages IP | Browser → GitHub Pages directly |

> All examples below use **Proxied mode** — the recommended and real-world path.
> In Proxied mode, your GitHub Pages IP is hidden from the entire internet.

---

## 2. Phase 1 — DNS Resolution

You type `https://ibtisam-iq.com` → press Enter.
Browser needs an IP. This is a **pre-connection step** — no data sent yet.

```
Step 1 — Browser DNS cache
         Chrome stores recent lookups (~60s TTL)
         Hit? → use IP directly, skip all below.

Step 2 — OS DNS cache
         macOS mDNSResponder holds recent lookups.
         Hit? → use IP directly, skip below.

Step 3 — /etc/hosts file
         Static override table on your MacBook.
         If you added:  127.0.0.1  ibtisam-iq.com
         → browser goes to localhost instead. No network query.

Step 4 — Configured DNS Resolver
         Your Wi-Fi DNS (ISP's or custom: 1.1.1.1 / 8.8.8.8)
         This resolver now queries recursively on your behalf:

Step 5 — Recursive DNS Resolution
         Resolver → Root Nameserver
                    "Who is responsible for .com domains?"
         Root NS  → .com TLD Nameserver
                    "Who is responsible for ibtisam-iq.com?"
         TLD NS   → Cloudflare Nameserver (ns1.cloudflare.com etc.)
                    ← because you set Cloudflare's NS in GoDaddy dashboard
         Cloudflare NS → returns Cloudflare edge IP (e.g. 104.21.x.x)
                         NOT GitHub Pages IP — proxy is ON 🟠
```

**Result:** `ibtisam-iq.com` → `104.21.x.x` (Cloudflare edge, nearest to you)

> Nobody on the internet knows GitHub Pages is behind this.
> The entire world only sees Cloudflare's IP. ✅

---

### Why VPN Broke Your DNS (Real Incident)

You installed and tested multiple VPNs, then closed them all.
Browser showed "site can't be reached" despite Wi-Fi being fully connected.

**What happened:**
```
VPN ON  → hijacked Step 4 (DNS resolver) → pointed to VPN's internal DNS server
VPN OFF → left the broken DNS config behind → resolver points to dead VPN server
Browser → tries to resolve ibtisam-iq.com → DNS timeout → no response → error
```

Wi-Fi was fine. DNS was broken. Two different things.

**Fix on macOS:**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Or: System Settings → Wi-Fi → Details → DNS → remove VPN entry → add 1.1.1.1 / 8.8.8.8

---

## 3. Phase 2 — TCP 3-Way Handshake (Layer 4)

IP resolved. Now your MacBook opens a TCP connection **to Cloudflare** on port 443.

```
Your MacBook (Port: 52341)         Cloudflare Edge (Port: 443)
        |                                      |
        |---- SYN (seq=x) ------------------>|   "I want to connect."
        |                                      |
        |<--- SYN-ACK (seq=y, ack=x+1) ------|   "OK. I'm ready."
        |                                      |
        |---- ACK (ack=y+1) ---------------->|   "Connected."
        |                                      |
               TCP CONNECTION OPEN
```

Both sides now agree on sequence numbers for reliable, ordered data delivery.

---

## 4. Phase 3 — TLS Handshake (Layer 5/6)

HTTPS requires an encrypted tunnel before any HTTP data travels.
This is between your browser and **Cloudflare** (not GitHub Pages — Cloudflare terminates TLS).

```
Your MacBook                        Cloudflare Edge
        |                                      |
        |---- ClientHello ------------------>|   TLS 1.3, cipher suites list
        |                                      |
        |<--- ServerHello + Certificate ------|   "Use AES-256. Here's my cert
        |                                      |    (issued for ibtisam-iq.com by Cloudflare)"
        | [Browser verifies cert with CA]      |
        |                                      |
        |---- Key Exchange ----------------->|   Shared session key derived
        |                                      |
        |---- Finished -------------------> |
        |<--- Finished ----------------------|
        |                                      |
               ENCRYPTED TUNNEL ESTABLISHED
```

> The SSL cert your browser validates is **Cloudflare's** — not GitHub's.
> Cloudflare then creates a separate encrypted connection to GitHub Pages behind the scenes.

---

## 5. Phase 4 — HTTP Request (Layer 7)

Inside the encrypted tunnel, browser sends:

```
GET / HTTP/1.1
Host: ibtisam-iq.com
User-Agent: Chrome/...
Accept: text/html
Accept-Encoding: gzip, deflate, br
```

---

## 6. Phase 5 — Encapsulation (Down Your MacBook's Stack)

| Layer | What Happens | What Gets Added |
|-------|-------------|-----------------|
| **L7 Application** | HTTP request created | — |
| **L6 Presentation** | Encrypted by TLS session key | — |
| **L5 Session** | Session tracked (keep-alive, session ID) | — |
| **L4 Transport** | Split into TCP **Segments** | Src Port: 52341, Dst Port: 443, Seq#, ACK# |
| **L3 Network** | IP **Packet** created | Src IP: 192.168.1.x, Dst IP: 104.21.x.x (Cloudflare) |
| **L2 Data Link** | ARP finds router's MAC → **Frame** built | Src MAC: your NIC, Dst MAC: your home router's MAC |
| **L1 Physical** | Frame → bits → Wi-Fi radio waves or Ethernet signal | — |

> At L2, destination MAC = your **home router** — not Cloudflare's MAC.
> MAC is always hop-to-hop. IP is always end-to-end.

---

## 7. Phase 6 — At Your Home Router

```
Incoming Frame (from MacBook):
  [ETH: Src=YourNIC_MAC, Dst=RouterLAN_MAC]
  [IP:  Src=192.168.1.x,  Dst=104.21.x.x]
  [TCP Segment + Encrypted HTTP Data]

Step 1 — L2: Router sees its own MAC → accepts frame → strips ETH header
Step 2 — L3: Reads IP → Dst=104.21.x.x → needs to go out to internet
Step 3 — NAT: Rewrites Src IP:
              192.168.1.x:52341 → 39.57.x.x:52341  (your public IP)
              Stores mapping in NAT table for return traffic
Step 4 — L2: Builds NEW Ethernet frame for next hop (ISP gateway):
              Src MAC = Router WAN MAC
              Dst MAC = ISP Gateway MAC
Step 5 — L1: Sends bits out to ISP

Outgoing Frame:
  [ETH: Src=RouterWAN_MAC, Dst=ISP_GW_MAC]
  [IP:  Src=39.57.x.x,     Dst=104.21.x.x]
  [TCP Segment + Encrypted HTTP Data]
```

> IP modified by NAT. MAC completely replaced. TCP + HTTP data untouched.

---

## 8. Phase 7 — Internet (Multiple Router Hops)

```
Router 1 → Router 2 → ... → Router N → Cloudflare datacenter
```

At each router:
```
Strip L2 frame → Read L3 IP → Check routing table →
Build new L2 frame for next hop → Forward
```

L2 (MAC) is rebuilt at every hop.
L3 (IP) stays the same throughout (Src: your public IP, Dst: Cloudflare IP).

```bash
traceroute ibtisam-iq.com    # see every hop live
```

---

## 9. Phase 8 — At Cloudflare Edge (Most Complex Phase)

Cloudflare is **not** the final destination — it is a reverse proxy in front of GitHub Pages.

```
Request arrives at nearest Cloudflare datacenter (anycast routing)

Step 1 — TLS Termination (L6)
         Cloudflare decrypts the request using your session key
         Now reads plaintext: GET / HTTP/1.1 Host: ibtisam-iq.com

Step 2 — Cache Check (L7)
         Has this page been cached at the edge?
         ✅ Cache HIT  → serve HTML/CSS/JS directly from Cloudflare
                         GitHub Pages is never contacted. Ultra fast.
         ❌ Cache MISS → must fetch from origin (GitHub Pages)

Step 3 — Forward to GitHub Pages (on cache miss)
         New TCP 3-way handshake: Cloudflare → 185.199.108.153 (GitHub Pages)
         New TLS handshake: Cloudflare ↔ GitHub Pages
         HTTP request sent: GET / HTTP/1.1 Host: ibtisam-iq.com

Step 4 — GitHub Pages Responds
         Finds your repo linked to ibtisam-iq.com
         Serves index.html + CSS + JS + assets

Step 5 — Cloudflare Receives Response
         Optionally caches it for future requests
         Re-encrypts it using YOUR browser's TLS session key
         Sends response back toward your MacBook
```

**Two separate TLS tunnels exist simultaneously:**

```
Your Browser ←──── TLS ────→ Cloudflare       (Cloudflare's SSL cert)
                   Cloudflare ←── TLS ──→ GitHub Pages  (GitHub's SSL cert)
```

---

## 10. Phase 9 — Return Path

```
GitHub Pages → Cloudflare → Internet →
Your Router (reverse NAT: 39.57.x.x → 192.168.1.x) →
Your MacBook
```

---

## 11. Phase 10 — Decapsulation (Up Your MacBook's Stack)

| Layer | What Happens |
|-------|-------------|
| **L1 Physical** | Bits received → converted to Frame |
| **L2 Data Link** | Dst MAC verified (yours ✅) → ETH header stripped → Packet |
| **L3 Network** | Dst IP verified (your IP ✅) → IP header stripped → Segment |
| **L4 Transport** | TCP reassembles all segments in correct order → ACKs sent → HTTP data extracted |
| **L5 Session** | Session identified, keep-alive maintained |
| **L6 Presentation** | Data decrypted using TLS session key |
| **L7 Application** | HTTP response parsed → Chrome renders ibtisam-iq.com ✅ |

---

## 12. Complete Timeline

```
You type: https://ibtisam-iq.com → Enter
                ↓
[DNS]
Browser cache → OS cache → /etc/hosts → DNS Resolver
→ Root NS → .com TLD NS → Cloudflare NS
→ Returns: 104.21.x.x (Cloudflare edge IP, proxy ON)
                ↓
[L4] TCP 3-Way Handshake
MacBook ←→ Cloudflare edge :443
SYN → SYN-ACK → ACK
                ↓
[L5/L6] TLS Handshake
ClientHello → ServerHello+Cert → KeyExchange → Finished
Encrypted tunnel: MacBook ↔ Cloudflare
                ↓
[L7] HTTP GET / built inside encrypted tunnel
[L6] Encrypted by TLS
[L5] Session tracked
[L4] TCP Segment (src:52341, dst:443, seq#)
[L3] IP Packet (src:192.168.1.x, dst:104.21.x.x)
[L2] ARP → router MAC → Ethernet Frame
[L1] Bits → Wi-Fi radio
                ↓
[Home Router]
NAT: 192.168.1.x:52341 → 39.57.x.x:52341
L2 MAC header rebuilt for ISP gateway
                ↓
[Internet]
Multiple router hops — L3 routes, L2 rebuilt at every hop
(traceroute ibtisam-iq.com)
                ↓
[Cloudflare Edge]
TLS terminated → HTTP request read
Cache HIT?  → serve from edge ✅ (GitHub never contacted)
Cache MISS? → new TCP+TLS → GitHub Pages 185.199.108.153
              GitHub serves your static site
              Cloudflare caches + re-encrypts → sends back
                ↓
[Return]
Internet → Router (reverse NAT) → MacBook
                ↓
[MacBook Decapsulation]
L1 → L2 → L3 → L4 → L5 → L6 → L7
Chrome renders ibtisam-iq.com ✅
```

---

## 13. Key Facts About Your Setup

| Question | Answer |
|----------|--------|
| Who registered the domain? | GoDaddy |
| Who controls DNS? | Cloudflare (authoritative nameserver) |
| Who terminates TLS? | Cloudflare (not GitHub) |
| Who hosts the files? | GitHub Pages |
| What IP does the world see? | Cloudflare edge IP (your GitHub IP is hidden) |
| How many TLS tunnels per request? | 2 (Browser↔Cloudflare + Cloudflare↔GitHub) |
| Where is caching done? | Cloudflare edge (CDN) |
| What happens on cache hit? | GitHub Pages is never contacted |
| What type of device is Cloudflare here? | L7 reverse proxy + CDN |
