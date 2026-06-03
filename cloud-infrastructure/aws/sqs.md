# Amazon SQS (Simple Queue Service)

## 1. What is SQS?

Amazon SQS is a **fully managed message queuing service** that decouples
application components by allowing them to communicate asynchronously
via a queue. Producers send messages to the queue; consumers read and
process them independently.

```
Without SQS — tight coupling:
  Web Server → directly calls Image Processor
  If Image Processor is slow/down → Web Server blocked → user waits → cascading failure

With SQS — loose coupling:
  Web Server → sends message to SQS → returns 200 immediately ✅
  Image Processor → reads from SQS at its own pace → processes → deletes message
  Image Processor down? → messages pile up safely in queue → resume when back up
  Web Server completely unaware of downstream failures
```

### Core Guarantees

| Property | Standard Queue | FIFO Queue |
|---------|---------------|-----------|
| Delivery | At-least-once (may duplicate) | Exactly-once |
| Ordering | Best-effort (may be out of order) | Strict FIFO within message group |
| Throughput | Unlimited | 300 TPS / 3,000 TPS (batching) / 30,000 TPS (high-throughput mode) |
| Use case | Maximum throughput, duplicate-tolerant | Order-critical, no duplicates |

---

## 2. Standard Queue ⭐

```
Delivery: at-least-once
  → Every message delivered at least once
  → Due to distributed nature, same message may be delivered twice
  → Your consumer MUST be idempotent (safe to process same message twice)
  → Use MessageId to deduplicate if needed

Ordering: best-effort
  → SQS tries to deliver in order but does NOT guarantee it
  → Under high throughput, messages may arrive out of order

Throughput: nearly unlimited
  → Millions of messages per second
  → Scales automatically

Retention: 1 minute to 14 days (default: 4 days)
Message size: up to 256 KB
  → Larger payloads: store in S3, send S3 reference in message (SQS Extended Client)

Use case: high-volume workloads where duplicates are acceptable
  Image resize jobs, email notifications, analytics events, log processing
```

---

## 3. FIFO Queue ⭐

```
Delivery: exactly-once
  → Message delivered once and only once
  → MessageDeduplicationId prevents duplicates in 5-minute window
  → Content-based deduplication (SHA-256 hash of body) available

Ordering: strict FIFO within a message group
  → MessageGroupId determines which group a message belongs to
  → Messages within same group processed in exact send order
  → Multiple groups → processed in parallel (ordered within each group)

Throughput: [docs.aws.amazon](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-types.html)
  Without batching:      300 TPS (API calls/second)
  With batching (10/batch): 3,000 messages/second
  High-throughput mode:  30,000 TPS (relaxed ordering within message groups)

FIFO queue names must end in: .fifo
  Example: order-processing.fifo

Use cases:
  User command sequences (login → update profile → save)
  Financial transactions (debit must happen before credit)
  E-commerce order steps (payment → inventory → fulfillment in order)
  Price updates (must apply in sequence to avoid wrong price displayed) [docs.aws.amazon](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-types.html)
```

### MessageGroupId and MessageDeduplicationId

```
MessageGroupId: (required for FIFO)
  Logical partition of messages
  All messages with same GroupId processed in order by one consumer at a time
  Different GroupIds → parallel processing → higher throughput

  Example:
    GroupId = "user-123" → all actions for user 123 processed in order
    GroupId = "user-456" → processed in parallel with user 123's messages

MessageDeduplicationId: (required if content-based dedup disabled)
  Unique per message
  Same ID within 5-minute window → second message silently discarded
  Prevents accidental duplicate sends (network retry, producer bug)
```

---

## 4. Message Lifecycle ⭐

```
1. Producer sends message → SQS stores it (replicated across 3 AZs)
2. Consumer calls ReceiveMessage → SQS returns message
3. Message enters INVISIBLE state (visibility timeout starts)
   → Other consumers cannot see it (prevents double processing)
4a. Consumer processes successfully → calls DeleteMessage → message gone ✅
4b. Consumer fails / crashes → visibility timeout expires →
    message becomes VISIBLE again → available for redelivery
    (this is the retry mechanism — no explicit retry needed)
```

---

## 5. Visibility Timeout ⭐

```
Default: 30 seconds
Range:   0 seconds to 43,200 seconds (12 hours) [docs.aws.amazon](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-sqs-queue.html)

What it is: time window during which a received message is hidden from
            other consumers while one consumer is processing it

Too short:
  Consumer still processing → timeout expires → message reappears →
  another consumer picks it up → double processing ❌

Too long:
  Consumer crashes after receiving → message hidden for a long time →
  other consumers can't retry until timeout expires → slow recovery ❌

Set timeout = expected max processing time + buffer
  Lambda processing: set timeout > Lambda function timeout

Extend dynamically:
  Consumer calls ChangeMessageVisibility before timeout expires
  → Extends by additional N seconds
  → Use for long-running jobs that need more time [docs.aws.amazon](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html)
```

---

## 6. Polling: Short vs Long ⭐

### Short Polling (Default)

```
ReceiveMessage → SQS checks a SUBSET of servers → returns immediately
  → May return 0 messages even if messages exist (not checked all servers yet)
  → Requires many API calls to drain queue → higher cost

WaitTimeSeconds = 0  ← short polling
```

### Long Polling (Recommended)

```
ReceiveMessage → SQS waits up to 20 seconds for a message to arrive
  → Returns as soon as message available OR timeout reached
  → Eliminates empty responses → significantly reduces API call count → lower cost
  → Reduces false-empty responses (checks all servers, not subset)

WaitTimeSeconds = 1 to 20  ← long polling (20 = maximum, recommended)

Enable at queue level OR per ReceiveMessage call
Always prefer long polling in production — reduces cost and improves latency [docs.aws.amazon](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html)
```

---

## 7. Dead-Letter Queue (DLQ) ⭐

```
A DLQ is a separate queue that receives messages that could not be
processed successfully after a configured number of attempts.

maxReceiveCount: how many times a message can be received before moving to DLQ
  Default recommendation: 3–5 attempts

Flow:
  Message received → processing fails → visibility timeout expires → visible again
  Received a 2nd time → fails → visible again
  Received a 3rd time → maxReceiveCount=3 reached → moved to DLQ

DLQ benefits:
  Failed messages isolated → don't block other messages
  Inspect failed messages → diagnose root cause
  Fix bug → redrive messages from DLQ back to source queue (DLQ Redrive)
  CloudWatch alarm on DLQ depth → alert on processing failures

DLQ rules:
  Standard queue → DLQ must also be Standard
  FIFO queue     → DLQ must also be FIFO
  Same region and account as source queue
  DLQ retention should be LONGER than source queue retention
    (so messages don't expire in DLQ before you can inspect them)
```

### DLQ Redrive

```
After fixing the bug:
  SQS → Dead-Letter Queues → Start DLQ redrive
  → SQS moves messages from DLQ back to source queue
  → Messages reprocessed by consumers

Or use Lambda to process DLQ separately for special handling
```

---

## 8. Message Attributes and Metadata

```
Message body: up to 256 KB of any content (JSON, XML, plain text, binary)

Message attributes (metadata — up to 10 per message):
  Name, Type (String, Number, Binary), Value
  Example:
    "OrderId":   { Type: "String", Value: "ORD-12345" }
    "Priority":  { Type: "Number", Value: "1" }
    "Source":    { Type: "String", Value: "web-checkout" }

  Use for: routing, filtering, business metadata without parsing body

MessageId: UUID auto-generated by SQS (use for deduplication in Standard queues)
ReceiptHandle: token to delete the message (valid only for current receive)
```

---

## 9. SQS + Lambda (Event Source Mapping) ⭐

```
Lambda polls SQS automatically (you don't write polling code):
  Lambda service reads batches from SQS → invokes Lambda → passes batch as event

Batch settings:
  Batch size:       1–10,000 messages (Standard), 1–10 (FIFO)
  Batch window:     0–300 seconds (wait to collect larger batch)
  Concurrency:      one Lambda per message group (FIFO), N Lambdas (Standard)

Message deletion behavior:
  Lambda returns SUCCESS → SQS deletes all messages in batch ✅
  Lambda throws ERROR → SQS returns ALL messages to queue (full retry)
  → Problem: one bad message → entire batch retried → good messages reprocessed

Partial batch response (recommended):
  Lambda returns { "batchItemFailures": [{"itemIdentifier": "msgId"}] }
  → Only failed messages returned to queue
  → Successful messages deleted ✅
  Enable: FunctionResponseTypes = ["ReportBatchItemFailures"]

Scaling:
  SQS Standard → Lambda scales up to 1,000 concurrent functions (60/min)
  SQS FIFO → one concurrent Lambda per MessageGroupId
```

---

## 10. SQS + SNS (Fan-Out Pattern) ⭐

```
Single SNS topic → multiple SQS queues → each processed independently

Example: order placed event
  SNS: order-events
    → SQS: inventory-queue     → Lambda: update inventory
    → SQS: payment-queue       → Lambda: charge payment
    → SQS: notification-queue  → Lambda: send confirmation email
    → SQS: analytics-queue     → Lambda: update dashboard

Benefits:
  Each subscriber processes at its own rate
  One queue slow/failed → others unaffected
  Add new subscriber without changing producer
  Each queue has its own DLQ
  Guaranteed delivery even if consumer is temporarily down [docs.aws.amazon](https://docs.aws.amazon.com/sns/latest/dg/sns-sqs-as-subscriber.html)
```

---

## 11. SQS Security

```
Encryption:
  In-transit: HTTPS by default
  At-rest:    SSE-SQS (AES-256, managed by SQS) or SSE-KMS (your key)
  Enable at queue creation or update

Access control:
  IAM policy: identity-based (who can send/receive from queue)
  SQS queue policy: resource-based (cross-account access)

Cross-account access:
  Queue owner adds queue policy allowing other account:
  {
    "Effect": "Allow",
    "Principal": { "AWS": "arn:aws:iam::ACCOUNT-B:root" },
    "Action": ["sqs:SendMessage", "sqs:ReceiveMessage"],
    "Resource": "arn:aws:sqs:us-east-1:ACCOUNT-A:my-queue"
  }
```

---

## 12. SQS Limits

| Setting | Value |
|---------|-------|
| Message size | Up to 256 KB (use S3 + SQS Extended Client for larger) |
| Message retention | 1 minute – 14 days (default: 4 days) |
| Visibility timeout | 0 – 43,200 seconds (12 hours) |
| Long poll wait time | 0 – 20 seconds |
| Max messages per ReceiveMessage | 10 |
| Delay queue (delay per message) | 0 – 900 seconds (15 minutes) |
| In-flight messages (Standard) | 120,000 |
| In-flight messages (FIFO) | 20,000 per message group |
| Queues per account | Unlimited (soft: 1,000 queues visible in console by default) |

---

## 13. Delay Queues

```
Delay queue: all messages invisible for N seconds after being sent
  Configure at queue level: DelaySeconds = 0–900
  Or per message: set MessageDeduplicationId delay on send

Use case:
  Payment processing: delay 30 seconds → give user time to cancel
  Rate limiting: spread processing over time
  Scheduled notifications: "send in 10 minutes"
```

---

## 14. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Standard queue guarantees no duplicates | Standard delivers **at-least-once** — always write idempotent consumers |
| Visibility timeout = message TTL | Visibility timeout = **hiding period during processing** — not expiry |
| Short polling is faster | Short polling has **higher cost and empty responses** — always use long polling |
| FIFO queue processes all messages in one order | FIFO is ordered **within a MessageGroupId** — different groups process in parallel |
| DLQ must be same type as source | DLQ **must be same type** — Standard→Standard, FIFO→FIFO |
| Lambda deletes messages after processing by default | Lambda deletes only on **full batch success** — use partial batch response for fault tolerance |
| FIFO queue name can be anything | FIFO queue names **must end in `.fifo`** |
| maxReceiveCount = 1 is safe | maxReceiveCount=1 → first failure goes to DLQ → **no retry** — use 3–5 |

---

## 15. Orders Service SQS Integration (EKS / Helm) ⭐

This section covers the complete workflow for integrating the Orders microservice with SQS on EKS — from creating the queue to patching the Helm-managed deployment with the missing environment variable.

### Architecture

```
User places order
  → Orders Service (EKS pod, namespace: orders)
  → publishes event to SQS queue: orders-events
  → downstream consumers (Lambda, other services) read from queue

Orders service reads messaging config from env vars:
  RETAIL_ORDERS_MESSAGING_PROVIDER=sqs
  RETAIL_ORDERS_MESSAGING_SQS_TOPIC=orders-events
```

> The Orders Helm chart supports three messaging providers: `in-memory`, `sqs`, `rabbitmq`.
> The chart sets `RETAIL_ORDERS_MESSAGING_PROVIDER` via `values.yaml` but does **not**
> expose an extra-env field to inject `RETAIL_ORDERS_MESSAGING_SQS_TOPIC`. That variable
> must be patched directly into the Deployment (see Step 5 below).

---

### Step 1: Create the SQS Queue

```bash
aws sqs create-queue --queue-name orders-events
```

This creates a **Standard queue** named `orders-events`. Standard is correct here — order events
are high-volume and downstream consumers are idempotent (safe to process duplicates).

Note the returned QueueUrl — you will need the queue ARN for the IAM policy:

```bash
# Get the queue ARN (needed for IAM policy)
aws sqs get-queue-attributes \
  --queue-url https://sqs.us-east-1.amazonaws.com/${AWS_ACCOUNT_ID}/orders-events \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text
# Output: arn:aws:sqs:us-east-1:ACCOUNT_ID:orders-events
```

---

### Step 2: Create the IAM Policy for SQS Access

```bash
cat > orders-sqs-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAPIActionsOnOrdersQueue",
      "Effect": "Allow",
      "Action": [
        "sqs:CreateQueue",
        "sqs:SendMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl"
      ],
      "Resource": "arn:aws:sqs:us-east-1:${AWS_ACCOUNT_ID}:orders-events"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name orders-sqs-policy \
  --policy-document file://orders-sqs-policy.json
```

#### Why these four actions?

| Action | Purpose |
|--------|---------|
| `sqs:CreateQueue` | Allows the service to create the queue if it doesn't exist (idempotent in most SDKs) |
| `sqs:SendMessage` | The core action — publish an order event to the queue |
| `sqs:GetQueueAttributes` | Read queue metadata (ARN, depth, policy) used by SDKs on startup |
| `sqs:GetQueueUrl` | Resolve the queue name → URL (required before any API call can be made) |

> The SQS ARN format is `arn:aws:sqs:REGION:ACCOUNT_ID:QUEUE_NAME` — note **sqs** in the
> service field, not `sqs/queue` or any other variant. The queue name is the final segment
> with no leading slash.

---

### Step 3: Create IRSA and Bind to the Orders ServiceAccount

```bash
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --region $AWS_REGION \
  --namespace orders \
  --name orders \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/orders-sqs-policy \
  --role-name orders-to-sqs \
  --approve \
  --override-existing-serviceaccounts
```

This command:
- Creates an IAM role `orders-to-sqs` with a trust policy scoped to the cluster's OIDC provider
- Attaches `orders-sqs-policy` to the role
- Annotates the existing `orders` ServiceAccount in the `orders` namespace with the role ARN
- Does **not** reinstall the Helm chart — the annotation is added in-place

#### Verify the ServiceAccount annotation

```bash
kubectl get sa orders -o yaml -n orders
```

Expected output (look for the annotation):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/orders-to-sqs
  labels:
    app.kubernetes.io/component: service
    app.kubernetes.io/instance: orders
    app.kubernetes.io/managed-by: eksctl
  name: orders
  namespace: orders
```

---

### Step 4: Configure the Orders Helm Chart

Update `values.yaml` to switch the messaging provider from `in-memory` to `sqs`:

```yaml
# Before
app:
  messaging:
    provider: 'in-memory'

# After
app:
  messaging:
    provider: 'sqs'
    sqs:
      topic: "orders-events"   # this is the SQS queue name (not an SNS topic)
```

The chart will set these environment variables on the Orders pod:

```
RETAIL_ORDERS_MESSAGING_PROVIDER=sqs
```

> ⚠️ **Chart Limitation:** The Retail Orders Helm chart does not expose an extra-env
> field. It sets `RETAIL_ORDERS_MESSAGING_PROVIDER` from `values.yaml`, but
> `RETAIL_ORDERS_MESSAGING_SQS_TOPIC` cannot be injected via Helm values.
> It must be patched directly into the Deployment (Step 5).
> The chart maintainers are expected to fix this in a future release.

---

### Step 5: Patch the Missing Environment Variable

Because the Helm chart does not expose a way to set `RETAIL_ORDERS_MESSAGING_SQS_TOPIC`,
patch the Deployment directly:

```bash
kubectl set env deployment/orders \
  RETAIL_ORDERS_MESSAGING_SQS_TOPIC=orders-events \
  -n orders
```

This injects the env var directly into the running Deployment spec. The pod is restarted
automatically. Note: this change is outside Helm — a `helm upgrade` will overwrite it.
If you re-upgrade, re-run this patch command afterward.

---

### Step 6: Verify

#### Check env vars are present in the pod

```bash
kubectl exec -it deploy/orders -n orders -- env | grep RETAIL
```

Expected output — look for all three:

```
RETAIL_ORDERS_PERSISTENCE_PROVIDER=postgres
RETAIL_ORDERS_PERSISTENCE_NAME=orders
RETAIL_ORDERS_MESSAGING_PROVIDER=sqs
RETAIL_ORDERS_MESSAGING_SQS_TOPIC=orders-events   ← confirm this is present
```

#### If the queue env var is still missing after the patch

```bash
kubectl rollout restart deploy/orders -n orders
```

Then verify again with the `exec` command above.

#### Confirm the queue is receiving messages

Place a test order in the UI. The `orders-events` SQS queue is created at runtime on the
first `SendMessage` call — it will not appear in the console until an order event is published.

```bash
# Check the queue depth after placing an order
aws sqs get-queue-attributes \
  --queue-url https://sqs.${AWS_REGION}.amazonaws.com/${AWS_ACCOUNT_ID}/orders-events \
  --attribute-names ApproximateNumberOfMessages
```

---

### End-to-end flow summary

```
Step 1: aws sqs create-queue --queue-name orders-events
          → Standard SQS queue created

Step 2: aws iam create-policy --policy-name orders-sqs-policy
          → IAM policy with SendMessage + GetQueueUrl + GetQueueAttributes + CreateQueue

Step 3: eksctl create iamserviceaccount ... --role-name orders-to-sqs
          → IRSA role created
          → orders ServiceAccount annotated with role ARN
          → Pod gets temporary AWS credentials via projected token

Step 4: Update values.yaml: provider: 'sqs'
          → Helm sets RETAIL_ORDERS_MESSAGING_PROVIDER=sqs on pod

Step 5: kubectl set env deployment/orders RETAIL_ORDERS_MESSAGING_SQS_TOPIC=orders-events -n orders
          → Patch injects the missing env var the chart cannot set

Step 6: kubectl exec -it deploy/orders -n orders -- env | grep RETAIL
          → Verify all three env vars are present

Result: Orders service publishes an event to SQS for every order placed ✅
```
