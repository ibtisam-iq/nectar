# AWS Route 53

## 1. What is Route 53?

Amazon Route 53 is a **globally distributed, highly available DNS (Domain Name System)
and domain registration service**. It routes end-user traffic to applications by
translating human-readable domain names into machine-readable IP addresses, and it
can also monitor the health of your endpoints.

```
Three functions in one service:
  1. Domain Registration    → buy and manage domain names
  2. DNS Management         → host DNS records for your domains
  3. Health Checking        → monitor endpoints and failover automatically
```

> The name "Route 53" references DNS port **53** — the standard UDP/TCP port
> used for all DNS queries worldwide.

---

## 2. How DNS Resolution Works ⭐

```
User types: ibtisam-iq.com in browser

Step 1: Browser checks local DNS cache (OS cache)
  → If cached and TTL not expired → use cached IP, done

Step 2: Browser asks Recursive Resolver (your ISP or 8.8.8.8)
  → Recursive Resolver checks its own cache
  → If cached → return IP, done

Step 3: Recursive Resolver asks Root Name Server (.)
  → Root Server: "I don't know ibtisam-iq.com, but .com is handled by these TLD servers"
  → Returns TLD server addresses for .com

Step 4: Recursive Resolver asks TLD Name Server (.com)
  → TLD: "I don't know the IP, but the authoritative server is ns-123.awsdns-45.com"
  → Returns authoritative server addresses

Step 5: Recursive Resolver asks Authoritative Name Server (Route 53)
  → Route 53: "ibtisam-iq.com → 3.14.15.92"
  → Returns the actual IP address

Step 6: Browser connects to 3.14.15.92
  → Result cached by Recursive Resolver for TTL duration
```

```
Key insight:
  Root Server   → knows who handles each TLD (.com, .io, .pk)
  TLD Server    → knows which name server is authoritative for each domain
  Auth Server   → knows the actual IP (Route 53 is this for your domain)
  Only the Authoritative Server has your real DNS records
```

---

## 3. Domain Registrar vs DNS Provider vs CDN ⭐

These are three separate concepts that are commonly confused:

| Role | Responsibility | Examples |
|------|---------------|---------|
| **Domain Registrar** | Owns the domain name lease; controls NS record delegation | GoDaddy, Namecheap, Route 53 Registrar |
| **DNS Provider** | Hosts DNS records; resolves domain → IP | Route 53, Cloudflare DNS, GoDaddy DNS |
| **CDN / Proxy** | Caches and serves content at edge locations; hides origin IP | Cloudflare CDN, CloudFront, Fastly |
| **Hosting / Origin** | Runs the actual application | GitHub Pages, EC2, Vercel, Netlify |

```
Your personal site setup (example):
  GoDaddy     → Registrar (you own ibtisam-iq.com)
  Cloudflare  → DNS provider + CDN + WAF
  GitHub Pages → Hosting (where HTML/CSS/JS files live)

Flow:
  User → Cloudflare DNS (resolves domain) → Cloudflare Edge (CDN cache)
       → GitHub Pages (origin server, if cache miss)
```

### Why You Change Name Servers

When you buy a domain from GoDaddy but want Route 53 to manage DNS:

```
Step 1: Create Hosted Zone in Route 53 for your domain
  → Route 53 gives you 4 name servers:
    ns-1234.awsdns-12.com
    ns-5678.awsdns-34.net
    ns-9012.awsdns-56.org
    ns-3456.awsdns-78.co.uk

Step 2: Log in to GoDaddy → change Name Servers to the above 4
  → GoDaddy now says: "For ibtisam-iq.com, ask Route 53"
  → Propagation: 24–48 hours for global DNS caches to update

You are delegating DNS authority from GoDaddy → Route 53
GoDaddy still owns the domain registration
Route 53 now controls all DNS records
```

---

## 4. Hosted Zone ⭐

A hosted zone is a **container for DNS records** for a single domain and its subdomains.

| Type | Use Case | Cost |
|------|---------|------|
| **Public Hosted Zone** | Domain accessible on public internet | $0.50/month |
| **Private Hosted Zone** | Domain accessible only within a VPC | $0.50/month |

```
Public Hosted Zone: ibtisam-iq.com
  → api.ibtisam-iq.com → 3.14.15.92    (public EC2)
  → www.ibtisam-iq.com → CloudFront
  → mail.ibtisam-iq.com → MX records

Private Hosted Zone: internal.corp
  → db.internal.corp → 10.0.2.15       (private RDS IP)
  → cache.internal.corp → 10.0.3.8     (private ElastiCache)
  (Only visible to EC2 inside your VPC — internet cannot resolve these)
```

### Default Records in Every Hosted Zone

| Record | Purpose |
|--------|---------|
| **NS (Name Server)** | 4 Route 53 name servers — copy these to your registrar |
| **SOA (Start of Authority)** | Zone metadata: primary NS, admin email, serial number, TTL defaults |

---

## 5. DNS Record Types ⭐

### A Record — Domain → IPv4

```
Name: ibtisam-iq.com
Type: A
Value: 3.14.15.92
TTL: 300

Usage: point root domain or subdomain to an IPv4 address
```

### AAAA Record — Domain → IPv6

```
Name: ibtisam-iq.com
Type: AAAA
Value: 2001:0db8:85a3::8a2e:0370:7334
Usage: IPv6 traffic
```

### CNAME Record — Domain → Another Domain

```
Name: www.ibtisam-iq.com
Type: CNAME
Value: ibtisam-iq.com
TTL: 300

Usage: alias one domain to another
Restriction: CNAME CANNOT be used at the zone apex (root domain)
  ❌ ibtisam-iq.com CNAME something.com   ← invalid per DNS spec
  ✅ www.ibtisam-iq.com CNAME something.com  ← valid (subdomain)
```

### MX Record — Mail Routing

```
Name: ibtisam-iq.com
Type: MX
Priority: 10
Value: mail.ibtisam-iq.com

Multiple MX records with different priorities → mail tries lowest priority number first
```

### TXT Record — Verification / SPF / DKIM

```
Name: ibtisam-iq.com
Type: TXT
Value: "v=spf1 include:_spf.google.com ~all"       ← SPF (prevents email spoofing)
Value: "google-site-verification=abc123..."         ← verify domain for Google Search Console
Value: "MS=ms12345..."                              ← verify for Microsoft 365
```

### NS Record — Name Server Delegation

```
Name: ibtisam-iq.com
Type: NS
Value: ns-1234.awsdns-12.com
       ns-5678.awsdns-34.net
       ...

Delegates authority for domain (or subdomain) to these name servers
```

### PTR Record — Reverse DNS

```
Name: 92.15.14.3.in-addr.arpa
Type: PTR
Value: mail.ibtisam-iq.com

Usage: verify that IP 3.14.15.92 belongs to ibtisam-iq.com
Used by: email servers to validate sending IP
```

### SRV Record — Service Location

```
Usage: Kubernetes, SIP, XMPP
Format: priority weight port target
```

### Record Type Summary

| Record | Maps | Use Case |
|--------|------|---------|
| A | Domain → IPv4 | Website, API server |
| AAAA | Domain → IPv6 | IPv6 traffic |
| CNAME | Domain → Domain | Subdomain alias (not zone apex) |
| Alias | Domain → AWS resource | Zone apex + AWS services (Route 53-specific) |
| MX | Domain → Mail server | Email routing |
| TXT | Domain → Text | Verification, SPF, DKIM |
| NS | Domain → Name servers | Delegation |
| PTR | IP → Domain | Reverse DNS, email validation |
| SRV | Domain → Service endpoint | Service discovery |

---

## 6. Alias Record (AWS-Specific) ⭐

Alias is a **Route 53 extension to DNS** — not a standard DNS record type.
It solves the problem CNAME cannot:

```
Problem:
  You have an ELB: my-lb-123.us-east-1.elb.amazonaws.com
  You want: ibtisam-iq.com → my ELB
  But CNAME cannot be set on zone apex (ibtisam-iq.com)

Solution: Alias Record
  Name: ibtisam-iq.com
  Type: A (Alias)
  Alias target: my-lb-123.us-east-1.elb.amazonaws.com
  → Works at zone apex ✅
  → Route 53 automatically resolves the ELB to its current IP(s)
  → If ELB IPs change, Alias auto-updates — no manual intervention
```

### CNAME vs Alias Comparison ⭐

| Feature | CNAME | Alias |
|---------|-------|-------|
| Use at zone apex | ❌ No | ✅ Yes |
| DNS query cost | Charged | **Free** |
| Target type | Any domain | AWS resource only |
| TTL configurable | ✅ Yes | ❌ No (Route 53 manages) |
| Health check support | Indirect | ✅ Native |
| Works with ELB / CloudFront / S3 | No (use Alias) | ✅ Yes |

### Valid Alias Targets

- Elastic Load Balancers (ALB, NLB, CLB)
- CloudFront distributions
- API Gateway endpoints
- S3 static website endpoints
- Elastic Beanstalk environments
- VPC Interface Endpoints
- Another Route 53 record in same hosted zone

> **Cannot use Alias for EC2 DNS names** (e.g., `ec2-xxx.compute.amazonaws.com`).
> Use A record with IP instead.

---

## 7. TTL (Time To Live) ⭐

```
TTL = how long (seconds) a DNS resolver should cache the record before asking again

Low TTL (60–300s):
  ✅ DNS changes propagate quickly
  ❌ More DNS queries → more Route 53 cost
  Use before planned changes (reduce TTL 24h before migration)

High TTL (3600–86400s):
  ✅ Faster response (cache hit), less Route 53 cost
  ❌ DNS changes take longer to propagate
  Use for stable records that rarely change

Practical rule:
  Normal operations:      300s–3600s
  Before a migration:     Set to 60s (24hrs in advance)
  After migration stable: Increase back to 3600s
```

---

## 8. Routing Policies ⭐

### 1. Simple Routing

```
One record → one or more IPs (no health checks on single record)
Multiple IPs in one record → client picks one at random

Use: single backend, basic setups
Limitation: no health checks → client may pick unhealthy IP
```

### 2. Weighted Routing

```
Multiple records with same name, different weights
Route 53 distributes traffic proportionally to weights

Example:
  Record A: 10.0.0.1  Weight: 70
  Record B: 10.0.0.2  Weight: 20
  Record C: 10.0.0.3  Weight: 10
  → 70% → A, 20% → B, 10% → C

Use cases:
  A/B testing new version (send 5% to v2)
  Gradual traffic migration (shift 0→10→50→100% to new region)
  Load distribution across servers

Weight = 0 → record not served (stop traffic without deleting record)
```

### 3. Latency-Based Routing

```
Routes user to the AWS Region with lowest network latency (not geographic distance)
Route 53 measures latency from user's location to each configured region

Example:
  User in Pakistan:
    Record: ec2-us-east-1.amazonaws.com   Region: us-east-1    latency: 180ms
    Record: ec2-me-south-1.amazonaws.com  Region: me-south-1   latency: 40ms
    → Route to me-south-1 (Bahrain) ✅

Note: latency ≠ geographic proximity always — routing is based on measured network
```

### 4. Failover Routing

```
Primary record: serves traffic when healthy
Secondary record: serves traffic when primary health check fails

Primary:   10.0.0.1  Type: PRIMARY   Health check: required
Secondary: 10.0.0.2  Type: SECONDARY Health check: optional

Flow:
  Primary healthy → all traffic → primary
  Primary fails health check → Route 53 automatically serves secondary
  Primary recovers → traffic returns to primary

Use case: active-passive disaster recovery
```

### 5. Geolocation Routing

```
Routes based on the geographic location of the DNS query origin
  (the country/continent of the user's recursive resolver)

Records:
  Location: US → 1.2.3.4
  Location: EU → 5.6.7.8
  Location: Default → 9.10.11.12  ← REQUIRED fallback for unmatched locations

Example:
  French user → EU record
  Brazilian user → Default record (no South America record)
  US user → US record

Use cases:
  Legal compliance (GDPR — EU users must hit EU servers)
  Content localization (language-specific content)
  Blocking regions (no default record = users from other regions get NXDOMAIN)
```

### 6. Geoproximity Routing

```
Routes based on geographic distance between user and resource
  WITH optional bias to expand/shrink effective geographic region

Bias: +1 to +99 (expand region) or -1 to -99 (shrink region)

Bias formula:
  Biased distance = actual distance × [1 - (bias/100)]
  Positive bias = resource appears closer → attracts more traffic
  Negative bias = resource appears farther → attracts less traffic

Example:
  Server A: us-east-1, bias: +50
  Server B: eu-west-1, bias: 0
  User equidistant between A and B:
    → A gets more traffic (positive bias makes A appear 50% closer)

Use case:
  Shift traffic from one region to another gradually
  Requires Route 53 Traffic Flow (visual editor)
```

### 7. Multi-Value Answer Routing

```
Returns up to 8 healthy IP addresses per DNS query
Client randomly picks one from the returned list

Similar to: Simple routing with multiple IPs
Difference: integrates with health checks — unhealthy IPs removed from response

Use case:
  Distribute traffic across multiple web servers without a load balancer
  NOT a replacement for a proper load balancer (ELB)
```

### 8. IP-Based Routing (CIDR-Based)

```
Routes based on client's IP address CIDR range
You define CIDR collections → map each collection to an endpoint

Example:
  CIDR: 203.0.113.0/24 (corporate network) → internal server
  CIDR: 0.0.0.0/0 (everyone else) → public server

Use cases:
  Corporate VPN users → internal resources
  ISP-specific routing (partner ISPs → dedicated capacity)
  Regional routing by known IP ranges
```

### Routing Policy Selection Guide ⭐

| Goal | Policy |
|------|--------|
| Single backend, simple setup | Simple |
| A/B testing, gradual migration | Weighted |
| Lowest latency per user | Latency |
| Active-passive DR | Failover |
| Compliance by country (GDPR) | Geolocation |
| Fine-tune traffic by distance + bias | Geoproximity |
| Multiple healthy IPs, no load balancer | Multi-Value |
| Corporate network vs public routing | IP-Based |

---

## 9. Health Checks ⭐

Route 53 health checkers run from **multiple AWS locations worldwide**
and check your endpoint independently.

### Three Health Check Types

**1. Endpoint Health Check**

```
Monitors: IP address or domain name
Protocol: HTTP, HTTPS, TCP
Interval: 30s (standard) or 10s (fast — additional cost)
Failure threshold: 3 failures = unhealthy (configurable 1–10)
String matching: check for specific string in response body (first 5,120 bytes)

Health check passes if:
  HTTP/HTTPS: response code 2xx or 3xx AND (optional) string found
  TCP: connection established successfully
```

**2. Calculated Health Check**

```
Combines results of multiple child health checks
Logic options: AND (all must pass), OR (any must pass), NOT
Min healthy count: specify minimum N children must be healthy

Use case:
  Application is healthy only if: web layer healthy AND database layer healthy
  → Create child checks for each → calculated check combines them
```

**3. CloudWatch Alarm Health Check**

```
Based on a CloudWatch alarm state (OK / ALARM / INSUFFICIENT_DATA)
Use case: private resources (EC2 in VPC) — Route 53 health checkers
          cannot reach private IPs directly
  → Create CloudWatch metric on private resource
  → Create alarm on that metric
  → Route 53 monitors the alarm state
```

### Health Checks for Private Resources

```
Route 53 health checkers run from public internet
  → Cannot reach private EC2 instances or private RDS

Solution:
  1. CloudWatch Metric + Alarm on private resource
  2. Route 53 Calculated/CloudWatch Alarm health check monitors the alarm
  → Indirect but effective health monitoring
```

---

## 10. Route 53 — Special Architectures

### Subdomain Delegation

```
You can delegate a subdomain to a different hosted zone or team:

Main company:  example.com           hosted in central Route 53
API team:      api.example.com       delegated to team's own hosted zone

In main hosted zone:
  NS record: api.example.com → ns-api-1.awsdns-xx.com
                                 ns-api-2.awsdns-xx.net
  → DNS queries for api.example.com forwarded to team's name servers
  → Team manages all api.example.com records independently
```

### Route 53 + CloudFront + S3 (Static Website Pattern)

```
domain: ibtisam-iq.com
  → Route 53 Alias → CloudFront distribution
  → CloudFront origin → S3 static bucket

Benefits:
  HTTPS on root domain (Alias + ACM certificate)
  Global CDN caching
  No direct S3 access (bucket can be private, only CloudFront reads it)
```

---

## 11. Route 53 Resolver (Hybrid DNS) ⭐

Enables DNS resolution between **on-premises networks and AWS VPCs**:

### Default VPC DNS

```
Every VPC has a built-in DNS resolver at:
  VPC base IP + 2 (e.g., 10.0.0.2 for a 10.0.0.0/16 VPC)
Resolves: AWS public hostnames, private hosted zones attached to VPC
```

### Inbound Endpoint

```
On-premises DNS servers can resolve AWS private hosted zone records

On-premises → VPN/Direct Connect → Inbound Endpoint (in VPC)
  → Route 53 Resolver resolves private hosted zone record
  → Returns IP → back to on-premises application

Use case: on-premises app calls internal AWS microservice by private DNS name
```

### Outbound Endpoint

```
VPC resources can resolve on-premises DNS names

EC2 in VPC → Outbound Endpoint → forwarding rule → on-premises DNS server
  → On-premises server resolves corp.internal domain
  → Returns IP → EC2 connects to on-premises resource

Use case: AWS Lambda needs to connect to on-premises database using internal hostname
```

### Resolver Rules

```
Forwarding rule: "for domain corp.internal, forward queries to 10.1.1.53"
System rule: built-in rules for AWS private hosted zones (auto-managed)
Recursive rule: default — resolve everything else using public DNS
```

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| CNAME can be used for root domain | CNAME **cannot** be at zone apex — use Alias instead |
| Alias and CNAME are the same | Alias is free, auto-updates, works at apex; CNAME is charged, generic, not at apex |
| Geolocation = Geoproximity | Geolocation routes by **country/continent**; Geoproximity routes by **distance with bias** |
| Changing NS records takes instant effect | NS changes propagate in **24–48 hours** (DNS cache TTL) |
| Route 53 hosts your application | Route 53 only resolves DNS — your app still runs on EC2/S3/ELB |
| Health checks directly monitor private IPs | Route 53 health checkers are public — use CloudWatch Alarm for private resources |
| Multi-Value is the same as ELB | Multi-Value returns up to 8 IPs with health checks — not a full load balancer |
| Low TTL costs nothing extra | Lower TTL = more DNS queries = **more Route 53 query charges** |
| SOA record is optional | SOA is **automatically created** in every hosted zone — cannot be deleted |
| Failover works without health checks | Failover routing **requires health checks** on the primary record |

---

## 13. Interview Questions Checklist

- [ ] What are Route 53's three main functions?
- [ ] Walk through DNS resolution step-by-step (6 steps)
- [ ] What is the difference between a registrar and a DNS provider?
- [ ] Why do you change name servers when switching DNS provider?
- [ ] Public vs private hosted zone — when to use each?
- [ ] CNAME vs Alias — 5 differences; when must you use Alias?
- [ ] Why can't a CNAME be set on the zone apex?
- [ ] What are all eight routing policies? Give a use case for each
- [ ] Geolocation vs Geoproximity — how do they differ?
- [ ] What is bias in Geoproximity routing? Positive vs negative?
- [ ] Three types of health checks — when to use each?
- [ ] How do you health-check a private EC2 instance?
- [ ] What is a Calculated Health Check?
- [ ] What happens to failover routing when primary health check fails?
- [ ] How does Route 53 Resolver handle hybrid DNS?
- [ ] Inbound vs Outbound Resolver endpoint — direction of each?
- [ ] What TTL strategy do you use before a planned DNS migration?
- [ ] What records are automatically created in every hosted zone?

## Nectar
