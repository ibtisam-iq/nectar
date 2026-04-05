# Amazon DynamoDB

## 1. What is DynamoDB?

DynamoDB is a **fully managed, serverless, multi-model NoSQL database** built
for internet-scale workloads requiring single-digit millisecond latency at any volume.
You provision no servers, manage no OS, and write no patching scripts — only design
your data model and interact via API.

```
Core trade-off:
  RDS:       SQL + ACID + complex queries  →  structured, relational data
  DynamoDB:  Flexible schema + speed       →  unstructured, high-volume, low latency
```

---

## 2. Core Data Model

```
Table
 └── Item (one record — equivalent to a row)
      ├── Attribute: { "user_id": "123" }      ← Partition Key (required)
      ├── Attribute: { "timestamp": "2026-…" } ← Sort Key (optional)
      ├── Attribute: { "name": "Ibtisam" }
      └── Attribute: { "tags": ["aws","k8s"] } ← can differ per item (schema-less)
```

| Concept | RDS Equivalent | DynamoDB |
|---------|---------------|---------|
| Database | Database | Table |
| Row | Record | Item |
| Column | Field | Attribute |
| Primary Key | Primary Key | Partition Key (+ optional Sort Key) |
| Index | Index | GSI / LSI |
| Max row size | Varies | **400 KB per item** |

---

## 3. Primary Key Types ⭐

### Simple Primary Key (Partition Key Only)

```
Table: Users
  PK: user_id

Items:
  { "user_id": "u-001", "name": "Ibtisam" }
  { "user_id": "u-002", "name": "Ali" }

Query: GetItem(user_id="u-001") → exact match only
```

### Composite Primary Key (Partition Key + Sort Key)

```
Table: Orders
  PK: user_id (partition key)
  SK: order_date (sort key)

Items in same partition (same user):
  { "user_id": "u-001", "order_date": "2026-01-01", "amount": 99  }
  { "user_id": "u-001", "order_date": "2026-03-15", "amount": 150 }
  { "user_id": "u-001", "order_date": "2026-04-01", "amount": 200 }

Query: all orders for user u-001 in 2026
  → KeyConditionExpression: user_id = "u-001" AND order_date BETWEEN "2026-01-01" AND "2026-12-31"
```

> **Partition key determines physical placement** (via hash function).
> **Sort key determines order within the partition** (sorted by value).
> Composite key enables range queries within a partition — essential design pattern.

---

## 4. Partitioning — How DynamoDB Scales ⭐

```
DynamoDB hashes partition key → determines which physical partition stores the item
Each partition: max 10 GB data, max 3,000 RCUs, max 1,000 WCUs

Table grows → DynamoDB splits partitions automatically (no downtime)
```

### Hot Partition Problem ⭐

```
Bad design: status as partition key
  "PENDING":  10,000 writes/sec  → all hit one partition → throttled ❌
  "COMPLETE": 100 writes/sec
  "FAILED":   10 writes/sec

Good design: user_id or order_id as partition key (high cardinality)
  user-001: 5 writes/sec
  user-002: 3 writes/sec
  user-003: 8 writes/sec
  → evenly distributed across partitions ✅
```

**Partition key best practices:**

- Use **high cardinality** keys: user IDs, order IDs, session IDs
- Avoid low cardinality: boolean flags, status codes, dates, country codes
- If forced to use low-cardinality key: add random suffix (`STATUS#PENDING#7`)
  then scatter-gather query across all suffixes on read

---

## 5. Data Types

| Category | Types |
|---------|-------|
| **Scalar** | String (S), Number (N), Binary (B), Boolean (BOOL), Null (NULL) |
| **Set** | String Set (SS), Number Set (NS), Binary Set (BS) — all items same type, no duplicates |
| **Document** | List (L) — ordered, any types; Map (M) — key-value, any types |

```json
{
  "user_id":    { "S": "u-001" },
  "age":        { "N": "25" },
  "active":     { "BOOL": true },
  "tags":       { "SS": ["aws", "k8s", "devops"] },
  "address": {
    "M": {
      "city":   { "S": "Rawalpindi" },
      "zip":    { "S": "46000" }
    }
  },
  "scores":     { "L": [{ "N": "95" }, { "N": "87" }] }
}
```

---

## 6. Capacity Modes ⭐

### On-Demand (Pay Per Request)

```
No capacity planning — DynamoDB scales instantly
Pay: per actual read/write request
Use when: unpredictable traffic, new applications, spiky workloads
Cost: ~2.5× more expensive per request than provisioned
```

### Provisioned (Fixed Capacity)

```
You set: RCUs (read capacity units) per second
         WCUs (write capacity units) per second
Pay: per provisioned RCU/WCU per hour regardless of usage
Use when: predictable, steady workloads
Add: Auto Scaling to adjust provisioned capacity based on utilization
```

---

## 7. RCU / WCU Calculations ⭐

### Write Capacity Unit (WCU)

```
1 WCU = 1 write per second for item up to 1 KB

Formula:
  WCU = writes_per_second × CEIL(item_size_KB / 1 KB)

Examples:
  Item = 0.5 KB, 100 writes/sec  → 100 × CEIL(0.5) = 100 × 1 = 100 WCU
  Item = 1.5 KB, 100 writes/sec  → 100 × CEIL(1.5) = 100 × 2 = 200 WCU
  Item = 3 KB,   50 writes/sec   → 50  × CEIL(3)   = 50  × 3 = 150 WCU
```

### Read Capacity Unit (RCU)

```
1 RCU = 1 strongly consistent read per second for item up to 4 KB
       OR
0.5 RCU = 1 eventually consistent read per second for item up to 4 KB

Formula:
  RCU (strong)    = reads_per_second × CEIL(item_size_KB / 4 KB)
  RCU (eventual)  = reads_per_second × CEIL(item_size_KB / 4 KB) × 0.5

Examples:
  Item = 4 KB,  100 strongly consistent reads/sec  → 100 × 1   = 100 RCU
  Item = 4 KB,  100 eventually consistent reads/sec → 100 × 0.5 = 50 RCU
  Item = 6 KB,  50 strongly consistent reads/sec   → 50  × CEIL(6/4) = 50 × 2 = 100 RCU
  Item = 10 KB, 80 eventually consistent reads/sec  → 80  × CEIL(10/4) × 0.5 = 80 × 3 × 0.5 = 120 RCU
```

> **Transactional reads/writes consume 2× RCU/WCU** — each transactional operation
> uses double the capacity of a standard operation.

---

## 8. Consistency Models ⭐

```
Default: Eventually Consistent (faster, costs 0.5 RCU)
  → Read may return data that is milliseconds behind
  → Use for: high-throughput read workloads, leaderboards, caches

Strongly Consistent (slower, costs 1 RCU)
  → Always returns latest committed data
  → Use for: financial balances, inventory, any "must be latest" data
  → Add --consistent-read flag in API call

Not available for:
  → Global Tables (always eventually consistent cross-region)
  → GSI reads (always eventually consistent)
```

---

## 9. Secondary Indexes ⭐

### Local Secondary Index (LSI)

```
Same partition key as base table, DIFFERENT sort key
Must be created AT TABLE CREATION — cannot add later
Max: 5 LSIs per table
Storage: shares table storage
Reads: supports strongly consistent reads

Table: Orders (PK: user_id, SK: order_date)
LSI: Orders-by-amount (PK: user_id, SK: amount)

Query: "get all orders for user u-001 sorted by amount"
  → Use LSI (same partition key = user_id)
```

### Global Secondary Index (GSI)

```
DIFFERENT partition key + optional different sort key
Can be added/deleted at ANY TIME (even after table creation)
Max: 20 GSIs per table
Storage: separate storage (own RCU/WCU)
Reads: eventually consistent only

Table: Orders (PK: user_id, SK: order_date)
GSI: Orders-by-status (PK: status, SK: order_date)

Query: "get all PENDING orders sorted by date"
  → Cannot do on base table (status not a key)
  → Use GSI (new partition = status) ✅
```

### GSI Projection Types

| Type | What is copied to GSI | Storage cost |
|------|----------------------|-------------|
| `KEYS_ONLY` | Only PK + SK + GSI key | Lowest |
| `INCLUDE` | Keys + specified attributes | Medium |
| `ALL` | All attributes | Highest (= full item copy) |

### LSI vs GSI Comparison

| Feature | LSI | GSI |
|---------|-----|-----|
| Partition key | Same as table | Different |
| Create timing | At table creation only | Anytime |
| Strongly consistent reads | ✅ Yes | ❌ No (eventually consistent) |
| Storage | Shared with table | Separate |
| Capacity | Uses table RCU/WCU | Own RCU/WCU |
| Max count | 5 | 20 |

---

## 10. Query vs Scan ⭐

| Operation | Uses Index | Reads | Cost |
|-----------|-----------|-------|------|
| **GetItem** | Exact PK lookup | Single item | Very cheap |
| **Query** | Partition key required | Items in one partition | Cheap |
| **Scan** | No index used | **Entire table** | ❌ Expensive |
| **BatchGetItem** | Up to 100 exact PK lookups | Multiple items | Cheap |

```
Scan is dangerous:
  Table: 50 million items × 400 KB max = up to 20 TB scan
  → Consumes massive RCUs
  → Can throttle production traffic
  → Use FilterExpression to reduce returned data (but scan still reads ALL items)

Design principle:
  "Design your table around your access patterns — never design and then query"
  → Know your queries first → then design PK/SK/GSI to serve those queries
```

### Expression Types

| Expression | Purpose |
|-----------|---------|
| `KeyConditionExpression` | Filter by PK and SK (Query only) |
| `FilterExpression` | Filter after reading (Scan or Query) |
| `ProjectionExpression` | Return only specific attributes |
| `ConditionExpression` | Conditional write — only write IF condition is true |
| `UpdateExpression` | Define what to update in UpdateItem |

---

## 11. Transactions ⭐

DynamoDB supports full ACID transactions across multiple tables and items:

```python
# All-or-nothing: both writes succeed or both fail
dynamodb.transact_write_items(
    TransactItems=[
        {
            'Put': {
                'TableName': 'Orders',
                'Item': {'order_id': {'S': 'o-123'}, 'status': {'S': 'CONFIRMED'}}
            }
        },
        {
            'Update': {
                'TableName': 'Inventory',
                'Key': {'product_id': {'S': 'p-456'}},
                'UpdateExpression': 'SET stock = stock - :val',
                'ConditionExpression': 'stock >= :val',
                'ExpressionAttributeValues': {':val': {'N': '1'}}
            }
        }
    ]
)
# If inventory check fails (stock < 1) → entire transaction rolls back
```

**Cost:** Transactions consume **2× RCU/WCU** per operation vs standard.
**Limit:** Up to 100 items or 4 MB per transaction.

---

## 12. DynamoDB Streams ⭐

Captures a time-ordered log of every change (INSERT / MODIFY / REMOVE) to items:

```
Insert/Update/Delete item
  → Event written to Stream (retention: 24 hours)
  → Lambda trigger reads Stream
  → Process event: audit log, replication, search index update, notifications

Stream record contains:
  KEYS_ONLY:          Only key attributes
  NEW_IMAGE:          New item state after change
  OLD_IMAGE:          Old item state before change
  NEW_AND_OLD_IMAGES: Both states (most common — enables delta comparison)
```

**Use cases:**
- Cross-region replication (foundation of Global Tables)
- Triggers: send email on order status change
- Search: sync changes to Elasticsearch/OpenSearch
- Audit trail: every change logged immutably

---

## 13. DynamoDB Accelerator (DAX) ⭐

In-memory cache purpose-built for DynamoDB — reduces read latency from
milliseconds to **microseconds**:

```
Without DAX:
  App → DynamoDB API → 1–10ms latency per read

With DAX:
  App → DAX Cluster (cache) → ~microseconds if cached
                            → DynamoDB if cache miss (~1–10ms)

DAX is a cluster (primary + replicas) deployed in your VPC
  → Only accessible within VPC (not public)
  → Drop-in replacement: change endpoint in SDK, code stays same

Write-through cache:
  Write → DAX → DynamoDB → both updated
  → Reads immediately see updated data from cache
```

| Property | Value |
|----------|-------|
| Latency | Microseconds (cache hit) |
| Access | VPC only (in-VPC cluster) |
| Use case | Read-heavy, repeated same item reads (product catalog, gaming) |
| Does NOT help | Write-heavy workloads, strongly consistent reads (bypasses cache) |

---

## 14. Global Tables ⭐

Active-active multi-Region replication — same table writable in multiple Regions:

```
Table: Users (Global Table)
  us-east-1 replica:    App writes user-001 ← write here
  eu-west-1 replica:    EU users read/write ← replicated from us-east-1
  ap-southeast-1:       APAC users read/write

Replication: DynamoDB Streams-powered, async, typically < 1 second

Active-active: any region can accept writes
  → Last-writer-wins for conflict resolution (based on timestamp)
```

**Requirements:**

- DynamoDB Streams enabled with `NEW_AND_OLD_IMAGES`
- All replicas: same table name, same partition key, same capacity settings
- Replicas must be empty when adding a new Region

**Use case:** Global apps where multi-region read AND write latency matters.

---

## 15. Backup and Restore

### On-Demand Backup

```
Manual snapshot → full table backup
Stored indefinitely (until deleted)
Restores to new table (does not overwrite existing)
No RCU consumption during backup
```

### Point-in-Time Recovery (PITR)

```
Enable PITR → DynamoDB continuously backs up table
Restore to any second in last 35 days
Restore creates new table — original table untouched
No performance impact on production table
```

---

## 16. TTL (Time To Live) ⭐

Automatically deletes expired items — no WCU consumed for deletions:

```
Add attribute: "expires_at": 1780000000  (Unix timestamp)
Enable TTL on table, point to "expires_at"
DynamoDB: periodically scans for expired items → deletes them within ~48 hours

Important:
  - Not real-time — deletion can be up to 48 hours after expiry
  - Expired-but-not-deleted items still returned in reads until deleted
  - Add FilterExpression to exclude expired items if needed:
    FilterExpression: "expires_at > :now"

Use cases: sessions, OTPs, cache, temporary tokens, rate limiting counters
```

---

## 17. DynamoDB Table Classes

| Class | Storage cost | Use Case |
|-------|-------------|---------|
| **Standard** | $0.25/GB/month | Frequently accessed data |
| **Standard-Infrequent Access (IA)** | $0.10/GB/month | Rarely accessed, large tables |

> Standard-IA has higher read/write costs but 60% lower storage cost.
> Use for tables with large data but infrequent access (audit logs, historical data).

---

## 18. PartiQL — SQL-Like Interface

DynamoDB supports PartiQL — a SQL-compatible query language (SELECT/INSERT/UPDATE/DELETE):

```sql
-- PartiQL query
SELECT * FROM Orders WHERE user_id = 'u-001' AND order_date > '2026-01-01'

-- Still uses partition key internally — no full table scans without PK
-- Easier for developers who know SQL but want DynamoDB's scale
```

---

## 19. Access Control — Fine-Grained IAM

IAM conditions allow restricting access to specific items within a table:

```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:GetItem", "dynamodb:PutItem"],
  "Resource": "arn:aws:dynamodb:us-east-1:123:table/UserData",
  "Condition": {
    "ForAllValues:StringEquals": {
      "dynamodb:LeadingKeys": ["${aws:userid}"]
    }
  }
}
```

> This IAM policy only lets a user access items where the partition key
> equals their own user ID. Users cannot read each other's data.
> This is **fine-grained access control** — a key DynamoDB security feature.

---

## 20. DynamoDB vs RDS — When to Use Which ⭐

| Need | Use |
|------|-----|
| Complex JOINs across multiple tables | RDS |
| Strict ACID transactions | RDS (or DynamoDB transactions for simpler cases) |
| Flexible schema, items differ per record | DynamoDB |
| Millions of requests/sec with ms latency | DynamoDB |
| Known, stable access patterns | DynamoDB (design table for patterns) |
| Ad-hoc queries and reporting | RDS |
| Serverless, no capacity planning | DynamoDB on-demand |
| Gaming leaderboards, session data, IoT | DynamoDB |
| Financial records, ERP, CRM | RDS |

---

## 21. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| DynamoDB uses SQL | DynamoDB uses API operations (GetItem, Query, Scan) + PartiQL as optional interface |
| Scan is equivalent to Query | Scan reads the **entire table** — extremely expensive at scale |
| GSI supports strongly consistent reads | GSI reads are **always eventually consistent** |
| LSI can be added after table creation | LSI must be created **at table creation only** |
| DAX caches all reads | DAX does NOT cache **strongly consistent reads** |
| TTL deletes items immediately | TTL deletion happens within **up to 48 hours** of expiry |
| Transactions are free | Transactions consume **2× RCU/WCU** per operation |
| Any attribute can be partition key | Partition key must be **high cardinality** — low cardinality creates hot partitions |
| DynamoDB is eventually consistent always | Strongly consistent reads available (but cost 2× RCU and not for GSI/Global Tables) |
| Global Tables = read-only replicas | Global Tables are **active-active** — all replicas accept writes |

---

## 22. Interview Questions Checklist

- [ ] DynamoDB vs RDS — when do you choose each?
- [ ] What is a partition key? Why does cardinality matter?
- [ ] Simple vs composite primary key — example of when to use composite?
- [ ] Calculate RCU for: 6 KB item, 100 strongly consistent reads/sec
- [ ] Calculate WCU for: 3.5 KB item, 200 writes/sec
- [ ] Eventually consistent vs strongly consistent — cost difference, when to use
- [ ] LSI vs GSI — 5 differences (creation time, consistency, storage, PK, count)
- [ ] What is a hot partition? How do you fix it?
- [ ] Query vs Scan — why is Scan dangerous at scale?
- [ ] What are the five expression types in DynamoDB?
- [ ] Transactions — what do they cost in RCU/WCU? Max items?
- [ ] DynamoDB Streams — what does NEW_AND_OLD_IMAGES give you?
- [ ] DAX — what does it cache? What does it NOT cache?
- [ ] Global Tables — replication model? Conflict resolution? Requirements?
- [ ] TTL — when are items actually deleted?
- [ ] On-demand vs provisioned — when do you choose each?
- [ ] Fine-grained IAM — how do you restrict a user to their own items only?
- [ ] What is PITR? Retention window?

## Nectar
