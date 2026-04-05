# AWS IAM Policies

## 1. What is a Policy?

A policy is a **JSON document** that defines permissions — what actions are
allowed or denied on which resources under what conditions. Policies have
no effect on their own; they must be **attached** to an identity or resource.

```
Policy = Permission Document (JSON)
Attached to → IAM User / Group / Role / AWS Resource
```

---

## 2. Policy JSON Structure ⭐

```json
{
  "Version": "2012-10-17",
  "Id": "optional-policy-id",
  "Statement": [
    {
      "Sid": "AllowS3ReadForReports",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::123456789012:role/ReportRole" },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::reports-bucket",
        "arn:aws:s3:::reports-bucket/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

### Field Reference

| Field | Required | Values | Notes |
|-------|---------|--------|-------|
| `Version` | ✅ | `"2012-10-17"` | Always use this — never omit |
| `Sid` | ❌ | Any string | Statement identifier — optional label |
| `Effect` | ✅ | `Allow` or `Deny` | Only two valid values |
| `Principal` | Context | ARN or `"*"` | Required in resource-based policies; **not used** in identity-based policies |
| `Action` | ✅ | `service:action` or `"*"` | Specific API call (e.g., `s3:GetObject`) |
| `Resource` | ✅ | ARN or `"*"` | What the action applies to |
| `Condition` | ❌ | Condition block | Optional additional constraints |

### Wildcards in Actions and Resources

```
"Action": "s3:*"             ← all S3 actions
"Action": "s3:Get*"          ← all S3 GET actions
"Action": "*"                ← all actions on all services (admin)

"Resource": "*"              ← all resources
"Resource": "arn:aws:s3:::my-bucket/*"  ← all objects in bucket
"Resource": "arn:aws:s3:::my-bucket"    ← the bucket itself (not objects)
```

> **S3 common gotcha:** To allow `s3:ListBucket`, the Resource must be the
> **bucket ARN** (`arn:aws:s3:::my-bucket`). To allow `s3:GetObject`,
> the Resource must be the **object ARN** (`arn:aws:s3:::my-bucket/*`).
> Both are needed together — they target different resource levels.

---

## 3. Policy Types ⭐ (Three Types)

### 1. AWS Managed Policy

```
Created and maintained by AWS
Namespace: starts with "arn:aws:iam::aws:policy/..."
           Note: no account ID in ARN (AWS-owned)

Examples:
  AmazonS3FullAccess
  AmazonEC2ReadOnlyAccess
  AdministratorAccess
  PowerUserAccess
  ReadOnlyAccess

Properties:
  ✅ Versioned — AWS updates when new actions added
  ✅ Reusable — attach to unlimited users/roles/groups
  ✅ No management overhead
  ❌ Too broad — often violates least privilege
  ❌ Cannot customize
```

### 2. Customer Managed Policy

```
Created and maintained by YOU in your AWS account
Namespace: arn:aws:iam::123456789012:policy/MyCustomPolicy
                       ↑ your account ID

Properties:
  ✅ Fully customizable — exact permissions you need
  ✅ Versioned — up to 5 versions stored; set any as default
  ✅ Reusable — attach to unlimited users/roles/groups in same account
  ✅ Auditable — you control changes
  ❌ Requires maintenance when AWS adds new APIs
```

### 3. Inline Policy

```
Embedded directly inside a specific user, group, or role
No separate existence — lives inside the entity
Deleted automatically when the entity is deleted

Properties:
  ✅ Tight coupling — policy guaranteed to go away with the entity
  ✅ Useful for unique one-off permissions
  ❌ Not reusable — cannot share with other entities
  ❌ Not visible in policy list — harder to audit
  ❌ No versioning
  ❌ Complicates automation at scale

When entity is deleted:
  Managed policy: remains in account ← exists independently
  Inline policy:  deleted with entity ← no independent existence
```

### Comparison Table

| Property | AWS Managed | Customer Managed | Inline |
|---------|------------|-----------------|--------|
| Created by | AWS | You | You |
| Reusable | ✅ (any account) | ✅ (same account) | ❌ (one entity) |
| Versioning | AWS-controlled | Up to 5 versions | ❌ None |
| Survives entity deletion | ✅ | ✅ | ❌ Deleted |
| Customizable | ❌ | ✅ | ✅ |
| Best for | Quick setup | Production | Unique edge cases |

---

## 4. Policy Categories by Attachment ⭐

Beyond the three types above, policies are also categorized by **what they attach to**:

### Identity-Based Policies

Attached to **IAM identities** (users, groups, roles):

```
Controls: what the identity CAN DO to resources
Principal field: NOT included (the identity itself is the principal)

Types: AWS Managed, Customer Managed, or Inline
Attached to: User, Group, Role
```

### Resource-Based Policies

Attached to **AWS resources** (S3 buckets, SQS queues, KMS keys, Lambda):

```
Controls: who CAN ACCESS this resource
Principal field: REQUIRED (specifies who is allowed)

Examples:
  S3 Bucket Policy        ← most common
  SQS Queue Policy
  KMS Key Policy          ← controls who can use the key
  Lambda Resource Policy  ← controls who can invoke the function
  API Gateway Resource Policy

Cross-account access:
  Resource-based policy alone can grant cross-account access
  (no need for AssumeRole — just specify the other account's ARN as Principal)
```

| | Identity-Based | Resource-Based |
|--|---------------|---------------|
| Attached to | IAM identity | AWS resource |
| Principal field | ❌ Not used | ✅ Required |
| Cross-account | Needs both IAM + trust policy | Can work alone |
| Example | AmazonS3FullAccess on a role | S3 bucket policy |

---

## 5. Condition Block ⭐

Conditions add **fine-grained control** beyond just Effect + Action + Resource:

```json
"Condition": {
  "ConditionOperator": {
    "ConditionKey": "value"
  }
}
```

### Common Condition Operators

| Operator | Example Usage |
|---------|-------------|
| `StringEquals` | Match exact string |
| `StringLike` | Wildcard match (`*`, `?`) |
| `ArnLike` | Match ARN pattern |
| `IpAddress` | IP range match |
| `Bool` | True/false check |
| `DateGreaterThan` | Time-based access |
| `Null` | Check if key exists |

### Common Global Condition Keys

| Key | Description | Example |
|-----|------------|---------|
| `aws:RequestedRegion` | Restrict to specific regions | Prevent resources in EU |
| `aws:SourceIp` | Restrict by IP address | Office network only |
| `aws:MultiFactorAuthPresent` | Require MFA | Enforce MFA for destructive actions |
| `aws:PrincipalArn` | Match calling principal ARN | Cross-account conditions |
| `aws:RequestTag/key` | Match request tag | Require tags on created resources |
| `aws:ResourceTag/key` | Match resource tag | Only access tagged resources |
| `s3:prefix` | Match S3 key prefix | User-specific S3 folder access |

### Real Examples

```json
// Require MFA to delete S3 objects
{
  "Effect": "Deny",
  "Action": "s3:DeleteObject",
  "Resource": "*",
  "Condition": {
    "BoolIfExists": {
      "aws:MultiFactorAuthPresent": "false"
    }
  }
}

// Allow S3 access only from specific IP range
{
  "Effect": "Deny",
  "Action": "s3:*",
  "Resource": "*",
  "Condition": {
    "NotIpAddress": {
      "aws:SourceIp": ["203.0.113.0/24", "198.51.100.0/24"]
    }
  }
}

// Users can only access their own S3 "folder"
{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::user-data/${aws:username}/*"
}
```

---

## 6. Policy Evaluation Logic ⭐ (Critical)

When AWS evaluates whether to allow or deny a request:

```
Evaluation order (strict precedence):

1. EXPLICIT DENY → Deny immediately (no exceptions, overrides everything)
      ↓ (if no explicit deny)
2. EXPLICIT ALLOW → Allow (from any applicable policy)
      ↓ (if no explicit allow)
3. IMPLICIT DENY → Deny by default (nothing was allowed)
```

### Evaluation with Multiple Policy Types

```
For a request from an IAM user in Account A to a resource in Account A:
  ALLOW if:
    → At least one identity-based policy allows the action
    → AND resource-based policy doesn't deny
    → AND no explicit deny anywhere

For cross-account: user in Account B to resource in Account A:
  ALLOW if:
    → Identity-based policy in Account B allows the action
    → AND resource-based policy in Account A allows Account B principal
    → AND no explicit deny in either account

For a role session with a Permission Boundary:
  ALLOW only if:
    → Identity policy allows
    → AND Permission Boundary allows (intersection)
    → AND SCPs allow (if Organizations is used)
```

### Visual Flow

```
Request arrives
     │
     ▼
Explicit DENY in any policy? ──Yes──→ DENY ❌
     │ No
     ▼
Explicit ALLOW in applicable policy? ──No──→ DENY ❌ (implicit)
     │ Yes
     ▼
Permission Boundary allows? (if set) ──No──→ DENY ❌
     │ Yes
     ▼
SCP allows? (if Organizations) ──No──→ DENY ❌
     │ Yes
     ▼
     ALLOW ✅
```

---

## 7. Service Control Policies (SCPs) ⭐

SCPs are a feature of **AWS Organizations** — they define the maximum
permissions available in an AWS account or OU (Organizational Unit):

```
Organization Root
  └── OU: Development
       └── OU: Engineering
            └── Account: 123456789012 (ibtisam's account)

SCP on Engineering OU: Deny all actions outside us-east-1, eu-west-1

→ Even if an IAM admin in account 123456789012 has AdministratorAccess,
  they CANNOT create resources in ap-southeast-1 — SCP blocks it

Root user is ALSO subject to SCPs (only time root user can be restricted)
```

**SCP vs IAM Policy:**

| | SCP | IAM Policy |
|--|-----|-----------|
| Applies to | Entire AWS account | Specific user/role |
| Restricts root user | ✅ Yes | ❌ No |
| Grants permissions | ❌ No (sets max ceiling) | ✅ Yes |
| Used in | AWS Organizations | Single account or multi-account |

> SCP says: "**at most** these actions are available in this account."
> IAM policy says: "**this identity** can do these actions."
> Both must allow — SCP blocks even if IAM explicitly allows.

---

## 8. AWS Managed Policy Examples (Common Ones)

| Policy Name | Allows |
|------------|--------|
| `AdministratorAccess` | `*` on `*` — full account access |
| `PowerUserAccess` | Everything except IAM and Organizations |
| `ReadOnlyAccess` | Read-only on all services |
| `AmazonS3FullAccess` | All S3 actions |
| `AmazonS3ReadOnlyAccess` | S3 Get + List only |
| `AmazonEC2FullAccess` | All EC2 actions |
| `IAMFullAccess` | All IAM actions |
| `AmazonDynamoDBFullAccess` | All DynamoDB actions |
| `CloudWatchLogsFullAccess` | All CloudWatch Logs actions |

---

## 9. Policy Writing — Patterns and Anti-Patterns

```
✅ Good: S3 access scoped to a specific bucket
  "Resource": "arn:aws:s3:::my-app-data/*"

❌ Bad: Wildcard resource for write access
  "Action": "s3:PutObject",
  "Resource": "*"

✅ Good: Separate Allow from Deny in different statements
  Statement 1: Allow read on specific bucket
  Statement 2: Deny delete actions (even on allowed bucket)

✅ Good: Use conditions to scope by tag
  Allow EC2:* only if ec2:ResourceTag/Environment = "dev"
  → Developers cannot touch production instances

✅ Good: DenyDeleteOnProduction
  "Effect": "Deny",
  "Action": ["ec2:TerminateInstances", "rds:DeleteDBInstance"],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "aws:ResourceTag/Environment": "production"
    }
  }
```

---

## 10. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| "Deny beats Allow — so add more Denys for security" | Deny is for exceptions — **default is already implicit deny**; over-use of explicit Deny creates complex policies |
| Inline policy is deleted when detached | Inline policy is deleted when the **entity is deleted** — there is no "detach" for inline policies |
| SCP grants permissions | SCP **never grants** — it only sets max ceiling; IAM policies still required to grant |
| Resource-based policy on S3 = same as IAM policy | Resource-based policy requires **Principal** field; IAM policy does not |
| `"Version": "2012-10-11"` is fine | Always use exactly `"2012-10-17"` — older version doesn't support policy variables |
| AdministratorAccess = root user | AdministratorAccess `{ "Effect": "Allow", "Action": "*", "Resource": "*" }` but **root user bypasses IAM entirely** |
| Permission boundary grants access | Permission boundary **restricts** access — it never grants on its own |

---

## 11. Interview Questions Checklist

- [ ] Three types of IAM policies — how does each differ?
- [ ] What happens to an inline policy when the user is deleted?
- [ ] What happens to a customer managed policy when its attached user is deleted?
- [ ] What are the six fields in a policy statement? Which are required?
- [ ] Identity-based vs resource-based — when do you use each?
- [ ] What is the policy evaluation order? (Explicit Deny → Allow → Implicit Deny)
- [ ] Cross-account S3 access — what must be true for it to work?
- [ ] What does an SCP do that an IAM policy cannot?
- [ ] Can an SCP restrict the root user? (Yes — only way to restrict root)
- [ ] Write a policy: allow a user to access only their own S3 folder
- [ ] What is the `Principal` field? When is it required vs not?
- [ ] Write a condition to require MFA for destructive actions
- [ ] What is a permission boundary? How does it differ from a regular policy?
- [ ] What does `aws:ResourceTag` condition key do?
