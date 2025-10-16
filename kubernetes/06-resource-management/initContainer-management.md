## Resource sharing within containers

Given the order of execution for init, sidecar and app containers, the following rules for resource usage apply:

- The highest of any particular resource request or limit defined on all init containers is the effective init request/limit. If any resource has no resource limit specified this is considered as the highest limit.
- The Pod's effective request/limit for a resource is the sum of pod overhead and the higher of:
  - the sum of all non-init containers(app and sidecar containers) request/limit for a resource
  - the effective init request/limit for a resource
- Scheduling is done based on effective requests/limits, which means init containers can reserve resources for initialization that are not used during the life of the Pod.


---

* Effective init = highest among init containers
* Pod’s effective request = max(sum(non-init containers), effective init) + overhead
* Scheduling, quota, QoS decisions use the effective pod request/limit
* Init can reserve resources even if not used later

---

## 🔥 Exam-Style Questions

### Q1

A Pod has:

* Two init containers:

  * `init-A`: 200 Mi memory request
  * `init-B`: 150 Mi memory request
* Two app containers (non-init):

  * `app-1`: 120 Mi request
  * `app-2`: 140 Mi request

Assume no overhead.
What is the Pod’s **effective memory request** (for scheduling)?
If the namespace has a ResourceQuota of 300 Mi, will this Pod be allowed?

### Answer

* Effective init = max(200, 150) = **200 Mi**
* Sum non-init = 120 + 140 = **260 Mi**
* Effective Pod request = max(200, 260) = **260 Mi**
* Quota is 300 Mi, so yes, this Pod fits (260 ≤ 300).

---

### Q2

You have a Deployment (1 replica) with:

* Two init containers:

  * `init-setup1`: 300 Mi memory request
  * `init-setup2`: 500 Mi memory request
* Two application containers:

  * `frontend`: 250 Mi
  * `backend`: 200 Mi

Also assume a pod overhead of 50 Mi.
Compute the effective memory request.
If the namespace quota is 900 Mi, is this Pod allowed?

### Answer

* Effective init = max(300, 500) = **500 Mi**
* Sum non-init = 250 + 200 = **450 Mi**
* Pod overhead = 50 Mi → we add overhead (if asked)
* Effective Pod request = max(500, 450) + 50 = **550 Mi**
* Namespace quota = 900 Mi → yes, 550 ≤ 900, so allowed.

---

### Q3

A Deployment with 3 replicas. For each Pod:

* init containers:

  * `init1`: 400 Mi
  * `init2`: 600 Mi
* application containers:

  * `serviceA`: 350 Mi
  * `serviceB`: 250 Mi

No overhead.

1. What is effective memory per Pod?
2. Total across all replicas?
3. If namespace quota is 1800 Mi, will the Deployment be admitted?

### Answer

* Effective init = max(400, 600) = **600 Mi**
* Sum non-init = 350 + 250 = **600 Mi**
* Effective Pod request = max(600, 600) = **600 Mi**
* 3 replicas × 600 = **1800 Mi** total
* Namespace quota = 1800 Mi → it exactly matches, so okay (barely).

---

### Q4

Pod has:

* init containers:

  * `init1`: request = 100 Mi
  * `init2`: no memory limit/request specified
* app containers:

  * `worker`: 120 Mi
  * `logger`: 30 Mi

What is Pod’s effective memory request (consider “no limit / no request” in init as highest)?

### Answer

* `init1` has 100 Mi request
* `init2` has *no memory request or limit specified* → this is considered highest (unbounded) or effectively infinity for that resource
* So effective init = “no limit” / effectively infinite → meaning init could demand more
* Sum non-init = 120 + 30 = 150 Mi
* Pod’s effective = whichever is higher: effective init (unbounded) vs 150 → effective init wins
* So Pod effective request = “unbounded / infinite” — in practice that means scheduling fails or is constrained by node or quota.
  (In real K8s, lacking a limit is “best-effort”, but for init container lacking explicit request is considered highest)

---

### Q5

A Deployment with 2 replicas. Each Pod:

* init containers:

  * `initA`: 150 Mi
  * `initB`: 250 Mi
* app containers:

  * `web`: 200 Mi
  * `api`: 180 Mi

Also consider pod overhead of 20 Mi.
Compute effective request per Pod and total for the Deployment.
If namespace quota = 900 Mi, is it okay?

---

### Answer

* Effective init = max(150, 250) = **250 Mi**
* Sum non-init = 200 + 180 = **380 Mi**
* Pod overhead = 20 Mi → adding if needed
* Effective Pod request = max(250, 380) + 20 = **400 Mi**
* Deployment has 2 replicas → total = 2 × 400 = **800 Mi**
* Namespace quota = 900 Mi → 800 ≤ 900, so acceptable.
