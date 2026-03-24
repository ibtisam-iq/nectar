# Amazon EC2 (Elastic Compute Cloud)

## 1. What is EC2?

Amazon EC2 provides **on-demand virtual servers** in the cloud with configurable CPU,
memory, storage, and networking. You pay only for what you run.

| Term | Definition |
|------|-----------|
| **EC2** | Elastic Compute Cloud — AWS's virtual server service |
| **Instance** | A single running virtual server |
| **Instance Type** | Full hardware configuration (CPU + RAM + network + storage) |
| **Instance Family** | Group of types with similar characteristics (same letter prefix) |
| **Instance Category** | High-level workload classification |
| **AMI** | Amazon Machine Image — template (OS + config) used to launch an instance |

---

## 2. Hierarchy

```
Instance Category
   └── Instance Family
         └── Instance Type (Generation + Processor + Capabilities)
               └── Instance Size
```

**Example mapping:**
```
Compute Optimized
   └── c (family)
         └── c7g (7th gen, Graviton)
               └── c7g.xlarge
```

---

## 3. Instance Categories

| Category | Use Case | Key Families |
|----------|---------|-------------|
| **General Purpose** | Balanced CPU + memory — web apps, APIs, small DBs | t, m |
| **Compute Optimized** | CPU-intensive — batch, video encoding, gaming servers | c |
| **Memory Optimized** | RAM-heavy — Redis, large DBs, in-memory analytics | r, x, u |
| **Storage Optimized** | High IOPS, low-latency disk — NoSQL, data warehouses | i, d, h |
| **Accelerated Computing** | GPU/ML/FPGA — AI training, graphics, inference | p, g, f, inf, trn |
| **High Performance Computing** | Scientific simulations, fluid dynamics | hpc |
| **Previous Generation** | Older hardware (m3, c3 etc.) — still available, not recommended | — |

---

## 4. Instance Families (Letters)

| Letter | Family | Category |
|--------|--------|---------|
| `t` | Burstable performance | General Purpose |
| `m` | Balanced (standard) | General Purpose |
| `c` | Compute optimized | Compute Optimized |
| `r` | Memory optimized | Memory Optimized |
| `x` | High memory | Memory Optimized |
| `u` | Ultra-high memory | Memory Optimized |
| `i` | High IOPS NVMe SSD | Storage Optimized |
| `d` | Dense HDD storage | Storage Optimized |
| `h` | HDD-based high throughput | Storage Optimized |
| `p` | GPU compute (NVIDIA) | Accelerated Computing |
| `g` | GPU (graphics + ML) | Accelerated Computing |
| `f` | FPGA | Accelerated Computing |
| `inf` | ML inference (Inferentia) | Accelerated Computing |
| `trn` | ML training (Trainium) | Accelerated Computing |
| `hpc` | High Performance Computing | HPC |
| `z` | High-frequency CPU | Specialized |
| `mac` | macOS workloads | Specialized |
| `vt` | Video transcoding | Specialized |

---

## 5. Instance Type Naming Convention ⭐

```
<family><generation><processor>apabilities>.<size>
```

**Full example breakdown — `c7gn.2xlarge`:**

| Part | Value | Meaning |
|------|-------|---------|
| `c` | family | Compute Optimized |
| `7` | generation | 7th generation |
| `g` | processor | AWS Graviton (ARM) |
| `n` | capability | Network optimized |
| `2xlarge` | size | 2× the large baseline |

**Processor type letters:**

| Letter | Processor |
|--------|----------|
| *(none)* | Intel Xeon (default) |
| `a` | AMD EPYC |
| `g` | AWS Graviton (ARM-based) |
| `i` | Intel Ice Lake (newer) |

**Capability letters (before the dot):**

| Letter | Meaning |
|--------|---------|
| `n` | Network optimized (higher bandwidth) |
| `d` | Local NVMe instance store |
| `e` | Extra memory |
| `z` | High-frequency CPU |
| `b` | EBS optimized |
| `s` | Local NVMe SSD (smaller, faster) |

---

## 6. Instance Sizes

Sizes scale **within the same family** — not fixed across all families.

| Size | Relative Scale |
|------|---------------|
| `nano` | Smallest |
| `micro` | Very small |
| `small` | Small |
| `medium` | Medium |
| `large` | Baseline |
| `xlarge` | 2× large |
| `2xlarge` | 4× large |
| `4xlarge` | 8× large |
| `8xlarge` | 16× large |
| `12xlarge` | 24× large |
| `16xlarge` | 32× large |
| `metal` | Bare metal (no hypervisor) |

> **Rule:** Each step up typically doubles vCPU and RAM within the same family.

---

## 7. T-Series (Burstable) — CPU Credit System ⭐

T-series instances (`t3`, `t4g` etc.) use a **credit-based CPU model**:

```
Instance idle / below baseline CPU usage  →  earns CPU credits
Instance bursts above baseline            →  spends CPU credits
Credits exhausted + Standard mode         →  CPU throttled to baseline
Credits exhausted + Unlimited mode        →  CPU continues, you pay extra
```

> Use `t` instances for **variable workloads** — dev/test, small websites, microservices.
> Do NOT use for constant high-CPU workloads — use `c` or `m` instead.

---

## 8. AWS Graviton (ARM) — Why It Matters ⭐

AWS Graviton is AWS's own ARM-based chip (custom silicon).

| Benefit | Numbers |
|---------|---------|
| Cost savings | 20–40% cheaper vs equivalent x86 instance |
| Performance | Same or better for most workloads |
| Best for | Linux workloads — Node.js, Python, Java, Go, containers |

> If your app runs on Linux and doesn't need x86 → **always evaluate Graviton first**.

---

## 9. Instance Store vs EBS

| | Instance Store | EBS (Elastic Block Store) |
|--|---------------|--------------------------|
| Type | Local disk attached to host | Network-attached storage |
| Performance | ✅ Very high (NVMe SSD) | Good (lower than instance store) |
| Persistence | ❌ Ephemeral — **lost on stop/terminate** | ✅ Persistent — survives stop/restart |
| Use case | Temp files, cache, buffers | OS, databases, permanent data |
| Identified by | `d` capability letter in instance type | Separate EBS volume attachment |

> **Stop vs Terminate:**
> - Stop → instance store data is lost; EBS data persists
> - Terminate → both instance store AND EBS root volume deleted (by default)

---

## 10. EC2 Pricing Models ⭐ (Most Important for Interviews)

| Model | Discount | Commitment | Best For |
|-------|----------|-----------|---------|
| **On-Demand** | None (full price) | None | Spiky/unpredictable workloads, testing |
| **Reserved Instances** | Up to 72% | 1 or 3 years | Steady, always-running workloads |
| **Savings Plans** | Up to 66% | 1 or 3 years ($ spend/hr) | Flexible — works across instance families |
| **Spot Instances** | Up to 90% | None (can be interrupted) | Fault-tolerant, batch, CI/CD, containers |
| **Dedicated Hosts** | Custom pricing | On-Demand or Reserved | Compliance, BYOL (Bring Your Own License) |
| **Dedicated Instances** | Premium over On-Demand | None | Single-tenant hardware, no physical isolation control |

### Reserved Instances — 3 Types

| Type | Discount | Flexibility |
|------|----------|------------|
| **Standard RI** | Up to 72% | Fixed family + Region |
| **Convertible RI** | Up to 54% | Can change family, OS, tenancy |
| **Scheduled RI** | 5–10% | Reserve for specific time window daily/weekly |

### Spot Instances — Critical Rules

```
- Up to 90% cheaper than On-Demand
- AWS can reclaim with 2-minute warning
- Use for: batch jobs, CI/CD, ML training, stateless workers
- DO NOT use for: databases, session-critical apps
- Spot Fleet: request across multiple instance types for better availability
- Spot Block: reserve Spot for 1–6 hours (no interruption during that window)
```

### Payment Options (affects discount)

| Payment | Discount |
|---------|---------|
| All Upfront | Maximum discount |
| Partial Upfront | Medium discount |
| No Upfront | Minimum discount |

> Earlier you pay → more you save.

---

## 11. EC2 Instance Lifecycle (States) ⭐

```
Launch
  ↓
pending  →  running  →  stopping  →  stopped
                   ↓
             shutting-down  →  terminated
```

| State | Description |
|-------|-------------|
| **pending** | Instance booting, not yet billed |
| **running** | Instance active — **billing starts** |
| **stopping** | Gracefully shutting down |
| **stopped** | Instance off — EBS preserved, **no compute billing** |
| **shutting-down** | Being terminated |
| **terminated** | Permanently deleted — cannot restart |

> Stopped instance → EBS still billed.
> Terminated instance → EBS root deleted by default (depends on `DeleteOnTermination` flag).

---

## 12. AMI (Amazon Machine Image) ⭐

**Definition:** A template containing OS + config + pre-installed software used to launch instances.

| AMI Type | Source |
|----------|--------|
| AWS-provided | Amazon Linux, Ubuntu, Windows Server, etc. |
| Community AMIs | Shared by other AWS users |
| AWS Marketplace | Vendor-provided (often commercial software) |
| Custom AMI | Created by you from a running instance (snapshot) |

**Key facts:**
- AMIs are **Regional** — must copy to use in another Region
- AMI = EBS Snapshot + launch permissions + block device mapping
- You can create a "golden AMI" — base image with all software pre-installed

---

## 13. Placement Groups ⭐

Controls **how instances are physically placed** in AWS infrastructure.

| Type | Layout | Use Case | Trade-off |
|------|--------|---------|-----------|
| **Cluster** | All instances in same AZ, same rack | HPC, low-latency inter-node | ❌ Single AZ = lower fault tolerance |
| **Spread** | Each instance on separate hardware | Critical instances, max fault isolation | ❌ Max 7 instances per AZ |
| **Partition** | Groups of instances on separate partitions (racks) | HDFS, Kafka, Cassandra | Balance between performance and isolation |

---

## 14. Tenancy Types

| Type | Hardware | Use Case | Cost |
|------|---------|---------|------|
| **Shared (default)** | Shared physical server with other accounts | Standard workloads | Standard |
| **Dedicated Instance** | Your instances on single-tenant hardware | Compliance (no hardware sharing) | Higher |
| **Dedicated Host** | Full physical server allocated to you | BYOL, compliance, visibility into cores/sockets | Highest |

---

## 15. Key Additional Concepts

### User Data (Bootstrap Script)
Script that runs **once at first launch** — used to install software, configure the instance.
```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
```

### Elastic IP
- A **static public IPv4 address** you allocate to your account
- Can be reassigned between instances
- **Free while attached** to a running instance
- **Charged** when allocated but NOT attached (wasted resource)

### Instance Metadata Service (IMDS)
Accessible from inside the instance:
```bash
curl http://169.254.169.254/latest/meta-data/
# Returns: instance-id, public-ip, ami-id, iam/security-credentials, etc.
```
- Uses link-local IP `169.254.169.254` — not routable outside the instance
- IMDSv2 (recommended) requires session token — more secure than IMDSv1

---

## 16. Workload → Instance Selection Guide

| Workload | Recommended Family | Why |
|----------|--------------------|-----|
| Dev/test, small web apps | `t3`, `t4g` | Burstable, cost-effective |
| Production web/API servers | `m6i`, `m6g` | Balanced, cost-efficient |
| Batch processing, CI/CD builds | `c6i`, `c7g` | High CPU per dollar |
| Redis, large databases | `r6g`, `r6i` | High RAM per vCPU |
| NoSQL (Cassandra, MongoDB) | `i4i` | High IOPS NVMe |
| ML training | `p4`, `trn1` | GPU/Trainium |
| ML inference | `inf2` | Inferentia chip |
| HPC / scientific | `hpc7g` | High-bandwidth networking |
| macOS apps | `mac1`, `mac2` | Actual macOS on Bare Metal |

---

## 17. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Storage Optimized = large disk size | Storage Optimized = high IOPS / low latency — not about size |
| T-series for always-on high CPU | T-series is burstable — use `m` or `c` for constant load |
| Instance store is persistent | Instance store is ephemeral — lost on stop/terminate |
| Stop = terminate | Stop preserves EBS; Terminate deletes the instance |
| Spot instances are always available | AWS can reclaim Spot with 2-min notice |
| Reserved Instances must be used always | They are billing discounts — not capacity reservations |
| AMIs are global | AMIs are Regional — copy to use in another Region |
| All Upfront = same discount as No Upfront | All Upfront = maximum discount |

---

## 18. Interview Questions Checklist

- [ ] What is EC2? What does "Elastic" mean in the name?
- [ ] Decode this instance type: `m6i.4xlarge`
- [ ] Decode this instance type: `r7gd.metal`
- [ ] What is the difference between instance family and instance type?
- [ ] What are the EC2 instance categories? Give one example each.
- [ ] What is a T-series instance? How do CPU credits work?
- [ ] What is AWS Graviton? Why should you use it?
- [ ] On-Demand vs Reserved vs Spot vs Savings Plans — when to use each?
- [ ] Spot instance — what happens when AWS reclaims it? How much warning?
- [ ] What is a Spot Fleet? Spot Block?
- [ ] Standard RI vs Convertible RI — difference?
- [ ] What are EC2 instance states? Difference between stopped and terminated?
- [ ] What is an AMI? How do you create a custom one?
- [ ] Instance store vs EBS — key differences?
- [ ] What are Placement Groups? 3 types?
- [ ] Shared vs Dedicated Instance vs Dedicated Host?
- [ ] What is User Data in EC2?
- [ ] What is an Elastic IP? When are you charged for it?
- [ ] What is IMDS? What IP does it use?
- [ ] You have a batch job — which pricing model and instance type?
- [ ] You have a Redis cache — which instance family?
