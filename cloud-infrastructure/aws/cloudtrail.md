# AWS CloudTrail

## 1. What is CloudTrail?

CloudTrail is AWS's **audit and governance service** — it records every
API call made in your AWS account (who did what, to which resource, when,
from where) and delivers those records as log events for compliance,
security analysis, and operational troubleshooting.

```
Every action in AWS = an API call:
  Console click → API call → CloudTrail records it
  CLI command   → API call → CloudTrail records it
  SDK call      → API call → CloudTrail records it
  AWS service acting on your behalf → CloudTrail records it

CloudTrail answers:
  "Who created this EC2 instance?" → CloudTrail
  "Who deleted the S3 bucket?"     → CloudTrail
  "Which IAM role made this change at 3am?" → CloudTrail
  "Was this production change authorized?" → CloudTrail
```

> CloudTrail is **enabled by default** in every AWS account from day one.
> Events are viewable in the console for the **last 90 days** for free.
> For longer retention, you create a **trail**.

---

## 2. Four Event Types ⭐

### 1. Management Events (Control Plane)

```
Operations on AWS resources themselves — create, modify, delete:
  CreateBucket, DeleteBucket        ← S3 management
  RunInstances, TerminateInstances  ← EC2
  CreateUser, AttachRolePolicy      ← IAM
  CreateVpc, ModifySecurityGroup    ← networking
  ConsoleLogin                      ← console sign-in

Logged by default: YES (both read and write, configurable)
Cost: FREE for first copy of management events in a trail
Read events:  DescribeInstances, ListBuckets  → low security value, high volume
Write events: RunInstances, DeleteBucket      → high security value (default)
```

### 2. Data Events (Data Plane)

```
Operations ON the data inside resources — high volume, not logged by default:
  S3:  GetObject, PutObject, DeleteObject (per-object operations)
  Lambda: InvokeFunction (every function execution)
  DynamoDB: GetItem, PutItem, DeleteItem
  SQS: SendMessage, ReceiveMessage
  Secrets Manager: GetSecretValue

Logged by default: NO (must explicitly enable)
Cost: CHARGED per event (can be very high for busy S3 buckets)
Use case: compliance requiring per-object access tracking, forensic investigation
```

### 3. Network Activity Events

```
AWS PrivateLink (VPC Endpoint) network activity:
  API calls made through interface VPC endpoints

Logged by default: NO
Use case: auditing which VPC endpoints are being used, by whom
```

### 4. Insights Events ⭐

```
CloudTrail Insights detects UNUSUAL API activity by analyzing management events:
  Unusual API call RATE    → e.g., suddenly 100× more DescribeInstances than normal
  Unusual API error RATE   → e.g., AccessDenied errors spiking (credential stuffing)

How it works: [docs.aws.amazon](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-insights-events-with-cloudtrail.html)
  Baseline: CloudTrail analyzes past patterns → establishes normal API call rate
  Detection: current rate deviates significantly → Insights event generated
  Event pair: one START event + one END event (shows duration of unusual activity)

insightDetails block contains: [docs.aws.amazon](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-insights-fields-trails.html)
  API name causing unusual activity
  Error code (if error-based insight)
  Start time and end time
  Statistics: baseline average vs actual count
  User agents and IAM identities involved

Logged by default: NO (must enable on trail/event data store)
Cost: CHARGED per 100,000 events analyzed
Retention: 90 days viewable in console [docs.aws.amazon](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-insights-events.html)

Use case:
  "Was there a credential stuffing attack on our API?"
  "Did an automated script accidentally loop and make 10,000 API calls?"
  "Alert when any IAM action rate is 5× above normal"
```

---

## 3. Trails ⭐

A **trail** is a configuration that delivers CloudTrail events to S3
(and optionally CloudWatch Logs and SNS) for long-term retention and analysis:

```
Without trail: 90 days in console only (no export, no analysis)
With trail:    events → S3 (unlimited retention) + optional CW Logs + SNS

Trail types:
  Single-region:         logs events in one AWS region
  Multi-region (recommended): logs events in ALL regions
    → Catches attacks from unexpected regions
    → Single S3 bucket receives all regions' logs
    → Enable with: --is-multi-region-trail

Organization trail:
  Created in management account → applies to ALL accounts in the organization
  Member accounts cannot disable it [docs.aws.amazon](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-events-with-cloudtrail.html)
  → Central security log for entire organization
  → S3 bucket in management account receives logs from all accounts
```

### Trail Configuration

```
S3 bucket:
  CloudTrail writes log files to: s3://my-cloudtrail-bucket/AWSLogs/AccountId/CloudTrail/Region/Year/Month/Day/
  File format: gzipped JSON
  File integrity validation: SHA-256 hash → detect if logs were tampered

CloudWatch Logs integration (optional):
  Trail → CloudWatch Log Group → metric filters → alarms
  Example: alarm on root account usage, unauthorized API calls

SNS notification (optional):
  Notify when new log file delivered to S3
  → Trigger Lambda to process immediately

Log file encryption:
  Default: SSE-S3 (AES-256)
  Optional: SSE-KMS with your own key (for compliance)
```

---

## 4. CloudTrail Event Record Structure

```json
{
  "eventVersion": "1.08",
  "userIdentity": {
    "type": "IAMUser",
    "principalId": "AIDAIOSFODNN7EXAMPLE",
    "arn": "arn:aws:iam::123456789012:user/ibtisam",
    "accountId": "123456789012",
    "userName": "ibtisam"
  },
  "eventTime": "2026-04-08T03:22:31Z",
  "eventSource": "ec2.amazonaws.com",
  "eventName": "TerminateInstances",
  "awsRegion": "us-east-1",
  "sourceIPAddress": "203.0.113.47",
  "userAgent": "aws-cli/2.15.0",
  "requestParameters": {
    "instancesSet": {
      "items": [{ "instanceId": "i-1234567890abcdef0" }]
    }
  },
  "responseElements": {
    "instancesSet": {
      "items": [{ "instanceId": "i-1234567890abcdef0", "currentState": "shutting-down" }]
    }
  },
  "errorCode": null,
  "errorMessage": null
}
```

| Field | Answers |
|-------|---------|
| `userIdentity` | **Who** — IAM user, role, service, root, federated |
| `eventTime` | **When** |
| `eventSource` | **Which service** — ec2, s3, iam, lambda |
| `eventName` | **What action** — RunInstances, DeleteBucket |
| `awsRegion` | **Where** |
| `sourceIPAddress` | **From where** — client IP or AWS service |
| `requestParameters` | **What was requested** — input parameters |
| `responseElements` | **What changed** — output/result |
| `errorCode` | **Did it fail** — AccessDenied, NoSuchBucket |

---

## 5. CloudTrail Lake ⭐

CloudTrail Lake is an **event data store** — a managed, queryable log
database for CloudTrail events:

```
Traditional trail → S3 files → Athena query (setup required)
CloudTrail Lake   → managed store → SQL queries directly (no setup)

Retention: 7 years (default configurable)
Query: SQL via CloudTrail console or API
Federated query: query across multiple accounts/organizations

Use cases:
  "List all IAM policy changes in the last 90 days"
  "Find all S3 DeleteObject calls by a specific role in 2025"
  "Identify all root account logins in the entire organization"
  "Compliance report: all access to production resources"

SQL example:
  SELECT eventName, userIdentity.arn, eventTime, awsRegion
  FROM my_event_data_store
  WHERE eventName = 'DeleteBucket'
    AND eventTime > '2026-01-01'
  ORDER BY eventTime DESC
  LIMIT 100
```

---

## 6. CloudTrail Integrations

### CloudTrail + CloudWatch Alarms (Critical Pattern) ⭐

Create metric filters on the CloudTrail log group → create alarms:

```
Essential security alarms to configure:

1. Root account usage
   Filter: { $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS }
   Alarm:  Count >= 1 → SNS → immediate PagerDuty alert

2. Unauthorized API calls
   Filter: { ($.errorCode = "AccessDenied") || ($.errorCode = "UnauthorizedAccess") }
   Alarm:  Count >= 5 in 5 minutes

3. Console login without MFA
   Filter: { $.eventName = "ConsoleLogin" && $.additionalEventData.MFAUsed != "Yes" }
   Alarm:  Count >= 1

4. IAM policy changes
   Filter: { ($.eventName = "DeleteGroupPolicy") || ($.eventName = "PutUserPolicy") ||
             ($.eventName = "AttachRolePolicy") || ($.eventName = "CreatePolicy") }
   Alarm:  Count >= 1

5. Security group changes
   Filter: { ($.eventName = "AuthorizeSecurityGroupIngress") ||
             ($.eventName = "RevokeSecurityGroupIngress") }
   Alarm:  Count >= 1

6. S3 bucket policy changes
   Filter: { ($.eventName = "PutBucketPolicy") || ($.eventName = "DeleteBucketPolicy") }
   Alarm:  Count >= 1
```

### CloudTrail + EventBridge

```
Every CloudTrail event can trigger an EventBridge rule:
  EventBridge rule: eventSource = iam.amazonaws.com AND eventName = CreateUser
  Target: Lambda → audit new IAM user creation → check against approved list
          → if unapproved → delete user + send alert

  EventBridge rule: eventName = StopInstances AND awsRegion = us-east-1
  Target: SNS → alert ops team

Benefit over CW metric filters:
  More expressive filtering (exact field matching)
  Faster (near-real-time, ~15 seconds)
  No metric filter setup needed
```

### CloudTrail + Athena (Large Scale Analysis)

```
S3 trail logs → Athena table (create table from CTrail format)
→ SQL queries on billions of log records

Use case: security forensics, compliance reporting across years of logs
Cost: $5/TB scanned
Optimization: partition by year/month/day → drastically reduce scanned data
```

---

## 7. CloudTrail vs CloudWatch — Distinct Purposes ⭐

| | CloudWatch | CloudTrail |
|--|-----------|-----------|
| **What** | Performance metrics + application logs | API call audit records |
| **Why** | Monitor health, alert on issues | Security, compliance, governance |
| **Answers** | "Is my app healthy right now?" | "Who changed what and when?" |
| **Logs** | Application output, system metrics | API call records (who/what/when/where) |
| **Default retention** | Forever (unless you set expiry) | 90 days (trail needed for more) |
| **Query** | Logs Insights SQL-like language | CloudTrail Lake SQL / Athena |
| **Alarms** | Yes — metric thresholds | No alarms natively (via CW integration) |
| **Triggers** | Yes — alarm actions | Yes — via EventBridge |
| **Cost driver** | Log ingestion ($0.50/GB) | Data events charged; management events free |

---

## 8. Key Security Facts ⭐

```
1. CloudTrail is enabled by default — 90-day event history, free, no setup

2. For compliance/security:
   → Create a multi-region trail → S3 with MFA Delete enabled
   → Enable log file validation (SHA-256 integrity check)
   → Restrict S3 bucket policy (no one can delete logs)
   → Enable CloudTrail Lake for queryable long-term storage

3. Root account actions are always logged regardless of trail config

4. Global service events (IAM, STS, CloudFront) are logged in us-east-1
   → Multi-region trail handles this automatically (includes global events)

5. CloudTrail logs are NOT real-time:
   → Delivered to S3: within ~15 minutes of API call
   → CloudWatch Logs: near-real-time (~5 minutes)
   → EventBridge: near-real-time (~15 seconds)

6. Who can see CloudTrail logs:
   → CloudTrail console: last 90 days, any IAM user with cloudtrail:LookupEvents
   → S3 trail files: only those with S3 read access
   → Protect with: S3 bucket policy, SCPs blocking cloudtrail:DeleteTrail

7. Organization trail: member accounts cannot disable or modify it [docs.aws.amazon](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-events-with-cloudtrail.html)
   → Central security team always has complete audit record
```

---

## 9. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| CloudTrail is not enabled by default | CloudTrail **is enabled** by default — 90-day event history visible in console |
| Default CloudTrail logs data events | Data events (S3 GetObject, Lambda Invoke) **must be explicitly enabled** — not default |
| CloudTrail provides real-time monitoring | CloudTrail logs arrive in S3 with ~15-minute delay — use **EventBridge for near-real-time** |
| One trail is enough | For organizations: create **organization trail** — single trail covers all accounts |
| CloudTrail Insights is always on | Insights events **must be enabled** on trail/data store — not on by default |
| CloudTrail logs = CloudWatch logs | Completely different: CloudWatch = app/system logs; CloudTrail = API audit logs |
| CloudTrail covers all regions by default | Default 90-day history is global, but **trails are single-region by default** — enable multi-region |
| Deleting a trail destroys past log files | Trail logs are in **S3** — deleting trail stops NEW logging; old files remain in S3 |
| CloudTrail Lake replaces trails | Lake and trails are complementary — Lake is for querying; trails deliver to S3 |

---

## 10. Interview Questions Checklist

- [ ] Is CloudTrail enabled by default? What do you get for free?
- [ ] Four event types — which are logged by default?
- [ ] What are data events? Why are they off by default?
- [ ] What are Insights events? What do they detect?
- [ ] What is a trail vs the default 90-day history?
- [ ] Multi-region trail vs single-region — when to use multi-region?
- [ ] Organization trail — which account creates it? Can members disable it?
- [ ] Five fields in a CloudTrail event record and what each answers
- [ ] CloudTrail + CloudWatch: what metric filters should every account have?
- [ ] CloudTrail + EventBridge: why faster than CloudWatch metric filters?
- [ ] CloudTrail vs CloudWatch — explain the difference clearly
- [ ] How do you protect CloudTrail logs from being deleted?
- [ ] What is CloudTrail Lake? How does it differ from S3-based trails?
- [ ] Global service events (IAM, STS) — which region are they logged in?
