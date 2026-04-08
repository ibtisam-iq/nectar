# AWS Systems Manager (SSM)

## 1. What is AWS Systems Manager?

AWS Systems Manager is an **operations management service** — a unified
interface for viewing operational data, automating tasks, managing
configuration, and maintaining compliance across your EC2 fleet and
on-premises infrastructure — without needing SSH or RDP access to
individual instances.

```
Without SSM:
  SSH into each server to run patches → manual, slow, audit-less
  Push config to 500 servers → script it yourself → error-prone
  "Run this command on all prod servers" → SSH loop → risky + no central log
  Secrets in .env files on servers → insecure

With SSM:
  Patch Manager: define patch baseline → SSM patches all instances on schedule
  Run Command: run shell script on 500 instances in parallel → full output log
  Session Manager: browser-based terminal → no SSH, no bastion, no open ports
  Parameter Store: centralized, encrypted config + secrets → app pulls at runtime
  Automation: define multi-step runbook → execute on schedule or on event trigger
  Inventory: see all software, services, network config across entire fleet
```

---

## 2. SSM Agent ⭐

```
Prerequisite: SSM Agent must be installed and running on managed nodes

Pre-installed on: Amazon Linux 2, Amazon Linux 2023, Amazon Linux (2017.09+),
                  Windows Server 2008+, Ubuntu 16.04+, RHEL 7+, SUSE 12+

Install manually (older/other OS):
  curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm -o ssm-agent.rpm
  sudo yum install -y ssm-agent.rpm
  sudo systemctl enable amazon-ssm-agent && sudo systemctl start amazon-ssm-agent

EC2 IAM requirements:
  Attach managed policy: AmazonSSMManagedInstanceCore
  → Allows: SSM API, S3 (for commands/logs), CloudWatch Logs

On-premises servers:
  Install SSM Agent → register with SSM as "hybrid" managed node
  → Same SSM capabilities as EC2 instances (patching, commands, session manager)
  → Appears in SSM Fleet Manager alongside EC2 instances

Network requirements:
  EC2 → needs access to SSM endpoints (public or VPC endpoint):
    ssm.region.amazonaws.com
    ec2messages.region.amazonaws.com
    ssmmessages.region.amazonaws.com
  For private subnets: create 3 VPC Interface Endpoints
  → No internet required → fully private fleet management
```

---

## 3. Session Manager ⭐

```
Browser or CLI-based terminal access to instances WITHOUT:
  ❌ SSH (port 22 closed — never needs to be open)
  ❌ Bastion hosts
  ❌ Key pairs (no PEM files)
  ❌ VPN
  ❌ Direct network access

How it works:
  SSM Agent on instance maintains outbound connection to SSM service
  You: AWS console → Systems Manager → Session Manager → Start Session
  → Browser terminal opens → full shell on instance
  Or: aws ssm start-session --target i-0123456789abcdef0

Logging: [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-aws-runpatchbaseline.html)
  All session activity (keystrokes + output) can be logged to:
    S3 (full session output)
    CloudWatch Logs (searchable)
  Audit: every session: who, which instance, when, what commands → CloudTrail

IAM control:
  iam:StartSession → controls who can start sessions
  Condition: ssm:resourceTag/Environment = prod
  → Only ops team can start sessions on prod instances

Port forwarding via Session Manager:
  aws ssm start-session \
    --target i-0123456789abcdef0 \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["3306"],"localPortNumber":["13306"]}'
  → Local port 13306 → tunnels to instance's port 3306 (MySQL)
  → No SSH needed, no SG change, fully audited

Best practice: [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-aws-runpatchbaseline.html)
  Remove all inbound SG rules for SSH (port 22) and RDP (3389)
  Use Session Manager exclusively → zero attack surface
  Enable CloudTrail + S3 session logging for full audit trail
```

---

## 4. Run Command ⭐

```
Execute commands on one or many managed instances simultaneously,
without opening any ports or using SSH:

Core concepts:
  Command Document: pre-built or custom script/command template
    AWS-RunShellScript:    run bash/shell commands on Linux
    AWS-RunPowerShellScript: run PowerShell on Windows
    AWS-RunPatchBaseline:  run patching (used by Patch Manager) [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-aws-runpatchbaseline.html)
    AWS-ConfigureAWSPackage: install/uninstall AWS packages
    AWS-UpdateSSMAgent:    update SSM Agent on instances

Target selection: [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-param-runcommand.html)
  By instance ID(s): --instance-ids i-111, i-222
  By tag(s): {"Key":"Environment","Values":["production"]}
  By resource group: all instances in an AWS Resource Group
  → Works on EC2 + on-premises managed nodes

Concurrency controls: [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-param-runcommand.html)
  Max concurrency: run on 50 instances at a time (or 20%)
  Error threshold: stop if 5 failures occur
  → Roll out command safely to large fleets

Example: apply hotfix to all prod servers:
  aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --parameters '{"commands":["yum update -y openssl"]}' \
    --targets '[{"Key":"tag:Environment","Values":["production"]}]' \
    --max-concurrency "20%" \
    --max-errors "5"

Output:
  Stored in S3 or CloudWatch Logs
  View per-instance: success/failure + stdout/stderr
  CloudTrail: records who ran what command on which instances
```

---

## 5. Patch Manager ⭐

```
Automate OS + application patching across your fleet:

Key concepts:
  Patch Baseline:
    Defines WHICH patches to install (by severity, classification, product)
    AWS-provided defaults: AmazonLinux2023DefaultPatchBaseline, etc.
    Custom baselines: define your own auto-approval rules
    Example baseline rule:
      Auto-approve: Critical severity, after 0-day delay
      Auto-approve: Important severity, after 7-day delay
      Reject: specific CVEs you've tested and excluded

  Patch Group:
    Tag instances with "Patch Group" key = "value"
    Associate a patch baseline to a patch group
    Example:
      Tag: Patch Group = ProdServers → use strict baseline (only critical + 7-day delay)
      Tag: Patch Group = DevServers  → use lenient baseline (all severity, 0-day delay)

  Maintenance Window:
    Schedule when patching runs: "every Sunday 2 AM–4 AM"
    Tasks registered: Run Command with AWS-RunPatchBaseline document [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-aws-runpatchbaseline.html)
    Rate control: 20% of fleet at a time → rolling patch deployment

  Patch compliance reporting:
    After patching: SSM reports each instance as "Compliant" or "Non-Compliant"
    View in: SSM Compliance dashboard OR AWS Config OR Security Hub

Scan mode vs Install mode: [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-aws-runpatchbaseline.html)
  Scan: check what patches are missing → report only (no install)
  Install: apply patches per baseline → reboot if required
  AWS-RunPatchBaseline document supports both via "Operation" parameter
```

---

## 6. Parameter Store ⭐

```
Centralized storage for configuration data and secrets:

Parameter types:
  String:        plain text value
  StringList:    comma-separated list of values
  SecureString:  encrypted with KMS (symmetric CMK or aws/ssm)

Tiers:
  Standard:
    Free (up to 10,000 parameters per account/region)
    Max value size: 4 KB
    No parameter policies (TTL/expiry)
  Advanced:
    $0.05/parameter/month (above 10,000 standard are free)
    Max value size: 8 KB
    Parameter policies: TTL (auto-expire old secrets), notifications

Hierarchy:
  /myapp/prod/database/password
  /myapp/prod/database/username
  /myapp/prod/api/stripe_key
  /myapp/dev/database/password

  GetParametersByPath: /myapp/prod/  → returns all parameters under prod
  → Application gets all config in ONE API call

Integration with Run Command: [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-param-runcommand.html)
  Parameter value referenced in command: {{ssm:/myapp/prod/db-password}}
  → SSM resolves parameter → injects into command → never visible in logs

IAM control:
  ssm:GetParameter by path or name
  ssm:PutParameter for specific paths
  KMS: kms:Decrypt required for SecureString parameters

Parameter Store vs Secrets Manager:
  Parameter Store: free for standard, config + secrets, no built-in rotation
  Secrets Manager: $0.40/secret/month, built-in rotation, cross-account easier
  Rule: static config → Parameter Store; DB passwords needing rotation → Secrets Manager
```

---

## 7. SSM Automation ⭐

```
Execute multi-step operational runbooks:
  Pre-built: AWS-StartEC2Instance, AWS-StopEC2Instance, AWS-CreateImage,
             AWS-PatchInstanceWithRollback, AWS-DisablePublicAccessForSecurityGroup
  Custom: write your own YAML runbook with sequential or parallel steps

Automation document steps:
  aws:executeAwsApi         → call any AWS API
  aws:runCommand            → run Run Command on instances
  aws:invokeLambdaFunction  → trigger Lambda
  aws:changeInstanceState   → start/stop/terminate instances
  aws:createSnapshot        → create EBS snapshot
  aws:waitForAwsResourceProperty → wait until condition met (e.g., instance running)
  aws:branch                → conditional branching

Example: pre-patch AMI creation runbook:
  Step 1: aws:createImage → snapshot current instance
  Step 2: aws:runCommand → run AWS-RunPatchBaseline
  Step 3: aws:waitForAwsResourceProperty → wait for patches complete
  Step 4: aws:createImage → create patched AMI
  Step 5: aws:changeInstanceState → start instance

Execution targets:
  Single resource: automate one EC2 instance
  Rate-controlled: apply to fleet (10% at a time)
  Triggered by: AWS Config remediation, EventBridge rule, Lambda, manual

Integrations:
  AWS Config → non-compliant resource → trigger SSM Automation [aws.amazon](https://aws.amazon.com/blogs/mt/manage-custom-aws-config-rules-with-remediation-using-conformance-packs/)
  EventBridge → scheduled trigger → Automation runs weekly
  CloudWatch Alarm → threshold exceeded → Automation scales resources
```

---

## 8. Inventory

```
Collect and view metadata from managed instances:

Data collected automatically:
  Installed applications (name, version, publisher)
  Running services
  Network configuration (IPs, MAC, DNS)
  Windows updates
  AWS components (SSM Agent version, etc.)
  Custom inventory (you define JSON schema + data)
  Files and registries (specify paths to track)

Query with: [docs.aws.amazon](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
  SSM Inventory dashboard → filter by any attribute
  AWS Config Advanced Query → SQL across entire fleet
  Example: "Show all instances running Apache version < 2.4.50"

Aggregation with Resource Data Sync:
  All inventory data → single S3 bucket → query with Athena
  → Build custom dashboards, compliance reports, asset management
```

---

## 9. Maintenance Windows

```
Define when SSM tasks run (patching, backups, scripts):
  Schedule: cron or rate expression
    cron(0 2 ? * SUN *) → every Sunday at 2 AM
    rate(7 days)
  Duration: max hours window can run
  Stop initiating: stop starting new tasks N hours before window closes
  Allow unregistered targets: run on instances not matching current targets

Register tasks:
  Run Command task: run AWS-RunPatchBaseline on patch group
  Automation task: run custom runbook
  Lambda task: invoke Lambda function
  Step Functions: start state machine execution

Rate control: [docs.aws.amazon](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-param-runcommand.html)
  10 instances at a time → rolling deployment
  Error threshold: stop if 3 failures → prevent cascading issues
```

---

## 10. SSM Features Summary

| Capability | Purpose | Key Use Case |
|-----------|---------|-------------|
| **Session Manager** | Browser terminal, no SSH | Secure access, no bastion hosts |
| **Run Command** | Run scripts fleet-wide | Hotfixes, config changes, ad-hoc tasks |
| **Patch Manager** | OS patch automation | Weekly patching with compliance reporting |
| **Parameter Store** | Config + secrets storage | App config, SecureString for secrets |
| **Automation** | Multi-step runbooks | Pre-approved operational procedures |
| **Inventory** | Fleet metadata collection | Asset management, compliance queries |
| **Maintenance Windows** | Scheduled task execution | Controlled patching windows |
| **Compliance** | Patch + config compliance | Dashboard of compliant vs non-compliant nodes |
| **Fleet Manager** | Single-pane EC2 + on-prem view | View all managed nodes in one console |
| **Distributor** | Package deployment | Deploy/update software packages at scale |

---

## 11. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Session Manager requires port 22 open | Session Manager requires **zero open inbound ports** — uses outbound HTTPS only |
| SSM works without IAM role on EC2 | EC2 needs **AmazonSSMManagedInstanceCore** policy attached to instance role |
| Patch Manager patches immediately on baseline change | Patches apply only during **Maintenance Windows** or explicit Run Command |
| Parameter Store standard tier has TTL/expiry | TTL/expiry parameter policies only available in **Advanced tier** |
| SSM Automation requires Lambda for all custom steps | Automation documents can call **AWS APIs directly** (aws:executeAwsApi) without Lambda |
| Run Command has no rollback mechanism | SSM Automation supports **rollback steps** — Run Command alone does not |
| Session logs are automatic | Session logging to S3/CloudWatch must be **explicitly configured** in Session Manager preferences |
| Parameter Store SecureString uses default encryption | SecureString uses **aws/ssm KMS key by default** — specify your CMK for extra control |

---

## 12. Interview Questions Checklist

- [ ] Session Manager — what ports must be open? (none — all outbound HTTPS)
- [ ] What IAM policy does EC2 need for SSM? (AmazonSSMManagedInstanceCore)
- [ ] Run Command — how do you target instances? (tag, instance ID, resource group)
- [ ] Patch baseline vs patch group — relationship?
- [ ] Parameter Store Standard vs Advanced — key differences? (size, TTL policies, cost)
- [ ] Parameter Store vs Secrets Manager — when to use each?
- [ ] SSM Automation — how does it integrate with AWS Config? (remediation trigger)
- [ ] How do you avoid SSH entirely in production? (Session Manager + remove SG port 22)
- [ ] How do you manage on-premises servers with SSM? (hybrid activation + SSM Agent install)
