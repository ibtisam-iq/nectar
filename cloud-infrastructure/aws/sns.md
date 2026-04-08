# Amazon SNS (Simple Notification Service)

## 1. What is SNS?

Amazon SNS is a **fully managed pub/sub (publish-subscribe) messaging
service**. Publishers send one message to a topic; SNS delivers it
simultaneously to all subscribed endpoints — push-based, no polling.

```
Model: ONE-TO-MANY (fan-out)

SQS model: PULL — consumer polls queue when ready
SNS model: PUSH — SNS pushes to all subscribers immediately

Publisher → SNS Topic → [  SQS Queue      ]
                         [  Lambda        ]
                         [  HTTP endpoint ]
                         [  Email         ]
                         [  SMS           ]
                         [  Mobile Push   ]

All subscribers receive the SAME message simultaneously
```

---

## 2. Topics: Standard vs FIFO ⭐

### Standard Topic

```
Delivery:   at-least-once (may duplicate)
Ordering:   best-effort (may be out of order)
Throughput: nearly unlimited
Subscribers: up to 12.5 million per topic [aws.amazon](https://aws.amazon.com/sns/features/)
Topics per account: 100,000 [aws.amazon](https://aws.amazon.com/sns/features/)

Compatible subscriber types:
  SQS Standard, SQS FIFO, Lambda, HTTP/HTTPS, Email, SMS,
  Mobile Push, Kinesis Data Firehose

Use case: maximum fan-out, high throughput, duplicate-tolerant
```

### FIFO Topic

```
Delivery:   exactly-once
Ordering:   strict FIFO
Throughput: 300 TPS publish (matches FIFO SQS limits)
Subscribers: up to 100 per topic [aws.amazon](https://aws.amazon.com/sns/features/)
Topics per account: 1,000 [aws.amazon](https://aws.amazon.com/sns/features/)

Compatible subscriber types:
  SQS FIFO ONLY

Topic name must end in: .fifo

Use case: order-critical events (financial transactions, inventory updates)
```

| | Standard Topic | FIFO Topic |
|--|---------------|-----------|
| Delivery | At-least-once | Exactly-once |
| Ordering | Best-effort | Strict FIFO |
| Max subscribers | 12.5 million | 100 |
| Max topics/account | 100,000 | 1,000 |
| Subscriber types | All (SQS, Lambda, HTTP, Email, SMS, Mobile) | SQS FIFO only |

---

## 3. Subscription Types ⭐

SNS supports two categories of subscriptions:

### A2A (Application-to-Application)

| Type | Use Case |
|------|---------|
| **SQS** | Durable message buffering — fan-out to queues for async processing |
| **Lambda** | Serverless processing — invoke function per message |
| **HTTP/HTTPS** | Push to any web endpoint (webhooks, microservices) |
| **Kinesis Data Firehose** | Stream to S3, Redshift, Splunk, OpenSearch |

### A2P (Application-to-Person)

| Type | Use Case |
|------|---------|
| **Email** | Human-readable notifications (plain text — not for transactional email, use SES) |
| **Email-JSON** | Raw JSON payload to email address |
| **SMS** | Text messages to mobile phones |
| **Mobile Push** | Push notifications to iOS (APNS), Android (FCM/GCM), Windows |

---

## 4. Message Publishing

```python
import boto3, json

sns = boto3.client('sns', region_name='us-east-1')

# Simple publish
sns.publish(
    TopicArn='arn:aws:sns:us-east-1:123456789012:order-events',
    Message=json.dumps({
        'orderId': 'ORD-12345',
        'userId': 'USER-789',
        'amount': 149.99,
        'items': ['laptop', 'mouse']
    }),
    Subject='New Order Placed',       # used by Email subscriptions as subject line
    MessageAttributes={
        'eventType': {
            'DataType': 'String',
            'StringValue': 'ORDER_PLACED'
        },
        'region': {
            'DataType': 'String',
            'StringValue': 'pk'
        }
    }
)
```

### Message Structure to Subscribers

```json
{
  "Type": "Notification",
  "MessageId": "abc123-...",
  "TopicArn": "arn:aws:sns:us-east-1:123456789012:order-events",
  "Subject": "New Order Placed",
  "Message": "{\"orderId\":\"ORD-12345\",\"userId\":\"USER-789\"}",
  "Timestamp": "2026-04-08T17:00:00.000Z",
  "SignatureVersion": "1",
  "Signature": "...",
  "MessageAttributes": {
    "eventType": { "Type": "String", "Value": "ORDER_PLACED" }
  }
}
```

> **Raw Message Delivery:** By default, SNS wraps your message in the JSON
> envelope above. Enable Raw Message Delivery on SQS/Lambda/HTTP subscriptions
> to receive only your original message body — no SNS envelope.

---

## 5. Message Filtering ⭐

By default every subscriber receives every message. Filter policies let
each subscriber receive **only the messages it cares about**:

```
Without filtering:
  SNS topic: all-events
    → SQS: order-service  receives: orders, payments, returns, reviews
    → SQS: payment-service receives: orders, payments, returns, reviews
    (each must filter in code — wasteful, complex)

With filtering:
  SNS topic: all-events
    → SQS: order-service   filter: {"eventType": ["ORDER_PLACED", "ORDER_CANCELLED"]}
    → SQS: payment-service filter: {"eventType": ["PAYMENT_SUCCESS", "PAYMENT_FAILED"]}
    → SQS: review-service  filter: {"eventType": ["REVIEW_SUBMITTED"]}
    (each receives only its own events — clean, decoupled)
```

### Filter Policy Scopes

```
MessageAttributes scope (default):
  Filter on MessageAttributes sent with publish call
  Message body can be anything (not parsed)

MessageBody scope:
  Filter on JSON fields inside the message body itself
  Message body must be valid JSON
  Enable: FilterPolicyScope = "MessageBody"
```

### Filter Policy Syntax

```json
// Exact string match
{ "eventType": ["ORDER_PLACED"] }

// Multiple allowed values (OR logic)
{ "eventType": ["ORDER_PLACED", "ORDER_UPDATED", "ORDER_CANCELLED"] }

// Numeric filter
{ "amount": [{ "numeric": [">=", 100] }] }
{ "amount": [{ "numeric": [">", 50, "<=", 500] }] }

// String prefix
{ "customerId": [{ "prefix": "PREMIUM-" }] }

// Exists / not exists
{ "referralCode": [{ "exists": true }] }
{ "testFlag":     [{ "exists": false }] }

// Anything-but (exclude specific values)
{ "eventType": [{ "anything-but": ["TEST_EVENT", "INTERNAL_PING"] }] }

// Combined (AND logic between keys)
{
  "eventType": ["ORDER_PLACED"],
  "region": ["pk", "in", "bd"],
  "amount": [{ "numeric": [">=", 50] }]
}
```

---

## 6. Fan-Out Pattern ⭐

The most common SNS architecture — one publish fans out to many consumers:

```
Order Service publishes ONE message to SNS:
  sns.publish(TopicArn=ORDER_TOPIC, Message=order_json)

SNS simultaneously delivers to ALL subscribers:
  → SQS: fulfillment-queue    → Lambda polls → picks items → ships
  → SQS: payment-queue        → Lambda polls → processes payment
  → SQS: email-queue          → Lambda polls → SES sends confirmation
  → SQS: analytics-queue      → Lambda polls → updates dashboard
  → Lambda: fraud-detection   → invoked immediately → checks fraud score
  → HTTP: partner-webhook     → notifies fulfillment partner

All processing happens in PARALLEL
One service failure doesn't affect others
Each SQS queue has its own DLQ for failure handling
```

---

## 7. SNS + SQS: Why Both Together? ⭐

```
SNS alone:
  ✅ Instant fan-out to many subscribers
  ❌ If Lambda/HTTP endpoint down → message LOST
  ❌ No retry buffer
  ❌ Consumer must be always available

SQS alone:
  ✅ Durable buffering with retry
  ✅ Consumer reads when ready
  ❌ Only one consumer type per queue
  ❌ Send to multiple consumers = publish to each queue separately

SNS + SQS together:
  ✅ SNS fan-out: publish once → all queues receive simultaneously
  ✅ SQS durability: message buffered if consumer down
  ✅ SQS retry: visibility timeout + DLQ
  ✅ Each queue independently scalable
  ✅ Decoupled: publisher doesn't know about consumers
  This is the standard production architecture [docs.aws.amazon](https://docs.aws.amazon.com/sns/latest/dg/sns-sqs-as-subscriber.html)
```

---

## 8. SNS Message Delivery Retries

```
For managed endpoints (SQS, Lambda):
  SNS retries until success or message expires
  SQS: durable — message stored until consumed
  Lambda: retried with exponential backoff

For HTTP/HTTPS endpoints:
  Retry policy (exponential backoff with jitter):
    Immediate:    3 retries (0 delay)
    Pre-backoff:  2 retries (1s delay)
    Backoff:      10 retries (exponential: 1s → 20 minutes)
    Post-backoff: 100,000 retries (20 minutes each) ← effectively unlimited

  On final failure (all retries exhausted):
    → Message discarded (unless DLQ configured on subscription)

SNS Subscription DLQ:
  Can attach SQS queue as DLQ on individual subscription
  Failed deliveries → DLQ for investigation
  Different from SQS DLQ (that's on the queue, not the subscription)
```

---

## 9. Mobile Push Notifications

```
SNS as push notification platform for mobile apps:

Platforms supported:
  Apple APNS    → iOS, macOS, tvOS
  Google FCM    → Android
  Amazon ADM    → Kindle Fire
  Baidu         → China Android devices
  Microsoft WNS → Windows

Flow:
  1. Mobile app registers with platform (APNS/FCM) → gets device token
  2. App sends device token to your backend
  3. Backend creates SNS Platform Endpoint using token
  4. Backend calls sns.publish(TargetArn=endpoint_arn, Message=...)
  5. SNS routes to correct platform → platform delivers to device

Fan-out to millions of devices:
  Create SNS topic → subscribe millions of platform endpoints
  sns.publish(TopicArn=...) → SNS pushes to all devices simultaneously
  → Scales to millions of devices per publish
```

---

## 10. SNS Security

```
Encryption:
  In-transit: HTTPS by default
  At-rest: SSE-SNS (AES-256) or SSE-KMS (your KMS key)

Access control:
  IAM policy: who can publish to topic, subscribe, manage
  SNS resource policy: cross-account publishing

Cross-account publishing:
  Account B wants to publish to Account A's topic:
  Account A adds resource policy:
  {
    "Effect": "Allow",
    "Principal": { "AWS": "arn:aws:iam::ACCOUNT-B:root" },
    "Action": "sns:Publish",
    "Resource": "arn:aws:sns:us-east-1:ACCOUNT-A:my-topic"
  }

Subscription confirmation:
  HTTP/HTTPS subscriptions: SNS sends confirmation request
  Endpoint must respond to confirmation URL within 3 days
  Prevents SNS from spamming endpoints without consent
```

---

## 11. SNS Pricing

```
Standard Topic:
  First 1 million publishes/month: FREE
  After: $0.50 per million publish requests

  Deliveries:
    SQS / Lambda / HTTP:        $0.50 per million
    Email:                      $2.00 per 100,000
    SMS (US):                   $0.00645 per message
    Mobile Push (APNS/FCM):     $0.50 per million

FIFO Topic:
  Publish: $0.30 per million
  Delivery to SQS FIFO: $0.30 per million
```

---

## 12. SNS vs SQS vs EventBridge ⭐

| | SNS | SQS | EventBridge |
|--|-----|-----|-------------|
| Pattern | Pub/Sub (push) | Queue (pull) | Event bus (route) |
| Delivery | Push to subscribers | Pull by consumer | Route to targets |
| Persistence | No (fire and forget) | Yes (up to 14 days) | Yes (24 hours) |
| Fan-out | ✅ One-to-many | ❌ One consumer (mostly) | ✅ One-to-many |
| Filtering | Message attributes / body | ❌ None | ✅ Rich pattern matching |
| Ordering | Best-effort (FIFO topic: strict) | Best-effort (FIFO queue: strict) | Best-effort |
| Replay | ❌ | ❌ | ✅ Archive + replay |
| Sources | Your code only | Your code only | 200+ AWS services + SaaS |
| Use case | Fan-out notifications | Task queue, buffering | Event-driven architecture |

---

## 13. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| SNS stores messages if subscriber is down | SNS is **fire-and-forget** — messages lost if HTTP endpoint down; use SNS→SQS for durability |
| All subscribers receive all messages | Default yes, but **filter policies** let each subscriber select only relevant messages |
| FIFO topic works with any subscriber | FIFO topic only supports **SQS FIFO** subscribers |
| SNS replaces SES for transactional email | SNS email = plain text, no DKIM/tracking; **use SES** for transactional email |
| Raw message delivery is always better | Raw delivery strips SNS envelope — HTTP endpoints that need **signature verification** need the envelope |
| SNS DLQ and SQS DLQ are the same thing | SNS DLQ is on **subscription** (failed delivery); SQS DLQ is on **queue** (failed processing) — different layers |
| Filter policy AND applies within an array | Values within an array are **OR**; separate keys are **AND** |
| FIFO topic name can be anything | FIFO topic names **must end in `.fifo`** |
