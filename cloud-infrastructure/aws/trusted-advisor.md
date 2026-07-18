# AWS Trusted Advisor

## 1. What is Trusted Advisor?

AWS Trusted Advisor is a **real-time best practice recommendation engine**
that continuously analyzes your AWS environment across six categories and
gives you actionable guidance to reduce cost, improve performance, harden
security, increase fault tolerance, stay within service quotas, and achieve
operational excellence.

```
Think of it as: an automated AWS solutions architect reviewing your account 24/7
  → Spots idle EC2 instances draining money
  → Flags open SSH ports exposed to the internet
  → Warns when you're at 80% of a service quota
  → Identifies single points of failure in your architecture

Trusted Advisor does NOT:
  Fix issues automatically (it only recommends — you act)
  Replace Inspector (CVE/vulnerability scanning)
  Replace Security Hub (aggregated security posture)
  Replace Cost Explorer (detailed cost drill-down)
  Monitor application metrics (that's CloudWatch)
```

---

## 2. Six Check Categories ⭐

### 1. Cost Optimization

Identifies unused and underutilized resources wasting money:

```
Low utilization EC2 instances
  → CPU < 10% AND network < 5 MB/day over 14 days
  → Recommendation: downsize or terminate

Idle load balancers
  → ALB/CLB with < 100 requests/day over 14 days
  → Recommendation: delete unused load balancers

Unassociated Elastic IP addresses
  → EIP allocated but not attached to a running instance
  → Cost: $0.005/hr per idle EIP → add up fast across large accounts

Underutilized EBS volumes
  → Low read/write activity on provisioned volumes
  → Recommendation: snapshot + delete, or downgrade storage type

Amazon RDS Idle DB Instances
  → RDS with no connections for 7+ days

Unattached/idle Redshift clusters
  → Cluster provisioned but not being queried

S3 Incomplete Multipart Uploads
  → Parts uploaded but never completed → still billed for storage
  → Fix: add S3 lifecycle rule to abort incomplete uploads after N days

Reserved Instance / Savings Plan purchase recommendations
  → Based on your On-Demand usage patterns over trailing period
  → "Buy 3 t3.medium RIs → save $420/month"
```

### 2. Performance

```
High utilization EC2 instances
  → CPU consistently > 90% → degraded performance risk
  → Recommendation: upsize instance or enable Auto Scaling

Large number of rules in EC2 security groups
  → Too many rules → increased latency for evaluation

EBS Provisioned IOPS volume attachment
  → High-IOPS EBS attached to non-EBS-optimized instance → throughput wasted
  → Fix: enable EBS optimization on instance

CloudFront content delivery optimization
  → Content not being cached effectively at edge
```

### 3. Security

```
Free checks (ALL support plans including Basic):
  MFA on Root Account               ← CRITICAL — most important check
  Security Groups – Specific Ports Unrestricted
    → SG inbound 0.0.0.0/0 on: 22 (SSH), 3389 (RDP), 3306 (MySQL),
      1433 (MSSQL), 5432 (PostgreSQL), 5500, 23, 21, 20, 25, 80, 443...
  Amazon S3 Bucket Permissions      ← public read/write detected
  Amazon EBS Public Snapshots       ← snapshot accessible to anyone
  Amazon RDS Public Snapshots       ← snapshot accessible to anyone
  AWS STS Global Endpoint           ← STS not using regional endpoints

Business/Enterprise additional checks:
  IAM Use                           ← using root for daily operations
  IAM Password Policy               ← weak/missing password policy
  CloudTrail Logging                ← not enabled in all regions
  S3 Bucket Logging                 ← server access logging disabled
  Exposed Access Keys               ← AWS scans GitHub continuously for leaked keys
  Lambda Functions using deprecated runtimes
  EC2 instances with outdated AMIs
  Route 53 MX and SPF misconfiguration
```

### 4. Fault Tolerance

```
EC2 Availability Zone Balance
  → Instances concentrated in one AZ → one AZ failure = total outage

RDS Multi-AZ
  → RDS single-AZ = no automatic failover on instance failure

Auto Scaling Group Resources
  → EC2 instances not in an ASG → no automatic recovery

ELB Cross-Zone Load Balancing
  → Not enabled → uneven request distribution across AZs

Amazon EBS Snapshots
  → EBS volumes with no snapshot taken recently

VPN Tunnel Redundancy
  → VPN connection with only one tunnel (need two for HA)

Direct Connect Connection Redundancy
  → Single DX connection = single point of failure

Route 53 Deleted Health Checks
  → DNS routing policies referencing deleted health checks

Aurora DB Instance Accessibility
  → Aurora cluster with no read replicas → reduced availability
```

### 5. Service Limits (Quotas)

```
FREE for ALL support plans (including Basic) — most important free value

Monitors usage vs AWS service quotas:
  Green:  < 80% of limit → healthy
  Yellow: 80–99% of limit → request increase NOW before you hit it
  Red:    ≥ 100% of limit → already at limit → API calls failing

Commonly watched quotas:
  EC2 Running On-Demand instances per region
  EBS volume count and total storage (TiB)
  Lambda concurrent executions (default: 1,000)
  VPCs per region (default: 5)
  IAM roles, users, policies per account
  CloudFormation stacks per region
  RDS DB instances per region
  Auto Scaling groups per region

Click through → Service Quotas console → request increase directly
```

### 6. Operational Excellence

```
AWS CloudTrail not logging in all regions
CloudWatch alarms not configured for key metrics
Lambda functions using deprecated/end-of-life runtimes
EC2 instances not managed by AWS Systems Manager
S3 versioning not enabled on important buckets
Lack of resource tagging (cost allocation tags missing)
```

---

## 3. Support Plan Access Tiers ⭐

| Support Plan | Monthly Cost | Trusted Advisor Access |
|-------------|-------------|----------------------|
| **Basic** | Free | 7 core checks only |
| **Developer** | $29/month | 7 core checks only |
| **Business** | $100/month min | Full access — all checks |
| **Enterprise On-Ramp** | $5,500/month | Full access — all checks |
| **Enterprise** | $15,000/month | Full access + Trusted Advisor Priority |

```
7 free core checks (Basic + Developer):
  6 security checks: MFA on root, public EBS snapshots, public RDS snapshots,
                     public S3 buckets, unrestricted SG ports, STS endpoint
  All service limit checks: always free regardless of plan

Business Support = the minimum to unlock full Trusted Advisor
→ #1 exam reason to upgrade from Developer to Business support [tutorialsdojo](https://tutorialsdojo.com/aws-trusted-advisor/)
```

---

## 4. Check Refresh Behavior

```
Auto-refresh:
  Business/Enterprise plans → checks refresh automatically WEEKLY
  Basic/Developer → must manually sign in to console to trigger refresh
  Some checks auto-refresh multiple times per day (e.g., Well-Architected checks)

Manual refresh:
  Console: Trusted Advisor → Refresh all checks button
  CLI: aws support refresh-trusted-advisor-check --check-id <id>
  API: RefreshTrustedAdvisorCheck

Rate limits on manual refresh: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-aws-trusted-advisor-recommendations/view)
  Same check: cannot refresh more than once every 5 minutes
  Daily cap on total refreshes per account

GovCloud exception: [github](https://github.com/aws-samples/aws-trusted-advisor-scheduled-refresh)
  Even Business/Enterprise → manual refresh only in GovCloud
```

---

## 5. Trusted Advisor Priority

```
Available: Enterprise and Unified Operations plans only

What it adds over standard Trusted Advisor:
  Your Technical Account Manager (TAM) + AWS account team
  curates and prioritizes the most critical recommendations for YOUR account
  based on your specific workloads, architecture, and risk profile

Features:
  Recommendation lifecycle tracking:
    Created → Acknowledged → In Progress → Resolved / Rejected
  Average time-to-resolve tracking
  Dismissed recommendations history (90-day window) [docs.aws.amazon](https://docs.aws.amazon.com/awssupport/latest/user/trusted-advisor-priority.html)
  Recommendations without update > 30 days flagged for follow-up
  View across all Organization member accounts from single console [aws.amazon](https://aws.amazon.com/premiumsupport/technology/trusted-advisor-priority/)

Use case:
  Large enterprises with complex architectures where 500+ checks
  would be overwhelming → TAM helps focus on what matters most
```

---

## 6. Organizational View

```
Business/Enterprise plans + AWS Organizations required

What it provides:
  Aggregated view of Trusted Advisor findings across ALL accounts
  Single report: "which accounts have public S3 buckets?"
  "which accounts have root MFA disabled?"
  "which accounts are approaching service limits?"

Reports:
  Generate on-demand or scheduled
  Format: JSON or CSV
  Download to S3 or view in console

Enable:
  Management account → Trusted Advisor → Organizational View → Enable
  Requires Organizations trusted access for Trusted Advisor

Refresh behavior in Org view: [docs.aws.amazon](https://docs.aws.amazon.com/awssupport/latest/user/organizational-view.html)
  Must refresh individual account checks before generating org report
  Cannot trigger refresh for all accounts from management account
  → Each member account must refresh independently (or use EventBridge automation)
```

---

## 7. EventBridge Integration and Automation ⭐

```
Trusted Advisor emits EventBridge events when check status changes:

Event pattern:
  source: "aws.trustedadvisor"
  detail-type: "Trusted Advisor Check Item Refresh Notification"
  detail.status: "ERROR" | "WARN" | "OK" | "NOT_AVAILABLE"
  detail.check-name: "MFA on Root Account"

Automation examples:

1. Unattached EIP → auto-release:
   TA check: unassociated EIP detected
   → EventBridge → Lambda → release EIP
   → saves money automatically

2. Public S3 bucket → auto-remediate:
   TA check: public S3 bucket detected
   → EventBridge → Lambda → put_public_access_block
   → SNS alert to security team

3. Service limit approaching → auto-request increase:
   TA check: EC2 limit at 80%
   → EventBridge → Lambda → create Service Quotas increase request

4. Weekly summary report:
   EventBridge scheduled rule → Lambda → pull all TA findings →
   format → send email via SES

CLI refresh automation: [oneuptime](https://oneuptime.com/blog/post/2026-02-12-aws-trusted-advisor-recommendations/view)
  aws support describe-trusted-advisor-checks --language en |
    jq '.checks[].id' |
    xargs -I{} aws support refresh-trusted-advisor-check --check-id {}
```

---

## 8. Trusted Advisor vs Other AWS Services ⭐

| Service | Purpose | What it Detects |
|---------|---------|----------------|
| **Trusted Advisor** | Best practice advisory (6 categories) | Architecture/config issues, waste, limits |
| **AWS Inspector** | Software vulnerability scanning | CVEs in EC2/ECR/Lambda packages |
| **AWS Security Hub** | Aggregated security posture | Cross-service security findings + compliance |
| **AWS Config** | Resource config tracking + compliance rules | Config drift, compliance violations |
| **AWS Compute Optimizer** | ML-based right-sizing | EC2/Lambda over/under-provisioning |
| **AWS Cost Explorer** | Cost analysis + forecasting | Spend trends, RI utilization |
| **AWS GuardDuty** | Threat detection | Malicious activity, anomalous behavior |

---

## 9. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Trusted Advisor automatically fixes issues | TA only **recommends** — you must act manually or automate via EventBridge |
| Basic plan gets all Trusted Advisor checks | Basic/Developer get **7 free checks only** — need Business+ for full access |
| Trusted Advisor refreshes in real-time | Business/Enterprise auto-refresh is **weekly** — manual refresh for immediate results |
| Same check can be refreshed any time | Manual refresh is **rate-limited** — one refresh per check per 5 minutes |
| Trusted Advisor replaces Inspector | TA checks architecture/config; Inspector scans **software CVEs** — completely different |
| Organizational view is always available | Requires **Business/Enterprise + AWS Organizations** — not available on Basic/Developer |
| Trusted Advisor Priority is on Business plan | Priority requires **Enterprise or Unified Operations** plan only |
| Service limit checks require Business plan | Service limit checks are **free for ALL plans** including Basic |

---

## 10. Interview Questions Checklist

- [ ] What does Trusted Advisor do? What are the six categories?
- [ ] Which checks are free on the Basic plan? (7: 6 security + all service limits)
- [ ] What is the minimum support plan for full Trusted Advisor access? (Business)
- [ ] How often does Trusted Advisor auto-refresh? For which plans?
- [ ] What is the manual refresh rate limit? (once per check per 5 minutes)
- [ ] Name five cost optimization checks
- [ ] Name five security checks available on Basic plan
- [ ] Name five fault tolerance checks
- [ ] What is Trusted Advisor Priority? Which plan includes it?
- [ ] What is Organizational View? What does it require?
- [ ] How do you automate responses to Trusted Advisor findings? (EventBridge)
- [ ] Trusted Advisor vs Inspector vs Security Hub vs GuardDuty — what does each do?
