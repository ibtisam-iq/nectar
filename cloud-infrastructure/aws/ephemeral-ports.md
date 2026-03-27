### Ephemeral Ports — Complete Deep Dive ⭐

#### What Are Ephemeral Ports?

When a **client initiates** any TCP/UDP connection, the OS automatically assigns
a temporary high-numbered **source port** for that session. The server's response
travels back to this port — not back to the server's own listening port.

```
Client OS assigns:  source port = 54231   (ephemeral — random, temporary)
Client sends:       54231 → server:80     (HTTP request)
Server responds:    server:80 → 54231     (HTTP response)
```

> The response targets the **client's ephemeral port**, not port 80.
> Port 80 is only the destination of the *request* — not the return.

---

#### Ephemeral Port Ranges by OS ⭐ [web:228][web:229]

Different operating systems use different ranges:

| OS / Service | Ephemeral Port Range |
|-------------|---------------------|
| **Amazon Linux** (EC2 default) | 32768 – 60999 |
| **Linux** (general kernel) | 32768 – 60999 |
| **Windows Server 2008+** | 49152 – 65535 |
| **Windows XP / Server 2003** | 1025 – 5000 (legacy) |
| **macOS** | 49152 – 65535 |
| **AWS NAT Gateway** | 1024 – 65535 (widest) |
| **AWS ELB / ALB** | 1024 – 65535 |

**Safe AWS NACL rule (covers all clients):**
```
Allow outbound TCP: 1024 – 65535
```

> AWS recommends **1024–65535** in NACL outbound rules to safely cover all
> OS types, NAT Gateways, and Load Balancers. [web:231]
>
> Using a narrower range (e.g., 49152–65535 only) will break connections from
> Linux clients whose ephemeral ports fall in 32768–49151. [web:230]

---

#### Stateful vs Stateless — Why Only NACL Needs This

| | Security Group (Stateful) | NACL (Stateless) |
|--|--------------------------|-----------------|
| Tracks connection? | ✅ Yes — remembers the session | ❌ No — each packet evaluated alone |
| Return traffic? | Auto-allowed | Must add explicit outbound rule |
| Need ephemeral port rule? | ❌ No | ✅ Yes — mandatory |

---

#### Correct NACL Rule Set for Common Scenarios

**Web Server (HTTP + HTTPS):**

| Direction | Rule # | Action | Protocol | Port | Source/Dest |
|-----------|--------|--------|---------|------|------------|
| Inbound | 100 | ALLOW | TCP | 80 | 0.0.0.0/0 |
| Inbound | 110 | ALLOW | TCP | 443 | 0.0.0.0/0 |
| Outbound | 100 | ALLOW | TCP | **1024–65535** | 0.0.0.0/0 |

**SSH Access:**

| Direction | Rule # | Action | Protocol | Port | Source/Dest |
|-----------|--------|--------|---------|------|------------|
| Inbound | 200 | ALLOW | TCP | 22 | your-IP/32 |
| Outbound | 200 | ALLOW | TCP | **1024–65535** | your-IP/32 |

**EC2 Initiating Outbound (e.g., calling an external API):**

| Direction | Rule # | Action | Protocol | Port | Source/Dest |
|-----------|--------|--------|---------|------|------------|
| Outbound | 300 | ALLOW | TCP | 443 | 0.0.0.0/0 |
| Inbound | 300 | ALLOW | TCP | **1024–65535** | 0.0.0.0/0 |

> When **EC2 is the client**, the ephemeral rule flips:
> outbound = specific port (443), inbound = ephemeral range (response comes back in).

---

#### The Two-Direction Mental Model

```
                  CLIENT side                SERVER side
                  ──────────                ──────────
Request →         src: ephemeral            dst: 80/443/22/etc
                  NACL outbound: allow 443  NACL inbound: allow 443

Response ←        dst: ephemeral ⚠️         src: 80/443/22/etc
                  NACL inbound: allow       NACL outbound: allow
                  1024-65535 ⚠️             1024-65535 ⚠️
```

> Every NACL direction pair needs:
> - **Specific port** for the request
> - **1024–65535** for the ephemeral response

---

#### Common Debugging Scenario

```
Symptom: HTTPS works from browser to server — but server can't initiate
         outbound calls to an external API.

Reason:  NACL has outbound 443 allowed (request goes out)
         but NACL inbound has no rule for 1024-65535
         → API response is blocked at the subnet boundary

Fix:     Add NACL inbound rule: Allow TCP 1024-65535 from 0.0.0.0/0
```
