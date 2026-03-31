# AWS Elastic Load Balancer (ELB)

## 1. Why Load Balancers Exist

| Problem | Without LB | With LB |
|---------|-----------|---------|
| Single point of failure | One EC2 dies → system down | Traffic rerouted to healthy instances |
| Uneven load | One instance overloaded, others idle | Distributed evenly across targets |
| Scaling | Can't add capacity transparently | New instances register and receive traffic automatically |
| Health visibility | No awareness of backend health | Continuous health checks, unhealthy targets removed |
| SSL termination | Each backend manages certificates | LB handles SSL — backends serve plain HTTP |

---

## 2. ELB Types ⭐

| Type | Layer | Protocols | Key Capability | Use Case |
|------|-------|-----------|---------------|---------|
| **ALB** | L7 | HTTP, HTTPS, HTTP/2, gRPC | Path/host/header-based routing | Web apps, microservices, APIs |
| **NLB** | L4 | TCP, UDP, TLS, TCP_UDP | Ultra-high throughput, static IP | Real-time, gaming, IoT, financial |
| **GWLB** | L3+L4 | GENEVE (6081) | Transparent bump-in-the-wire | Third-party security appliances |
| **CLB** | L4+L7 | HTTP, HTTPS, TCP, SSL | Legacy | Do not use for new architectures |

---

## 3. Application Load Balancer (ALB)

### Architecture

```
Client
  ↓ HTTPS:443
ALB (DNS: my-alb-123.us-east-1.elb.amazonaws.com)
  ↓ evaluates Listener Rules
  ├── /api/* → Target Group A (API servers)
  ├── /static/* → Target Group B (CDN origins)
  └── default → Target Group C (main app)
```

### Listener Actions (Not Just "Forward")

| Action | Use Case |
|--------|---------|
| **Forward** | Send to one or more target groups (with optional weights) |
| **Redirect** | HTTP → HTTPS redirect (301/302); URL rewriting |
| **Fixed Response** | Return static HTTP response without hitting any target |
| **Authenticate** | OIDC or Cognito auth before forwarding |

**HTTP → HTTPS redirect (every ALB should have this):**
```
Listener: port 80 (HTTP)
  Action: Redirect to port 443 (HTTPS), status 301
Listener: port 443 (HTTPS)
  Action: Forward to Target Group
```

### Routing Rules ⭐

ALB listener rules evaluate conditions in priority order (1 = highest):

| Condition Type | Example | Use Case |
|---------------|---------|---------|
| **Path pattern** | `/api/*`, `/images/*.jpg` | Microservice routing |
| **Host header** | `api.example.com`, `app.example.com` | Virtual hosting, multi-tenant |
| **HTTP header** | `X-Custom-Header: value` | Internal routing, canary |
| **HTTP method** | `GET`, `POST`, `DELETE` | REST API routing |
| **Query string** | `?version=v2` | Version routing |
| **Source IP** | `10.0.0.0/8` | Internal vs external routing |

### SSL/TLS Termination ⭐

ALB terminates SSL at the load balancer — backend targets receive plain HTTP:

```
Client → HTTPS (TLS 1.3) → ALB (decrypts) → HTTP → EC2
                                         ↑
                              ACM certificate loaded here
```

**Benefits:**
- Offloads crypto from application instances
- Centralized certificate management via ACM
- Backends serve HTTP (simpler config, less CPU)

**End-to-end encryption (if compliance requires):**
```
Client → HTTPS → ALB → HTTPS → EC2
(ALB re-encrypts to backend — certificate needed on EC2 too)
```

### SNI — Multiple Certificates on One ALB ⭐

Server Name Indication (SNI) allows a single HTTPS listener to serve
multiple domains, each with its own certificate:

```
ALB Listener (HTTPS:443)
  ├── Certificate: api.example.com (ACM cert 1)
  ├── Certificate: app.example.com (ACM cert 2)  ← up to 25 certs
  └── Default certificate: example.com

Client requests api.example.com:
  → TLS Client Hello contains SNI hostname
  → ALB selects matching certificate
  → Serves correct cert ✅
```

> Clients that don't support SNI (legacy clients) receive the **default certificate**.
> Up to **25 additional certificates** per ALB listener.

### Built-in Authentication ⭐

ALB can authenticate users **before** forwarding to targets — no auth code in app:

```
Client request → ALB
  → Check: is user authenticated? (session cookie)
  → No? Redirect to Cognito / Okta / Google login page
  → User logs in → IdP issues token
  → ALB validates token → forwards request + user claims in headers
  → EC2 reads X-Amzn-Oidc-Data header to get user info
```

| Type | Provider |
|------|---------|
| **Cognito** | AWS User Pools, Social identity (Google, Facebook, Amazon) |
| **OIDC** | Okta, PingFederate, any OIDC-compliant IdP |

> Requires HTTPS listener. Works with Cognito and any OIDC-compliant provider.

### Source IP — X-Forwarded-For

Because ALB terminates the connection, the EC2 backend sees the **ALB's IP**
as source, not the client IP. ALB adds headers:

```
X-Forwarded-For: 203.0.113.45      ← real client IP
X-Forwarded-Proto: https           ← original protocol
X-Forwarded-Port: 443              ← original port
X-Amzn-Trace-Id: Root=1-xxxxx      ← request tracing ID
```

> Parse `X-Forwarded-For` in your application for the real client IP.

### ALB Key Properties

| Property | Detail |
|----------|--------|
| IP type | DNS name only — no static IP (use Global Accelerator if static IP needed) |
| Security Groups | ✅ Required |
| Cross-zone LB | ✅ Always enabled (cannot disable) |
| WAF integration | ✅ Attach AWS WAF directly to ALB |
| Idle timeout | 60 seconds default (1–4000s configurable) |
| Max listener rules | 100 per listener |
| Min subnets | 2 AZs required |

---

## 4. Network Load Balancer (NLB)

### Key Distinction from ALB

NLB operates at **Layer 4** — it sees TCP/UDP packets but not HTTP headers.
It cannot inspect paths, headers, or cookies. What it gains: extreme speed.

```
Client TCP connection:
  SYN → NLB → SYN → EC2
           (NLB is transparent — EC2 sees the actual connection)
```

### Static IP ⭐

NLB provides **one static IP per AZ** (or you can assign an Elastic IP):

```
NLB in 3 AZs:
  AZ-1a: 54.1.2.3 (static or EIP)
  AZ-1b: 54.4.5.6 (static or EIP)
  AZ-1c: 54.7.8.9 (static or EIP)
```

> This is why NLB is used when clients need to whitelist IP addresses.
> ALB provides only a DNS name — IPs can change.

### Source IP Preservation

Unlike ALB, NLB passes the **real client IP** directly to the backend
(no X-Forwarded-For needed):

```
Client (203.0.113.45) → NLB → EC2 sees source IP: 203.0.113.45 ✅
```

> Exception: if targets are registered by Instance ID (not IP),
> the source IP is preserved. If proxy protocol is needed for IP targets, enable it.

### NLB Security Groups ⭐ (August 2023 Update)

NLB now supports Security Groups — previously it relied on NACL and backend SG only:

```
Before August 2023:
  NLB → no SG → all traffic passed through → EC2 SG filtered

After August 2023:
  NLB → NLB SG (filters what NLB accepts) → EC2 SG (filters what EC2 accepts)
```

> **Important:** SG on NLB can only be attached **at creation time** — cannot add later.
> AWS now recommends attaching an SG to all new NLBs.

**SG referencing pattern (NLB):**
```
NLB SG:  Allow TCP 443 from 0.0.0.0/0
EC2 SG:  Allow TCP 443 from NLB-SG  ← reference NLB SG, not IP
         (ensures EC2 only accepts traffic from NLB, not direct internet)
```

### Cross-Zone Load Balancing

| LB Type | Cross-Zone Default | Can Disable? |
|---------|------------------|-------------|
| ALB | ✅ Always on | ❌ No |
| NLB | ❌ Off by default | ✅ Yes (enable per TG) |
| CLB | ❌ Off by default | ✅ Yes |

```
Cross-zone OFF (NLB default):
  AZ-1a: 3 targets → each gets 33% of that AZ's traffic (50% total ÷ 3)
  AZ-1b: 1 target  → gets 50% of all traffic

Cross-zone ON:
  All 4 targets share traffic equally (25% each) regardless of AZ
```

> Enable cross-zone for NLB when AZs have different numbers of targets.
> Note: Cross-zone NLB traffic is charged at $0.01/GB.

### NLB Key Properties

| Property | Detail |
|----------|--------|
| Performance | Millions of requests/second, ~100μs latency |
| Static IP | One per AZ (can assign EIP) |
| Security Groups | ✅ Supported since Aug 2023 (attach at creation) |
| Preserve source IP | ✅ Yes (no X-Forwarded-For needed) |
| Cross-zone LB | ❌ Off by default |
| TLS termination | ✅ Supported (offloads TLS from EC2) |
| Protocols | TCP, UDP, TLS, TCP_UDP |
| Use with | IoT (UDP), gaming, financial trading, VoIP |

---

## 5. Gateway Load Balancer (GWLB)

Deploys, scales, and manages third-party virtual network appliances
(firewalls, IDS/IPS, deep packet inspection) in the traffic path — transparently.

```
Traffic flow with GWLB:
  Internet
    ↓
  GWLB (GENEVE encapsulation — port 6081)
    ↓
  Security Appliances (Palo Alto, Fortinet, CheckPoint) → inspect
    ↓
  GWLB (returns traffic)
    ↓
  Application VPC
```

| Property | Detail |
|----------|--------|
| Protocol | GENEVE (Generic Network Virtualization Encapsulation) |
| Layer | L3+L4 (transparent to application) |
| Target type | Third-party appliance EC2 instances |
| Use case | Centralized security inspection, compliance |

---

## 6. Internet-Facing vs Internal

| Property | Internet-Facing | Internal |
|----------|----------------|---------|
| DNS | Public DNS resolves to public IP | Private DNS resolves to private IP |
| Accessible from | Public internet | Within VPC or connected networks |
| Subnets | Public subnets | Private subnets |
| Use case | User-facing websites, public APIs | Microservices, DB layer, internal services |

```
3-tier architecture:
  Internet → Internet-Facing ALB (public) → App servers
  App servers → Internal ALB (private) → Database services
```

---

## 7. Listener Rules — Complete Flow ⭐

```
Listener: HTTPS:443
  Rule 1 (priority 1): IF path = /api/*        → Forward to API-TG
  Rule 2 (priority 2): IF host = admin.app.com → Authenticate → Forward to Admin-TG
  Rule 3 (priority 3): IF path = /health       → Fixed Response: 200 "OK"
  Rule 4 (priority 4): IF method = OPTIONS      → Fixed Response: 200 (CORS preflight)
  Default rule:                                 → Forward to Web-TG
```

> Rules evaluated in priority order — first match wins.
> Default rule has no condition — always matches as fallback.

---

## 8. Security Groups Architecture

### ALB + EC2 SG Chaining ⭐

```
ALB SG:
  Inbound:  Allow TCP 80, 443 from 0.0.0.0/0
  Outbound: Allow TCP 80 to EC2-SG (reference by SG ID)

EC2 SG:
  Inbound:  Allow TCP 80 from ALB-SG (reference by SG ID)
            ← This blocks all direct internet access to EC2 ✅
  Outbound: Allow all
```

### NLB + EC2 SG Chaining (post August 2023)

```
NLB SG:
  Inbound:  Allow TCP 443 from 0.0.0.0/0
  Outbound: Allow TCP 443 to EC2-SG

EC2 SG:
  Inbound:  Allow TCP 443 from NLB-SG
            ← Prevents bypass of NLB; ensures all traffic via NLB ✅
```

---

## 9. Multi-AZ Nodes ⭐

When you attach subnets from multiple AZs, ELB creates a **load balancer node**
in each AZ. DNS resolution round-robins across these nodes:

```
ALB DNS: my-alb.elb.amazonaws.com
  → resolves to: 10.0.1.5 (AZ-1a LB node)
                 10.0.2.5 (AZ-1b LB node)
                 10.0.3.5 (AZ-1c LB node)

If AZ-1a fails → DNS stops returning that IP → AZ-1b and 1c serve all traffic
```

> Minimum 2 AZs for ALB (best practice: 3).
> Each AZ must have at least one public subnet for internet-facing LB.

---

## 10. Cross-Region Load Balancing

ALB and NLB are **regional services** — cannot target instances in another Region directly.

| Option | How | Best For |
|--------|-----|---------|
| **Route 53** | DNS-based routing (latency, weighted, failover) | Multi-region active-active |
| **Global Accelerator** | Anycast IPs, routes to nearest healthy endpoint | Low-latency global routing, static IPs |
| **IP target type + peering** | Register cross-VPC/cross-region IPs | Complex, not recommended |

---

## 11. WAF + Shield Integration (ALB) ⭐

```
Internet → AWS Shield (DDoS protection, automatic) → ALB → WAF Web ACL → EC2

WAF rules can:
  - Block by IP, geo, rate limiting
  - SQL injection / XSS protection
  - Custom regex rules
  - Bot control
```

> WAF attaches to ALB (and CloudFront, API Gateway).
> NLB does NOT support WAF — use ALB for applications needing WAF.

---

## 12. Complete ALB vs NLB Reference ⭐

| Feature | ALB | NLB |
|---------|-----|-----|
| **Layer** | L7 (Application) | L4 (Transport) |
| **Protocols** | HTTP, HTTPS, HTTP/2, gRPC | TCP, UDP, TLS, TCP_UDP |
| **Path/host routing** | ✅ Yes | ❌ No |
| **Header/method routing** | ✅ Yes | ❌ No |
| **Static IP** | ❌ (use Global Accelerator) | ✅ Per AZ |
| **Security Groups** | ✅ Required | ✅ Optional (attach at creation) |
| **Source IP to backend** | Via X-Forwarded-For | ✅ Preserved natively |
| **Cross-zone LB** | ✅ Always on | ❌ Off by default |
| **SSL/TLS termination** | ✅ | ✅ |
| **SNI (multiple certs)** | ✅ Up to 25 | ✅ |
| **WAF integration** | ✅ | ❌ |
| **Cognito/OIDC auth** | ✅ Built-in | ❌ |
| **WebSocket** | ✅ | ✅ |
| **gRPC** | ✅ | ❌ |
| **UDP** | ❌ | ✅ |
| **Performance** | High | Ultra-high (millions RPS) |
| **Latency** | ~ms | ~μs |
| **Use case** | Web apps, APIs, microservices | IoT, gaming, real-time, VoIP |

---

## 13. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| NLB doesn't support Security Groups | NLB supports SGs since **August 2023** — attach at creation |
| ALB provides static IP | ALB gives only DNS — use Global Accelerator for static IP |
| NLB reads HTTP headers | NLB is L4 — cannot see HTTP content at all |
| Cross-zone is same on ALB and NLB | ALB: always on; NLB: off by default (costs $0.01/GB when enabled) |
| ALB passes real client IP directly | ALB uses **X-Forwarded-For** — NLB preserves source IP natively |
| SG can be added to NLB anytime | NLB SG can only be attached **at creation time** |
| HTTP/2 delivered to backend | ALB terminates HTTP/2 and sends HTTP/1.1 to targets |
| ALB works without SG | ALB **requires** a Security Group |
| WAF works with NLB | WAF only integrates with **ALB** (and CloudFront, API Gateway) |
| CLB is a valid modern choice | CLB is legacy — use ALB for HTTP or NLB for TCP/UDP |

---

## 14. Interview Questions Checklist

- [ ] What problems does a load balancer solve?
- [ ] ALB vs NLB — layer, protocols, and key feature differences
- [ ] What is a Listener? What types of actions can it take?
- [ ] List all ALB routing condition types (path, host, header, method, query, IP)
- [ ] What is SSL termination? End-to-end encryption vs termination at LB?
- [ ] What is SNI? How many certificates per ALB listener?
- [ ] How does ALB pass the real client IP to EC2?
- [ ] What is NLB's static IP capability? Why is it needed?
- [ ] Does NLB support Security Groups? Since when? Key restriction?
- [ ] Cross-zone load balancing — default for ALB vs NLB?
- [ ] What is built-in authentication on ALB? Providers?
- [ ] ALB + EC2 SG chaining — how to prevent direct access to EC2?
- [ ] What does GWLB do and what protocol does it use?
- [ ] Internet-facing vs internal LB — difference?
- [ ] Cross-region load balancing — why doesn't ALB support it natively? What to use?
- [ ] What is WAF? Which ELB types support it?
- [ ] What happens to multi-AZ LB nodes when one AZ fails?
- [ ] What is Global Accelerator? When to use it over Route 53?

## Nectar

- At least two Availability Zones and a subnet for each zone.
- The selected subnet does not have a route to an internet gateway. This means that your load balancer will not receive internet traffic.
- You can proceed with this selection; however, for internet traffic to reach your load balancer, you must update the subnet’s route table in the VPC console
