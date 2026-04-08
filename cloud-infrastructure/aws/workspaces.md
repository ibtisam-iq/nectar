# Amazon WorkSpaces

## 1. What is Amazon WorkSpaces?

Amazon WorkSpaces is AWS's **Desktop-as-a-Service (DaaS)** solution — it
delivers fully managed virtual cloud desktops to users anywhere, accessible
from any device, without the need to provision or maintain physical hardware.

```
Traditional desktop problem:
  Buy laptop → IT provisions OS → install apps → ship to user → patch monthly
  User leaves → reclaim hardware → wipe → reimage → store
  Remote work → VPN → slow → security risk → hardware needed

WorkSpaces model:
  User opens client on any device (Windows, Mac, iPad, web browser, Thin Client)
  → Connects to their personal cloud desktop running in AWS
  → All data stays in AWS (never on local device) → secure
  → IT manages bundles centrally → deploy to 1 or 10,000 users identically
  → User terminated → disable WorkSpace → done (no hardware retrieval)
```

### WorkSpaces Family Overview

```
Amazon WorkSpaces Family includes multiple products:
  WorkSpaces Personal    → persistent, dedicated desktops (one user per desktop)
  WorkSpaces Pools       → non-persistent, shared desktops (any user from pool)
  WorkSpaces Thin Client → physical lightweight device for accessing WorkSpaces
  WorkSpaces Web         → browser-based access to internal web apps (DEPRECATED → March 31, 2027) [docs.aws.amazon](https://docs.aws.amazon.com/workspaces-thin-client/latest/ag/configuring-WorkSpaces-web.html)
  AppStream 2.0          → stream individual applications (not full desktop)
```

---

## 2. WorkSpaces Personal ⭐

**Persistent, dedicated virtual desktops** — each WorkSpace assigned to
one specific user. Changes persist: user installs an app → it stays next session.

```
Architecture:
  VPC → subnet (private) → WorkSpace instance (EC2 + EBS)
  User → WorkSpaces Client (any device) → streaming protocol (DCV or PCoIP)
  → Sees their personal desktop with all their files/apps

Key characteristics:
  Persistent:    user data, apps, settings survive reboots and sessions
  Dedicated:     one WorkSpace = one user (not shared)
  Always available: desktop ready when user connects
  Managed:       AWS handles hypervisor, hardware, OS patching (if enabled)
```

### Operating Systems Available

```
Windows:
  Windows 11 (included Microsoft RDS SAL: $4.19/month/user)
  Windows 10 (included RDS SAL)
  Windows Server 2019/2022 (bring your own license variant available)

Linux:
  Amazon Linux 2023    ← free, no license cost
  Ubuntu 22.04 LTS     ← free
  Red Hat Enterprise Linux (RHEL) 8
  Rocky Linux 8

BYOL (Bring Your Own License):
  You supply Windows licenses → AWS hosts → lower cost but more admin
```

---

## 3. WorkSpaces Pools ⭐

**Non-persistent, shared desktops** — users get a fresh desktop from a pool
each session. No data persists between sessions.

```
Architecture:
  Pool of identical WorkSpace instances → user connects → gets one →
  Session ends → instance wiped → returned to pool for next user

Key characteristics:
  Non-persistent:  session data wiped on logout (no user volume)
  Shared:          multiple users share the same pool of instances
  Scales automatically: pool grows/shrinks based on demand
  Cost-efficient:  pay per session-hour (not per user per month)

User data persistence options:
  Amazon S3 or FSx for Windows: mount as home directory via Group Policy
  → User files in S3/FSx → available every session → desktop still wiped

Use case:
  Task workers: call center agents, retail staff, shift workers
  Contractors: short-term workers who shouldn't retain data
  Kiosk/lab environments: shared stations
  BYOD corporate: employees using personal devices → no corporate data on device
```

---

## 4. Bundles ⭐

A **bundle** is a fixed combination of vCPU, RAM, storage, and OS.
WorkSpaces Personal bundles include a root volume (OS + apps) and user volume (personal data):

### WorkSpaces Personal Bundles (Windows, us-east-1)

| Bundle | vCPUs | RAM | Root Vol | User Vol | AlwaysOn/mo | AutoStop base/hr |
|--------|-------|-----|----------|----------|------------|-----------------|
| Value | 1 | 2 GB | 80 GB | 10 GB | $23 | $7.25 + $0.19/hr |
| Standard | 2 | 4 GB | 80 GB | 50 GB | $33 | $9.75 + $0.28/hr |
| Performance | 2 | 8 GB | 175 GB | 100 GB | $60 | $13.00 + $0.57/hr |
| Power | 4 | 16 GB | 175 GB | 100 GB | $79 | $13.00 + $0.83/hr |
| PowerPro | 8 | 32 GB | 175 GB | 100 GB | $138 | $19.00 + $1.51/hr |
| Graphics.g4dn | 4 | 16 GB + GPU | 175 GB | 100 GB | $—  | Premium |
| GeneralPurpose.4xlarge | 16 | 64 GB | — | — | Enterprise | Enterprise |
| GeneralPurpose.8xlarge | 32 | 128 GB | — | — | Enterprise | Enterprise |

> Windows license (RDS SAL) **included** in Windows bundle pricing at $4.19/user/month.
> Linux bundles (Amazon Linux, Ubuntu): NO Microsoft license cost → cheaper.

### WorkSpaces Pools Bundles (per-session pricing)

```
Standard Pool (2 vCPU, 4 GB RAM, 200 GB root):
  $0.10/hour (active session)
  $0.025/hour (stopped instance, AutoStop mode)
  + $4.19/month/user (Windows RDS SAL)

Graphics Pool (GPU-backed):
  Graphics.g4dn (16 vCPU, 64 GB RAM, 1 GPU): $2.73/hour + $4.19/month/user

No user volume: data goes to S3/FSx
```

---

## 5. Billing Modes ⭐

### AlwaysOn (Monthly Billing)

```
Flat monthly fee per WorkSpace
Instance running 24/7 — always ready, instant login
Best for: users working 160+ hours/month (full-time employees)

Break-even:
  Standard bundle: $33/month vs AutoStop $9.75 + $0.28/hr
  Break-even: ($33 - $9.75) / $0.28 = ~83 hours/month
  → If user works > 83 hrs/month: AlwaysOn is cheaper
```

### AutoStop (Hourly Billing)

```
Monthly base fee (infrastructure/storage) + hourly rate when connected
Instance stops N minutes after user disconnects (configurable)
Best for: part-time users, shift workers, occasional use

AutoStop idle timeout:
  Default: 1 hour after disconnect → instance stops
  Configurable: 0–24 hours
  Drawback: 1–2 min startup time when stopped instance resumes (EBS snapshot resume)

Break-even (Standard): ~83 hours/month
  < 83 hrs/month → AutoStop cheaper
  > 83 hrs/month → AlwaysOn cheaper [venn](https://www.venn.com/learn/aws-workspace/aws-workspaces-pricing/)
```

---

## 6. Streaming Protocols ⭐

WorkSpaces supports two streaming protocols that transmit the desktop display
from AWS to the user's device:

### DCV (NICE DCV) — Recommended

```
Developed by AWS (acquired from NICE Software)
Default protocol for new WorkSpaces

Features:
  Higher loss/latency tolerance → better for remote users, poor networks [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces-networking.html)
  Smart card authentication (CAC/PIV cards) → government/enterprise use
  Webcam support in-session [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces-networking.html)
  SAML 2.0 integration
  Certificate-based authentication
  Web browser access (no client install needed) [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/userguide/amazon-workspaces-web-access.html)
  USB redirection
  Better GPU/graphics workload performance

Use DCV when:
  Users on high-latency/lossy networks (global teams, home internet)
  Smart card auth required
  Webcam needed in session
  SAML SSO integration needed
  Web Access required [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/userguide/amazon-workspaces-web-access.html)
```

### PCoIP (PC over IP) — Legacy

```
Developed by Teradici (owned by HP)
Older protocol — still supported but DCV preferred

Features:
  Excellent image quality on good networks
  Mature protocol with broad client support
  No Web Access support ← major limitation [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/userguide/amazon-workspaces-web-access.html)
  No smart card support

Limitations vs DCV:
  No web browser access
  Worse performance on high-latency networks
  No webcam support
  No SAML — only AD authentication

Use PCoIP when:
  Legacy deployments already using PCoIP
  Specific PCoIP thin client hardware in place
  No web access needed

Migration: [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/userguide/amazon-workspaces-web-access.html)
  "For continued Web Access usage, we recommend evaluating migration to DCV"
  → Move all new deployments to DCV
```

| Feature | DCV | PCoIP |
|---------|-----|-------|
| Web browser access | ✅ | ❌ |
| Smart card auth | ✅ | ❌ |
| Webcam in-session | ✅ | ❌ |
| SAML 2.0 | ✅ | ❌ |
| High-latency tolerance | ✅ High | ❌ Lower |
| Recommended | ✅ Default | Legacy only |

---

## 7. Access Methods

### WorkSpaces Client Application

```
Install native client → connect to WorkSpace
Available for: Windows, macOS, Ubuntu Linux, iOS, Android, ChromeOS
Features: full protocol support (DCV + PCoIP), local device integration

Download: clients.amazonworkspaces.com
```

### Web Access (DCV only)

```
Open browser → workspaces.aws → log in → full desktop in browser tab
No client install required
Requires: DCV protocol (not available for PCoIP) [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/userguide/amazon-workspaces-web-access.html)
Best for: BYOD, kiosk access, Chromebooks
Limitation: some features reduced vs native client (USB, printing)
```

### WorkSpaces Thin Client

```
Purpose-built lightweight physical device for accessing WorkSpaces:
  Small device (~$200) → plug into monitor + keyboard + mouse
  Boots into WorkSpaces streaming session directly
  No general-purpose OS → no local data storage → highly secure
  IT-managed via AWS console (zero-touch deployment)

End of support: March 31, 2027 → AWS ending WorkSpaces Thin Client [docs.aws.amazon](https://docs.aws.amazon.com/workspaces-thin-client/latest/ag/configuring-WorkSpaces-web.html)
  → Migrate to web access or native client before that date
  → WorkSpaces Secure Browser portal as alternative for web-based needs [docs.aws.amazon](https://docs.aws.amazon.com/workspaces-thin-client/latest/ag/configuring-WorkSpaces-web.html)

Configure: [docs.aws.amazon](https://docs.aws.amazon.com/workspaces/latest/adminguide/access-control-awstc.html)
  Directory level: enable WorkSpaces Thin Client Access
  Group Policy + Security Policy settings required for login to work
  Specific port requirements for streaming
```

---

## 8. Directories (Active Directory) ⭐

WorkSpaces requires an **AWS Directory Service** for user authentication
and desktop management:

```
Three directory options:

1. AWS Managed Microsoft AD (recommended for enterprises):
   Full Microsoft AD in AWS → join WorkSpaces to domain
   Group Policy, LDAP, Kerberos, MFA support
   Can trust on-premises AD → hybrid identity
   Cost: ~$0.12–$0.31/hr per directory (NOT included in WorkSpaces pricing)
   Use: enterprises with complex AD requirements

2. Simple AD:
   Samba 4-based, Kerberos-compatible
   Subset of Microsoft AD features
   Cost: INCLUDED in WorkSpaces pricing (free) [aws.amazon](https://aws.amazon.com/workspaces/desktop-as-a-service/pricing/)
   Limitations: no Group Policy fine-tuning, no trust relationships
   Use: small deployments, simple authentication

3. AD Connector:
   Proxy to your on-premises AD
   WorkSpaces authenticates against your existing corporate AD
   Cost: INCLUDED in WorkSpaces pricing (free) [aws.amazon](https://aws.amazon.com/workspaces/desktop-as-a-service/pricing/)
   No user data stored in AWS
   Use: organizations with existing on-premises AD that want WorkSpaces
```

> **Note:** AWS Managed Microsoft AD is **NOT** included in WorkSpaces pricing —
> it charges separately. Simple AD and AD Connector ARE included.

---

## 9. Networking ⭐

```
WorkSpaces instances run in a VPC:
  Private subnet(s) — WorkSpaces never have public IPs by default
  Security Groups control network access within VPC

WorkSpaces Streaming (client → desktop):
  Port 443 (HTTPS): registration and authentication
  Port 4172 (TCP + UDP): DCV/PCoIP streaming traffic
  Port 4195 (UDP): DCV streaming (recommended, optimized)
  → These ports must be open outbound from user's network to AWS

On-premises connectivity:
  VPN or Direct Connect → WorkSpaces in private subnet can access
  on-premises resources (file servers, printers, internal apps)
  AD Connector: proxy authentication to on-premises AD over VPN/DX

Internet access for WorkSpaces:
  Add NAT Gateway to VPC → route WorkSpaces traffic through NAT
  Or: WorkSpaces Internet Access (AWS-managed NAT, included in bundle pricing)
  For CloudFront + internet access: assign public IP per WorkSpace (costs extra now)
```

---

## 10. Security ⭐

```
Encryption:
  Root volume: encrypted with AWS KMS (optional, enable at creation)
  User volume: encrypted with AWS KMS (optional, enable at creation)
  In-transit: all streaming traffic encrypted (TLS 1.2+)
  Cannot change encryption after WorkSpace created → enable at setup

IP Access Control:
  IP access control group: allowlist of CIDRs that can connect
  Applied at directory level → all WorkSpaces in directory inherit
  Use: restrict WorkSpaces access to corporate IP ranges only

MFA:
  Supported via RADIUS or AD FS integration
  Configure on directory → all WorkSpaces require MFA at login
  Supported for: Smart cards (DCV only), RADIUS, SAML

Device access control:
  Client access certificates: only trusted devices can connect
  Works with: WorkSpaces Application Manager + MDM solutions

Data protection:
  Clipboard: enable/disable copy-paste between local device and WorkSpace
  Printing: enable/disable local printer access
  USB: enable/disable USB redirection
  → Zero-trust controls prevent data exfiltration
```

---

## 11. WorkSpaces vs AppStream 2.0

| Dimension | WorkSpaces Personal | WorkSpaces Pools | AppStream 2.0 |
|-----------|--------------------|-----------------|--------------|
| Desktop type | Full persistent desktop | Full non-persistent desktop | Individual applications only |
| Persistence | ✅ Per-user persistent | ❌ Session only | ❌ Session only |
| User assignment | 1:1 (dedicated) | Pool (any user) | Pool |
| OS | Windows + Linux | Windows | Windows |
| Use case | Knowledge workers, developers | Task workers, shift workers | Specific app delivery (ERP, design tools) |
| Pricing model | Monthly per desktop | Hourly per session | Hourly per instance |
| Start time | Instant (AlwaysOn) or 1–2 min (AutoStop) | ~30 sec from pool | ~2 min (if cold) |

---

## 12. Pricing Summary

```
WorkSpaces Personal (Windows Standard, us-east-1):
  AlwaysOn:  $33.00/month flat + $4.19 RDS SAL = ~$37.19/month total
  AutoStop:  $9.75/month + $0.28/hour connected + $4.19 RDS SAL

WorkSpaces Pools (Windows Standard, us-east-1):
  $0.10/hour active + $0.025/hour stopped (AutoStop)
  + $4.19/month per user who accessed in that month

Linux bundles: NO RDS SAL fee → subtract $4.19/month/user from above

Free Tier: [aws.amazon](https://aws.amazon.com/workspaces/desktop-as-a-service/pricing/)
  Personal: 2 Standard RHEL/Rocky/Ubuntu/Windows/Amazon Linux bundles,
            80 GB root + 50 GB user, hourly mode,
            up to 40 combined hours/month for 3 months
  Pools:    2 Standard Windows bundles, 200 GB root,
            up to 40 combined hours/month for 3 months
  Additional: 5 Performance Ubuntu AutoStop WorkSpaces,
              80 GB root + 100 GB user, 100 hours/month

Cost optimization tips:
  Use Linux bundles where possible (no $4.19/month RDS SAL)
  AutoStop for part-time users, AlwaysOn for full-time (break-even ~83 hrs)
  Right-size bundles: start Standard → upgrade if performance needed
  Use Pools for task workers (hourly vs fixed monthly)
  Delete unused WorkSpaces immediately (still billed if provisioned but unused)
```

---

## 13. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| WorkSpaces stores user data locally on device | All data stored **in AWS** — nothing saved on local device |
| PCoIP and DCV have same feature set | DCV supports web access, smart cards, webcam, SAML; PCoIP does **not** |
| WorkSpaces Thin Client has long-term support | Thin Client support **ends March 31, 2027** — plan migration |
| Simple AD has same features as AWS Managed AD | Simple AD is Samba-based — **no trust relationships, limited Group Policy** |
| WorkSpaces pricing includes AWS Managed AD | AWS Managed AD is **NOT included** — only Simple AD and AD Connector are free |
| AutoStop means zero cost when not connected | AutoStop has **base infrastructure cost** even when stopped ($9.75/month for Standard) |
| Can enable volume encryption after WorkSpace created | Encryption must be **enabled at creation** — cannot change after |
| WorkSpaces Pools store per-user data | Pools are **non-persistent** — user volume wiped after session; use S3/FSx for persistence |
| AlwaysOn is always cheaper | AlwaysOn only cheaper above **~83 hours/month** — AutoStop better for part-time users |
| Web Access works on PCoIP WorkSpaces | Web Access requires **DCV protocol** — not available for PCoIP |

---

## 14. Interview Questions Checklist

- [ ] What is Desktop-as-a-Service? How does WorkSpaces implement it?
- [ ] WorkSpaces Personal vs WorkSpaces Pools — key differences?
- [ ] What does "persistent" mean in the context of WorkSpaces Personal?
- [ ] DCV vs PCoIP — three features DCV has that PCoIP lacks
- [ ] Why is DCV recommended for new deployments?
- [ ] AlwaysOn vs AutoStop — break-even calculation for Standard bundle
- [ ] Three directory options — which are included in WorkSpaces pricing?
- [ ] What is the AutoStop idle timeout? What happens when instance stops?
- [ ] How do you persist user data in WorkSpaces Pools? (S3/FSx)
- [ ] How do you restrict WorkSpaces to corporate IP ranges? (IP access control groups)
- [ ] When must you enable volume encryption? (at creation — cannot change after)
- [ ] WorkSpaces Thin Client end-of-support date? (March 31, 2027)
- [ ] WorkSpaces vs AppStream 2.0 — when to use each?
- [ ] What ports must be open for WorkSpaces streaming? (443, 4172, 4195)
- [ ] Windows RDS SAL cost per user? ($4.19/month)
- [ ] Free tier — how many WorkSpaces, how many hours, for how long?
