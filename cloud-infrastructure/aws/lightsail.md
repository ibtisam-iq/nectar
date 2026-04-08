# Amazon Lightsail

## 1. What is Lightsail?

Amazon Lightsail is AWS's **simplified cloud platform** — a Virtual Private
Server (VPS) service designed for developers, small businesses, and individuals
who want to launch applications quickly without deep AWS expertise. It bundles
compute, storage, networking, and DNS into predictable flat monthly pricing.

```
EC2 model:
  Choose AMI → choose instance type → configure VPC → attach EBS →
  configure Security Group → set up Elastic IP → manage networking
  → Deep AWS knowledge required, many moving parts, variable cost

Lightsail model:
  Choose blueprint → choose bundle → click Launch → done ✅
  Simplified console, flat monthly price, everything pre-configured
  → No AWS expertise needed
```

### Lightsail vs EC2 — When to Use Which

| Dimension | Lightsail | EC2 |
|-----------|----------|-----|
| Audience | Beginners, small apps, VPS migrants | Engineers building production systems |
| Pricing | Flat monthly (predictable) | Variable by-the-second (complex) |
| Networking | Simplified (no VPC config) | Full VPC control |
| Scaling | Manual or basic auto-scaling | Full Auto Scaling Groups |
| Integration | Limited AWS service integration | Deep integration with all AWS services |
| Max size | Up to 72 vCPUs (compute-optimized) | Hundreds of vCPUs (bare metal) |
| Use case | WordPress, simple web apps, VPS migration | Any enterprise-grade workload |

> Lightsail can **peer with a VPC** — so you can connect a Lightsail instance
> to RDS, ElastiCache, or other VPC resources if needed.

---

## 2. Core Lightsail Components

```
Lightsail offers six resource types:
  1. Instances        → virtual servers (Linux + Windows)
  2. Containers       → managed container service
  3. Databases        → managed MySQL and PostgreSQL
  4. Storage          → object storage (S3-compatible)
  5. Load Balancers   → managed HTTP/HTTPS load balancer
  6. CDN Distributions → CloudFront-backed CDN
  + DNS (free):       → manage domain DNS records
  + Snapshots:        → instance and database backups
  + Static IPs:       → fixed public IP addresses
```

---

## 3. Instances ⭐

### Blueprints (Pre-configured Images)

A blueprint is a **pre-built image** with OS + application already installed:

**OS Blueprints:**
```
Amazon Linux 2023
Ubuntu 24.04 LTS
Debian 12
CentOS Stream 9
AlmaLinux 9
Windows Server 2022 / 2019 / 2016
FreeBSD
```

**Application Blueprints:**
```
WordPress           → most popular CMS (also WordPress Multisite)
cPanel & WHM        → web hosting control panel
Plesk               → hosting management platform
Drupal              → CMS
Magento             → e-commerce
Ghost               → blogging platform
Joomla              → CMS

LAMP Stack          → Linux + Apache + MySQL + PHP
MEAN Stack          → MongoDB + Express + Angular + Node.js
Node.js             → JavaScript runtime (updated Jan 2026) [aws.amazon](https://aws.amazon.com/about-aws/whats-new/2026/01/amazon-lightsail-nodejs-lamp-and-ruby-on-rails/)
Ruby on Rails       → full-stack Ruby framework (updated Jan 2026) [aws.amazon](https://aws.amazon.com/about-aws/whats-new/2026/01/amazon-lightsail-nodejs-lamp-and-ruby-on-rails/)
Django              → Python web framework
```

> **IMDSv2 enforced by default** on new blueprints (Node.js, LAMP, Ruby on Rails
> from January 2026) — more secure than IMDSv1.

### Instance Bundles (Plans)

A bundle = fixed combination of vCPU + RAM + SSD + data transfer at a flat monthly price:

**General Purpose (Linux):**

| Bundle | Monthly | vCPUs | RAM | SSD | Transfer |
|--------|---------|-------|-----|-----|---------|
| Nano | $3.50 | 2 | 512 MB | 20 GB | 1 TB |
| Micro | $7 | 2 | 1 GB | 40 GB | 2 TB |
| Small | $12 | 2 | 2 GB | 60 GB | 3 TB |
| Medium | $20 | 2 | 4 GB | 80 GB | 4 TB |
| Large | $40 | 2 | 8 GB | 160 GB | 5 TB |
| XLarge | $80 | 4 | 16 GB | 320 GB | 6 TB |
| 2XLarge | $160 | 8 | 32 GB | 640 GB | 7 TB |

> Windows bundles cost approximately 2× the Linux equivalent.
> Data transfer overage: $0.09/GB beyond included allowance.

**Compute-Optimized Bundles (NEW — April 2026):**

```
New compute-optimized tier — up to 72 vCPUs [aws.amazon](https://aws.amazon.com/about-aws/whats-new/2026/04/lightsail-compute-optimized-instances/)
7 sizes available, both IPv6-only and dual-stack networking
Ideal for:
  Batch processing, distributed analytics
  High-performance web servers
  Scientific modeling and simulation
  Dedicated gaming servers
  Ad serving engines
  Video encoding
  CPU-intensive ML inference
```

**Memory-Optimized Bundles:**
```
Higher memory-to-CPU ratio
Use for: in-memory caching, real-time analytics, high-performance databases
Example: Memory-optimized Large-16GB Linux: $70/month, 2 vCPUs, 16 GB RAM, 160 GB SSD, 5 TB [docs.aws.amazon](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-bundles.html)
```

### Instance Features

```
Static IP: assign a fixed public IP to instance (free while attached to running instance)
SSH access: browser-based SSH terminal in Lightsail console (no key required)
Firewall:  simplified rules (port-based allow list)
Snapshots: manual or automatic daily backups
Monitoring: CPU, network, status checks (built-in, no CloudWatch setup)
Metadata:  IMDSv2 enforced on new blueprints [aws.amazon](https://aws.amazon.com/about-aws/whats-new/2026/01/amazon-lightsail-nodejs-lamp-and-ruby-on-rails/)
```

---

## 4. Managed Databases ⭐

Fully managed MySQL and PostgreSQL — no OS patching, automatic backups:

```
Engines: MySQL 8.0, PostgreSQL 16
Bundles:
  Standard plan    → single-AZ (dev/test)
  High-availability → multi-AZ with standby replica (production)

New larger bundles (January 2026): [aws.amazon](https://aws.amazon.com/about-aws/whats-new/2026/01/larger-managed-database-bundles-lightsail/)
  Up to 8 vCPUs, 32 GB RAM, 960 GB SSD storage
  Available in both Standard and High-Availability

Features:
  Automatic daily snapshots (retained 7 days by default)
  Point-in-time restore
  Encryption at rest
  Automatic minor version upgrades
  Custom parameters
  Public or private endpoint

Connection:
  From Lightsail instance: use internal endpoint (free data transfer within same region)
  From EC2/Lambda: enable VPC peering + use internal endpoint
  From outside AWS: use public endpoint (additional data transfer cost)
```

---

## 5. Containers

Lightsail Containers is a **simplified container hosting service** — no
Kubernetes, no ECS task definitions, no cluster management:

```
What it manages:
  Container image pull (from Lightsail container registry or Docker Hub)
  Deployment scaling
  Load balancing
  HTTPS (free TLS certificate)
  Custom domain mapping

Workflow:
  1. Push Docker image: aws lightsail push-container-image
  2. Create container service (choose power + scale)
  3. Create deployment (define containers, ports, env vars)
  4. Lightsail provides public HTTPS endpoint

Container service power options:
  Nano:   0.25 vCPU, 512 MB RAM
  Micro:  0.5  vCPU, 1 GB RAM
  Small:  1    vCPU, 2 GB RAM
  Medium: 2    vCPUs, 4 GB RAM
  Large:  4    vCPUs, 8 GB RAM
  XLarge: 8    vCPUs, 16 GB RAM

Scale: 1 to 20 nodes per service

Limitations vs ECS/EKS:
  No persistent storage mounts
  No advanced networking (no VPC integration for containers)
  No fine-grained IAM per task
  Limited to public-facing services

Use case: simple containerized web apps, APIs, microservices prototype
```

---

## 6. Object Storage

```
S3-compatible object storage with simplified management:
  No bucket policy complexity
  No IAM setup
  No public access block configuration

Pricing: flat monthly fee per GB stored
  $1/month for 5 GB + 25 GB transfer
  $3/month for 100 GB + 250 GB transfer
  Overage: $0.022/GB storage, $0.09/GB transfer

Use case:
  Static website hosting
  Media storage for Lightsail WordPress instances
  File uploads for Lightsail container apps
```

---

## 7. Load Balancers and CDN

```
Lightsail Load Balancer:
  HTTP/HTTPS application load balancer
  Free TLS certificate from Lightsail CA (not ACM)
  Session persistence (sticky sessions)
  Health checks
  Attach multiple Lightsail instances as targets

  Pricing: $18/month flat fee

Lightsail CDN Distribution:
  Backed by CloudFront infrastructure
  Simplified setup — no CloudFront distribution configuration
  Custom domain + HTTPS
  Cache behaviors (simplified)

  Pricing: flat monthly fee by data transfer tier
    $2.50/month for 50 GB transfer included
    $5.00/month for 150 GB transfer included
```

---

## 8. Lightsail DNS (Free)

```
Free managed DNS for any domain registered anywhere:
  Create DNS zone → point your registrar NS records to Lightsail DNS servers
  Record types: A, AAAA, CNAME, MX, TXT, NS, SRV

  Alias records: point to Lightsail resources (instances, load balancers, CDN)

Limitations vs Route 53:
  No routing policies (no weighted, latency, geolocation)
  No health checks
  No private hosted zones
  Use Route 53 for production DNS needs
```

---

## 9. Lightsail Pricing Model

```
Flat monthly pricing — predictable with no surprise bills:
  Compute: flat monthly per bundle
  Database: flat monthly per bundle
  Storage: flat monthly per GB tier
  Load balancer: flat monthly
  CDN: flat monthly per transfer tier
  Static IP: FREE while attached to running instance ($0.005/hour when detached)
  Snapshots: $0.05/GB/month

Free trial:
  3 months free on select bundles for new accounts
  750 hours/month free for first 3 months

Data transfer:
  Each bundle includes a generous transfer allowance
  Inbound transfer: always free
  Outbound within allowance: free
  Overage: $0.09/GB
```

---

## 10. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Lightsail = EC2 with simplified UI only | Lightsail is a **completely separate service** with its own networking, snapshots, DNS, and pricing model |
| Lightsail integrates natively with all AWS services | Lightsail has **limited integration** — use VPC peering for EC2/RDS access |
| Lightsail CDN = setting up CloudFront manually | Lightsail CDN is **backed by CloudFront** but with a simplified, limited interface |
| Lightsail is only for tiny workloads | Compute-optimized bundles now offer **up to 72 vCPUs** (April 2026) |
| Lightsail static IPs always cost money | Static IPs are **free while attached** to a running instance — charged only when detached |
| Lightsail databases are like RDS | Lightsail databases are simpler — **no read replicas, no Aurora, no parameter group complexity** |
