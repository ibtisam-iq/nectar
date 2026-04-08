# AWS Active Directory

## 1. What is Active Directory?

Microsoft Active Directory (AD) is an **identity and access management system**
that authenticates and authorizes users, computers, and services within a
network. It is the backbone of enterprise identity management in most
organizations worldwide.

```
What AD provides:
  Authentication:  "Is this user who they claim to be?" (Kerberos, NTLM)
  Authorization:   "What resources can this user access?"
  Directory:       Hierarchical store of users, groups, computers, policies
  Group Policy:    Centrally push security settings to all domain-joined machines
  DNS:             AD relies heavily on DNS for domain controller discovery
  LDAP:            Query and update directory (Lightweight Directory Access Protocol)

Core objects in AD:
  Domain:          mycompany.local — the namespace boundary
  OU (Org Unit):   logical container → Engineering, HR, Finance
  User:            individual identity with attributes (name, email, groups)
  Group:           collection of users for access control
  Computer:        domain-joined machine with machine account
  GPO (Group Policy Object): rules applied to users/computers in an OU
  Forest:          top-level boundary — one or more domains sharing schema
  Tree:            contiguous namespace within a forest
```

---

## 2. AWS Directory Service Overview ⭐

AWS offers three managed directory options under **AWS Directory Service**:

| Service | What It Is | Best For |
|---------|-----------|----------|
| **AWS Managed Microsoft AD** | Real Microsoft AD hosted in AWS | Enterprises, > 5,000 users, trust needed |
| **Simple AD** | Samba 4 (AD-compatible, not real AD) | Small orgs, < 5,000 users, basic needs |
| **AD Connector** | Proxy to existing on-premises AD | Use existing AD without cloud copy |

```
Decision tree:
  Have existing on-premises AD?
    → YES, want to keep it as source of truth   → AD Connector
    → YES, want cloud AD too + trust            → AWS Managed Microsoft AD
  No existing AD, just need basic auth?
    → < 5,000 users, simple needs               → Simple AD
    → > 5,000 users OR need full AD features    → AWS Managed Microsoft AD
```

---

## 3. AWS Managed Microsoft AD ⭐

**Real Microsoft Active Directory** running on AWS-managed Windows Server
domain controllers — not a simulation or subset. You get actual AD with
full feature support.

```
Architecture:
  AWS deploys domain controllers in 2 AZs (minimum) for high availability
  Domain controllers: patched, monitored, backed up by AWS
  You: manage users, groups, OUs, GPOs, trusts
  AWS: manages: OS patches, DC health, replication, hardware

Editions:
  Standard:  up to 30,000 objects (users, groups, computers)
  Enterprise: up to 500,000 objects

Pricing:
  Standard:  $0.12/hour (~$86/month per directory) [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html)
  Enterprise: $0.31/hour (~$223/month per directory)
  + Domain controller hours if you add extra DCs for scale
```

### Full Feature Set

```
✅ Supports:
  Trust relationships with other AD domains (on-premises + other AWS Managed AD)
  Multi-factor authentication (MFA via RADIUS)
  Group Policy (GPO) — full support
  Schema extensions (for applications needing custom AD schema)
  LDAP (secure LDAP / LDAPS)
  Kerberos-based SSO
  Active Directory Administrative Center
  PowerShell AD module
  Active Directory Recycle Bin (undelete accidentally deleted objects)
  Group Managed Service Accounts (gMSA)
  POSIX attributes (for Linux machines)
  Smart cards (via RADIUS integration)
  Domain join: EC2 Windows + Linux instances
  AWS service integration: WorkSpaces, RDS SQL Server, FSx for Windows,
                           QuickSight, Chime, Connect, WorkDocs
```

### Trust Relationships ⭐

```
Trust = bidirectional or unidirectional trust between two AD domains
→ Users in one domain can access resources in the trusted domain
   without needing a separate account in each domain

AWS Managed Microsoft AD trust directions: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_setup_trust.html)
  Incoming:   users from self-managed (on-prem) AD → access AWS Managed AD resources
  Outgoing:   users from AWS Managed AD → access self-managed (on-prem) AD resources
  Two-way:    both directions → most common for hybrid architectures

Trust types:
  External trust: between two separate domains (different forests)
  Forest trust:   between entire forest roots → all domains in each forest trust each other

Prerequisites for trust: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_tutorial_setup_trust.html)
  VPN or Direct Connect: secure network path between on-premises and AWS VPC
  DNS resolution: each side must resolve the other's domain names
    → Add conditional forwarder: "for corp.ibtisam-iq.local, use DNS 10.0.0.5"
  Firewall rules: AD ports open between on-premises and AWS
    TCP/UDP 88 (Kerberos), TCP 135 (RPC), TCP/UDP 389 (LDAP),
    TCP/UDP 445 (SMB), TCP/UDP 464 (Kerberos pw change),
    TCP 3268/3269 (Global Catalog), dynamic RPC ports

Selective authentication: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_setup_trust.html)
  Restrict trust so only specific service accounts from on-prem
  can query AWS Managed AD (not all on-prem users)
  → Principle of least privilege for inter-domain access

One trust per domain pair:
  Only one trust relationship can exist between two domains at a time
  → If you have Incoming trust and want to change to Two-way:
    delete existing → create new Two-way trust [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_setup_trust.html)
```

### Multi-Region Replication

```
Replicate AWS Managed Microsoft AD to additional AWS regions:
  Primary region: us-east-1 (where DC created)
  Additional regions: eu-west-1, ap-southeast-1

Benefits:
  Low-latency authentication for global users
  Regional resilience: one region fails → other regions continue

Use cases:
  Global WorkSpaces deployment (users authenticate to nearest DC)
  Multi-region EC2 fleet with domain join
```

---

## 4. Simple AD ⭐

**Samba 4-based AD-compatible directory** — NOT real Microsoft AD.
It implements core AD protocols but lacks many advanced features:

```
What Simple AD CAN do: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html)
  User/group management
  Kerberos-based SSO
  Group Policy (basic)
  LDAP
  EC2 domain join (Windows + Linux)
  WorkSpaces integration (included in WorkSpaces pricing)
  IAM Identity Center integration

What Simple AD CANNOT do: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html)
  Trust relationships with other domains ← critical limitation [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/simple_ad_best_practices.html)
  Multi-factor authentication (MFA via RADIUS) ← no MFA support
  Schema extensions
  Active Directory Administrative Center
  PowerShell AD module
  Active Directory Recycle Bin
  Group Managed Service Accounts (gMSA)
  POSIX attributes

Sizes:
  Small: up to 500 users — ~$0.05/hr ($36/month)
  Large: up to 5,000 users — ~$0.15/hr ($108/month)
  Included FREE when used only with WorkSpaces
```

```
Use Simple AD when:
  Small organization (< 500–5,000 users)
  No trust relationships needed
  No MFA via RADIUS needed
  Basic WorkSpaces, EC2 domain join needed
  Cost is primary concern

Do NOT use Simple AD if:
  You need trust relationships → use AWS Managed Microsoft AD [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/simple_ad_best_practices.html)
  You need MFA → use AWS Managed Microsoft AD
  > 5,000 users → use AWS Managed Microsoft AD
  You have existing on-premises AD → use AD Connector
```

---

## 5. AD Connector ⭐

**A proxy/gateway** — it does NOT create a new directory. It forwards
authentication requests to your existing on-premises Active Directory
over a VPN or Direct Connect connection:

```
Architecture:
  AWS service (WorkSpaces/EC2) → AD Connector → VPN/DX → On-premises AD DC
  No user data stored in AWS at all
  On-premises AD remains single source of truth

Use case: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ad_connector_getting_started.html)
  You already have on-premises AD → want AWS services to use it
  Users log in to WorkSpaces/EC2 with their existing corporate AD credentials
  No need to duplicate identity in cloud
  Password changes: users change in on-premises AD → immediately applies to AWS

Sizes:
  Small:  up to 500 users — ~$0.05/hr ($36/month)
  Large:  up to 5,000 users — ~$0.15/hr ($108/month)
  Included FREE when used only with WorkSpaces

Requirements: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ad_connector_getting_started.html)
  Existing on-premises AD with reachable domain controllers
  VPN or Direct Connect to AWS VPC (AD Connector lives in VPC)
  2 DNS servers from on-premises AD (for redundancy)
  Service account in on-prem AD with specific permissions
    (read users/groups, Kerberos pre-authentication)
  Firewall: AD ports open between VPC and on-premises

What AD Connector supports:
  ✅ WorkSpaces
  ✅ EC2 domain join (Windows)
  ✅ IAM Identity Center (sync users/groups)
  ✅ RDS (for AD authentication)
  ✅ MFA via RADIUS (authenticate against on-prem RADIUS server)
  ❌ Trust relationships (no AD in cloud — nothing to trust)
  ❌ Schema extensions
  ❌ Group Policy enforcement from AWS side
```

```
AD Connector vs AWS Managed Microsoft AD for on-prem integration:

AD Connector:
  → Proxy only, no cloud AD → no cloud-only resources
  → Users managed entirely on-premises → no cloud objects
  → Network dependency: VPN/DX must be up for auth to work
    (if VPN fails → no one can log in to AWS)

AWS Managed Microsoft AD with trust:
  → Cloud AD exists independently → works even if on-prem unreachable
  → Trust allows on-prem users to access cloud resources
  → More expensive but more resilient
```

---

## 6. AWS IAM Identity Center (Successor to AWS SSO) ⭐

AWS IAM Identity Center is the **centralized SSO and access management
service** for your entire AWS organization — it integrates with Active
Directory to give users single sign-on access to AWS accounts and
business applications.

```
What it provides:
  Single portal: users.ibtisam-iq.awsapps.com
  → User logs in ONCE with corporate credentials
  → Sees all AWS accounts they have access to (with assigned roles)
  → Sees all configured SaaS apps (Salesforce, Slack, Office 365)
  → Clicks → role assumed automatically via AssumeRoleWithSAML → AWS Console opens

No more:
  Maintaining separate IAM users in every AWS account
  Sharing IAM access keys across teams
  Manual cross-account role switching
```

### Identity Sources

```
Three identity source options:

1. IAM Identity Center built-in directory (default):
   AWS manages users/groups directly in Identity Center
   Simple: no external dependency
   Use: greenfield AWS deployments, no existing IdP

2. Active Directory (via AWS Directory Service): [cloudquery](https://www.cloudquery.io/blog/aws-identity-center-guide)
   Connect AWS Managed Microsoft AD OR on-premises AD via AD Connector
   → Users and groups synced from AD to Identity Center
   → Users authenticate with their AD credentials
   → Group memberships from AD map to permission sets automatically
   Use: enterprises with existing Active Directory

3. External Identity Provider (SAML 2.0 + SCIM): [aws.amazon](https://aws.amazon.com/blogs/architecture/field-notes-integrating-active-directory-federation-service-with-aws-iam-identity-center/)
   Okta, Azure AD (Entra ID), Google Workspace, Ping Identity, AD FS
   SAML 2.0: authentication federation
   SCIM: automatic user/group provisioning from IdP → Identity Center
   Use: organizations already using third-party IdP
```

### AD FS + IAM Identity Center

```
Flow when using AD FS as external IdP: [aws.amazon](https://aws.amazon.com/blogs/architecture/field-notes-integrating-active-directory-federation-service-with-aws-iam-identity-center/)
  1. User opens AWS IAM Identity Center portal
  2. Identity Center redirects to AD FS (on-premises)
  3. User enters AD credentials → AD FS authenticates against AD
  4. AD FS issues SAML 2.0 assertion (signed XML with user attributes)
  5. Assertion sent to Identity Center endpoint
  6. Identity Center calls STS AssumeRoleWithSAML
  7. STS issues temporary credentials for the assigned permission set role
  8. User gets console access or CLI credentials

Note: Direct AD integration (without AD FS) is simpler: [aws.amazon](https://aws.amazon.com/blogs/architecture/field-notes-integrating-active-directory-federation-service-with-aws-iam-identity-center/)
  AWS Managed Microsoft AD → IAM Identity Center directly
  → Skip AD FS entirely for simpler setup
  → Enables WebAuthn, TOTP MFA, free SAML IdP for apps
```

### Permission Sets

```
A permission set = a collection of IAM policies assigned to users/groups per account:

Create permission set:
  Name: "DeveloperAccess"
  Policies:
    AWS managed: PowerUserAccess (full access except IAM)
    Customer managed: S3-prod-readonly
  Session duration: 8 hours

Assign:
  Account: "production" account
  User/Group: "Engineering" group (from AD or built-in)
  Permission set: DeveloperAccess

Result:
  All users in "Engineering" group
  → Can access "production" account with DeveloperAccess permissions
  → Role created in target account: AWSReservedSSO_DeveloperAccess_xxxxx

Assignment combinations:
  Group + Account + Permission Set → team access pattern
  User + Account + Permission Set → individual exception
  Group + Multiple accounts + Same permission set → broad team access
```

---

## 7. Directory Integration Map ⭐

How different AWS services connect to Active Directory:

```
AWS Managed Microsoft AD / Simple AD / AD Connector
         │
         ├── WorkSpaces Personal/Pools    ← domain join, user auth
         ├── EC2 Instances (Windows)      ← domain join, Kerberos, GPO
         ├── EC2 Instances (Linux)        ← domain join via SSSD + AD
         ├── RDS for SQL Server           ← Windows Authentication
         ├── FSx for Windows File Server  ← AD-integrated file shares, ACLs
         ├── FSx for NetApp ONTAP         ← SMB with AD auth
         ├── AWS Transfer Family          ← AD-based SFTP authentication
         └── IAM Identity Center          ← SSO for AWS accounts + SaaS apps
                   │
                   └── AWS Accounts (via permission sets)
                       SaaS apps (Salesforce, Slack, Jira via SAML)
                       Custom SAML apps
```

---

## 8. EC2 Domain Join ⭐

```
Windows EC2 instance → join to AWS Managed Microsoft AD or Simple AD:

Method 1: SSM document (recommended — automated, no manual steps):
  aws ssm send-command \
    --document-name "AWS-JoinDirectoryServiceDomain" \
    --parameters '{
      "directoryId": ["d-abc1234567"],
      "directoryName": ["corp.ibtisam-iq.com"],
      "dnsIpAddresses": ["10.0.1.10", "10.0.1.11"]
    }' \
    --instance-ids i-0123456789abcdef0

Method 2: EC2 launch configuration:
  Launch instance → Advanced → Domain join directory → select directory
  → EC2 joins domain automatically on first boot

Required:
  EC2 must be in SAME VPC as directory (or peered VPC)
  EC2 IAM role: AmazonSSMManagedInstanceCore + ds:* permissions
  Security group: EC2 can reach domain controller IPs on AD ports

After domain join:
  Users can log into EC2 with AD credentials (RDP with domain\username)
  GPOs apply from domain controllers to EC2 instance
  EC2 appears as computer object in AD

Linux domain join: [docs.aws.amazon](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html)
  Works with AWS Managed Microsoft AD
  Uses SSSD (System Security Services Daemon) + Kerberos
  Users: ssh -l "aduser@corp.ibtisam-iq.com" ec2-instance
```

---

## 9. RDS and FSx Active Directory Integration

### RDS SQL Server with AD Authentication

```
RDS SQL Server → joined to AWS Managed Microsoft AD:
  Windows Authentication: AD users connect to SQL Server without SQL password
  → "Trusted connection" from application
  → Connection string: Integrated Security=SSPI

Setup:
  Create IAM role for RDS with AmazonRDSDirectoryServiceAccess policy
  Associate RDS with AWS Managed Microsoft AD
  Create AD users → grant database permissions → connect

Supported:
  AWS Managed Microsoft AD only (not Simple AD, not AD Connector)
```

### FSx for Windows File Server

```
FSx for Windows natively integrates with AD:
  AWS Managed Microsoft AD: join FSx → share files with AD ACLs
  On-premises AD via AD Connector: FSx joins on-premises domain
  Self-managed AD: FSx joins your own AD in a VPC

Features:
  AD-based access control: users see only their authorized shares
  DFS Namespaces: \\corp\share → maps to FSx namespace
  Active Directory auditing: who accessed/modified which file
  Quota management per user/group
```

---

## 10. Hybrid Identity Architecture ⭐

```
Full hybrid identity pattern (most common enterprise scenario):

On-premises:
  Corporate AD (corp.ibtisam-iq.local)
  AD FS server (for SAML federation)
  Users authenticate to on-prem AD daily

AWS:
  AWS Managed Microsoft AD (aws.ibtisam-iq.com)
  Two-way forest trust → on-prem AD
  IAM Identity Center → connected to AWS Managed AD

User experience:
  On-prem user: john@corp.ibtisam-iq.local
  → Opens IAM Identity Center portal
  → Clicks "Sign in with corporate credentials"
  → Redirected to AD FS → enters AD password → MFA
  → SAML assertion → IAM Identity Center
  → Sees: production account (DeveloperAccess), staging account (AdminAccess)
  → Clicks production → temporary console session with exactly that permission set

  Same user → opens WorkSpaces client
  → Enters AD username + password → trust relationship
  → AWS Managed AD authenticates via trust → corporate AD validates
  → WorkSpace opens with user's persistent desktop

  Same user → opens EC2 Windows server (RDP)
  → Logs in: corp\john → Kerberos via trust → authenticated ✅
  → GPO from on-prem AD applies to EC2 instance

Everything flows from ONE identity: the on-premises AD user
```

---

## 11. Three-Way Comparison ⭐

| Feature | AWS Managed Microsoft AD | Simple AD | AD Connector |
|---------|------------------------|-----------|-------------|
| Technology | Real Microsoft AD | Samba 4 | Proxy only |
| Users | Up to 500K | Up to 5K | Existing on-prem |
| Trust relationships | ✅ Full | ❌ None | ❌ N/A (no cloud AD) |
| MFA (RADIUS) | ✅ Yes | ❌ No | ✅ Yes |
| Group Policy | ✅ Full | ✅ Basic | Via on-prem AD |
| Schema extensions | ✅ Yes | ❌ No | Via on-prem AD |
| PowerShell AD module | ✅ Yes | ❌ No | Via on-prem AD |
| AD Recycle Bin | ✅ Yes | ❌ No | N/A |
| gMSA | ✅ Yes | ❌ No | Via on-prem AD |
| Multi-region replication | ✅ Yes | ❌ No | ❌ No |
| EC2 domain join | ✅ Windows + Linux | ✅ Windows | ✅ Windows |
| User data in AWS? | ✅ Yes (cloud AD) | ✅ Yes | ❌ No (proxy only) |
| Works if on-prem down? | ✅ Yes (independent) | ✅ Yes | ❌ No (depends on prem) |
| Cost | $0.12–$0.31/hr | $0.05–$0.15/hr | $0.05–$0.15/hr |
| WorkSpaces included | Paid separately | ✅ Free | ✅ Free |

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Simple AD supports trust relationships | Simple AD **does NOT support trust** — use AWS Managed Microsoft AD |
| Simple AD supports MFA | Simple AD has **no MFA/RADIUS support** — use AWS Managed Microsoft AD |
| AD Connector stores users in AWS | AD Connector is a **proxy only** — zero user data stored in AWS |
| AD Connector works if VPN/DX goes down | AD Connector **requires connectivity** to on-premises — if VPN fails, no auth |
| AWS Managed Microsoft AD is included in WorkSpaces pricing | AWS Managed Microsoft AD is **separate cost** — only Simple AD and AD Connector are included in WorkSpaces |
| IAM Identity Center replaced IAM users | Identity Center manages **SSO and role assignment** — IAM still exists for service accounts and programmatic access |
| Two trust relationships can exist per domain pair | Only **one trust per domain pair** at a time — must delete and recreate to change direction |
| Forest trust covers only root domains | Forest trust covers **all domains in both forests** — external trust covers only specific domains |
| AD Connector can do schema extensions | AD Connector is a proxy — **all AD operations go to on-premises AD** |
| IAM Identity Center is per-account | Identity Center is an **Organizations-level service** — one instance manages all accounts |

---

## 13. Interview Questions Checklist

- [ ] What does Active Directory provide? (auth, authorization, GPO, DNS, LDAP, Kerberos)
- [ ] Three AWS Directory Service options — when to use each?
- [ ] What can Simple AD NOT do that AWS Managed Microsoft AD can? (trusts, MFA, schema, PowerShell)
- [ ] What is AD Connector? Does it store users in AWS?
- [ ] What happens if VPN fails when using AD Connector?
- [ ] Trust relationship types — External vs Forest? Incoming/Outgoing/Two-way?
- [ ] Prerequisites for trust between AWS Managed AD and on-premises? (VPN, DNS, ports)
- [ ] What is selective authentication for trust relationships?
- [ ] What is IAM Identity Center? How is it different from IAM?
- [ ] Three identity sources for IAM Identity Center?
- [ ] What is a permission set? How is it different from an IAM role?
- [ ] AD FS + IAM Identity Center SAML flow — seven steps
- [ ] How does EC2 domain join work? (SSM document)
- [ ] Which directory types support MFA via RADIUS? (AWS Managed AD + AD Connector)
- [ ] Which AWS services integrate with Active Directory?
- [ ] AWS Managed Microsoft AD Standard vs Enterprise — object limits?
- [ ] Which directory types are free with WorkSpaces? (Simple AD + AD Connector)
- [ ] Multi-region replication — which directory type supports it? (AWS Managed Microsoft AD only)
