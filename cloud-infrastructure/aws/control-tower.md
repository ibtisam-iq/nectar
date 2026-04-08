# AWS Control Tower

## 1. What is AWS Control Tower?

AWS Control Tower is an **automated landing zone service** — it builds a
well-architected, multi-account AWS environment with pre-configured security
baselines, guardrails, and account vending on top of AWS Organizations,
so you don't have to assemble all those pieces manually.

```
Without Control Tower:
  Set up Organizations + SCPs manually
  Configure CloudTrail in every account manually
  Set up centralized logging account manually
  Set up security audit account manually
  Create account onboarding process manually
  Document all guardrails manually
  → Weeks of work, error-prone, inconsistent

With Control Tower:
  Click "Set up landing zone" → 30–60 minutes
  → Organizations created (if not exists)
  → Log archive account created + CloudTrail → centralized S3
  → Audit account created + cross-account roles
  → Guardrails applied to all OUs
  → Account Factory ready: create compliant new accounts in minutes
  → Dashboard: compliance status of all accounts in one view
```

---

## 2. Landing Zone ⭐

```
A landing zone = the entire baseline multi-account environment Control Tower creates:

Automatically created accounts:
  Management Account:    the root account you launch Control Tower from
  Log Archive Account:   receives CloudTrail logs + Config snapshots from ALL accounts
                         → centralized, tamper-resistant audit trail
  Audit Account:         cross-account read access to ALL member accounts
                         → security team / auditors can review without account access
                         → has pre-configured SNS topics for compliance alerts

Automatically configured:
  AWS Organizations: OU structure created
  AWS CloudTrail:    organization-level trail → logs all accounts → Log Archive S3
  AWS Config:        enabled in all accounts → resources tracked
  AWS SSO:           preconfigured with directory + permission sets
  Guardrails:        mandatory + strongly recommended applied to all enrolled OUs
  VPC:               optional baseline VPC configuration

Default OU structure: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-aws-control-tower-landing-zones/view)
  Root
  ├── Security OU → Log Archive account + Audit account
  └── Sandbox OU → initial member accounts

After setup: you create additional OUs and enroll accounts
```

---

## 3. Guardrails ⭐

```
Guardrails = pre-packaged governance rules for your landing zone

Two mechanism types:
  Preventive guardrails: implemented as SCPs → BLOCK actions before they happen
    Example: "Disallow changes to CloudTrail" → SCP denies cloudtrail:StopLogging
    Effect: action attempted → immediately denied

  Detective guardrails: implemented as AWS Config rules → DETECT non-compliant state
    Example: "Detect public S3 buckets" → Config rule checks s3:BucketPublicAccessEnabled
    Effect: bucket made public → Config marks NONCOMPLIANT → dashboard alerts

Three enforcement levels:
  Mandatory:              ALWAYS enabled, cannot be disabled
    Examples: detect changes to log archive account, detect SCP changes
  Strongly Recommended:   enabled by default, CAN be disabled
    Examples: detect public S3 buckets, detect unrestricted SSH
  Elective:               off by default, opt-in
    Examples: restrict specific instance types, require specific tags

Guardrails apply at OU level only — not individual accounts [globallogic](https://www.globallogic.com/ro/insights/blogs/deploying-a-landing-zone-with-aws-control-tower-part-2/)

Important behavior: [globallogic](https://www.globallogic.com/ro/insights/blogs/deploying-a-landing-zone-with-aws-control-tower-part-2/)
  OUs created THROUGH Control Tower console → "Registered" → guardrails apply
  OUs created via CLI or Organizations console → "Unregistered"
  → Must manually register OU in Control Tower to apply guardrails
```

---

## 4. Account Factory ⭐

```
Self-service account provisioning — create new, compliant AWS accounts
in minutes with standardized configuration:

Every Account Factory account gets automatically: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-set-up-aws-control-tower-account-factory-for-new-accounts/view)
  Enrollment in Control Tower governance
  Guardrails (preventive + detective) from landing zone
  Standard IAM roles and configurations
  VPC networking (if configured in Account Factory settings)
  SSO access for designated users
  CloudTrail logging → Log Archive account
  Config enabled + reporting to aggregator

Account Factory methods:
  Console: Control Tower → Account Factory → Enroll Account / Create Account
  Service Catalog: Account Factory product in portfolio
    → Developers/teams can self-request accounts via Service Catalog
  Account Factory for Terraform (AFT):
    Infrastructure-as-Code account vending:
    → Push to Git repo → pipeline runs → new account created + configured
    → GitOps-style account management
    → Apply account customizations via Terraform

Customization after creation:
  Account Factory customizations (AFCx): run additional Config/scripts post-creation
  CfCT (Customizations for Control Tower): CloudFormation StackSets deployed to new accounts
```

---

## 5. Control Tower Dashboard

```
Single pane of glass for entire organization:
  Accounts: list of all enrolled accounts + OU membership
  Guardrails: which are enabled per OU
  Compliance: COMPLIANT / NONCOMPLIANT status per account per guardrail
  Non-compliant resources: drill down to specific resource + Config rule violation

Use case:
  CISO logs into Control Tower → sees 3 accounts flagged NONCOMPLIANT
  → Clicks → sees "Detect public S3 buckets" violated in prod-data account
  → Investigates → remediates → status returns to COMPLIANT
```

---

## 6. Control Tower vs Organizations

| Aspect | AWS Organizations | AWS Control Tower |
|--------|-----------------|-----------------|
| What it is | Foundation service | Orchestration layer on top of Organizations |
| Setup | Manual configuration | Automated landing zone setup |
| SCPs | You write + manage manually | Pre-built guardrails (Preventive SCPs) |
| Logging | You configure manually | Auto-configured CloudTrail org trail |
| Account creation | API / Console → manual config | Account Factory → standardized + compliant |
| Compliance visibility | None | Dashboard: COMPLIANT/NONCOMPLIANT per account |
| Config rules | You enable manually per account | Auto-enabled + detective guardrails |
| Best for | Advanced teams building custom | Enterprises wanting best-practice baseline fast |

```
Relationship: Control Tower USES Organizations under the hood
  Control Tower creates + manages the Organizations structure
  You can use both: Control Tower for governance + Organizations directly for billing
  Do NOT manually change SCPs that Control Tower created → may break guardrails
```

---

## 7. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Guardrails apply to individual accounts | Guardrails apply to **OUs only** — not individual accounts |
| Control Tower replaces Organizations | Control Tower **builds ON TOP of** Organizations — Organizations still the foundation |
| OUs created in Organizations console are governed | OUs created outside Control Tower are **"Unregistered"** — must manually register |
| Detective guardrails block actions | Detective guardrails **detect and report** — only preventive guardrails block |
| Mandatory guardrails can be disabled | Mandatory guardrails **cannot be disabled** — always enforced |
| Account Factory accounts need manual compliance setup | Account Factory accounts get **automatic governance enrollment** — no manual steps |

---

## 8. Interview Questions Checklist

- [ ] What is a landing zone? What two accounts does Control Tower auto-create?
- [ ] Preventive vs detective guardrails — mechanism for each? (SCP vs Config rule)
- [ ] Three guardrail enforcement levels? (mandatory, strongly recommended, elective)
- [ ] What happens to OUs created outside Control Tower? (Unregistered — must register)
- [ ] Account Factory for Terraform (AFT) — what is it? (GitOps account vending)
