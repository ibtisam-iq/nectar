# AWS Storage — Complete Reference

---

## 1. Storage Types — The Big Picture

```
AWS Storage
├── Block Storage     → EBS, Instance Store     (low-latency, OS/database)
├── Object Storage    → S3                       (scalable, internet-accessible)
└── File Storage      → EFS, FSx                 (shared, multi-instance)
```

> **Rule:** Storage type determines access pattern, not just "where data lives."
> Match storage type to workload behavior — wrong choice = bottleneck or wasted cost.

---

## 2. Block Storage

Data stored as fixed-size **blocks** — like a physical hard drive.
Access is direct, low-latency, and operates below the filesystem level.

---

### 2.1 Amazon EBS (Elastic Block Store)

**Definition:** Persistent, network-attached block storage volumes for EC2 instances.

| Property | Detail |
|----------|--------|
| Attachment | One instance at a time (except io1/io2 Multi-Attach) |
| Location | AZ-specific — must be in same AZ as the EC2 instance |
| Persistence | ✅ Data survives instance stop/restart |
| Scope | Single AZ |
| Max size | 16 TiB (io2 Block Express: 64 TiB) |
| Resize | ✅ Can increase size — ❌ cannot decrease |

---

#### 2.1.1 EBS Volume Types — Performance Numbers ⭐

| Type | Category | Max IOPS | Max Throughput | Durability | Best For |
|------|----------|---------|----------------|-----------|---------|
| **gp3** ✅ Recommended | SSD | 16,000 | 1,000 MB/s | 99.8–99.9% | Most workloads (default choice) |
| **gp2** (legacy) | SSD | 16,000 | 250 MB/s | 99.8–99.9% | Older setups — migrate to gp3 |
| **io2** | Provisioned IOPS SSD | 64,000 | 1,000 MB/s | **99.999%** | Mission-critical databases |
| **io2 Block Express** | Provisioned IOPS SSD | 256,000 | 4,000 MB/s | **99.999%** | SAP HANA, extreme performance |
| **io1** (legacy) | Provisioned IOPS SSD | 64,000 | 1,000 MB/s | 99.8–99.9% | Replaced by io2 |
| **st1** | Throughput HDD | 500 | 500 MB/s | 99.8–99.9% | Big data, log processing |
| **sc1** | Cold HDD | 250 | 250 MB/s | 99.8–99.9% | Infrequent access, cold storage |
| **Magnetic** (legacy) | HDD | 40–200 | 40–90 MB/s | 99.8–99.9% | Not recommended |

---

#### 2.1.2 gp2 vs gp3 — Why Always Use gp3 ⭐

| Feature | gp2 (legacy) | gp3 (recommended) |
|---------|-------------|-------------------|
| IOPS model | Tied to size: 3 IOPS/GB (min 100, max 16,000) | **Independent** of size — baseline 3,000 IOPS |
| Throughput | Max 250 MB/s | Baseline 125 MB/s → up to **1,000 MB/s** |
| Bursting | Yes (credit-based for small volumes) | ❌ No burst — **consistent** provisioned performance |
| Price | $0.10/GB/month | **$0.08/GB/month** (20% cheaper) |
| Flexibility | ❌ Can't tune IOPS separately | ✅ IOPS and throughput independently tunable |

> **Always choose gp3 over gp2.** It is cheaper, faster (for most sizes), and more predictable.
> gp2 small volumes (<334 GB) rely on burst credits — performance becomes unpredictable.

---

#### 2.1.3 io2 vs gp3 — When is io2 Worth the Cost?

```
gp3 at 16,000 IOPS (200 GB):   ~$81/month
io2 at 16,000 IOPS (200 GB):   ~$1,065/month   (≈13× more expensive)
```

**Pay for io2 only when you need:**
- More than 16,000 IOPS (io2 goes up to 64,000 / Block Express to 256,000)
- **99.999% durability** (five nines — for mission-critical databases)
- **Sub-millisecond consistent latency** (Oracle, SAP HANA, SQL Server)
- **Multi-Attach** — attach to multiple instances simultaneously

---

#### 2.1.4 Boot (Root Volume) Support

| Volume Type | Bootable |
|------------|---------|
| gp2, gp3, io1, io2 | ✅ Yes |
| st1, sc1 | ❌ No — HDD volumes cannot be root |
| Magnetic (standard) | ✅ Yes (legacy) |

---

#### 2.1.5 IOPS vs Throughput — Clarified ⭐

| Metric | Definition | Unit | Optimized by |
|--------|-----------|------|-------------|
| **IOPS** | Number of read/write operations per second | ops/sec | io1, io2, gp3 |
| **Throughput** | Amount of data transferred per second | MB/s | st1, gp3 |

```
Small random reads/writes (databases, OS) → care about IOPS
Large sequential reads/writes (logs, big data) → care about Throughput
```

---

#### 2.1.6 EBS Root Volume Behavior

| Setting | Default | Configurable |
|---------|---------|-------------|
| Delete on termination | ✅ Enabled | ✅ Yes — can disable |

> Disabling `DeleteOnTermination` on root volume = EBS persists after instance termination.
> Data volumes: `DeleteOnTermination` is **disabled** by default.

---

#### 2.1.7 EBS Multi-Attach (io1/io2 only) ⭐

- Attach **one EBS volume to multiple EC2 instances** simultaneously (same AZ)
- Only io1 and io2 support this
- Use case: clustered databases (Oracle RAC, DRBD) that manage concurrent access
- Application must handle concurrent writes — EBS does NOT manage write conflicts

---

#### 2.1.8 EBS Snapshots ⭐

Point-in-time backups of EBS volumes — stored in **S3** (managed by AWS, not your bucket).

| Property | Detail |
|----------|--------|
| Type | **Incremental** — only changed blocks since last snapshot are stored |
| Storage | S3 (AWS-managed, not visible in your S3 console) |
| Scope | Regional — can copy to another Region |
| Speed | First snapshot = full copy; subsequent = incremental |
| Restore | Create new EBS volume from snapshot (any AZ in same Region) |
| Use | Backup, migration, AMI creation, cross-Region/cross-account sharing |

```bash
# Create snapshot
aws ec2 create-snapshot --volume-id vol-xxxxxxxx --description "my backup"

# Copy to another Region
aws ec2 copy-snapshot --source-region us-east-1 --source-snapshot-id snap-xxxxxxxx --region eu-west-1
```

**Snapshot best practices:**
- Use **Amazon Data Lifecycle Manager (DLM)** for automated snapshot schedules
- Enable **EBS Snapshot Archive** for 75% cheaper long-term retention (restore takes hours)
- Enable **Recycle Bin** to protect against accidental deletion (1–365 day retention)

---

#### 2.1.9 EBS Encryption

| Property | Detail |
|----------|--------|
| Algorithm | AES-256 |
| Key management | AWS KMS (Customer Managed Key or AWS Managed Key) |
| What is encrypted | Data at rest, data in transit (between EC2 and EBS), snapshots |
| Performance impact | Minimal — handled by hardware |
| Default | Off per volume (can enable account-level default encryption) |

> **Encrypted volume → all snapshots encrypted.**
> **Encrypted snapshot → all volumes created from it are encrypted.**
> You cannot directly encrypt an existing unencrypted volume — copy snapshot → encrypt copy → create volume.

---

#### 2.1.10 Mount Points (Volume Identification)

| OS | Root Volume Device | Additional Volumes |
|----|-------------------|-------------------|
| Linux (older/Xen) | `/dev/xvda` | `/dev/xvdb`, `/dev/xvdc`, ... |
| Linux (NVMe/Nitro) | `/dev/nvme0n1` | `/dev/nvme1n1`, `/dev/nvme2n1`, ... |
| Windows | `C:\` (`/dev/sda1`) | Additional drive letters |

> Modern AWS instances (Nitro-based, all current gen) use **NVMe** device names.

---

#### 2.1.11 Attach / Detach Rules

| Scenario | Allowed |
|---------|---------|
| Attach additional data volume to running instance | ✅ Yes (hot attach) |
| Detach data volume from running instance | ✅ Yes (unmount first) |
| Detach root volume from running instance | ❌ No — must stop instance |
| Increase volume size while running | ✅ Yes (then extend filesystem) |
| Decrease volume size | ❌ Never |
| Move volume to another AZ | ❌ Not directly — snapshot → new volume in target AZ |
| Move volume to another Region | ❌ Not directly — snapshot → copy to Region → new volume |

---

### 2.2 Instance Store (Ephemeral Storage)

**Definition:** Temporary block storage **physically attached** to the host machine your EC2 runs on.

| Property | Detail |
|----------|--------|
| Location | Local NVMe on host hardware |
| Performance | ✅ Extremely high — no network overhead |
| Persistence | ❌ Non-persistent |
| Cost | Included in instance price |
| Attachment | Fixed — cannot attach/detach |
| Identified by | `d` capability letter in instance type (e.g. `i4i`, `m5d`) |

**Behavior by action:**

| Action | Data |
|--------|------|
| **Reboot** | ✅ Preserved |
| **Stop** | ❌ Lost |
| **Terminate** | ❌ Lost |
| **Host failure** | ❌ Lost |

**Use cases:** Temporary cache, buffer, scratch space, batch intermediate results, replica data.

---

#### EBS vs Instance Store — Decision Guide

| Feature | EBS | Instance Store |
|---------|-----|----------------|
| Persistence | ✅ Yes | ❌ No (ephemeral) |
| Location | Network-attached | Local to host |
| Performance | High (ms latency) | ✅ Very high (µs latency) |
| Lifecycle | Independent of instance | Tied to instance |
| Backup | ✅ Snapshots | ❌ No native backup |
| Cost | Billed separately | Included in instance price |
| Best for | OS, databases, permanent data | Cache, temp processing |

---

## 3. Object Storage — Amazon S3

**Definition:** Store data as **objects** (file + metadata + unique key) in **buckets**.

| Property | Detail |
|----------|--------|
| Scalability | Unlimited — no capacity limit |
| Durability | 99.999999999% (11 nines) |
| Availability | 99.99% (Standard class) |
| Access | HTTPS API — not mountable as disk |
| Scope | **Regional** (globally unique bucket names) |
| Max object size | 5 TB |

**S3 Storage Classes (Cost vs Access):**

| Class | Access | Use Case |
|-------|--------|---------|
| **Standard** | Milliseconds | Frequently accessed data |
| **Standard-IA** | Milliseconds | Infrequent access — cheaper storage, retrieval fee |
| **One Zone-IA** | Milliseconds | Infrequent, non-critical (single AZ) |
| **Glacier Instant** | Milliseconds | Archive with instant retrieval |
| **Glacier Flexible** | Minutes–hours | Long-term archive |
| **Glacier Deep Archive** | Hours (up to 12h) | Cheapest — regulatory archive |
| **Intelligent-Tiering** | Milliseconds | Unknown access pattern — auto-moves between tiers |

---

## 4. File Storage

Shared filesystem accessible by **multiple instances simultaneously** — like a NAS.

---

### 4.1 Amazon EFS (Elastic File System)

**Definition:** Managed **NFS** (Network File System) for Linux workloads.

| Property | Detail |
|----------|--------|
| Protocol | NFS v4 |
| OS support | Linux only |
| Scope | **Regional** — spans all AZs in a Region |
| Scaling | ✅ Automatic — grows/shrinks as files are added/removed |
| Access | Multiple EC2 instances simultaneously |
| Performance modes | General Purpose (default), Max I/O (highly parallel) |
| Storage classes | Standard, Infrequent Access (EFS-IA — cheaper) |

---

### 4.2 Amazon FSx (Managed Specialty File Systems)

**Definition:** Fully managed file systems for specific use cases requiring specialty protocols.

| Type | Protocol | OS | Best For |
|------|---------|-----|---------|
| **FSx for Windows** | SMB (Samba) | Windows | Windows workloads, Active Directory integration |
| **FSx for Lustre** | Lustre | Linux | HPC, ML training, high-throughput computing |
| **FSx for NetApp ONTAP** | NFS, SMB, iSCSI | Multi-OS | Enterprise storage migration, hybrid cloud |
| **FSx for OpenZFS** | NFS | Linux | ZFS-based workloads, data migrations |

> **FSx for Lustre** can directly integrate with **S3** — reads/writes back to S3 bucket automatically.
> **FSx for Windows** = the answer whenever a question mentions SMB, Windows Server, or Active Directory.

---

## 5. Complete AWS Storage Comparison ⭐

| Dimension | EBS | Instance Store | S3 | EFS | FSx |
|-----------|-----|---------------|-----|-----|-----|
| Type | Block | Block | Object | File | File |
| Persistence | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Multi-instance | ❌ (io2 only) | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Scope | Single AZ | Tied to host | Regional | Regional | AZ or Regional |
| Scalability | Manual resize | Fixed | Unlimited | Automatic | Manual |
| Access method | Block (mounted) | Block (local) | HTTPS API | NFS | SMB/NFS/Lustre |
| Linux support | ✅ | ✅ | ✅ | ✅ | ✅ (Lustre, ONTAP, ZFS) |
| Windows support | ✅ | ✅ | ✅ | ❌ | ✅ (FSx for Windows) |
| Latency | Low (ms) | Lowest (µs) | Higher (API) | Low (ms) | Low (ms) |
| Cost model | Per GB + IOPS | Included | Per GB stored | Per GB stored | Per GB stored |

---

## 6. Workload → Storage Mapping

| Requirement | Storage Choice | Reason |
|------------|---------------|--------|
| EC2 OS / boot disk | EBS gp3 | Persistent, bootable, cost-efficient |
| Production database (MySQL, Postgres) | EBS gp3 or io2 | IOPS performance, persistence |
| Mission-critical DB (Oracle, SAP HANA) | EBS io2 Block Express | 99.999% durability, sub-ms latency |
| High-speed temp processing | Instance Store | Local NVMe, no network overhead |
| Shared config/data across Linux servers | EFS | NFS, multi-instance, auto-scaling |
| Windows Server shared drive | FSx for Windows | SMB protocol, AD integration |
| HPC / ML training data | FSx for Lustre | Parallel I/O, S3 integration |
| Static website, images, videos | S3 | Cheap, scalable, HTTP accessible |
| Backups and archive | S3 Glacier | Very cheap, long-term |
| Big data / log processing (sequential) | EBS st1 | High throughput HDD, cheap |

---

## 7. EC2 Storage Architecture Patterns

### Pattern 1 — Standard Web Server
```
EC2 Instance
├── EBS gp3 (root) → OS + app code
└── EBS gp3 (data) → logs, config
```

### Pattern 2 — High Performance Database
```
EC2 Instance
├── EBS gp3 (root)  → OS
└── EBS io2         → database data files (high IOPS + 99.999% durability)
```

### Pattern 3 — Batch Processing (Cost-Optimized)
```
EC2 Spot Instance
└── Instance Store → scratch space during processing
    S3             → input data source + output destination
```

### Pattern 4 — Shared Application (Multi-Server)
```
EC2 Instance 1 ─┐
EC2 Instance 2 ─┼── EFS (shared NFS) → shared config, uploads
EC2 Instance 3 ─┘
     │
     └── EBS gp3 (per instance) → OS
```

---

## 8. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| gp2 is fine for new workloads | Always use gp3 — cheaper, faster, independent IOPS tuning |
| EBS can be attached across AZs | EBS is AZ-specific — must be in same AZ as instance |
| EBS snapshots go to your S3 bucket | Snapshots go to AWS-managed S3 — not visible in your S3 |
| Instance store survives stop | Instance store is lost on stop/terminate — only survives reboot |
| EFS works on Windows | EFS uses NFS — Linux only; use FSx for Windows for Windows |
| st1/sc1 can be root volumes | HDD volumes cannot boot — only SSD volumes are bootable |
| io2 is always better than gp3 | io2 costs ~13× more — only justify for >16,000 IOPS or 99.999% durability needed |
| Increasing EBS size auto-resizes filesystem | Must also extend the filesystem after volume resize (e.g. `resize2fs` on Linux) |
| EBS snapshots are full backups | Snapshots are **incremental** — only changed blocks stored after first |
| S3 is mountable like a disk | S3 is object storage — accessed via HTTPS API, not mounted as filesystem |

---

## 9. Interview Questions Checklist ✅

- [ ] Name the 3 types of AWS storage — example of each
- [ ] What is EBS? What are its key properties?
- [ ] List all EBS volume types with IOPS and throughput limits
- [ ] gp2 vs gp3 — why always choose gp3?
- [ ] gp3 vs io2 — when does io2 justify the cost?
- [ ] What is the difference between IOPS and Throughput?
- [ ] Which EBS volume types are bootable?
- [ ] What is EBS Multi-Attach? Which volume types support it?
- [ ] What are EBS Snapshots? Are they incremental?
- [ ] Where are EBS Snapshots stored?
- [ ] How do you move an EBS volume to another AZ? Another Region?
- [ ] What happens to EBS when an EC2 instance is terminated?
- [ ] What is Instance Store? When is data lost?
- [ ] Instance Store vs EBS — key differences
- [ ] What is EFS? Which OS does it support?
- [ ] EFS vs FSx — when to use which?
- [ ] FSx types — which for Windows? Which for HPC?
- [ ] What is S3? What durability does it offer?
- [ ] Name S3 storage classes — cheapest for archival?
- [ ] You need shared storage for 3 Linux EC2 instances — what do you use?
- [ ] You need high-speed temp storage for batch jobs — what do you use?
- [ ] How do you encrypt an existing unencrypted EBS volume?
