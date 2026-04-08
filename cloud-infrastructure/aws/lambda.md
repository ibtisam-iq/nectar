# AWS Lambda

## 1. What is Lambda?

AWS Lambda is a **serverless, event-driven compute service** — you upload
code and AWS runs it. No servers to provision, no OS to manage, no capacity
to plan. You pay only for the milliseconds your code actually executes.

```
Traditional server model:
  Provision EC2 → install runtime → deploy app → manage 24/7
  Pay: every hour the server exists (even idle hours)

Lambda model:
  Upload code → Lambda runs it on demand
  Pay: only while code executes (per 1ms)
  Idle time: $0
```

> Lambda is not for long-running processes. It is designed for
> **short-lived, stateless functions** that respond to events.

---

## 2. Lambda Execution Model

### Handler Function

Every Lambda function has a **handler** — the entry point AWS invokes:

```python
# Python
def handler(event, context):
    print(event['name'])
    return {
        'statusCode': 200,
        'body': 'Hello from Lambda'
    }
```

```javascript
// Node.js
exports.handler = async (event, context) => {
    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'Hello from Lambda' })
    };
};
```

| Parameter | Contains |
|-----------|---------|
| `event` | Input data from the trigger (HTTP request, S3 event, SQS message, etc.) |
| `context` | Runtime info: function name, remaining time, request ID, memory limit |

### Execution Environment Lifecycle

```
Phase 1: INIT (cold start only)
  ├── Download your code/container
  ├── Start language runtime (Node.js, Python, Java…)
  ├── Run initialization code OUTSIDE handler
  │   (import libraries, create DB connections, load config)
  └── Duration: 100ms to 1+ second

Phase 2: INVOKE
  ├── Run handler function with event
  └── Duration: your code execution time

Phase 3: SHUTDOWN (if no new invocations for ~15 min)
  └── Execution environment frozen/terminated
```

```python
# Code placement matters — INIT vs INVOKE

import boto3                         # ← INIT: runs once per cold start
db_client = boto3.client('dynamodb') # ← INIT: connection created once

def handler(event, context):
    # ← INVOKE: runs every request
    result = db_client.get_item(...)  # reuses existing connection ✅
    return result
```

---

## 3. Cold Start vs Warm Start ⭐

```
Cold Start (new execution environment):
  Trigger arrives → no available environment →
  AWS provisions environment → INIT phase → INVOKE
  Latency added: ~100ms (Python/Node.js) to ~1s+ (Java/.NET)

Warm Start (reuse existing environment):
  Trigger arrives → existing environment available →
  INVOKE directly (skip INIT)
  Latency added: ~0ms
```

### What Causes Cold Starts?

| Trigger | Explanation |
|---------|------------|
| First invocation ever | No environments exist yet |
| Traffic spike | 10 concurrent requests → 10 environments needed simultaneously |
| After ~15 minutes idle | Environment was frozen/recycled |
| Code/config update deployed | New environments needed for new version |
| Region first invocation | No warm environments in that region |

### Cold Start Mitigation Strategies

**1. Provisioned Concurrency (Eliminates Cold Starts)**

```
Pre-initializes N execution environments — always warm and ready.
Incoming requests route to pre-warmed environment → zero cold start.

Must be applied to a FUNCTION VERSION or ALIAS — NOT $LATEST [docs.aws.amazon](https://docs.aws.amazon.com/lambda/latest/dg/provisioned-concurrency.html)

CLI:
  aws lambda put-provisioned-concurrency-config \
    --function-name my-api \
    --qualifier prod \           ← alias or version, not $LATEST
    --provisioned-concurrent-executions 10

Cost: charged per GB-second while environments are provisioned
      (even when not actively executing — this is always-on compute)

Auto-scaling Provisioned Concurrency:
  Scale up at 8am, scale down at 8pm (based on schedule)
  Scale based on utilization metric (target 70% utilization)
```

**2. ARM64 Architecture (Graviton2)**

```
lambda.Architecture.ARM_64
→ 13–24% faster cold starts vs x86_64
→ 20% cheaper per GB-second
→ Use for: most workloads (Python, Node.js, Java)
```

**3. Minimize Package Size**

```
Smaller deployment package = faster code download during INIT
  Use: tree-shaking, exclude dev dependencies
  Use: Lambda layers for shared large libraries
  Use: container images for large dependencies (cached per environment)
```

**4. Move Heavy Work to INIT Phase**

```python
# Do expensive setup once at init, not every request
s3 = boto3.client('s3')               # ← init phase
config = load_config_from_ssm()       # ← init phase (cached)

def handler(event, context):
    return s3.get_object(...)         # ← invoke phase (reuses client)
```

**5. Keep Functions Warm (Scheduled EventBridge)**

```
EventBridge rule: every 5 minutes → invoke Lambda with warmup event
→ Prevents idle timeout from recycling environments
→ Free tier covers most warmup invocations
Note: keeps ONE environment warm — not useful for concurrent scaling
```

---

## 4. Lambda Limits ⭐

| Resource | Limit |
|---------|-------|
| **Memory** | 128 MB – **10,240 MB** (1 MB increments) |
| **Timeout** | 1 second – **900 seconds (15 minutes)** |
| **Ephemeral storage (/tmp)** | 512 MB – 10,240 MB |
| **Deployment package (zip)** | 50 MB compressed / 250 MB uncompressed |
| **Container image size** | 10 GB |
| **Environment variables** | 4 KB total |
| **Layers per function** | 5 layers |
| **Concurrent executions (default)** | 1,000 per region (soft limit — can request increase) |
| **Burst concurrency** | 500–3,000 (varies by region) |

### CPU Scales With Memory

```
Lambda allocates CPU proportional to memory:
  128 MB  → ~0.07 vCPU
  1,769 MB → 1 full vCPU  ← threshold for one full CPU
  3,538 MB → 2 vCPUs
  10,240 MB → ~5.8 vCPUs

For CPU-bound workloads (image processing, ML inference):
  Increase memory → you get more CPU → faster execution
  May actually REDUCE cost: faster = less duration billed
```

---

## 5. Invocation Types

### Synchronous

```
Caller waits for result before continuing

Sources:
  API Gateway, ALB, CloudFront, SDK direct call

Flow:
  Caller → Lambda → executes → returns response → Caller receives result

Error handling: caller receives error immediately
Retry: caller's responsibility
```

### Asynchronous

```
Caller sends event and immediately gets 202 Accepted
Lambda processes in background — caller doesn't wait

Sources:
  S3 event notifications, SNS, EventBridge, CloudWatch Events

Flow:
  Event → Lambda internal queue → Lambda executes
  Caller already moved on

Error handling: Lambda retries automatically
  Default: 2 retries (3 total attempts)
  On final failure → Dead Letter Queue (SQS or SNS)

Configure:
  Maximum age of event: 60s – 6 hours
  Maximum retry attempts: 0, 1, or 2
  On-failure destination: SQS, SNS, EventBridge, another Lambda
```

### Event Source Mapping (Poll-Based)

```
Lambda polls a source for new records, processes in batches

Sources:
  SQS (standard + FIFO)
  Kinesis Data Streams
  DynamoDB Streams
  MSK (Managed Streaming for Kafka)
  MQ (ActiveMQ, RabbitMQ)

Flow:
  Lambda service polls SQS every 1–20 seconds
  Receives batch (up to 10,000 messages for SQS)
  Invokes Lambda with the batch
  On success: messages deleted from SQS
  On failure: messages return to queue (retry) or go to DLQ

Batch settings:
  Batch size: 1–10,000 (SQS), 1–10,000 (Kinesis)
  Batch window: 0–300 seconds (wait to collect larger batch)
```

---

## 6. Event Sources (Triggers) ⭐

| Category | Source | Invocation Type |
|---------|--------|----------------|
| **HTTP** | API Gateway (REST, HTTP) | Synchronous |
| **HTTP** | Application Load Balancer | Synchronous |
| **Storage** | S3 (object events) | Asynchronous |
| **Streaming** | Kinesis Data Streams | Event Source Mapping (poll) |
| **Queue** | SQS | Event Source Mapping (poll) |
| **Database** | DynamoDB Streams | Event Source Mapping (poll) |
| **Messaging** | SNS | Asynchronous |
| **Events** | EventBridge | Asynchronous |
| **Schedule** | EventBridge Scheduler | Asynchronous |
| **Auth** | Cognito User Pools | Synchronous |
| **Edge** | CloudFront (Lambda@Edge) | Synchronous |

---

## 7. Versions and Aliases ⭐

### Versions

```
$LATEST → mutable, always the most recent code
v1, v2, v3 → immutable snapshots of code + configuration

Publish a version:
  aws lambda publish-version --function-name my-function
  → Creates an immutable version (v1, v2…)
  → Version has its own ARN: arn:aws:lambda:...:function:my-function:3

Qualified ARN:   arn:...:my-function:3  → specific version
Unqualified ARN: arn:...:my-function    → $LATEST [docs.aws.amazon](https://docs.aws.amazon.com/lambda/latest/dg/configuration-versions.html)

Cannot edit code of a published version — it is frozen
```

### Aliases

```
A named pointer to a version — can be updated without changing clients

my-function:prod  → points to v3
my-function:dev   → points to $LATEST
my-function:beta  → points to v4

Update prod alias:
  aws lambda update-alias --function-name my-function \
    --name prod --function-version 4
  → prod now points to v4 (no client-side changes needed)

Traffic shifting (canary deployments):
  prod alias: 90% → v3, 10% → v4
  → Gradually shift traffic to test new version in production
  → Use with CodeDeploy for automated rollback on alarms

  aws lambda update-alias --function-name my-function \
    --name prod \
    --routing-config '{"AdditionalVersionWeights":{"4":0.10}}'
```

```
Alias ARN: arn:aws:lambda:...:function:my-function:prod
  → Always resolves to the version the alias points to
  → Use alias ARNs in all triggers/event sources — enables zero-downtime deploys
```

---

## 8. Lambda Layers ⭐

Layers are **ZIP archives containing shared code, libraries, or binaries**
that can be attached to multiple functions:

```
Without layers:
  function-A.zip: code + numpy + pandas + scipy  (200 MB)
  function-B.zip: code + numpy + pandas + scipy  (200 MB)
  function-C.zip: code + numpy + pandas + scipy  (200 MB)
  → 600 MB total, duplicate libraries

With layers:
  numpy-pandas-layer.zip: numpy + pandas + scipy  (180 MB shared layer)
  function-A.zip: code only (5 MB)
  function-B.zip: code only (3 MB)
  function-C.zip: code only (4 MB)
  → 192 MB total, fast deploys, single update point

Layer directory structure (Python):
  python/lib/python3.12/site-packages/
    numpy/
    pandas/

Layer directory structure (Node.js):
  nodejs/node_modules/
    lodash/
    moment/

Limits:
  Max 5 layers per function
  Total unzipped (code + all layers): 250 MB
  Layers versioned (immutable when published)
```

---

## 9. Lambda in a VPC

By default Lambda runs **outside your VPC** (in AWS-managed infrastructure).
Attach Lambda to a VPC when your function needs to access private resources:

```
Use cases for VPC attachment:
  → Lambda → private RDS (no public endpoint)
  → Lambda → private ElastiCache
  → Lambda → private EC2 microservice

VPC configuration:
  Assign to: private subnets (NOT public subnets)
  Assign to: Security Group (controls outbound connections)

Architecture:
  Lambda (in VPC private subnet)
    → security group allows port 3306 → RDS security group
    → connects to private RDS ✅

Internet access from VPC Lambda:
  Lambda in private subnet → NAT Gateway → Internet ✅
  Lambda in private subnet (no NAT) → No internet ❌
  Lambda in public subnet → still no internet (Lambda ignores public subnet routing)
```

> Placing Lambda in a VPC adds ~100ms cold start overhead
> (setting up ENI — Elastic Network Interface). This was worse before 2019;
> AWS significantly reduced it with hyperplane ENIs. Still relevant for
> latency-sensitive synchronous functions.

---

## 10. Concurrency ⭐

```
Concurrency = number of requests being handled simultaneously at one moment

Each in-flight request occupies one execution environment.
If 50 requests arrive simultaneously → 50 concurrent Lambda instances needed.

Account concurrency limit: 1,000 per region (default, soft limit)
  → If function needs 1,001 simultaneous executions → throttled (429 error)

Reserved Concurrency:
  Guarantee N executions are always available for a specific function
  Also caps the function at N → prevents one function consuming all account concurrency

  aws lambda put-function-concurrency \
    --function-name critical-api \
    --reserved-concurrent-executions 100
  → Guarantees: critical-api always gets 100 executions
  → Caps: critical-api never exceeds 100 (even if more available)
  → Set to 0 → throttle the function completely (useful for emergency stop)

Unreserved Concurrency:
  The remaining concurrency (1,000 - sum of all reserved) shared by all other functions
```

### Concurrency Types Summary

| Type | Purpose | Cold Starts |
|------|---------|------------|
| **On-Demand** | Default — scales to account limit | Yes |
| **Reserved** | Guarantees capacity + caps function | Yes |
| **Provisioned** | Pre-warmed environments for specific version/alias | **No** |

---

## 11. Lambda Destinations

Modern replacement for DLQ — route function output to a destination based on success or failure:

```
Asynchronous invocation destinations:
  On success → SQS / SNS / EventBridge / another Lambda
  On failure  → SQS / SNS / EventBridge / another Lambda

Event source mapping destinations:
  On failure  → SQS / SNS

Example: order processing pipeline
  Lambda: process-order
    On success → SNS: notify-customer
    On failure  → SQS: failed-orders-dlq (for manual review + retry)
```

> Destinations provide **more context** than DLQ — they include the full event,
> the function response, error details, and execution metadata. Prefer destinations
> over DLQ for async Lambda error handling.

---

## 12. Lambda@Edge and CloudFront Functions

Run code **at CloudFront edge locations** — closest to the end user:

| | Lambda@Edge | CloudFront Functions |
|--|------------|---------------------|
| Runtime | Node.js, Python | JavaScript only |
| Max memory | 128 MB (viewer) / 10 GB (origin) | 2 MB |
| Max duration | 5s (viewer) / 30s (origin) | < 1ms |
| Network access | ✅ Yes | ❌ No |
| Cost | Higher | 1/6th the cost |
| Triggers | CloudFront viewer/origin req/resp | Viewer request/response only |
| Use case | Auth, A/B test, URL rewrite, API | Header manipulation, URL rewrite, redirects |

```
CloudFront trigger points:
  Viewer Request  → before cache check (Lambda@Edge + CF Functions)
  Origin Request  → cache miss, before origin call (Lambda@Edge only)
  Origin Response → after origin responds (Lambda@Edge only)
  Viewer Response → before sending to user (Lambda@Edge + CF Functions)

Example: auth at edge
  Viewer Request → Lambda@Edge → verify JWT → allow/deny before hitting origin
  → Blocks unauthenticated requests at CDN layer, not your origin server
```

---

## 13. Environment Variables and Configuration

```python
import os

def handler(event, context):
    db_host   = os.environ['DB_HOST']      # ← environment variable
    env_name  = os.environ['ENVIRONMENT']  # ← "prod" / "dev"
    api_key   = os.environ['API_KEY']      # ← sensitive: use KMS encryption

# Environment variables limit: 4 KB total (all variables combined)
# Encrypt with KMS: Lambda console → Configuration → Environment variables → Enable encryption
```

### Secrets — Best Practice

```
Bad:  hardcoded credentials in code or environment variables (plaintext)
OK:   environment variable encrypted with KMS
Best: fetch from Secrets Manager at runtime (auto-rotation, audit trail)

import boto3, json
client = boto3.client('secretsmanager')

# Fetch once in INIT phase — cache in global variable
secret = json.loads(client.get_secret_value(SecretId='prod/db')['SecretString'])
DB_PASSWORD = secret['password']
```

---

## 14. Lambda Pricing

```
Two charges:
  1. Requests: $0.20 per 1 million requests
  2. Duration: $0.0000166667 per GB-second

GB-second = (memory in GB) × (duration in seconds)

Example:
  Function: 512 MB memory, 500ms execution, 1 million requests/month
  Duration cost:
    0.5 GB × 0.5 seconds = 0.25 GB-seconds per request
    × 1,000,000 requests  = 250,000 GB-seconds
    × $0.0000166667       = $4.17
  Request cost: $0.20
  Total: ~$4.37/month

Free tier (every month, does not expire):
  1,000,000 requests/month
  400,000 GB-seconds/month

ARM64 (Graviton): 20% cheaper per GB-second vs x86_64
```

---

## 15. Common Patterns ⭐

### API (Serverless REST API)

```
Client → API Gateway → Lambda → DynamoDB
Scales from 0 to millions of requests
Cost: pay per request, $0 when idle
```

### Event Processing

```
S3 upload → Lambda → resize image → save thumbnail → S3
SQS message → Lambda → process order → DynamoDB + SES email
DynamoDB Stream → Lambda → sync to Elasticsearch
```

### Scheduled Jobs (Cron)

```
EventBridge rule: cron(0 2 * * ? *)  → Lambda: cleanup-old-data
Every day at 2 AM → runs cleanup function
No server needed — serverless cron
```

### Fan-Out Pattern

```
One event → SNS → multiple Lambda subscribers
  Lambda-A: send email
  Lambda-B: update analytics
  Lambda-C: log to audit trail
All three execute in parallel from single SNS publish
```

---

## 16. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Lambda can run indefinitely | Hard timeout: **15 minutes** maximum |
| Increase timeout to fix slow DB queries | Lambda in VPC without NAT/endpoint = no internet — fix networking first |
| Put Lambda in public subnet for internet access | Lambda in public subnet still has no internet — use **private subnet + NAT Gateway** |
| Create DB connection inside handler | Create connection in **INIT phase** (outside handler) — reused across warm invocations |
| Provisioned Concurrency on $LATEST | Provisioned Concurrency must be on a **version or alias** — not $LATEST |
| Layers count against the 250 MB limit | Yes — total unzipped = code + all layers combined must be ≤ 250 MB |
| Cold starts happen on every invocation | Cold starts occur in **< 1% of invocations** in steady workloads |
| Reserved Concurrency = no cold starts | Reserved concurrency limits capacity — only **Provisioned** eliminates cold starts |
| Environment variables have no size limit | All env vars combined: **4 KB total limit** |
| Lambda scales linearly | Lambda scales in burst increments; **burst limit** (500–3000/min) applies on rapid scale-out |

---

## 17. Interview Questions Checklist

- [ ] What is serverless computing? How does Lambda fit?
- [ ] Explain the Lambda execution environment lifecycle (3 phases)
- [ ] What is a cold start? What causes it? How do you fix it?
- [ ] Cold start duration range? When do they occur? (< 1% of invocations)
- [ ] Three invocation types — synchronous, asynchronous, event source mapping
- [ ] Error handling for each invocation type (retries, DLQ, destinations)
- [ ] Versions vs Aliases — what are they? How do you do canary deployments?
- [ ] What is Provisioned Concurrency? Why must it be on a version/alias?
- [ ] Reserved vs Provisioned vs On-Demand concurrency — differences?
- [ ] Why put Lambda in a VPC? What do you lose? What configuration is needed?
- [ ] How do you give Lambda internet access when it's in a VPC?
- [ ] CPU scaling with memory — at what memory is 1 full vCPU? (1,769 MB)
- [ ] What are Lambda Layers? Use case? Limits?
- [ ] Lambda@Edge vs CloudFront Functions — when to use each?
- [ ] Destinations vs DLQ — why prefer destinations for async Lambda?
- [ ] Lambda pricing model — two charges, free tier?
- [ ] What is the ephemeral storage (/tmp) and its limit?
- [ ] Where should you put DB connection creation — handler or outside? Why?
