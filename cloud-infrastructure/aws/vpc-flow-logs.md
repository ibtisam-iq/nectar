# VPC Flow Logs

## Definition

VPC Flow Logs capture **IP traffic metadata** going to and from network interfaces.
They record who talked to whom, on what port, with what result — but never the
actual content of the packets.

```
What Flow Logs capture:   WHO, WHEN, WHERE, HOW MUCH, ACCEPT or REJECT
What Flow Logs DON'T:     WHAT (no payload, no DNS query content, no HTTP body)
```

---

## Scope — Three Levels

| Level | Captures |
|-------|---------|
| **VPC** | All ENIs in the entire VPC |
| **Subnet** | All ENIs in that specific subnet |
| **ENI** | Only that specific network interface |

---

## Destinations ⭐

| Destination | Real-Time? | Best For |
|-------------|-----------|---------|
| **CloudWatch Logs** | Near real-time | Querying with CloudWatch Insights, alerting |
| **S3** | Delayed (5–15 min) | Long-term storage, Athena queries, cheap archival |
| **Kinesis Data Firehose** | Real-time streaming | SIEM tools (Splunk, Datadog), custom HTTP endpoints |

> Kinesis Data Firehose was added in October 2022 — enables real-time delivery
> to Splunk, Elasticsearch, custom HTTP endpoints without Lambda

---

## Log Format — Default Fields

```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes windowstart windowend action flow-direction log-status
```

**Example record:**
```
2 123456789012 eni-abc12345 10.0.1.10 8.8.8.8 52344 443 6 10 840 1629000000 1629000060 ACCEPT egress OK
```

| Field | Value | Meaning |
|-------|-------|---------|
| version | 2 | Flow log format version |
| account-id | 123456789012 | AWS account |
| interface-id | eni-abc12345 | ENI that captured traffic |
| srcaddr | 10.0.1.10 | Source IP |
| dstaddr | 8.8.8.8 | Destination IP |
| srcport | 52344 | Source port (ephemeral) |
| dstport | 443 | Destination port (HTTPS) |
| protocol | 6 | TCP (6=TCP, 17=UDP, 1=ICMP) |
| packets | 10 | Packet count in interval |
| bytes | 840 | Bytes transferred |
| action | ACCEPT | Allowed or rejected by SG/NACL |
| log-status | OK | Log delivery status |

**Custom format:** You can add or remove fields — including newer fields like
`pkt-srcaddr`, `pkt-dstaddr` (original IPs behind NAT), `vpc-id`, `subnet-id`,
`instance-id`, `flow-direction`.

---

## Traffic NOT Captured ⭐ (Critical — Exam Trap)

| Traffic Type | Why Excluded |
|-------------|-------------|
| **Instance metadata** (`169.254.169.254`) | AWS internal service — excluded by design |
| **Amazon Time Sync** (`169.254.169.123`) | AWS internal service |
| **DHCP traffic** | Infrastructure-level — excluded |
| **DNS queries to AmazonProvidedDNS** | AWS internal DNS — excluded |
| **Windows license activation** | AWS internal traffic |
| **VPC router reserved IP** (`x.x.x.1`) | Infrastructure-level |
| **Traffic Mirror source traffic** | Mirrored traffic is only shown at target |
| **NLB ↔ endpoint network interfaces** | Internal LB mechanism |

> **Key:** If you use your **own DNS server**, DNS queries to it ARE logged.
> Only queries to `AmazonProvidedDNS` are excluded.

---

## Aggregation Interval

| Interval | Default? | Use Case |
|----------|---------|---------|
| **10 minutes** | Older default | Lower cost, delayed analysis |
| **1 minute** | Modern default | Faster troubleshooting, near real-time |

> Flow logs are NOT real-time. There is always a delivery delay
> (minutes for CloudWatch, up to 15 min for S3).

---

## What You Can Analyze

| Use Case | CloudWatch Insights Query |
|---------|--------------------------|
| Who is being blocked? | Filter `action = "REJECT"` → group by srcaddr |
| Port scan detection | Count rejected packets per source IP |
| Top talkers | Sum bytes by srcaddr + dstaddr |
| Failed SSH attempts | Filter dstport=22 + action=REJECT |
| Data exfiltration | Anomalous high bytes to external IPs |

**Example CloudWatch Insights query:**
```sql
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter action = "REJECT" and ispresent(srcAddr)
| stats count() as rejectCount by srcAddr, dstPort
| sort rejectCount desc
| limit 20
```

---

## VPC Traffic Mirroring — vs Flow Logs

Flow Logs = metadata only.
If you need **actual packet capture** (full payload inspection):

| Feature | Flow Logs | Traffic Mirroring |
|---------|-----------|-----------------|
| Captures | Metadata (IPs, ports, action) | Full packet payload |
| Use case | Traffic analysis, security auditing | Deep packet inspection, IDS/IPS |
| Destination | CloudWatch, S3, Firehose | Another ENI (e.g., monitoring appliance) |
| Cost | Storage cost only | Instance cost for mirror target |
| Privacy concern | Low (no payload) | High (actual data content) |

---

## Comparison — Flow Logs vs SG vs NACL

| Tool | Layer | Purpose | Reactive? |
|------|-------|---------|----------|
| **Security Group** | ENI | Control what traffic is allowed | ✅ Blocks traffic |
| **NACL** | Subnet | Control what traffic is allowed (subnet boundary) | ✅ Blocks traffic |
| **VPC Flow Logs** | ENI/Subnet/VPC | Observe and record traffic metadata | ❌ Cannot block anything |
| **Traffic Mirroring** | ENI | Capture actual packet payload | ❌ Cannot block anything |

> Flow Logs is a **passive observer** — it never affects traffic flow.
> It records what SGs and NACLs allow or deny — useful for verifying your rules work.

---

## Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Only 2 Flow Log destinations | Three: CloudWatch, S3, and **Kinesis Data Firehose** (since 2022) |
| Flow Logs capture all traffic | DNS to AmazonProvidedDNS, DHCP, metadata (169.254.x.x), Time Sync are excluded |
| Flow Logs capture DNS queries | DNS to AmazonProvidedDNS is excluded; own DNS server traffic IS captured |
| Flow Logs are real-time | Delivery is delayed — minutes for CWL, up to 15 min for S3 |
| Flow Logs = packet capture | Flow Logs capture metadata only — use Traffic Mirroring for payload |
| Flow Logs can block traffic | Flow Logs are passive observers — cannot allow or deny anything |

---

### 2.11 Interview Questions Checklist

- [ ] What are VPC Flow Logs?
- [ ] What are the three destinations for Flow Logs? (CWL, S3, Kinesis Firehose)
- [ ] What are the three scope levels for Flow Logs?
- [ ] Name 4 types of traffic that Flow Logs do NOT capture
- [ ] What is the aggregation interval for Flow Logs?
- [ ] Are Flow Logs real-time? (No — delayed delivery)
- [ ] Flow Logs vs Traffic Mirroring — what is the key difference?
- [ ] Can Flow Logs block traffic? (No — passive observer only)
- [ ] Write a CloudWatch Insights query to find the top sources of rejected traffic
