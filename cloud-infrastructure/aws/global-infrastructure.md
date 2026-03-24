# AWS Global Infrastructure

---

## 1. The Hierarchy

```
AWS Cloud
   └── Regions  (geographic groupings)
         └── Availability Zones / AZs  (isolated fault boundaries)
               └── Data Centers  (physical buildings with hardware)
```

> Resources live in **Data Centers** — not directly in Regions or AZs.
> Region and AZ are logical groupings on top of physical infrastructure.

---

## 2. Current Numbers (Official — March 2026)

| Component | Count |
|-----------|-------|
| Launched Regions | **39** |
| Availability Zones | **123** |
| CloudFront POPs (Edge) | **750+** |
| Regional Edge Caches | **15** |
| Local Zones | **43** |
| Wavelength Zones | **33** |
| Planned new Regions | 2 more (Saudi Arabia, Chile) |

> **Rule:** These numbers keep increasing. Always verify at [aws.amazon.com/about-aws/global-infrastructure](https://aws.amazon.com/about-aws/global-infrastructure).

---

## 3. Data Center

**Definition:** A physical facility containing servers, storage, and networking equipment.

- Real physical location — actual hardware lives here
- Highly secured (biometric, 24/7 surveillance, redundant power)
- AWS does NOT expose how many DCs exist per AZ
- Focus on logical design, not counting buildings

---

## 4. Availability Zone (AZ)

**Definition:** One or more Data Centers grouped together, treated as a single logical unit.

| Property | Detail |
|----------|--------|
| Isolation | Physically separate from other AZs (separate power, cooling, networking) |
| Connection | Linked to other AZs in same Region via **high-bandwidth, low-latency private fiber** |
| Purpose | **Fault boundary** — if one AZ fails, others keep running |
| Minimum per Region | 3 AZs (most regions); some have 4–6 |
| Physical separation | Far enough to isolate failures, close enough for low latency |

> **AZ = Failure Boundary** — the core reason multi-AZ architecture exists.

---

## 5. Region

**Definition:** A geographic area containing a cluster of multiple, isolated AZs.

| Property | Detail |
|----------|--------|
| Minimum AZs | 3 per Region |
| Independence | Fully isolated from other Regions (separate infrastructure) |
| Connectivity | Regions connected via AWS backbone network |
| Selection criteria | Latency, compliance/data residency, service availability, cost |

**Example — Mumbai Region:**
```
Region:  ap-south-1
AZs:     ap-south-1a
         ap-south-1b
         ap-south-1c
```

---

## 6. Naming Convention ⭐

| Pattern | Meaning | Example |
|---------|---------|---------|
| `geo-direction-number` | Region | `ap-south-1` |
| `geo-direction-number` + **letter** | AZ | `ap-south-1a` |

**Region name breakdown:**
```
ap  -  south  -  1
 ↓       ↓       ↓
Asia   location  region
Pacific          number
```

**Rule:** Ends with a number = Region. Ends with a letter = AZ.

**Common region prefixes:**

| Prefix | Geography |
|--------|-----------|
| `us-east` | US East (N. Virginia, Ohio) |
| `us-west` | US West (N. California, Oregon) |
| `eu-` | Europe |
| `ap-` | Asia Pacific |
| `sa-` | South America |
| `ca-` | Canada |
| `me-` | Middle East |
| `af-` | Africa |

---

## 7. AZ Identity Per Account (Important Correction) ⭐

AWS does not expose all AZs to every account — and AZ names are **not consistent across accounts**.

```
Your account:       ap-south-1a  →  maps to  Physical Zone ID: aps1-az1
Another account:    ap-south-1a  →  maps to  Physical Zone ID: aps1-az2
```

> Same AZ name, different physical location.
> AWS does this for **capacity management and load distribution**.
> To compare actual physical AZs across accounts → use **AZ ID** (e.g. `aps1-az1`), not AZ name.

**Enable additional AZs:** Some AZs are not enabled by default in new accounts. You opt in via the console under Account Settings.

---

## 8. Edge Locations ⭐

**Definition:** Points of Presence (PoPs) deployed in cities worldwide — closer to end users than Regions.

| Type | Count | Purpose |
|------|-------|---------|
| CloudFront Edge Locations (PoPs) | 750+ | Cache and serve content (CDN) |
| Regional Edge Caches | 15 | Mid-tier cache between PoPs and origin |

**Used by:** Amazon CloudFront (CDN), Route 53, AWS Shield, Lambda@Edge

**Request flow:**
```
User
 ↓
Edge Location  ← cache hit? serve directly ✅
 ↓ (cache miss)
Regional Edge Cache  ← cache hit? serve from here ✅
 ↓ (cache miss)
AWS Region  ← fetch from origin (your EC2/S3/etc.)
```

> Edge Locations are **NOT** Regions or AZs — they do not run compute workloads.
> They exist purely for **low latency content delivery and DNS resolution**.

---

## 9. Local Zones & Wavelength Zones (Bonus — Interview Aware)

| Type | Count | Purpose | Use Case |
|------|-------|---------|----------|
| **Local Zones** | 43 | AWS compute/storage extended into metro cities | Ultra-low latency apps (gaming, media, AR/VR) |
| **Wavelength Zones** | 33 | AWS infra embedded in telecom 5G networks | 5G mobile edge computing |

> These sit **outside** the main Region but are extensions of it.
> Local Zone example: `us-west-2-lax-1a` (Los Angeles Local Zone of Oregon Region).

---

## 10. Regional vs Global Services ⭐

### Global Services (not tied to any Region)

| Service | Notes |
|---------|-------|
| **IAM** | Users, Groups, Roles, Policies — global |
| **Route 53** | Global DNS service |
| **CloudFront** | CDN — uses edge locations globally |
| **AWS Organizations** | Account management — global |
| **Global Accelerator** | Global network routing |
| **Billing & Cost Management** | Global |
| **AWS WAF** (for CloudFront) | Must be in `us-east-1` (shown as "Global" in console) |

### Regional Services (tied to a specific Region)

| Service | Notes |
|---------|-------|
| **EC2** | Instances tied to AZ within a Region |
| **VPC** | Regional — spans all AZs in a Region |
| **RDS** | Regional (AZ-specific instances) |
| **S3** | Buckets are regional (globally unique names) |
| **Lambda** | Regional |
| **EKS / ECS** | Regional |
| **CloudWatch** | Regional |
| **SNS / SQS** | Regional |
| **AMI** | Regional (must copy to use in another Region) |
| **Security Groups** | VPC-level → Regional |
| **Key Pairs** | Regional (unless uploaded RSA key) |

### AZ-Specific Resources (bound to a single AZ)

| Resource | Notes |
|----------|-------|
| EC2 Instance | Runs in a specific AZ |
| EBS Volume | Tied to one AZ (cannot attach across AZs) |
| Subnet | Exists in one AZ |
| RDS instance | Primary in one AZ; Multi-AZ = standby in another |

> **Exam rule:** If you can't select a Region in the console for a service → it's Global.

---

## 11. AWS Console — Control Plane

**Definition:** Web interface to manage AWS resources.
Console sends commands via API → Region → AZ → Data Center → Resource.
**Console stores no data** — it is purely a control plane.

### Key Console Components

| Element | Purpose |
|---------|---------|
| Services Menu (9 dots) | Access all AWS services |
| Search Bar | Find any service quickly |
| **Region Selector** ⭐ | Determines where resources are created |
| CloudShell | Browser-based CLI (no setup needed) |
| AWS Q | AI assistant for AWS help |
| Notifications (bell) | Alerts and health events |
| Account/Settings | Billing, security credentials, preferences |

> **Region Selector is critical** — always verify selected Region before creating a resource.
> Default Region for new accounts: `us-east-1` (N. Virginia).

### Resource Creation Flow

```
You click "Launch EC2" in console
           ↓
Console → AWS API
           ↓
Selected Region (e.g. ap-south-1)
           ↓
Selected AZ (e.g. ap-south-1a)
           ↓
Physical Data Center
           ↓
Resource Created ✅
```

### User Access Flow

```
User Request
     ↓
Edge Location (CloudFront PoP — nearest to user)
     ↓  (cache miss)
AWS Region
     ↓
AZ → Data Center → Your Resource
     ↓
Response back via same path ✅
```

---

## 12. Why This Architecture Exists

| Problem | AWS Solution |
|---------|-------------|
| Single point of failure | Multiple AZs (fault isolation) |
| High latency for global users | Edge Locations (CDN) |
| Regional disaster | Multi-Region deployment |
| Compliance / data residency | Choose specific Region |
| Ultra-low latency for metro areas | Local Zones |
| 5G edge computing | Wavelength Zones |

---

## 13. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Region = Data Center | Region = group of AZs |
| AZ = single Data Center | AZ = one or more DCs grouped as one logical unit |
| All accounts share same AZ mapping | AZ names differ per account — use AZ ID for comparison |
| Edge Locations are Regions | Edge Locations are PoPs for CDN — not compute Regions |
| IAM is Regional | IAM is Global |
| S3 is Global | S3 buckets are Regional (names are globally unique) |
| Resources live in Regions | Resources live in Data Centers (inside AZs, inside Regions) |

---

## 14. Interview Questions Checklist ✅

- [ ] What is the AWS Global Infrastructure hierarchy?
- [ ] How many Regions and AZs does AWS have? (current numbers)
- [ ] What is a Region? How do you choose one?
- [ ] What is an Availability Zone? Why does it exist?
- [ ] What is the difference between a Region and an AZ?
- [ ] Decode this: `ap-southeast-1b` — what is it?
- [ ] What is an Edge Location? How is it different from a Region?
- [ ] What are Regional Edge Caches?
- [ ] What are Local Zones? What are Wavelength Zones?
- [ ] Name 5 Global services and 5 Regional services
- [ ] Why is IAM global but EC2 regional?
- [ ] What does the Region Selector in AWS Console do?
- [ ] Why do AZ names differ between accounts?
- [ ] What is an AZ ID and why is it more reliable than AZ name?
- [ ] What is `us-east-1` and why is it the default?
- [ ] What happens when you create an EC2 instance — which components are involved?
