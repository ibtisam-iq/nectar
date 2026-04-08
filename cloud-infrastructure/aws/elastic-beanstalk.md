# AWS Elastic Beanstalk

## 1. What is Elastic Beanstalk?

Elastic Beanstalk is AWS's **Platform-as-a-Service (PaaS)** — you upload
application code, and Elastic Beanstalk automatically handles provisioning,
load balancing, auto-scaling, health monitoring, and deployment. You retain
full control over the underlying AWS resources.

```
Without Elastic Beanstalk (manual):
  Create VPC → create EC2 → install runtime → configure ALB →
  create ASG → set scaling policies → configure CloudWatch alarms →
  deploy app → manage all of it forever

With Elastic Beanstalk:
  eb init + eb create → upload code → Beanstalk provisions everything
  You: write code + configure environment settings
  Beanstalk: everything else (infrastructure management)
  You still own all underlying resources (visible in EC2, ALB, ASG console)
```

### Elastic Beanstalk vs Other Services

| Service | Abstraction Level | Who Manages Infrastructure |
|---------|-----------------|--------------------------|
| **EC2** | IaaS — raw compute | You manage everything |
| **Elastic Beanstalk** | PaaS — code + config | Beanstalk manages infra, you manage code |
| **Lambda** | FaaS — functions | AWS manages everything |
| **Lightsail** | VPS — simplified | Simplified but you still choose bundle |
| **ECS/EKS** | Containers — orchestration | You manage containers |

> Elastic Beanstalk is **free** — you pay only for the underlying AWS
> resources it provisions (EC2, ALB, RDS, etc.).

---

## 2. Core Concepts ⭐

### Application

```
Top-level container — represents your entire application (like a project folder)
Contains: multiple environments + application versions

Example:
  Application: "ibtisam-portfolio"
    ├── Environment: production  (running v2.1.0)
    ├── Environment: staging     (running v2.2.0-beta)
    └── Application Versions:
         ├── v2.2.0-beta (new code being tested)
         ├── v2.1.0 (current production)
         └── v2.0.0 (previous stable)
```

### Application Version

```
Labeled reference to deployable code:
  Source: S3 object (ZIP or WAR file)
  Created: automatically when you deploy, or manually

Stored in S3 — Beanstalk retrieves during deployment
Max versions per application: 1,000 (configurable lifecycle policy)
```

### Environment

```
Running instance of your application on AWS infrastructure:
  EC2 instances + ALB + ASG + security groups + CloudWatch alarms
  All created and managed by Elastic Beanstalk

Two environment types:
  Web Server → handles HTTP/HTTPS traffic (ALB + EC2)
  Worker     → processes background jobs from SQS queue (EC2 + SQS)
```

---

## 3. Supported Platforms ⭐

Elastic Beanstalk provides managed **platform versions** (runtime + OS):

```
Languages + runtimes:
  Python   (3.11, 3.10, 3.9)
  Node.js  (22, 20, 18)
  Java     (Corretto 21, 17, 11, 8)
  .NET     (Core on Linux, Windows Server)
  PHP      (8.3, 8.2, 8.1)
  Ruby     (3.3, 3.2, 3.1)
  Go       (1.22, 1.21)

Containers:
  Docker (single container)
  Docker (multi-container via ECS)
  Custom platform (build your own with Packer)

AWS manages:
  Runtime security patches
  OS updates
  Platform version updates (you choose when to upgrade)
```

---

## 4. Environment Tiers ⭐

### Web Server Environment

```
Architecture:
  Route 53 (CNAME) → Elastic Load Balancer → Auto Scaling Group → EC2 instances

Handles: HTTP/HTTPS requests from users
Load balancer types: Application LB, Network LB, Classic LB
Scaling: based on request metrics (latency, request count)

Use case: web applications, REST APIs, any HTTP-based service
```

### Worker Environment

```
Architecture:
  SQS Queue → EC2 instances (no load balancer)

Worker daemon runs on EC2 → polls SQS → calls your app's HTTP endpoint (localhost)
Your app processes the job → returns 200 → worker daemon deletes SQS message
Failed job → visibility timeout expires → retried → eventually goes to DLQ

Handles: background tasks, long-running jobs, async processing

Use case:
  Video transcoding, report generation, email sending, data processing
  Periodic tasks (cron.yaml — EB worker cron scheduler)
```

---

## 5. Deployment Policies ⭐

Five strategies for deploying new application versions:

### 1. All at Once (Default)

```
Deploy new version to ALL instances simultaneously

Timeline:
  All instances → stop serving → update → start serving new version
  Brief complete downtime during deployment

Characteristics:
  Deploy time:    Fastest ⚡
  Downtime:       Yes — all instances update simultaneously
  Rollback:       Manual redeploy of previous version
  Cost:           No extra instances
  Use case:       Development/test environments where downtime is acceptable

Example: 4 instances → all 4 updated at once → ~2 min downtime
```

### 2. Rolling

```
Deploy new version in batches — one batch at a time

Timeline:
  Batch 1 (1 of 4 instances) → update → healthy →
  Batch 2 (1 of 4 instances) → update → healthy →
  Batch 3 (1 of 4 instances) → update → healthy →
  Batch 4 (1 of 4 instances) → update → healthy ✅

Characteristics:
  Deploy time:    Slower (batched)
  Downtime:       No (some capacity reduced during each batch)
  Capacity:       REDUCED during deployment (n - batch_size instances serving)
  Rollback:       Manual redeploy (both old + new versions running simultaneously)
  Cost:           No extra instances
  Use case:       Production where some capacity reduction is acceptable

Configure:
  Batch size: fixed count (e.g., 1) or percentage (e.g., 25%)
```

### 3. Rolling with Additional Batch

```
Like Rolling, but first launches EXTRA instances before rolling

Timeline:
  Launch 1 new instance (extra batch) → deploy new version there →
  Then roll through existing instances in batches

Characteristics:
  Deploy time:    Slower (launch + batched)
  Downtime:       No
  Capacity:       FULL capacity maintained throughout (extra instances compensate)
  Rollback:       Manual redeploy
  Cost:           Small extra cost (additional instances during deployment only)
  Use case:       Production where BOTH zero-downtime AND full capacity required
```

### 4. Immutable

```
Deploy new version to a completely FRESH set of instances

Timeline:
  Create new Auto Scaling group → deploy new version to new instances →
  Health check new instances → swap new ASG in → terminate old instances

Characteristics:
  Deploy time:    Slowest (full new fleet)
  Downtime:       No
  Capacity:       DOUBLED during deployment (old + new instances running)
  Rollback:       Fastest — terminate new instances (old still running untouched)
  Cost:           Higher (double instances during deployment)
  Use case:       Production requiring safest deployment + fast rollback

Key safety: old instances never touched → rollback = just terminate new ones [docs.aws.amazon](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.deploy-existing-version.html)
```

### 5. Traffic Splitting (Canary)

```
Deploy new version to fresh instances + split traffic between old and new

Timeline:
  Launch new instances → deploy new version →
  Send X% of traffic to new version for N minutes →
  If healthy: shift 100% to new version →
  If unhealthy: automatic rollback (shift traffic back to old version)

Characteristics:
  Deploy time:    Slowest
  Downtime:       No
  Rollback:       Automatic (traffic redirected back)
  Cost:           Higher (double instances during evaluation)
  Use case:       Canary testing new version on real production traffic

Configure: [docs.aws.amazon](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.rolling-version-deploy.html)
  Traffic split: percentage to send to new version (e.g., 10%)
  Evaluation time: minutes to wait before shifting 100% (e.g., 15 minutes)
```

### Deployment Policy Comparison ⭐

| Policy | Downtime | Full Capacity | Deploy Speed | Rollback | Cost |
|--------|---------|--------------|-------------|---------|------|
| All at once | ✅ Yes | No (all down) | Fastest | Manual redeploy | None extra |
| Rolling | No | No (reduced) | Medium | Manual redeploy | None extra |
| Rolling + extra batch | No | ✅ Yes | Slow | Manual redeploy | Small extra |
| Immutable | No | ✅ Yes (2×) | Slowest | Fastest (terminate new) | Double during deploy |
| Traffic splitting | No | ✅ Yes (2×) | Slowest | Automatic | Double during eval |

---

## 6. Blue/Green Deployments ⭐

```
Not a built-in deployment policy — achieved using two separate environments:

Blue environment:  PRODUCTION — running current stable version (v1)
Green environment: STAGING    — new version deployed and tested (v2)

Steps:
  1. Clone blue environment → create green
  2. Deploy new version to green
  3. Test green thoroughly (no production traffic yet)
  4. Swap environment URLs (Route 53 weighted routing OR Beanstalk CNAME swap)
     → Green becomes production instantly
     → Blue becomes standby (old version)
  5. After validation: terminate blue (or keep as emergency rollback)

Beanstalk URL swap:
  eb swap production-env --destination_name staging-env
  → Swaps CNAME records: production domain now points to green environment
  → Instant swap — DNS propagation only (no new instances)

Benefits:
  Zero downtime
  Full traffic test before cutover
  Instant rollback: swap CNAMEs back
  Blue kept warm: rollback in seconds [oneuptime](https://oneuptime.com/blog/post/2026-02-12-setup-elastic-beanstalk-web-application-deployment/view)
```

---

## 7. Configuration: .ebextensions ⭐

`.ebextensions` is a directory in your app bundle for declarative Beanstalk
configuration — customize the environment beyond standard settings:

```
Project structure:
  my-app/
    .ebextensions/
      01_packages.config   ← install system packages
      02_files.config      ← create config files
      03_commands.config   ← run commands before app starts
      04_container.config  ← application server settings
    application/
      app.py / index.js / etc.
    requirements.txt / package.json
```

```yaml
# .ebextensions/01_packages.config
packages:
  yum:
    git: []
    gcc: []
    postgresql-devel: []

# .ebextensions/02_files.config
files:
  "/etc/myapp/config.json":
    mode: "000644"
    owner: root
    group: root
    content: |
      {
        "environment": "production",
        "logLevel": "info"
      }

# .ebextensions/03_commands.config
commands:
  01_migrate_database:
    command: "python manage.py migrate"
    leader_only: true    # ← run only on one instance (not all)

# .ebextensions/04_environment.config
option_settings:
  aws:elasticbeanstalk:application:environment:
    DJANGO_SETTINGS_MODULE: myapp.settings.production
  aws:autoscaling:asg:
    MinSize: 2
    MaxSize: 10
  aws:elasticbeanstalk:command:
    DeploymentPolicy: Immutable
    BatchSizeType: Percentage
    BatchSize: 25
```

---

## 8. Beanstalk and RDS ⭐

Two ways to use RDS with Elastic Beanstalk:

### Option 1: RDS Inside Beanstalk Environment

```
Beanstalk creates + manages the RDS instance as part of the environment

Advantage: automatic connection string injected as env vars
Disadvantage: RDS deleted when environment is deleted ❌ (data loss!)

Only for: development/test environments
NEVER for production — deleting env = deleting database
```

### Option 2: RDS Outside Beanstalk (Recommended for Production)

```
Create RDS instance independently in RDS console or CloudFormation
Configure Beanstalk environment to connect via environment variables:
  RDS_HOSTNAME, RDS_PORT, RDS_DB_NAME, RDS_USERNAME, RDS_PASSWORD

Advantage:
  Database lifecycle independent of Beanstalk environment ✅
  Can use same database across multiple environments (staging shares prod DB if needed)
  Database survives environment termination ✅
  Can attach RDS to multiple Beanstalk environments

Security:
  Beanstalk EC2 security group → allowed inbound on DB port → RDS security group
```

---

## 9. Beanstalk Environment Configuration

```
Environment properties (env vars injected into app):
  Console: Environment → Configuration → Software → Environment properties
  .ebextensions: option_settings → aws:elasticbeanstalk:application:environment

Instance settings:
  Instance type: t3.micro → m6i.4xlarge (any EC2 type)
  Root volume: size and type
  EC2 key pair: for SSH access

Scaling:
  Min/max instances in ASG
  Scale-out metric: CPUUtilization, RequestCount, NetworkOut, custom metric
  Scale-in cooldown

Load balancer:
  Type: ALB / NLB / Classic
  HTTPS: attach ACM certificate
  Idle timeout

Health checks:
  Enhanced health: detailed per-instance health (recommended)
  Basic health: ELB health check only

Managed platform updates:
  Beanstalk can auto-apply minor/patch platform updates
  Choose maintenance window
```

---

## 10. EB CLI ⭐

```bash
# Install
pip install awsebcli

# Initialize application in current directory
eb init my-application \
  --platform "Python 3.11 running on 64bit Amazon Linux 2023" \
  --region us-east-1

# Create environment (provisions all AWS resources)
eb create production \
  --instance-type t3.small \
  --min-instances 2 \
  --max-instances 10 \
  --elb-type application

# Deploy new version
eb deploy production

# Open application URL in browser
eb open

# View logs (last 100 lines)
eb logs

# SSH into first instance
eb ssh production

# Swap environments (blue/green)
eb swap production --destination_name staging

# Scale manually
eb scale 5 production   # set to 5 instances

# Terminate environment (deletes all resources)
eb terminate production

# Environment status + health
eb status
eb health --refresh
```

---

## 11. Beanstalk Monitoring and Logs

```
Enhanced Health Monitoring:
  Per-instance health dashboard
  Request metrics: P50, P75, P95, P99 latency
  HTTP response code breakdown (2xx, 3xx, 4xx, 5xx)
  Instance status checks

CloudWatch integration:
  Beanstalk auto-creates CloudWatch alarms
  Custom metrics from app → CloudWatch → Beanstalk health dashboard

Log retrieval:
  eb logs                    → last 100 lines from all instances
  eb logs --all              → full logs
  eb logs --zip              → download compressed

Log streaming to CloudWatch Logs:
  Enable: Configuration → Software → Log streaming → ON
  Log groups:
    /aws/elasticbeanstalk/environment-name/var/log/nginx/error.log
    /aws/elasticbeanstalk/environment-name/var/log/app.log
```

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Beanstalk costs money itself | Beanstalk is **free** — you pay for the EC2/ALB/RDS it provisions |
| Delete Beanstalk environment to remove app | Terminating environment **deletes ALL resources** including any in-environment RDS |
| Put RDS inside Beanstalk environment for production | Always create RDS **outside Beanstalk** for production — independent lifecycle |
| All-at-once is safe for production | All-at-once causes **complete downtime** — use Rolling, Immutable, or Traffic Splitting |
| Immutable rollback is slow | Immutable rollback is **fastest** — just terminate new instances; old ones never changed |
| .ebextensions runs every request | `.ebextensions` commands run **during deployment** — not per request |
| Blue/Green is a built-in Beanstalk policy | Blue/Green is achieved via **two separate environments + CNAME swap** — not a built-in policy |
| Beanstalk manages your code repository | Beanstalk receives a **ZIP file from S3** — use CodePipeline for full CI/CD integration |
| Traffic splitting = manual blue/green | Traffic splitting is **automated canary with configurable percentage + auto-rollback** |
