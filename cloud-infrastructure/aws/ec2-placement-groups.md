# EC2 Placement Groups

---

## 1. What is a Placement Group?

A logical grouping that controls **how EC2 instances are physically placed
on underlying hardware** — to optimize for performance, latency, or availability.

> It is NOT about configuration or networking rules.
> It IS a hardware-level architecture decision.

---

## 2. Infrastructure Mental Model

```
Availability Zone
  └── Multiple Racks
        └── Each rack has:
              ├── Independent power supply
              ├── Independent network switch
              └── Physical servers running EC2 instances
```

**Key:** Each rack is an independent failure domain. If a rack loses power or
its network switch fails — only that rack is affected.
This is the physical foundation all three strategies build upon.

---

## 3. The Three Strategies

| Strategy | Core Idea | Latency | Fault Tolerance | Instance Limit |
|---------|-----------|---------|----------------|----------------|
| **Cluster** | Pack together — same rack | ✅ Lowest | ❌ Lowest | Hundreds (no hard limit) |
| **Partition** | Separate groups on separate racks | Medium | Medium | No limit per group (7 partitions/AZ) |
| **Spread** | Every instance on a different rack | Highest | ✅ Highest | **7 per AZ** (hard limit) |

---

## 4. Cluster Placement Group ⭐

**Definition:** Packs instances as close together as possible — same rack or
adjacent hardware in one AZ — to minimize latency and maximize bandwidth.

```
AZ
 └── Rack A
       ├── Instance 1
       ├── Instance 2
       ├── Instance 3
       └── Instance 4     ← all on same/adjacent hardware
```

### Performance Characteristics

| Metric | Value |
|--------|-------|
| Network throughput (inter-instance) | Up to 10 Gbps (single-flow) |
| Enhanced Networking required | ✅ Yes (ENA-supported instance types) |
| Jumbo Frames (9001 MTU) | ✅ Recommended — maximizes throughput |
| Internet / Direct Connect traffic | Limited to 5 Gbps |

### Rules and Constraints

- Single AZ only
- Recommended to use **same instance type** (homogeneous)
  - Mixed types are allowed but reduce chance of AWS fulfilling full capacity
- Must use instance types that support Enhanced Networking
- `InsufficientInstanceCapacity` error is more common here — all instances
  need to fit on nearby hardware simultaneously

### InsufficientInstanceCapacity — Fix

```
Error when launching:
  → AWS cannot place all instances close enough in that AZ

Fix:
  1. Stop ALL instances in the placement group
  2. Start them all again together
     → AWS may migrate them to new hardware with space for all
  3. Or: launch all instances in a single request (not one-by-one)
```

### Use Cases
- HPC (High Performance Computing) — tightly coupled, MPI workloads
- Distributed ML training (inter-GPU communication)
- Real-time analytics requiring fast node-to-node communication
- Financial modeling, scientific simulations

---

## 5. Partition Placement Group ⭐

**Definition:** Divides instances into logical **partitions**, each partition
isolated on **separate racks** with independent power and networking.

```
AZ
 ├── Partition 1 → Rack A → [instance 1, instance 2, instance 3]
 ├── Partition 2 → Rack B → [instance 4, instance 5, instance 6]
 └── Partition 3 → Rack C → [instance 7, instance 8, instance 9]
```

If Rack B fails → Partition 2 is affected, Partitions 1 and 3 keep running.

### Key Properties

| Property | Detail |
|----------|--------|
| Max partitions per AZ | **7** |
| Instance limit per group | No hard limit (account limits apply) |
| Multi-AZ support | ✅ **Yes** — partitions can span multiple AZs in same Region |
| Dedicated Instances | Max **2 partitions** per group |
| Capacity Reservations | ❌ Not supported in partition placement groups |

### Partition Metadata Visibility ⭐

Partition-aware distributed systems (Kafka, HDFS, HBase, Cassandra) can query
**which partition an instance is in** via the instance metadata service:

```bash
curl http://169.254.169.254/latest/meta-data/placement/partition-number
# Returns: 1, 2, or 3 etc.
```

> This allows the application to make intelligent replication decisions —
> e.g. "ensure replicas go to instances in different partitions."

### Use Cases
- Apache Kafka (producers/consumers spread across partitions)
- Hadoop HDFS (rack-aware data replication)
- HBase, Cassandra (topology-aware placement)
- Any distributed system that manages its own replication and needs hardware isolation

---

## 6. Spread Placement Group ⭐

**Definition:** Every single instance is placed on a **completely separate rack** —
maximum fault isolation.

```
AZ
 ├── Rack A → Instance 1   (only this instance here)
 ├── Rack B → Instance 2   (only this instance here)
 ├── Rack C → Instance 3   (only this instance here)
 └── ...     up to 7 per AZ
```

### Key Properties

| Property | Detail |
|----------|--------|
| Max instances per AZ | **7 (hard limit)** — no exceptions |
| Multi-AZ support | ✅ **Yes** — 7 per AZ × number of AZs (e.g. 3 AZs = up to 21 instances) |
| Hardware guarantee | Each instance on separate physical rack — independent power + network |
| Dedicated Hosts | ❌ Not supported in Spread placement groups |

### Spread Level Options

| Level | Where | Availability |
|-------|-------|-------------|
| **Rack** (default) | Separate racks within an AZ | Standard — all Regions |
| **Host** | Separate physical hosts | AWS Outposts only |

### Use Cases
- Small number of critical instances that must survive any single hardware failure
- Primary + secondary + tertiary instances (e.g. ZooKeeper quorum, 3-node etcd)
- Any setup where the failure of one instance must NOT correlate with another

---

## 7. Partition vs Spread — The Key Distinction

| Question | Partition | Spread |
|---------|-----------|--------|
| How many instances? | Hundreds (no limit) | Max 7 per AZ |
| Failure isolation? | Partition-level (rack group) | Individual rack per instance |
| App manages placement? | ✅ Yes — metadata query | ❌ No — AWS manages it |
| Multi-AZ? | ✅ Yes | ✅ Yes |
| Rack failure kills? | All instances in that partition | Only that one instance |

> Use **Partition** for distributed systems that manage their own replication logic.
> Use **Spread** for small sets of critical standalone instances.

---

## 8. Latency / Availability Trade-off

```
      Cluster ←────────────────────────→ Spread
      (Pack)                            (Separate)

Latency:    LOWEST ←─────────────────→ HIGHEST
Network:    FASTEST ←────────────────→ SLOWER
Availability: LOWEST ←───────────────→ HIGHEST
```

```
                     Partition
                   (middle ground)
                       ↑
           Balances both extremes
```

---

## 9. Rules, Constraints & Gotchas ⭐

| Rule | Detail |
|------|--------|
| One group per instance | An instance can only be in **one** placement group at a time |
| Merge groups | ❌ Cannot merge two placement groups |
| Move existing instance | ❌ Cannot move a running/stopped instance into a placement group — must launch fresh |
| Workaround for move | Create AMI from existing instance → launch new instance from AMI into placement group |
| After stop/start | Instance stays in same placement group if stopped and started within the group |
| Capacity Reservations | Work with Cluster and Spread; ❌ NOT with Partition |
| Same VPC required? | No — peered VPCs are also supported for Cluster groups |

---

## 10. How to Move an Existing Instance into a Placement Group

```
Existing Instance (not in any placement group)
     ↓
Create AMI from it
     ↓
Launch new instance from AMI
    → select placement group during launch
     ↓
Terminate original instance (after validation)
```

---

## 11. Engineering Decision Framework

```
Is inter-instance latency your primary concern?
  YES → Cluster (same rack, 10 Gbps)

Are you running a distributed system with its own replication?
  YES → Partition (topology-aware, metadata API)
  How many instances? Hundreds → Partition is the only option (Spread = max 7/AZ)

Do you have a small number of critical instances (≤ 7/AZ)?
  YES → Spread (maximum fault isolation, separate rack per instance)
```

### Scenario Mapping

| Workload | Strategy | Reason |
|---------|----------|--------|
| HPC / MPI workload | Cluster | Microsecond inter-node latency |
| ML training (multi-GPU) | Cluster | High-bandwidth GPU interconnect |
| Apache Kafka cluster | Partition | Rack-aware replication, hundreds of brokers |
| HDFS NameNode + DataNodes | Partition | Rack-aware block placement |
| ZooKeeper 3-node quorum | Spread | Each node on separate rack, max 7 limit fits |
| Primary + 2 replicas (any DB) | Spread | Correlated failure prevention |
| Redis Sentinel (3 nodes) | Spread | Each sentinel on separate hardware |

---

## 12. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Partition group only supports single AZ | Partition supports **multiple AZs** in same Region |
| Spread only supports single AZ | Spread supports multi-AZ — 7 instances **per AZ** |
| Can move stopped instance into placement group | Cannot move — must launch fresh into the group |
| Cluster group has no instance limit | Cluster has no hard limit but `InsufficientInstanceCapacity` is common at scale |
| Spread supports Dedicated Hosts | Dedicated Hosts not supported in Spread groups |
| Partition groups are only for Kafka | Partition works for any topology-aware distributed system |
| All instance types work in Cluster | Cluster requires Enhanced Networking (ENA) capable instances |
| Capacity Reservations work with Partition | Capacity Reservations are NOT supported in Partition groups |

---

## 13. Interview Questions Checklist ✅

- [ ] What is a Placement Group? What problem does it solve?
- [ ] Name the 3 placement group strategies
- [ ] Cluster: What is the max network throughput? What does it require?
- [ ] Why is `InsufficientInstanceCapacity` more common in Cluster groups?
- [ ] How do you fix `InsufficientInstanceCapacity` in a Cluster group?
- [ ] Partition: How many partitions per AZ?
- [ ] Does Partition support multi-AZ? (Yes)
- [ ] What is the partition metadata API? Why is it useful?
- [ ] Spread: What is the hard instance limit per AZ?
- [ ] Spread vs Partition — when to choose each?
- [ ] Can you move a running/stopped instance into a placement group?
- [ ] What is the workaround to place an existing instance in a group?
- [ ] Rack vs Host level — what is the difference in Spread?
- [ ] Do Capacity Reservations work with Partition groups? (No)
- [ ] What is Jumbo Frame (MTU 9001) and why use it in Cluster groups?
