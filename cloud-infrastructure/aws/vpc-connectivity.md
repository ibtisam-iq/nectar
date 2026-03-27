# AWS Connectivity — VPN, Direct Connect & VPC Peering

## 1. Connectivity Scenarios

| Need | Solution |
|------|---------|
| On-premises ↔ AWS (over internet) | Site-to-Site VPN |
| On-premises ↔ AWS (dedicated fiber) | AWS Direct Connect |
| Multiple on-prem branches ↔ AWS | VPN CloudHub |
| Remote user ↔ AWS | AWS Client VPN |
| VPC ↔ VPC (same or different account/region) | VPC Peering |
| Many VPCs + on-premises (hub model) | Transit Gateway |

---

## 2. Site-to-Site VPN

### Components

| Component | Location | Role |
|-----------|---------|------|
| **Virtual Private Gateway (VGW)** | AWS VPC | AWS-side VPN endpoint — attached to VPC |
| **Customer Gateway (CGW)** | On-premises | Represents your physical VPN device in AWS |
| **VPN Connection** | Logical link | Two IPsec tunnels connecting VGW ↔ CGW |

```
On-Premises                              AWS
Data Center                              VPC
  [Router/Firewall]                      [VGW]
  [CGW resource] ──── Tunnel 1 ──────────┤
                ──── Tunnel 2 ──────────┘  (two tunnels for redundancy)
```

### Key Properties

| Property | Detail |
|----------|--------|
| Transport | Public internet |
| Encryption | IPsec (AES-256) |
| Tunnels per connection | **2** (active/passive or ECMP active/active) |
| Routing | Static routes OR BGP (dynamic) |
| Speed | Up to 1.25 Gbps per tunnel |
| Setup time | Minutes to hours |
| Cost | Low (~$0.05/hr per VPN connection) |
| Latency | Variable (depends on internet) |

> **Two tunnels** = redundancy. If one tunnel fails, traffic automatically
> shifts to the second. Each tunnel terminates in a different AZ on the AWS side.

### Routing — Static vs BGP

| Mode | How | Use When |
|------|-----|---------|
| **Static** | You manually add on-prem CIDR to VPN config + route table | Simple setups, predictable routes |
| **BGP (dynamic)** | Routes automatically propagated via route propagation | Complex/changing networks, multiple routes |

```bash
# With BGP + route propagation enabled:
# Route table automatically gets:
# 192.168.0.0/24 → vgw-xxxxxxxx  (on-prem network, auto-propagated)
```

---

## 3. AWS VPN CloudHub

Extends Site-to-Site VPN to connect **multiple on-premises offices** to the same VGW —
and allows those offices to communicate with each other through AWS.

```
Branch A (New York)  ─── VPN ───┐
Branch B (London)    ─── VPN ───┼── VGW (single VPC) ── AWS VPC
Branch C (Karachi)   ─── VPN ───┘
              ↕ (branches can also talk to each other via VGW)
```

> Uses a hub-and-spoke model.
> Each branch needs a unique BGP ASN.
> Traffic between branches goes through AWS — billed as data transfer.

---

## 4. AWS Client VPN

For **individual users** (developers, remote employees) to connect to AWS or on-premises:

```
Your Laptop (OpenVPN client) → Client VPN Endpoint → VPC / On-Premises
```

| Property | Detail |
|----------|--------|
| Protocol | OpenVPN (TLS) |
| Authentication | Active Directory, SAML, certificate-based |
| Split tunneling | ✅ Optional — only VPC traffic through VPN, rest goes to internet directly |
| Use case | Remote workers, developers, temporary access |

> Client VPN ≠ Site-to-Site VPN. Client VPN is **user-level** access, not network-level.

---

## 5. AWS Direct Connect (DX)

### Definition

A **dedicated private fiber connection** from your data center to an AWS
Direct Connect Location (colocation facility) — bypassing the public internet entirely.

```
Your Data Center
  → Your private fiber →
    Direct Connect Location (AWS-partner colocation)
      → AWS backbone →
        AWS Region
```

> You do NOT lay fiber directly to AWS. You connect to a
> **Direct Connect Location** (e.g., Equinix, Cyxtera) where AWS has a presence.
> A third-party carrier handles your data center → DX Location connection.

### Connection Types

| Type | Bandwidth | Provisioned By |
|------|-----------|---------------|
| **Dedicated Connection** | 1, 10, or 100 Gbps | AWS directly (from DX Location) |
| **Hosted Connection** | 50 Mbps – 10 Gbps | AWS Partner (sub-1G options available) |

### Key Properties

| Property | Detail |
|----------|--------|
| Network | Private — no public internet |
| Encryption | ❌ NOT encrypted by default |
| Latency | Consistent and low |
| Bandwidth | 1–100 Gbps (dedicated) |
| Setup time | Weeks to months (physical provisioning) |
| Cost | High — port fee + data transfer |
| SLA | 99.99% with redundant connections |

> **DX is NOT encrypted by default.**
> For encryption: run a Site-to-Site VPN over the Direct Connect connection
> (VPN over DX = private path + encryption).

### Virtual Interfaces (VIFs) ⭐

A VIF is a logical subdivision of the physical DX connection — allows one
physical fiber to carry multiple traffic types.

| VIF Type | Connects To | IP Addressing | Max Bandwidth | Use Case |
|---------|------------|--------------|--------------|---------|
| **Private VIF** | VPC (via VGW or DX Gateway) | RFC 1918 (private) | 10 Gbps | Access private resources in VPC |
| **Public VIF** | AWS public services (S3, DynamoDB, CloudFront) | Public IPs | 10 Gbps | Access AWS public endpoints without internet |
| **Transit VIF** | Transit Gateway (directly) | RFC 1918 (private) | **100 Gbps** | Multi-VPC modern architecture |

```
Same DX connection can carry multiple VIFs (different VLANs):
  VLAN 100 → Private VIF → VPC-A
  VLAN 200 → Public VIF  → S3, SQS, SNS
  VLAN 300 → Transit VIF → Transit Gateway → multiple VPCs
```

### Direct Connect Gateway

Connects **one DX connection to multiple VPCs** across Regions and accounts:

```
On-Premises → DX Location → Private VIF → DX Gateway → VGW (VPC-A, us-east-1)
                                                    → VGW (VPC-B, ap-south-1)
                                                    → VGW (VPC-C, eu-west-1)
```

Without DX Gateway — each VPC needs its own VIF (expensive and complex).

### Architecture Decision

```
Single VPC, simple:       Private VIF → VGW → VPC
Multiple VPCs, modern:    Transit VIF → Transit Gateway → VPCs  (up to 100 Gbps)
Multiple VPCs, legacy:    Private VIF → DX Gateway → TGW → VPCs
Access S3/DynamoDB:       Public VIF → AWS Public Zone
```

---

## 6. DX + VPN — Backup Architecture ⭐

Direct Connect has no SLA on the fiber between your data center and the DX Location.
Best practice for production:

```
Primary:  Direct Connect     (high bandwidth, low latency, private)
Backup:   Site-to-Site VPN   (internet-based, activates on DX failure)
```

```
On-Premises
  ├── Direct Connect → VGW   (primary, high-speed)
  └── VPN Connection → VGW   (backup, activates when DX fails)
```

BGP routing handles failover automatically — DX routes preferred (shorter AS path).

---

## 7. VPN vs Direct Connect

| Feature | Site-to-Site VPN | Direct Connect |
|---------|----------------|---------------|
| Transport | Public internet | Private dedicated fiber |
| Encryption | ✅ IPsec (always) | ❌ Not by default (add VPN for encryption) |
| Latency | Variable | Consistent, low |
| Bandwidth | ~1.25 Gbps/tunnel | 1–100 Gbps |
| Setup time | Minutes–hours | Weeks–months |
| Cost | Low (~$0.05/hr) | High (port + data) |
| Reliability | Depends on internet | Very high (99.99% with redundancy) |
| Use case | Quick setup, backup, dev | Enterprise, large data, compliance |

---

## 8. VPC Peering ⭐

Private connection between two VPCs over the AWS internal network —
traffic never leaves AWS backbone.

### How It Works

```
VPC-A (Requester)     →     VPC-B (Accepter)
  sends peering request       accepts request
  updates own route table     updates own route table
  → communication works ✅
```

### Setup Steps

```
1. Create VPC Peering Connection
   (VPC-A initiates → VPC-B accepts)

2. Update Route Table in VPC-A:
   Destination: 192.168.0.0/16 → Target: pcx-xxxxxxxx

3. Update Route Table in VPC-B:
   Destination: 10.0.0.0/16 → Target: pcx-xxxxxxxx

4. Update Security Groups / NACLs to allow traffic
```

> Peering connection alone = nothing.
> **Route tables are what actually make it work.**

### Properties

| Property | Detail |
|----------|--------|
| Transport | AWS private network (no internet) |
| Encryption | Encrypted in transit (AWS backbone) |
| Cross-Region | ✅ Yes — inter-region peering (data transfer charges apply) |
| Cross-Account | ✅ Yes — requester/accepter in different accounts |
| Max peering per VPC | 50 (default) / 125 (max with increase) |
| Cost | Free within same Region; data transfer charges inter-Region |

### Critical Limitations ⭐

**1. No Overlapping CIDRs:**
```
VPC-A: 10.0.0.0/16
VPC-B: 10.0.0.0/24  ← overlaps → peering BLOCKED ❌

VPC-A: 10.0.0.0/16
VPC-B: 192.168.0.0/16 ← no overlap → allowed ✅
```

**2. No Transitive Routing:**
```
VPC-A ↔ VPC-B (peered)
VPC-A ↔ VPC-C (peered)
VPC-B ↛ VPC-C (NOT routable — traffic cannot transit through VPC-A)

Fix: Create direct VPC-B ↔ VPC-C peering
OR:  Use Transit Gateway (supports transitive routing)
```

**3. No Edge-to-Edge Routing:**
```
VPC-A has a VPN to on-premises
VPC-B is peered with VPC-A
→ VPC-B CANNOT reach on-premises via VPC-A's VPN ❌

Fix: Use Transit Gateway
```

---

## 9. VPC Peering vs Transit Gateway

| Factor | VPC Peering | Transit Gateway |
|--------|------------|----------------|
| Transitive routing | ❌ No | ✅ Yes |
| N VPCs (connections needed) | N×(N-1)/2 mesh | N attachments (hub-spoke) |
| 10 VPCs | 45 peering connections | 10 TGW attachments |
| Cross-Region | ✅ Yes | ✅ Yes (TGW peering) |
| On-premises (VPN/DX) | ❌ No | ✅ Yes (unified hub) |
| Cost | Free within Region | Per attachment + data |
| Bandwidth | No limit | Up to 50 Gbps per VPC attachment |
| Use when | ≤ 5 VPC connections | 5+ VPCs or hybrid networking |

```
10 VPCs with peering = 45 connections to manage ❌
10 VPCs with TGW    = 10 attachments to one TGW ✅
```

---

## 10. CIDR Planning — Architect-Level Responsibility ⭐

The most common connectivity failure is CIDR overlap. Design with future growth:

```
Rule: Plan all CIDR blocks BEFORE connecting anything.
      Overlapping CIDRs = no peering, no VPN routing, routing ambiguity.

Example Plan:
  VPC Production:   10.0.0.0/16
  VPC Staging:      10.1.0.0/16
  VPC Dev:          10.2.0.0/16
  On-Premises:      192.168.0.0/16

All unique → any connectivity option works ✅
```

---

## 11. Full Connectivity Architecture (Enterprise)

```
On-Premises Data Center
  ├── Direct Connect (primary)  ─────┐
  └── Site-to-Site VPN (backup) ─────┤
                                     ↓
                              Transit Gateway
                                ┌────┴────┐
                            VPC-Prod   VPC-Dev
                            (10.0.0.0)  (10.2.0.0)
                                └────┬────┘
                                  VPC-Shared
                              (NAT GW, VPC Endpoints,
                               DNS resolver)
```

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| IGW used for VPN connectivity | VGW is used for VPN — IGW is for internet access only |
| Direct Connect is encrypted by default | DX is NOT encrypted — add VPN over DX for encryption |
| VPC Peering supports transitive routing | No transitive routing — use Transit Gateway |
| One VPN tunnel per connection | AWS VPN provides **two** tunnels per connection (redundancy) |
| Direct Connect setup takes hours | Takes **weeks to months** (physical provisioning) |
| Peering works without route table updates | Route tables on **both** sides must be manually updated |
| Default VPCs can always be peered | Default VPCs have `172.31.0.0/16` — same CIDR across regions → cannot peer |
| VPN CloudHub = internet VPN | CloudHub routes via AWS backbone after entering via VPN tunnel |
| DX is always faster than VPN | DX has consistent latency; VPN may be adequate for non-latency-sensitive workloads |
| Transit VIF needs DX Gateway | Transit VIF connects **directly** to TGW — no DX Gateway needed |

---

## 13. Interview Questions Checklist

- [ ] What are the two components of a Site-to-Site VPN? (VGW + CGW)
- [ ] How many IPsec tunnels per VPN connection? Why two?
- [ ] Static routing vs BGP routing in VPN — when to use each?
- [ ] What is VPN CloudHub? How does it work?
- [ ] Client VPN vs Site-to-Site VPN — difference?
- [ ] What is Direct Connect? Who lays the fiber?
- [ ] Is Direct Connect encrypted? How do you add encryption?
- [ ] What are the three VIF types? What does each connect to?
- [ ] Transit VIF vs Private VIF — key difference?
- [ ] What is a Direct Connect Gateway? When is it needed?
- [ ] What is the best practice for DX resilience? (DX primary + VPN backup)
- [ ] VPN vs Direct Connect — 5 comparisons
- [ ] What are the two hard limits of VPC Peering? (no overlap, no transitive)
- [ ] Walk through the 4 steps to set up VPC Peering
- [ ] Why doesn't peering work between two default VPCs in different regions?
- [ ] What is edge-to-edge routing? Why is it blocked in peering?
- [ ] VPC Peering vs Transit Gateway — when to use which?
- [ ] 10 VPCs need full mesh connectivity — how many peering connections? (45)
- [ ] What is the CIDR planning responsibility of an architect?
