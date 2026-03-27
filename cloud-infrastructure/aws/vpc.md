# AWS VPC — Complete Reference

---

## 1. What is a VPC?

A **Virtual Private Cloud (VPC)** is a logically isolated virtual network inside
AWS where you launch and control your resources. It is part of the AWS public cloud
infrastructure — "private" means your network is **logically separated** from all
other AWS customers, not physically isolated.

```
AWS Region
  └── Your VPC (logically isolated network)
        ├── Your EC2 instances
        ├── Your databases
        └── Your load balancers
```

> You control: IP ranges, subnets, routing, gateways, and security.

---

## 2. VPC Scope & Limits

| Property | Detail |
|----------|--------|
| Scope | **Regional** — spans all AZs in a Region |
| Default VPC | One per Region — auto-created by AWS |
| VPCs per Region | 5 (default, can request increase) |
| CIDR block size | Minimum **/28** (16 IPs), Maximum **/16** (65,536 IPs) |
| Secondary CIDRs | Up to 4 additional IPv4 CIDR blocks per VPC |
| IPv6 | Supported — AWS assigns /56 block; subnets get /64 |
| Default VPC CIDR | `172.31.0.0/16` (same in every Region) |

---

## 3. CIDR & IP Address Math ⭐

### IP Calculation Formula

```
Host bits  = 32 − prefix length
Total IPs  = 2^(host bits)
Usable IPs = Total IPs − 5        (AWS reserves 5 per subnet)
```

| Prefix | Host Bits | Total IPs | AWS Reserved | Usable IPs |
|--------|----------|-----------|-------------|-----------|
| /28 | 4 | 16 | 5 | **11** |
| /27 | 5 | 32 | 5 | **27** |
| /26 | 6 | 64 | 5 | **59** |
| /24 | 8 | 256 | 5 | **251** |
| /20 | 12 | 4,096 | 5 | **4,091** |
| /16 | 16 | 65,536 | 5 | **65,531** |

---

### AWS's 5 Reserved IPs Per Subnet ⭐

For any subnet (example: `10.0.1.0/24`):

| Address | Reserved for |
|---------|-------------|
| `10.0.1.0` | Network address (identifies the subnet) |
| `10.0.1.1` | VPC router (default gateway) |
| `10.0.1.2` | AWS DNS server |
| `10.0.1.3` | Reserved for future AWS use |
| `10.0.1.255` | Broadcast address (AWS doesn't use broadcast, but reserves it) |

> Traditional networking reserves 2 (network + broadcast).
> AWS reserves **5** — remember this for any exam capacity question.

---

### Number of Subnets Formula

```
Subnets = 2^(new prefix − original VPC prefix)
```

**Example:** VPC `/16`, subnet `/20`:
```
2^(20 − 16) = 2^4 = 16 subnets possible
Each /20 has 4,096 IPs (4,091 usable)
```

---

## 4. Private IP Ranges (RFC 1918)

| Class | Range | Common VPC Use |
|-------|-------|----------------|
| A | 10.0.0.0 – 10.255.255.255 | Large enterprise VPCs |
| B | 172.16.0.0 – 172.31.255.255 | AWS default VPC uses 172.31.0.0/16 |
| C | 192.168.0.0 – 192.168.255.255 | Smaller VPCs |

> **Rule:** Always use private IP ranges in VPC CIDR. Public IPs in CIDR
> would conflict with internet routing.

---

## 5. VPC Components — Full Map

```
VPC (Regional)
  ├── Subnets (AZ-specific)
  ├── Internet Gateway (IGW)
  ├── NAT Gateway
  ├── Route Tables
  ├── Security Groups
  ├── Network ACLs (NACL)
  ├── VPC Endpoints
  ├── VPC Peering
  ├── VPN Gateway
  └── Flow Logs
```

---

## 6. Subnets ⭐

**Scope:** One AZ — cannot span multiple AZs.

| Type | Internet Access | Use Case |
|------|----------------|---------|
| **Public** | ✅ Direct — has route to IGW | Web servers, load balancers, bastion hosts |
| **Private** | ❌ No direct — uses NAT Gateway for outbound | App servers, databases, internal services |

### Public vs Private — What Makes a Subnet Public?

```
A subnet is "public" if and only if:
  1. It has a route: 0.0.0.0/0 → Internet Gateway
  2. Resources have a public IP (auto-assign enabled OR Elastic IP)
```

> There is no "public" checkbox on a subnet. It's purely about routing.

### Auto-Assign Public IP

| VPC Type | Auto-assign Public IP default |
|---------|------------------------------|
| Default VPC | ✅ Enabled |
| Custom VPC | ❌ Disabled — must enable per subnet |

---

## 7. Internet Gateway (IGW) ⭐

Enables bidirectional internet access for resources in **public subnets**.

| Property | Detail |
|----------|--------|
| Type | Horizontally scaled, redundant, HA — no bandwidth bottleneck |
| Attachment | **One IGW per VPC** |
| Cost | Free — no charge for the IGW itself (data transfer costs apply) |
| Direction | Inbound + outbound (bidirectional) |
| Requires | Route table entry: `0.0.0.0/0 → igw-xxxxxxxx` |

```
EC2 (public subnet)
   → Route Table: 0.0.0.0/0 → IGW
   → IGW performs NAT: private IP ↔ public IP
   → Internet
```

> IGW also performs **one-to-one NAT** — maps private IP of EC2 to its
> public/Elastic IP for internet communication.

---

## 8. NAT Gateway ⭐

Allows **private subnet instances to initiate outbound internet connections**
(e.g., download updates, call external APIs) — but blocks all inbound connections
from the internet.

| Property | Detail |
|----------|--------|
| Placement | Must be in a **public subnet** |
| Requires | Elastic IP attached |
| Direction | Outbound only (private → internet) — not inbound |
| HA | Single AZ — for HA, deploy one NAT GW **per AZ** |
| Managed | AWS-managed — no patching needed |
| Cost | Per hour + per GB processed |

### NAT Gateway vs NAT Instance

| Feature | NAT Gateway | NAT Instance |
|---------|------------|-------------|
| Managed by | AWS | You |
| Availability | Highly available in AZ | Single instance — SPOF |
| Bandwidth | Up to 100 Gbps | Limited by instance type |
| Source/Dest check | Handled automatically | Must disable manually |
| Security Groups | Cannot attach | Can attach |
| Cost | Higher | Lower (but operational overhead) |
| Use today | ✅ Recommended | Legacy only |

### Traffic Flow: Private Subnet → Internet

```
Private EC2
  → Private Route Table: 0.0.0.0/0 → NAT Gateway (in public subnet)
  → NAT Gateway → Route Table: 0.0.0.0/0 → IGW
  → Internet
  → Response returns via NAT Gateway → Private EC2
(Internet never initiates connection to private EC2 ✅)
```

---

## 9. Route Tables ⭐

Controls **where traffic is directed** based on destination IP.

### How Routing Works

Every route table has entries:

| Destination | Target | Meaning |
|-------------|--------|---------|
| `10.0.0.0/16` | `local` | Stay inside VPC (auto-created) |
| `0.0.0.0/0` | `igw-xxxxxxxx` | Default route to internet (public subnet) |
| `0.0.0.0/0` | `nat-xxxxxxxx` | Default route via NAT (private subnet) |

> **Longest prefix match** wins: more specific route = higher priority.
> `10.0.1.0/24` beats `10.0.0.0/16` for traffic to `10.0.1.5`.

### Route Table Association

```
Each subnet must be associated with exactly ONE route table.
One route table can serve multiple subnets.

Default (main) route table: auto-associated with any subnet
  that doesn't have an explicit association.
```

### Public vs Private Route Table

```
Public Route Table:
  Destination        Target
  10.0.0.0/16   →   local
  0.0.0.0/0     →   igw-xxxxxxxx   ← makes it public

Private Route Table:
  Destination        Target
  10.0.0.0/16   →   local
  0.0.0.0/0     →   nat-xxxxxxxx   ← outbound via NAT
```

---

## 10. Auto-Created Components When VPC Is Created

| Component | Auto-created | Properties |
|-----------|-------------|-----------|
| **Main Route Table** | ✅ Yes | Contains only `local` route — no internet |
| **Default Security Group** | ✅ Yes | Inbound: same SG only; Outbound: all |
| **Default NACL** | ✅ Yes | Inbound: allow all; Outbound: allow all |
| **DHCP Options Set** | ✅ Yes | DNS settings for the VPC |
| **Subnets** | ❌ No (custom VPC) | Must create manually |
| **Internet Gateway** | ❌ No | Must create and attach manually |
| **NAT Gateway** | ❌ No | Must create in public subnet manually |

> **Default VPC only:** comes with subnets, IGW, and routes pre-configured —
> ready to use immediately. Custom VPCs start bare.

---

## 11. VPC Peering ⭐

Connects two VPCs using AWS private network — traffic never traverses the internet.

```
VPC A (10.0.0.0/16) ←──── Peering ────→ VPC B (10.1.0.0/16)
```

| Property | Detail |
|----------|--------|
| Same Region | ✅ Supported |
| Cross-Region | ✅ Supported |
| Cross-Account | ✅ Supported |
| Cost | Cross-Region peering: data transfer charges apply |
| DNS | Must enable DNS resolution on both sides to resolve private hostnames |
| Max peering per VPC | 125 (default 50, can increase to 125) |

### Critical Limitations

**1. No Overlapping CIDRs:**
```
VPC A: 10.0.0.0/16
VPC B: 10.0.0.0/24   ← OVERLAP → peering not allowed ❌
VPC B: 10.1.0.0/16   ← no overlap → allowed ✅
```

**2. No Transitive Peering:**
```
VPC A ─── peered ──→ VPC B
VPC A ─── peered ──→ VPC C

VPC B CANNOT reach VPC C through VPC A ❌
Must create direct B ↔ C peering for that ✅
```

**3. Route tables must be updated manually:**
```
VPC A route table: add 10.1.0.0/16 → pcx-xxxxxxxx (peering connection)
VPC B route table: add 10.0.0.0/16 → pcx-xxxxxxxx
```

---

## 12. Transit Gateway

When you have many VPCs, peering becomes unmanageable — N×(N-1)/2 connections.

```
10 VPCs via peering = 45 peering connections ❌ complex
10 VPCs via Transit Gateway = 10 attachments ✅ hub-and-spoke
```

| Feature | VPC Peering | Transit Gateway |
|---------|------------|----------------|
| Transitive routing | ❌ No | ✅ Yes |
| Scale | Up to 125 peers/VPC | Thousands of VPCs |
| Cross-Region | ✅ Yes | ✅ Yes |
| Cross-Account | ✅ Yes | ✅ Yes |
| On-premises (VPN/DX) | ❌ No | ✅ Yes (unified hub) |
| Cost | Lower for few VPCs | Higher (per attachment + data) |

> Use **VPC Peering** for ≤ a few VPC connections.
> Use **Transit Gateway** as a centralized hub for 5+ VPCs or hybrid networks.

---

## 13. VPC Endpoints

Access AWS services (S3, DynamoDB, etc.) from private subnets **without going through the internet** — traffic stays on AWS private network.

| Type | How | Supported Services |
|------|-----|-------------------|
| **Gateway Endpoint** | Route table entry | S3 and DynamoDB only |
| **Interface Endpoint** (PrivateLink) | ENI with private IP in subnet | 100+ AWS services (SQS, SNS, API Gateway, etc.) |

```
Without endpoint:
  Private EC2 → NAT Gateway → Internet → S3 (public API)
  Cost: NAT Gateway data processing + transfer

With Gateway Endpoint:
  Private EC2 → VPC Gateway Endpoint → S3 (private)
  Cost: Free for Gateway Endpoint ✅
```

> **Gateway Endpoints are free** — always use them for S3 and DynamoDB from private subnets.

---

## 14. VPC DNS Settings

Two VPC-level settings control DNS behavior:

| Setting | Default | What It Does |
|---------|---------|-------------|
| `enableDnsSupport` | ✅ Enabled | Enables AWS DNS resolver (169.254.169.253) |
| `enableDnsHostnames` | ❌ Disabled (custom VPC) | Assigns public DNS hostnames to instances with public IPs |

> Both must be enabled for VPC Peering to resolve private DNS hostnames.
> Default VPC has both enabled.

---

## 15. VPC Flow Logs

Captures metadata about IP traffic in/out of VPCs, subnets, and ENIs.

| Level | Captures |
|-------|---------|
| VPC level | All traffic in the VPC |
| Subnet level | All traffic in one subnet |
| ENI level | Traffic for one network interface |

**Destinations:** CloudWatch Logs, S3, Kinesis Data Firehose

**Use for:** Security analysis, troubleshooting, compliance, detecting port scans.

```
Flow log record format:
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
```

---

## 16. VPC Tenancy

| Tenancy | Hardware | Cost |
|---------|---------|------|
| **Default** | Shared — multi-tenant | Standard pricing |
| **Dedicated** | All instances on dedicated hardware | +$2/hr per active Region + per-instance premium |

> VPC-level tenancy = default for all instances launched in it.
> Can override per instance if VPC is `default` tenancy.
> Cannot change VPC tenancy from `dedicated` to `default`.

---

## 17. Full VPC Architecture — 3-Tier App

```
Region: ap-south-1
│
└── VPC: 10.0.0.0/16
      │
      ├── Public Subnet: 10.0.1.0/24 (AZ-1a)
      │     ├── Route Table: 10.0.0.0/16 → local, 0.0.0.0/0 → IGW
      │     ├── ALB (Application Load Balancer)
      │     └── NAT Gateway (+ Elastic IP)
      │
      ├── Private Subnet: 10.0.2.0/24 (AZ-1a)
      │     ├── Route Table: 10.0.0.0/16 → local, 0.0.0.0/0 → NAT GW
      │     └── App Servers (EC2)
      │
      ├── Private Subnet: 10.0.3.0/24 (AZ-1b)  ← second AZ for HA
      │     └── App Servers (EC2)
      │
      └── DB Subnet: 10.0.4.0/24 (AZ-1a + 1b)
            ├── Route Table: 10.0.0.0/16 → local (no internet)
            └── RDS (Multi-AZ)
      │
      └── Internet Gateway (attached to VPC)
```

---

## 18. Step-by-Step: Build a Working VPC

```
1. Create VPC             → define CIDR (10.0.0.0/16)
2. Create Subnets         → public + private, in different AZs
3. Create IGW             → attach to VPC
4. Create NAT Gateway     → place in public subnet, assign EIP
5. Update Route Tables    → public: add 0.0.0.0/0 → IGW
                            private: add 0.0.0.0/0 → NAT GW
6. Configure NACLs        → subnet-level firewall rules
7. Configure SGs          → instance-level firewall rules
8. Launch EC2             → into correct subnet
```

---

## 19. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| VPC spans one AZ | VPC is **Regional** — spans all AZs; subnets are AZ-specific |
| Making subnet "public" via a setting | Public = subnet has route to IGW + instances have public IPs |
| NAT Gateway placed in private subnet | NAT Gateway must be in a **public subnet** |
| One NAT Gateway is HA | NAT Gateway is AZ-specific — deploy one per AZ for HA |
| VPC Peering supports transitive routing | No — A↔B, A↔C does NOT give B↔C access |
| Overlapping CIDRs can be peered | Overlapping CIDRs make peering impossible |
| Route table auto-updated for peering | Must manually add routes on **both** sides |
| Gateway Endpoint has a cost | S3 and DynamoDB Gateway Endpoints are **free** |
| AWS reserves 2 IPs per subnet | AWS reserves **5** (not 2 like traditional networking) |
| Custom VPC comes with subnets | Custom VPC has no subnets — must create manually |
| IGW supports multiple VPCs | **One IGW per VPC** — cannot attach same IGW to multiple VPCs |

---

## 20. Interview Questions Checklist

- [ ] What is a VPC? What does "private" mean in VPC context?
- [ ] What is the scope of a VPC — Region or AZ?
- [ ] What is the scope of a subnet — Region or AZ?
- [ ] What CIDR sizes can a VPC have? (/28 to /16)
- [ ] How many IPs does AWS reserve per subnet? Name all 5.
- [ ] Calculate usable IPs for a /24 subnet (251)
- [ ] How many subnets can you create from a /16 VPC using /20 subnets? (16)
- [ ] What makes a subnet "public"?
- [ ] Default VPC vs Custom VPC — key differences?
- [ ] What is an Internet Gateway? How many per VPC?
- [ ] What is a NAT Gateway? Where must it be placed?
- [ ] NAT Gateway vs NAT Instance — key differences?
- [ ] What auto-created resources does a new VPC include?
- [ ] What is a Route Table? How does longest-prefix match work?
- [ ] What are the two critical VPC Peering limitations? (no overlap, no transitive)
- [ ] How do you enable B↔C communication when only A↔B and A↔C are peered?
- [ ] VPC Peering vs Transit Gateway — when to use which?
- [ ] What is a VPC Endpoint? Gateway vs Interface?
- [ ] Which services does a Gateway Endpoint support? (S3, DynamoDB)
- [ ] What are VPC Flow Logs? What do they capture?
- [ ] What are enableDnsSupport and enableDnsHostnames?
- [ ] What is VPC tenancy? Default vs Dedicated?
