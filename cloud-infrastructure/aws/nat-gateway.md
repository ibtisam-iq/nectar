# NAT Gateway & NAT Instance

---

## 1. Why NAT Exists

A private subnet EC2 instance has no public IP and no route to the IGW —
it cannot reach the internet at all. But it still needs **outbound** internet access:

- OS security patches (`apt update`, `yum update`)
- Package downloads (`pip install`, `npm install`, `docker pull`)
- Calls to external APIs
- Database replication tools, license servers

The requirement is asymmetric:
```text
✅ Private EC2 → Internet (outbound — needed)
❌ Internet → Private EC2 (inbound — must NOT be allowed)
```

> **NAT (Network Address Translation)** solves this by acting as an
> intermediary — it translates the private source IP to a public IP
> for outbound requests, while blocking all unsolicited inbound traffic.

---

## 2. Bastion Host vs NAT — Key Distinction

These solve different problems:

| Tool | Solves | How |
|------|--------|-----|
| **Bastion Host** | Admin **access to** private EC2 | You → public EC2 → private EC2 (SSH tunnel) |
| **NAT Gateway** | Private EC2 **accessing** internet | Private EC2 → NAT → Internet |

> Bastion host = you reaching private instances.
> NAT Gateway = private instances reaching the internet.
> They are complementary — not alternatives.

---

## 3. NAT Gateway — Architecture ⭐

### Mandatory Requirements

```text
NAT Gateway MUST be placed in a PUBLIC subnet
  (it needs the IGW route to reach the internet)
NAT Gateway MUST have an Elastic IP
  (its public-facing identity)
```

### Complete Traffic Flow

```text
Private EC2 (10.0.2.5 — no public IP)
  ↓
Private Subnet Route Table: 0.0.0.0/0 → nat-xxxxxxxx
  ↓
NAT Gateway (10.0.1.x, EIP: 54.x.x.x — in public subnet)
  ↓
Public Subnet Route Table: 0.0.0.0/0 → igw-xxxxxxxx
  ↓
Internet Gateway
  ↓
Internet (sees source IP as 54.x.x.x — private IP is hidden)

Return traffic:
Internet → IGW → NAT Gateway → Private EC2
(Internet never initiates — NAT blocks all unsolicited inbound)
```

### Route Table Configuration

```text
Public Subnet Route Table:          Private Subnet Route Table:
  10.0.0.0/16 → local                 10.0.0.0/16 → local
  0.0.0.0/0   → igw-xxxxxxxx          0.0.0.0/0   → nat-xxxxxxxx

❌ You CANNOT have both in the same route table:
  0.0.0.0/0 → igw-xxxxxxxx
  0.0.0.0/0 → nat-xxxxxxxx
  (duplicate destination = invalid — only one default route per table)
```

---

## 4. NAT Gateway Types ⭐

Since 2021, AWS offers two NAT Gateway types:

| Type | Placement | Use Case |
|------|-----------|---------|
| **Public** (default) | Public subnet + EIP | Private EC2 → public internet |
| **Private** | Private subnet, no EIP | Private EC2 → other VPCs or on-premises (via TGW/VPN) without going through internet |

### Private NAT Gateway — When to Use

```text
VPC A (10.0.0.0/16) → Private NAT GW → Transit Gateway → VPC B (10.1.0.0/16)

Use case: VPC B has overlapping CIDR with another VPC.
Private NAT translates the source IP, allowing communication despite CIDR overlap.
Traffic stays entirely on AWS private network — never touches internet.
```

---

## 5. NAT Gateway Performance & Limits

| Metric | Standard NAT Gateway | Regional NAT Gateway (2025) |
|--------|--------------------|-----------------------------|
| Bandwidth | 5 Gbps → scales to **100 Gbps** | Scales automatically across AZs |
| Max simultaneous connections | **55,000 per destination IP** | Higher — auto-scales |
| Max active connections | **~440,000** total | Higher |
| Port range | 1,024 – 65,535 | Same |
| Error metric | `ErrorPortAllocation` | Same |

> Port exhaustion (55,000 simultaneous connections to one destination) = `ErrorPortAllocation` errors.
> Fix: Add multiple EIPs to the NAT Gateway — each adds 55,000 more ports.

---

## 6. NAT Gateway Pricing ⭐ (Critical for Architecture Decisions)

| Charge | Amount (us-east-1) |
|--------|-------------------|
| **Hourly** | $0.045/hr per NAT Gateway |
| **Data processing** | $0.045/GB (both directions through the gateway) |
| **Data transfer out** | $0.09/GB (standard EC2 internet egress — on top of processing) |
| **Cross-AZ traffic** | $0.01/GB extra each direction |
| **Idle (no traffic)** | Still billed at $0.045/hr |
| **Partial hour** | Billed as full hour |

**Monthly baseline cost:**
```text
$0.045/hr × 24 hrs × 30 days = $32.40/month minimum — per NAT Gateway
Even if zero traffic flows through it.
```

**At scale (1 TB/month through one NAT GW):**
```text
Hourly:           $32.40
Data processing:  1,024 GB × $0.045 = $46.08
Data transfer:    1,024 GB × $0.09  = $92.16
Total:            ~$170/month for one NAT Gateway
```

> NAT Gateway is one of the **biggest surprise bills** in AWS.
> Always use **VPC Endpoints** for S3 and DynamoDB traffic — it bypasses NAT
> Gateway entirely and is FREE for Gateway Endpoints.

---

## 7. High Availability — Per-AZ Pattern ⭐

NAT Gateway is **AZ-specific** — if the AZ fails, the NAT Gateway in that AZ fails.

```text
❌ Wrong (single point of failure):
  AZ-1a Private Subnet ─┐
  AZ-1b Private Subnet ─┴─→ One NAT GW (AZ-1a) ← fails if AZ-1a is down

✅ Correct (per-AZ):
  AZ-1a Private Subnet → Route Table A → NAT GW (AZ-1a, EIP-1)
  AZ-1b Private Subnet → Route Table B → NAT GW (AZ-1b, EIP-2)
  AZ-1c Private Subnet → Route Table C → NAT GW (AZ-1c, EIP-3)
```

> Deploy **one NAT Gateway per AZ** + **one route table per AZ**.
> Also eliminates cross-AZ data transfer charges ($0.01/GB each way).

### Regional NAT Gateway (2025)

AWS released **Regional NAT Gateway** in November 2025:

- Spans multiple AZs automatically
- Built-in port exhaustion protection (adds EIPs automatically)
- Reduces operational overhead vs managing per-AZ NAT Gateways
- Pricing model differs — check current AWS pricing for regional vs standard

---

## 8. NAT Gateway vs NAT Instance — Complete Comparison

| Feature | NAT Instance | NAT Gateway |
|---------|-------------|------------|
| **Managed by** | You (EC2 instance) | AWS (fully managed) |
| **Setup** | Launch special AMI, disable source/dest check | Create in public subnet, assign EIP |
| **Source/Dest check** | ❌ Must manually disable | ✅ AWS handles automatically |
| **Security Groups** | ✅ Can attach SGs | ❌ Cannot attach SGs (use NACLs) |
| **Bandwidth** | Limited by instance type | Up to 100 Gbps (auto-scales) |
| **Availability** | Single instance = SPOF; need manual failover | ✅ Highly available per AZ |
| **Patching** | ❌ You must patch the OS | ✅ AWS patches automatically |
| **Bastion capability** | ✅ Can double as bastion host | ❌ Cannot SSH into it |
| **Port forwarding** | ✅ Can configure custom rules | ❌ Fixed NAT behavior only |
| **Cost** | EC2 instance cost (cheaper for low traffic) | Hourly + per-GB (expensive at scale) |
| **Use today** | Legacy only — not recommended | ✅ Standard choice |

### NAT Instance — Why Source/Destination Check Must Be Disabled

By default, AWS drops any packet where the ENI is not the source or destination.
A NAT instance **forwards** other instances' traffic — it is neither the source
nor the destination of those packets. You must disable this check:

```bash
aws ec2 modify-network-interface-attribute \
  --network-interface-id eni-xxxxxxxx \
  --no-source-dest-check
```

---

## 9. Egress-Only Internet Gateway (EIGW) — IPv6 NAT ⭐

For **IPv6 traffic**, NAT Gateway doesn't apply — IPv6 addresses are all publicly
routable (no private IPv6 space). But you still need outbound-only behavior
for private instances.

**Solution:** Egress-Only Internet Gateway

| Property | Detail |
|----------|--------|
| Works with | IPv6 only |
| Direction | Outbound IPv6 ✅ — Inbound IPv6 ❌ blocked |
| Stateful | ✅ Yes — allows return traffic for established sessions |
| Cost | Free (no hourly charge — only data transfer costs) |
| Compared to | NAT Gateway for IPv4 |

```text
IPv4 private subnet → NAT Gateway → Internet
IPv6 private subnet → Egress-Only IGW → Internet
```

> EIGW = "NAT Gateway for IPv6" — but it doesn't actually do address
> translation (IPv6 has enough addresses). It only enforces traffic direction.

---

## 10. Cost Reduction Strategies ⭐

NAT Gateway is a major AWS cost driver. Reduce it by:

| Strategy | Savings | How |
|---------|---------|-----|
| **VPC Gateway Endpoints** | High | S3 + DynamoDB traffic bypasses NAT GW (free) |
| **VPC Interface Endpoints** | Medium | Route AWS service traffic (ECR, SQS, SSM) via private endpoint |
| **Per-AZ deployment** | Cross-AZ cost | Avoids $0.01/GB cross-AZ fee |
| **Consolidate NAT GWs** | Moderate | Fewer gateways if HA requirements allow |
| **Schedule deletion** | Dev/test only | Delete NAT GW at night — $32.40/month savings per GW |
| **Monitor with CloudWatch** | Visibility | `BytesOutToDestination`, `ErrorPortAllocation`, `ActiveConnectionCount` |

**The biggest quick win:**
```text
S3 traffic without endpoint:
  Private EC2 → NAT GW → Internet → S3 = $0.045/GB processing fee

S3 traffic with Gateway Endpoint:
  Private EC2 → VPC Endpoint → S3 = FREE ✅

For 1 TB/month to S3: saves ~$46/month per NAT Gateway
```

---

## 11. Complete Decision Tree

```text
Does the instance need internet access?
  NO → No NAT needed

  YES → Is it for outbound only (no inbound)?
    YES → Is traffic IPv4 or IPv6?
      IPv4 → NAT Gateway (in public subnet + EIP)
      IPv6 → Egress-Only Internet Gateway

    NO (needs bidirectional) → Give instance public IP + IGW route
                               (make subnet public)

Is the traffic going to AWS services (S3, DynamoDB, ECR, SSM)?
  YES → Use VPC Endpoint first (free or cheaper than NAT GW)
```

---

## Key Points

- NAT gateway is created inside public subnet, but its route entry is made in private route table.

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| NAT Gateway placed in private subnet | Must be in **public subnet** (needs IGW access) |
| NAT Gateway has no EIP | EIP is **mandatory** for public NAT Gateway |
| One NAT GW covers all AZs safely | NAT GW is AZ-specific — deploy one per AZ for HA |
| NAT Gateway is free when idle | Costs $0.045/hr ($32.40/month) even with zero traffic |
| Data processing is charged once | Charged on **both** inbound and outbound through the gateway |
| NAT Instance can be used reliably | Single point of failure — use NAT Gateway in production |
| Attach Security Group to NAT Gateway | Cannot attach SGs to NAT Gateway — use NACLs |
| Bastion host solves internet access | Bastion = admin access to private EC2; NAT = private EC2 accessing internet |
| NAT handles IPv6 | IPv6 uses Egress-Only Internet Gateway — not NAT Gateway |
| S3 access needs NAT Gateway | Use free **S3 Gateway Endpoint** — bypasses NAT entirely |

---

## 13. Interview Questions Checklist

- [ ] Why does a private subnet EC2 need NAT even though it doesn't need to be accessed from internet?
- [ ] Where must a NAT Gateway be placed? Why?
- [ ] What is mandatory alongside a NAT Gateway? (Elastic IP)
- [ ] Trace the full traffic flow: private EC2 → internet → response
- [ ] Why can't you have both 0.0.0.0/0 → IGW and 0.0.0.0/0 → NAT in one route table?
- [ ] Public NAT Gateway vs Private NAT Gateway — when to use each?
- [ ] What is the monthly baseline cost of one NAT Gateway? (~$32.40)
- [ ] What are the two cost components of NAT Gateway? (hourly + per-GB processing)
- [ ] How do you architect NAT Gateway for high availability?
- [ ] What is port exhaustion in NAT Gateway? How do you fix it?
- [ ] Regional NAT Gateway vs per-AZ — what changed in 2025?
- [ ] NAT Instance: what check must you disable and why?
- [ ] NAT Instance vs NAT Gateway — 5 differences
- [ ] What is an Egress-Only Internet Gateway? When do you use it?
- [ ] What is the biggest cost optimization for NAT Gateway? (VPC Endpoints for S3/DynamoDB)
- [ ] Bastion host vs NAT Gateway — what does each solve?
