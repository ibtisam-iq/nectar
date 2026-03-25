# AWS AMI, Snapshots & Lifecycle

---

## 1. EBS Snapshots

### 1.1 Definition

> A point-in-time backup of an EBS volume — stored in AWS-managed S3
> (not visible in your S3 console, not accessible via S3 API).

### 1.2 Core Characteristics

| Property | Detail |
|----------|--------|
| Storage backend | AWS-managed S3 (internal — you cannot browse it) |
| Type | **Incremental** — only changed blocks after first snapshot |
| Scope | **Regional** — snapshot belongs to the Region it was created in |
| AZ constraint | ❌ None — snapshot is Region-scoped, not AZ-scoped |
| Visibility | Private (default), shared with specific accounts, or public |
| Consistency | Crash-consistent by default; application-consistent if configured |

---

### 1.3 Incremental Snapshot Mechanics ⭐

```
Day 1 → Snapshot A  (full: 20 GB used data)        → stores 20 GB
Day 2 → Snapshot B  (5 GB changed since A)          → stores 5 GB
Day 3 → Snapshot C  (3 GB changed since B)          → stores 3 GB
Total S3 usage = 28 GB  (not 60 GB)
```

**Point-in-time rule:**
- Snapshot captures the **exact state at moment of initiation**
- Data written after snapshot starts → NOT included in that snapshot
- Snapshot completion may take time, but captured data is fixed at start time

---

### 1.4 Snapshot Size vs Volume Size

Snapshot size = **actual used data**, not allocated volume size.

```
Volume size:    100 GB (allocated)
Data written:   8 GB (actual)
Snapshot size:  ≈ 8 GB  (billed amount)
```

> You are billed per GB of snapshot data stored in S3.

---

### 1.5 Snapshot Deletion Behavior ⭐

Snapshots are incremental but **logically independent** — each can be deleted safely.

```
Snapshot A ──┐
Snapshot B ──┤── shared blocks stay
Snapshot C ──┘

Delete Snapshot B:
→ Blocks unique to B → permanently deleted
→ Blocks shared with A or C → preserved in remaining snapshots
→ No data loss for A or C
```

> AWS handles reference counting internally.
> You never need to delete snapshots in order — delete any, data integrity is maintained.

---

### 1.6 Snapshot Tiers ⭐

| Tier | Cost | Restore Speed | Use Case |
|------|------|--------------|---------|
| **Standard** (default) | ~$0.05/GB/month | Immediate | Active backup, recent history |
| **Archive** | ~75% cheaper | 24–72 hours to restore | Long-term retention, compliance |
| **Recycle Bin** | Same as original tier | Immediate (after restore from bin) | Accidental deletion protection |

---

### 1.7 Fast Snapshot Restore (FSR) ⭐

**Problem:** When you create a volume from a snapshot, blocks are loaded lazily from S3.
First read of any block has higher latency until it is fully initialized.

**Solution:** Fast Snapshot Restore pre-initializes all blocks — volumes are **fully ready immediately**.

| Feature | Detail |
|---------|--------|
| Cost | Additional charge per DSU (per AZ, per snapshot) |
| Best for | Auto-scaling groups, disaster recovery volumes |
| Alternative (free) | Pre-warm by reading entire volume after creation: `dd if=/dev/xvdf of=/dev/null` |

---

### 1.8 Recycle Bin

Protects against accidental snapshot/AMI deletion.

```
You delete snapshot
    ↓
Moves to Recycle Bin (not permanently gone)
    ↓
Retained for configured period (1 day → 1 year)
    ↓
Restore before expiry → immediately available
OR
Period expires → permanently deleted
```

**Rules:**
- Snapshot in Recycle Bin → cannot be used until restored
- When deleted, all sharing permissions are automatically removed
- Restored → sharing permissions are reinstated
- Cannot manually delete from Recycle Bin — only expires or is restored

---

### 1.9 Snapshot Operations

| Operation | Scope | Notes |
|-----------|-------|-------|
| Create snapshot | Volume → same Region | Can be done while instance is running |
| Copy snapshot | → Another Region | Enables cross-Region DR |
| Copy snapshot | → Another account | Grant permissions first |
| Share snapshot | With specific account | Account can create volume/AMI |
| Make public | All accounts | Anyone can create volume from it |
| Create volume | → Any AZ in same Region | Choose AZ at creation |
| Create AMI | Snapshot → launch template | See AMI section |
| Archive | Standard → Archive tier | 75% cost saving, slow restore |

```bash
# Create snapshot
aws ec2 create-snapshot --volume-id vol-xxxxxxxx --description "prod-db-backup"

# Copy to another Region
aws ec2 copy-snapshot \
  --source-region us-east-1 \
  --source-snapshot-id snap-xxxxxxxx \
  --region ap-south-1 \
  --description "DR copy"

# Enable Fast Snapshot Restore
aws ec2 enable-fast-snapshot-restores \
  --availability-zones us-east-1a \
  --source-snapshot-ids snap-xxxxxxxx
```

---

### 1.10 Crash-Consistent vs Application-Consistent

| Type | What It Captures | Risk |
|------|----------------|------|
| **Crash-consistent** (default) | Everything written to disk at that instant | In-memory data not flushed = possible inconsistency for DBs |
| **Application-consistent** | Quiesces app, flushes writes, then snapshots | Clean, safe for databases |

**How to get application-consistent snapshots:**
- Linux: Freeze filesystem → snapshot → unfreeze (`fsfreeze`)
- Use **AWS Systems Manager (SSM)** pre-snapshot scripts
- Use **AWS Backup** (handles consistency automatically)

---

### 1.11 Amazon Data Lifecycle Manager (DLM)

Automates snapshot and AMI creation/deletion without custom scripts.

```
DLM Policy:
  Target:    EC2 instances with tag: backup=true
  Schedule:  Daily at 02:00 UTC
  Retain:    15 most recent snapshots
  Copy to:   ap-south-1 (cross-Region DR)
  ───────────────────────────────────────
  Day 1  → creates snap-001
  Day 2  → creates snap-002
  ...
  Day 16 → creates snap-016, deletes snap-001
```

**Features:**
- Target by EC2 tags or specific volumes
- Multiple schedules (hourly, daily, weekly)
- Cross-Region copy on schedule
- Cross-account copy
- Fast Snapshot Restore enablement
- AMI lifecycle management

---

## 2. Amazon Machine Image (AMI)

### 2.1 Definition

> An AMI is a **complete launch template** for an EC2 instance —
> containing OS, configuration, software, and one or more EBS snapshots.

### 2.2 What an AMI Contains

```
AMI
 ├── Root volume snapshot    (OS + installed software)
 ├── Additional volume snapshots (if any data volumes)
 ├── Launch permissions       (who can use this AMI)
 ├── Block device mapping     (which snapshots → which volumes, at what size)
 └── Virtualization type      (HVM or PV — always HVM for current gen)
```

---

### 2.3 AMI Backing Type ⭐

| Type | Root Volume | Stop Support | Snapshot | Common? |
|------|------------|-------------|---------|---------|
| **EBS-backed** | EBS volume | ✅ Can stop | ✅ Yes | ✅ Default and standard |
| **Instance store-backed** | Instance store (S3-stored template) | ❌ Cannot stop — only terminate | ❌ No snapshot possible | Rare — legacy use |

> 99% of EC2 instances today are **EBS-backed**.
> Instance store-backed AMIs exist but are specialized — you cannot stop the instance, only reboot or terminate.

---

### 2.4 AMI Creation Flow

```
Running EC2 Instance
     ↓
Create AMI (AWS Console / CLI)
     ↓
AWS pauses instance writes briefly (or uses no-reboot flag)
     ↓
EBS snapshots created for all attached volumes
     ↓
AMI registered (AMI ID: ami-xxxxxxxxxxxxxxxxx)
     ↓
New EC2 launched from AMI → identical environment
```

**No-reboot flag:**
- Default behavior = instance is briefly quiesced for consistency
- `--no-reboot` flag = snapshot taken without stopping I/O → risk of crash-consistent state for databases

---

### 2.5 AMI Properties

| Property | Detail |
|----------|--------|
| Scope | **Regional** — AMI exists in the Region where created |
| Copy to Region | Must explicitly copy — creates new AMI ID in target Region |
| Copy to account | Share AMI → target account copies it to own account |
| Encryption | AMI with encrypted snapshots → launched volumes are encrypted |
| Copy + encrypt | Can encrypt unencrypted AMI during copy |
| Deregister | Deleting AMI = deregistering it — **does NOT delete underlying snapshots** |
| Permissions | Private (default), shared with specific accounts, or public |

---

### 2.6 AMI Lifecycle ⭐

```
Create AMI
    ↓
pending → available (ready to use)
    ↓
Optional: Copy to other Region/account
    ↓
Deregister AMI  ←  does NOT auto-delete snapshots
    ↓
Manually delete orphaned snapshots
```

> **Important:** Deregistering an AMI leaves its backing snapshots intact.
> You must delete them separately to stop being billed.

---

### 2.7 AMI Types by Source

| Type | Description | Use Case |
|------|-------------|---------|
| **AWS-provided** | Amazon Linux, Ubuntu, Windows Server, etc. | Standard base OS |
| **AWS Marketplace** | Vendor-provided (commercial software pre-installed) | WordPress, Nginx, DB appliances |
| **Community AMIs** | Shared publicly by other AWS users | Use with caution — not vetted by AWS |
| **Custom / Golden AMI** | Created by you from a configured instance | Production standard image |

---

### 2.8 Golden AMI Pattern

Build once → launch many times with identical configuration.

```
Base AWS AMI (Amazon Linux 2023)
     ↓
Launch instance
     ↓
Install: Docker, Node.js, CloudWatch Agent, security patches
Configure: app user, SSH hardening, environment variables
Test: health checks, smoke tests
     ↓
Create Golden AMI
     ↓
Auto Scaling Group uses Golden AMI → every instance identical
```

**Benefits:**
- Faster launch (no user data install time)
- Consistent configuration across all instances
- Auditable — AMI ID tied to a specific version

---

## 3. Snapshot vs AMI — Complete Comparison ⭐

| Dimension | EBS Snapshot | AMI |
|-----------|-------------|-----|
| **Purpose** | Backup a single volume | Template to launch a complete instance |
| **Scope** | Single EBS volume | Entire instance (all volumes + config) |
| **Contains** | Block data | Snapshots + launch permissions + block device mapping |
| **Direct use** | Create volume → attach to EC2 | Launch new EC2 directly |
| **Bootable** | Not directly | ✅ Yes — that's its purpose |
| **Incremental** | ✅ Yes | Backed by incremental snapshots |
| **Cross-Region** | Copy snapshot | Copy AMI (copies snapshots too) |
| **Deregister/Delete** | Delete directly | Deregister AMI, then manually delete snapshots |
| **Recycle Bin** | ✅ Supported | ✅ Supported (EBS-backed AMIs) |

---

## 4. Volume → Snapshot → AMI Relationship

```
EBS Volume
  │
  ├─── Create Snapshot ──→  EBS Snapshot
  │                              │
  │                              ├── Create Volume → attach to any instance in Region
  │                              ├── Copy to another Region
  │                              ├── Share with another account
  │                              └── Register as AMI ──→  AMI
  │                                                          │
  └─────────────────────────────────────────────────────────┘
                                          Launch EC2 from AMI
```

---

## 5. Cross-Region & Cross-Account Operations

### Cross-Region (Disaster Recovery Pattern)

```
us-east-1 (primary)                ap-south-1 (DR)
  EC2 Instance                          │
  → EBS Snapshot                        │
  → Copy Snapshot ──────────────────────→ Snapshot copy
  → Copy AMI ───────────────────────────→ AMI copy
                                         → Launch EC2 (failover)
```

> When you copy an AMI to another Region, its underlying snapshots are also copied.
> Each Region creates a new unique AMI ID and snapshot ID.

### Cross-Account Sharing

```
Account A (owner):
  → Modify snapshot permissions → add Account B
  → Modify AMI permissions → add Account B

Account B (recipient):
  → Copy snapshot/AMI to own account (own the copy)
  → Can launch instances from shared AMI
  → Cannot further share unless they own the copy
```

---

## 6. AWS Backup (Centralized Lifecycle Management)

**Amazon Data Lifecycle Manager (DLM)** handles EBS/AMI automation.
**AWS Backup** is the broader service for centralized backup across multiple AWS services.

| Feature | DLM | AWS Backup |
|---------|-----|-----------|
| Scope | EBS volumes, AMIs | EC2, EBS, RDS, DynamoDB, EFS, FSx, S3, and more |
| Consistency | Crash-consistent | ✅ Application-consistent (using SSM) |
| Cross-account | ✅ Yes | ✅ Yes |
| Cross-Region | ✅ Yes | ✅ Yes |
| Compliance | Basic | ✅ WORM (Vault Lock), audit manager |
| Use case | EBS-only automation | Multi-service, enterprise backup strategy |

---

## 7. Architecture Patterns

### Pattern 1 — Automated Daily Backup

```
DLM Policy
  → Tag: Environment=production
  → Daily snapshot at 03:00 UTC
  → Retain 30 days
  → Copy to ap-south-1 (DR Region)
```

### Pattern 2 — Blue/Green Deployment

```
v1 AMI (current)           v2 AMI (new release)
  → Launch v1 ASG             → Launch v2 ASG
  → Validate health            → Shift traffic
  → Keep v1 AMI as rollback    → Deregister v1 AMI + delete snapshots
```

### Pattern 3 — DR Failover

```
Primary Region (us-east-1):
  EC2 → Daily DLM snapshot → Copy to ap-south-1

DR Region (ap-south-1):
  Snapshot → Create volume → Launch instance (failover)
  OR
  AMI copy → Launch EC2 directly
```

---

## 8. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Snapshots are full backups each time | First snapshot is full; all subsequent are **incremental** |
| Deleting a snapshot corrupts other snapshots | Each snapshot is logically independent — delete any safely |
| Snapshot size = volume size | Snapshot size = actual used data, not allocated |
| Deleting an AMI deletes its snapshots | Deregistering AMI does **not** delete snapshots — must delete manually |
| AMIs are global | AMIs are **Regional** — must copy to use in another Region |
| Copying AMI doesn't copy snapshots | Copying AMI to another Region automatically copies its backing snapshots |
| Instance store-backed instances can be stopped | Cannot be stopped — only rebooted or terminated |
| FSR is free | Fast Snapshot Restore has additional cost per DSU |
| Recycle Bin snapshots can be used immediately | Must restore from Recycle Bin first before use |
| Application-consistent = default | Default is crash-consistent; app-consistent requires fsfreeze or SSM scripts |

---

## 9. Interview Questions Checklist ✅

- [ ] What is an EBS Snapshot? Where is it stored?
- [ ] Are snapshots full or incremental? Explain incremental mechanics
- [ ] What is the difference between snapshot size and volume size?
- [ ] What happens when you delete a snapshot that shares blocks?
- [ ] What is an AMI? What does it contain?
- [ ] EBS-backed AMI vs Instance store-backed AMI — key differences?
- [ ] Can you stop an instance store-backed instance?
- [ ] What is a Golden AMI? Why use it over User Data?
- [ ] What is the flow from EC2 instance → Snapshot → AMI → new EC2?
- [ ] Does deregistering an AMI delete its snapshots?
- [ ] How do you move an AMI to another Region?
- [ ] How do you share a snapshot or AMI with another AWS account?
- [ ] What is Fast Snapshot Restore? Why is it needed?
- [ ] What is EBS Snapshot Archive? What is the restore time?
- [ ] What is the Recycle Bin? What happens to a snapshot inside it?
- [ ] Crash-consistent vs application-consistent — difference?
- [ ] What is Amazon Data Lifecycle Manager (DLM)?
- [ ] What is AWS Backup? How does it differ from DLM?
- [ ] When you copy an AMI to another Region — what else gets copied?
- [ ] Snapshot vs AMI — complete comparison (5 dimensions)
