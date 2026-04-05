# AWS IAM

## 1. What is IAM?

IAM (Identity and Access Management) is AWS's **global, free security service**
that controls **who can authenticate** (prove identity) and **who is authorized**
(allowed to do what) across every AWS service and resource.

```
Authentication → Who are you?   → IAM verifies identity via password, keys, tokens
Authorization  → What can you do? → IAM evaluates policies to allow or deny actions
```

> IAM is **global** — not region-specific. Users, groups, roles, and policies you
> create apply across all AWS Regions.

---

## 2. Root User vs IAM Users ⭐

### Root User

```
Created when AWS account is first opened
Email address + password login
Has UNRESTRICTED access to everything — including closing the account, changing
billing info, and cancelling AWS support plans
```

**Root user should be used ONLY for:** [source: AWS Security Best Practices]
- Creating the first IAM admin user
- Changing account settings (root email, account name)
- Restoring IAM admin access if lost
- Enabling MFA on the root account
- Viewing and paying bills

**Root user should NEVER be used for:**
- Daily operations
- CI/CD pipelines
- Application access
- CLI access

### IAM User

```
Created inside an AWS account
Has ZERO permissions by default — explicit Allow required
Has its own credentials separate from root
```

| Property | Root User | IAM User |
|---------|----------|---------|
| Created by | AWS account opening | IAM service |
| Default permissions | Unlimited | None |
| Can be deleted | ❌ | ✅ |
| Can be restricted | ❌ (even SCPs don't apply) | ✅ |
| MFA support | ✅ | ✅ |
| Password policy applies | ❌ | ✅ |
| Use for daily work | ❌ Never | ✅ Yes |

**Account limit:** 5,000 IAM users per AWS account.

---

## 3. IAM Users — Credentials ⭐

An IAM user can have up to **two types of credentials**:

### Console Access (Username + Password)

```
Used for: AWS Management Console (browser)
How: username + password + optional MFA
Enable: manually in IAM → user settings
```

### Programmatic Access (Access Key ID + Secret Access Key)

```
Used for: AWS CLI, SDKs, APIs
Format:
  Access Key ID:     AKIAIOSFODNN7EXAMPLE       (20 chars, starts with AKIA)
  Secret Access Key: wJalrXUtnFEMI/K7MDENGbPxR (40 chars, shown ONCE at creation)

Limits: max 2 active access keys per user
```

**Access Key Rules:**
- Secret is shown **once** at creation — if lost, must rotate (deactivate + create new)
- Rotate regularly (set reminder or use IAM Access Analyzer)
- **Never embed in code, Docker images, or Git repos**
- Use `aws configure` to store in `~/.aws/credentials` on local machine
- For applications running on AWS: **use IAM roles, not access keys**

### MFA (Multi-Factor Authentication)

| MFA Type | Device | Use Case |
|---------|--------|---------|
| Virtual MFA | Authenticator app (Google Authenticator, Authy) | Most common |
| Hardware TOTP | Physical keyfob | High-security environments |
| FIDO Security Key | YubiKey, hardware key | Enterprise |
| SMS (legacy) | Phone text message | Deprecated — avoid |

---

## 4. IAM Groups ⭐

A group is a collection of IAM users that share a set of permissions.
Permissions are attached to the group — all members inherit them.

```
DevOps-Team (Group)
  ├── Policy: EC2FullAccess
  ├── Policy: S3ReadOnly
  └── Members:
       ├── ibtisam (User)
       ├── ali (User)
       └── sara (User)
```

**Group Rules:**
- Users can belong to **multiple groups** (permissions are combined)
- Groups **cannot contain other groups** (no nesting)
- Groups are NOT principals — they cannot be specified in resource-based policies
- A user with no group has only their directly-attached policies
- Max: 300 groups per account; max 10 groups per user

```
User effective permissions = (own policies) + (all group policies combined)
Exception: explicit Deny anywhere → overrides all Allows
```

---

## 5. Security Token Service (STS) ⭐

STS generates **short-lived, temporary security credentials** for any principal
that needs temporary access:

```
Temporary Credentials Package:
  - Access Key ID       (temporary)
  - Secret Access Key   (temporary)
  - Session Token       (required with the above two)
  - Expiration          (default 1hr; configurable 15min–12hr)
```

### STS API Calls

| API | Used By | Purpose |
|-----|---------|---------|
| `AssumeRole` | IAM user or role | Assume a role in same or different account |
| `AssumeRoleWithWebIdentity` | App user (Google, Facebook, Cognito) | Web identity federation |
| `AssumeRoleWithSAML` | Corporate SSO user | SAML 2.0 federation |
| `GetFederationToken` | Proxy app, broker | Federation for non-IAM users |
| `GetSessionToken` | IAM user with MFA | MFA-protected API calls |

```
AssumeRole flow:
  1. App calls sts:AssumeRole with role ARN
  2. STS verifies caller has sts:AssumeRole permission
  3. STS verifies trust policy of target role allows this caller
  4. STS issues temp credentials (Access Key + Secret + Token)
  5. App uses temp credentials to call AWS APIs
  6. Credentials expire → repeat
```

---

## 6. IAM Password Policy

Configures requirements for IAM user console passwords at the account level:

```
Settings available:
  ✅ Minimum password length (default: 8, max: 128)
  ✅ Require uppercase letters
  ✅ Require lowercase letters
  ✅ Require numbers
  ✅ Require special characters
  ✅ Allow users to change their own password
  ✅ Password expiration (e.g., every 90 days)
  ✅ Prevent password reuse (remember last N passwords, max 24)
  ✅ Require admin reset after expiry
```

> Password policy applies to **IAM users only** — not root user,
> not federated users, not role sessions.

---

## 7. IAM Credential Report + Access Advisor

### Credential Report

Account-level CSV report of all IAM users and their credential status:

```
Columns include:
  user, arn, user_creation_time
  password_enabled, password_last_used, password_last_changed, password_next_rotation
  mfa_active
  access_key_1_active, access_key_1_last_rotated, access_key_1_last_used_date
  access_key_2_active, access_key_2_last_rotated, access_key_2_last_used_date

Use case: security audit — find users who haven't rotated keys in 90+ days
Generate: IAM Console → Credential Report → Download CSV
```

### IAM Access Advisor (per user/role)

Shows which services a user/role has accessed recently:

```
Use case: identify unused permissions → apply least privilege
  "User was granted EC2FullAccess but hasn't used EC2 in 180 days"
  → Remove EC2FullAccess → reduce attack surface
```

---

## 8. IAM Best Practices ⭐

| Practice | Why |
|---------|-----|
| Lock root user, enable MFA on root | Root compromise = complete account loss |
| Create IAM admin user immediately | Never use root for daily work |
| Attach permissions to groups, not users | Easier management at scale |
| Grant least privilege | Reduce blast radius of compromise |
| Use roles for AWS services | No long-lived credentials on EC2/Lambda |
| Rotate access keys regularly | Limit exposure window if keys leak |
| Enable MFA for privileged users | Phishing-resistant second factor |
| Use IAM Access Analyzer | Continuously detect overly permissive access |
| Use permission boundaries for delegated admin | Prevent privilege escalation |
| Never hardcode credentials | Use environment vars, Secrets Manager, roles |

---

## 9. IAM — Key Facts for Exams

- IAM is **global** — no region selection
- IAM is **free** — no charge for users, groups, roles, policies
- New IAM user has **zero permissions by default**
- **Explicit Deny** always overrides any Allow
- Root user **cannot be restricted** by SCPs or permission boundaries
- Max **5,000 IAM users** per account
- Groups **cannot be nested**
- A user can belong to **max 10 groups**
- Access keys: max **2 per user** (to allow rotation without downtime)
- STS temporary credentials: **15 minutes to 12 hours**
