# AWS Auto Scaling

## 1. Why Auto Scaling Exists

| Problem | Without ASG | With ASG |
|---------|------------|---------|
| Traffic spike | Servers overload → downtime | New instances launched automatically |
| Low traffic | Servers idle → wasted cost | Instances terminated, cost drops |
| Instance failure | Manual detection + replacement | Auto-detected, auto-replaced |
| Deployment | Manual rollout, risky | Instance Refresh = controlled rolling update |

> ASG simultaneously provides **availability**, **elasticity**, and **cost efficiency** —
> three goals that are normally in tension.

---

## 2. Scaling Dimensions: Horizontal vs Vertical

| Type | What changes | AWS approach | Example |
|------|-------------|-------------|---------|
| **Horizontal (Scale Out/In)** | Number of instances | ✅ ASG handles automatically | 2 → 10 → 2 instances |
| **Vertical (Scale Up/Down)** | Size of instance | ⚠️ Manual — requires stop/resize/start | t3.medium → t3.xlarge |

> Cloud architecture strongly prefers horizontal scaling — it's elastic,
> doesn't require downtime, and distributes failure risk.
> Vertical scaling has an upper ceiling (largest instance type) and requires downtime.

---

## 3. ASG vs Kubernetes Scaling — Layer Separation

```
User Traffic
  ↓
Kubernetes HPA (Horizontal Pod Autoscaler)
  → Scales PODS when CPU/memory high
  → But: pods need NODES (EC2) to run on
  ↓
EC2 Node capacity fills up
  ↓
Kubernetes Cluster Autoscaler (CA)
  → Signals AWS ASG: "I need more nodes"
  ↓
AWS Auto Scaling Group
  → Launches EC2 instances (infrastructure layer)
  ↓
Karpenter (alternative to CA)
  → Direct AWS API calls, faster node provisioning
```

| Tool | Layer | Scales |
|------|-------|--------|
| **HPA (Kubernetes)** | Application | Pods and containers |
| **VPA (Kubernetes)** | Application | Pod resource requests |
| **Cluster Autoscaler** | Infrastructure | EC2 nodes via ASG |
| **Karpenter** | Infrastructure | EC2 nodes directly (no ASG dependency) |
| **AWS ASG** | Infrastructure | EC2 instances |

---

## 4. Capacity — Three Numbers ⭐

```
Minimum ≤ Desired ≤ Maximum

Minimum:  Floor — ASG never goes below this (availability guarantee)
Desired:  Current target — ASG actively maintains this count
Maximum:  Ceiling — ASG never exceeds this (cost protection)
```

| Setting | Recommended for Production |
|---------|--------------------------|
| Minimum | ≥ 1 (prevents full outage); ≥ 2 for true HA |
| Desired | Start with baseline capacity based on normal load |
| Maximum | Cap to control cost; set high enough for peak + margin |

> Setting Minimum = 0 means ASG can scale to zero — valid for dev/test to save cost,
> but dangerous for production (zero instances = zero availability).

---

## 5. ASG Instance Distribution — Multi-AZ ⭐

ASG distributes instances across the subnets you configure (one per AZ).

| Mode | Behavior | Use When |
|------|---------|---------|
| **Balanced** (default) | Tries equal distribution across AZs | High availability (recommended) |
| **Balanced Best Effort** | Prioritizes speed over balance | Fast scale-out needed |
| **Balanced Only** | Strict balance — delays if imbalance | Compliance / strict HA |

```
ASG with 3 AZs, desired = 6:
  AZ-1a: 2 instances
  AZ-1b: 2 instances
  AZ-1c: 2 instances

If AZ-1a instances terminate:
  ASG rebalances: launches in AZ-1a to restore balance
```

---

## 6. Scaling Policies — Complete Breakdown ⭐

### 1. Manual Scaling

Change `desired capacity` directly — ASG launches/terminates to reach it.
Health replacement and AZ balancing still managed by ASG.

```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name my-asg \
  --desired-capacity 5
```

---

### 2. Scheduled Scaling

Scale at predictable times — runs before the load arrives.

```
Schedule: cron(0 8 * * 1-5)    → business hours start → desired=10
Schedule: cron(0 20 * * 1-5)   → business hours end   → desired=2
Schedule: cron(0 0 * * 0)      → Sunday midnight       → desired=20
```

> **Use case:** Known load patterns — office hours, end-of-month reports, weekly jobs.

---

### 3. Dynamic Scaling

Scale in response to real-time CloudWatch metrics.

#### a) Simple Scaling (Legacy)

One threshold, one action, mandatory cooldown wait:

```
Alarm: CPU > 70% → Add 1 instance
       (then wait cooldown before re-evaluating)
```

| Limitation | Detail |
|-----------|--------|
| Cooldown blocks all scaling | Must wait even if load keeps climbing |
| Single threshold | Cannot respond proportionally to severity |
| **Deprecated in spirit** | Use Step Scaling instead |

---

#### b) Step Scaling ⭐

Multiple thresholds → proportional response — no mandatory cooldown wait:

```
CPU 60–70%:  Add 1 instance (mild spike)
CPU 70–85%:  Add 2 instances (moderate spike)
CPU 85–100%: Add 4 instances (severe spike)

CPU 40–30%:  Remove 1 instance
CPU 30–0%:   Remove 2 instances
```

> Step scaling does **not** wait for cooldown before triggering again.
> New instances have individual warmup periods instead.

---

#### c) Target Tracking Scaling ⭐ (Recommended)

You define the **target** — AWS controls the adjustment automatically:

```
Target: CPU = 50%
  Current CPU: 80% → ASG adds instances until CPU drops to ~50%
  Current CPU: 20% → ASG removes instances until CPU rises to ~50%
  AWS uses predictive math — adds more than "just enough" to avoid overshoot
```

**Built-in metrics for Target Tracking:**

| Metric | Target Example |
|--------|---------------|
| `ASGAverageCPUUtilization` | 50% |
| `ASGAverageNetworkIn` | 1 GB/min |
| `ASGAverageNetworkOut` | 1 GB/min |
| `ALBRequestCountPerTarget` | 1000 req/target |

**Custom metric:** Any CloudWatch metric (SQS queue depth, custom app metrics).

> Target Tracking is the most widely used policy — it's self-tuning and
> handles both scale-out AND scale-in with one rule.

---

### 4. Predictive Scaling

Uses ML on historical data to **pre-scale before load arrives**:

```
Historical pattern: CPU spikes every Monday 9 AM
  → Sunday 11 PM: ASG pre-launches instances
  → Monday 9 AM: instances already running ← no launch latency ✅
```

| Property | Detail |
|----------|--------|
| Requires | At least 24 hours of history (14 days for full accuracy) |
| Modes | Forecast only (visibility) or Forecast + Scale (active) |
| Combined | Use with Target Tracking for best results |

---

### Scaling Policy Comparison ⭐

| Policy | Cooldown | Proportional | Best For |
|--------|---------|-------------|---------|
| Simple | ✅ Required (blocks) | ❌ One step | Legacy only |
| Step | Warmup per instance | ✅ Yes (steps) | Variable spikes |
| Target Tracking | Warmup per instance | ✅ Auto-calculated | Production default |
| Scheduled | N/A | N/A | Predictable patterns |
| Predictive | N/A | ML-based | Regular recurring patterns |

---

## 7. Cooldown vs Warmup — Critical Distinction ⭐

These two timers are **completely different** — confusing them is the #1 ASG mistake.

### Cooldown Period (Simple Scaling only)

**Purpose:** Prevents launching/terminating another batch immediately after one action.

```
Simple scaling triggers → +2 instances launched
Cooldown starts: 300s
  (during this time: no new scaling actions, even if CPU stays high)
Cooldown ends → ASG re-evaluates
```

> **Only applies to Simple Scaling.** Target Tracking and Step Scaling do NOT
> use cooldown — they use warmup periods instead.

### Instance Warmup Period (Step + Target Tracking)

**Purpose:** Prevents newly launched instances from being counted in metrics
until they're actually ready, avoiding premature scale-in.

```
New instance launched (CPU reads 0% — it's still booting)
Warmup: 300s
  (during warmup: instance NOT counted in aggregate ASG CPU average)
  (scale-in is blocked while any instance is warming up)
Warmup ends → instance contributes to metrics → ASG can scale in if needed
```

```
Without warmup:           With warmup:
Launch 3 instances        Launch 3 instances
They show 0% CPU          They're excluded from average
Aggregate drops to 10%    Aggregate stays at true value
ASG scales IN again! ❌   No false scale-in ✅
```

| Timer | Applies To | Blocks | Purpose |
|-------|-----------|--------|---------|
| **Cooldown** | Simple scaling | All scaling actions | Prevent rapid successive actions |
| **Warmup** | Step + Target Tracking | Scale-in only | Prevent counting booting instances in metrics |
| **Grace Period** | Health checks | Health check failures | Don't kill a booting instance |

---

## 8. Health Checks ⭐

ASG checks health via two sources — both must pass:

| Check Type | What It Tests | Who Configures |
|-----------|--------------|---------------|
| **EC2 status checks** | Instance OS/hardware reachable | Always active |
| **ELB health check** | Application returns healthy HTTP response | Enable in ASG settings |
| **Custom health check** | Your own health signal via API | Optional |

```bash
# Enable ELB health checks for ASG (recommended for all LB-attached ASGs)
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name my-asg \
  --health-check-type ELB \
  --health-check-grace-period 300
```

**Unhealthy behavior:**
```
Instance fails health check
  → ASG marks as Unhealthy
  → ASG terminates it (deregisters from LB first — connection draining)
  → ASG launches replacement
  → New instance registered to LB
  → Grace period starts (health checks ignored for grace period duration)
```

---

## 9. Lifecycle Hooks ⭐ (Critical Advanced Concept)

Lifecycle hooks let you **pause** an instance during launch or termination to
run custom logic before it proceeds.

```
Normal launch:       Pending → InService
With launch hook:    Pending → Pending:Wait (PAUSED) → custom action → InService

Normal termination:  InService → Terminating → Terminated
With terminate hook: InService → Terminating:Wait (PAUSED) → custom action → Terminated
```

### Lifecycle Hook Use Cases

| Hook Type | Use Case |
|-----------|---------|
| **Launch hook** | Install software, load config, run tests, register with service discovery |
| **Terminate hook** | Drain application state, backup data, delete secrets, close DB connections, deregister from service discovery |

```
Example: Terminate hook for graceful shutdown
  Instance scaling in
    → Lifecycle hook fires
    → Sends SNS notification → Lambda runs
    → Lambda: drain DB connections, backup /var/app/cache to S3
    → Lambda calls complete-lifecycle-action → instance terminates
```

**Hook timeout:** Default 1 hour — instance stays paused up to 1 hour.
You call `complete-lifecycle-action` to release it early.

**January 2026 update:** New **instance lifecycle policy** — if a termination hook
times out or fails, you can now configure the instance to be **retained** for
manual intervention instead of force-terminated.

---

## 10. Termination Policies ⭐

When ASG needs to scale in (remove instances), it picks which instance to terminate:

| Policy | Logic |
|--------|-------|
| **Default** | Selects AZ with most instances → then: oldest LT version → closest to billing hour |
| **OldestInstance** | Terminates the instance that has been running the longest |
| **NewestInstance** | Terminates the most recently launched (useful for rollback) |
| **OldestLaunchTemplate** | Terminates instances running old LT versions (force upgrade) |
| **OldestLaunchConfiguration** | Same but for LC (legacy) |
| **ClosestToNextInstanceHour** | Terminates instance closest to next billing hour (cost-efficient) |
| **AllocationStrategy** | Maintains optimal On-Demand + Spot balance |
| **Custom (Lambda)** | Fully custom logic via Lambda function |

> **Best practice for rolling deployments:** Use `OldestLaunchTemplate` so
> instances on old AMI/config are prioritized for termination as new ones launch.

---

## 11. Scale-In Protection ⭐

Protect specific instances from being terminated during scale-in events:

```
Use case: An instance is processing a critical long-running job.
          Scale-in should skip it.

aws autoscaling set-instance-protection \
  --instance-ids i-xxxxxxxx \
  --auto-scaling-group-name my-asg \
  --protected-from-scale-in
```

> Instance protection does NOT protect from health-check-based termination.
> If the instance fails a health check, ASG terminates it regardless.

---

## 12. Warm Pools ⭐ (Reduce Scale-Out Latency)

If your instances take a long time to boot (JVM warm-up, large model loading, complex init),
a Warm Pool pre-initializes instances so they're ready instantly when needed.

```
Without Warm Pool:
  Traffic spike → ASG launches → 5 min boot → instance ready
  → Users experience 5 min degraded service ❌

With Warm Pool:
  Traffic spike → ASG moves pre-initialized instance to InService
  → 0-10 sec transition time ✅

Warm pool continuously keeps N pre-initialized instances:
  Stopped (cheapest — no compute, still EBS cost)
  Running (full cost, fastest to serve)
  Hibernated (memory preserved, faster resume than cold start)
```

| State | Cost | Resume Time |
|-------|------|------------|
| **Stopped** | EBS only (~$0.10/GB/month) | ~60-90 sec (cold start) |
| **Running** | Full EC2 cost | ~10 sec |
| **Hibernated** | EBS + small overhead | ~30-60 sec (RAM restore) |

---

## 13. Complete Instance Lifecycle ⭐

```
LAUNCH FLOW:
  Pending
    → (lifecycle hook fires if configured)
    → Pending:Wait  [custom action, up to 1 hr]
    → Pending:Proceed
  InService  ← instance receives traffic
    → (scale-in or failure)
  Terminating
    → (lifecycle hook fires if configured)
    → Terminating:Wait  [custom action]
    → Terminating:Proceed
  Terminated

WARM POOL STATES (if configured):
  Warmed:Pending → Warmed:Running/Stopped/Hibernated
    → Traffic spike → moves to Pending → InService
```

---

## 14. Complete Scaling Flow — End to End

```
1. CloudWatch alarm: ASGAverageCPUUtilization > 70%
   ↓
2. Target Tracking policy triggers
   ↓
3. ASG calculates: need 3 more instances to reach 50% target
   ↓
4. ASG launches 3 EC2s via Launch Template (LT $Default v3)
   ↓
5. Launch lifecycle hook (if configured): wait for custom action
   ↓
6. Instance state: Pending → InService
   ↓
7. ASG registers instance with ALB Target Group
   ↓
8. Target Group health check runs
   ↓
9. Instance health: healthy → starts receiving traffic
   ↓
10. Warmup period: instance excluded from aggregate metrics
    ↓
11. Warmup expires → instance contributes to CPU average
    ↓
12. CPU drops to ~50% → scaling stops
```

---

## 15. Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|---------|
| Cooldown applies to all scaling policies | Cooldown applies to **Simple Scaling only** |
| Warmup and cooldown are the same thing | Cooldown blocks all scaling; warmup excludes metrics from booting instances |
| Grace period = warmup period | Grace period = health check delay; warmup = metric exclusion for scaling math |
| Target Tracking waits for cooldown | TT uses **per-instance warmup**, not a global cooldown |
| Simple scaling is fine for production | Use Step Scaling or Target Tracking — Simple Scaling's cooldown causes dangerous delays |
| Scale-in protection prevents health termination | Protection only blocks scale-in policy termination — health failures still terminate |
| Warm Pool instances are free | Stopped warm pool instances still pay for **EBS storage** |
| Lifecycle hooks default to 30 minutes | Default timeout is **1 hour** |
| Termination = immediate | ASG deregisters from LB first → connection draining → then terminates |
| ASG handles Kubernetes node scaling | Kubernetes Cluster Autoscaler or **Karpenter** signals ASG; ASG doesn't watch Kubernetes |

---

## 16. Interview Questions Checklist

- [ ] What three problems does Auto Scaling solve?
- [ ] Horizontal vs vertical scaling — which does AWS prefer and why?
- [ ] What are the three capacity numbers? Relationship constraint?
- [ ] Why is Minimum = 0 bad for production?
- [ ] List all 5 scaling policy types with a use case for each
- [ ] Simple vs Step vs Target Tracking — key differences?
- [ ] What metric does Target Tracking use for ALB? (ALBRequestCountPerTarget)
- [ ] Cooldown vs warmup period — what does each block and when does each apply?
- [ ] What happens if a newly launched instance is counted in metrics during warmup?
- [ ] What are lifecycle hooks? Give a real use case for terminate hook
- [ ] What is the default lifecycle hook timeout? (1 hour)
- [ ] What is the January 2026 lifecycle policy update? (retention on timeout)
- [ ] What is a termination policy? Name 4 options
- [ ] What is scale-in protection? What doesn't it protect against?
- [ ] What is a Warm Pool? Three instance states and their costs?
- [ ] When does ASG deregister from LB before termination? (always — connection draining)
- [ ] ASG vs Kubernetes scaling — two separate layers, explain each
- [ ] Walk through the complete lifecycle of an instance from launch to termination

---

## Nectar

