# EC2 Pricing Models — Complete Reference

---

## 1. Why Pricing Models Matter

AWS EC2 has multiple pricing models because workloads are not all the same.
Choosing the wrong model = paying 3–10× more than necessary.

> **Core principle:** Match the pricing model to workload behavior —
> not just to the cheapest price tag.

---

## 2. Billing Granularity ⭐ (Corrected)

| OS | Billing Unit | Minimum |
|----|-------------|---------|
| Amazon Linux | Per second | 60 seconds |
| Ubuntu / Ubuntu Pro | Per second | 60 seconds |
| Windows Server | Per second | 60 seconds |
| RHEL, SLES | Per second | 60 seconds |
| Other commercial UNIX | Per full hour | 1 hour |

> **Practical impact:** A Linux/Windows instance running for 3 min 15 sec
> = billed for exactly 195 seconds — not 4 minutes, not 1 hour.
>
> **Windows is more expensive** than Linux — not because of billing granularity,
> but because of the **Microsoft license cost** embedded in the per-second rate.

---

## 3. Complete Pricing Models Overview

| Model | Discount vs On-Demand | Commitment | Interruptible |
|-------|----------------------|-----------|---------------|
| **On-Demand** | None (baseline price) | None | No |
| **Spot** | Up to 90% | None | ✅ Yes — AWS can reclaim |
| **Savings Plans** | Up to 72% | 1 or 3 years ($/hr spend) | No |
| **Reserved Instances** | Up to 72% | 1 or 3 years (specific instance) | No |
| **Dedicated Instances** | Premium over On-Demand | None | No |
| **Dedicated Hosts** | On-Demand or RI pricing | Optional | No |
| **Capacity Reservations** | None (On-Demand rate) | None | No |

---

## 4. On-Demand Instances

Pay for compute by the second. No commitment, no discount.

**Characteristics:**
- No upfront payment
- No minimum duration (beyond 60-second minimum billing)
- Full flexibility — launch/stop/terminate anytime
- Highest per-hour cost of all models

**Use when:**
- Load is unknown or unpredictable
- Short-term or temporary workloads
- Dev/test environments
- First-time running a new workload (before you know its pattern)

**Engineering rule:**
```
Flexibility needed > Cost savings → On-Demand
```

---

## 5. Reserved Instances (RI)

Commitment to a specific EC2 configuration for 1 or 3 years in exchange for discount.

### 5.1 RI Scope — Regional vs Zonal ⭐ (Often Missed)

| Scope | Capacity Reservation | AZ Flexibility | Instance Size Flexibility |
|-------|---------------------|----------------|--------------------------|
| **Regional** | ❌ No guaranteed capacity | ✅ Any AZ in Region | ✅ Flexible within family |
| **Zonal** | ✅ Capacity reserved in that AZ | ❌ Fixed to one AZ | ❌ Fixed to specific size |

> Regional RI gives more flexibility.
> Zonal RI guarantees actual capacity — useful for critical workloads.

### 5.2 Offering Class

| Class | Discount | Flexibility | Can Sell on Marketplace |
|-------|---------|------------|------------------------|
| **Standard** | Up to 72% | Fixed: family, Region, OS | ✅ Yes |
| **Convertible** | Up to 54% | Can change: family, OS, tenancy, Region | ❌ No |

> Standard RI = maximum savings, minimum flexibility.
> Convertible RI = lower savings, but you can exchange it if workload changes.

### 5.3 Payment Options

| Payment | Discount Level |
|---------|---------------|
| **All Upfront** | Maximum discount |
| **Partial Upfront** | Medium discount |
| **No Upfront** | Minimum discount |

> Pay more upfront → save more over the term.

### 5.4 RI Marketplace

Unused Standard RIs can be **sold to other AWS accounts** via the RI Marketplace —
a way to recover cost if your workload changed unexpectedly.

**Use when:**
- Workload is stable and predictable
- Long-running baseline infrastructure (databases, app servers)
- Cost optimization is a priority and usage is known 1–3 years ahead

---

## 6. Savings Plans (Modern, Flexible Alternative)

Commit to a **minimum hourly spend ($/hr)** for 1 or 3 years.
AWS automatically applies discount to any eligible usage up to that committed amount.

### 6.1 Types of Savings Plans ⭐ (4 Types — Not 2 or 3)

| Type | Covers | Max Discount | Flexibility |
|------|--------|-------------|------------|
| **Compute Savings Plan** | EC2 + Fargate + Lambda | Up to 66% | Any family, Region, OS, size, tenancy |
| **EC2 Instance Savings Plan** | EC2 only (specific family + Region) | Up to 72% | Flexible size + OS within that family |
| **SageMaker AI Savings Plan** | SageMaker services only | Up to 64% | SageMaker only |
| **Database Savings Plan** | RDS, Aurora, Redshift | Up to 60% | Database services only |

> AWS officially has **four** Savings Plan types as of 2025.

### 6.2 Compute vs EC2 Instance Savings Plan — Decision Guide

```
Are you running Lambda or Fargate alongside EC2?
    YES → Compute Savings Plan (covers all three)
    NO  → EC2 Instance Savings Plan (higher discount for pure EC2)

Are you locked into one instance family and Region?
    YES → EC2 Instance Savings Plan (up to 72%)
    NO  → Compute Savings Plan (up to 66%, full flexibility)
```

**Key difference in numbers:**
```
Workload: $10,000/month EC2 spend
Compute SP (66%):       → ~$3,400/month
EC2 Instance SP (72%):  → ~$2,800/month (if all in one family+Region)
Over 3 years:           → $21,600 difference
```

**Use when:**
- You have a predictable minimum monthly compute spend
- You want flexibility across instance families (Compute SP)
- You're fully committed to one EC2 family and Region (EC2 SP)

---

## 7. Spot Instances ⭐

Unused AWS capacity sold at up to 90% discount. AWS can reclaim at any time.

**How it works:**
```
AWS has spare capacity in a pool (specific instance type + AZ)
You bid for that capacity
AWS gives it to you while available
If AWS needs it back → 2-minute interruption notice → instance terminated
```

**Key rules:**
- Up to **90% cheaper** than On-Demand
- **2-minute warning** before termination (via instance metadata + EventBridge)
- Not available on-demand — depends on Region, AZ, and current demand
- Cannot be converted to other pricing models

### 7.1 Spot Fleet

Request Spot capacity across **multiple instance types and AZs** in one request.

```
Spot Fleet Config:
  - c5.xlarge in us-east-1a
  - c5a.xlarge in us-east-1b
  - m5.xlarge in us-east-1a
  ...
```

Fleet uses **allocation strategies** to pick instances:

| Strategy | Behavior |
|---------|---------|
| **price-capacity-optimized** ✅ Recommended | Balances lowest price + highest availability pool |
| **capacity-optimized** | Picks pool with most available capacity (lowest interruption risk) |
| **lowest-price** | Picks cheapest pool (higher interruption risk) |
| **diversified** | Spreads across all pools |

### 7.2 EC2 Fleet

Like Spot Fleet but supports mixed On-Demand + Spot + Reserved in a single request.
Useful for auto-scaling groups that need guaranteed baseline + cheap burst.

**Use Spot when:**
- Workload is fault-tolerant and stateless
- Can checkpoint and resume (ML training, batch jobs)
- Interruption = acceptable delay, not data loss

**DO NOT use Spot for:**
- Databases
- Session-critical applications
- Any workload requiring guaranteed availability

---

## 8. Capacity Reservations

Reserve EC2 capacity in a **specific AZ**, billed at On-Demand rate — no discount.

**Key property:** Guarantees capacity exists when you need it.

| Feature | RI | Capacity Reservation |
|---------|----|---------------------|
| Discount | ✅ Yes | ❌ No (On-Demand rate) |
| Capacity guarantee | ❌ Regional RI does not | ✅ Yes |
| Time commitment | ✅ 1 or 3 years | ❌ None — cancel anytime |
| AZ specific | Zonal RI only | ✅ Always |

**Combining for best of both:**
```
Capacity Reservation (guarantees the slot)
+
Regional RI or Savings Plan (applies discount to the billing)
= Guaranteed capacity + discounted price ✅
```

**Use when:**
- Critical event with known capacity requirement (Black Friday, product launch)
- Compliance requires guaranteed compute in specific AZ
- Disaster recovery standby capacity

---

## 9. Dedicated Instances

Instances that run on hardware **dedicated to your AWS account** — no other customer
shares the physical host.

- AWS controls which physical machine is used
- You have no visibility into cores, sockets, or host configuration
- Priced at a premium over standard On-Demand

**Use when:** Compliance or regulation requires single-tenant hardware.

---

## 10. Dedicated Hosts

A **full physical server** allocated exclusively to you.

| Feature | Dedicated Instance | Dedicated Host |
|---------|--------------------|----------------|
| Physical isolation | Logical only | ✅ Full physical server |
| Hardware visibility | ❌ No | ✅ Sockets, cores, IDs |
| BYOL support | Limited | ✅ Full (Oracle, SQL Server, VMware) |
| Instance placement control | ❌ No | ✅ Yes |
| Pricing | Per instance | Per host/hour |

**Use when:**
- Bring Your Own License (BYOL) — Microsoft, Oracle, VMware require per-core licensing
- Security audits require physical server visibility
- Regulatory mandates full hardware isolation

---

## 11. Tenancy Summary

| Tenancy | Hardware Sharing | Your Control | Cost |
|---------|----------------|-------------|------|
| **Shared** (default) | Multiple accounts share host | None | Standard |
| **Dedicated Instance** | Only your account on host | Limited | +10% premium |
| **Dedicated Host** | Entire physical server for you | Full | Highest |

---

## 12. EC2 Status Checks ⭐

AWS runs automated health checks every minute:

| Check | What It Tests | Failure Means |
|-------|-------------|---------------|
| **System Status Check** | Underlying AWS hardware + hypervisor | AWS infrastructure problem — AWS must fix |
| **Instance Status Check** | OS networking, software config | Your problem — reboot or fix the OS |
| **EBS Status Check** | Attached EBS volume reachability | Storage issue — check volume or replace |

**Actions on failure:**
- System check failure → trigger **instance recovery** (moves to healthy host, same IP, EBS preserved)
- Instance check failure → you must investigate (OS crash, OOM, disk full, misconfig)

```bash
# Check status via CLI
aws ec2 describe-instance-status --instance-ids i-xxxxxxxxxxxxxxxxx
```

---

## 13. Connection Methods

| OS | Protocol | Credential | Port |
|----|---------|-----------|------|
| **Linux** | SSH | Key pair `.pem` file | 22 |
| **Windows** | RDP | Password (decrypted with key pair) | 3389 |
| **Any OS** | AWS Systems Manager Session Manager | IAM role (no key pair needed) | None (uses SSM agent) |

> **Session Manager** (SSM) is the modern approach — no key pairs, no open ports,
> full audit trail via CloudTrail. Preferred for production.

---

## 14. Instance Identification

| Identifier | Format | Mutable |
|-----------|--------|---------|
| **Instance ID** | `i-` + 17 hex chars (e.g. `i-0a1b2c3d4e5f6789a`) | ❌ Permanent |
| **Instance Name** | User-defined tag (`Name` key) | ✅ Changeable |
| **Private IP** | Stays same for instance lifetime | ❌ Fixed while running |
| **Public IP** | Changes on every stop/start | ❌ Dynamic (use Elastic IP to fix) |

---

## 15. Cost Optimization Decision Framework

```
Step 1 — Is the workload interruptible?
    YES → Spot Instances (up to 90% off)
    NO  → continue to Step 2

Step 2 — Is usage predictable / long-term?
    NO  → On-Demand
    YES → continue to Step 3

Step 3 — Is it EC2-only or multi-service (Lambda/Fargate too)?
    EC2 only, single family → EC2 Instance Savings Plan (up to 72%)
    Multi-service or need flexibility → Compute Savings Plan (up to 66%)
    Need exact capacity guarantee → Capacity Reservation + Savings Plan

Step 4 — Does it need physical isolation?
    BYOL / license control → Dedicated Host
    Compliance only → Dedicated Instance
    Standard workload → Shared (default)
```

### Scenario → Model Mapping

| Scenario | Best Model |
|---------|-----------|
| Unknown traffic, new app | On-Demand |
| Dev/test environment | On-Demand or Spot |
| Batch processing, CI/CD | Spot |
| ML training job | Spot (with checkpointing) |
| Production database (stable) | Reserved Instance (Standard, 1–3yr) |
| Mixed EC2 + Lambda workload | Compute Savings Plan |
| Pure EC2, predictable family | EC2 Instance Savings Plan |
| Black Friday / known event | Capacity Reservation + Savings Plan |
| BYOL Oracle / SQL Server | Dedicated Host |
| Compliance, no shared hardware | Dedicated Instance |

---

## 16. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Windows billed per hour | Both Linux and Windows billed per second (60s min) |
| Savings Plans have 2 types | AWS has 4 Savings Plan types (Compute, EC2, SageMaker, Database) |
| RI guarantees capacity | Only Zonal RI reserves capacity; Regional RI does not |
| Spot Blocks still available | AWS deprecated Spot Blocks in Dec 2021 — use Spot Fleet instead |
| Dedicated Instance = Dedicated Host | Dedicated Instance = logical isolation; Host = full physical control |
| Capacity Reservation gives discount | No discount — billed at On-Demand rate; purpose is capacity guarantee |
| Convertible RI can be sold | Only Standard RI can be sold on RI Marketplace |
| All Upfront = same as No Upfront | All Upfront = maximum discount; No Upfront = minimum discount |
| Savings Plan replaces RI entirely | Both coexist; RI is still valid, especially Zonal RI for capacity |

---

## 17. Interview Questions Checklist ✅

- [ ] Name all EC2 pricing models
- [ ] What is the billing granularity for Linux? Windows? (per second — 60s min)
- [ ] On-Demand vs Reserved vs Savings Plans — when to use each?
- [ ] Standard RI vs Convertible RI — key differences?
- [ ] Regional RI vs Zonal RI — which one guarantees capacity?
- [ ] What are the 4 types of Savings Plans?
- [ ] Compute Savings Plan vs EC2 Instance Savings Plan — when to choose each?
- [ ] How does Spot Instance interruption work? How much warning?
- [ ] What is Spot Fleet? What allocation strategies are available?
- [ ] What is EC2 Fleet?
- [ ] What is a Capacity Reservation? Does it give a discount?
- [ ] How do you combine Capacity Reservation with Savings Plans?
- [ ] Dedicated Instance vs Dedicated Host — key differences?
- [ ] What is BYOL and which tenancy model supports it?
- [ ] What are the 3 EC2 status checks? Who fixes each failure type?
- [ ] How do you connect to a Linux EC2? Windows EC2?
- [ ] What is SSM Session Manager? Why is it better than SSH in production?
- [ ] Instance ID vs Instance Name — which can change?
- [ ] Walk through the cost optimization decision framework
