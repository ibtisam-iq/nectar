# AWS Organizations

## 1. What is AWS Organizations?

AWS Organizations is a **free account management service** that lets you
centrally govern multiple AWS accounts — grouping them into a hierarchy,
applying security guardrails, pooling billing, and enabling cross-account
AWS service integration.

```
Without Organizations:
  10 accounts → 10 separate bills, 10 separate IAM setups
  No central way to enforce: "nobody in any account can disable CloudTrail"
  Volume discounts: each account's usage counted separately

With Organizations:
  Single management structure → all accounts governed centrally
  SCPs: one policy blocks actions across 50 accounts simultaneously
  Consolidated billing: usage pooled → volume discounts + RI sharing
  One CloudTrail org trail → logs everything in every account
  Free service: no charge for Organizations itself
```

---

## 2. Key Concepts ⭐

```
Root:
  Top of the hierarchy — exactly ONE root per organization
  Policies attached to Root apply to ALL OUs and accounts
  Management account lives here

Management Account (formerly "master account"):
  The account that CREATED the organization
  Pays all consolidated bills
  Cannot be restricted by SCPs — fully exempt [docs.aws.amazon](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
  Can create new accounts, invite existing accounts, remove accounts
  Best practice: use management account ONLY for billing/governance
                 → no workloads deployed here

Member Accounts:
  All other accounts in the organization
  Subject to SCPs from parent OUs/Root
  Can only belong to ONE organization at a time
  Can be removed (leaves) or closed

Organizational Units (OUs):
  Logical containers to group accounts
  Hierarchy: Root → OU → Sub-OU → Account (up to 5 levels deep)
  SCP applied to OU → inherited by ALL accounts in OU + child OUs [aws.amazon](https://aws.amazon.com/blogs/industries/best-practices-for-aws-organizations-service-control-policies-in-a-multi-account-environment/)
  An account can belong to only ONE OU at a time

Typical OU structure: [aws.amazon](https://aws.amazon.com/blogs/industries/best-practices-for-aws-organizations-service-control-policies-in-a-multi-account-environment/)
  Root
  ├── Management Account
  ├── OU: Security (audit, log archive accounts)
  ├── OU: Infrastructure (shared networking, DNS)
  ├── OU: Workloads
  │   ├── OU: Production
  │   │   └── Accounts: prod-app, prod-data, prod-api
  │   └── OU: Development
  │       └── Accounts: dev-team-a, dev-team-b
  └── OU: Sandbox
      └── Accounts: individual developer sandboxes
```

---

## 3. Policy Types ⭐

```
Organizations supports multiple policy types:

1. Service Control Policies (SCPs): ← most important
   Restrict maximum permissions in member accounts
   Must be ENABLED per organization (not on by default)
   Apply to: all IAM users + roles in member accounts (including account root user)
   Do NOT apply to: management account [docs.aws.amazon](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
   Do NOT grant permissions — only restrict them

2. Tag Policies:
   Enforce consistent tagging across accounts
   Example: require "Environment" tag with values: prod/dev/staging
   Helps with cost allocation and resource management

3. Backup Policies:
   Enforce AWS Backup plans across accounts
   Example: all EC2 in prod accounts must be backed up daily

4. AI Services Opt-Out Policies:
   Opt all accounts out of AI service data usage
   (Prevents AWS using your data to train AI models)

5. Chatbot Policies:
   Control AWS Chatbot configurations across accounts
```

### SCP Deep Dive

```
SCP inheritance rules:
  Account effective permissions = IAM permissions ∩ ALL SCPs in hierarchy
  Parent OU SCP restricts → child CANNOT be more permissive → only further restrictive
  Default: FullAWSAccess SCP attached to Root (allows everything) [docs.aws.amazon](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
  Remove FullAWSAccess → implicit deny everything → accounts can do nothing

Deny list strategy (recommended): [docs.aws.amazon](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
  Keep FullAWSAccess SCP → add explicit Deny SCPs for what to block
  Example: Deny ec2:RunInstances for non-approved regions

Allow list strategy:
  Remove FullAWSAccess → add explicit Allow SCPs for what IS permitted
  Everything else implicitly denied
  More restrictive → harder to maintain

SCP does NOT affect:
  Management account (always exempt) [docs.aws.amazon](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
  Service-linked roles (AWS internal roles)
  Anything before the account joins the organization

Common SCP guardrails: [aws.amazon](https://aws.amazon.com/blogs/industries/best-practices-for-aws-organizations-service-control-policies-in-a-multi-account-environment/)
  1. Prevent leaving organization:
     Deny: organizations:LeaveOrganization

  2. Restrict to approved regions:
     Deny: "*" where aws:RequestedRegion not in [us-east-1, eu-west-1]
     Exclude global services from region restriction:
       Condition: StringNotEquals + ArnNotLike for IAM/STS/CloudFront

  3. Prevent disabling security services:
     Deny: cloudtrail:StopLogging, cloudtrail:DeleteTrail,
           config:DeleteConfigRule, guardduty:DeleteDetector

  4. Require MFA for sensitive actions:
     Deny: ec2:StopInstances where aws:MultiFactorAuthPresent: false

  5. Prevent root user usage:
     Deny: "*" where aws:PrincipalArn matches root ARN pattern

  6. Enforce encryption:
     Deny: s3:PutObject where s3:x-amz-server-side-encryption not set
```

---

## 4. Account Lifecycle Management

```
Create new account (programmatic):
  aws organizations create-account \
    --email newaccount@company.com \
    --account-name "Production-App"
  → Account created with standard structure
  → Automatically joins organization under management account
  → An OrganizationAccountAccessRole is created for cross-account access

Invite existing account:
  Send invitation → account owner accepts → joins organization
  → SCPs begin applying immediately on join

Move account between OUs:
  aws organizations move-account \
    --account-id 123456789012 \
    --source-parent-id ou-xxxx-aaaaaaaa \
    --destination-parent-id ou-xxxx-bbbbbbbb
  → New OU's SCPs apply immediately

Close account:
  Must remove from org first OR use Organizations close account API
  90-day closure period before permanent deletion

Delegated administrator:
  Assign a member account as delegated admin for specific services
  (GuardDuty, Security Hub, Macie, Config, etc.)
  → That account manages the service across org without management account access
  Best practice: use Security/Audit OU account as delegated admin
```

---

## 5. AWS Services Integrating with Organizations

```
Billing:
  AWS Cost Explorer:       org-wide cost analysis
  AWS Budgets:             org-wide + per-account budgets
  Cost and Usage Reports:  org-level consolidated CUR

Security:
  AWS CloudTrail:          org trail → logs ALL accounts, ALL regions, one S3 bucket
  AWS Config:              org-wide config rules + aggregator
  AWS GuardDuty:           org-wide threat detection → findings centralized
  AWS Security Hub:        aggregate security findings across all accounts
  AWS Macie:               S3 data classification across all accounts
  AWS Firewall Manager:    WAF rules + Security Groups deployed org-wide
  AWS IAM Access Analyzer: analyze resource policies org-wide

Management:
  AWS Control Tower:       automated landing zone on top of Organizations
  AWS SSO/Identity Center: org-wide SSO + permission sets across all accounts
  AWS Service Catalog:     share product portfolios across accounts
  AWS RAM (Resource Access Manager): share resources (subnets, AMIs) cross-account
```

---

## 6. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| SCPs grant permissions | SCPs **restrict** max permissions — they never grant |
| SCPs apply to management account | Management account is **fully exempt** from SCPs |
| Account can belong to multiple OUs | Account belongs to **exactly one OU** at a time |
| Removing FullAWSAccess SCP is safe | Removing it **implicitly denies everything** — accounts lose all access |
| SCP affects service-linked roles | SCPs **do NOT restrict service-linked roles** |
| Region restriction SCP blocks IAM/STS | Must **exclude global services** (IAM, STS, CloudFront, S3 namespace) from region deny SCPs |
| Organizations has a cost | Organizations is a **completely free service** |

---

## 7. Interview Questions Checklist

- [ ] What is an SCP? Does it grant or restrict permissions?
- [ ] Who is exempt from SCPs? (management account)
- [ ] Deny list strategy vs allow list strategy for SCPs — difference?
- [ ] How do you restrict resources to specific regions via SCP? (aws:RequestedRegion condition)
- [ ] How do you create an account programmatically? (Organizations create-account API)
