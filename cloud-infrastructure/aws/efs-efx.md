
# AWS EFS & FSx

## 1. Where These Fit — Full AWS Storage Picture

```
EBS   → Block storage  → 1 EC2 only (mostly)     → hard disk attached to one server
S3    → Object storage → HTTP API, any client    → unlimited cloud bucket
EFS   → File storage   → many Linux EC2s at once → NFS shared network drive
FSx   → File storage   → specialist file systems → NFS/SMB/Lustre/ZFS for specific stacks
```

The single question that determines which to use:

```
Do multiple servers need to READ AND WRITE the same files simultaneously?
  NO  → EBS (block) or S3 (objects)
  YES → EFS or FSx (shared file system)

  YES + Linux workloads, simple NFS → EFS
  YES + Windows / HPC / enterprise NAS → FSx
```

---

# Part 1 — Amazon EFS (Elastic File System)

---All exact performance specs pulled directly from official AWS documentation.  Writing the complete file now.

***

````markdown
# AWS EFS & FSx — Complete Reference

---

## 1. Where These Fit — Full AWS Storage Picture

```
EBS   → Block storage  → 1 EC2 only (mostly)    → hard disk attached to one server
S3    → Object storage → HTTP API, any client    → unlimited cloud bucket
EFS   → File storage   → many Linux EC2s at once → NFS shared network drive
FSx   → File storage   → specialist file systems → NFS/SMB/Lustre/ZFS for specific stacks
```

The single question that determines which to use:

```
Do multiple servers need to READ AND WRITE the same files simultaneously?
  NO  → EBS (block) or S3 (objects)
  YES → EFS or FSx (shared file system)

  YES + Linux workloads, simple NFS → EFS
  YES + Windows / HPC / enterprise NAS → FSx
```

---

# Part 1 — Amazon EFS (Elastic File System)

---

## 2. What is EFS?

Amazon EFS is a **fully managed, serverless, elastic NFS (Network File System)**
for Linux. It scales capacity automatically — you never provision storage size.
Multiple EC2 instances, containers (ECS/EKS), and Lambda functions across
multiple AZs can mount and access the same file system simultaneously.

```
           AZ-1              AZ-2              AZ-3
      ┌──────────┐      ┌──────────┐      ┌──────────┐
      │  EC2 #1  │      │  EC2 #2  │      │  EC2 #3  │
      └────┬─────┘      └────┬─────┘      └────┬─────┘
           │                 │                 │
      ┌────▼─────────────────▼─────────────────▼─────┐
      │              EFS File System                  │
      │  (Mount Targets in each AZ's subnet)          │
      └───────────────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Protocol | NFSv4.0 / NFSv4.1 |
| OS support | **Linux only** (not Windows) |
| Capacity | **Elastic** — grows/shrinks automatically |
| Availability | Regional (3+ AZs) or One Zone (single AZ) |
| Durability | 99.999999999% (11 nines) — Regional |
| Concurrent access | Thousands of instances simultaneously |

---

## 3. EFS File System Types

### Regional (Multi-AZ) — Default

```
Data stored redundantly across 3+ AZs
Mount target created in each AZ's subnet
If one AZ fails → instances in other AZs continue unaffected
Use: production workloads requiring high availability
```

### One Zone (Single-AZ)

```
Data stored in a single AZ
Lower cost (~47% cheaper than Regional Standard)
Mount target in one subnet only
Use: dev/test, non-critical data, data you can recreate
Risk: AZ failure = data unavailable (or lost if AZ is permanently destroyed)
```

---

## 4. EFS Storage Classes ⭐

EFS automatically moves files between storage classes based on access patterns:

| Storage Class | Latency | Cost | For |
|--------------|---------|------|-----|
| **EFS Standard** | ~1ms read / ~2.7ms write | Highest | Frequently accessed files |
| **EFS Standard-IA** (Infrequent Access) | Tens of ms | ~92% lower storage cost | Rarely accessed files |
| **EFS Archive** | Tens of ms | Lowest | Files accessed a few times per year |
| **One Zone** | ~1ms read / ~1.6ms write | ~47% less than Regional | Single-AZ, frequently accessed |
| **One Zone-IA** | Tens of ms | Lowest overall | Single-AZ, infrequently accessed |

### Intelligent Tiering — Lifecycle Management

```
Enable lifecycle policy → EFS automatically transitions files:

  After 30 days no access → Standard → Standard-IA
  After 90 days no access → Standard-IA → Archive

  First access after transition → file moves back to Standard (configurable)

Similar to S3 Intelligent-Tiering but for file systems.
```

> A retrieval fee applies when reading from IA/Archive classes.
> For files accessed frequently, keep them in Standard to avoid per-read charges.

---

## 5. Performance Modes

### General Purpose (Default — Always Use This)

```
Lowest per-operation latency
Supports all throughput modes
One Zone file systems always use General Purpose

Recommended for: 99%+ of workloads
```

### Max I/O (Legacy — Avoid)

```
Designed for highly parallelized workloads
BUT: higher per-operation latency than General Purpose
NOT supported for: One Zone file systems or Elastic throughput

AWS Recommendation:
  "Due to higher per-operation latencies with Max I/O,
   we recommend using General Purpose performance mode for all file systems."

Monitor PercentIOLimit CloudWatch metric — if consistently near 100%,
switch to Elastic throughput instead of Max I/O mode.
```

---

## 6. Throughput Modes ⭐

Throughput mode controls how much throughput your file system can drive:

### Elastic Throughput (Recommended — Default)

```
Automatically scales throughput up and down with your workload
No capacity planning needed — you pay per GB read/written

Best for:
  Spiky or unpredictable workloads
  Average-to-peak ratio of 5% or less
  New file systems where patterns are unknown

Performance (Regional + Elastic + General Purpose):
  Read latency:  ~1 ms
  Write latency: ~2.7 ms
  Max read IOPS: 900,000–2,500,000
  Max write IOPS: 500,000
  Max read throughput (per file system):  20–60 GiBps
  Max write throughput (per file system): 1–5 GiBps
  Max per-client:  1,500 MiBps (with amazon-efs-utils v2.0+)
```

### Provisioned Throughput

```
You specify a fixed throughput level regardless of file system size
You pay for provisioned amount above baseline

Best for:
  Known, steady workloads
  Average-to-peak ratio of 5% or more

Performance (Regional + Provisioned):
  Max read IOPS: 55,000
  Max write IOPS: 25,000
  Max read throughput:  3–10 GiBps
  Max write throughput: 1–3.33 GiBps
  Max per-client: 500 MiBps

Note: after switching to Provisioned or changing Provisioned amount,
      must wait 24 hours before switching back to Elastic/Bursting.
```

### Bursting Throughput

```
Throughput scales proportionally to storage size in Standard class
Accumulates burst credits when idle → spends credits when busy

Baseline: 50 KiBps per GiB of Standard storage
Burst:    100 MiBps per TiB of Standard storage

Example (100 GiB Standard storage):
  Baseline: 5 MiBps continuous write
  Burst:    100 MiBps write for 72 minutes/day (on full credit balance)

Example (1 TiB Standard storage):
  Baseline: 50 MiBps write
  Burst:    100 MiBps write for 12 hours/day

Performance (Regional + Bursting):
  Max read IOPS: 35,000
  Max write IOPS: 7,000
  Max read throughput: 3–5 GiBps
  Max write throughput: 1–3 GiBps

Best for: workloads with long quiet periods followed by bursts
Avoid: if throughput is consistently high (credits will be exhausted)
```

### Throughput Mode Comparison

| Mode | Scales With | Best For | Pricing |
|------|------------|---------|---------|
| **Elastic** | Workload automatically | Spiky, unpredictable | Per GB read/written |
| **Provisioned** | Your specification | Steady, known patterns | Per MiBps provisioned |
| **Bursting** | Storage size + credits | Large files, infrequent bursts | Included in storage cost |

---

## 7. Mounting EFS on Linux

```bash
# Install EFS mount helper (amazon-efs-utils)
sudo yum install -y amazon-efs-utils      # Amazon Linux / RHEL
sudo apt-get install -y amazon-efs-utils  # Ubuntu / Debian

# Mount using EFS mount helper (recommended — handles TLS + retries)
sudo mount -t efs fs-12345678:/ /mnt/efs

# Mount with TLS encryption in transit
sudo mount -t efs -o tls fs-12345678:/ /mnt/efs

# Mount using NFS directly (alternative)
sudo mount -t nfs4 \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  fs-12345678.efs.us-east-1.amazonaws.com:/ /mnt/efs

# Auto-mount on boot — add to /etc/fstab:
fs-12345678:/ /mnt/efs efs defaults,_netdev 0 0
```

**For EKS (Kubernetes):** Use the `aws-efs-csi-driver` — creates
`PersistentVolume` backed by EFS; multiple pods read/write simultaneously
using `ReadWriteMany` access mode (not possible with EBS).

---

## 8. EFS Access Points

Access points enforce a specific directory, POSIX user/group, and
file permissions for application access:

```
EFS Root:  /
  ├── /app1  ← Access Point A (uid:1001, gid:1001, root path /app1)
  ├── /app2  ← Access Point B (uid:1002, gid:1002, root path /app2)
  └── /logs  ← Access Point C (uid:1000, gid:1000, root path /logs)

App1 mounts via Access Point A → sees only /app1, cannot access /app2
App2 mounts via Access Point B → sees only /app2

Benefit: multi-tenant isolation on one EFS file system
Use case: Lambda functions, containerized apps needing scoped access
```

---

## 9. EFS Security

| Layer | Mechanism |
|-------|-----------|
| Network access | Mount targets in VPC subnets; Security Groups control port 2049 (NFS) |
| Identity | IAM policies + EFS resource policy |
| Encryption at rest | KMS-managed keys (enable at creation — cannot change later) |
| Encryption in transit | TLS 1.2+ via EFS mount helper (`-o tls`) |
| POSIX permissions | Standard Linux file/directory permissions (uid/gid) |
| Access Points | Application-level isolation |

---

## 10. EFS Use Cases

| Use Case | Why EFS |
|---------|---------|
| **Kubernetes persistent storage** | `ReadWriteMany` — multiple pods share same volume |
| **WordPress / CMS media files** | Multiple web servers need same uploaded images |
| **CI/CD build artifacts** | Multiple build agents share workspace |
| **Machine learning training data** | Multiple training instances read same dataset |
| **Home directories** | Each user gets their own directory on shared EFS |
| **Container storage (ECS/EKS)** | Tasks share a filesystem across AZs |

---

# Part 2 — Amazon FSx

---

## 11. What is FSx?

Amazon FSx provides **fully managed, third-party file systems** — you get
the exact file system you're familiar with (Lustre, ONTAP, ZFS, Windows),
managed by AWS. Choose FSx when your workload requires a specific file system
that EFS (NFS-only, Linux-only) cannot serve.

```
Four FSx file systems:
  FSx for Windows File Server  → Windows SMB workloads
  FSx for Lustre              → HPC, ML, high-throughput Linux
  FSx for NetApp ONTAP        → Enterprise multi-protocol NAS
  FSx for OpenZFS             → ZFS Linux workloads, low latency
```

---

## 12. FSx for Windows File Server ⭐

### What It Is

Fully managed Windows file system backed by **Windows Server** with full
SMB (Server Message Block) protocol support and **Active Directory integration**.

```
Protocol:   SMB 2.0, 2.1, 3.0, 3.1.1
Clients:    Windows, Linux (via CIFS), macOS
Auth:       Microsoft Active Directory (AWS Managed AD or self-managed)
```

### Key Features

| Feature | Detail |
|---------|--------|
| Active Directory | Native integration — users log in with Windows credentials |
| NTFS permissions | Full Windows ACL support |
| DFS Namespaces | Distribute files across multiple FSx file systems |
| Shadow Copies | Previous versions — users self-restore files |
| SMB Multichannel | Multiple network connections for higher throughput |
| Deployment | Single-AZ or Multi-AZ (99.99% availability SLA) |
| Max throughput | 12–20 GB/s per file system |
| Max file system | 64 TiB |
| Latency | < 1 ms |
| Storage | SSD (low latency) or HDD (cost-optimized) |

### When to Use

- Lift-and-shift Windows applications to AWS
- `.NET` apps needing Windows file shares
- SQL Server home directory, user profiles
- Any workload requiring Windows ACLs or Active Directory

---

## 13. FSx for Lustre ⭐

### What It Is

Fully managed **Lustre** — the world's most popular **high-performance parallel
file system**, used in the largest supercomputers and ML clusters.
Linux-only, extremely high throughput.

```
Protocol:   Custom POSIX-compliant (Lustre protocol)
Clients:    Linux only
Auth:       POSIX permissions
```

### Performance

| Metric | Value |
|--------|-------|
| Max throughput per file system | **1,000 GB/s** |
| Max per-client throughput | 150 GB/s |
| Max IOPS | Millions |
| Latency | < 1 ms |

> FSx for Lustre throughput (1,000 GB/s) is the highest of any FSx file system —
> 10–70× higher than the others. Built specifically for data-intensive workloads.

### Deployment Types

```
Scratch (Temporary):
  No replication within AZ
  Data NOT preserved if file server fails
  Higher burst throughput
  Use: short-term processing, cost-sensitive HPC

Persistent (Long-term):
  Data replicated within single AZ
  File server failures are auto-recovered
  Use: long-running workloads, ML training runs
```

### S3 Integration ⭐

```
FSx for Lustre can be linked to an S3 bucket:
  Import: data in S3 automatically imported to Lustre on first access (lazy loading)
  Export: results written back to S3 automatically

Pattern for ML training:
  Training data in S3 (cheap, durable)
    → Link to FSx for Lustre (high-speed scratch during training)
    → Model output exported back to S3
    → Delete FSx after training (pay only during training job)
```

### When to Use

- Machine learning training on large datasets
- High-performance computing (genomics, financial simulations, weather modeling)
- Video rendering and transcoding
- Seismic data processing

---

## 14. FSx for NetApp ONTAP ⭐

### What It Is

Fully managed **NetApp ONTAP** — the most feature-rich FSx option,
supporting multiple protocols simultaneously.

```
Protocols:  NFS (3, 4.0, 4.1, 4.2) + SMB (2.0–3.1.1) + iSCSI (block storage)
Clients:    Windows, Linux, macOS — simultaneously
```

### Performance

| Metric | Value |
|--------|-------|
| Max throughput per file system | 72–80 GB/s |
| Max per-client throughput | 18 GB/s |
| Max IOPS | Millions |
| Max file system size | Virtually unlimited (10s of PBs) |
| Latency | < 1 ms |

### Unique Capabilities

| Feature | Description |
|---------|-------------|
| **Multi-protocol** | Same data accessed via NFS (Linux) AND SMB (Windows) simultaneously |
| **FlexClone** | Instant zero-copy clones of volumes (no data duplication) |
| **SnapMirror** | Cross-region replication to on-premises NetApp or another FSx |
| **Auto-tiering** | Hot data on SSD, cold data automatically moved to cheaper storage tier |
| **Data deduplication** | Removes duplicate blocks — reduces storage consumption |
| **iSCSI** | Block storage accessible as SAN (Storage Area Network) |
| **Anti-virus integration** | Native virus scanning support |
| **Deployment** | Single-AZ (99.9%) or Multi-AZ (99.99%) |
| **On-prem caching** | NetApp FlexCache — cache AWS data on-premises |

### When to Use

- Lift-and-shift existing NetApp ONTAP NAS to AWS
- Multi-protocol workloads (Windows + Linux accessing same files)
- Enterprise NAS migration
- Complex data management (cloning, replication, tiering)
- Any workload where you're already using NetApp on-premises

---

## 15. FSx for OpenZFS ⭐

### What It Is

Fully managed **OpenZFS** — a Linux-native file system known for
data integrity, inline compression, and the **lowest latency** of any FSx option.

```
Protocol:   NFS (3, 4.0, 4.1, 4.2)
Clients:    Windows, Linux, macOS
```

### Performance

| Metric | Value |
|--------|-------|
| Latency | **< 0.5 ms** (lowest of all FSx types) |
| Max throughput per file system | 10–21 GB/s |
| Max per-client throughput | 10 GB/s |
| Max IOPS | 1–2 million |
| Max file system size | 512 TiB |

### Key Features

| Feature | Description |
|---------|-------------|
| **Instant snapshots** | Point-in-time snapshots, space-efficient |
| **FlexClone-equivalent** | Instant zero-copy clones |
| **Inline compression** | Reduces storage cost automatically |
| **Deployment** | Single-AZ (99.5%) or Multi-AZ (99.99%) |
| **Cross-region backups** | ✅ Supported |
| **End-user restore** | Users can restore previous file versions |

### When to Use

- Lift-and-shift ZFS workloads to AWS
- Linux-based file servers needing low latency
- Development/test environments needing instant cloning
- Any workload needing sub-millisecond NFS latency

---

## 16. FSx — Full Comparison Table

| Feature | Windows FS | Lustre | NetApp ONTAP | OpenZFS |
|---------|-----------|--------|-------------|---------|
| Protocol | SMB | Lustre (custom) | NFS + SMB + iSCSI | NFS |
| OS clients | Win, Linux, Mac | **Linux only** | Win, Linux, Mac | Win, Linux, Mac |
| Max throughput | 12–20 GB/s | **1,000 GB/s** | 72–80 GB/s | 10–21 GB/s |
| Latency | < 1 ms | < 1 ms | < 1 ms | **< 0.5 ms** |
| Max IOPS | Hundreds of thousands | **Millions** | **Millions** | 1–2 million |
| Max size | 64 TiB | Multiple PBs | **Virtually unlimited** | 512 TiB |
| Multi-AZ SLA | 99.99% | ❌ (Single-AZ) | 99.99% | 99.99% |
| Active Directory | ✅ | ❌ | ✅ | ❌ |
| S3 integration | ❌ | ✅ (auto import/export) | ❌ | ❌ |
| Data deduplication | ✅ | ❌ | ✅ | ❌ |
| Instant snapshots | ✅ | ❌ | ✅ | ✅ |
| Cross-region replication | ✅ | ✅ (via S3) | ✅ (SnapMirror) | ✅ |
| Use case | Windows apps | ML/HPC | Enterprise NAS | ZFS/Linux |

---

## 17. EFS vs FSx — When to Use Which ⭐

| If you need... | Use |
|---------------|-----|
| Shared Linux filesystem, elastic, simple | **EFS** |
| Multiple pods in Kubernetes sharing storage | **EFS** (ReadWriteMany) |
| Windows applications, SMB, Active Directory | **FSx for Windows** |
| ML training, HPC, highest possible throughput | **FSx for Lustre** |
| S3 as dataset, fast processing, export results | **FSx for Lustre** |
| Migrate existing NetApp ONTAP NAS to AWS | **FSx for NetApp ONTAP** |
| Windows AND Linux accessing same files | **FSx for NetApp ONTAP** |
| Migrate ZFS workloads, sub-ms latency NFS | **FSx for OpenZFS** |
| Dev/test cloning, snapshot-heavy workflows | **FSx for NetApp ONTAP** or **OpenZFS** |

---

## 18. EFS vs EBS vs S3 — Complete Storage Comparison

| Feature | EBS | EFS | S3 |
|---------|-----|-----|-----|
| Type | Block | File (NFS) | Object |
| Access | 1 EC2 (mostly) | Many EC2s simultaneously | HTTP API |
| OS support | Linux + Windows | **Linux only** | Any |
| Mount | ✅ Block device | ✅ NFS mount | ❌ Not mountable |
| Elastic capacity | ❌ (fixed size) | ✅ Auto-grows/shrinks | ✅ Unlimited |
| Multi-AZ | ❌ (per AZ, unless io2 Multi-Attach) | ✅ Regional | ✅ (≥3 AZs) |
| Use case | Root volume, DB | Shared files, Kubernetes | Backups, web assets, data lake |
| Max size | 64 TiB per volume | Unlimited | Unlimited |
| Cost model | GB provisioned | GB stored + throughput | GB stored + requests |

---

## 19. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| EFS works on Windows | EFS is **Linux-only** (NFS) — use FSx for Windows for Windows clients |
| EFS needs pre-provisioned storage size | EFS is **elastic** — capacity grows/shrinks automatically |
| Max I/O mode is always better for heavy workloads | AWS recommends **General Purpose** for everything — Max I/O has higher latency |
| Bursting throughput is the best mode | **Elastic** is the recommended default — Bursting can exhaust credits |
| FSx for Lustre supports Windows clients | FSx for Lustre is **Linux-only** — for Windows use FSx for Windows or ONTAP |
| FSx for Lustre data is always durable | **Scratch** deployment has no replication — data can be lost on failure |
| EFS and EBS can

## 2. What is EFS?

Amazon EFS is a **fully managed, serverless, elastic NFS (Network File System)**
for Linux. It scales capacity automatically — you never provision storage size.
Multiple EC2 instances, containers (ECS/EKS), and Lambda functions across
multiple AZs can mount and access the same file system simultaneously.

```
           AZ-1              AZ-2              AZ-3
      ┌──────────┐      ┌──────────┐      ┌──────────┐
      │  EC2 #1  │      │  EC2 #2  │      │  EC2 #3  │
      └────┬─────┘      └────┬─────┘      └────┬─────┘
           │                 │                 │
      ┌────▼─────────────────▼─────────────────▼─────┐
      │              EFS File System                  │
      │  (Mount Targets in each AZ's subnet)          │
      └───────────────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Protocol | NFSv4.0 / NFSv4.1 |
| OS support | **Linux only** (not Windows) |
| Capacity | **Elastic** — grows/shrinks automatically |
| Availability | Regional (3+ AZs) or One Zone (single AZ) |
| Durability | 99.999999999% (11 nines) — Regional |
| Concurrent access | Thousands of instances simultaneously |

---

## 3. EFS File System Types

### Regional (Multi-AZ) — Default

```
Data stored redundantly across 3+ AZs
Mount target created in each AZ's subnet
If one AZ fails → instances in other AZs continue unaffected
Use: production workloads requiring high availability
```

### One Zone (Single-AZ)

```
Data stored in a single AZ
Lower cost (~47% cheaper than Regional Standard)
Mount target in one subnet only
Use: dev/test, non-critical data, data you can recreate
Risk: AZ failure = data unavailable (or lost if AZ is permanently destroyed)
```

---

## 4. EFS Storage Classes ⭐

EFS automatically moves files between storage classes based on access patterns:

| Storage Class | Latency | Cost | For |
|--------------|---------|------|-----|
| **EFS Standard** | ~1ms read / ~2.7ms write | Highest | Frequently accessed files |
| **EFS Standard-IA** (Infrequent Access) | Tens of ms | ~92% lower storage cost | Rarely accessed files |
| **EFS Archive** | Tens of ms | Lowest | Files accessed a few times per year |
| **One Zone** | ~1ms read / ~1.6ms write | ~47% less than Regional | Single-AZ, frequently accessed |
| **One Zone-IA** | Tens of ms | Lowest overall | Single-AZ, infrequently accessed |

### Intelligent Tiering — Lifecycle Management

```
Enable lifecycle policy → EFS automatically transitions files:

  After 30 days no access → Standard → Standard-IA
  After 90 days no access → Standard-IA → Archive

  First access after transition → file moves back to Standard (configurable)

Similar to S3 Intelligent-Tiering but for file systems.
```

> A retrieval fee applies when reading from IA/Archive classes.
> For files accessed frequently, keep them in Standard to avoid per-read charges.

---

## 5. Performance Modes

### General Purpose (Default — Always Use This)

```
Lowest per-operation latency
Supports all throughput modes
One Zone file systems always use General Purpose

Recommended for: 99%+ of workloads
```

### Max I/O (Legacy — Avoid)

```
Designed for highly parallelized workloads
BUT: higher per-operation latency than General Purpose
NOT supported for: One Zone file systems or Elastic throughput

AWS Recommendation:
  "Due to higher per-operation latencies with Max I/O,
   we recommend using General Purpose performance mode for all file systems."

Monitor PercentIOLimit CloudWatch metric — if consistently near 100%,
switch to Elastic throughput instead of Max I/O mode.
```

---

## 6. Throughput Modes ⭐

Throughput mode controls how much throughput your file system can drive:

### Elastic Throughput (Recommended — Default)

```
Automatically scales throughput up and down with your workload
No capacity planning needed — you pay per GB read/written

Best for:
  Spiky or unpredictable workloads
  Average-to-peak ratio of 5% or less
  New file systems where patterns are unknown

Performance (Regional + Elastic + General Purpose):
  Read latency:  ~1 ms
  Write latency: ~2.7 ms
  Max read IOPS: 900,000–2,500,000
  Max write IOPS: 500,000
  Max read throughput (per file system):  20–60 GiBps
  Max write throughput (per file system): 1–5 GiBps
  Max per-client:  1,500 MiBps (with amazon-efs-utils v2.0+)
```

### Provisioned Throughput

```
You specify a fixed throughput level regardless of file system size
You pay for provisioned amount above baseline

Best for:
  Known, steady workloads
  Average-to-peak ratio of 5% or more

Performance (Regional + Provisioned):
  Max read IOPS: 55,000
  Max write IOPS: 25,000
  Max read throughput:  3–10 GiBps
  Max write throughput: 1–3.33 GiBps
  Max per-client: 500 MiBps

Note: after switching to Provisioned or changing Provisioned amount,
      must wait 24 hours before switching back to Elastic/Bursting.
```

### Bursting Throughput

```
Throughput scales proportionally to storage size in Standard class
Accumulates burst credits when idle → spends credits when busy

Baseline: 50 KiBps per GiB of Standard storage
Burst:    100 MiBps per TiB of Standard storage

Example (100 GiB Standard storage):
  Baseline: 5 MiBps continuous write
  Burst:    100 MiBps write for 72 minutes/day (on full credit balance)

Example (1 TiB Standard storage):
  Baseline: 50 MiBps write
  Burst:    100 MiBps write for 12 hours/day

Performance (Regional + Bursting):
  Max read IOPS: 35,000
  Max write IOPS: 7,000
  Max read throughput: 3–5 GiBps
  Max write throughput: 1–3 GiBps

Best for: workloads with long quiet periods followed by bursts
Avoid: if throughput is consistently high (credits will be exhausted)
```

### Throughput Mode Comparison

| Mode | Scales With | Best For | Pricing |
|------|------------|---------|---------|
| **Elastic** | Workload automatically | Spiky, unpredictable | Per GB read/written |
| **Provisioned** | Your specification | Steady, known patterns | Per MiBps provisioned |
| **Bursting** | Storage size + credits | Large files, infrequent bursts | Included in storage cost |

---

## 7. Mounting EFS on Linux

```bash
# Install EFS mount helper (amazon-efs-utils)
sudo yum install -y amazon-efs-utils      # Amazon Linux / RHEL
sudo apt-get install -y amazon-efs-utils  # Ubuntu / Debian

# Mount using EFS mount helper (recommended — handles TLS + retries)
sudo mount -t efs fs-12345678:/ /mnt/efs

# Mount with TLS encryption in transit
sudo mount -t efs -o tls fs-12345678:/ /mnt/efs

# Mount using NFS directly (alternative)
sudo mount -t nfs4 \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  fs-12345678.efs.us-east-1.amazonaws.com:/ /mnt/efs

# Auto-mount on boot — add to /etc/fstab:
fs-12345678:/ /mnt/efs efs defaults,_netdev 0 0
```

**For EKS (Kubernetes):** Use the `aws-efs-csi-driver` — creates
`PersistentVolume` backed by EFS; multiple pods read/write simultaneously
using `ReadWriteMany` access mode (not possible with EBS).

---

## 8. EFS Access Points

Access points enforce a specific directory, POSIX user/group, and
file permissions for application access:

```
EFS Root:  /
  ├── /app1  ← Access Point A (uid:1001, gid:1001, root path /app1)
  ├── /app2  ← Access Point B (uid:1002, gid:1002, root path /app2)
  └── /logs  ← Access Point C (uid:1000, gid:1000, root path /logs)

App1 mounts via Access Point A → sees only /app1, cannot access /app2
App2 mounts via Access Point B → sees only /app2

Benefit: multi-tenant isolation on one EFS file system
Use case: Lambda functions, containerized apps needing scoped access
```

---

## 9. EFS Security

| Layer | Mechanism |
|-------|-----------|
| Network access | Mount targets in VPC subnets; Security Groups control port 2049 (NFS) |
| Identity | IAM policies + EFS resource policy |
| Encryption at rest | KMS-managed keys (enable at creation — cannot change later) |
| Encryption in transit | TLS 1.2+ via EFS mount helper (`-o tls`) |
| POSIX permissions | Standard Linux file/directory permissions (uid/gid) |
| Access Points | Application-level isolation |

---

## 10. EFS Use Cases

| Use Case | Why EFS |
|---------|---------|
| **Kubernetes persistent storage** | `ReadWriteMany` — multiple pods share same volume |
| **WordPress / CMS media files** | Multiple web servers need same uploaded images |
| **CI/CD build artifacts** | Multiple build agents share workspace |
| **Machine learning training data** | Multiple training instances read same dataset |
| **Home directories** | Each user gets their own directory on shared EFS |
| **Container storage (ECS/EKS)** | Tasks share a filesystem across AZs |

---

# Part 2 — Amazon FSx

---

## 11. What is FSx?

Amazon FSx provides **fully managed, third-party file systems** — you get
the exact file system you're familiar with (Lustre, ONTAP, ZFS, Windows),
managed by AWS. Choose FSx when your workload requires a specific file system
that EFS (NFS-only, Linux-only) cannot serve.

```
Four FSx file systems:
  FSx for Windows File Server  → Windows SMB workloads
  FSx for Lustre              → HPC, ML, high-throughput Linux
  FSx for NetApp ONTAP        → Enterprise multi-protocol NAS
  FSx for OpenZFS             → ZFS Linux workloads, low latency
```

---

## 12. FSx for Windows File Server ⭐

### What It Is

Fully managed Windows file system backed by **Windows Server** with full
SMB (Server Message Block) protocol support and **Active Directory integration**.

```
Protocol:   SMB 2.0, 2.1, 3.0, 3.1.1
Clients:    Windows, Linux (via CIFS), macOS
Auth:       Microsoft Active Directory (AWS Managed AD or self-managed)
```

### Key Features

| Feature | Detail |
|---------|--------|
| Active Directory | Native integration — users log in with Windows credentials |
| NTFS permissions | Full Windows ACL support |
| DFS Namespaces | Distribute files across multiple FSx file systems |
| Shadow Copies | Previous versions — users self-restore files |
| SMB Multichannel | Multiple network connections for higher throughput |
| Deployment | Single-AZ or Multi-AZ (99.99% availability SLA) |
| Max throughput | 12–20 GB/s per file system |
| Max file system | 64 TiB |
| Latency | < 1 ms |
| Storage | SSD (low latency) or HDD (cost-optimized) |

### When to Use

- Lift-and-shift Windows applications to AWS
- `.NET` apps needing Windows file shares
- SQL Server home directory, user profiles
- Any workload requiring Windows ACLs or Active Directory

---

## 13. FSx for Lustre ⭐

### What It Is

Fully managed **Lustre** — the world's most popular **high-performance parallel
file system**, used in the largest supercomputers and ML clusters.
Linux-only, extremely high throughput.

```
Protocol:   Custom POSIX-compliant (Lustre protocol)
Clients:    Linux only
Auth:       POSIX permissions
```

### Performance

| Metric | Value |
|--------|-------|
| Max throughput per file system | **1,000 GB/s** |
| Max per-client throughput | 150 GB/s |
| Max IOPS | Millions |
| Latency | < 1 ms |

> FSx for Lustre throughput (1,000 GB/s) is the highest of any FSx file system —
> 10–70× higher than the others. Built specifically for data-intensive workloads.

### Deployment Types

```
Scratch (Temporary):
  No replication within AZ
  Data NOT preserved if file server fails
  Higher burst throughput
  Use: short-term processing, cost-sensitive HPC

Persistent (Long-term):
  Data replicated within single AZ
  File server failures are auto-recovered
  Use: long-running workloads, ML training runs
```

### S3 Integration ⭐

```
FSx for Lustre can be linked to an S3 bucket:
  Import: data in S3 automatically imported to Lustre on first access (lazy loading)
  Export: results written back to S3 automatically

Pattern for ML training:
  Training data in S3 (cheap, durable)
    → Link to FSx for Lustre (high-speed scratch during training)
    → Model output exported back to S3
    → Delete FSx after training (pay only during training job)
```

### When to Use

- Machine learning training on large datasets
- High-performance computing (genomics, financial simulations, weather modeling)
- Video rendering and transcoding
- Seismic data processing

---

## 14. FSx for NetApp ONTAP ⭐

### What It Is

Fully managed **NetApp ONTAP** — the most feature-rich FSx option,
supporting multiple protocols simultaneously.

```
Protocols:  NFS (3, 4.0, 4.1, 4.2) + SMB (2.0–3.1.1) + iSCSI (block storage)
Clients:    Windows, Linux, macOS — simultaneously
```

### Performance

| Metric | Value |
|--------|-------|
| Max throughput per file system | 72–80 GB/s |
| Max per-client throughput | 18 GB/s |
| Max IOPS | Millions |
| Max file system size | Virtually unlimited (10s of PBs) |
| Latency | < 1 ms |

### Unique Capabilities

| Feature | Description |
|---------|-------------|
| **Multi-protocol** | Same data accessed via NFS (Linux) AND SMB (Windows) simultaneously |
| **FlexClone** | Instant zero-copy clones of volumes (no data duplication) |
| **SnapMirror** | Cross-region replication to on-premises NetApp or another FSx |
| **Auto-tiering** | Hot data on SSD, cold data automatically moved to cheaper storage tier |
| **Data deduplication** | Removes duplicate blocks — reduces storage consumption |
| **iSCSI** | Block storage accessible as SAN (Storage Area Network) |
| **Anti-virus integration** | Native virus scanning support |
| **Deployment** | Single-AZ (99.9%) or Multi-AZ (99.99%) |
| **On-prem caching** | NetApp FlexCache — cache AWS data on-premises |

### When to Use

- Lift-and-shift existing NetApp ONTAP NAS to AWS
- Multi-protocol workloads (Windows + Linux accessing same files)
- Enterprise NAS migration
- Complex data management (cloning, replication, tiering)
- Any workload where you're already using NetApp on-premises

---

## 15. FSx for OpenZFS ⭐

### What It Is

Fully managed **OpenZFS** — a Linux-native file system known for
data integrity, inline compression, and the **lowest latency** of any FSx option.

```
Protocol:   NFS (3, 4.0, 4.1, 4.2)
Clients:    Windows, Linux, macOS
```

### Performance

| Metric | Value |
|--------|-------|
| Latency | **< 0.5 ms** (lowest of all FSx types) |
| Max throughput per file system | 10–21 GB/s |
| Max per-client throughput | 10 GB/s |
| Max IOPS | 1–2 million |
| Max file system size | 512 TiB |

### Key Features

| Feature | Description |
|---------|-------------|
| **Instant snapshots** | Point-in-time snapshots, space-efficient |
| **FlexClone-equivalent** | Instant zero-copy clones |
| **Inline compression** | Reduces storage cost automatically |
| **Deployment** | Single-AZ (99.5%) or Multi-AZ (99.99%) |
| **Cross-region backups** | ✅ Supported |
| **End-user restore** | Users can restore previous file versions |

### When to Use

- Lift-and-shift ZFS workloads to AWS
- Linux-based file servers needing low latency
- Development/test environments needing instant cloning
- Any workload needing sub-millisecond NFS latency

---

## 16. FSx — Full Comparison Table

| Feature | Windows FS | Lustre | NetApp ONTAP | OpenZFS |
|---------|-----------|--------|-------------|---------|
| Protocol | SMB | Lustre (custom) | NFS + SMB + iSCSI | NFS |
| OS clients | Win, Linux, Mac | **Linux only** | Win, Linux, Mac | Win, Linux, Mac |
| Max throughput | 12–20 GB/s | **1,000 GB/s** | 72–80 GB/s | 10–21 GB/s |
| Latency | < 1 ms | < 1 ms | < 1 ms | **< 0.5 ms** |
| Max IOPS | Hundreds of thousands | **Millions** | **Millions** | 1–2 million |
| Max size | 64 TiB | Multiple PBs | **Virtually unlimited** | 512 TiB |
| Multi-AZ SLA | 99.99% | ❌ (Single-AZ) | 99.99% | 99.99% |
| Active Directory | ✅ | ❌ | ✅ | ❌ |
| S3 integration | ❌ | ✅ (auto import/export) | ❌ | ❌ |
| Data deduplication | ✅ | ❌ | ✅ | ❌ |
| Instant snapshots | ✅ | ❌ | ✅ | ✅ |
| Cross-region replication | ✅ | ✅ (via S3) | ✅ (SnapMirror) | ✅ |
| Use case | Windows apps | ML/HPC | Enterprise NAS | ZFS/Linux |

---

## 17. EFS vs FSx — When to Use Which ⭐

| If you need... | Use |
|---------------|-----|
| Shared Linux filesystem, elastic, simple | **EFS** |
| Multiple pods in Kubernetes sharing storage | **EFS** (ReadWriteMany) |
| Windows applications, SMB, Active Directory | **FSx for Windows** |
| ML training, HPC, highest possible throughput | **FSx for Lustre** |
| S3 as dataset, fast processing, export results | **FSx for Lustre** |
| Migrate existing NetApp ONTAP NAS to AWS | **FSx for NetApp ONTAP** |
| Windows AND Linux accessing same files | **FSx for NetApp ONTAP** |
| Migrate ZFS workloads, sub-ms latency NFS | **FSx for OpenZFS** |
| Dev/test cloning, snapshot-heavy workflows | **FSx for NetApp ONTAP** or **OpenZFS** |

---

## 18. EFS vs EBS vs S3 — Complete Storage Comparison

| Feature | EBS | EFS | S3 |
|---------|-----|-----|-----|
| Type | Block | File (NFS) | Object |
| Access | 1 EC2 (mostly) | Many EC2s simultaneously | HTTP API |
| OS support | Linux + Windows | **Linux only** | Any |
| Mount | ✅ Block device | ✅ NFS mount | ❌ Not mountable |
| Elastic capacity | ❌ (fixed size) | ✅ Auto-grows/shrinks | ✅ Unlimited |
| Multi-AZ | ❌ (per AZ, unless io2 Multi-Attach) | ✅ Regional | ✅ (≥3 AZs) |
| Use case | Root volume, DB | Shared files, Kubernetes | Backups, web assets, data lake |
| Max size | 64 TiB per volume | Unlimited | Unlimited |
| Cost model | GB provisioned | GB stored + throughput | GB stored + requests |

---

## 19. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| EFS works on Windows | EFS is **Linux-only** (NFS) — use FSx for Windows for Windows clients |
| EFS needs pre-provisioned storage size | EFS is **elastic** — capacity grows/shrinks automatically |
| Max I/O mode is always better for heavy workloads | AWS recommends **General Purpose** for everything — Max I/O has higher latency |
| Bursting throughput is the best mode | **Elastic** is the recommended default — Bursting can exhaust credits |
| FSx for Lustre supports Windows clients | FSx for Lustre is **Linux-only** — for Windows use FSx for Windows or ONTAP |
| FSx for Lustre data is always durable | **Scratch** deployment has no replication — data can be lost on failure |
| EFS and EBS can
