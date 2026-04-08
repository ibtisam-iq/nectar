# Amazon Inspector

## 1. What is Amazon Inspector?

Amazon Inspector is a **continuous, automated vulnerability management service**
that scans your AWS workloads for software vulnerabilities (CVEs) and
unintended network exposure, providing risk-prioritized findings that help
you remediate the most critical issues first.

```
Inspector answers:
  "Does my EC2 instance have a critical CVE in its installed packages?"
  "Is my container image running a vulnerable version of OpenSSL?"
  "Is my Lambda function using a library with a known exploit?"
  "Is port 22 on my EC2 instance reachable from the internet?"

Inspector does NOT:
  Fix vulnerabilities (it reports them — you patch/update)
  Scan application logic/code for bugs (that's code review / SAST tools)
  Detect active threats or malicious activity (that's GuardDuty)
  Check architecture best practices (that's Trusted Advisor)
```

> **Inspector Classic (v1) is being retired May 20, 2026** — migrate to
> Inspector v2 (current version). All new content refers to Inspector v2.

---

## 2. Inspector Classic vs Inspector v2 ⭐

| | Inspector Classic | Inspector v2 (Current) |
|--|-----------------|----------------------|
| Retirement | May 20, 2026 ❌ | Active ✅ |
| Scanning model | Manual assessment runs scheduled by you | Continuous, automatic, always-on |
| Target selection | Manual (you define targets) | Automatic (all supported resources) |
| Trigger | You run assessment → one-time scan | New resource → auto-scanned instantly |
| New CVE published | No re-scan (you must re-run) | Automatically re-scans all affected resources |
| Scope | EC2 only | EC2 + ECR + Lambda |
| Agent | Required on every EC2 | SSM Agent (already on most instances) |
| SBOM | ❌ No | ✅ Yes |
| CI/CD integration | ❌ Limited | ✅ Yes (Jenkins, CodePipeline) |
| Organization support | Limited | ✅ Full Organizations integration |

---

## 3. What Inspector Scans ⭐

### EC2 Instances

```
Scanning methods — hybrid approach:

Agent-based (SSM-managed instances):
  Uses AWS Systems Manager (SSM) Agent already installed on instance
  → Collects software inventory: installed packages, versions, OS
  → Inspector matches against CVE database
  → Real-time: scans immediately when new package installed
  → Deep package analysis (application-level packages too)
  Requirement: SSM Agent running + AmazonSSMManagedInstanceCore IAM role

Agentless (non-SSM instances): [cloudkeeper](https://www.cloudkeeper.com/insights/blog/amazon-inspector-classic-support-ends-2026-migrate-seamlessly)
  Uses EBS snapshot analysis
  → Inspector takes EBS snapshot → analyzes OS and application packages
  → No agent required on instance
  → Runs at least every 24 hours (not real-time like agent-based)
  → Fallback for instances where SSM cannot be installed

Network reachability:
  Analyzes VPC config: security groups, NACLs, route tables, IGW
  → Identifies if specific ports are reachable from internet
  → "Port 22 on i-1234 is reachable from 0.0.0.0/0"
  No agent needed for network reachability checks
```

### ECR Container Images

```
Triggers:
  Image pushed to ECR → Inspector scans immediately (on-push scanning)
  New CVE published → Inspector re-scans all images in ECR automatically
  Image re-pushed or tag updated → re-scanned

What it scans:
  OS packages (Alpine, Ubuntu, Amazon Linux base layers)
  Application packages (npm, pip, gem, maven, go modules)
  Both layers scanned independently

Integration:
  Findings shown in ECR console alongside the image
  Block image pull if CRITICAL CVE found (via ECR lifecycle policy + Inspector)
  CI/CD: scan image in pipeline before deploying to ECS/EKS
```

### Lambda Functions

```
Triggers:
  Lambda function created or updated → Inspector scans immediately
  New CVE published → Inspector re-scans all Lambda functions

What it scans:
  Lambda deployment package: application dependencies
    Python: requirements.txt packages (boto3, requests, etc.)
    Node.js: package.json dependencies
    Java: Maven/Gradle dependencies
  Lambda layer dependencies (scanned separately)

Does NOT scan:
  Lambda function code logic
  Environment variable values
  Secrets in code
```

---

## 4. Finding Types

```
1. Package Vulnerability Findings
   A specific CVE found in an installed package version
   Fields:
     CVE ID:       CVE-2024-12345
     Package:      openssl 1.1.1t
     Fixed version: openssl 1.1.1u  ← upgrade path
     CVSS score:   9.8 (Critical)
     EPSS score:   0.94 (94% probability of exploitation in next 30 days)
     Exploit available: YES/NO
   Windows EC2: reported as KB IDs (e.g., KB5023697) instead of CVE IDs [docs.aws.amazon](https://docs.aws.amazon.com/inspector/latest/user/findings-types.html)
   A KB update covering multiple CVEs → single KB finding with highest CVSS [docs.aws.amazon](https://docs.aws.amazon.com/inspector/latest/user/findings-types.html)

2. Network Reachability Findings (EC2 only)
   Identifies unintended network exposure:
     "Port 22 reachable from internet via SG + NACL + route table analysis"
     "Port 3306 (MySQL) reachable from internet — should be private"

3. Code Vulnerability Findings (Lambda)
   Application-level dependency vulnerabilities
```

---

## 5. Severity and Risk Scoring ⭐

Inspector uses a **multi-factor risk score** — not just raw CVSS:

```
Severity levels (5 tiers): [docs.aws.amazon](https://docs.aws.amazon.com/inspector/latest/user/findings-understanding-severity.html)
  CRITICAL     → Inspector score 9.0–10.0
  HIGH         → Inspector score 7.0–8.9
  MEDIUM       → Inspector score 4.0–6.9
  LOW          → Inspector score 0.1–3.9
  INFORMATIONAL → score 0.0

Inspector Score = AWS-adjusted risk score (0.0–10.0)
  Based on multiple factors beyond raw CVSS:
    CVSS base score           → severity of vulnerability itself
    EPSS score                → empirical probability of exploit in 30 days
    Exploit availability      → public exploit code exists? (PoC / weaponized)
    Network reachability      → is the affected resource internet-facing?
    Asset context             → is this a production vs dev resource?

Example: same CVE on two different resources:
  CVE-2024-5678 on internet-facing EC2: Inspector score = 9.5 (CRITICAL)
  CVE-2024-5678 on private EC2 (no internet route): Inspector score = 6.2 (MEDIUM)
  → Same CVE, different risk based on exposure context

EPSS (Exploit Prediction Scoring System): [cloudkeeper](https://www.cloudkeeper.com/insights/blog/amazon-inspector-classic-support-ends-2026-migrate-seamlessly)
  0.0–1.0 probability score
  0.94 = 94% chance this CVE will be actively exploited in next 30 days
  Prioritize patching high-EPSS CVEs even if CVSS is "only" Medium
```

---

## 6. Inspector Console — Key Views

```
Dashboard:
  Total active findings by severity
  Most impacted resources (EC2 instances with most findings)
  Top CVEs across your environment
  Coverage: % of resources being actively scanned

Findings view:
  Filter by: severity, resource type, CVE ID, fix availability
  Group by: resource, CVE, account (for Organizations)
  Export: JSON / CSV

Coverage view:
  Shows which resources ARE and ARE NOT being scanned
  Why not scanning: "SSM agent not running", "resource not supported"
  Fix coverage gaps by installing SSM agent or enabling agentless scanning

Software Bill of Materials (SBOM): [cloudkeeper](https://www.cloudkeeper.com/insights/blog/amazon-inspector-classic-support-ends-2026-migrate-seamlessly)
  Full inventory of all packages across EC2, ECR, Lambda
  Export SBOM per resource or account-wide
  Format: CycloneDX or SPDX
  Use for: compliance, supply chain security, audit
```

---

## 7. Inspector + Organizations ⭐

```
Delegate Inspector administration to a member account
(like Security Hub — centralized security account pattern)

Delegated admin account:
  → Enable Inspector for ALL organization accounts from one place
  → View aggregated findings from all accounts
  → Configure auto-enable for new accounts

Auto-enable settings: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-amazon-inspector-ec2-vulnerability-scanning/view)
  aws_inspector2_organization_configuration:
    ec2:    true/false   ← auto-enable EC2 scanning for new accounts
    ecr:    true/false   ← auto-enable ECR scanning for new accounts
    lambda: true/false   ← auto-enable Lambda scanning for new accounts

New account joins Organization → Inspector automatically enabled
→ No manual action needed per account
```

---

## 8. Inspector Integrations ⭐

### EventBridge (Real-time Automation)

```python
# EventBridge rule for CRITICAL/HIGH findings
event_pattern = {
  "source": ["aws.inspector2"],
  "detail-type": ["Inspector2 Finding"],
  "detail": {
    "severity": ["CRITICAL", "HIGH"],
    "status": ["ACTIVE"]
  }
}

# Targets:
# → SNS → email/PagerDuty alert to security team
# → Lambda → auto-create Jira/ServiceNow ticket
# → Lambda → tag EC2 instance as "needs-patching"
# → Lambda → stop non-compliant EC2 in dev environment
```

### Security Hub

```
Inspector → Security Hub (automatic integration):
  All Inspector findings forwarded to Security Hub
  Normalized to ASFF (Amazon Security Finding Format)
  Aggregated with findings from GuardDuty, Macie, Config
  → Single pane of glass for all security findings
  → Correlate: "EC2 with critical CVE is also showing GuardDuty anomalies"
```

### ECR Console Integration

```
ECR image list → shows vulnerability count per image tag
  my-app:latest  → 3 CRITICAL, 12 HIGH, 45 MEDIUM
  my-app:v1.2    → 0 CRITICAL, 2 HIGH, 10 MEDIUM

Click → drill into specific CVEs → see fix version → update Dockerfile
Helps developers see vulnerabilities before deploying
```

### CI/CD Pipeline Integration

```
Jenkins / CodePipeline / GitHub Actions:
  Build image → push to ECR → Inspector scans → wait for results →
  If CRITICAL CVE found → fail pipeline → block deployment

Inspector CI/CD integration steps:
  1. Push image to ECR (Inspector scans immediately on push)
  2. Wait for scan: aws inspector2 list-findings --filter-criteria ...
  3. Check for CRITICAL/HIGH findings
  4. If found → fail pipeline + notify team
  5. If clean → proceed with ECS/EKS deployment

This shifts security LEFT → catch vulnerabilities during build, not in prod
```

---

## 9. Enabling Inspector

```bash
# Enable Inspector for EC2 + ECR in current account
aws inspector2 enable \
  --resource-types EC2 ECR

# Enable Lambda scanning too
aws inspector2 enable \
  --resource-types EC2 ECR LAMBDA

# Check coverage
aws inspector2 list-coverage \
  --filter-criteria '{"scanStatusCode":[{"comparison":"NOT_EQUALS","value":"ACTIVE"}]}'
  # Shows resources NOT being scanned + reason why

# List CRITICAL findings
aws inspector2 list-findings \
  --filter-criteria '{
    "severity": [{"comparison": "EQUALS", "value": "CRITICAL"}],
    "findingStatus": [{"comparison": "EQUALS", "value": "ACTIVE"}]
  }'

# Get account summary
aws inspector2 get-findings-report-status

# Enable for entire organization (from delegated admin account)
aws inspector2 update-organization-configuration \
  --auto-enable '{"ec2": true, "ecr": true, "lambda": false}'
```

---

## 10. Inspector Pricing

```
EC2 scanning:
  Agent-based:  $0.0045/instance/hour (~$3.24/instance/month)
  Agentless:    $0.00028/instance/scan

ECR container image scanning:
  Initial scan: $0.09 per image digest
  Ongoing re-scan: $0.01/image digest/month

Lambda scanning:
  $0.28 per Lambda function/month

Free tier:
  15-day free trial per resource type per account
  EC2: first 15 days free per instance
  ECR: first 15 days free
  Lambda: first 15 days free

Cost tip:
  Only enable for production workloads if budget-constrained
  Dev environments: enable agentless (cheaper) or disable entirely
  Organizations: enable selectively per OU (prod OU vs dev OU)
```

---

## 11. Inspector vs Trusted Advisor vs GuardDuty vs Security Hub ⭐

| Service | What it Detects | When to Use |
|---------|----------------|------------|
| **Inspector** | Software CVEs in packages (EC2/ECR/Lambda), network exposure | Vulnerability management, patch prioritization |
| **Trusted Advisor** | Architecture anti-patterns, waste, config issues, limits | Account-wide best practice review |
| **GuardDuty** | Active threats — malware, C2 traffic, unusual API calls, crypto mining | Threat detection and incident response |
| **Security Hub** | Aggregates ALL security findings; compliance standards (CIS, PCI-DSS) | Centralized security posture management |
| **Macie** | Sensitive data (PII, credentials) in S3 | Data privacy and classification |
| **Config** | Resource configuration history + compliance rules | Config drift, resource compliance audit |

```
Typical security stack in production:
  Inspector  → find + prioritize CVEs to patch
  GuardDuty  → detect if any CVEs are being actively exploited
  Security Hub → see everything in one place
  Trusted Advisor → keep architecture well-architected
  Config     → track who changed what resource config

Inspector finding → GuardDuty alert on same instance:
  "This EC2 has CVE-2024-5678 AND is making unusual outbound connections"
  → Likely compromised → incident response immediately
```

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Inspector Classic is still available | Classic **retires May 20, 2026** — migrate to Inspector v2 now |
| Inspector requires a separate agent installed | Inspector v2 uses the **SSM Agent** already on most EC2 instances — no new agent |
| Inspector scans run on a schedule you define | Inspector v2 is **continuous and event-driven** — no schedules, no manual runs |
| All findings have same severity regardless of exposure | Inspector **adjusts score based on network reachability** — same CVE scores differently on public vs private resource |
| Inspector fixes vulnerabilities | Inspector **only reports** — you must patch OS packages or update dependencies |
| CVSS score alone determines priority | Also consider **EPSS score** (exploit probability) + **exploit availability** + **network exposure** |
| Inspector only scans EC2 | Inspector v2 scans **EC2 + ECR container images + Lambda functions** |
| Inspector findings are separate from Security Hub | Inspector **automatically forwards** all findings to Security Hub |
| Agentless scanning is real-time | Agentless uses EBS snapshots — runs **at least every 24 hours**, not real-time |
| Must re-enable Inspector when new CVE published | Inspector **automatically re-scans** all resources when new CVE is published |

---

## 13. Interview Questions Checklist

- [ ] What does Amazon Inspector do? What does it NOT do?
- [ ] Inspector Classic vs Inspector v2 — three key differences
- [ ] When is Inspector Classic being retired? (May 20, 2026)
- [ ] What three resource types does Inspector v2 scan?
- [ ] Agent-based vs agentless scanning — how does each work?
- [ ] What agent does Inspector v2 use for EC2? (SSM Agent)
- [ ] What is network reachability scanning? What does it analyze?
- [ ] What triggers Inspector to scan an ECR image? (on-push + new CVE)
- [ ] Five severity levels — what score range is CRITICAL? (9.0–10.0)
- [ ] What is the Inspector Score? How does it differ from raw CVSS?
- [ ] What is EPSS? Why does it matter for patching priority?
- [ ] Same CVE on internet-facing vs private EC2 — different Inspector score? Why?
- [ ] What is SBOM? What formats does Inspector export?
- [ ] How do you auto-remediate findings? (EventBridge + Lambda)
- [ ] Inspector + Security Hub integration — what format? (ASFF)
- [ ] How do you integrate Inspector into CI/CD pipelines?
- [ ] How do you enable Inspector for all Organization accounts?
- [ ] Inspector vs GuardDuty vs Trusted Advisor vs Security Hub — what does each do?
