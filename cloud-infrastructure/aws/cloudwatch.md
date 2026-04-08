# Amazon CloudWatch

## 1. What is CloudWatch?

CloudWatch is AWS's **unified observability service** — it collects metrics,
logs, and traces from your AWS infrastructure and applications, then lets
you monitor, alert, visualize, and automatically respond to operational events.

```
Three pillars of observability:
  Metrics  → numbers over time (CPU = 78%, RequestCount = 4,320)
  Logs     → text records of events (application logs, access logs, Lambda output)
  Traces   → request path across distributed services (X-Ray integration)

CloudWatch covers: Metrics + Logs
AWS X-Ray covers:  Traces (distributed tracing)
```

---

## 2. CloudWatch Metrics ⭐

A **metric** is a time-series of data points with a name, namespace, and
optional dimensions.

```
Metric anatomy:
  Namespace:  AWS/EC2          ← service grouping (or custom: MyApp/Orders)
  MetricName: CPUUtilization   ← what is measured
  Dimensions: InstanceId=i-1234567890abcdef0  ← what it applies to
  Unit:       Percent
  Value:      78.3
  Timestamp:  2026-04-08T15:30:00Z
```

### Default vs Custom Metrics

| Type | Published By | Cost | Examples |
|------|------------|------|---------|
| **AWS default** | AWS services automatically | Free | EC2 CPUUtilization, S3 BucketSizeBytes, ALB RequestCount |
| **Detailed monitoring** | AWS services (1-min granularity) | Small charge | EC2 with detailed monitoring enabled (default: 5-min) |
| **Custom metrics** | Your application via PutMetricData API | Per metric per month | OrderCount, ActiveUsers, QueueDepth |

### EC2 Default Metrics (Free, 5-minute granularity)

```
AWS/EC2 namespace:
  CPUUtilization         ← % CPU used
  NetworkIn / NetworkOut ← bytes transferred
  DiskReadOps / DiskWriteOps ← disk operations
  StatusCheckFailed      ← instance or system check failure

NOT available by default (need CloudWatch Agent):
  Memory (RAM) utilization  ← OS-level, AWS cannot see it
  Disk space utilization    ← OS-level, AWS cannot see it
  Process counts            ← OS-level

CloudWatch Agent:
  Installed on EC2 → reads OS-level metrics → sends to CloudWatch
  IAM role required: CloudWatchAgentServerPolicy
  Config: /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

### Metric Resolution

```
Standard resolution: 1 minute  (minimum for detailed monitoring)
High resolution:     1 second  (custom metrics only — higher cost)

Retention:
  < 60 seconds resolution: retained 3 hours
  1-minute resolution:     retained 15 days
  5-minute resolution:     retained 63 days
  1-hour resolution:       retained 455 days (15 months)
  (CloudWatch automatically aggregates older data to lower resolution)
```

### Metric Math

Combine metrics with mathematical expressions into new virtual metrics:

```
Example: Error rate % from two metrics
  m1: HTTPCode_ELB_5XX_Count
  m2: RequestCount
  Expression: (m1/m2)*100  → ErrorRate %
  → Create alarm on ErrorRate instead of raw counts

Functions available:
  METRICS()      → array of all metrics in expression
  SUM(METRICS()) → sum across all dimensions (e.g., total CPU across fleet)
  AVG(METRICS()) → average across all dimensions
  MIN/MAX        → minimum/maximum of metrics
  ANOMALY_DETECTION_BAND(m1, 2) → ML band for anomaly detection [docs.aws.amazon](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Anomaly_Detection.html)
```

---

## 3. CloudWatch Alarms ⭐

An alarm watches a metric (or metric math expression) and transitions
between states based on whether the metric crosses a threshold:

### Alarm States

```
OK          → metric within acceptable range
ALARM       → metric exceeded threshold → actions triggered
INSUFFICIENT_DATA → not enough data points yet (new alarm or metric gap)
```

### Alarm Components

```
Metric:          what to watch (CPUUtilization of i-1234567890abcdef0)
Threshold:       > 80%
Period:          300 seconds (5 minutes) — data point interval
Evaluation:      3 out of 3 periods → must breach 3 consecutive periods
Datapoints:      N of M evaluation (e.g., 3 out of 5 periods)
```

### Alarm Actions

| Action | Use Case |
|--------|---------|
| **SNS notification** | Email, SMS, PagerDuty, Slack (via Lambda) |
| **EC2 action** | Stop, Start, Terminate, Reboot instance |
| **Auto Scaling** | Add/remove instances from ASG |
| **Systems Manager** | Run automation runbook |
| **Lambda** | Custom remediation logic |

```yaml
# Alarm → SNS → Lambda → auto-remediate
Alarm: EC2 CPU > 90% for 3 periods
  → SNS topic: ops-alerts
    → Email: on-call engineer
    → Lambda: snapshot instance + send PagerDuty alert
```

### Composite Alarms

```
Multiple alarms combined with AND/OR logic:
  ALARM if: (CPU > 90% AND Memory > 85%)   ← avoid false positives
  ALARM if: (5xx errors > 100 OR latency > 5s)

Benefits:
  Reduce alert noise — only alarm when multiple signals agree
  Create a "service health" rollup alarm from individual metric alarms
```

### Anomaly Detection Alarms ⭐

```
Instead of static threshold → use ML-learned band of expected values:

CloudWatch trains model on 2 weeks of metric history
  → Learns hourly, daily, weekly patterns
  → Creates expected value band (configurable width in std deviations)

Alarm triggers when metric goes OUTSIDE the band:
  ANOMALY_DETECTION_BAND(m1, 2)  ← 2 = number of standard deviations

Example:
  Normal traffic: 1,000–5,000 req/min (varies by time of day)
  Static threshold alarm: > 8,000 → many false positives on peak hours
  Anomaly detection: > expected range for this time of day → accurate

Use cases:
  Traffic spikes that are unusual for the current time
  Lambda duration deviating from normal
  Error rates deviating from baseline
  Business metrics (orders/minute) dropping unexpectedly
```

---

## 4. CloudWatch Logs ⭐

### Log Hierarchy

```
Log Group   → container for a service/application
  └── Log Stream → sequence of events from one source (one EC2, one Lambda)
       └── Log Events → individual timestamped log entries
```

### Log Sources

| Source | How Logs Get to CloudWatch |
|--------|--------------------------|
| Lambda | Automatic — every Lambda writes to `/aws/lambda/<function-name>` |
| EC2 | CloudWatch Agent required |
| ECS/EKS | awslogs log driver / Fluent Bit |
| API Gateway | Enable access logging in stage settings |
| VPC Flow Logs | Enable on VPC/subnet/ENI → destination CloudWatch |
| CloudTrail | Enable CloudWatch Logs integration on trail |
| RDS | Enable enhanced monitoring + slow query logs |
| Load Balancer | Enable access logs (goes to S3) — not native CW |

### Log Retention

```
Default: logs kept forever (never expire) — accrues cost indefinitely
Set retention: 1 day, 3 days, 5 days, 1 week, 2 weeks, 1/3/6 months, 1/2/5/10 years

Best practice:
  Dev log groups:  7 days
  Prod app logs:   90 days → then archive to S3 via subscription
  Audit logs:      1–7 years (compliance)
```

### Metric Filters

Extract metric values FROM log data:

```
Log group: /aws/lambda/order-processor
Filter pattern: [timestamp, requestId, level="ERROR", ...]
→ Creates metric: LambdaErrors (count of matching lines)
→ Create alarm on this metric

Example patterns:
  "ERROR"                          ← any line containing ERROR
  "[ERROR]"                        ← literal [ERROR]
  { $.statusCode = 500 }           ← JSON log: statusCode field = 500
  { $.latency > 1000 }             ← JSON log: latency > 1000ms
```

---

## 5. CloudWatch Logs Insights ⭐

**Interactive query engine** for searching and analyzing log data using
a purpose-built query language:

```sql
-- Most common query pattern: find errors in last 1 hour
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50

-- Top 10 slowest Lambda invocations
fields @timestamp, @duration, @requestId
| filter @type = "REPORT"
| sort @duration desc
| limit 10

-- Error rate percentage
fields @timestamp, @message
| stats
    count(*) as totalRequests,
    sum(@message like /ERROR/) as errors
| project errors/totalRequests * 100 as errorRate

-- Parse custom log format
fields @message
| parse @message "user=* action=* duration=*ms" as user, action, duration
| stats avg(duration) by action
| sort avg_duration desc

-- Lambda cold starts
fields @timestamp, @initDuration
| filter @initDuration > 0
| stats count() as coldStarts, avg(@initDuration) as avgInitMs

-- VPC Flow Log: top talkers
fields srcAddr, dstAddr, bytes
| stats sum(bytes) as totalBytes by srcAddr, dstAddr
| sort totalBytes desc
| limit 10
```

```
Key commands:
  fields    → select specific fields to return
  filter    → where clause (like SQL WHERE)
  stats     → aggregate: count, sum, avg, min, max, percentile
  sort      → order results
  limit     → cap result count
  parse     → extract fields from unstructured log text
  dedup     → remove duplicates by field
  display   → rename/format fields in output

Time range: query logs from any time window (up to retention period)
Supports: all log groups simultaneously (cross-log-group query)
```

---

## 6. CloudWatch Logs — Subscriptions and Export

### Subscription Filter (Real-time Streaming)

```
Stream logs in real-time to:
  Lambda           → process and forward to Elasticsearch/Splunk/custom
  Kinesis Data Streams    → high-volume real-time processing
  Kinesis Firehose → buffer and deliver to S3/Datadog/Splunk

Use case:
  /aws/lambda/api → subscription filter → Kinesis → Firehose → S3
  → Centralized log archive at low cost
```

### S3 Export (Batch)

```
Export historical log data to S3:
  CreateExportTask API → exports to S3 (takes minutes to hours)
  Not real-time — up to 12 hours delay

Use for: compliance archiving, bulk analysis in Athena
```

---

## 7. CloudWatch Agent ⭐

Required for OS-level metrics and custom application logs from EC2:

```
Collects:
  Memory utilization (RAM)
  Disk space per mount point
  Disk I/O per device
  Network metrics per interface
  Process metrics
  Custom app logs (tail any log file)
  StatsD / collectd metrics from applications

Install:
  SSM Run Command (recommended for fleets)
  Or manually: yum install amazon-cloudwatch-agent

Configure:
  /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  Or use: aws-cloudwatch-agent-config-wizard (interactive)

IAM role needed:
  CloudWatchAgentServerPolicy (attach to EC2 instance profile)
```

---

## 8. CloudWatch Dashboards

```
Global service — view metrics from any region on one dashboard
Share with: AWS accounts, email (public link), third parties (no AWS login)

Widget types:
  Line chart     → trends over time
  Number         → current metric value (CPUUtilization: 34%)
  Gauge          → visual meter
  Bar chart      → comparison
  Text           → markdown annotations and runbook links
  Alarm status   → traffic light for multiple alarms
  Log table      → embedded Logs Insights query result
  Explorer       → auto-discover and graph tagged resources

Automatic dashboards:
  AWS creates default dashboards for each service → CloudWatch → Dashboards → Automatic
  EC2, Lambda, RDS, ELB etc. — pre-built, no configuration needed
```

---

## 9. CloudWatch Synthetics (Canary Monitoring)

```
Runs scripted synthetic transactions against your application endpoints
  → Detects issues BEFORE real users do
  → Monitors availability and performance from outside your system

Canary types:
  Heartbeat monitor:  GET your URL → check 200 response
  API canary:         series of API calls → validate responses
  Broken link check:  crawl pages → find broken links
  GUI workflow:       Puppeteer script → simulate user login/checkout
  Visual monitoring:  screenshot comparison (detects UI regressions)

Schedule: every 1 minute to every 1 hour
Stores: screenshots, HAR files, Lambda execution logs in S3
Metrics: SuccessPercent, Duration → create alarms on them

Use case:
  Alarm: canary SuccessPercent < 100% for 3 minutes
  → Trigger PagerDuty before your monitoring team notices
```

---

## 10. CloudWatch ServiceLens and X-Ray Integration

```
ServiceLens = CloudWatch Metrics + Logs + X-Ray Traces unified view
  → Map of microservices with health, latency, error rate per service
  → Click any service → drill into its traces
  → Click any trace → see which Lambda/EC2/DynamoDB call is slow

X-Ray adds to CloudWatch:
  Distributed tracing: follow one request across Lambda → API Gateway → DynamoDB
  Service map: visual dependency graph with latency/error annotations
  Segments + subsegments: timing breakdown of each component

Enable tracing:
  Lambda: X-Ray active tracing → one checkbox
  EC2: install X-Ray daemon
  ECS: X-Ray sidecar container
```

---

## 11. CloudWatch Pricing

```
Metrics:
  AWS default metrics:  free
  Custom metrics:       $0.30/metric/month (first 10,000 metrics)
  High-resolution:      $0.02/metric/month additional

Alarms:
  Standard resolution:  $0.10/alarm/month
  High-resolution:      $0.30/alarm/month
  Composite alarms:     $0.50/alarm/month

Logs:
  Ingestion:    $0.50/GB
  Storage:      $0.03/GB/month
  Insights query: $0.005/GB scanned

Dashboards:
  First 3 dashboards: free
  After: $3/dashboard/month

Synthetics canaries:
  $0.0012 per canary run
```

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| CloudWatch monitors EC2 RAM by default | RAM is OS-level — requires **CloudWatch Agent** |
| Logs are automatically deleted | Default retention: **forever** — always set a retention policy |
| One alarm = one threshold | Use **composite alarms** to reduce noise; use **anomaly detection** for dynamic workloads |
| Alarm actions only send emails | Alarms can trigger: **EC2 actions, Auto Scaling, Systems Manager, Lambda, SNS** |
| Logs Insights only queries one log group | Logs Insights can query **multiple log groups simultaneously** |
| Alarm on INSUFFICIENT_DATA = problem | INSUFFICIENT_DATA just means not enough data yet — new resources often start here |
| CloudWatch is region-specific only | **Dashboards** are global — can show metrics from any region in one dashboard |
| Custom metrics cost the same as standard | High-resolution custom metrics (1-second) cost **more** than standard (1-minute) |

---

## 13. Interview Questions Checklist

- [ ] Three pillars of observability — which does CloudWatch cover?
- [ ] Which EC2 metrics are NOT available by default? What do you need?
- [ ] Metric retention periods — what happens to 1-second data after 3 hours?
- [ ] Three alarm states — what does INSUFFICIENT_DATA mean?
- [ ] Five alarm actions — name all of them
- [ ] What is a composite alarm? Why use it?
- [ ] What is anomaly detection? How does it differ from a static threshold?
- [ ] Write a Logs Insights query: top 10 slowest Lambda invocations
- [ ] What is a metric filter? What does it do?
- [ ] CloudWatch Agent — what does it add? What IAM policy does it need?
- [ ] Real-time log streaming — what are the three destinations?
- [ ] What is CloudWatch Synthetics? What does a canary do?
