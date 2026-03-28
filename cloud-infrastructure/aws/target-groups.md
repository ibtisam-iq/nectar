
# AWS Target Groups

## 1. What is a Target Group?

A Target Group is a **logical collection of backend resources** that a Load Balancer
routes traffic to. It separates the routing decision (load balancer + listener)
from the destination (target group + targets).

```
Client
  ↓
Load Balancer (routing decision: which target group?)
  ↓
Target Group (health tracking, algorithm, attributes)
  ↓
Targets: EC2 / IP / Lambda / ALB
```

> The Load Balancer decides **which** Target Group to send to (via listener rules).
> The Target Group decides **which target** within the group to send to (via algorithm).
> These are two separate routing decisions.

---

## 2. Three-Layer Mental Separation ⭐

| Layer | Component | Responsibility |
|-------|-----------|---------------|
| **L7** | ALB | HTTP/HTTPS routing, path/header-based rules |
| **L4** | NLB | TCP/UDP/TLS routing, connection-level |
| **Backend** | Target Group | Holds targets, runs health checks |
| **Routing rule** | Listener | Maps port + protocol → action (forward to TG) |

> Never mix these layers mentally. A Listener belongs to a Load Balancer.
> A Target Group is independent and can be referenced by a Listener rule.

---

## 3. Target Types ⭐

### 1. Instances

Register EC2 instances by Instance ID. AWS resolves the instance's **private IP** automatically.

```
Target Group → EC2 instance-id (i-xxxxxxxx)
             → LB sends to: 10.0.1.10:80 (private IP resolved by AWS)
```

| When to Use |
|------------|
| Standard web apps on EC2 |
| Auto Scaling Groups (ASG registers/deregisters automatically) |
| Any EC2-based workload |

> With Auto Scaling: the ASG registers and deregisters instances from the
> target group automatically as it scales out/in.

---

### 2. IP Addresses

Register any IP address — EC2 private IPs, on-premises IPs, container IPs.

**Supported CIDR ranges:**

- VPC CIDR (same VPC or peered VPC)
- `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` — RFC 1918
- On-premises CIDRs (via VPN or Direct Connect)

```
Target Group → 10.0.2.10:8080  (EC2 in private subnet)
             → 192.168.1.20:80  (on-prem server via DX/VPN)
             → 10.0.3.5:9000    (container IP in ECS)
```

| When to Use |
|------------|
| Containers (ECS tasks, Kubernetes pods) — multiple services per host |
| On-premises servers integrated into AWS routing |
| ECS with `awsvpc` network mode (each task gets its own IP) |
| Multiple services on the same EC2 using different ports |

> Key distinction from Instances type: you register the **IP + port** directly,
> not the instance. Useful when the instance IP is not the right granularity.

---

### 3. Lambda Function

ALB invokes the Lambda function directly — no server or port needed.

```
Client → ALB → Lambda function (event payload: HTTP request object)
Lambda returns response → ALB converts → HTTP response to client
```

**Lambda receives the request as a JSON event:**
```json
{
  "httpMethod": "GET",
  "path": "/api/data",
  "headers": { "Host": "example.com" },
  "queryStringParameters": { "id": "123" },
  "body": null
}
```

| Property | Detail |
|----------|--------|
| Load Balancer | ✅ **ALB only** — not NLB or GWLB |
| Multi-value headers | Must enable `multi_value_headers.enabled` attribute |
| Health check | ALB invokes Lambda — expects HTTP 200 response |
| Concurrency | ALB scales Lambda automatically |

| When to Use |
|------------|
| Serverless HTTP APIs |
| Event-driven processing behind HTTP endpoint |
| No-server responses (status pages, webhooks) |

---

### 4. Application Load Balancer (as Target)

An NLB can forward traffic to an ALB as its backend target. This enables
a two-tier load balancing architecture.

```
Client
  ↓
NLB (Layer 4 — static IP, TCP)
  ↓
ALB (Layer 7 — path routing, header inspection)
  ↓
EC2 targets
```

| Property | Detail |
|----------|--------|
| Load Balancer type | ✅ **NLB only** — ALB registers another ALB |
| Protocol | TCP (because NLB operates at L4) |
| Use case | Static IP requirement (NLB) + smart routing (ALB) |

| When to Use |
|------------|
| Client requires a **static IP** (firewall allowlist) — NLB provides this |
| Application also needs HTTP-layer routing — ALB provides this |
| Enterprise with IP-allowlisting requirements |

---

## 4. Protocol — LB Type Mapping ⭐

| Load Balancer | Protocols | Layer | Target Types |
|--------------|-----------|-------|-------------|
| **ALB** | HTTP, HTTPS, HTTP/2, gRPC | L7 | Instances, IP, Lambda |
| **NLB** | TCP, TLS, UDP, TCP_UDP | L4 | Instances, IP, ALB |
| **GWLB** | GENEVE (port 6081) | L3+L4 | Instances, IP |

### HTTP Version Clarification ⭐

| Protocol | Client → ALB | ALB → Target |
|---------|-------------|-------------|
| HTTP/1.1 | ✅ | ✅ |
| HTTP/2 | ✅ (ALB terminates, converts) | HTTP/1.1 only (downgraded) |
| gRPC | ✅ | ✅ (target group protocol must be HTTP with gRPC) |

> ALB supports HTTP/2 **from the client** but communicates to targets over
> HTTP/1.1. So when creating a target group for HTTP/2 workloads,
> set the target group protocol to HTTP (not HTTP/2).
> gRPC is the exception — the target group protocol must match (gRPC).

---

## 5. Load Balancing Algorithms ⭐

| Algorithm | How | Best For |
|-----------|-----|---------|
| **Round Robin** (default) | Rotates evenly across healthy targets | Uniform request types |
| **Least Outstanding Requests** | Sends to target with fewest in-flight requests | Variable request duration (some fast, some slow) |
| **Random** | Random selection among healthy targets | Simple, even distribution without state |
| **Weighted Random** | Random, but respects target weights | A/B testing, gradual rollouts |

> Set via `load_balancing.algorithm.type` attribute on the target group.
> **Least Outstanding Requests** is better than Round Robin when some requests
> take much longer — avoids overloading slow or warming-up instances.

---

## 6. Target Group Attributes ⭐

### Deregistration Delay (Connection Draining)

When a target is **deregistered** (removed or scaling in), the load balancer:

1. Stops sending **new requests** to it immediately
2. Waits for **in-flight requests** to complete
3. After timeout → marks target as `unused`

```
States:
  healthy → draining (stop new, finish existing) → unused → terminated

Default: 300 seconds
Range:   0–3600 seconds
```

```bash
# Set deregistration delay to 60 seconds (for fast-draining services)
aws elbv2 modify-target-group-attributes \
  --target-group-arn arn:aws:... \
  --attributes Key=deregistration_delay.timeout_seconds,Value=60
```

> Set **low (30–60s)** for stateless services.
> Set **high (300+s)** for long-running connections (file uploads, WebSockets).

---

### Slow Start Mode

Gradually ramps up traffic to a **newly registered target** instead of sending
it a full share immediately. Useful for targets that need warm-up time (JVM, caches).

```
Timeline with slow_start.duration_seconds = 120:
  t=0s:    New target registered → receives ~0% of its fair share
  t=60s:   Receives ~50% of fair share
  t=120s:  Fully warmed → receives 100% fair share
  (Linear increase over the duration)
```

| Property | Value |
|----------|-------|
| Range | 30–900 seconds |
| Default | 0 (disabled) |
| Algorithm restriction | Not compatible with Least Outstanding Requests |

---

### Sticky Sessions (Session Affinity)

Binds a user's session to a specific target — all requests from that user
go to the same target for the duration of the session.

| Type | Cookie | Duration |
|------|--------|---------|
| **LB-generated cookie** (`AWSALB`) | Set by ALB | 1s to 7 days |
| **Application-based cookie** | Set by your app | Custom name, custom duration |

```
User A: first request → routed to Target-1
        Cookie: AWSALB=xxxxx (target-1 affinity)
User A: second request → reads cookie → sent to Target-1 again ✅

User B: first request → routed to Target-2
        all subsequent requests → Target-2
```

> Sticky sessions break even distribution — some targets get more load.
> Use only when your application requires session state on the server.
> **Better alternative:** Store session state in ElastiCache (Redis) — removes stickiness need.

---

## 7. Weighted Target Groups ⭐ (Blue/Green & Canary)

A listener rule can forward traffic to **multiple target groups with weights**,
enabling gradual rollouts:

```
Listener Rule: forward to
  Target Group v1 (Blue):  Weight 90  → 90% of traffic
  Target Group v2 (Green): Weight 10  → 10% of traffic (canary)
```

**Blue/Green deployment sequence:**

```bash
# Step 1: Deploy new version to Green TG, send 10% traffic
aws elbv2 modify-listener --listener-arn ... \
  --default-actions '[{"Type":"forward","ForwardConfig":{
    "TargetGroups":[
      {"TargetGroupArn":"<blue-arn>","Weight":90},
      {"TargetGroupArn":"<green-arn>","Weight":10}]}}]'
# Step 2: Monitor — no errors? Shift to 50/50
# Step 3: Full cutover
aws elbv2 modify-listener --listener-arn ... \
  --default-actions '[{"Type":"forward","ForwardConfig":{
    "TargetGroups":[
      {"TargetGroupArn":"<blue-arn>","Weight":0},
      {"TargetGroupArn":"<green-arn>","Weight":100}]}}]'
```

| Use Case | Weight Config |
|---------|--------------|
| Canary (5% new) | `old=95, new=5` |
| Blue/green (50/50) | `blue=50, green=50` |
| Full cutover | `old=0, new=100` |
| Cloud migration | `on-prem=80, aws=20` → `on-prem=0, aws=100` |

> NLB also supports Weighted Target Groups (added November 2025).

---

## 8. Health Checks ⭐

### Parameters

| Parameter | What It Controls | Default |
|-----------|-----------------|---------|
| **Protocol** | HTTP, HTTPS, TCP, gRPC | Matches TG protocol |
| **Path** | HTTP endpoint to check (e.g., `/health`) | `/` |
| **Port** | `traffic-port` or custom | `traffic-port` |
| **Healthy threshold** | Consecutive successes to mark healthy | 5 |
| **Unhealthy threshold** | Consecutive failures to mark unhealthy | 2 |
| **Timeout** | Max wait per check | 5s |
| **Interval** | Time between checks | 30s |
| **Success codes** | HTTP status codes for "healthy" | `200` |

### Health Check Port Strategies

```
Strategy 1 — traffic-port (default):
  Health check sent to same port as traffic (e.g., :80)
  ✅ Simple ❌ Health check and traffic compete for same thread pool

Strategy 2 — custom port (e.g., :8081):
  Dedicated health endpoint on different port
  ✅ Isolated ✅ App can return rich health status
  ✅ Best practice for production
```

### Target States

| State | Meaning |
|-------|---------|
| `initial` | Registered, first health check pending |
| `healthy` | Passing health checks — receives traffic |
| `unhealthy` | Failing health checks — no traffic |
| `draining` | Deregistering — finishing in-flight requests |
| `unused` | Not attached to any LB, or deregistration complete |

---

## 9. Auto Scaling Integration

Target groups integrate directly with **Auto Scaling Groups**:

```
ASG scales OUT → new EC2 launched → automatically registered to TG
ASG scales IN  → EC2 selected → TG sets to draining → waits deregistration delay
              → connections drained → instance terminated
```

> This is why deregistration delay must be set appropriately —
> if it's too short, in-flight requests are killed when ASG scales in.

**Health check grace period** (ASG setting, separate from TG health check):
```
Grace period: time after launch before ASG checks TG health status
Default: 300 seconds
Purpose: Give instance time to boot + start app before health checks run
```

---

## 10. Target Group — Scope and Limits

| Property | Detail |
|----------|--------|
| Region | Target groups are regional |
| One LB per TG | A target group can only be associated with one load balancer |
| Multiple listener rules | Same TG can be used in multiple listener rules of same LB |
| Cross-zone | Cross-zone load balancing setting can be per-target-group (ALB) |
| Max targets | No hard limit on targets per TG (soft: hundreds per group) |

---

## 11. When to Use What

| Scenario | Target Type | Algorithm |
|---------|------------|-----------|
| Standard EC2 web app with ASG | Instances | Round Robin |
| ECS containers (`awsvpc` mode) | IP | Least Outstanding Requests |
| On-premises servers via DX/VPN | IP | Round Robin |
| Serverless HTTP API | Lambda | N/A |
| NLB → smart HTTP routing | ALB | N/A |
| Long-running requests (video, ML) | Instances or IP | Least Outstanding Requests |
| Canary / blue-green deployment | Multiple TGs with weights | — |
| Session-dependent app (legacy) | Instances + sticky sessions | Round Robin |

---

## 12. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| ALB supports HTTP/2 to targets | ALB terminates HTTP/2, sends HTTP/1.1 to targets (except gRPC) |
| Lambda target works with NLB | Lambda target type is **ALB only** |
| ALB as target works with ALB | ALB as target works with **NLB only** |
| Deregistration = immediate termination | Deregistration goes through `draining` state — waits for in-flight requests |
| Sticky sessions = better performance | Sticky sessions break even distribution — only use when truly required |
| Slow start compatible with all algorithms | Slow start is **incompatible** with Least Outstanding Requests |
| One TG can serve multiple LBs | One TG can only be associated with **one** load balancer |
| Health check path must be `/` | Configure a dedicated `/health` endpoint for accurate health signals |
| Weighted TG only for ALB | NLB also supports Weighted Target Groups (Nov 2025) |
| Instance type uses public IPs | Instances type always uses **private IPs** — even if instance has a public IP |

---

## 13. Interview Questions Checklist

- [ ] What is a Target Group and why does it exist?
- [ ] What are the four target types? When do you use each?
- [ ] Why must Lambda target type be ALB only?
- [ ] Why must ALB-as-target be used with NLB only?
- [ ] Why does ALB not forward HTTP/2 to targets?
- [ ] What is deregistration delay? What states does a target go through?
- [ ] When would you set deregistration delay to 0? To 600?
- [ ] What is slow start mode? What algorithm is it incompatible with?
- [ ] Sticky sessions — two types? What is the downside?
- [ ] What is the better alternative to sticky sessions?
- [ ] What are weighted target groups? Describe a blue/green deployment using them
- [ ] What are the three load balancing algorithms? When do you choose LOR over Round Robin?
- [ ] What is a health check grace period and what sets it? (ASG — not TG)
- [ ] Can one target group serve multiple load balancers? (No)
- [ ] How does ASG + Target Group integration work for scale-in events?
