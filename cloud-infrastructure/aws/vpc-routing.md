# AWS VPC Routing — Implied Router & Route Tables

## 1. The Implied Router

AWS VPCs have no visible router device. Instead, every VPC has an
**implicit/implied router** — a fully managed, invisible routing engine
that AWS runs inside the VPC fabric.

```
Traditional on-premises:          AWS VPC:
  Physical Router (device)    →   Implied Router (invisible, AWS-managed)
  Routing table (on device)   →   Route Table (you configure)
```

| Component | Role |
|-----------|------|
| **Implied Router** | The execution engine — forwards every packet |
| **Route Table** | The decision logic — tells the router where to send traffic |

> You configure route tables. AWS's implied router reads them and acts.
> You never touch the router itself — it's fully managed and always available.

**Where does the implied router "live"?**

The VPC router's IP address is always the **second IP of every subnet**
(e.g., `10.0.1.1` in a `10.0.1.0/24` subnet). This is one of the 5
reserved IPs per subnet — it is the default gateway for every resource in that subnet.

---

## 2. Route Table — Complete Model

### Definition

A route table is a set of rules (**routes**) that tell the implied router
where to send traffic based on its destination IP address.

### Route Structure

Every route has two parts:

| Field | Meaning | Example |
|-------|---------|---------|
| **Destination** | Which IP range this rule applies to | `10.0.0.0/16`, `0.0.0.0/0` |
| **Target** | Where to send matching traffic | `local`, `igw-xxx`, `nat-xxx` |

### All Possible Route Targets

| Target | Meaning |
|--------|---------|
| `local` | Stay inside the VPC — inter-subnet traffic |
| `igw-xxxxxxxx` | Internet Gateway — public internet |
| `nat-xxxxxxxx` | NAT Gateway — outbound internet from private subnet |
| `eni-xxxxxxxx` | Elastic Network Interface — route to a specific NIC |
| `pcx-xxxxxxxx` | VPC Peering Connection |
| `vpce-xxxxxxxx` | VPC Endpoint (Gateway type — S3/DynamoDB) |
| `tgw-xxxxxxxx` | Transit Gateway |
| `vgw-xxxxxxxx` | Virtual Private Gateway (VPN/Direct Connect) |
| `i-xxxxxxxx` | EC2 Instance (NAT instance or appliance) |
| `blackhole` | Drop the traffic — see Section 5 |

---

## 3. The Local Route ⭐

Every route table has exactly one permanent entry that cannot be deleted or modified:

```
Destination: 10.0.0.0/16   →   Target: local
```

This is written automatically when the VPC is created — NOT when the IGW is created.

**What it does:** Tells the implied router that any traffic destined for an
IP within the VPC's CIDR stays inside the VPC.
This is what enables subnet-to-subnet communication without any extra configuration.

| Property | Detail |
|----------|--------|
| Created | Automatically when VPC is created |
| Modifiable | ❌ Cannot edit or delete |
| Covers | Entire VPC CIDR range |
| Scope | All subnets — every route table has this entry |

> **If you want to block subnet-to-subnet traffic** — the local route cannot be
> removed. Use **NACLs** or **Security Groups** to restrict communication instead.

---

## 4. Route Table Types & Association Rules ⭐

### Types

| Type | Description |
|------|-------------|
| **Main (Default)** | Auto-created with VPC; auto-assigned to subnets with no explicit association |
| **Custom** | You create; must explicitly associate with subnets |
| **Gateway Route Table** | Can be associated with an IGW or VGW for edge routing |

### Association Rules

```
Rule 1: One subnet → exactly ONE route table at any time
Rule 2: One route table → any number of subnets
Rule 3: Subnet with no explicit association → uses Main route table
```

```
VPC (10.0.0.0/16)
  ├── Main Route Table         ← used by subnet-C (no explicit association)
  ├── Custom Route Table A     ← subnet-A and subnet-B explicitly associated
  └── Custom Route Table B     ← subnet-D explicitly associated
```

### Main Route Table — Special Behaviors

| Property | Detail |
|----------|--------|
| Deletable | ❌ Cannot delete directly |
| Replaceable | ✅ Promote any custom route table to become Main |
| Default association | Any subnet without an explicit association uses it |
| Best practice | Keep Main route table private (local route only) — force explicit routing decisions |

**How to replace Main route table:**
```
1. Create a new route table
2. Actions → Set as Main
3. Old main demoted → now a regular custom table → can delete it
```

---

## 5. Longest Prefix Match — Route Priority ⭐

When multiple routes could match a destination IP, **the most specific route wins**
(longest prefix = most bits matched = highest priority).

```
Route Table:
  10.0.0.0/16   → local
  10.0.1.0/24   → nat-gateway
  0.0.0.0/0     → igw

Traffic to 10.0.1.5:
  Matches 10.0.0.0/16 (16-bit match)
  Matches 10.0.1.0/24 (24-bit match) ← WINS — more specific
  → sent to nat-gateway
```

**Route priority when prefix lengths are equal:**
```
1. Static routes (manually added)   — highest priority
2. VPN static routes
3. BGP propagated routes (Direct Connect)
4. BGP propagated routes (Site-to-Site VPN)
```

---

## 6. Blackhole Routes ⭐

A route enters **blackhole** state when its target no longer exists — but the
route entry still remains in the table.

**How it happens:**
```
You add:  0.0.0.0/0 → nat-xxxxxxxx
Later:    NAT Gateway is deleted
Result:   Route still exists, target is gone → Status: blackhole
Effect:   All matching traffic is silently dropped ❌
```

**Common causes:**
- NAT Gateway deleted — route table still points to it
- VPC Peering connection deleted — peer routes become blackholes
- EC2 instance (NAT instance) terminated — routes pointing to it blackhole
- IGW detached from VPC — routes pointing to it blackhole

**Fix:**
```bash
# Detect blackhole routes
aws ec2 describe-route-tables --query 'RouteTables[*].Routes[?State==`blackhole`]'
# Delete the blackhole route
aws ec2 delete-route \
  --route-table-id rtb-xxxxxxxx \
  --destination-cidr-block 0.0.0.0/0
```

> Blackhole routes cause **silent packet drops** — no error returned to the client.
> The most confusing network debugging scenario in VPCs.

---

## 7. Route Propagation

Route propagation allows a **Virtual Private Gateway (VGW)** — used for Site-to-Site
VPN or Direct Connect — to automatically add routes it learns via BGP into a
route table.

**Without propagation (manual):**
```
You must manually add:  192.168.0.0/24 → vgw-xxxxxxxx   (on-premises CIDR)
```

**With propagation (automatic):**
```
VGW learns 192.168.0.0/24 from on-premises via BGP
→ Automatically added to route table → no manual entry needed
→ Route appears with type: "propagated"
```

| Property | Detail |
|----------|--------|
| Enable per route table | ✅ Can enable/disable per table |
| Route type | Shown as "propagated" vs "static" |
| Priority | Static routes beat propagated routes with same prefix |
| Use case | VPN / Direct Connect hybrid networking |

---

## 8. Public vs Private Subnet — Routing-Only Distinction

There is no "public/private" label or toggle in AWS.
**A subnet is public if and only if:**

```
Condition 1: Route table has   0.0.0.0/0 → igw-xxxxxxxx
Condition 2: Resource has a public IP (auto-assigned or Elastic IP)

BOTH conditions required — either alone = no internet access
```

**Public subnet route table:**
```
Destination      Target
10.0.0.0/16  →   local
0.0.0.0/0    →   igw-xxxxxxxx   ← this route = what makes it "public"
```

**Private subnet route table (with outbound access):**
```
Destination      Target
10.0.0.0/16  →   local
0.0.0.0/0    →   nat-xxxxxxxx   ← outbound via NAT, no inbound
```

**Isolated subnet (no internet at all):**
```
Destination      Target
10.0.0.0/16  →   local           ← only local route; no internet access
```

---

## 9. Per-AZ Route Table Pattern ⭐ (Production Best Practice)

For **high availability**, each AZ's private subnet should use its own route table
pointing to its own NAT Gateway.

**Wrong (single point of failure):**
```
AZ-1a Private Subnet  ─┐
AZ-1b Private Subnet  ─┴── One route table → One NAT GW (AZ-1a)
                           ↑ If NAT GW in AZ-1a fails → both AZs lose internet
```

**Correct (per-AZ NAT Gateway):**
```
AZ-1a Private Subnet → Route Table A → NAT Gateway in AZ-1a
AZ-1b Private Subnet → Route Table B → NAT Gateway in AZ-1b
```

> Always create **one route table per AZ** for private subnets, each pointing
> to the NAT Gateway in its own AZ.

---

## 10. Route Table Limits

| Resource | Default Limit |
|----------|--------------|
| Route tables per VPC | 200 |
| Routes per route table | 50 (can increase to 1,000) |
| Subnets per VPC | 200 |
| IGW per VPC | 1 (attached at a time) |
| Peering connections per VPC | 50 (can increase to 125) |

---

## 11. Complete Traffic Flow — End to End

### Internet → Private EC2 (via ALB in public subnet)

```
Internet
  → IGW (NAT: public IP → private IP of ALB)
  → Route Table (public subnet): 0.0.0.0/0 → local for VPC IPs
  → Implied Router
  → ALB (public subnet, 10.0.1.x)
  → Implied Router
  → Route Table (private subnet): 10.0.0.0/16 → local
  → App Server (private subnet, 10.0.2.x)
```

### Private EC2 → Internet (software update)

```
App Server (10.0.2.5)
  → Route Table (private): 0.0.0.0/0 → nat-xxxxxxxx
  → Implied Router
  → NAT Gateway (public subnet, 10.0.1.x)
  → Route Table (public): 0.0.0.0/0 → igw-xxxxxxxx
  → IGW (NAT: EIP of NAT GW → destination)
  → Internet
```

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| IGW creates the local route | Local route is created when **VPC is created** — not IGW |
| Route table evaluates all rules | **Longest prefix match** — most specific route wins first |
| Deleting IGW removes the local route | Deleting IGW only removes ability to use IGW as target — local route stays |
| One NAT GW covers all AZs | NAT GW is AZ-specific — use one per AZ for HA |
| Blackhole routes fail loudly | Blackhole routes **silently drop packets** — no error |
| Main route table can be deleted | Cannot delete directly — must replace it first |
| Local route can be deleted | Local route is **permanent** — cannot delete or modify |
| New custom route table has internet | New route table only has `local` route — private by default |
| Route propagation works for all VPNs | Propagation is only for VGW (VPN/Direct Connect) — not for peering |

---

## 13. Interview Questions Checklist

- [ ] What is the implied router? Where does it "live" (what IP)?
- [ ] What is a route table? What are the two parts of every route?
- [ ] What is the local route? Can it be deleted?
- [ ] When is the local route created — with VPC or with IGW?
- [ ] What is the Main route table? What makes a subnet use it?
- [ ] One subnet → how many route tables? One route table → how many subnets?
- [ ] Explain longest prefix match with an example
- [ ] What makes a subnet public? (Two conditions required)
- [ ] What are all possible route targets in a VPC?
- [ ] What is a blackhole route? How does it occur? How do you detect it?
- [ ] Why is blackhole dangerous? (Silent drop)
- [ ] What is route propagation? When is it used?
- [ ] Why create separate route tables per AZ for private subnets?
- [ ] How do you replace the Main route table?
- [ ] How do you block internal VPC communication if the local route can't be deleted?
- [ ] Walk through the traffic flow from a private EC2 to the internet
