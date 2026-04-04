# AWS Databases — RDS

## 1. Database Types in AWS

| Category | Type | AWS Service | Engine |
|---------|------|------------|--------|
| **Relational** | SQL | RDS | MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, IBM Db2 |
| **Relational** | SQL (Cloud-native) | Aurora | MySQL-compatible, PostgreSQL-compatible |
| **NoSQL** | Key-Value | DynamoDB | Proprietary |
| **NoSQL** | Document | DocumentDB | MongoDB-compatible |
| **NoSQL** | Columnar | Keyspaces | Apache Cassandra-compatible |
| **NoSQL** | Graph | Neptune | Gremlin, SPARQL, openCypher |
| **NoSQL** | Time Series | Timestream | Proprietary |
| **Cache** | In-Memory | ElastiCache | Redis, Memcached |
| **Search** | Full-text | OpenSearch | Elasticsearch-compatible |
| **Ledger** | Immutable | QLDB | Proprietary |

---

## 2. Why RDS Exists — Three Options Compared

| Aspect | On-Premises | EC2 + DB Engine | RDS |
|--------|------------|----------------|-----|
| Hardware | You manage | AWS manages | AWS manages |
| OS patching | You manage | You manage | AWS manages |
| DB engine install | You manage | You manage | AWS manages |
| Backups | You manage | You manage | AWS manages |
| Replication | You configure | You configure | AWS manages |
| Failover | You configure | You configure | AWS manages |
| Scaling | You procure hardware | You resize EC2 | You adjust settings |
| **You manage** | Everything | Schema, queries, indexes | Schema, queries, indexes, tuning |

> The key trade-off of RDS: **you lose OS-level access** (no SSH to the DB instance)
> in exchange for AWS managing all infrastructure operations.
> If you need OS access (custom plugins, special OS config), use **RDS Custom**
> (available for Oracle and SQL Server only).

---

## 3. RDS Architecture — Mental Model ⭐

```
RDS DB Instance = EC2 instance (hidden) + EBS volume + RDS management layer

┌─────────────────────────────────────────────┐
│              RDS DB Instance                │
│  ┌─────────────────────────────────────┐    │
│  │  DB Engine (MySQL / PostgreSQL / …) │    │
│  └────────────────┬────────────────────┘    │
│                   │ reads/writes            │
│  ┌────────────────▼────────────────────┐    │
│  │         EBS Storage (gp3/io2)       │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  Security Group → controls port access      │
│  VPC Subnet     → network placement         │
│  IAM Role       → access to AWS services    │
│  Parameter Group→ DB engine config          │
└─────────────────────────────────────────────┘
```

---

## 4. Storage Types (EBS-backed)

| Type | IOPS | Use Case | Notes |
|------|------|---------|-------|
| **gp2** | 3 IOPS/GB (burst to 3,000) | General purpose | Legacy — use gp3 for new |
| **gp3** | 3,000 base (up to 16,000) | General purpose | Cheaper than gp2, decouple IOPS from size |
| **io1** | Up to 64,000 IOPS | High performance | Legacy provisioned IOPS |
| **io2 / io2 Block Express** | Up to 256,000 IOPS | Critical production | Highest durability + IOPS |

**Storage Auto Scaling:**
```
Enable max storage threshold (e.g., 1 TB max)
  → RDS automatically increases storage when:
     - Free storage < 10% of total
     - Low storage lasts > 5 minutes
     - 6 hours since last auto-scale
  → No downtime for storage increase
```

---

## 5. Instance Classes

| Class | Type | Use Case | Example |
|-------|------|---------|---------|
| **T** | Burstable | Dev/test, low traffic | db.t3.medium, db.t4g.large |
| **M** | General Purpose | Balanced workloads | db.m6i.xlarge |
| **R** | Memory Optimized | High-performance DBs, large datasets | db.r6g.2xlarge |
| **X** | Memory Intensive | In-memory analytics | db.x2idn |
| **Optimized Reads** | NVMe SSD cache | Read-heavy workloads | db.r6gd (local NVMe) |

---

## 6. Networking ⭐

### DB Subnet Group

A logical group of subnets across multiple AZs — RDS deploys into these subnets.

```
Requirements:
  - Must span at least 2 AZs
  - Use private subnets (no public access to DB)
  - Separate from application subnets (best practice)

Example:
  subnet-db-1a (10.0.10.0/24) AZ-1a
  subnet-db-1b (10.0.11.0/24) AZ-1b
  subnet-db-1c (10.0.12.0/24) AZ-1c
```

### Security Group for RDS

```
RDS SG inbound rules:
  Allow TCP 3306 (MySQL) from App-SG   ← reference SG ID, not IP
  Allow TCP 5432 (PostgreSQL) from App-SG

Never:
  Allow TCP 3306 from 0.0.0.0/0        ← never expose DB to internet
```

---

## 7. Read Replicas vs Multi-AZ ⭐ (Most Critical Distinction)

This is the #1 most tested RDS concept — they are completely different:

| Dimension | Read Replicas | Multi-AZ |
|-----------|--------------|---------|
| **Purpose** | Scale **reads** | High **availability** |
| **Replication** | **Asynchronous** (slight lag) | **Synchronous** (zero data loss) |
| **Use standby for traffic?** | ✅ Yes — queries go to replicas | ❌ No — standby is passive |
| **Failover** | Manual — you promote it | **Automatic** — DNS flips |
| **Count** | Up to 15 | 1 standby (Multi-AZ instance) |
| **Cross-region** | ✅ Yes | ❌ No — same region only |
| **Cost** | You pay for replica instance | +~20% instance cost for standby |
| **Promotes to primary?** | Yes — manual promotion breaks replication | Yes — automatic via DNS CNAME flip |

```
Read Replica use case:
  App → write → Primary DB
  App → read  → Read Replica (offload reads)
  Reporting tools → Read Replica (heavy queries don't affect primary)

Multi-AZ use case:
  Primary fails (AZ down, hardware failure)
  → RDS flips DNS CNAME to standby
  → Application reconnects to same endpoint — no code change
  → Failover: ~1–2 minutes (Multi-AZ Instance) [aws.amazon](https://aws.amazon.com/blogs/database/choose-the-right-amazon-rds-deployment-option-single-az-instance-multi-az-instance-or-multi-az-database-cluster/)
```

> **Read Replica is NOT a backup.** It has async replication — if primary data is
> corrupted or deleted, the corruption replicates. Use snapshots for point-in-time backup.

---

## 8. Deployment Options ⭐

### Single-AZ

```
[Primary Instance] ← all reads + writes
One AZ — instance failure = downtime until manual recovery
Use: Dev/test only
```

### Multi-AZ Instance (Classic HA)

```
[Primary Instance] ──sync replication──→ [Standby Instance]
Same Region, different AZ              ← passive, no traffic
Failover time: ~1–2 minutes [aws.amazon](https://aws.amazon.com/blogs/database/choose-the-right-amazon-rds-deployment-option-single-az-instance-multi-az-instance-or-multi-az-database-cluster/)
RPO (data loss): ~0 (synchronous)
RTO (downtime): ~1–2 minutes
```

### Multi-AZ Cluster (New — 2022)

```
[Writer Instance]
    ├── sync replication ──→ [Reader Instance 1] AZ-2  ← serves reads
    └── sync replication ──→ [Reader Instance 2] AZ-3  ← serves reads
Failover time: ~25–75 seconds [aws.amazon](https://aws.amazon.com/blogs/database/choose-the-right-amazon-rds-deployment-option-single-az-instance-multi-az-instance-or-multi-az-database-cluster/)
Benefit over Multi-AZ Instance: readers serve traffic (not passive)
```

---

## 9. Backups ⭐

### Automated Backups

```
Retention: 1–35 days (default: 7 days; set to 0 to disable)
Backup window: daily snapshot during configured time window
Transaction logs: backed up every 5 minutes → enables PITR to any second

Point-in-Time Recovery (PITR):
  Restore DB to any second within retention window
  Creates NEW DB instance (does not overwrite existing)
```

### Manual Snapshots

```
User-triggered
Retained indefinitely (not affected by retention period)
Can copy to another region → cross-region DR
Can share with another AWS account
Restore → creates new DB instance with restored data
```

### Key Backup Behaviors

| Property | Automated | Manual Snapshot |
|---------|-----------|----------------|
| Retention | 1–35 days | Forever (until you delete) |
| Trigger | Automatic | Manual |
| PITR | ✅ | ❌ (point-in-time to snapshot date only) |
| Survives DB deletion | ❌ (deleted with DB unless final snapshot taken) | ✅ |

---

## 10. Security

### Encryption at Rest

```
Enabled at creation with KMS key (cannot encrypt existing unencrypted instance)
Encrypts: DB instance + automated backups + read replicas + snapshots

To encrypt existing unencrypted DB:
  1. Create snapshot
  2. Copy snapshot with encryption enabled
  3. Restore from encrypted snapshot
  4. Point application to new instance
```

### Encryption in Transit

```
SSL/TLS enforced by parameter group setting:
  MySQL: rds.force_ssl = 1
  PostgreSQL: rds.force_ssl = 1
```

### Authentication

| Method | How | Best For |
|--------|-----|---------|
| **Password** | Username + password in connection string | Basic |
| **IAM Auth** | Generate IAM auth token (15 min TTL), no long-lived password | EC2/Lambda connecting to RDS |
| **Kerberos** | Microsoft AD integration | Enterprise, Windows environments |

```
IAM Authentication flow:
  1. EC2 calls aws rds generate-db-auth-token (requires IAM permission)
  2. Token valid for 15 minutes
  3. Use token as password in DB connection
  4. RDS validates token against IAM — no password stored anywhere ✅
```

---

## 11. RDS Proxy ⭐

Solves the **connection explosion** problem — especially Lambda → RDS:

```
Problem:
  Lambda scales to 1,000 concurrent functions
  Each opens a DB connection
  MySQL max connections: ~100–200 for small instances
  → Connection errors, DB overload ❌

With RDS Proxy:
  Lambda → RDS Proxy (connection pool: 100 connections to DB)
  → Proxy multiplexes 1,000 Lambda connections onto 100 DB connections ✅
  → DB sees manageable connection count

Also:
  - IAM authentication enforced at proxy level
  - Secrets Manager integration (credentials never in Lambda code)
  - Failover faster: ~66% reduction in failover time (proxy handles reconnection)
```

---

## 12. Monitoring ⭐

| Tool | Level | Key Metrics |
|------|-------|------------|
| **CloudWatch Metrics** | Instance level | CPU, FreeableMemory, DatabaseConnections, ReadIOPS, WriteIOPS |
| **Enhanced Monitoring** | OS level (50+ metrics) | Per-process CPU, memory breakdown, file system |
| **Performance Insights** | SQL/query level | Top SQL by wait type, load, execution time |

```
Performance Insights:
  Free: 7 days retention
  Paid: up to 2 years
  Shows: which SQL queries are causing load, what they're waiting for
  Use: identify slow queries without needing slow query log
```

---

## 13. Aurora — AWS Cloud-Native Database ⭐

Aurora is NOT the same as RDS with MySQL/PostgreSQL. It's a reimagined architecture:

### Architecture Difference

```
Standard RDS (MySQL):                    Aurora:
  [Compute] → [EBS Volume]               [Compute (Primary + 15 Replicas)]
  One EBS per instance                       ↓
  Replication copies data                [Shared Cluster Volume]
  Replica lag: seconds                    6 copies of data across 3 AZs
                                          Replicas share storage — no copy needed
                                          Replica lag: milliseconds
```

### Aurora Key Numbers

| Property | Value |
|----------|-------|
| Copies of data | **6 copies** across 3 AZs (2 per AZ) |
| Survives losing | Up to 2 copies without write impact; 3 copies without read impact |
| Max read replicas | **15** (vs 5 for standard RDS) |
| Storage auto-scale | Grows in 10 GB increments up to **128 TB** automatically |
| Failover time | **~25–75 seconds** (faster than RDS Multi-AZ 1–2 min) |
| Backtrack | Rewind DB to any point in last 72 hours — no restore from snapshot needed |
| Endpoints | Writer endpoint, Reader endpoint (load-balanced across all replicas) |

```
Aurora Endpoints:
  Writer endpoint:  my-cluster.cluster-xyz.us-east-1.rds.amazonaws.com
    → Always points to primary (even after failover)

  Reader endpoint:  my-cluster.cluster-ro-xyz.us-east-1.rds.amazonaws.com
    → Load-balances reads across all Aurora Replicas
```

### Aurora Serverless v2

```
Automatically scales compute in fine-grained increments (0.5 ACU units)
Pay per ACU-second used — no idle cost
Scales from minimum to maximum ACU in ~seconds
Use case: unpredictable workloads, dev/test, multitenant apps
```

### Aurora Global Database

```
One primary Region + up to 5 secondary read-only Regions
Replication lag: < 1 second (storage-based replication, no DB impact)

Use case:
  Global apps needing low latency reads in multiple continents
  DR: promote secondary to primary in < 1 minute if primary region fails

Failover types:
  Managed failover: RDS orchestrates promotion (~1 min)
  Manual failover: you control the switch
```

---

## 14. Multi-AZ vs Read Replicas vs Aurora Replicas ⭐

| Feature | RDS Multi-AZ | RDS Read Replicas | Aurora Replicas |
|---------|-------------|-----------------|----------------|
| Purpose | HA failover | Read scaling | Read scaling + HA |
| Replication | Synchronous | Asynchronous | Synchronous (shared storage) |
| Serves reads? | ❌ Standby passive | ✅ Yes | ✅ Yes |
| Failover | Automatic | Manual promotion | Automatic (~25–75s) |
| Max count | 1 standby | 15 | 15 |
| Cross-region | ❌ | ✅ | ✅ (Global DB) |
| Lag | 0 | Seconds | Milliseconds |

---

## 15. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Multi-AZ standby serves reads | Multi-AZ standby is **passive** — zero traffic; use Read Replicas for reads |
| Read Replica = automatic failover | Read Replicas require **manual promotion** — no automatic failover |
| Multi-AZ replication is async | Multi-AZ uses **synchronous** replication — zero data loss |
| Read Replicas prevent data corruption | Replication is async — deletions and corruptions replicate to replicas |
| Aurora is just faster RDS | Aurora uses shared cluster storage — architecturally different, not just faster |
| Aurora failover same as RDS Multi-AZ | Aurora: 25–75s; RDS Multi-AZ Instance: ~1–2 min |
| Cannot encrypt existing RDS DB | True — but workaround: snapshot → encrypt copy → restore new instance |
| RDS Proxy needed for EC2 apps | RDS Proxy primarily solves Lambda → RDS connection pooling; EC2 with small connection count doesn't need it |
| Automated backups persist after DB deletion | Automated backups **deleted with DB** unless you take a final manual snapshot |
| Backup retention default is 0 (off) | Default retention is **7 days** (set to 0 explicitly to disable) |

---

## 16. Interview Questions Checklist

- [ ] Why use RDS over EC2 + database? What does AWS manage?
- [ ] What does RDS Custom solve? (OS access for Oracle/SQL Server)
- [ ] Read Replicas vs Multi-AZ — purpose, replication type, failover
- [ ] Multi-AZ Instance vs Multi-AZ Cluster — key differences, failover times
- [ ] Can Multi-AZ standby serve read traffic? (No)
- [ ] How do you enable read scaling on standard RDS?
- [ ] What is DB Subnet Group? Why must it span 2+ AZs?
- [ ] How does IAM Authentication work for RDS?
- [ ] What is RDS Proxy and when do you need it?
- [ ] Automated vs manual snapshot — retention, PITR, behavior on DB deletion
- [ ] How do you encrypt an existing unencrypted RDS instance?
- [ ] Aurora vs RDS MySQL — three key architectural differences
- [ ] How many copies does Aurora store? In how many AZs?
- [ ] Aurora Serverless v2 — when to use vs provisioned?
- [ ] Aurora Global Database — max secondary regions, replication lag, failover time
- [ ] What is Aurora Backtrack? When is it useful?
- [ ] Storage Auto Scaling — what triggers it?
- [ ] Performance Insights vs Enhanced Monitoring vs CloudWatch — differences

## Nectar
