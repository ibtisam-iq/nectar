# Transit Gateway (TGW)

## TGW Architecture Fundamentals

Transit Gateway is a **Regional, highly available, fully managed network transit hub**.
It acts like a cloud router where every connected network registers as an **attachment**
and all routing decisions happen at the TGW level — independently of VPC route tables.

```
VPC-A (10.0.0.0/16) ──────────────────────────────┐
VPC-B (10.1.0.0/16) ─────────── TGW ──────────────┤
VPC-C (10.2.0.0/16) ──────────────────────────────┤
On-Premises (192.168.0.0/16) ── (VPN/DX) ─────────┘
```

Every packet entering or leaving the TGW is routed based on the **TGW Route Table**
— a separate routing layer that you control independently from VPC route tables.

---

## Attachment Types ⭐

Every connection to a TGW is an **attachment**:

| Attachment Type | Connects | Use Case |
|----------------|---------|---------|
| **VPC** | VPC in same Region | Standard VPC-to-VPC routing |
| **VPN** | Site-to-Site VPN | On-premises via encrypted internet tunnel |
| **Direct Connect Gateway** | Direct Connect Gateway | On-premises via dedicated fiber |
| **TGW Peering** | TGW in another Region | Cross-Region multi-VPC connectivity |
| **TGW Connect** | SD-WAN appliance (GRE + BGP) | Integration with third-party SD-WAN |

> **TGW replaces VGW for hybrid architecture.**
> Modern design: Customer Gateway → VPN → TGW (not VGW).
> VGW is only needed if connecting a single VPC directly to on-premises.

## VPC Attachment Subnet Requirement

When attaching a VPC, you must specify **one subnet per AZ** where TGW should place
its Elastic Network Interface. Best practice: use dedicated `/28` subnets per AZ:

```
VPC: 10.0.0.0/16
  Subnet: 10.0.255.0/28 (AZ-1a) → TGW ENI subnet
  Subnet: 10.0.255.16/28 (AZ-1b) → TGW ENI subnet
  (These subnets are for TGW ENIs only — do not place EC2 here)
```

---

## TGW Route Tables — Association & Propagation ⭐

TGW has its own routing layer, completely separate from VPC route tables.
Understanding **association** vs **propagation** is the most critical concept.

### Association (One per attachment)

Every attachment must be **associated** with exactly one TGW route table.
The associated route table is consulted when traffic arrives FROM that attachment.

```
VPC-A attachment → associated with → TGW-RT-Production
VPN attachment   → associated with → TGW-RT-Hybrid
```

### Propagation (Can propagate to many)

An attachment can **propagate** its CIDR routes into one or more TGW route tables.
Propagation = the TGW route table automatically learns the attachment's CIDR.

```
VPC-A (10.0.0.0/16) propagates to → TGW-RT-Production and TGW-RT-Hybrid
VPC-B (10.1.0.0/16) propagates to → TGW-RT-Production only
VPN on-prem (192.168.0.0/16) propagates to → TGW-RT-Hybrid only
```

### Two-Level Routing Flow

```
Traffic: VPC-A → VPC-B

Step 1: VPC-A route table
  10.1.0.0/16 → tgw-xxxxxxxx

Step 2: TGW looks up VPC-A's associated route table (TGW-RT-Production)
  10.1.0.0/16 → VPC-B attachment (propagated)

Step 3: Traffic delivered to VPC-B

Step 4: VPC-B route table handles internal delivery
  (local route: 10.1.0.0/16 → local)
```

### Default Route Table Behavior

When TGW is created, by default:

| Setting | Default | Meaning |
|---------|---------|---------|
| Default route table association | ✅ Enabled | All new attachments auto-associated with default TGW-RT |
| Default route table propagation | ✅ Enabled | All attachments auto-propagate CIDRs to default TGW-RT |

> With defaults: all VPCs can reach all other VPCs immediately — zero manual routing.
> For isolation (dev/prod separation): disable defaults and use custom route tables.

---

## TGW Route Table — Isolation Pattern ⭐

The most powerful TGW use case: **network segmentation without firewall appliances**.

```
Scenario:
  VPC-Prod-A (10.0.0.0/16)
  VPC-Prod-B (10.1.0.0/16)
  VPC-Dev    (10.2.0.0/16)
  VPC-Shared (10.3.0.0/16) — DNS, monitoring, shared services

Goal: Dev cannot reach Prod, but all can reach Shared

TGW Route Table: RT-Prod
  Association:  VPC-Prod-A attachment, VPC-Prod-B attachment
  Propagation:  10.0.0.0/16 (Prod-A), 10.1.0.0/16 (Prod-B), 10.3.0.0/16 (Shared)
  → Prod-A ↔ Prod-B ✅, Prod → Shared ✅, Prod → Dev ❌

TGW Route Table: RT-Dev
  Association:  VPC-Dev attachment
  Propagation:  10.2.0.0/16 (Dev), 10.3.0.0/16 (Shared)
  → Dev → Shared ✅, Dev → Prod ❌

TGW Route Table: RT-Shared
  Association:  VPC-Shared attachment
  Propagation:  10.0.0.0/16, 10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16 (all)
  → Shared → All ✅
```

---

## ECMP — Equal Cost Multi-Path ⭐

TGW supports **ECMP** for VPN attachments — allows multiple VPN connections
to be treated as equal paths, increasing bandwidth beyond the single-tunnel limit.

```
Single Site-to-Site VPN tunnel:   max ~1.25 Gbps
Two tunnels, no ECMP:             active/passive — still 1.25 Gbps
Two VPN connections, ECMP on:     active/active — up to 2.5 Gbps
Four VPN connections, ECMP on:    up to 5 Gbps
```

**Requirements:**
- BGP routing (not static) — ECMP requires equal-cost BGP paths
- Same destination prefixes advertised over all tunnels
- ECMP enabled at TGW creation time (cannot enable after)

> ECMP is the standard way to scale VPN bandwidth with TGW beyond 1.25 Gbps.

---

## Appliance Mode ⭐

By default, TGW sends traffic symmetrically — but for **stateful inspection appliances**
(firewalls, IDS/IPS), both directions of a flow must hit the **same appliance instance**.

**Problem without appliance mode:**
```
Request:  VPC-A → TGW → Firewall-Instance-1 → VPC-B
Response: VPC-B → TGW → Firewall-Instance-2 → VPC-A
→ Stateful firewall loses session state ❌
```

**With appliance mode enabled** on the inspection VPC attachment:
```
Request:  VPC-A → TGW → Firewall-Instance-1 → VPC-B
Response: VPC-B → TGW → Firewall-Instance-1 → VPC-A (same instance ✅)
→ TGW uses flow hash to pin flows to the same ENI
```

> Enable appliance mode when inserting stateful firewalls, IDS/IPS, or packet inspection
> appliances into the traffic path via a dedicated security/inspection VPC.

---

## Centralized Architecture Patterns

### Pattern 1 — Centralized Egress (NAT)

Instead of one NAT Gateway per VPC, route all outbound internet traffic
through a single shared NAT Gateway VPC:

```
VPC-A (private) ──────────────────────────────┐
VPC-B (private) ─────── TGW ──── VPC-Egress ──┤── NAT GW ── IGW ── Internet
VPC-C (private) ──────────────────────────────┘
  (all VPCs route 0.0.0.0/0 → TGW → VPC-Egress → NAT)

Savings: 3 NAT Gateways ($97.20/month) → 1 NAT Gateway ($32.40/month)
```

### Pattern 2 — Centralized Inspection (Firewall)

Route all inter-VPC and internet traffic through a central firewall:

```
VPC-A ──┐                              ┌── VPC-A
VPC-B ──┼── TGW ── VPC-Inspection ────┼── VPC-B
VPC-C ──┘   (AWS Network Firewall /   └── VPC-C
             3rd-party appliance)
```

> All traffic flows through VPC-Inspection — appliance mode must be enabled
> on TGW attachment for the inspection VPC.

---

## Multi-Account Sharing (AWS RAM) ⭐

TGW can be shared across AWS accounts using **AWS Resource Access Manager (RAM)**:

```
Account A (Network team) → Creates TGW → Shares via RAM
Account B (App team)     → Attaches VPC-B to shared TGW
Account C (Dev team)     → Attaches VPC-C to shared TGW
```

| Property | Detail |
|----------|--------|
| Billing | Attachment billed to the **VPC owner account** |
| Control | TGW owner manages route tables and policies |
| Cross-org | Can share within AWS Organization or to specific accounts |
| Use case | Centralized network governance in multi-account organizations |

---

## TGW Pricing ⭐

| Charge | Rate (us-east-1) |
|--------|-----------------|
| **Attachment (hourly)** | $0.05/hr per attachment |
| **Data processing** | $0.02/GB sent to TGW |
| **Peering attachment** | $0.05/hr (no data processing charge for peering) |
| **Monthly per attachment** | ~$36.50/month |

**Example: 10 VPCs + 1 VPN, 1 TB/month traffic:**
```
Attachments:   11 × $36.50   = $401.50/month
Data:          1,024 GB × $0.02 = $20.48/month
Total:         ~$422/month

vs VPC Peering (10 VPCs = 45 connections):
  Peering: $0 hourly + data transfer only
  But: 45 route table entries to manage manually
```

> TGW is **operationally cheaper** at scale even if financially more expensive
> than peering — the management overhead of mesh peering grows exponentially.

---

## TGW Limits

| Resource | Limit |
|----------|-------|
| Attachments per TGW | 5,000 |
| TGW route tables per TGW | 20 |
| Routes per TGW route table | 10,000 |
| TGWs per Region per account | 5 (default) |
| Peering attachments per TGW | 50 |
| Bandwidth per VPC attachment | Up to 50 Gbps |
| VPN ECMP paths | Up to 8 equal-cost paths |

---

## Decision Framework

```
How many VPCs do you have?
  2–3 VPCs only → VPC Peering (cheaper, simpler)
  4+ VPCs OR need transitive routing → Transit Gateway

Do you need on-premises connectivity to multiple VPCs?
  Yes → TGW (single connection point for all VPCs)
  No, only one VPC → VGW (simpler, cheaper)

Do you need dev/prod network isolation?
  Yes → TGW with multiple route tables

Do you need centralized firewall inspection?
  Yes → TGW with appliance mode + inspection VPC

Multi-account architecture?
  Yes → TGW + RAM sharing
```

---

## Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| TGW replaces VGW entirely | TGW can **terminate VPN directly** — VGW not needed for hybrid with TGW |
| One route table per TGW | TGW can have **multiple route tables** for isolation |
| Association and propagation are the same | Association = which table is used for incoming traffic; Propagation = which tables learn this attachment's CIDR |
| ECMP works with static routing | ECMP requires **BGP** routing — not compatible with static routes |
| Appliance mode is default | Must **explicitly enable** appliance mode on the attachment |
| TGW is free | $0.05/hr per attachment = $36.50/month minimum per attachment |
| TGW peering is transitive across regions | TGW-to-TGW peering is supported but **each TGW handles its own routing** |
| Disabling defaults breaks existing connectivity | Only affects **new** attachments — existing ones keep their associations |

---

## Interview Questions

- [ ] Why was TGW created? What problem does it solve over VPC Peering?
- [ ] What is N(N-1)/2 and why does it matter for peering?
- [ ] List all 5 TGW attachment types and when to use each
- [ ] What is the difference between association and propagation in TGW route tables?
- [ ] How do you isolate dev VPCs from prod VPCs using TGW route tables?
- [ ] Does TGW replace VGW? When would you still use VGW?
- [ ] What is ECMP? What routing protocol does it require?
- [ ] What is appliance mode? When must you enable it?
- [ ] What are the two centralized architecture patterns with TGW?
- [ ] How do you share TGW across AWS accounts?
- [ ] What is the cost of TGW? (hourly + per-GB)
- [ ] TGW vs VPC Peering — when is TGW worth the extra cost?
- [ ] What subnet do you specify when creating a VPC attachment?
- [ ] How many attachments can one TGW support? (5,000)
- [ ] What happens when default route table association is disabled?
