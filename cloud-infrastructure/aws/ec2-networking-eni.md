# EC2 Networking — ENI, IPs, Elastic IP

---

## 1. NIC → ENI: Physical to Virtual

In a physical server, a **Network Interface Card (NIC)** is the hardware component
that connects the machine to the network — it owns the MAC address, sends and
receives packets, and is the actual point of connectivity.

In EC2, there is no physical NIC. AWS virtualizes this as an
**ENI (Elastic Network Interface)** — the virtual NIC.

```
Physical World          AWS EC2
──────────────    →    ──────────────
NIC (hardware)          ENI (virtual)
MAC address             MAC address
IP address(es)          Private IP(s)
Network port            Subnet + SG
```

> **Core rule:** EC2 does NOT directly own IPs or a MAC address.
> The **ENI owns them**. EC2 uses them through the ENI.

---

## 2. ENI — Complete Component Map

Every ENI contains:

| Component | Detail |
|-----------|--------|
| **Primary private IPv4** | Assigned from subnet CIDR — cannot be changed |
| **Secondary private IPv4(s)** | Optional — multiple allowed per ENI |
| **Public IPv4** | Auto-assigned if subnet enables it — dynamic |
| **Elastic IP (EIP)** | Optional static public IP — 1 EIP per private IP |
| **MAC address** | Unique per ENI — persists through instance lifecycle |
| **Security Groups** | Attached at ENI level (not instance level) |
| **Subnet** | ENI belongs to one subnet → one AZ |
| **Source/Dest Check** | On by default — see Section 9 |
| **Description / tags** | Metadata for identification |

---

## 3. Primary ENI (eth0)

Every EC2 instance has one **primary ENI** created automatically at launch.

| Property | Behavior |
|----------|---------|
| Device index | Always **0** |
| Detachable | ❌ Cannot be detached while instance is running or stopped |
| Deleted on terminate | ✅ Yes — by default |
| Created from | Subnet + Security Group selected during launch |

---

## 4. Secondary ENIs

You can attach **additional ENIs** to an instance — subject to per-instance limits.

### Attachment Rules

| Rule | Detail |
|------|--------|
| AZ requirement | Must be in the **same AZ** as the instance |
| Subnet | Each ENI can be in a different subnet (but same AZ) |
| Hot attach | ✅ Can attach/detach while instance is **running** |
| Primary ENI | ❌ Cannot detach eth0 |
| Termination | Secondary ENIs are **not deleted** on termination by default |

### ENI Limits Per Instance Type

The number of ENIs (and IPs per ENI) you can attach **depends on instance type**:

| Instance Type | Max ENIs | Max Private IPs per ENI |
|--------------|---------|------------------------|
| `t3.micro` | 2 | 2 |
| `t3.medium` | 3 | 6 |
| `m5.large` | 3 | 10 |
| `m5.4xlarge` | 8 | 30 |
| `c5.18xlarge` | 15 | 50 |

> **Rule:** Larger instance = more ENIs + more IPs per ENI.
> Check: `aws ec2 describe-instance-types --instance-types m5.large`

---

## 5. IP Types — Complete Breakdown ⭐

### Private IPv4

| Property | Behavior |
|----------|---------|
| Source | Assigned from subnet CIDR range via AWS-managed DHCP |
| Primary IP | Cannot be changed — fixed for instance lifetime |
| Secondary IPs | Can be assigned/unassigned on live ENI |
| On reboot | ✅ Stays the same |
| On stop → start | ✅ Stays the same |
| On terminate | ❌ Released — gone |

### Public IPv4 (Auto-assigned)

| Property | Behavior |
|----------|---------|
| Source | AWS public IP pool |
| On reboot | ✅ Stays the same |
| On stop → start | ❌ **Released — new IP assigned** |
| On hibernate | ❌ Released |
| On terminate | ❌ Released |
| Predictable? | ❌ No — changes unless you use Elastic IP |

### IPv4 Behavior Summary

| Action | Private IP | Public IP | Elastic IP |
|--------|-----------|-----------|-----------|
| Reboot | ✅ Same | ✅ Same | ✅ Same |
| Stop → Start | ✅ Same | ❌ Changes | ✅ Same |
| Hibernate | ✅ Same | ❌ Released | ✅ Same |
| Terminate | ❌ Gone | ❌ Gone | ✅ Stays in account |

---

## 6. Multiple Private IPs — Why It Matters

One ENI can hold multiple private IPs. This enables:

| Use Case | How |
|---------|-----|
| **Multiple websites** on one instance | Each site gets its own private IP + EIP |
| **Container workloads** (EKS, ECS) | Each pod/container gets a private IP from the ENI |
| **Network appliances** (NAT, VPN, firewall) | Accept traffic destined for multiple IPs |
| **High availability failover** | Move secondary IP (or EIP) to standby instance |

### HA Failover Pattern (ENI Move)

```
Primary instance (eth1 ENI attached)
   → unhealthy
   ↓
Detach ENI from primary
   ↓
Attach ENI to standby instance
   ↓
DNS/EIP keeps pointing to same address ✅
```
> This is called **ENI-based failover** — entire network identity (IPs + MAC + SGs)
> moves to the standby instance in seconds.

---

## 7. Elastic IP (EIP)

### Definition
A **static public IPv4 address** you own in your AWS account — it never changes
until you explicitly release it.

### How It Works

```
Without EIP:
  Stop/Start → public IP changes → your DNS/app breaks

With EIP:
  EIP attached → same IP always → stable endpoint ✅
  Stop/Start → EIP stays on ENI → no change
```

### EIP Association Rules

| Can attach to | Detail |
|--------------|--------|
| ENI (preferred) | Attaches to a specific private IP on an ENI |
| EC2 instance directly | Actually attaches to the primary ENI under the hood |
| 1 EIP per private IP | Each private IP can have at most 1 EIP |

### Account Limits
- Default: **5 EIPs per Region per account**
- Can request increase via Service Quotas

---

## 8. IPv4 Pricing (CRITICAL UPDATE — Feb 2024) ⭐

**Before February 1, 2024:**
- Auto-assigned public IPs = FREE while attached
- EIP not attached to running instance = $0.005/hr (idle charge)

**After February 1, 2024 (current):**

| Address Type | Price/hr | Monthly (~730 hrs) |
|-------------|---------|-------------------|
| Any in-use public IPv4 (auto-assigned or EIP) | **$0.005** | **~$3.65** |
| EIP attached to stopped instance | $0.005 | ~$3.65 |
| EIP not attached to anything (idle) | $0.005 | ~$3.65 |
| BYOIP (Bring Your Own IP) | FREE | FREE |
| IPv6 | FREE | FREE |

> **Every public IPv4 address costs $0.005/hr regardless of state.**
> This applies to EC2, RDS, EKS nodes, Load Balancers, NAT Gateways — everything.
> **Free Tier:** 750 hours/month of public IPv4 for first 12 months.

### Why AWS made this change:
IPv4 addresses are globally scarce. AWS is pushing users toward IPv6.

### Cost Optimization Response:
```
Option 1 → Use IPv6 (free) for internal communication
Option 2 → Use private IPs + NAT Gateway for outbound internet
Option 3 → Share one public IP via Load Balancer instead of 1 IP per instance
Option 4 → Use VPN / Direct Connect for private access
```

---

## 9. Source/Destination Check ⭐

By default, AWS enforces a check on every ENI:

> "This ENI must be either the **source** or **destination** of all traffic it handles."

This is a security measure — prevents an instance from accidentally routing
traffic that doesn't belong to it.

**When to disable it:**
- **NAT Instance** — it forwards traffic from private subnet to internet
  (source = private instance, destination = internet — neither is the NAT instance itself)
- **VPN appliance** — forwards VPN-tunneled traffic
- **Network firewall / proxy** — inspects and forwards traffic for others

```bash
# Disable via CLI (required for NAT instances)
aws ec2 modify-network-interface-attribute \
  --network-interface-id eni-xxxxxxxx \
  --no-source-dest-check
```

---

## 10. ENI Interface Types ⭐

When creating an ENI, AWS offers different interface types:

| Type | Full Name | Use Case |
|------|-----------|---------|
| **ENA** | Elastic Network Adapter | Default for all modern EC2 — high throughput, low latency |
| **EFA** | Elastic Fabric Adapter | HPC workloads — MPI (Message Passing Interface), ML training |
| **EFA + ENA** | Both modes combined | HPC that also needs standard network traffic |

### ENA vs EFA — The Key Difference

| | ENA | EFA |
|--|-----|-----|
| Network path | Standard OS kernel networking | Bypasses kernel (OS-bypass) |
| Latency | Low (milliseconds) | Ultra-low (microseconds) |
| Use case | Any EC2 workload | HPC, tightly-coupled distributed computing |
| Protocol | TCP/UDP | libfabric (custom) |

> EFA is only useful when the **application is MPI-aware** (e.g. HPC scientific simulation,
> distributed ML training across many GPUs). Otherwise, ENA is the correct choice.

---

## 11. Security Groups at ENI Level ⭐

Security Groups are applied to **ENIs**, not to EC2 instances directly.

```
EC2 Instance
 ├── eth0 (primary ENI) → SG: allow HTTP/HTTPS (public traffic)
 └── eth1 (secondary ENI) → SG: allow DB port 5432 (private only)
```

**Why this matters:**
- One instance can have completely different security rules per ENI
- Useful for separating management traffic from application traffic
- Multiple SGs can be attached to one ENI (up to 5 by default)

---

## 12. Complete ENI Lifecycle

| Action | ENI | Private IP | Public IP | Elastic IP | MAC |
|--------|-----|-----------|-----------|-----------|-----|
| **Launch** | Created | Assigned | Assigned (if enabled) | If attached | Assigned |
| **Reboot** | Same | ✅ Same | ✅ Same | ✅ Same | ✅ Same |
| **Stop** | Same | ✅ Same | ❌ Released | ✅ Same | ✅ Same |
| **Start** | Same | ✅ Same | ❌ New IP | ✅ Same | ✅ Same |
| **Hibernate** | Same | ✅ Same | ❌ Released | ✅ Same | ✅ Same |
| **Terminate** | Deleted (primary) | ❌ Gone | ❌ Gone | ✅ Stays in account | Gone |
| **ENI detach** | Exists independently | ✅ Retained on ENI | — | ✅ Retained on ENI | ✅ Retained |

> **Key insight:** The ENI is the persistent identity.
> Detach an ENI → it retains its IPs, MAC, and SGs — ready to attach to another instance.

---

## 13. Architecture Patterns Using ENIs

### Pattern 1 — Dual-NIC Security Appliance
```
eth0 (ENA) → Public subnet → SG: allow HTTP/HTTPS
eth1 (ENA) → Private subnet → SG: allow all internal
Instance acts as: reverse proxy / WAF
```

### Pattern 2 — Management Network Separation
```
eth0 → Application traffic (public-facing)
eth1 → Management traffic (SSH, monitoring — restricted SG, private only)
```

### Pattern 3 — Container Networking (EKS/ECS)
```
EC2 Node (m5.large — 3 ENIs, 10 IPs each)
 ├── eth0 → Node's own IP (10.0.1.5)
 ├── eth1 → Pod IPs (10.0.1.20, 10.0.1.21, 10.0.1.22...)
 └── eth2 → More pod IPs (10.0.1.30, 10.0.1.31...)
```
> AWS VPC CNI plugin assigns pod IPs directly from the VPC CIDR — native VPC routing.

---

## 14. Final Mental Model

```
EC2 Instance (compute)
   └── eth0: Primary ENI (network identity)
         ├── Private IP: 10.0.1.5   (permanent)
         ├── Public IP: 54.x.x.x    (changes on stop/start)
         ├── Elastic IP: 13.x.x.x   (static, $0.005/hr)
         ├── MAC: 0a:1b:2c:3d:4e:5f (permanent per ENI)
         └── Security Group: sg-xxx  (firewall rules)

EC2 is just compute — ENI is the network identity.
```

---

## 15. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| EC2 owns the IP addresses | ENI owns IPs — EC2 uses them through ENI |
| EIP is free when attached | Since Feb 2024, ALL public IPv4 cost $0.005/hr — attached or not |
| Auto-assigned public IP is free | Also $0.005/hr since Feb 2024 |
| Private IP changes on stop/start | Private IP is stable — only public IP changes |
| Security Groups attach to EC2 | SGs attach to ENIs — EC2 can have different rules per interface |
| Primary ENI can be detached | Primary ENI (eth0) cannot be detached |
| Secondary ENI deleted on terminate | Secondary ENIs are NOT deleted on termination by default |
| EFA = just faster ENA | EFA bypasses the OS kernel entirely — completely different path |
| Source/Dest check can stay on for NAT | Must **disable** source/dest check on NAT instance ENI |

---

## 16. Interview Questions Checklist ✅

- [ ] What is an ENI? How does it relate to a NIC?
- [ ] Does EC2 own its IP addresses? (No — ENI does)
- [ ] What are the components of an ENI?
- [ ] What is the primary ENI (eth0)? Can it be detached?
- [ ] What happens to private IP on stop/start? (Stays same)
- [ ] What happens to public IP on stop/start? (Changes)
- [ ] What is an Elastic IP? How does it differ from auto-assigned public IP?
- [ ] How much does a public IPv4 address cost since Feb 2024? ($0.005/hr)
- [ ] What is the monthly cost of one public IPv4? (~$3.65/month)
- [ ] Why did AWS start charging for public IPv4? (IPv4 scarcity, push to IPv6)
- [ ] How many EIPs per Region by default? (5)
- [ ] What is Source/Destination Check? When must you disable it?
- [ ] What is ENA? What is EFA? Key difference?
- [ ] Why does EFA bypass the kernel? What does that enable?
- [ ] Can you attach an ENI to a running instance? (Yes — hot attach)
- [ ] What is ENI-based failover? How does it work?
- [ ] How does EKS use multiple private IPs per ENI?
- [ ] What is the max number of ENIs for a t3.micro? (2)
- [ ] Why does MAC address matter for software licensing? (Tied to ENI — survives stop/start)
