# AWS Config

## 1. What is AWS Config?

AWS Config is a **resource inventory, configuration history, and compliance
evaluation service** — it continuously records the configuration state of
your AWS resources, tracks changes over time, and evaluates them against
rules you define.

```
Without AWS Config:
  EC2 security group changed → opens port 22 to 0.0.0.0/0 → you find out 3 weeks later
  Compliance audit: "show me config of that S3 bucket on March 1" → impossible
  "Who changed the VPC route table last Tuesday?" → no record

With AWS Config:
  Every configuration change recorded with: what changed, who changed it, when
  "Show me the config of bucket X at any point in the last 7 years" → instant
  Config rule evaluates S3 public access → marks NONCOMPLIANT immediately
  SNS alert sent → engineer notified within minutes of violation
  Auto-remediation: SSM Automation runs → fixes the issue → COMPLIANT again
```

---

## 2. Core Concepts ⭐

```
Configuration Item (CI):
  A snapshot of a resource's configuration at a point in time
  Includes: resource type, ID, ARN, region, creation time, configuration details,
            relationships to other resources, tags, CloudTrail event ID that caused change
  Stored in: S3 bucket (JSON format) — your Config delivery bucket

Configuration History:
  All CIs for a resource over time → "configuration timeline"
  View: Config console → resource → Configuration Timeline
  Shows: each change with before/after state

Configuration Snapshot:
  Point-in-time dump of ALL resources' configuration in region
  Delivered to S3 on demand or on schedule

Resource Relationships:
  Config tracks relationships between resources
  Example: EC2 instance → linked to VPC, subnet, SGs, EBS, IAM role
  → If VPC changes, you see which EC2 instances are affected

Supported resources: 300+ AWS resource types
  EC2, RDS, S3, IAM, VPC, Lambda, ECS, EKS, CloudFormation, etc.
```

---

## 3. Config Rules ⭐

```
Rules evaluate whether resources are COMPLIANT or NONCOMPLIANT:

Managed Rules (AWS pre-built, 300+ available):
  s3-bucket-public-read-prohibited      → S3 buckets must have public read blocked
  encrypted-volumes                     → EBS volumes must be encrypted
  iam-user-mfa-enabled                  → all IAM users must have MFA
  restricted-ssh                        → no SG allows 0.0.0.0/0 on port 22
  rds-instance-public-access-check      → RDS must not be publicly accessible
  cloudtrail-enabled                    → CloudTrail must be active
  root-account-mfa-enabled              → root must have MFA
  vpc-flow-logs-enabled                 → VPC flow logs must be enabled
  s3-bucket-ssl-requests-only           → S3 must deny HTTP requests

Custom Rules (Lambda-based):
  You write Lambda function → evaluates resource config → returns COMPLIANT/NONCOMPLIANT
  Trigger: config change detected OR periodic (every 1/3/6/12/24 hours)
  Use: organization-specific compliance checks not covered by managed rules
  Example: check that all EC2 instances have a specific tag + value pattern

Rule trigger types:
  Configuration change:   evaluates when resource is created/modified/deleted
  Periodic:               evaluates on a schedule (regardless of changes)
  Hybrid:                 both triggers

Evaluation scope:
  Resource type: rule applies to specific resource types (e.g., AWS::EC2::SecurityGroup)
  Tag-based: rule applies to resources with specific tags
  Account-wide: rule applies to all resources (for global checks)
```

---

## 4. Conformance Packs ⭐

```
A conformance pack = a collection of Config rules + remediation actions
bundled as a single deployable YAML template: [docs.aws.amazon](https://docs.aws.amazon.com/config/latest/developerguide/conformance-packs.html)

Benefits:
  Deploy 50 Config rules as one action (not one by one)
  Apply same compliance standard across entire org
  Pre-built templates for common compliance frameworks:
    PCI DSS, HIPAA, CIS AWS Foundations Benchmark,
    NIST 800-53, FedRAMP, SOC 2, AWS Security Best Practices

Deployment: [docs.aws.amazon](https://docs.aws.amazon.com/config/latest/developerguide/conformance-packs.html)
  Single account + region
  OR across entire AWS Organization → all accounts + all regions
  Uses CloudFormation StackSets under the hood for org-wide deployment

Structure (YAML template):
  Parameters: ...
  Rules:
    - ruleName: S3BucketPublicAccessProhibited
      identifier: S3_BUCKET_PUBLIC_READ_PROHIBITED
    - ruleName: EncryptedEBSVolumes
      identifier: ENCRYPTED_VOLUMES
    - ruleName: CustomSecurityGroupCheck
      owner: CUSTOM_LAMBDA
      sourceIdentifier: arn:aws:lambda:...
  Remediation:
    - targetType: SSM_DOCUMENT
      targetId: AWS-DisablePublicAccessForSecurityGroup
      retryAttemptSeconds: 60
      maximumAutomaticAttempts: 5

Remediation via SSM Automation: [aws.amazon](https://aws.amazon.com/blogs/mt/manage-custom-aws-config-rules-with-remediation-using-conformance-packs/)
  Non-compliant resource detected →
  AWS Config triggers SSM Automation document →
  SSM Automation (or Lambda) fixes the resource →
  Config re-evaluates → COMPLIANT
  Example: SG with 0.0.0.0/0 on 22 → SSM Automation removes the rule automatically
```

---

## 5. Remediation ⭐

```
Two remediation modes:
  Manual: Config marks NONCOMPLIANT → you manually fix
  Automatic: Config triggers SSM Automation or Lambda → auto-fixes

Automatic remediation configuration:
  Config rule → Actions → Manage Remediation
  Target: SSM Automation document (e.g., AWS-DisablePublicAccessForSecurityGroup)
  Parameters: resource ID passed from Config evaluation result
  Retry: up to 25 attempts, configurable interval
  Execution role: IAM role for SSM Automation to make API calls

Example: automatic SG remediation: [aws.amazon](https://aws.amazon.com/blogs/mt/manage-custom-aws-config-rules-with-remediation-using-conformance-packs/)
  Config rule: restricted-ssh (no SG open to 0.0.0.0/0 on port 22)
  Non-compliant: SG sg-abc123 opens 22 to 0.0.0.0/0
  Trigger: SSM Automation document AWS-DisablePublicAccessForSecurityGroup
  Result: inbound rule removed → SG marked COMPLIANT automatically
  Notification: SNS → email/Slack alert about the auto-remediation

Custom Lambda remediation: [aws.amazon](https://aws.amazon.com/blogs/mt/manage-custom-aws-config-rules-with-remediation-using-conformance-packs/)
  Config rule detects non-compliance →
  SSM Automation triggers Lambda function →
  Lambda makes API calls to fix resource →
  Result reported back → Config re-evaluates
  Use: complex remediations not covered by built-in SSM documents
```

---

## 6. Aggregators (Multi-Account / Multi-Region)

```
Config Aggregator: collect Config data from multiple accounts/regions
into a single account for centralized view:

Types:
  Individual account sources: specify specific account IDs + regions
  Organization source: automatically includes ALL accounts in org
    → new accounts auto-added as they join org

Aggregator account (typically Security/Audit account):
  Sees: all resources, all compliance data, all Config rules across all accounts
  Use: compliance dashboard, cross-account queries, security team view

Query with Advanced Queries (SQL-like):
  SELECT resourceId, resourceType, configuration.publiclyAccessible
  FROM aws_config_configuration_snapshot
  WHERE resourceType = 'AWS::RDS::DBInstance'
    AND configuration.publiclyAccessible = 'true'
  → Returns all public RDS instances across all accounts in seconds
```

---

## 7. Config vs CloudTrail

```
Common confusion — they are COMPLEMENTARY, not alternatives:

CloudTrail:
  Records: API CALLS (who did what action, when, from where)
  Question answered: "Who called DeleteSecurityGroup at 2 PM?"
  Data: API event logs (actor + action + timestamp)
  Retention: 90 days in CloudTrail console, unlimited in S3

AWS Config:
  Records: RESOURCE STATE (what the resource looks like, how it changed)
  Question answered: "What did security group sg-abc look like on March 1?"
  Data: configuration snapshots + diffs (resource properties)
  Retention: 7 years by default (configurable)

Together:
  CloudTrail: tells you WHAT API was called (iam:AttachRolePolicy)
  Config:     tells you WHAT CHANGED (role had X policies → now has X + Y)
  Use both: Config timeline shows change → click "CloudTrail event" → see who did it
```

---

## 8. Pricing

```
Config Rules:
  $0.001 per configuration item recorded per region
  $0.003 per Config rule evaluation per region
  Free: first 12 months, 1,000 recorded items + 20,000 rule evaluations (new accounts)

Conformance Packs:
  $0.0012 per resource per conformance pack evaluation
  First 30 days free for new conformance packs

No charge for:
  Config queries (Advanced Query)
  Configuration history delivery to S3
  Notifications delivered to SNS

Cost tip: enable only in regions you use → avoid paying for empty region scans
```

---

## 9. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Config prevents resource creation | Config only **records and evaluates** — it does NOT prevent actions (use SCPs for prevention) |
| Config and CloudTrail are alternatives | They are **complementary** — Config tracks state, CloudTrail tracks API calls |
| Custom rules require periodic trigger | Custom rules can trigger on **configuration change OR periodic** — or both |
| Conformance packs are only for single accounts | Conformance packs deploy across **entire Organization** via StackSets |
| Auto-remediation is immediate + unlimited retries | Remediation has **configurable retry limits** (up to 25 attempts) + interval |
| Config records only current state | Config maintains **full historical timeline** for every resource |

---

## 10. Interview Questions Checklist

- [ ] Config vs CloudTrail — what does each record?
- [ ] Managed rules vs custom rules — how are custom rules implemented? (Lambda)
- [ ] What is a conformance pack? How does org-wide deployment work?
- [ ] How does automatic remediation work? (Config → SSM Automation document)
- [ ] What is a Config Aggregator? What account should own it? (Security/Audit account)
