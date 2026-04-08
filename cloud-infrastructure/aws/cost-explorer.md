# AWS Cost Explorer

## 1. What is Cost Explorer?

AWS Cost Explorer is a **free interactive visualization and analysis tool**
for exploring your historical and forecasted AWS costs and usage — allowing
you to filter, group, and drill into spend across any dimension (service,
account, region, tag, instance type, usage type).

```
Core value:
  "Why did my AWS bill jump $3,000 this month?"
  → Open Cost Explorer → Group by Service → EC2 cost doubled
  → Filter to EC2 → Group by Instance Type → m5.2xlarge instances appeared
  → Filter by Region → us-west-2 → tagged "temp-load-test" → forgotten instances
  → Stop them → next month bill back to normal
  Total time: 5 minutes
```

---

## 2. Enabling Cost Explorer ⭐

```
Enable: AWS Console → Billing and Cost Management → Cost Explorer → Enable
Cannot be enabled via API or CLI — console only
Data load: ~24 hours after enabling
Historical data: 13 months loaded retroactively on first enable
After enabling: CANNOT be disabled (data retained)
Auto-creates: Cost Anomaly Detection with default monitor + alert [costgoat](https://costgoat.com/pricing/aws-cost-explorer)

Multi-account Organizations:
  Enable in management account → automatically available for ALL member accounts
  Members see their own data; management account sees all data + consolidated view
```

---

## 3. Core Features ⭐

### Cost & Usage Visualization

```
Dimensions to group/filter by:
  Service:        EC2, RDS, S3, Lambda, CloudFront, etc.
  Account:        specific member account (in Organizations)
  Region:         us-east-1, eu-west-1, ap-southeast-1
  Availability Zone
  Instance Type:  m5.large, r7g.xlarge, t4g.micro
  Usage Type:     BoxUsage:m5.large, DataTransfer-Out-Bytes, etc.
  Purchase Option: On-Demand, Reserved, Spot, Savings Plan
  Tag:            Environment=prod, Team=engineering, Project=silverstack
  Cost Category:  custom grouping rules you define
  Charge Type:    Usage, Tax, Support, Credit, Refund

Time periods:
  Past: daily/monthly view up to 13 months back
  Future: forecast up to 12 months ahead (ML-based projection)
  Granularity: monthly (default), daily, hourly (paid add-on) [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-granular-data.html)
```

### Granularity Options

```
Monthly granularity:
  Default → free → 13 months history
  Best for: high-level trend analysis, budget reviews, monthly reports

Daily granularity:
  Free → 13 months of daily data
  Best for: identifying which day a cost spike occurred
  Resource-level data available at daily granularity [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-granular-data.html)

Hourly granularity (paid): [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-hourly-granularity.html)
  Cost: $0.01 per 1,000 usage records/month ($0.00000033/record/day) [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-hourly-granularity.html)
  Data retention: 14 days only (not 13 months) [costgoat](https://costgoat.com/pricing/aws-cost-explorer)
  Scope: all services hourly OR EC2 resource-level hourly [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-granular-data.html)
  Example: 100 EC2 instances = 336 records each (24h × 14 days)
           = 33,600 records = $0.34/month [costgoat](https://costgoat.com/pricing/aws-cost-explorer)
  Best for: deployment cost tracking, identifying hour-specific cost spikes,
            resource scheduling optimization (when to stop dev instances)
  Enable: Cost Explorer → Preferences → Enable hourly granularity
  Note: once enabled → applies to all compatible resources automatically [costgoat](https://costgoat.com/pricing/aws-cost-explorer)
```

---

## 4. RI & Savings Plans Reports ⭐

```
Reserved Instance Utilization Report:
  What % of your purchased RI hours are actually being used?
  Threshold alert: "alert me if RI utilization drops below 80%"
  Low utilization → you're paying for RIs that aren't being used
  Action: sell unused Standard RIs on RI Marketplace

Reserved Instance Coverage Report:
  What % of your total On-Demand eligible hours are covered by RIs?
  High coverage → good (most usage getting discount)
  Low coverage → opportunity to buy more RIs for steady usage

Savings Plans Utilization Report:
  % of committed $/hour being used
  Unused commitment = wasted money

Savings Plans Coverage Report:
  % of eligible compute usage covered by Savings Plans
  Gaps = On-Demand usage that could be covered with more commitment

Recommendations:
  Cost Explorer analyzes 14 days of usage history → recommends:
    "Buy X m5.large RIs in us-east-1 → save $Y/month"
    "Purchase $Z/hour Compute Savings Plan → save $W/month"
  Filter by: RI term (1 or 3 year), payment option, lookback period
  Purchase directly from Cost Explorer recommendations tab
```

---

## 5. Rightsizing Recommendations ⭐

```
Identifies overprovisioned EC2 instances to downsize or terminate: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-rightsizing.html)

How it works:
  Analyzes EC2 instance metrics from CloudWatch (CPU, network, memory if agent)
  Identifies instances running at < 40% CPU utilization over 14 days
  Recommends: downsize (e.g., m5.2xlarge → m5.large) or terminate (idle)

Recommendation output: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-rightsizing.html)
  Current instance: m5.2xlarge in us-east-1 → $120/month
  Recommended:      m5.large in us-east-1  → $60/month
  Monthly savings:  $60/month
  Risk:             low (CPU utilization < 10%)

Enable CloudWatch agent for better accuracy:
  Default: only EC2 hypervisor metrics (CPU %, network) available
  With CloudWatch agent: memory utilization also included
  → Better recommendations (fewer false positives from memory-heavy apps)

Bulk view: [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-rightsizing.html)
  See ALL underutilized EC2 instances across ALL member accounts in ONE view
  Filter by: account, region, instance family, minimum savings threshold
  Export to CSV → share with FinOps team

Note: takes action in EC2 console — NOT automated (you click to modify)
```

---

## 6. Cost Categories

```
Group costs into custom business dimensions:

Example: "Engineering team" category:
  Rules:
    WHEN account is 123456789 OR 987654321   → "Engineering"
    WHEN tag:Team = "engineering"             → "Engineering"
    WHEN service = "CodeBuild"                → "Engineering"

Appears in:
  Cost Explorer filters/groups: "Group by Cost Category"
  Budgets: budget for "Engineering" category
  Cost and Usage Reports: CostCategory column

Use cases:
  Chargeback: bill each team their exact AWS spend
  Showback: show teams their cost without billing them (awareness)
  Project cost tracking: one category per project/product

Split charge rules:
  Shared costs (e.g., shared VPN, support plan) → split across categories by usage %
  → Each team sees their proportional share of shared costs
```

---

## 7. Cost Explorer API

```
Programmatic access to all Cost Explorer data:

Pricing: [costgoat](https://costgoat.com/pricing/aws-cost-explorer)
  $0.01 per API request (NOT free)
  → Runaway scripts → expensive quickly
  → Recommend: use Budgets alerts to monitor Cost Explorer API spend itself

Key API calls:
  GetCostAndUsage:         retrieve costs/usage with filters/groups
  GetCostForecast:         get ML-based spend forecast
  GetReservationUtilization: RI utilization data
  GetSavingsPlansUtilization: SP utilization data
  GetRightsizingRecommendation: EC2 rightsizing suggestions [docs.aws.amazon](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-rightsizing.html)
  GetDimensionValues:      list available values for a dimension (services, regions)
  GetTags:                 list all cost allocation tag key/values

Example use case: daily Slack cost report
  EventBridge → Lambda (daily 8 AM) → GetCostAndUsage (yesterday)
  → format → Slack webhook → "Yesterday's AWS spend: $247 (↑12% vs 7-day avg)"

Avoid API call explosion:
  Cache results (store in DynamoDB/S3 → refresh once/day)
  Use monthly granularity unless hourly needed → fewer records
  Set Budgets alert for cost-management API spend category
```

---

## 8. Cost Explorer vs Other Cost Tools

| Tool | Purpose | Granularity | Historical | Forward-looking |
|------|---------|------------|-----------|----------------|
| **Cost Explorer** | Analyze actual spend, visualize trends | Monthly / Daily / Hourly | 13 months | 12-month forecast |
| **AWS Budgets** | Alert when thresholds breached | Monthly | Current month | Forecasted vs budget |
| **Cost Anomaly Detection** | Detect unexpected spikes via ML | Daily | 10-day min baseline | No |
| **Cost & Usage Report** | Raw data for custom analysis | Hourly/Daily/Monthly | Full history in S3 | No |
| **Pricing Calculator** | Estimate cost BEFORE deploying | N/A | No (hypothetical) | Pre-deployment estimate |
| **Trusted Advisor** | Best-practice checks + optimization | Per resource | Current state | Recommendations |
| **Compute Optimizer** | Right-size EC2/Lambda/EBS/ASG | Per resource | Last 14 days | Projected savings |

---

## 9. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Cost Explorer can be enabled via API | Must be enabled through the **AWS console only** |
| Hourly granularity stores 13 months of data | Hourly data is retained for **14 days only** |
| Cost Explorer API is free | Cost Explorer API costs **$0.01 per request** — can accumulate fast |
| Cost Explorer disables after enabling | Once enabled, **cannot be disabled** — data is retained |
| Rightsizing recommendations auto-apply changes | Rightsizing is **recommendations only** — you manually resize in EC2 console |
| Hourly granularity covers all 13 months | Hourly granularity covers only **the past 14 days** |
| Cost Explorer forecasts are deterministic | Forecasts are **ML-based projections** — accuracy improves with more history |
| Cost Explorer available immediately after enabling | Data loads in **~24 hours** after enabling |

---

## 10. Interview Questions Checklist

- [ ] What is Cost Explorer? Is it free?
- [ ] Can Cost Explorer be enabled via CLI/API? (NO — console only)
- [ ] How much historical data does Cost Explorer show? (13 months)
- [ ] Three granularity levels — which is paid and what does it cost? (hourly: $0.01/1K records)
- [ ] Hourly granularity data retention period? (14 days only, not 13 months)
- [ ] RI Utilization vs RI Coverage report — what does each show?
- [ ] How does rightsizing work? Is it automated? (recommendations only — manual action)
- [ ] Cost Explorer API cost? ($0.01/request)
- [ ] What auto-deploys when Cost Explorer is first enabled? (Cost Anomaly Detection)
- [ ] Cost Explorer vs Pricing Calculator — key difference? (actual vs hypothetical)
- [ ] Cost Categories — what is chargeback vs showback?
- [ ] Cost Explorer vs Cost & Usage Report — when to use each?
