# AWS Network Security — Security Groups & NACLs

## 1. Foundation — Ports & Protocols

### Port Range

| Range | Category | Examples |
|-------|---------|---------|
| 0 – 1023 | Well-known / System | 22 (SSH), 80 (HTTP), 443 (HTTPS), 3306 (MySQL) |
| 1024 – 49151 | Registered | 3389 (RDP), 8080 (alt HTTP), 5432 (PostgreSQL) |
| 49152 – 65535 | Ephemeral / Dynamic | OS-assigned for response traffic |

### Ephemeral Ports — Why They Matter for NACL ⭐

When a **client** connects to a server, the OS assigns a random high port for the
**return traffic**. This is called an ephemeral port.

```
Client (your laptop)                Server (EC2)
Port: 54231 (ephemeral) ←─────────── Port: 443
                         HTTP Response
```

**SG (stateful):** No problem — return traffic is automatically tracked.

**NACL (stateless):** You must explicitly allow the ephemeral port range in your
outbound rules on the server side, and inbound rules on the client side.

```
NACL Inbound rule  (server subnet):  allow TCP 443 inbound (incoming request)
NACL Outbound rule (server subnet):  allow TCP 1024-65535 outbound (response to client)
```

> If you forget ephemeral ports in NACL outbound rules, responses will be blocked
> even though the request was allowed. This is the #1 NACL debugging trap.

To learn more about ephemeral ports, click [here](ephemeral-ports.md).

### OSI Layer

Both SG and NACL operate at **Layer 3 (Network) and Layer 4 (Transport)**:

- Layer 3: IP address-based rules
- Layer 4: Port + Protocol (TCP/UDP) rules

---

## 2. Security Groups

**Definition:** A stateful virtual firewall attached to an **ENI** — not to EC2 directly.

```
Internet → ENI → Security Group evaluates → EC2
```

---

### 2.1 Stateful — What It Means ⭐

Stateful = SG **tracks connection state**. Return traffic is automatically allowed.

```
Client → SG (inbound rule: allow TCP 443) → EC2
EC2    → response automatically allowed ← Client
(No outbound rule needed for the response)
```

**But new outbound is different:**
```
EC2 → tries to call external API (new connection, not a response)
    → needs explicit outbound rule ✅
```

> Stateful = only NEW traffic is evaluated against rules.
> Established/return traffic bypasses evaluation entirely.

---

### 2.2 Rule Evaluation — All Rules Simultaneously

SG evaluates **ALL rules at once** — most permissive rule wins.
This is NOT first-match.

```
Rule 1: Allow TCP 80 from 10.0.0.5
Rule 2: Allow TCP 80 from 0.0.0.0/0

Traffic from 10.0.0.5 on port 80:
→ BOTH rules match → traffic is ALLOWED (most permissive)
```

> Because SG is allow-only, all rules are just "add more allows."
> There is no ordering — it's a union of all allow rules.

---

### 2.3 Default vs Custom SG Behavior

| | Default SG (auto-created with VPC) | Custom SG (you create) |
|--|-----------------------------------|----------------------|
| Inbound | Allow from **same SG only** | ❌ Block all |
| Outbound | Allow all (0.0.0.0/0) | Allow all (0.0.0.0/0) |
| Deletable | ❌ Cannot delete | ✅ Yes |

> Custom SG outbound allows all by default — you can restrict it.
> Default SG inbound self-reference = instances in the same SG can talk to each other.

---

### 2.4 SG as Source/Destination (SG Chaining) ⭐

Instead of specifying an IP range, you can reference **another SG ID** as the source
or destination of a rule.

**Example — 3-tier architecture:**

```
ALB-SG      → allows all HTTP/HTTPS from internet (0.0.0.0/0)
AppServer-SG → allows port 8080 from ALB-SG only
DB-SG       → allows port 3306 from AppServer-SG only
```

Configuration:
```
AppServer-SG inbound rule:
  Protocol: TCP
  Port: 8080
  Source: ALB-SG (sg-xxxxxxxx)  ← references SG ID, not IP

DB-SG inbound rule:
  Protocol: TCP
  Port: 3306
  Source: AppServer-SG (sg-yyyyyyyy)
```

**Why this is better than IP-based rules:**

- Auto-scales — when new app server launches and joins AppServer-SG, it can
  immediately talk to DB without updating DB-SG rules
- No hardcoded IPs — works even when instances are replaced
- Uses **private IPs** of instances in the referenced SG (not public IPs)

> SG referencing is the standard way to architect secure multi-tier applications in AWS.

---

### 2.5 SG Limits

| Limit | Default Value |
|-------|--------------|
| Inbound rules per SG | 60 |
| Outbound rules per SG | 60 |
| SGs per ENI | 5 |
| SGs per VPC | 2,500 |

---

### 2.6 Key SG Properties

| Property | Detail |
|----------|--------|
| Attachment point | ENI (one or more SGs per ENI) |
| Rules type | Allow only — no deny |
| Rule evaluation | All rules simultaneously — most permissive wins |
| Updates | Real-time — no restart needed |
| Scope | Applies within VPC (same or peered VPC with referencing) |
| Default outbound | Allow all (you can restrict) |

---

## 3. Network ACL (NACL)

**Definition:** A stateless firewall at the **subnet boundary** — controls all traffic
entering and leaving a subnet.

```
Internet
   ↓
NACL evaluated (subnet entry)
   ↓
Inside subnet → Security Group evaluated (ENI)
   ↓
EC2
```

---

### 3.1 Stateless — What It Means ⭐

Stateless = NACL has **no memory of connections**. Every packet is evaluated
independently against the rules — both directions independently.

```
Client → EC2 (inbound port 443)
  NACL evaluates: is inbound TCP 443 allowed? YES → packet passes

EC2 → Client (response on ephemeral port 54231)
  NACL evaluates: is outbound TCP 54231 allowed? SEPARATE evaluation
  → If no rule allows 1024-65535 outbound → BLOCKED ❌
```

> You must configure **both** inbound and outbound rules for every interaction.

---

### 3.2 Default vs Custom NACL

| | Default NACL | Custom NACL |
|--|-------------|-------------|
| Inbound | ✅ Allow ALL | ❌ Deny ALL (only `*` deny rule exists) |
| Outbound | ✅ Allow ALL | ❌ Deny ALL |
| Assigned to | Every new subnet | Must manually associate |
| Deletable | ❌ Cannot delete | ✅ Yes |

---

### 3.3 Rule Numbering and Evaluation (First Match) ⭐

Rules evaluated **in ascending number order** — first match wins, lower rules are ignored.

| Rule # | Type | Protocol | Port | Action |
|--------|------|---------|------|--------|
| 100 | Inbound | TCP | 22 | ALLOW |
| 200 | Inbound | TCP | 80 | ALLOW |
| 300 | Inbound | TCP | 443 | ALLOW |
| 400 | Inbound | TCP | 0-65535 | ALLOW |
| **\*** | Inbound | All | All | **DENY** |

> Rule `*` is the **implicit deny** — always present, always last, cannot be modified.
> Every NACL ends with `*` DENY ALL — you cannot remove it.

**Numbering best practice:**
- Use increments of 100 (100, 200, 300...) for room to insert later (150, 250)
- Valid range: 1 – 32766

---

### 3.4 NACL Allows DENY Rules ⭐

Unlike SG, NACL supports explicit **DENY** rules. This is critical for blocking
specific IPs or ranges.

```
Rule 90:  DENY  TCP from 203.0.113.0/24  (block known bad IP range)
Rule 100: ALLOW TCP 443 from 0.0.0.0/0
Rule *:   DENY  ALL
```

> Rule 90 blocks the bad range before Rule 100 can allow it.
> **Lower number = higher priority.**

---

### 3.5 Subnet Association

| Property | Detail |
|----------|--------|
| One NACL per subnet | Each subnet can only be associated with ONE NACL |
| One NACL → many subnets | One NACL can be applied to multiple subnets |
| Default | Every subnet starts with the default NACL (allow all) |
| Change | You can swap NACL association at any time |

---

### 3.6 NACL Rule Limits

| Limit | Value |
|-------|-------|
| Rules per NACL (inbound) | 20 (can request increase to 40) |
| Rules per NACL (outbound) | 20 (can request increase to 40) |
| NACLs per VPC | 200 |

---

## 4. SG vs NACL — Complete Comparison ⭐

| Dimension | Security Group | NACL |
|-----------|---------------|------|
| **Level** | ENI (instance-level) | Subnet (boundary-level) |
| **State** | **Stateful** — tracks connections | **Stateless** — evaluates each packet independently |
| **Rules** | Allow only (no deny) | Allow + **Deny** |
| **Evaluation** | All rules simultaneously | **First match wins** (ordered by rule number) |
| **Implicit behavior** | Implicit deny all inbound | Implicit deny all (the `*` rule) |
| **Return traffic** | Automatically allowed | Must explicitly allow (both directions) |
| **Ephemeral ports** | Not needed (stateful) | Must allow 1024-65535 for responses |
| **Multiple per resource** | ✅ Multiple SGs per ENI | ❌ One NACL per subnet |
| **Default (inbound)** | Block all (custom SG) | Allow all (default NACL) |
| **Scope** | One instance at a time | All instances in the subnet |
| **Updates** | Real-time | Real-time |
| **Source/Dest** | IP, CIDR, or SG reference | IP / CIDR only |

---

## 5. Full Traffic Flow (Request + Response)

### Request: Client → EC2 (inbound)

```
Client (54.x.x.x) → EC2 (port 443)

1. NACL inbound rule evaluated at subnet boundary
   → Rule 100: Allow TCP 443 from 0.0.0.0/0 ✅

2. Security Group inbound rule evaluated at ENI
   → Allow TCP 443 from 0.0.0.0/0 ✅

3. EC2 receives request ✅
```

### Response: EC2 → Client (outbound)

```
EC2 (port 443) → Client (ephemeral port 54231)

1. Security Group: STATEFUL → response automatically allowed ✅

2. NACL outbound rule evaluated at subnet boundary: STATELESS
   → Must have rule: Allow TCP 1024-65535 outbound ✅ or ❌
```

> **The most common NACL debugging scenario:**
> Request works (inbound allowed) but response fails (outbound ephemeral not allowed).

---

## 6. Real Architecture — 3-Tier App

```
Internet
   │
   ↓ TCP 80/443
[Public Subnet NACL]  ← Allow: inbound 80/443, outbound 1024-65535
   │
   ↓
[ALB]                 ← SG: inbound 80/443 from 0.0.0.0/0
   │
   ↓ TCP 8080
[Private Subnet NACL] ← Allow: inbound 8080, outbound 1024-65535
   │
   ↓
[App Servers]         ← SG: inbound 8080 from ALB-SG (SG reference)
   │
   ↓ TCP 3306
[DB Subnet NACL]      ← Allow: inbound 3306, outbound 1024-65535
   │
   ↓
[RDS]                 ← SG: inbound 3306 from AppServer-SG (SG reference)
```

**NACL usage here:** Coarse boundary control between subnet tiers.
**SG usage here:** Fine-grained instance-level control using SG references.

---

## 7. When to Use What

| Use This | When |
|---------|------|
| **Security Group** | Controlling access to a specific instance / ENI |
| **Security Group** | Microservices — referencing SG ID instead of IPs |
| **Security Group** | Auto-scaling — no IP hardcoding needed |
| **NACL** | Explicitly blocking a known malicious IP range |
| **NACL** | Adding an extra layer of protection at subnet boundary |
| **NACL** | Compliance requirement for subnet-level firewall |
| **Both** | Defense in depth — always recommended for production |

---

## 8. Troubleshooting Checklist

When a connection fails, check in this order:

```
1. Route Table       → Is there a route to the destination?
2. NACL (inbound)    → Is the inbound traffic allowed at subnet boundary?
3. NACL (outbound)   → Is response traffic allowed out (ephemeral ports)?
4. Security Group    → Is the port allowed at the ENI level?
5. OS Firewall       → Is iptables/Windows Firewall blocking?
6. Application       → Is the service listening on the correct port?
```

> Ping (ICMP) fails? → Check both NACL and SG for ICMP protocol rules —
> neither allows ICMP by default in custom configs.

---

## 9. Common Mistakes ✅

| ❌ Wrong | ✅ Correct |
|---------|---------|
| SG evaluates rules top to bottom | SG evaluates ALL rules simultaneously — most permissive wins |
| NACL evaluates all rules | NACL is first-match — rule order matters |
| Return traffic needs outbound SG rule | SG is stateful — return traffic automatically allowed |
| NACL allows all traffic by default (custom) | Custom NACL denies ALL by default — only default NACL allows all |
| Only need inbound NACL rule | NACL stateless — must add both inbound AND outbound rules |
| Forget ephemeral ports in NACL | Must allow 1024-65535 outbound for responses to reach clients |
| SG attached to EC2 | SG attached to **ENI** — EC2 has no direct SG |
| One subnet can have multiple NACLs | One subnet → one NACL at a time |
| SG can only use IP ranges as source | SG can reference **another SG ID** as source/destination |
| Deleting NACL rules = allow | Deleting rule = falls through to `*` implicit deny |

---

## 10. Interview Questions Checklist ✅

- [ ] What is a Security Group? What level does it operate at?
- [ ] What does "stateful" mean in Security Groups?
- [ ] SG rule evaluation — all at once or first match?
- [ ] Can Security Groups have DENY rules? (No)
- [ ] What is the default inbound/outbound for a custom SG?
- [ ] What is the default SG in a VPC? How is it different?
- [ ] What is SG chaining / SG referencing? Why use it?
- [ ] What is a NACL? What level does it operate at?
- [ ] What does "stateless" mean in NACLs?
- [ ] NACL rule evaluation order — how does first-match work?
- [ ] Can NACLs have DENY rules? (Yes — only NACLs can explicitly deny)
- [ ] What is the `*` rule in a NACL?
- [ ] Default NACL vs Custom NACL — inbound/outbound defaults?
- [ ] How many NACLs can one subnet have? (One)
- [ ] What are ephemeral ports? Why do they matter for NACLs?
- [ ] You added an inbound NACL rule but responses are blocked — why?
- [ ] Walk through the full request + response flow through NACL + SG
- [ ] SG vs NACL — 5 key differences
- [ ] When would you use NACL over SG?
- [ ] A connection is failing — what is your debugging order?
