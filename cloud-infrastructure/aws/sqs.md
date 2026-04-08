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
