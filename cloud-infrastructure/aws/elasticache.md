# Amazon ElastiCache

## 1. What is ElastiCache?

Amazon ElastiCache is a **fully managed, in-memory caching service** that
deploys and operates Redis, Valkey, or Memcached clusters in AWS — used to
reduce database load, achieve sub-millisecond latency, and absorb massive
read traffic that would otherwise hit your primary database.

```
Without caching:
  Every user request → SQL query → RDS → disk I/O → 10–100ms latency
  10,000 concurrent users → 10,000 DB queries → DB overwhelmed → timeout

With ElastiCache:
  First request → DB miss → query DB → store result in ElastiCache
  Next 9,999 requests → cache HIT → ElastiCache returns in <1ms → DB untouched

Result:
  Sub-millisecond response times
  Database reads reduced by 90%+
  Application scales horizontally without DB bottleneck
  Cost: ElastiCache nodes cheaper than scaling RDS vertically
```

### When to Use ElastiCache

```
✅ Perfect use cases:
  Read-heavy workloads: product catalog, user profiles, leaderboards
  Session management: store HTTP sessions across stateless app servers
  Real-time analytics: counters, rate limiting, trending content
  Pub/Sub messaging: event notifications between microservices
  Queue/job management: Redis lists as job queues
  Geospatial data: Redis GEO commands → nearest store, delivery tracking
  Leaderboards: Redis sorted sets → top 10 users by score in O(log N)

❌ NOT suitable for:
  Primary data store (data is volatile — can be evicted or lost)
  Large data sets that don't fit in memory
  Complex relational queries (use RDS)
  Durable writes that must survive node failure (use RDS/DynamoDB)
```

---

## 2. Engines Supported ⭐

ElastiCache supports three engines:

```
1. Valkey (recommended — new default as of 2024)
   Open-source Redis fork maintained by Linux Foundation
   API-compatible with Redis 7.2
   Features:
     All Redis data structures + commands
     Cluster mode: up to 500 shards [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.html)
     ElastiCache Serverless: 33% lower price vs Redis + 90% lower minimum storage [aws.amazon](https://aws.amazon.com/elasticache/pricing/)
     Node-based: 20% lower price vs Redis [aws.amazon](https://aws.amazon.com/elasticache/pricing/)
   Use: new deployments — best cost + performance

2. Redis OSS (open-source)
   Original Redis maintained by Redis Ltd
   Full feature set: strings, hashes, lists, sets, sorted sets, bitmaps, HyperLogLog,
                     streams, pub/sub, geospatial, Lua scripting, transactions
   Cluster mode: up to 500 shards [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.html)
   Use: existing Redis workloads, specific Redis OSS version requirements

3. Memcached
   Simpler, pure caching engine
   Multi-threaded (better CPU utilization on high-core nodes)
   No replication, no persistence, no pub/sub
   Scales horizontally: add nodes → consistent hashing distributes keys
   Use: simple caching only, multi-threaded performance critical,
        no advanced data structures needed

Valkey starts at $6/month for Serverless — cheapest option [aws.amazon](https://aws.amazon.com/elasticache/pricing/)
```

---

## 3. Valkey/Redis Data Structures

```
Strings:
  SET user:1:name "Ibtisam"    → O(1)
  GET user:1:name              → "Ibtisam" in <1ms
  INCR page:views:home         → atomic counter (no race condition)
  SETEX session:abc 3600 data  → key with 1 hour TTL

Hashes (like a Map/Dict for an object):
  HSET user:1 name "Ibtisam" email "i@example.com" age 25
  HGET user:1 name             → "Ibtisam"
  HGETALL user:1               → all fields
  Use: user profiles, shopping cart items

Lists (ordered linked list):
  LPUSH queue:emails task1     → push to front
  RPUSH queue:emails task2     → push to back
  LPOP queue:emails            → dequeue from front
  Use: job queues, recent activity, message queues

Sets (unordered, unique):
  SADD tags:post:1 aws cloud devops
  SMEMBERS tags:post:1         → {aws, cloud, devops}
  SINTER tags:post:1 tags:post:2 → common tags between posts
  Use: unique visitors, friend lists, tag systems

Sorted Sets (unique + score → auto-sorted):
  ZADD leaderboard 1000 "Alice"  200 "Bob"  5000 "Ibtisam"
  ZRANGE leaderboard 0 -1 WITHSCORES REV  → Ibtisam:5000, Alice:1000, Bob:200
  ZRANK leaderboard "Ibtisam"    → 0 (rank 1)
  Use: leaderboards, rate limiting, priority queues

Bitmaps:
  SETBIT users:active:2026-04-08 userId 1  → mark user active today
  BITCOUNT users:active:2026-04-08         → count active users today
  Use: daily active users, feature flags per user ID

HyperLogLog (probabilistic count — ~2% error):
  PFADD unique:visitors user1 user2 user3
  PFCOUNT unique:visitors       → ~3 (approximate)
  Use: unique visitor counts where exact count not required, uses very little memory

Geospatial:
  GEOADD stores 73.048 33.615 "Rawalpindi-Store-1"
  GEODIST stores "Rawalpindi-Store-1" "Lahore-Store-2" km
  GEORADIUS stores 73.048 33.615 50 km ASC → stores within 50km
  Use: nearest location, delivery radius, geo-fencing

Streams (append-only log, like Kafka):
  XADD events * action "login" userId "42"
  XREAD COUNT 10 STREAMS events 0
  XGROUP CREATE events consumers $  → consumer groups
  Use: event sourcing, activity feeds, real-time analytics pipeline

Pub/Sub:
  SUBSCRIBE notifications:user:42
  PUBLISH notifications:user:42 '{"message": "New follower"}'
  Use: real-time notifications, chat, live updates
  Note: messages NOT persistent — if subscriber offline, message lost
```

---

## 4. Cluster Modes (Valkey / Redis) ⭐

### Cluster Mode Disabled (CMD)

```
Architecture:
  Single shard (1 primary + up to 5 read replicas)
  All data on ONE primary node
  Replicas: read-only copies of the same data

Read replicas:
  0 replicas: no redundancy → primary fails → total data loss [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.Redis-RedisCluster.html)
  1–5 replicas: HA → primary fails → replica promoted to primary automatically

Multi-AZ:
  Deploy primary in AZ-1, replicas in AZ-2 and AZ-3
  Primary fails → ElastiCache auto-promotes replica in different AZ → ~60 sec failover
  DNS endpoint updated → application reconnects automatically

Endpoints:
  Primary endpoint: writes → always points to current primary
  Reader endpoint: reads → load-balanced across all replicas
  Individual endpoints: one per node (for explicit targeting)

Scaling:
  Scale UP: resize node type (r7g.large → r7g.xlarge) → brief downtime
  Scale OUT: add/remove read replicas → no downtime (reads spread across more replicas)

Limitations:
  No data partitioning → ALL data must fit in single node's memory [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.Redis-RedisCluster.html)
  Max memory = single node instance size
  Write throughput limited to single primary node

Use CMD when:
  Dataset fits in one node's memory
  Simple architecture preferred
  Need to run Lua scripts, transactions (MULTI/EXEC) without sharding complexity
```

### Cluster Mode Enabled (CME) ⭐

```
Architecture:
  Up to 500 shards (partitions) [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.html)
  Each shard: 1 primary + up to 5 read replicas
  Data distributed across shards via consistent hashing on key slot

Key slots:
  Redis uses 16,384 hash slots total (0–16383)
  Each shard owns a range of slots
  Key → CRC16(key) % 16384 → maps to slot → maps to shard → maps to node
  CLUSTER KEYSLOT mykey → returns which slot number

Example with 3 shards:
  Shard 0: slots 0–5460      (primary + replicas in us-east-1a + 1b)
  Shard 1: slots 5461–10922  (primary + replicas in us-east-1b + 1c)
  Shard 2: slots 10923–16383 (primary + replicas in us-east-1c + 1a)

Endpoints:
  Configuration endpoint (single): clients use this → cluster handles routing
  → Smart client (Cluster-aware client) connects to configuration endpoint
  → Client learns topology from CLUSTER SLOTS command
  → Client routes request directly to correct node (no proxy hop) [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.Redis.Groups.html)

Scaling:
  Online resharding: add shards → slots redistributed → NO downtime [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/modify-cluster-mode.html)
  Scale down: remove shards → slots migrated → NO downtime
  Vertical scaling: resize node types → brief downtime per node
  Maximum capacity: 500 shards × node memory = petabytes theoretically

Key limitation: [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.Redis-RedisCluster.html)
  Multi-key operations MUST be on same shard
  → MGET key1 key2 → only if both keys hash to same slot
  → Transactions (MULTI/EXEC) → only if all keys on same shard
  → Lua scripts → only if all keys on same shard
  Workaround: hash tags → {user}.name and {user}.age → always same slot
    (CRC16 computed on just the part inside {})
```

### CMD vs CME Comparison

| Feature | Cluster Mode Disabled | Cluster Mode Enabled |
|---------|----------------------|---------------------|
| Shards | 1 | 1–500 |
| Replicas | 0–5 | 0–5 per shard |
| Data partitioning | ❌ No | ✅ Yes |
| Max dataset size | Single node RAM | 500 × node RAM |
| Multi-key operations | ✅ All | ⚠️ Same shard only |
| Transactions | ✅ Full | ⚠️ Same shard only |
| Lua scripts | ✅ Full | ⚠️ Same shard only |
| Online resharding | ❌ No | ✅ Yes |
| Backup | Single .rdb | One .rdb per shard |

---

## 5. ElastiCache Serverless ⭐

No capacity planning, no nodes to manage — **you just create a cache
and ElastiCache scales automatically**:

```
How it works:
  You create a serverless cache (no instance type selection)
  ElastiCache manages: node provisioning, scaling, Multi-AZ, failover
  You pay for: data stored (GB-hours) + requests (ECPUs)

Scaling behavior: [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Scaling.html)
  ElastiCache Serverless for Valkey 8.0:
    Doubles supported requests every 2–3 minutes
    Reaches 5M RPS per cache from zero in under 13 minutes

Pricing: [aws.amazon](https://aws.amazon.com/elasticache/pricing/)
  Memcached/Redis: $0.125/GB-hour storage + $0.0034/million ECPUs
  Valkey:          33% lower: storage + ECPU pricing
  Minimum:
    Redis/Memcached: 1 GB minimum storage billed/hour
    Valkey:          100 MB minimum storage ← 90% lower minimum

Serverless vs Provisioned:
  Serverless better for:
    Variable/unpredictable traffic (auto-scales up/down)
    New projects (no capacity planning needed)
    Dev/test (small minimum, no idle node cost if you delete it)
  Provisioned better for:
    Steady, predictable high throughput (cheaper per unit)
    Specific node type requirements (memory-optimized, CPU-optimized)
    Cost-sensitive production workloads (reserved nodes = 40–75% discount)

Free tier:
  None for ElastiCache (no free tier) → starts billing immediately
```

---

## 6. Caching Strategies ⭐

### Lazy Loading (Cache-Aside)

```
Read flow:
  1. Application checks cache for key
  2. Cache HIT  → return data immediately (sub-ms)
  3. Cache MISS → query database → store in cache with TTL → return data

Write flow:
  Update database ONLY
  Cache invalidated OR left to expire via TTL

Pros:
  Cache only contains requested data (no wasted memory)
  Cache failure: graceful degradation → just slower (DB fallback)
  Data structure flexible (cache exactly what app needs)

Cons:
  First request after miss: latency spike (3 round trips: check cache → DB → write cache)
  Cache stampede: many simultaneous misses → all hit DB at once
    Mitigation: mutex locks, probabilistic early expiration

Code pattern:
  data = cache.get("user:42")
  if data is None:
      data = db.query("SELECT * FROM users WHERE id=42")
      cache.setex("user:42", 300, serialize(data))  # TTL = 5 min
  return data
```

### Write-Through

```
Write flow:
  1. Application writes to cache
  2. Cache SYNCHRONOUSLY writes to database
  3. Both cache and DB always in sync

Read flow:
  Cache hit always (data pre-populated on every write)

Pros:
  Cache always fresh → no stale data
  No cache miss latency on reads (data already there)
  Good for write-then-immediately-read patterns

Cons:
  Write latency: every write hits both cache AND DB
  Cache bloat: data written to cache even if never read again
  Cache failure: writes fail if cache unavailable

Use with:
  Write-then-read workloads (write user profile → immediately show it)
  Data freshness critical
```

### Write-Behind (Write-Back)

```
Write flow:
  1. Application writes to cache
  2. Cache returns success IMMEDIATELY (async)
  3. Cache batches writes → flushes to DB asynchronously (e.g., every 1 sec)

Pros:
  Fastest write latency (app doesn't wait for DB)
  Batch DB writes → better throughput, fewer DB connections
  Absorb write spikes without overwhelming DB

Cons:
  Risk of data loss: cache fails before DB flush → writes lost ← dangerous
  Complexity: need reliable async flush mechanism
  Eventual consistency: DB may lag behind cache

Use for:
  High-frequency counters (page views, likes) — losing a few counts acceptable
  Non-critical data where eventual consistency acceptable
  NOT for: financial transactions, inventory, anything requiring durability
```

### Cache Warming (Pre-loading)

```
Proactively load data into cache BEFORE traffic hits:
  Deployment: pre-warm cache during deploy → no cold start latency
  Schedule: nightly job → load next day's data (promotions, inventory)
  Migration: seed new cache from DB before switching traffic

Why needed:
  Cold cache on deploy → first user gets slow DB response
  Flash sale: cache miss storm at 12:00:00 → DB overwhelmed

Implementation:
  for user_id in top_1000_users:
      data = db.query(user_id)
      cache.setex(f"user:{user_id}", 3600, serialize(data))
```

---

## 7. Cache Eviction Policies ⭐

When cache is full and new data must be written, ElastiCache must evict
existing keys — policy determines which keys are removed:

```
noeviction (default):
  Returns error when memory full → writes rejected
  Use: when losing data is unacceptable (data must stay until TTL)
  ❌ Bad for caches — your app will get write errors when cache fills

allkeys-lru (MOST COMMON for caches):
  Evict least recently used key across ALL keys
  Automatically removes stale/unpopular data → keeps hot data
  Use: general-purpose cache where some staleness acceptable
  ✅ Recommended default for most caching use cases

allkeys-lfu (Least Frequently Used):
  Evict key accessed least number of times across ALL keys
  Better than LRU for data with temporal access patterns
  Use: when access frequency matters more than recency

volatile-lru:
  Evict LRU key ONLY from keys that have a TTL set
  Keys without TTL: NEVER evicted
  Use: mix of persistent (no TTL) + cached (TTL) data in same Redis

volatile-lfu:
  LFU eviction from TTL keys only
  Use: similar to volatile-lru but frequency-based

volatile-ttl:
  Evict key with LOWEST remaining TTL first
  Use: when data with soonest expiry is least valuable

allkeys-random:
  Random key removed across ALL keys
  Use: access patterns completely uniform (rare in practice)

volatile-random:
  Random key removed from TTL-set keys only

Summary recommendation:
  Pure cache (all keys should be evictable):     allkeys-lru or allkeys-lfu
  Mixed cache + persistent (some keys must stay): volatile-lru (only evict TTL keys)
  Never lose any data:                            noeviction + monitor memory + alert
```

---

## 8. TTL (Time To Live) ⭐

```
TTL = expiry time on a cache key after which it auto-deletes:

SET user:42:profile data EX 3600    → expires in 3600 seconds (1 hour)
EXPIRE user:42:profile 3600         → set TTL on existing key
TTL user:42:profile                 → returns remaining seconds (-1 = no TTL, -2 = expired/gone)
PERSIST user:42:profile             → remove TTL → key never expires

TTL strategy decisions:
  Too short: frequent cache misses → DB hammered
  Too long: stale data served → inconsistency risk

Common TTL values:
  User sessions:          30 min (security: auto-logout)
  Product catalog:        1 hour (changes infrequently)
  Search results:         5 min (freshness important)
  Rate limit counters:    1 sec (reset every second)
  Homepage content:       10 min (acceptable staleness)
  User profile:           15 min (balance freshness vs DB load)
  Leaderboards:           30 sec (near real-time required)

Cache stampede / Thundering herd:
  Problem: 1000 keys all expire at exactly the same time
           → 1000 simultaneous cache misses → 1000 DB queries simultaneously
  Solutions:
    1. TTL jitter: TTL = base_ttl + random(0, 300)  ← spread expiration
       cache.setex(key, 3600 + random.randint(0, 300), value)
    2. Stale-while-revalidate: serve stale data + async refresh
    3. Mutex/lock: first request gets lock → fetches from DB → others wait
```

---

## 9. High Availability & Failover ⭐

```
Multi-AZ (Cluster Mode Disabled):
  Primary: us-east-1a  → Replica: us-east-1b
  Primary fails:
    ElastiCache detects failure (~10–30 sec)
    Replica in us-east-1b promoted to primary
    DNS endpoint updated to new primary
    Total failover time: ~60 seconds
    Application: reconnect (connection dropped during failover)

  Enable Multi-AZ + auto-failover:
    console: Enable Multi-AZ → check "Auto-failover"
    OR: always have at least 1 replica

Multi-AZ (Cluster Mode Enabled):
  Each shard has its own primary + replicas in different AZs
  One shard's primary fails → that shard's replica promotes
  Other shards: unaffected (data in other shards still served)
  → More granular fault isolation vs CMD

Automatic Backup (Snapshots):
  Daily automated backup to S3 (RDB snapshot)
  Retention: 0–35 days
  CMD: one .rdb file; CME: one .rdb file per shard [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Replication.Redis-RedisCluster.html)
  Restore: creates new cluster from snapshot
  Manual snapshots: available any time, kept until deleted

AOF (Append Only File) — persistence:
  Logs every write operation
  On node restart: replay AOF → recover data
  Available: single-node clusters (no replicas) only
  Trade-off: slower writes due to disk I/O
  Recommendation: use Multi-AZ replicas instead of AOF for HA
```

---

## 10. Global Datastore (Cross-Region Replication)

```
Replicate ElastiCache cluster across AWS regions:
  Primary cluster: us-east-1 (reads + writes)
  Secondary clusters: eu-west-1, ap-southeast-1 (reads only)

Features: [docs.aws.amazon](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Redis-Global-Datastore.html)
  Replication lag: typically < 1 second
  Fully managed: automatic replication + failover
  Promote secondary: if primary region fails → promote secondary → it accepts writes

Use cases:
  Global applications: users read from nearest region (low latency)
  Disaster recovery: primary region fails → promote secondary region
  Compliance: replicate to specific regions for data residency

Supported: Valkey and Redis OSS only (not Memcached)
```

---

## 11. Security ⭐

```
Network isolation:
  ElastiCache always deployed in VPC (no public endpoint)
  Security Group: control inbound access to cache port (6379 Redis, 11211 Memcached)
  Typical: allow port 6379 from app server security group only

Encryption in transit:
  TLS: enabled at cluster creation
  Clients must use TLS endpoint (rediss:// for Redis)
  Note: small CPU overhead for TLS → test latency impact for high-throughput caches

Encryption at rest:
  KMS-based encryption of data on disk (snapshots, AOF files)
  Enable at cluster creation
  Specify AWS managed key (aws/elasticache) or your CMK

Authentication:
  Valkey/Redis: Redis AUTH token (password)
    Set: AUTH mypassword (legacy)
    Or: Redis 6.0+ ACL (Access Control Lists):
        user appuser on >password ~user:* +GET +SET +DEL
        → Limits appuser to only GET/SET/DEL on keys matching user:*
  Memcached: SASL authentication

IAM:
  IAM does NOT directly control Redis data access
  IAM controls: manage ElastiCache clusters (CreateCacheCluster, DeleteReplicationGroup)
  Data access: Redis AUTH tokens / ACLs control who can read/write data
```

---

## 12. ElastiCache vs Other Caching Options

| Feature | ElastiCache (Redis) | ElastiCache (Memcached) | DynamoDB DAX | CloudFront |
|---------|--------------------|-----------------------|-------------|-----------|
| Data structures | Rich (20+ types) | Strings only | Transparent DB cache | HTTP objects |
| Persistence | Optional (RDB/AOF) | ❌ None | ❌ None | ❌ None |
| Replication | ✅ Multi-AZ | ❌ None | ✅ Multi-AZ | Edge PoPs |
| Pub/Sub | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Multi-threaded | Limited | ✅ Yes | Managed | Managed |
| Use case | General cache, sessions, queues | Simple cache, multi-threaded | DynamoDB read acceleration | Static content, API |
| Integration | Any app | Any app | DynamoDB ONLY | HTTP/HTTPS |

```
DAX (DynamoDB Accelerator):
  Built specifically for DynamoDB
  Application code: identical (DAX is API-compatible with DynamoDB SDK)
  Reduces DynamoDB read latency from ms → microseconds
  Manages its own cache invalidation (reads DynamoDB change streams)
  Use: only when your cache source is DynamoDB

ElastiCache:
  Standalone cache — you manage what's in it
  Works with any data source (RDS, DynamoDB, external APIs)
  Rich data structure support (sorted sets, pub/sub, streams)
  Use: when you need flexible caching beyond DynamoDB
```

---

## 13. Pricing ⭐

```
Provisioned (Node-based):
  On-demand: pay per node-hour
  Reserved: 1-year or 3-year commitment → 40–60% discount
  Examples (us-east-1, on-demand):
    cache.t4g.micro  (0.5 GB):  $0.018/hr → ~$13/month
    cache.r7g.large  (13.07 GB): $0.156/hr → ~$112/month
    cache.r7g.xlarge (26.32 GB): $0.313/hr → ~$225/month
  Valkey nodes: 20% cheaper than Redis OSS equivalent [aws.amazon](https://aws.amazon.com/elasticache/pricing/)
  Note: Multi-AZ = 2× node cost (primary + replica both billed)

Serverless: [aws.amazon](https://aws.amazon.com/elasticache/pricing/)
  Redis/Memcached:
    Storage: per GB-hour stored
    Requests: per million ECPUs
    Minimum: 1 GB storage/hour (~$3.75/month base minimum)
  Valkey:
    33% lower pricing on ECPUs
    Minimum: 100 MB storage ← very low minimum for dev use
    Starts at $6/month [aws.amazon](https://aws.amazon.com/elasticache/pricing/)

Reserved Node savings:
  1-year, no upfront: ~40% savings vs on-demand
  1-year, all upfront: ~45% savings
  3-year, all upfront: ~60–75% savings
  → Use for steady production caches running 24/7
```

---

## 14. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| ElastiCache is a primary data store | ElastiCache is a **cache** — data can be evicted; always have a backing store (RDS/DynamoDB) |
| noeviction is best for caches | noeviction returns **errors when full** — use `allkeys-lru` for general caching |
| Cluster mode enabled supports cross-slot MGET freely | CME multi-key operations require **all keys on same shard** — use hash tags `{tag}` to co-locate |
| CMD supports data partitioning | CMD has **single shard** — all data on one node; use CME for horizontal data scaling |
| Deleting ElastiCache pauses billing | Serverless caches **must be deleted** to stop billing — "Available" or "Updating" = billed |
| Cache TTL jitter is optional | Without TTL jitter, **cache stampede** hits DB with simultaneous expirations — always add jitter |
| Write-through means no DB writes | Write-through writes to **both cache AND DB** synchronously — not cache-only |
| ElastiCache has free tier | ElastiCache has **no free tier** — billing starts immediately |
| Redis AUTH controls IAM permissions | Redis AUTH/ACL control **data-level access**; IAM controls cluster management API only |
| AOF + replicas together for best HA | For HA: use **Multi-AZ replicas** — AOF only for single-node; replicas are preferred |

---

## 15. Interview Questions Checklist

- [ ] What is ElastiCache? When would you use it instead of RDS?
- [ ] Valkey vs Redis OSS vs Memcached — key differences? When to choose each?
- [ ] Why is Valkey recommended for new deployments? (20–33% cheaper)
- [ ] Cluster Mode Disabled vs Enabled — shards, data partitioning, multi-key ops
- [ ] Max shards in CME? (500) Max replicas per shard? (5)
- [ ] What are hash slots? How does CME route keys? (CRC16 % 16384)
- [ ] What is a hash tag and why is it used in CME? ({tag} co-locates keys)
- [ ] Three caching strategies — pros/cons of each?
- [ ] Lazy Loading vs Write-Through — when to use each?
- [ ] What is cache stampede? How do you prevent it? (TTL jitter, mutex)
- [ ] Eight eviction policies — which is recommended for a cache? (allkeys-lru)
- [ ] Difference between volatile-* and allkeys-* eviction policies?
- [ ] How does Multi-AZ failover work? Approximate failover time? (~60 sec)
- [ ] ElastiCache Serverless — what are ECPUs? Minimum billing unit?
- [ ] Global Datastore — what is it? Which engines?
- [ ] How do you secure ElastiCache? (VPC, SG, TLS, Redis ACL, KMS)
- [ ] ElastiCache vs DAX — when to use each?
- [ ] How do you prevent cold start on deployment? (cache warming)
- [ ] What data is lost in CMD if primary has no replicas? (ALL data)
- [ ] Can you enable encryption after ElastiCache cluster creation? (NO — set at creation)
