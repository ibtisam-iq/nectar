# AWS IAM Roles

## 1. Role vs User — The Core Distinction ⭐

```
IAM User:
  → Has a permanent identity (username)
  → Has long-lived credentials (password + access keys)
  → "Possessed" — you ARE this user
  → Best for: human beings with long-term AWS access

IAM Role:
  → Has no permanent credentials
  → Generates temporary credentials via STS when assumed
  → "Assumed" — you TEMPORARILY become this role
  → Best for: AWS services, automation, cross-account, federation
```

> A role is like a **uniform** — anyone authorized can put it on, use its permissions,
> and take it off. The uniform is not permanently assigned to anyone.

### Why Roles Are Safer Than Users

```
IAM User Access Key:
  Validity: PERMANENT (until manually rotated/deleted)
  If leaked: attacker has indefinite access until you notice and rotate
  Rotation: manual, human-driven

IAM Role Temporary Credentials:
  Validity: 15 minutes to 12 hours (configurable)
  If leaked: expires soon on its own
  Rotation: automatic — STS issues fresh credentials on each AssumeRole
```

---

## 2. Role Anatomy — Two Policies Every Role Has ⭐

Every IAM role has exactly two policy components:

```
IAM Role
  ├── Trust Policy (WHO can assume this role?)
  │     → Defines which principals are allowed to call sts:AssumeRole
  │
  └── Permission Policy (WHAT can be done after assuming?)
        → Standard IAM policy defining allowed/denied actions
```

### Trust Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

> The trust policy is a **resource-based policy on the role itself**.
> It answers: "Who is allowed to wear this uniform?"

### Permission Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-app-bucket/*"
    }
  ]
}
```

---

## 3. Five Principal Types That Can Assume Roles ⭐

AWS defines five categories of entities (principals) that can be granted
permission to assume a role:

### 1. AWS Service

An AWS service itself assumes the role to perform actions on your behalf.

```
Trust policy principal:
  "Principal": { "Service": "ec2.amazonaws.com" }
  "Principal": { "Service": "lambda.amazonaws.com" }
  "Principal": { "Service": "ecs-tasks.amazonaws.com" }

Use cases:
  EC2 → reads from S3 (attach role to instance via Instance Profile)
  Lambda → writes to DynamoDB
  ECS Task → pulls secrets from Secrets Manager
  CodePipeline → deploys to ECS
  RDS Enhanced Monitoring → publish metrics to CloudWatch
```

### 2. IAM User (Same Account)

An IAM user in the same account assumes a role for elevated/different permissions.

```
Trust policy principal:
  "Principal": { "AWS": "arn:aws:iam::123456789012:user/ibtisam" }
  OR for any user in account:
  "Principal": { "AWS": "arn:aws:iam::123456789012:root" }

Use cases:
  Developer assumes admin role temporarily (with MFA enforcement)
  Service account user assumes deployment role
  Break-glass scenario: normal user assumes emergency-access role

Condition to require MFA before assuming:
  "Condition": {
    "Bool": { "aws:MultiFactorAuthPresent": "true" }
  }
```

### 3. IAM User (Cross-Account)

A user or role in Account B assumes a role in Account A.

```
Account A (target): Trust policy allows Account B
  "Principal": { "AWS": "arn:aws:iam::ACCOUNT-B-ID:root" }
  OR specific user:
  "Principal": { "AWS": "arn:aws:iam::ACCOUNT-B-ID:user/deployer" }

Account B (source): User/role must have permission to call sts:AssumeRole
  {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::ACCOUNT-A-ID:role/DeployRole"
  }

Use cases:
  Central security account audits all other accounts
  CI/CD pipeline in one account deploys to another
  Shared services account (logging, monitoring) accessed by all accounts
```

### 4. Web Identity / OIDC Federation

External identity provider users (Google, Facebook, GitHub Actions, Cognito)
assume a role without needing IAM users.

```
Trust policy principal:
  "Principal": {
    "Federated": "cognito-identity.amazonaws.com"
  }
  OR for GitHub Actions:
  "Principal": {
    "Federated": "token.actions.githubusercontent.com"
  }

Condition for GitHub Actions (OIDC):
  "Condition": {
    "StringLike": {
      "token.actions.githubusercontent.com:sub":
        "repo:ibtisam-iq/my-repo:ref:refs/heads/main"
    }
  }

Use cases:
  Mobile app users (via Cognito) access their own S3 folder
  GitHub Actions deploys to AWS without storing access keys in repo secrets
  Google-authenticated users access AWS resources
```

> **GitHub Actions + OIDC is the modern standard** for CI/CD. Never use
> IAM user access keys in GitHub secrets — use OIDC role assumption instead.

### 5. SAML 2.0 Federation

Corporate identity provider (Microsoft Active Directory, Okta, Ping)
users assume AWS roles using SAML assertions.

```
Trust policy principal:
  "Principal": {
    "Federated": "arn:aws:iam::123456789012:saml-provider/MyCorpAD"
  }
  "Action": "sts:AssumeRoleWithSAML"

Flow:
  1. Employee opens AWS Console
  2. Redirected to corporate SSO (Okta / ADFS)
  3. Employee logs in with corporate credentials
  4. IDP sends SAML assertion to AWS
  5. STS exchanges SAML assertion for temporary credentials
  6. Employee gets console access with role permissions

Use cases:
  Enterprise companies — employees use their existing AD credentials
  No IAM users created for each employee
  Access controlled from corporate directory (provision/deprovision = instant)
```

---

## 4. Role Types in AWS ⭐

### Service Role

Manually created role with a trust policy for an AWS service.
You define both the trust policy and permission policy.

```
Example: create role for EC2 to access S3
  Trust: ec2.amazonaws.com
  Permissions: s3:GetObject on my-bucket
```

### Service-Linked Role

Special role created automatically by AWS when you enable certain services.
**Pre-defined trust policy** — you cannot edit the trust policy.
You can only edit the permission boundaries or delete the role if the service allows.

```
Examples:
  AWSServiceRoleForElasticLoadBalancing   ← created when first ELB is created
  AWSServiceRoleForAutoScaling            ← created when first ASG is created
  AWSServiceRoleForRDS                    ← created when first RDS instance is created

Cannot be used for: general purpose access
Cannot be renamed: name is fixed by AWS
```

### Instance Profile

A **wrapper** that allows an IAM role to be attached to an EC2 instance.
When you create a role for EC2 in the console, AWS automatically creates
an instance profile with the same name.

```
EC2 → Instance Profile → IAM Role → Permissions

CLI:
  aws iam create-instance-profile --instance-profile-name MyProfile
  aws iam add-role-to-instance-profile --instance-profile-name MyProfile --role-name MyRole
  aws ec2 associate-iam-instance-profile --instance-id i-xxx --iam-instance-profile Name=MyProfile

Application on EC2 gets credentials from metadata service:
  curl http://169.254.169.254/latest/meta-data/iam/security-credentials/MyRole
  → Returns: AccessKeyId, SecretAccessKey, Token, Expiration
  → Credentials auto-refresh before expiry — application never needs to handle rotation
```

---

## 5. Role Session Duration

```
Default session duration: 1 hour
Configurable: 15 minutes to 12 hours (set on the role definition)
Max session (AWS console): 12 hours

Recommendation:
  Interactive console sessions: 4–8 hours
  CI/CD pipelines: 15–60 minutes (shortest needed)
  Long-running batch jobs: extend to actual runtime
```

---

## 6. Cross-Account Role Pattern ⭐ (Production Common Pattern)

```
Company has:
  Account 001 (Production) — contains production resources
  Account 002 (Development) — developers work here
  Account 003 (CI/CD) — deployment pipelines run here

Pattern: "Hub and Spoke" cross-account roles

In Account 001 (Production):
  Role: ProductionDeployRole
  Trust policy: allows Account 003's pipeline role to assume it

In Account 003 (CI/CD):
  Role: PipelineRole
  Permission: sts:AssumeRole on Account 001's ProductionDeployRole

Deploy flow:
  Pipeline (Account 003) → AssumeRole → ProductionDeployRole (Account 001)
  → Gets temp credentials scoped to Account 001
  → Deploys to production
  → Credentials expire → no persistent access
```

---

## 7. Permission Boundaries ⭐

A permission boundary is an **IAM managed policy** set as the maximum permissions
an IAM entity (user or role) can have — even if their identity policies grant more.

```
Effective permissions = (Identity Policy) ∩ (Permission Boundary)

Example:
  Identity Policy: Allow s3:*, ec2:*, rds:*
  Permission Boundary: Allow s3:*, ec2:*
  Effective Permissions: Allow s3:*, ec2:*  (RDS removed by boundary)

Use case: delegated administration
  You give a team lead permission to create IAM roles for their team
  BUT you set a permission boundary so they cannot create roles
  with more permissions than they themselves have
  → Prevents privilege escalation
```

---

## 8. Role Assumption Decision Flow

```
Request: "User X wants to assume Role Y"

Step 1: Does User X have sts:AssumeRole permission for Role Y?
  → Check User X's identity policies (and group policies)
  → If NO → AccessDenied ❌

Step 2: Does Role Y's trust policy allow User X?
  → Check trust policy Principal and Conditions
  → If NO → AccessDenied ❌

Step 3: Are there permission boundaries that restrict?
  → If boundary blocks AssumeRole → AccessDenied ❌

Step 4: All checks pass → STS issues temporary credentials ✅
  → Session with Role Y's permission policies
```

---

## 9. Interview Questions Checklist

- [ ] What is the difference between an IAM user and an IAM role?
- [ ] Why are roles safer than long-term access keys?
- [ ] What two policies does every role have? What does each do?
- [ ] List the five principal types that can assume a role with examples
- [ ] What is an Instance Profile? How does EC2 get credentials from it?
- [ ] How do GitHub Actions assume an AWS role without storing access keys?
- [ ] What is a service-linked role? Can you edit its trust policy?
- [ ] What is a permission boundary? How does it prevent privilege escalation?
- [ ] Cross-account role setup — what must be configured in BOTH accounts?
- [ ] If a user is granted AssumeRole but the role's trust policy doesn't allow them, can they assume it?
- [ ] What is the default and maximum role session duration?
