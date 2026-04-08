# AWS Billing & Cost Management

## 1. AWS Pricing Models ⭐

AWS charges on multiple dimensions depending on the service:

```
Three fundamental pricing dimensions:
  Compute:  pay per hour or per second (EC2, Lambda per invocation/ms)
  Storage:  pay per GB stored per month (S3, EBS, RDS)
  Transfer: pay per GB transferred OUT of AWS
            → Transfer IN: always FREE
            → Transfer between AZs in same region: small fee (~$0.01/GB each way)
            → Transfer OUT to internet: $0.09/GB (first 10TB/month, tiered lower)
            → Transfer between AWS services in SAME AZ: FREE
            → Transfer to CloudFront: FREE from AWS origin

Core pricing models:

1. Pay-as-you-go:
   Use a resource → pay for exactly what you use → no commitment
   Stop using → billing stops immediately
   Example: EC2 On-Demand → $0.096/hr while running → stop → $0.00

2. Save when you commit:
   Commit to 1 or 3 years → get 40–75% discount vs on-demand
   Options: Reserved Instances, Savings Plans, dedicated host reservations
   Best for: steady, predictable workloads

3. Pay less by using more (volume discounts):
   Higher usage → automatically lower per-unit price
   Example: S3 → first 50TB: $0.023/GB, next 450TB: $0.022/GB
   Consolidated billing: pool usage across accounts → hit tiers faster [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/consolidated-billing.html)

4. Free Tier:
   Three types: [scribd](https://www.scribd.com/document/829226986/AWS-Pricing-Calculator)
   12 Months Free: from AWS account creation date
     → 750 hrs/month EC2 t2.micro (Linux or Windows)
     → 5 GB S3 Standard storage
     → 750 hrs/month RDS db.t2.micro (MySQL/PostgreSQL/MariaDB)
   Always Free: no expiry ever
     → Lambda: 1 million requests/month + 400,000 GB-seconds/month
     → DynamoDB: 25 GB storage + 25 WCU + 25 RCU
     → CloudWatch: 10 custom metrics, 10 alarms, 5 GB log data ingestion
     → SNS: 1 million publishes/month
     → SQS: 1 million requests/month
     → SES: 62,000 outbound emails/month (from EC2)
   Short-term trials: 60–90 day free trials for specific services
     → Inspector, GuardDuty, Security Hub: 30-day trial
     → Lightsail: 3-month free bundle trial
```
---

```markdown
## Free Tier — CORRECTED (As of July 15, 2025) ⭐

AWS redesigned the Free Tier on July 15, 2025. The old 12-month model was
REPLACED with a Free Plan vs Paid Plan model for new accounts:

### Legacy Free Tier (accounts created BEFORE July 15, 2025)

  The original 12-month model still applies to existing accounts:
    12 Months Free (from account creation date):
      EC2:  750 hrs/month t2.micro (Linux or Windows) + 30 GB EBS
      RDS:  750 hrs/month db.t2.micro (MySQL, PostgreSQL, MariaDB, SQL Server Express)
      S3:   5 GB Standard storage
    Always Free: (same as new model — see below)
    Short-term trials: (same as new model — see below)


### New Free Tier (accounts created ON OR AFTER July 15, 2025)

  Two plan choices at sign-up — BOTH receive up to $200 in credits:
    $100 USD credits: given at sign-up automatically
    Up to $100 more:  earn by completing guided AWS activities (exploring services)
    Total:            up to $200 in credits

  ┌─────────────────┬──────────────────────────────┬──────────────────────────────┐
  │ Feature         │ Free Plan                    │ Paid Plan                    │
  ├─────────────────┼──────────────────────────────┼──────────────────────────────┤
  │ Duration        │ 6 months OR credits depleted │ No expiry                    │
  │ Credits         │ Up to $200 (same)            │ Up to $200 (same)            │
  │ AWS Services    │ Select services only         │ ALL 150+ services            │
  │ Beyond credits  │ Account closes (no charges)  │ Pay standard rates           │
  │ Account closure │ After 6 months/credits + 90d │ Never auto-closes            │
  │ Short-term trial│ ❌ NOT available              │ ✅ Available                 │
  │ Promo credits   │ ❌ Not eligible               │ ✅ Eligible                  │
  └─────────────────┴──────────────────────────────┴──────────────────────────────┘

  Free Plan expiry behavior:
    Credits used up OR 6 months reached → Free Plan ends
    90-day grace period → then account CLOSED + resources DELETED
    → Must upgrade to Paid Plan before grace period to keep resources

  EC2 on new Free Plan:
    Instance types covered: t3.micro, t3.small, t4g.micro, t4g.small,
                            c7i-flex.large, m7i-flex.large (using credits)
    (No longer a fixed "750 hr/month" limit — usage draws from $200 credit pool)

  RDS on new Free Plan:
    db.t3.micro and db.t4g.micro
    Engines: MySQL, PostgreSQL, MariaDB, SQL Server (Express Edition only)
    Up to 6 months on Free Plan (credit-based, not fixed hour limit)

### Always Free — unchanged, applies to ALL accounts forever

  These limits apply indefinitely — no expiry, no credit required:
    Lambda:      1,000,000 requests/month + 400,000 GB-seconds/month
    DynamoDB:    25 GB storage + 25 WCU + 25 RCU
    S3:          5 GB Standard storage
    CloudFront:  1 TB data transfer out + 10 million HTTP/S requests/month
    SNS:         1,000,000 publishes/month
    SQS:         1,000,000 requests/month
    CloudWatch:  10 custom metrics, 10 alarms, 5 GB log data ingestion
    SES:         3,000 message charges/month
    Aurora DSQL: 100K DPU + 1 GiB storage/month
    IAM:         Always free (no limits)
    VPC:         Always free (no per-resource charge for VPC itself)
    30+ more services with permanent monthly limits

### Short-term Trials — Paid Plan accounts only

  Available only on Paid Plan (not Free Plan):
    GuardDuty:     30-day free trial
    Inspector:     30-day free trial
    Security Hub:  30-day free trial
    Macie:         30-day free trial
    Other security/observability services: see individual service pages

### Key Exam Points ⭐

  Old 12-month free model: applies ONLY to accounts created before July 15, 2025
  New model: Free Plan (6 months / $200 credits) OR Paid Plan ($200 credits, no expiry)
  Short-term trials: ONLY available on Paid Plan — not Free Plan
  Always Free limits: identical across both old and new accounts — permanent
  EC2 free tier: now credit-based (t3/t4g families) vs old fixed 750 hr/month t2.micro
  RDS free tier: db.t3.micro / db.t4g.micro — db.t2.micro was the legacy tier
  Free Plan account: auto-CLOSES after 6 months + 90-day grace if not upgraded
```

**Summary of what changed vs your original notes:**

| Item | Old (pre-July 15, 2025) | New (post-July 15, 2025) |
|------|------------------------|--------------------------|
| Duration | 12 months | 6 months (Free Plan) |
| Model | Usage-hours based | $200 credit-based |
| EC2 free | 750 hrs/month t2.micro | t3/t4g families, credit-based  [cloudwithalon](https://cloudwithalon.com/writing/aws-free-tier-2025-whats-free-and-for-how-long/) |
| RDS free | db.t2.micro | db.t3.micro / db.t4g.micro  [aws.amazon](https://aws.amazon.com/rds/free/) |
| Short-term trials | Available to all | Paid Plan only  [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans.html) |
| Account on expiry | Rolls to paid (no closure) | Closes after 90-day grace  [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-plans.html) |
| Always Free | Unchanged | Unchanged — same limits  [dev](https://dev.to/aws-builders/whats-new-in-aws-free-tier-2025-2ba5) |

---

## 2. Compute Savings Options ⭐

### On-Demand Instances

```
No commitment → pay per second (Linux) or per hour (Windows)
Most expensive per unit → maximum flexibility
Best for:
  Short-term, spiky, unpredictable workloads
  Dev/test instances that run irregular hours
  Applications being tested for the first time
```

### Reserved Instances (RIs)

```
Commit to a specific instance type in a specific region for 1 or 3 years
Savings: up to 72% vs On-Demand

RI Types:
  Standard RI:
    Deepest discount (72% 3-year all-upfront)
    Instance type CANNOT be changed
    CAN sell on RI Marketplace if no longer needed
    CAN change: AZ, instance size (within family), networking type

  Convertible RI:
    Smaller discount (~54% 3-year all-upfront)
    CAN change: instance family, OS, tenancy, payment option
    CANNOT sell on RI Marketplace
    Best for: workloads that may need to change instance type

Payment options:
  All Upfront:    pay everything now → maximum discount
  Partial Upfront: pay some now + reduced hourly rate
  No Upfront:     no payment now → pay reduced hourly rate → smallest discount

Scope:
  Regional RI: applies to any AZ in region → AZ flexibility + instance size flexibility
  Zonal RI:    applies to specific AZ only → reserves capacity in that AZ (capacity reservation)

RI sharing in Organizations:
  Reserved Instances purchased in any account → discount shared across ALL org accounts
  → Buy RI in management account → applies to usage in member accounts automatically [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/consolidated-billing.html)
```

### Savings Plans

```
Commitment: spend a minimum $/hour for 1 or 3 years → get discount on usage
More flexible than RIs — commitment is to a spend level, not a specific instance

Three types:

1. Compute Savings Plans (most flexible):
   Applies to: EC2 (any family, size, region, OS, tenancy) + Fargate + Lambda
   Discount: up to 66% vs On-Demand
   Automatically applies to: any eligible compute usage in any region
   Best for: organizations whose workload type may change

2. EC2 Instance Savings Plans (deepest discount):
   Applies to: specific instance family in specific region (e.g., m5 in us-east-1)
   Discount: up to 72% (same as Standard RI)
   Flexibility within family: any size (m5.large or m5.xlarge), any AZ, any OS
   Least flexible — committed to one instance family per region

3. SageMaker Savings Plans:
   Applies to: SageMaker ML instance usage only
   Discount: up to 64%

Savings Plans vs Reserved Instances: [teleglobals](https://teleglobals.com/blog/complete-aws-cost-optimization-guide)
  Savings Plans: flexible (any size, region, OS for Compute type) → easier to manage
  RIs: rigid (specific instance) → slightly deeper discount for EC2 Instance type
  Recommendation: prefer Savings Plans for most new commitments

Purchase: AWS Cost Explorer → Savings Plans → Recommendations → buy directly
```

### Spot Instances

```
Use AWS spare EC2 capacity → up to 90% discount vs On-Demand
Interruption risk: AWS can reclaim with 2-minute warning

Best practices:
  Design stateless, fault-tolerant workloads
  Use Spot instance diversification (multiple instance types + AZs)
  Combine with On-Demand: On-Demand for baseline + Spot for burst
  Use EC2 Auto Scaling with mixed instances policy

Use cases:
  Big data processing (EMR)
  CI/CD test runners (Jenkins agents)
  Batch jobs, rendering, genome sequencing
  Stateless web servers (behind ALB + ASG)

NOT for:
  Databases → state not tolerant of interruptions
  Long-running critical jobs → risk of mid-job interruption
  WorkSpaces, RDS → not supported with Spot
```

---

## 3. AWS Organizations & Consolidated Billing ⭐

### What is AWS Organizations?

```
Hierarchical structure for managing multiple AWS accounts:

  Root
  ├── Management Account (formerly "master") — pays all bills, creates organization
  │   └── Cannot be restricted by SCPs
  ├── Organizational Unit (OU): Production
  │   ├── Account: prod-core
  │   ├── Account: prod-data
  │   └── OU: Workloads
  │       └── Account: prod-app-1
  └── OU: Sandbox
      ├── Account: dev-ibtisam
      └── Account: dev-team

Benefits of Organizations:
  Centralized account management
  Consolidated billing → single bill for all accounts [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/consolidated-billing.html)
  Volume discount pooling across accounts
  RI and Savings Plans sharing automatically across all accounts [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/consolidated-billing.html)
  Service Control Policies (SCPs) for guardrails
  AWS CloudTrail org trail → logs all accounts
  AWS Config aggregation → compliance across all accounts
  Automatic account creation via Organizations API
```

### Consolidated Billing Benefits

```
Single bill: one invoice for all member accounts [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/consolidated-billing.html)

Volume discount pooling: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-set-up-aws-organizations-consolidated-billing/view)
  WITHOUT consolidated billing:
    Account A: 20TB S3 → $0.023/GB (first 50TB tier)
    Account B: 20TB S3 → $0.023/GB (first 50TB tier)
    Account C: 20TB S3 → $0.023/GB (first 50TB tier)
    Total paid: 60TB × $0.023

  WITH consolidated billing:
    Combined usage: 60TB total
    First 50TB: $0.023/GB
    Next 10TB: $0.022/GB  ← lower tier reached automatically
    Savings: $0.001/GB × 10,000 GB = $10/month without any effort

RI sharing: [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/consolidated-billing.html)
  Account A buys 10 m5.xlarge Standard RIs
  Account B uses m5.xlarge instances but bought no RIs
  → RI discount from Account A automatically applies to Account B's usage
  → Management account can DISABLE this sharing if needed

Free tier:
  Each account in organization gets its OWN free tier
  → 20 accounts → 20 × 750 hrs EC2 free tier
  → Useful for dev/test sandboxes

No extra cost: consolidated billing feature is FREE [docs.aws.amazon](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/consolidated-billing.html)
```

### Service Control Policies (SCPs) ⭐

```
SCPs are GUARDRAILS — they restrict what IAM policies in member accounts
can grant. They do NOT grant permissions themselves.

Key rules:
  SCPs apply to: all users + roles in member accounts (including root user of member)
  SCPs do NOT apply to: management account (fully exempt from SCPs)
  SCPs + IAM policy: BOTH must allow → effective permission = intersection

Example SCP use cases:
  1. Prevent disabling CloudTrail (compliance):
     {
       "Effect": "Deny",
       "Action": ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail"],
       "Resource": "*"
     }
     → Even if member account admin user tries → DENIED

  2. Restrict to specific regions (data residency):
     {
       "Effect": "Deny",
       "Action": "*",
       "Resource": "*",
       "Condition": {
         "StringNotEquals": {
           "aws:RequestedRegion": ["us-east-1", "eu-west-1"]
         }
       }
     }
     → No resources can be created outside allowed regions

  3. Require encryption (security baseline):
     Deny s3:CreateBucket unless aws:RequestObjectEncryption condition met

  4. Prevent leaving the organization:
     Deny organizations:LeaveOrganization
     → Member accounts cannot remove themselves from org

SCP inheritance:
  Applied at OU level → all accounts in OU + child OUs inherit
  Child OU can ONLY be further restricted — never MORE permissive than parent
  Root SCP: applies to everything in organization

SCP attach targets:
  Root (all OUs and accounts), OU (and children), individual account
```

---

## 4. AWS Cost Explorer ⭐

```
Free visualization and analysis tool for your AWS costs and usage:

What it provides: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html)
  View historical spend: up to 13 months back
  Current month spend: data available within 24 hours (updated daily)
  Forecasting: next 12–18 months based on historical patterns
  RI/Savings Plans recommendations: "buy these RIs to save $X/month"
  Granularity: daily, monthly, hourly (hourly: extra $0.01/day/resource)
  Filter/group by: service, account, region, AZ, tag, instance type, usage type

Enable: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-enable.html)
  Management console → Billing → Cost Explorer → Enable
  Cannot enable via API → must be done in console
  After enabling: historical data (13 months) loaded in ~24 hours
  Cost Anomaly Detection: AUTO-CONFIGURED when Cost Explorer enabled [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-enable.html)

Key reports:
  Cost & Usage report:  spend breakdown by service, time period
  RI utilization report: are you using your Reserved Instances? (%)
  RI coverage report:   what % of your usage is covered by RIs?
  Savings Plans utilization: are your Savings Plans being fully used?

Cost allocation tags:
  Tag your resources: Environment=prod, Team=engineering, Project=silverstack
  Activate tags in Billing → Cost Allocation Tags
  → Cost Explorer filters by these tags → see spend per project/team/env
  → Tag before resources exist (retroactive tagging not applied to past bills)
```

---

## 5. AWS Budgets ⭐

```
Set spend limits and receive alerts before/after threshold breached:

Budget types: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
  Cost budget:          alert when $ spend exceeds threshold
  Usage budget:         alert when usage (GB, hours) exceeds threshold
  RI utilization budget: alert when RI utilization drops BELOW threshold
                         (you're not using RIs you paid for)
  RI coverage budget:   alert when RI coverage drops BELOW threshold
                         (more On-Demand usage than you intended)
  Savings Plans utilization: alert when SP utilization drops below threshold
  Savings Plans coverage:    alert when SP coverage drops below threshold

Alert triggers: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
  Actual: when actual spend crosses threshold (after the fact)
  Forecasted: when projected spend will cross threshold (proactive)

Notification channels:
  Email: up to 5 email recipients per alert
  SNS topic: trigger Lambda, PagerDuty, Slack via SNS → Lambda → Slack webhook

Budget Actions: ⭐
  Automatically take action when budget threshold hit:
    Apply IAM policy: add deny-all policy to role → stops spending
    Apply SCP: restrict org member account from creating resources
    Stop EC2/RDS instances: directly stop instances to cut costs
  Example:
    Dev sandbox account spending > $200/month
    → Budget Action: apply SCP denying ec2:RunInstances
    → No more EC2 instances can be launched until month reset

Pricing:
  First 2 budgets: FREE
  After 2 budgets: $0.02/budget/day (~$0.62/budget/month)
  Budget Actions: $0.10 per action/day

Best practices:
  Set forecast alert at 80% of budget → early warning
  Set actual alert at 100% → immediate notification when exceeded
  Set actual alert at 120% → catch runaway costs
  Create per-account budgets in Organizations
  Create per-tag budgets (by project, team, environment)
```

---

## 6. Cost Anomaly Detection ⭐

```
ML-powered service that detects unexpected cost spikes automatically:

How it works: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/getting-started-ad.html)
  Builds baseline from historical spend patterns per service
  Detects spend that deviates significantly from expected
  Alert threshold (default): > $100 AND > 40% above expected spend [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-enable.html)
  Detection latency: up to 24 hours after usage [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/management-limits.html)
  Historical data needed: minimum 10 days before detection starts [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/management-limits.html)

Auto-configured when Cost Explorer enabled: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-enable.html)
  AWS creates: one AWS Services monitor + daily summary alert subscription

Monitor types: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/getting-started-ad.html)
  AWS Managed monitors (auto):
    AWS Services: evaluates ALL services automatically → new services auto-included
    Linked Accounts: tracks ALL member accounts → new accounts auto-included
    Cost Categories: tracks all values in a cost category automatically
    Limit: 2 AWS managed monitors per management account, 1 per member [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/management-limits.html)

  Customer Managed monitors (manual): [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/getting-started-ad.html)
    Track specific services, up to 10 specific accounts, one cost category value
    Set different alert thresholds per monitor
    Use: high-priority workloads needing unique thresholds

Subscriptions (alerts):
  Individual: immediate alert per anomaly
  Daily summary: one daily digest of all anomalies
  Weekly summary: one weekly digest
  Channels: email (up to 10 recipients/subscription) or SNS topic [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/management-limits.html)

Unsupported services (no anomaly detection): [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/management-limits.html)
  AWS Marketplace, AWS Support, WorkSpaces, Route 53,
  ACM, AWS Shield, Cost Explorer itself, Budgets

Accuracy feedback:
  After receiving alert: mark anomaly as "Confirmed" or "Not an anomaly"
  → ML model improves over time based on your feedback
```

---

## 7. AWS Pricing Calculator

```
Pre-deployment cost estimation tool — estimate monthly AWS bill BEFORE deploying:

URL: calculator.aws [calculator](https://calculator.aws)

Features:
  Add AWS services → configure specs → see estimated monthly cost
  Group by: project, team, environment
  Export: CSV, JSON, PDF
  Share: generate shareable link for stakeholder review
  Compare: side-by-side scenarios (current vs proposed architecture)

What you can estimate:
  EC2: instance type, OS, region, usage hours, RI/Savings Plans discounts
  RDS: instance type, storage, multi-AZ, backup storage
  S3: storage class, request counts, data transfer
  CloudFront: data transfer, HTTPS requests by region
  Any AWS service with public pricing

NOT a billing tool:
  Pricing Calculator: BEFORE deployment → estimate future cost
  Cost Explorer:      AFTER deployment → analyze actual cost
  AWS Budgets:        WHILE running → alert on actual/forecast vs limit

Pricing Calculator is FREE to use (no AWS account needed) [calculator](https://calculator.aws)
```

---

## 8. AWS Cost and Usage Report (CUR) ⭐

```
Most detailed billing data available — raw data exported to S3:

Content:
  Line item per resource per hour (or day)
  Every AWS charge: compute, storage, data transfer, support, taxes, credits
  Tags on each resource (if cost allocation tags activated)
  RI/Savings Plans charges and credits
  Blended vs unblended rates
  Resource-level detail (specific EC2 instance ID, specific S3 bucket)

Setup:
  Billing → Cost and Usage Reports → Create report
  S3 bucket: choose destination
  Granularity: hourly, daily, or monthly
  Format: CSV (gzip) or Parquet
  Integration: AWS Athena (auto-creates Glue tables) or Redshift or QuickSight

Use cases:
  Finance team SQL queries: "show me total EC2 cost per team tag last month"
  Custom dashboards in QuickSight
  Chargeback/showback: bill each team their share of AWS cost
  Identify resource-level waste (EC2 instances with zero CPU last 30 days)

CUR vs Cost Explorer:
  CUR: raw data export → for custom analysis → Athena/Redshift queries
  Cost Explorer: managed UI → for quick analysis → no custom queries
  Both: use together — Cost Explorer for quick checks, CUR for deep dives
```

---

## 9. Trusted Advisor ⭐

```
AWS's automated best-practice recommendation engine:

Five check categories:
  1. Cost Optimization:
     - Idle EC2 instances (< 10% CPU for 14 days) → stop or downsize
     - Underutilized EBS volumes → 85%+ unattached for 30 days → delete
     - Unassociated Elastic IPs → $0.005/hr if not attached → release
     - Unused Reserved Instances → RIs with < 80% utilization → sell or modify
     - S3 buckets without lifecycle policies → move to cheaper tiers

  2. Performance:
     - EC2 instances overutilized → upgrade instance type
     - CloudFront distributions without compression
     - EBS throughput/IOPS limits → upgrade volume type

  3. Security:
     - S3 buckets with public access enabled → investigate
     - Security groups open to 0.0.0.0/0 on port 22/3389 → restrict
     - MFA not enabled on root account → enable now
     - IAM access keys older than 90 days → rotate
     - No CloudTrail enabled → enable immediately

  4. Fault Tolerance:
     - EC2 instances without Multi-AZ backup
     - EBS volumes without recent snapshots
     - RDS without Multi-AZ enabled
     - Auto Scaling groups with < 2 AZs

  5. Service Limits (Quotas):
     - Resources approaching service limits → request increase proactively

Access tiers:
  Basic/Developer support: 7 core checks only (security + service limits)
  Business support:        ALL checks + automated refresh + AWS Support API
  Enterprise support:      ALL checks + priority support + TAM
```

---

## 10. AWS Support Plans ⭐

| Feature | Basic | Developer | Business | Enterprise On-Ramp | Enterprise |
|---------|-------|-----------|---------|-------------------|-----------|
| **Price** | Free | $29/month | $100/month or 3% | $5,500/month or 10% | $15,000/month or 3–10% |
| **Technical support** | Docs/forums | Business hours, 1 person | 24/7, unlimited | 24/7, unlimited | 24/7, unlimited |
| **Response: General guidance** | — | 24 business hours | 24 hours | 24 hours | 24 hours |
| **Response: System impaired** | — | 12 business hours | 12 hours | 12 hours | 12 hours |
| **Response: Prod system impaired** | — | — | 4 hours | 4 hours | 4 hours |
| **Response: Prod system DOWN** | — | — | 1 hour | 1 hour | 1 hour |
| **Response: Business-critical DOWN** | — | — | — | 30 minutes | 15 minutes |
| **Trusted Advisor** | 7 checks | 7 checks | All checks | All checks | All checks |
| **TAM (Technical Account Manager)** | ❌ | ❌ | ❌ | Pool of TAMs | Dedicated TAM |
| **Concierge support** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Infrastructure Event Management** | ❌ | ❌ | Extra fee | 1/year included | Included |

```
Notes:
  Business/Enterprise pricing: max(flat fee, % of monthly AWS bill)
  Developer: ONE primary contact (not whole team)
  Business: UNLIMITED contacts
  Enterprise: Dedicated TAM proactively monitors your environment
  Infrastructure Event Management: pre-event planning for launch/migrations
```

---

## 11. AWS Cost Optimization Toolkit

```
Right Sizing:
  Compute Optimizer:
    Analyzes EC2, Lambda, EBS, ECS, ASG usage (CloudWatch metrics)
    Recommends: "resize m5.2xlarge → m5.large → save $150/month"
    Savings: typically 20–40% on compute
    Free service
  Cost Explorer Resource Optimization: identifies idle + underutilized EC2

Spot Instance Advisor:
  Shows interruption frequency per instance type per region
  Choose low-interruption-frequency types for better reliability

S3 Storage Lens:
  Org-wide S3 usage analytics
  Identifies: unused buckets, objects not accessed for 90+ days
  Recommendations: move to S3-IA, Glacier → reduce storage cost

S3 Intelligent-Tiering:
  Auto-moves objects between tiers based on access patterns
  No retrieval fees
  Cost: $0.0025/1,000 objects/month monitoring fee

Reserved Instance Marketplace:
  Sell unwanted Standard RIs to other AWS customers
  Convertible RIs cannot be sold
  Typical: recover 50–90% of remaining RI value

Cost Categories:
  Group charges by custom rules → "Engineering team", "Production", "Shared Services"
  Rules: by account, service, tag, charge type
  Use in Cost Explorer, Budgets, CUR for chargeback reporting
```

---

## 12. Billing Alarm (CloudWatch)

```
Simple billing alert using CloudWatch metric (older method → use Budgets instead):

Requirements:
  Must be set in us-east-1 (billing metrics only available in us-east-1)
  Must enable billing alerts in account preferences FIRST:
    Billing preferences → Receive Billing Alerts → Save

Create:
  CloudWatch → Alarms → Billing → EstimatedCharges
  Threshold: > $50 USD
  Alarm action: SNS topic → email notification

AWS Budgets vs CloudWatch Billing Alarm:
  Budgets: richer features (RI/SP coverage, forecasted, actions) → PREFERRED
  CloudWatch alarm: simpler, older approach, still works
  Both: covered in exam — know both exist and their differences
```

---

## 13. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| SCPs grant permissions to member accounts | SCPs are **guardrails only** — they restrict what IAM can grant; they do NOT grant access |
| SCPs apply to the management account | SCPs **never apply to the management account** — fully exempt |
| Consolidated billing shares RI discounts automatically | RI sharing is **on by default** — but management account can **disable** it per account |
| Cost Explorer can be enabled via API | Cost Explorer must be **enabled via the console** — no API option |
| Cost Anomaly Detection needs manual setup | Enabling Cost Explorer **auto-configures** Cost Anomaly Detection with default monitor + alert |
| Anomaly Detection works on all services | Route 53, ACM, WorkSpaces, Marketplace **not supported** by Anomaly Detection |
| AWS Pricing Calculator uses your actual bill data | Pricing Calculator is for **pre-deployment estimation** — it has no access to your account |
| First 2 Budgets are paid | First **2 Budgets are free** — $0.02/day per budget beyond 2 |
| Reserved Instances must be used in the purchasing account | RIs are **shared across all accounts** in the same AWS Organization automatically |
| Convertible RIs can be sold on RI Marketplace | Only **Standard RIs** can be listed on the RI Marketplace — Convertible RIs cannot |

---

## 14. Interview Questions Checklist

- [ ] Three core AWS pricing models? (pay-as-you-go, commit to save, volume discounts)
- [ ] Three types of Free Tier? (12-month, always-free, short trials)
- [ ] Data transfer pricing rules — what's free, what costs? (IN free, same-AZ free, OUT charged)
- [ ] Standard RI vs Convertible RI — key differences? (sellable vs changeable)
- [ ] Regional RI vs Zonal RI — difference? (flexibility vs capacity reservation)
- [ ] Compute Savings Plans vs EC2 Instance Savings Plans — scope?
- [ ] What is consolidated billing? Key benefits? (single bill, volume pooling, RI sharing)
- [ ] SCPs — do they grant permissions? Who are they exempt for? (management account)
- [ ] What two things must allow access under SCPs + IAM? (intersection — both must allow)
- [ ] When does Cost Explorer data become available after enabling? (24 hours, 13 months history)
- [ ] What is auto-created when you enable Cost Explorer? (Anomaly Detection monitor + alert)
- [ ] Anomaly Detection default alert threshold? (> $100 AND > 40% above expected)
- [ ] Minimum history needed for Anomaly Detection? (10 days)
- [ ] Budget types — what is RI utilization budget? (alert when you're NOT using RIs you paid for)
- [ ] Budget Actions — three types of actions? (IAM policy, SCP, stop EC2/RDS)
- [ ] Cost Explorer vs Pricing Calculator vs Budgets vs CUR — one-line purpose of each?
- [ ] Trusted Advisor — five categories? Which checks require Business support?
- [ ] Support plan with Dedicated TAM? (Enterprise) vs pool TAM? (Enterprise On-Ramp)
- [ ] Business-critical system down SLA? (15 min Enterprise, 30 min Enterprise On-Ramp)
- [ ] How do you enable billing alarms in CloudWatch? (must enable in billing preferences + us-east-1 region)
