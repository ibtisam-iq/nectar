# IP Addressing

## 1. IP Address Basics

**Definition:** A logical identifier assigned to a device for communication over a network.

| Property | IPv4 | IPv6 |
|----------|------|------|
| Bits | 32 | 128 |
| Format | Decimal (4 octets) | Hexadecimal |
| Example | `192.168.1.10` | `2001:0db8:85a3::8a2e:0370:7334` |
| Subnetting | ✅ Yes | ✅ Yes (advanced) |
| Used today | ✅ Widely | ✅ Growing |

**IPv4 Structure:**
```
8 bits | 8 bits | 8 bits | 8 bits  →  4 octets
Min per octet = 0,  Max per octet = 255  (2⁸ = 256 values)
```

---

## 2. Binary Conversion (Why It Matters)

Computers work in binary; IP math always reduces to binary.

**Powers of 2 (memorize this row):**
```
128  64  32  16  8  4  2  1
```

**Example — Convert 192:**
```
192 ≥ 128 → 1,  remainder 64
64  ≥ 64  → 1,  remainder 0
Rest       → 0

Result: 11000000
```

---

## 3. IP Classes (Legacy / Classful — Conceptual Only ⚠️)

> Classes are obsolete in production. Learn for interviews, think in CIDR for real work.

| Class | First Octet Range | Leading Bits | Default Prefix | Usage |
|-------|-------------------|--------------|----------------|-------|
| A | 0–127 | `0` | /8 | Large networks |
| B | 128–191 | `10` | /16 | Medium networks |
| C | 192–223 | `110` | /24 | Small networks |
| D | 224–239 | `1110` | — | Multicast |
| E | 240–255 | `1111` | — | Reserved/Experimental |

**Special Ranges (Never assign to hosts):**
- `0.x.x.x` → Reserved (network zero)
- `127.x.x.x` → Loopback (`127.0.0.1` = localhost)

> **Rule:** Class is determined by the **first octet only**.

---

## 4. Network vs Host (Critical Concept)

Every IP = **Network part** + **Host part**

| Class | Structure | Network Bits | Host Bits |
|-------|-----------|-------------|-----------|
| A | N . H . H . H | 8 | 24 |
| B | N . N . H . H | 16 | 16 |
| C | N . N . N . H | 24 | 8 |

- **Network bits** → identify *which group/network*
- **Host bits** → identify *which device inside that group*

---

## 5. Network ID & Broadcast Address

| Type | Rule | Purpose |
|------|------|---------|
| **Network ID** (First IP) | Set all host bits = `0` | Represents the network, cannot assign to host |
| **Broadcast** (Last IP) | Set all host bits = `255` | Sends packet to ALL devices in network |

**Examples:**

| Given IP | Class | Network ID | Broadcast |
|----------|-------|-----------|-----------|
| `10.20.30.40` | A | `10.0.0.0` | `10.255.255.255` |
| `172.16.5.4` | B | `172.16.0.0` | `172.16.255.255` |
| `192.168.1.50` | C | `192.168.1.0` | `192.168.1.255` |

---

## 6. Usable IPs Formula

```
Total IPs  = 2^(host bits)
Usable IPs = Total - 2        ← subtract Network ID + Broadcast
```

| Class | Host Bits | Total | Usable |
|-------|-----------|-------|--------|
| A | 24 | 16,777,216 | 16,777,214 |
| B | 16 | 65,536 | 65,534 |
| C | 8 | 256 | 254 |

---

## 7. CIDR — Classless Inter-Domain Routing (Modern System ✅)

**Format:** `192.168.1.0/24`
`/24` = 24 bits for network, remaining `(32-24) = 8` bits for host.

```
Total IPs = 2^(32 − CIDR prefix)
```

| CIDR | Host Bits | Total IPs | Usable IPs |
|------|-----------|-----------|------------|
| /8   | 24 | 16,777,216 | 16,777,214 |
| /16  | 16 | 65,536 | 65,534 |
| /24  | 8 | 256 | 254 |
| /25  | 7 | 128 | 126 |
| /26  | 6 | 64 | 62 |
| /28  | 4 | 16 | 14 |
| /30  | 2 | 4 | 2 |
| /32  | 0 | 1 | 1 (single host) |

> **Rule:** Bigger prefix `/` = smaller network. Smaller prefix `/` = bigger network.

### Subnet Mask

A subnet mask is a 32-bit number that separates network bits (all `1`s) from host bits (all `0`s).

| CIDR | Subnet Mask | Binary |
|------|-------------|--------|
| /8 | 255.0.0.0 | `11111111.00000000.00000000.00000000` |
| /16 | 255.255.0.0 | `11111111.11111111.00000000.00000000` |
| /24 | 255.255.255.0 | `11111111.11111111.11111111.00000000` |
| /26 | 255.255.255.192 | `11111111.11111111.11111111.11000000` |
| /28 | 255.255.255.240 | `11111111.11111111.11111111.11110000` |

---

## 8. Subnetting

**Definition:** Dividing one large network into multiple smaller networks by borrowing host bits and giving them to the network.

```
Class A default:  N . H . H . H   (/8)
After /16:        N . N . H . H   (/16)  ← borrowed 8 bits from host
```

| Effect | Result |
|--------|--------|
| Borrow host bits → network | More networks, fewer hosts per network |
| More subnets | Better traffic control, security isolation |

**Example:** `10.0.3.4/16`
- Class A default = /8
- Given /16 → borrowed 8 bits → smaller network carved out of Class A space

---

## 9. Communication Rule

**Step-by-step to check if two IPs can communicate:**

1. Find class (first octet)
2. Apply network structure → find Network ID
3. Compare Network IDs

| IP | Network ID | Same Network? |
|----|-----------|--------------|
| `192.168.1.10` | `192.168.1.0` | ✅ |
| `192.168.1.15` | `192.168.1.0` | ✅ |
| `192.168.1.12` | `192.168.1.0` | ✅ |
| `192.168.2.11` | `192.168.2.0` | ❌ Different |

> **Same Network ID → Switch. Different Network ID → Router.**

---

## 10. Switch vs Router

| | Switch | Router |
|--|--------|--------|
| Works on | MAC address (Layer 2) | IP address (Layer 3) |
| Connects | Devices within same network (LAN) | Different networks |
| When needed | Same Network ID | Different Network IDs |

---

## 11. Communication Modes

| Mode | Traffic Pattern | Example |
|------|----------------|---------|
| **Unicast** | One sender → One receiver | Opening google.com |
| **Multicast** | One sender → Specific group | Zoom call, live stream |
| **Broadcast** | One sender → All devices in network | ARP request |

> ⚠️ **Broadcast is local network only** — it does NOT travel across routers to the internet.

---

## 12. Private vs Public IP (RFC 1918)

**Private IP Ranges (cannot route on internet):**

| Class | CIDR | Range |
|-------|------|-------|
| A | `10.0.0.0/8` | 10.0.0.0 – 10.255.255.255 |
| B | `172.16.0.0/12` | 172.16.0.0 – 172.31.255.255 |
| C | `192.168.0.0/16` | 192.168.0.0 – 192.168.255.255 |

> These ranges are defined by **RFC 1918** (IANA standard).

**Public IP:** Any IP outside the above ranges — globally unique, routable on internet.

### NAT (Network Address Translation)

```
Private IP → NAT (Router/Gateway) → Public IP → Internet
```

Without NAT, private IPs have no internet access.

### IP Assignment Chain

```
IANA → RIR (e.g., APNIC for Asia-Pacific) → ISP → You
```

> You don't buy IPs from IANA directly. Your ISP assigns your public IP.

---

## 13. Network Types (LAN / MAN / WAN)

| Type | Scope | How Connected | Internet Required? |
|------|-------|--------------|-------------------|
| **LAN** (Local Area Network) | Single building / floor | Switch | ❌ No |
| **MAN** (Metropolitan Area Network) | City-wide (multiple LANs) | Fiber / leased lines | Optional |
| **WAN** (Wide Area Network) | Global (multiple networks) | Router + Internet | ✅ Yes |

> **Key rule:** Network type is defined by **how networks are connected**, not just physical distance.
> LAN can exist **with or without** internet.
> `LAN = private IP` and `WAN = public IP` is an oversimplification — not strictly correct.

---

## 14. Complete Mental Flow (Memorize This) ⭐

Given any IP, think in this order:

```
1. Identify class       → look at first octet
2. Network structure    → how many octets = network
3. Network ID           → zero out host bits
4. Broadcast            → max out host bits (255)
5. Total/Usable IPs     → 2^(host bits), minus 2
6. CIDR check           → is prefix = default? If not → subnetting
7. Compare two IPs      → same Network ID? → switch / router decision
```

---

## 15. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|----------|
| IPv6 has no subnetting | IPv6 supports subnetting (advanced) |
| Classes are used in modern networking | Classes are obsolete — CIDR is used |
| All IPs in a range are usable | Network ID + Broadcast = reserved (−2) |
| LAN always needs internet | LAN works without internet |
| `LAN = private IP, WAN = public IP` | Not strictly true; based on network boundaries |
| You buy public IP from IANA | IANA → RIR → ISP → You |
| Broadcast reaches the whole internet | Broadcast is limited to local network only |

---

## 16. Interview Questions Checklist ✅

- [ ] What is an IP address? IPv4 vs IPv6?
- [ ] How is IPv4 structured? Why max 255 per octet?
- [ ] What are IP classes and their ranges? (leading bits reason)
- [ ] What are network bits vs host bits?
- [ ] How do you find Network ID? Broadcast address?
- [ ] Formula: Total IPs and Usable IPs
- [ ] What is CIDR? How is it different from classful?
- [ ] What is a subnet mask? Give examples for /24, /26, /28
- [ ] What is subnetting? What does "borrowing bits" mean?
- [ ] How do you check if two IPs can communicate?
- [ ] Switch vs Router — when is each needed?
- [ ] Unicast vs Multicast vs Broadcast
- [ ] Private IP ranges (RFC 1918) — all three
- [ ] What is NAT and why is it needed?
- [ ] LAN vs MAN vs WAN
- [ ] IANA → RIR → ISP → You (IP assignment chain)
