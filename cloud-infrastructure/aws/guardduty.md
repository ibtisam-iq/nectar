# Amazon GuardDuty

## 1. What is GuardDuty?

Amazon GuardDuty is a **fully managed intelligent threat detection service**
that continuously monitors your AWS accounts, workloads, and data for
malicious activity and anomalous behavior using ML, AI, and threat
intelligence feeds — requiring zero infrastructure to deploy or manage.

```
Without GuardDuty:
  EC2 instance communicating with known botnet C2 server → no alert → goes unnoticed for months
  IAM credentials stolen → attacker calling AWS APIs from Russia → no alert
  Cryptominer running on ECS task → high CPU bill → discovered 3 weeks later

With GuardDuty:
  Enabled in 2 clicks → immediately starts analyzing data sources
  C2 communication detected → UnauthorizedAccess:EC2/MaliciousIPCaller finding → SNS alert
  Anomalous IAM API call → Credential access finding → auto-blocked via Lambda
  Cryptominer EBS scan → Execution:EC2/MaliciousFile finding → terminate + remediate
```

---

## 2. Data Sources ⭐

GuardDuty analyzes multiple data streams without you configuring anything:

### Foundational (always included, no extra cost)

```
AWS CloudTrail Management Events:
  All API calls across your account (CreateInstance, AttachRolePolicy, etc.)
  Detects: unusual API activity, privilege escalation, impossible travel

AWS CloudTrail S3 Data Events:
  Object-level operations (GetObject, PutObject, DeleteObject)
  Detects: mass data exfiltration, data destruction, unusual access patterns

VPC Flow Logs:
  Network traffic metadata (IPs, ports, bytes, accept/reject)
  Detects: port scanning, unusual outbound traffic, communication with threat IPs

DNS Logs:
  DNS query/response logs from VPC resolvers
  Detects: DNS tunneling, communication with malware C2 domains,
           data exfiltration via DNS

Note: GuardDuty does NOT need you to enable CloudTrail, VPC Flow Logs, or DNS logs
separately — it accesses them independently even if YOU haven't enabled them
```

### Protection Plans (optional add-ons)

```
S3 Protection: [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/s3-protection.html)
  Monitors CloudTrail S3 DATA events (object-level API)
  Detects: data exfiltration, destruction, anomalous access patterns
  Extended Threat Detection: correlates multi-stage attack sequences across S3 [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/s3-protection.html)
  Default: enabled when GuardDuty is first turned on [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/s3-protection.html)

EKS Protection: [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)
  Analyzes Kubernetes audit logs from EKS clusters
  Detects: suspicious API server auth attempts, privilege escalation,
           unusual service account creation, container escape attempts [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)
  Extended Threat Detection for EKS: [linkedin](https://www.linkedin.com/posts/osamamunir_amazon-guardduty-expands-extended-threat-activity-7340778468126707713-khEX)
    Correlates EKS audit logs + runtime behavior + malware execution
    + AWS API activity → identifies sophisticated multi-stage attack sequences
    Example: exploit container app → steal service account token
             → access Kubernetes secrets → exfiltrate data [linkedin](https://www.linkedin.com/posts/osamamunir_amazon-guardduty-expands-extended-threat-activity-7340778468126707713-khEX)

Runtime Monitoring: [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)
  OS-level events on: EKS nodes, EC2 instances, ECS tasks (including Fargate)
  Detects: process-level anomalies, unusual file system access,
           privilege escalation, cryptomining behavior at runtime
  Requires: GuardDuty security agent deployed on instances/nodes

Malware Protection for EC2: [aws.amazon](https://aws.amazon.com/guardduty/)
  Scans EBS volumes attached to EC2 instances and container workloads
  Triggered: when suspicious activity finding occurs → scan initiated
  Also: agentless scan-on-demand + continuous scanning
  Detects: backdoors, trojans, cryptominers, ransomware in EBS volumes

Malware Protection for S3: [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/gdu-malware-protection-s3.html)
  Scans newly uploaded S3 objects AUTOMATICALLY on every new upload
  Detects: malware in user-uploaded files (file sharing, CI/CD artifact storage)
  Results published to: EventBridge + CloudWatch namespace [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/gdu-malware-protection-s3.html)
  Note: if scanned in standalone mode (no GuardDuty detector) → no Finding generated,
        results only go to EventBridge [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/gdu-malware-protection-s3.html)

RDS Protection:
  Analyzes RDS login activity
  Detects: brute force attacks, credential stuffing, anomalous login behavior
  Supports: Aurora MySQL, Aurora PostgreSQL, RDS MySQL, RDS PostgreSQL

Lambda Protection:
  Monitors Lambda function network activity
  Detects: functions communicating with known malicious IPs/domains,
           unexpected data exfiltration from serverless workloads

AWS Backup Protection: [aws.amazon](https://aws.amazon.com/guardduty/)
  Scans EC2, EBS, and S3 backups stored in AWS Backup for malware
```

---

## 3. Finding Types ⭐

```
Findings follow naming convention:
  ThreatPurpose:ResourceType/ThreatFamilyName

Threat Purposes:
  Backdoor:          malware with remote access capability
  Behavior:          unusual resource behavior pattern
  CredentialAccess:  credential theft or misuse
  CryptoMining:      cryptocurrency mining activity
  DefenseEvasion:    attempts to avoid detection
  Discovery:         reconnaissance/enumeration
  Exfiltration:      data being copied out
  Impact:            resource hijacking/destruction
  InitialAccess:     first foothold into environment
  Persistence:       maintaining unauthorized access
  PrivilegeEscalation: gaining elevated permissions
  Stealth:           hiding malicious activity
  Trojan:            trojan malware behavior
  UnauthorizedAccess: actions with stolen credentials

Resource Types:
  EC2, IAMUser, S3, Kubernetes, Lambda, RDSDBInstance, Container

Examples: [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-s3.html)
  UnauthorizedAccess:EC2/SSHBruteForce
    → EC2 instance receiving SSH brute force attacks inbound
  UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B
    → Console login from anomalous IP/location
  Discovery:S3/MaliciousIPCaller
    → IAM entity calling ListBuckets from known threat IP [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-s3.html)
  Exfiltration:S3/ObjectRead.Unusual
    → Large volume of S3 objects read → possible data exfiltration [docs.aws.amazon](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-s3.html)
  CryptoMining:EC2/BitcoinTool.B
    → EC2 communicating with known Bitcoin mining pool
  Execution:EC2/MaliciousFile
    → Malware detected on EBS volume scan → execution risk
  PrivilegeEscalation:Kubernetes/PrivilegedContainer
    → Container launched with elevated privileges in EKS [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)
  CredentialAccess:Kubernetes/MaliciousIPCaller
    → Kubernetes API calls from known threat IP [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)
  Impact:EC2/WinRMBruteForce
    → Windows remote management brute force

Severity levels:
  Critical (9.0–10.0): immediate action required (new — Extended Threat Detection) [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)
  High    (7.0–8.9):   confirmed malicious activity → immediate investigation
  Medium  (4.0–6.9):   suspicious activity → needs investigation soon
  Low     (1.0–3.9):   unusual but not immediately harmful → monitor
```

---

## 4. Extended Threat Detection ⭐

```
NEW capability: correlates events across MULTIPLE protection plans,
data sources, and timelines to detect multi-stage attack sequences [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)

Traditional GuardDuty:
  One finding per event: "unusual API call" → Medium severity
  Context: none — you correlate manually

Extended Threat Detection:
  Correlates: EKS audit logs + runtime behavior + malware results + CloudTrail APIs
  Generates: single Critical finding for the entire attack sequence
  Contains: full timeline, all actors, all affected resources,
            sequence of steps the attacker took [linkedin](https://www.linkedin.com/posts/osamamunir_amazon-guardduty-expands-extended-threat-activity-7340778468126707713-khEX)

Example attack sequence detected: [linkedin](https://www.linkedin.com/posts/osamamunir_amazon-guardduty-expands-extended-threat-activity-7340778468126707713-khEX)
  T=0:00  Attacker exploits vulnerable container application via HTTP
  T=0:02  Process spawns unexpected shell → runtime anomaly detected
  T=0:05  Service account token extracted from container memory
  T=0:08  Token used to query Kubernetes secrets via API server
  T=0:12  AWS STS called → temporary credentials obtained
  T=0:15  S3 GetObject on sensitive buckets from unknown IP
  → GuardDuty correlates all 6 events → ONE Critical finding with full context

Finding type for attack sequences:
  AttackSequence:Kubernetes/CompromisedCluster [linkedin](https://www.linkedin.com/posts/osamamunir_amazon-guardduty-expands-extended-threat-activity-7340778468126707713-khEX)
  AttackSequence:S3/CompromisedData [aws.amazon](https://aws.amazon.com/blogs/security/navigating-amazon-guardduty-protection-plans-and-extended-threat-detection/)
```

---

## 5. Multi-Account Setup ⭐

```
GuardDuty + Organizations (recommended):
  Designate delegated administrator account (Security/Audit OU account)
  Enable GuardDuty for entire organization in one click
  All existing + future member accounts: auto-enrolled [amazonaws](https://www.amazonaws.cn/en/guardduty/faqs/)

  Administrator account capabilities:
    View ALL findings across all member accounts
    Manage protection plans for all accounts
    Export findings from all accounts to central S3/EventBridge
    Suppress findings org-wide

  Member account limitations:
    Cannot disable GuardDuty if managed by admin
    Can view their own findings only (not other accounts)

  Auto-enable for new accounts:
    GuardDuty → Settings → Enable for all accounts (+ new accounts)
    → New account joins org → GuardDuty enabled automatically [amazonaws](https://www.amazonaws.cn/en/guardduty/faqs/)

Standalone multi-account (older method):
  GuardDuty → Accounts → Send invitation → member accepts
  Less preferred: manual invitation per account
```

---

## 6. Findings Automation ⭐

```
GuardDuty finding → EventBridge → automated response:

EventBridge rule:
  Source: aws.guardduty
  Detail type: "GuardDuty Finding"
  Filter: severity >= 7 (High/Critical only)
  Target: Lambda function, SNS, SSM Automation, Step Functions

Common automated responses: [red-team](https://red-team.sh/posts/real-time-ids-using-guardduty/)
  1. Alert → SNS → email/Slack/PagerDuty
  2. Isolate compromised EC2:
     Lambda: modify SG → remove all inbound/outbound rules → attach quarantine SG
  3. Revoke compromised IAM credentials:
     Lambda: iam:AttachUserPolicy → attach DenyAll policy to compromised user/role
  4. Block malicious IP:
     Lambda: update WAF IP set → add IP to block list
  5. Snapshot + terminate compromised EC2:
     Lambda: create EBS snapshot (forensics) → terminate instance
  6. Ticket creation:
     Lambda → Jira/ServiceNow API → create security incident ticket

Finding suppression rules:
  Suppress known-good findings (e.g., pentest IPs, scanner tools)
  Filter by: finding type, resource, specific IP range
  Suppressed findings: still generated but auto-archived → not visible by default
  Use carefully: do NOT suppress high-severity types broadly

Findings export: [amazonaws](https://www.amazonaws.cn/en/guardduty/faqs/)
  Active findings: export to S3 bucket (for SIEM, long-term storage, Athena queries)
  EventBridge: real-time streaming of findings to SIEM (Splunk, Datadog, etc.)
  Update frequency: 6 hours (default) or 15 minutes (configurable)
```

---

## 7. 30-Day Free Trial + Pricing

```
Free trial: 30 days per account (per region) — full features [amazonaws](https://www.amazonaws.cn/en/guardduty/faqs/)
  During trial: cost estimate shown → "you would have spent $X this month"

After trial — pay per data analyzed:
  Foundational threat detection:
    CloudTrail management events: per 1M events analyzed
    VPC Flow Logs + DNS logs: per GB analyzed
  Protection plans: separate per-GB or per-resource pricing
    S3 Protection: per 1M S3 data events
    Malware Protection EC2: per GB of EBS scanned
    Malware Protection S3: per GB of objects scanned
    RDS Protection: per million login events
    EKS Audit Log Monitoring: per million audit log events
    Runtime Monitoring: per vCPU-hour (EC2), per task-hour (Fargate)
    Lambda Protection: per million invocations

Cost optimization:
  S3 bucket key: reduces KMS calls → indirectly reduces cost
  Use suppression rules for known-good noisy findings
  Disable protection plans you don't need (e.g., Lambda Protection if no Lambda)
  Multi-account admin: one bill, but each account's usage billed separately

Free tier (Always Free): NONE — only 30-day trial per account [amazonaws](https://www.amazonaws.cn/en/guardduty/faqs/)
```

---

## 8. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| GuardDuty needs CloudTrail/VPC Flow Logs enabled | GuardDuty **independently accesses** these data streams — you don't need to enable them first |
| GuardDuty prevents attacks | GuardDuty **detects and alerts** only — no blocking; use Lambda+EventBridge for response |
| Malware Protection for S3 generates a GuardDuty Finding if standalone | In standalone mode (no detector), results go to **EventBridge only — no Finding generated** |
| GuardDuty is regional only | GuardDuty must be **enabled per region** — but org-wide setup enables it across all regions |
| One finding per attack in Extended Threat Detection | Extended Threat Detection generates **ONE Critical finding** for the entire multi-stage sequence |
| Suppressed findings are deleted | Suppressed findings are **archived, not deleted** — still accessible, just hidden from default view |
| GuardDuty has Always Free tier | GuardDuty has a **30-day free trial only** — billing starts after trial ends |
| Member accounts can disable GuardDuty when managed by admin | Admin-managed accounts **cannot disable GuardDuty** |

---

## 9. Interview Questions Checklist

- [ ] What does GuardDuty analyze? Name four foundational data sources
- [ ] Does GuardDuty require you to enable VPC Flow Logs or CloudTrail? (NO)
- [ ] Eight protection plans — what does each protect?
- [ ] What is Extended Threat Detection? What severity does it generate? (Critical)
- [ ] Malware Protection for S3 — when is a Finding generated vs not?
- [ ] Finding naming convention — ThreatPurpose:ResourceType/ThreatFamily
- [ ] How do you auto-respond to a GuardDuty finding? (EventBridge → Lambda)
- [ ] Multi-account GuardDuty setup — delegated admin capabilities
- [ ] How do you suppress known-good findings? (suppression rules)
- [ ] GuardDuty free tier? (30-day trial per account per region — no always-free tier)
