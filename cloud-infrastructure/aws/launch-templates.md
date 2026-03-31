# AWS Launch Templates — Complete Reference

## 1. What is a Launch Template?

A Launch Template is a **reusable, versioned configuration blueprint** that defines
every parameter needed to launch an EC2 instance — so you never configure the
same settings twice.

```
Without LT:                        With LT:
Every launch: select AMI           Define once → reference everywhere
             choose type    →      ASG, Spot Fleet, EC2 Fleet all reuse it
             set network           Version it → safe updates + rollback
             add SG
             add user data
             (error-prone, slow)
```

---

## 2. What a Launch Template Contains

| Category | Settings |
|---------|---------|
| **Compute** | AMI ID, instance type (t3.medium, m5.large…), placement group |
| **Networking** | VPC, subnet, security groups, public IP assignment, multiple ENIs |
| **Storage** | EBS volumes (size, type, encrypted, throughput, delete-on-termination) |
| **Access** | Key pair, IAM instance profile (role) |
| **Metadata** | IMDSv1 vs IMDSv2 enforcement, hop limit |
| **Startup** | User data script (base64 encoded, max 16 KB) |
| **Operations** | Tags, shutdown behavior, termination protection, detailed monitoring |
| **Advanced** | Hibernation, EFA (Elastic Fabric Adapter), capacity reservation, tenancy |
| **Credits** | T-instance CPU credit specification (standard/unlimited) |

> Every field is **optional** — you can leave fields blank and provide them at
> launch time, or inherit from a base template via override.

---

## 3. Launch Template vs AMI — The Critical Distinction ⭐

| Aspect | AMI | Launch Template |
|--------|-----|----------------|
| **What it is** | Snapshot of OS + installed software | Configuration for HOW to launch |
| **Contains OS** | ✅ | ✅ (by referencing an AMI) |
| **Contains networking** | ❌ | ✅ (VPC, subnet, SG) |
| **Contains instance type** | ❌ | ✅ |
| **Contains user data** | ❌ | ✅ |
| **Contains IAM role** | ❌ | ✅ |
| **Versioned** | ✅ (immutable snapshots) | ✅ (numbered versions) |

```
AMI = WHAT the machine looks like (disk state, OS, software)
Launch Template = HOW to run the machine (network, size, security, scripts)

Production launch:
  AMI: ami-0c55b159cbfafe1f0  (Ubuntu 24.04 + Nginx pre-installed)
    ↓ referenced inside ↓
  Launch Template v3: t3.medium, sg-app, iam-web-role, user_data.sh
    ↓ used by ↓
  Auto Scaling Group: min=2, max=10, desired=3
```

---

## 4. Versioning ⭐

Every Launch Template starts at version 1. New versions are numbers, not names.

```
v1: AMI=ami-abc, type=t2.micro, sg=sg-old    ← original
v2: AMI=ami-abc, type=t3.micro, sg=sg-old    ← instance type upgrade
v3: AMI=ami-xyz, type=t3.micro, sg=sg-new    ← new AMI + new SG
```

### Default vs Latest Version

| Setting | Meaning |
|---------|---------|
| `$Default` | Explicitly marked — your stable/production version |
| `$Latest` | Always points to the newest version number |

> **Best practice:** Set `$Default` to your tested/stable version.
> Use `$Latest` only in dev/test. ASG and Spot Fleet reference `$Default` unless configured otherwise.

### Instance Refresh — Rolling Update via Versioning ⭐

When you publish a new Launch Template version (e.g., updated AMI for OS patch),
ASG can **Instance Refresh** — rolling replace all existing instances:

```
LT v2 → v3 (new AMI with security patch)
  ↓
Instance Refresh launched:
  Phase 1: Launch new instances (v3), wait for health check ✅
  Phase 2: Terminate old instances (v2)
  Phase 3: Repeat until all instances run v3
  (configurable: min healthy %, warmup time, checkpoint)
```

> Instance Refresh is the correct way to update a running ASG fleet.
> Never manually terminate and replace instances in production.

---

## 5. Launch Template vs Launch Configuration ⭐ (Deprecation)

Launch Configuration was the original ASG blueprint — it is now deprecated.

### Deprecation Timeline

| Date | Event |
|------|-------|
| January 1, 2023 | No new EC2 instance types available in Launch Configurations |
| April 1, 2023 | New accounts cannot create LCs in EC2 Console |
| October 1, 2024 | New accounts cannot create LCs via API either |
| **Now (2026)** | Launch Configurations exist only in legacy accounts |

### Feature Comparison

| Feature | Launch Configuration | Launch Template |
|---------|---------------------|----------------|
| Versioning | ❌ No | ✅ Yes |
| New EC2 instance types | ❌ Not supported after Jan 2023 | ✅ All types |
| Multiple network interfaces | ❌ No | ✅ Yes |
| Multiple EBS volumes | ❌ Limited | ✅ Full support |
| IMDSv2 enforcement | ❌ No | ✅ Yes |
| Spot Fleet support | ✅ | ✅ |
| Mixed Instances Policy | ❌ No | ✅ Yes |
| T-instance credit spec | ❌ No | ✅ Yes |
| Capacity Reservations | ❌ No | ✅ Yes |
| Status | **Deprecated** | **Current standard** |

> Migration: use the AWS Console "Copy to launch template" — one-click conversion
> from an existing Launch Configuration to a Launch Template.

---

## 6. Mixed Instances Policy (Advanced ASG Feature)

With Launch Template, an ASG can use **multiple instance types** — maximizing
availability and minimizing cost by using a mix of On-Demand and Spot:

```yaml
Auto Scaling Group:
  Launch Template: base (defines AMI, networking, SG, user data)
  Mixed Instances Policy:
    On-Demand base: 2             ← always keep 2 On-Demand (guaranteed)
    On-Demand percentage: 20%     ← 20% of scaling = On-Demand, 80% = Spot
    Instance overrides:
      - InstanceType: t3.large    (primary)
      - InstanceType: t3a.large   (fallback)
      - InstanceType: m5.large    (fallback)
      - InstanceType: m5a.large   (fallback)
```

> ASG tries instance types in priority order — moves to next if capacity unavailable.
> This dramatically improves Spot availability — if one type's capacity is exhausted,
> ASG uses the next type automatically.

---

## 7. IMDSv2 Enforcement — Security Requirement ⭐

The Instance Metadata Service (IMDS) at `169.254.169.254` exposes:
- IAM role credentials
- Instance identity
- User data
- Network config

**IMDSv1 (old — vulnerable):** Anyone who can send HTTP from inside the instance
can query `169.254.169.254` and steal IAM credentials. SSRF attacks exploit this.

**IMDSv2 (secure):** Requires a session token obtained via PUT request first.
SSRF attacks cannot follow the PUT → GET sequence.

```
IMDSv1 (vulnerable):
  curl http://169.254.169.254/latest/meta-data/iam/security-credentials/my-role
  → Returns credentials (any code/SSRF can do this) ❌

IMDSv2 (secure):
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
          -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  curl http://169.254.169.254/latest/meta-data/... \
       -H "X-aws-ec2-metadata-token: $TOKEN"
  → Only code that can send PUT first gets the token ✅
```

**Enforce in Launch Template:**
```
Metadata options:
  IMDSv2: Required (httpTokens = required)
  Hop limit: 1  (prevents container-to-host metadata access)
```

> Launch Templates are the **only way to enforce IMDSv2 at scale** across ASG fleets.
> This is a security compliance requirement for any production EC2 fleet.

---

## 8. User Data ⭐

Script that runs **once** at first boot on the instance.

```bash
#!/bin/bash
# User data script example (always starts with shebang)
yum update -y
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx
echo "SERVER_ENV=production" >> /etc/environment
aws s3 cp s3://my-bucket/app.tar.gz /opt/app/
```

| Property | Detail |
|----------|--------|
| Encoding | Must be **base64 encoded** (console does this automatically) |
| Max size | **16 KB** |
| Runs as | root |
| Runs when | First launch only (by default) — can configure to run on every boot |
| Logging | `/var/log/cloud-init-output.log` |

### AMI-baking vs User Data — When to Use Which

| Approach | Method | Best For |
|---------|--------|---------|
| **AMI baking** | Pre-install everything in AMI | Fast launch (no install time), complex software |
| **User data** | Install/configure at boot | Dynamic config (environment variables, secrets), simple packages |
| **Hybrid** | AMI has base software, user data does config | Production standard — fast + flexible |

```
AMI: Ubuntu + Nginx + Java (pre-installed, tested)
User data: pulls latest app version from S3, writes environment config
Result: launch time = ~30 seconds (no package installs)
```

---

## 9. Where Launch Templates Are Used

| Service | How Used |
|---------|---------|
| **EC2 Auto Scaling Group** | Required — defines what instances to launch |
| **EC2 Fleet** | Mixed instance type fleet management |
| **Spot Fleet** | Spot instance fleet with fallback types |
| **Direct EC2 Launch** | Launch single instance from template (no manual config) |
| **CloudFormation** | `AWS::EC2::LaunchTemplate` resource |
| **Terraform** | `aws_launch_template` resource |
| **EKS Node Groups** | Managed node groups can use LT for custom AMI |
| **AWS Batch** | Compute environments (migrated from LC in 2024) |

---

## 10. Full Workflow — Production Web App

```
Step 1: Create custom AMI
  - Launch base EC2
  - Install: Nginx, Node.js, dependencies
  - Test
  - Actions → Create Image → ami-custom-webapp

Step 2: Create Launch Template
  Name: webapp-lt
  AMI: ami-custom-webapp
  Instance type: t3.medium
  Security Group: sg-webapp (allow 80, 443 from ALB)
  IAM role: ec2-webapp-role (S3 read, Secrets Manager read)
  IMDSv2: Required
  User data:
    #!/bin/bash
    SECRET=$(aws secretsmanager get-secret-value --secret-id prod/db-password)
    echo "DB_PASSWORD=$SECRET" >> /etc/environment
    systemctl start webapp
  Tags: Env=Production, App=WebApp

Step 3: Create Auto Scaling Group
  Launch Template: webapp-lt $Default
  Min: 2, Max: 10, Desired: 3
  Target Group: webapp-tg (attached to ALB)
  Scaling Policy: target 60% CPU

Step 4: Update AMI (security patch needed)
  - Create new AMI with patch → ami-custom-webapp-v2
  - Create LT version 2: update AMI to ami-custom-webapp-v2
  - Set v2 as $Default
  - Start Instance Refresh on ASG → rolling replace ✅
```

---

## 11. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Launch Configurations are still fine | **Deprecated** — no new instance types since Jan 2023; new accounts blocked since Oct 2024 |
| AMI contains networking config | AMI only stores disk state — networking lives in Launch Template |
| $Latest version is always stable | $Latest = newest version (may be untested); use `$Default` for production |
| User data runs on every reboot | User data runs **once** at first boot by default |
| User data size has no limit | Max **16 KB** — keep scripts small, pull large configs from S3 |
| IMDSv1 vs IMDSv2 doesn't matter | IMDSv1 is vulnerable to SSRF — always enforce IMDSv2 in production |
| One template per instance type | One LT + Mixed Instances Policy supports many instance types |
| Instance Refresh = terminate and recreate | Instance Refresh is a **managed rolling replacement** — not the same as manual termination |
| Launch Template tied to one service | Same LT used by EC2, ASG, Spot Fleet, EC2 Fleet, EKS |

---

## 12. Interview Questions Checklist

- [ ] What is a Launch Template? What problem does it solve?
- [ ] AMI vs Launch Template — key difference?
- [ ] What does a Launch Template contain? (Name 8+ settings)
- [ ] What is versioning in Launch Templates? `$Default` vs `$Latest`?
- [ ] What is Instance Refresh? How does it use versioning?
- [ ] When was Launch Configuration deprecated? What are the milestones?
- [ ] Name 5 features that LT has but LC doesn't
- [ ] What is Mixed Instances Policy? How does it improve Spot availability?
- [ ] What is user data? When does it run? What are its limits?
- [ ] AMI baking vs user data — when to use each? Hybrid pattern?
- [ ] What is IMDSv2? Why is IMDSv1 a security risk?
- [ ] How do you enforce IMDSv2 at scale across an ASG fleet?
- [ ] What does `hop limit: 1` do in metadata options?
- [ ] What services use Launch Templates? (Name 6+)
- [ ] Walk through building a production ASG from scratch using Launch Template

## Nectar
