# RDS Deployment Options

## 1. Core Idea

Deployment options define how your database is distributed across infrastructure for
**availability**, **performance**, and **fault tolerance**. Each tier adds capability
at higher cost and complexity.

```
Single-AZ  →  Multi-AZ Instance  →  Multi-AZ Cluster  →  Aurora
 (Basic)        (HA only)           (HA + Read Scale)   (Max perf)
```

---

## 2. Single-AZ DB Instance

```
┌──────────────────────────┐
│       AZ-1               │
│  ┌─────────────────┐     │
│  │  DB Instance    │     │
│  │  Read + Write   │     │
│  └─────────────────┘     │
└──────────────────────────┘
```

| Property | Value |
|----------|-------|
| Instances | 1 |
| Failover | ❌ None (manual recovery) |
| Read scaling | ❌ No |
| RPO | High (data since last backup can be lost) |
| RTO | High (minutes to hours for manual recovery) |
| Use case | Dev/test, non-critical workloads |

---

## 3. Multi-AZ DB Instance ⭐

```
┌─────────────────┐         ┌─────────────────┐
│      AZ-1       │         │      AZ-2        │
│                 │         │                  │
│ ┌─────────────┐ │ ──sync──→ ┌─────────────┐ │
│ │   Primary   │ │  repl.  │ │   Standby   │ │
│ │ Read+Write  │ │         │ │  PASSIVE ❌  │ │
│ └─────────────┘ │         │ └─────────────┘ │
└─────────────────┘         └─────────────────┘
         ↑
  Single endpoint (DNS)
  points here always
```

### Replication — Synchronous

```
App writes → Primary receives → MUST sync to Standby → write acknowledged
(write blocked until Standby confirms receipt)
Typical additional write latency: 2–5ms
Benefit: zero data loss — Standby always has every committed transaction
```

### Failover Mechanics — DNS CNAME Flip ⭐

```
Step 1: RDS detects Primary failure (AZ down, storage failure, OS crash…)
Step 2: Standby promoted to NEW Primary
Step 3: RDS updates DNS record → CNAME flips to new Primary's IP
Step 4: Your app reconnects using same endpoint string (no code change)
Step 5: Old Primary (if recoverable) becomes new Standby
        Old Primary does NOT come back as Primary
Failover time: 60–120 seconds [docs.aws.amazon](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.Failover.html)
```

> **Critical:** Your application must use the **DNS endpoint**, never hardcode the IP.
> IP changes during failover — DNS endpoint stays the same.

### What Triggers Automatic Failover

| Trigger | Example |
|---------|---------|
| AZ outage | AWS data center failure |
| Primary instance failure | Hardware failure, OS crash |
| Storage failure | EBS volume issue |
| DB engine crash | Process killed, OOM |
| Network loss | Primary loses network connectivity |
| **Manual** | Reboot → "Reboot with Failover" option |

### Forcing a Failover (Testing)

```bash
# Test your application's failover handling without a real outage
aws rds reboot-db-instance \
  --db-instance-identifier my-prod-db \
  --force-failover
# → RDS fails over to standby, ~60-120s downtime
# → Use this in test environments regularly to validate app resilience
```

### Multi-AZ Instance Properties

| Property | Value |
|----------|-------|
| Instances | 2 (Primary + Standby) |
| Replication | Synchronous |
| Standby serves traffic | ❌ Passive — never receives queries |
| Failover | ✅ Automatic (DNS flip) |
| Failover time | **60–120 seconds** |
| RPO | ~0 (synchronous — no data loss) |
| RTO | ~60–120 seconds |
| Use case | Production HA |

---

## 4. Multi-AZ DB Cluster ⭐

```
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│      AZ-1       │   │      AZ-2       │   │      AZ-3       │
│                 │   │                 │   │                 │
│ ┌─────────────┐ │   │ ┌─────────────┐ │   │ ┌─────────────┐ │
│ │   Writer    │─┼───┼→│  Reader-1   │ │   │ │  Reader-2   │ │
│ │ Read+Write  │ │   │ │  Readable ✅ │ │  │ │  Readable ✅ │ │
│ └─────────────┘ │   │ └─────────────┘ │   │ └─────────────┘ │
└─────────────────┘   └─────────────────┘   └─────────────────┘
         ↑                     ↑
  Writer endpoint        Reader endpoint
  (write traffic)        (load-balanced reads)
```

### Replication — Semi-Synchronous

```
App writes → Writer → MUST acknowledge by at least 1 Reader → confirmed
(not all readers, but at least one must confirm → faster than full sync)
PostgreSQL cluster: reader with lowest lag is promoted on failover
MySQL cluster: both readers must apply outstanding transactions
```

### Three Dedicated Endpoints

| Endpoint Type | Points To | Purpose |
|--------------|----------|---------|
| **Cluster (Writer) endpoint** | Current Writer | All writes + general connections |
| **Reader endpoint** | Load-balanced across Readers | Read-only queries |
| **Instance endpoints** | Specific instance | Direct access (diagnostic only) |

> Always use **cluster endpoint** for writes and **reader endpoint** for reads.
> Never use instance endpoints in production — they break during failover.

### Failover Behavior

```
Writer fails
  → RDS selects reader with least replication lag
  → Promotes it to new Writer
  → Reader endpoint automatically adjusts
  → Cluster endpoint points to new Writer

Failover time: < 35 seconds [docs.aws.amazon](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/multi-az-db-clusters-concepts-failover.html)
(vs 60–120s for Multi-AZ Instance)

MySQL: BOTH remaining readers apply outstanding transactions → then promote
PostgreSQL: reader with LOWEST lag promoted → applies remaining transactions
```

### Multi-AZ Cluster Properties

| Property | Value |
|----------|-------|
| Instances | 3 (1 Writer + 2 Readers) |
| Replication | Semi-synchronous |
| Readers serve traffic | ✅ Yes — active read scaling |
| Failover | ✅ Automatic |
| Failover time | **< 35 seconds** |
| RPO | ~0 |
| RTO | ~35 seconds |
| Use case | Production HA + read scaling |

---

## 5. Head-to-Head: All Deployment Options ⭐

| Feature | Single-AZ | Multi-AZ Instance | Multi-AZ Cluster |
|---------|-----------|------------------|----------------|
| Instance count | 1 | 2 | 3 |
| Replication | None | Synchronous | Semi-synchronous |
| Standby usable for reads | — | ❌ Passive | ✅ Active |
| Automatic failover | ❌ | ✅ | ✅ |
| Failover time | Manual | 60–120s | < 35s |
| RPO | High | ~0 | ~0 |
| Endpoints | 1 | 1 | 3 (writer + reader + instances) |
| Read scaling | ❌ | ❌ | ✅ |
| Cost | 1× | ~2× | ~3× |

---

## 6. Standby vs Read Replica — Complete Separation ⭐

| Dimension | Multi-AZ Standby | Read Replica |
|-----------|-----------------|-------------|
| **Purpose** | High Availability | Read Scaling / Performance |
| **Replication** | Synchronous | **Asynchronous** |
| **Receives queries** | ❌ Never | ✅ Yes |
| **Automatic failover** | ✅ Yes | ❌ Must manually promote |
| **Data lag** | Zero | Seconds (async lag) |
| **Separate endpoint** | ❌ (uses primary endpoint) | ✅ Own endpoint |
| **Cross-region** | ❌ Same Region only | ✅ Yes |
| **Max count** | 1 | Up to 15 |
| **Cost** | ~2× primary | Each replica = separate instance cost |
| **After promotion** | Becomes primary + new standby created | Becomes standalone DB (replication breaks) |

```
The most common confusion:
  ❌ "My Multi-AZ standby can serve reads during peak traffic"
  ✅ Standby is invisible to your app — it only appears after a failover

  ❌ "Read Replica will automatically become primary if primary fails"
  ✅ Read Replica promotion is a MANUAL action you must trigger
```

---

## 7. RPO & RTO Deep Dive ⭐

```
RPO (Recovery Point Objective) = How much DATA can you lose?
  → Measured in time: "we can tolerate data loss up to X ago"

RTO (Recovery Time Objective) = How fast must you RECOVER?
  → Measured in time: "system must be back within X"

Single-AZ:
  RPO: last automated backup (up to 24h loss)
  RTO: 30 min – several hours (manual intervention)

Multi-AZ Instance:
  RPO: ~0 (synchronous — no committed data lost)
  RTO: 60–120s (DNS flip + reconnection) [docs.aws.amazon](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.Failover.html)

Multi-AZ Cluster:
  RPO: ~0 (semi-synchronous — at least 1 reader confirmed)
  RTO: < 35s [docs.aws.amazon](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/multi-az-db-clusters-concepts-failover.html)

Aurora Multi-AZ:
  RPO: ~0 (6 copies across 3 AZs)
  RTO: ~25s (Aurora optimized failover)

Aurora Global Database:
  RPO: < 1s (storage-level replication)
  RTO: < 1 min (cross-region promotion)
```

---

## 8. Application-Level Connection Handling ⭐

The database can failover perfectly — but your app must handle it correctly:

### What Breaks During Failover

```
1. TCP connections to old Primary IP → forcefully closed
2. In-flight transactions → rolled back
3. DNS cache → may still point to old IP for TTL duration
```

### Best Practices for Application Resilience

```python
# 1. Always use the DNS endpoint (never hardcode IP)
DB_HOST = "my-db.cluster-xyz.us-east-1.rds.amazonaws.com"
# 2. Set short DNS TTL caching (Java JVM caches DNS by default = problem)
# Java fix:
networkaddress.cache.ttl=1  # in java.security
# 3. Implement retry logic with exponential backoff
import time
def connect_with_retry(max_attempts=5):
    for attempt in range(max_attempts):
        try:
            return db.connect(host=DB_HOST)
        except OperationalError:
            wait = 2 ** attempt  # 1, 2, 4, 8, 16 seconds
            time.sleep(wait)
# 4. Use RDS Proxy — handles reconnection transparently
# App → RDS Proxy (maintains pool) → new Primary
# App sees no connection disruption during failover ✅
```

---

## 9. Deployment Option Selection Framework

```
Start here:
  Is this dev/test with no downtime requirements?
  → Single-AZ (cheapest)

  Is downtime of 1-2 minutes acceptable?
  → Multi-AZ Instance (HA, no read scaling)

  Need read scaling + < 35s failover?
  → Multi-AZ Cluster

  Need max performance + < 25s failover + auto storage scaling + serverless?
  → Aurora Multi-AZ (MySQL or PostgreSQL compatible)

  Need < 1s RPO globally across multiple regions?
  → Aurora Global Database
```

---

## 10. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Old Primary becomes Standby immediately after failover | Old Primary is demoted — RDS recovers it and makes it new Standby |
| Multi-AZ Standby serves reads during normal operation | Standby is **completely passive** — zero traffic until failover |
| Failover is instant | Multi-AZ Instance: **60–120s**; Cluster: **<35s** |
| DNS changes instantly after failover | DNS has TTL — applications caching DNS may still connect to old IP |
| Read Replica auto-promotes on failure | Read Replica promotion is **manual** — not automatic failover |
| Multi-AZ Cluster uses full synchronous replication | Cluster uses **semi-synchronous** — at least 1 reader must acknowledge |
| Forcing failover via reboot doesn't work | `reboot-db-instance --force-failover` explicitly triggers failover |
| Standby endpoint is separate from Primary | Single endpoint (CNAME) — points to current Primary, updates on failover |

---

## 11. Interview Questions Checklist

- [ ] Three deployment options — architecture of each?
- [ ] What is synchronous vs semi-synchronous vs asynchronous replication?
- [ ] What exactly happens step-by-step during Multi-AZ Instance failover?
- [ ] Failover times: Multi-AZ Instance vs Cluster vs Aurora
- [ ] After failover, where does old Primary go?
- [ ] Why should you never hardcode the IP of an RDS instance?
- [ ] What is the DNS CNAME flip mechanism?
- [ ] How do you force a failover for testing? (reboot --force-failover)
- [ ] Multi-AZ Cluster: how many endpoints? What does each do?
- [ ] Standby vs Read Replica — complete comparison (6 dimensions)
- [ ] RPO and RTO for each deployment option?
- [ ] What breaks in the application layer during a failover?
- [ ] Three application best practices for surviving RDS failover
- [ ] When does RDS Proxy improve failover behavior?
- [ ] Multi-AZ Cluster failover: MySQL vs PostgreSQL — how does each pick the new writer?

## Nectar
