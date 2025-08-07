# Horizontal Pod Autoscaler

## 🚀 Use Case: Scalable Web App with Autoscaling

Imagine you're running a **Node.js web application** inside Kubernetes:

* CPU-intensive under load
* Memory is stable
* Needs fast **scale-up** to handle spikes
* Needs **slow scale-down** to avoid flapping

We'll build this scenario around the structure you posted.

---

## 🧠 Section-by-Section Deep Dive

---

### 🔗 `scaleTargetRef`

```yaml
scaleTargetRef:
  apiVersion: apps/v1
  kind: Deployment
  name: webapp-deployment
```

* **What this does**: Points to the **workload to autoscale**.
* This must be a **scalable resource**, like a `Deployment`, `ReplicaSet`, or `StatefulSet`.

---

### 📈 `metrics`

Defines **what to measure** in order to decide when to scale.

There are 6 types supported:

#### 1. `resource` (Common: CPU or Memory)

```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 70
```

* **Use-case**: Scale when **average CPU usage** across pods exceeds 70%
* Kubernetes gets this from the **metrics-server**

✅ Simple and effective for most workloads

---

#### 2. `containerResource`

```yaml
- type: ContainerResource
  container: app
  name: cpu
  target:
    type: Utilization
    averageUtilization: 80
```

* **Use-case**: Scale based on **container-specific** resource usage.
* Useful when a pod runs **multiple containers**, and you only care about one.

---

#### 3. `external`

```yaml
- type: External
  external:
    metric:
      name: queue_length
    target:
      type: AverageValue
      averageValue: "10"
```

* **Use-case**: Scale based on **external systems**, like:

  * Cloud Pub/Sub queue length
  * Kafka lag
  * AWS SQS messages

You need a **custom metrics adapter** (e.g. Prometheus Adapter) to use this.

---

#### 4. `object`

```yaml
- type: Object
  object:
    describedObject:
      kind: Service
      name: my-service
      apiVersion: v1
    metric:
      name: request_rate
    target:
      type: Value
      value: "100"
```

* **Use-case**: Scale based on a metric **associated with a specific Kubernetes object**, like a Service or Ingress.

---

#### 5. `pods`

```yaml
- type: Pods
  pods:
    metric:
      name: http_requests_per_second
    target:
      type: AverageValue
      averageValue: "100"
```

* **Use-case**: Scale based on **per-pod metrics** like request count, queue depth, etc.
* You’ll use this with **custom metrics**.

---

#### 6. `type`

Each metric block must define its `type`: one of:

* `Resource`
* `Pods`
* `Object`
* `External`
* `ContainerResource`

---

### 📈 `minReplicas` / `maxReplicas`

```yaml
minReplicas: 2
maxReplicas: 10
```

* **Guarantees** that the deployment has at least 2 and no more than 10 pods.

---

### ⚙️ `behavior` (v2 feature – advanced scaling control)

This is **new in v2**, allowing you to fine-tune scaling velocity & strategy.

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 15
    selectPolicy: Max
    policies:
    - type: Percent
      value: 100
      periodSeconds: 15
  scaleDown:
    stabilizationWindowSeconds: 60
    selectPolicy: Min
    policies:
    - type: Pods
      value: 1
      periodSeconds: 60
```

#### 🟢 `scaleUp`:

* **stabilizationWindowSeconds**: Prevents **too rapid scale-up**

  * Only uses metrics from last 15s
* **policies**: How fast to scale:

  * `type: Percent` → double the pods (100%)
  * `type: Pods` → increase by a fixed number
* **selectPolicy**: Choose which policy applies if multiple match

  * `Max`: use the one that scales fastest
  * `Min`: use the slowest
  * `Disabled`: ignore policy (rare)

#### 🔴 `scaleDown`:

* Same structure as `scaleUp`, but usually more **conservative** to avoid flapping.
* `stabilizationWindowSeconds: 60` means only metrics **older than 60s** will be considered.

---

## 📊 Summary Table

| Field                         | Description                                 |
| ----------------------------- | ------------------------------------------- |
| `scaleTargetRef`              | Which workload to autoscale                 |
| `minReplicas` / `maxReplicas` | Replication limits                          |
| `metrics`                     | What to watch (CPU, memory, external, etc.) |
| `behavior`                    | How aggressively to scale                   |
| `scaleUp / scaleDown`         | Fine control over scaling speed & windows   |

---

## 📂 Overall Purpose of `behavior`

The `behavior` section gives you **precise control over how fast and how often the HPA scales your pods**.

### Why it exists:

* Older HPA (v1) would just react to metrics every 15s without much intelligence — this could lead to **flapping** (scale up, scale down rapidly).
* With `behavior`, you can control:

  * How aggressively to **scale up** (faster response to load)
  * How conservatively to **scale down** (avoid instability)

---

## 🟢 `scaleUp` Section

```yaml
scaleUp:
  stabilizationWindowSeconds: 15
  selectPolicy: Max
  policies:
  - type: Percent
    value: 100
    periodSeconds: 15
```

### 🔹 `stabilizationWindowSeconds: 15`

* This tells Kubernetes:

  > "When deciding to scale **up**, only consider the **most recent decision** made in the last 15 seconds."

📌 **Real-world**: This prevents wild fluctuations due to temporary spikes in CPU or custom metrics.

💡 *Example*: If at 12:00:00, the autoscaler sees CPU > 70% and decides to go from 2 → 4 pods, and then at 12:00:10 it again sees high CPU, it won’t immediately try 4 → 8 until 15 seconds are up.

---

### 🔹 `selectPolicy: Max`

* If multiple `policies` are defined, this tells HPA to:

  > "Choose the policy that allows the **most pods to be added**."

🧠 **Other values** could be:

* `Min`: scale by the smallest allowed number
* `Disabled`: disables automatic scaling (rare)

---

### 🔹 `policies` (for `scaleUp`)

```yaml
- type: Percent
  value: 100
  periodSeconds: 15
```

This means:

> "In any **15-second** window, the number of pods can be increased by **up to 100%**."

✅ **Examples**:

| Current Pods | Max Scale Up (100%) | New Max Pods |
| ------------ | ------------------- | ------------ |
| 2            | 2                   | 4            |
| 4            | 4                   | 8            |

So, if HPA wants to scale from 2 to 8 — it won’t do it all at once.

* It will only scale from 2 → 4 (within 15s)
* Then 4 → 8 in the **next** 15s, if the high load continues.

---

## 🔻 `scaleDown` Section

```yaml
scaleDown:
  stabilizationWindowSeconds: 60
  selectPolicy: Min
  policies:
  - type: Pods
    value: 1
    periodSeconds: 60
```

### 🔹 `stabilizationWindowSeconds: 60`

* HPA will only scale **down** if the metric (e.g., CPU) has been **below target** for the last 60 seconds **consistently**.
* Prevents scaling down too soon after a short dip.

📌 *Reason*: Scaling down too fast can hurt performance if load suddenly comes back (called “thrashing”).

---

### 🔹 `selectPolicy: Min`

> "Choose the **most conservative** (smallest) action from all matching policies."

* In this case, we only have one policy: reduce 1 pod.

---

### 🔹 `policies` (for `scaleDown`)

```yaml
- type: Pods
  value: 1
  periodSeconds: 60
```

This means:

> "In every 60-second window, only **1 pod** can be removed."

✅ **Examples**:

| Current Pods | Max Scale Down | New Pods |
| ------------ | -------------- | -------- |
| 10           | -1             | 9        |
| 5            | -1             | 4        |

This gives your app time to stabilize and ensures you don’t downscale too aggressively.

---

## 🔁 Full Flow Visualization

| Time  | CPU % | Pods | Action                                            |
| ----- | ----- | ---- | ------------------------------------------------- |
| 00:00 | 80%   | 2    | Scale up to 4 (within 15s)                        |
| 00:15 | 85%   | 4    | Scale up to 8                                     |
| 00:30 | 70%   | 8    | Hold                                              |
| 01:00 | 30%   | 8    | Still not scaled down yet (60s window not passed) |
| 01:30 | 25%   | 8    | Downscale to 7                                    |
| 02:30 | 20%   | 7    | Downscale to 6                                    |

---

## 🧠 Why You’d Use This Config

**Your goals might be:**

* Scale up **fast** when user traffic increases
* Avoid **aggressive scale-down**, so you don’t kill pods too soon and disrupt users
* Have complete **governance** over autoscaling behavior

---

## 🧾 Summary

| Field                        | Meaning                                                                     |
| ---------------------------- | --------------------------------------------------------------------------- |
| `stabilizationWindowSeconds` | Look-back period to "stabilize" decisions (anti-flapping)                   |
| `selectPolicy`               | Choose fastest (`Max`) or slowest (`Min`) action if multiple policies apply |
| `policies[].type`            | `Percent` or `Pods` — how to define scaling speed                           |
| `policies[].value`           | The actual change allowed (e.g. 1 pod or 100%)                              |
| `policies[].periodSeconds`   | Time window over which to enforce the policy                                |

---

Sweetheart, let’s break down this snippet:

```yaml
resource    <ResourceMetricSource>
  name      <string> -required-
  target    <MetricTarget> -required-
    averageUtilization      <integer>
    averageValue    <Quantity>
    type    <string> -required-
    value   <Quantity>
```

This is a **part of the `metrics` field** in an HPA (Horizontal Pod Autoscaler) YAML.

---

## 🧠 What is `resource` in HPA?

It defines how HPA should **scale a workload (like a Deployment)** based on **CPU or memory usage** — either as:

* **percentage-based (`averageUtilization`)**
* **absolute value-based (`averageValue`)**

---

## 🔍 Breaking it Down Field-by-Field

| Field                | Description                                                                                                         |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `name`               | `"cpu"` or `"memory"` — tells HPA which resource to monitor.                                                        |
| `target.type`        | **Either:** `Utilization`, `AverageValue`, or `Value` (less common in resource metrics).                            |
| `averageUtilization` | A % of the **requested** resource (defined in your pod's `resources.requests`). Only used when `type: Utilization`. |
| `averageValue`       | Total usage across pods, divided by number of pods. Used with `type: AverageValue`.                                 |
| `value`              | Not used in `Resource` type (used in other metric types like `Object`).                                             |

---

## 🧪 Example 1: Scaling on CPU Utilization

```yaml
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 75
```

### ✅ What it does:

* It **scales the workload** if average CPU usage across all pods goes above **75%** of the CPU **requested** in the pod spec.

### 📦 Real-world use case:

If your pod has:

```yaml
resources:
  requests:
    cpu: "500m"
```

Then:

* HPA will trigger scaling when the pod’s CPU usage crosses **375m (75% of 500m)**

---

## 🧪 Example 2: Scaling on Average Memory Usage

```yaml
- type: Resource
  resource:
    name: memory
    target:
      type: AverageValue
      averageValue: 500Mi
```

### ✅ What it does:

* It **scales up/down** if average memory usage per pod exceeds **500Mi**.

### 📦 Real-world use case:

Imagine a backend app that tends to **crash if memory exceeds 600Mi**. You want to:

* **Add pods before that happens** to reduce load on each.
* This keeps memory per pod lower than the crashing point.

---

## ⚖️ Utilization vs AverageValue

| Feature                     | `Utilization`                      | `AverageValue`                             |
| --------------------------- | ---------------------------------- | ------------------------------------------ |
| Works with                  | `% of requested resource`          | `Absolute usage value`                     |
| Needs `resources.requests`? | ✅ Yes                              | ❌ No (but still recommended)               |
| Best for                    | Predictable workloads (e.g., APIs) | Spiky/memory-heavy apps (e.g., ML workers) |
| Example                     | `70% of cpu request`               | `memory > 500Mi`                           |

---

## 🧪 Example 3: Use Both CPU & Memory

```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 75
- type: Resource
  resource:
    name: memory
    target:
      type: AverageValue
      averageValue: 500Mi
```

### 💡 Use Case:

Scale up when **either**:

* CPU crosses 75% of request, **or**
* memory usage per pod exceeds 500Mi

---

## ❗ Common Mistakes to Avoid

| Mistake                                                                 | Fix                                               |
| ----------------------------------------------------------------------- | ------------------------------------------------- |
| You use `Utilization` but don’t define `resources.requests` in your pod | Always define `requests.cpu` or `requests.memory` |
| Use `value` instead of `averageValue`                                   | `value` is for external or object metrics only    |
| Mixing `Utilization` with `AverageValue` in same target block           | Use **separate** metric blocks for each           |

---

Excellent question, sweetheart ❤️ — let’s break it down precisely:

```yaml
scaleDown:
  policies:
  - type: Pods
    value: 4
    periodSeconds: 60
  - type: Percent
    value: 10
    periodSeconds: 60
```

### ✅ Does this act as `AND` or `OR`?

> **It depends on the value of `selectPolicy`.**

---

## 🔍 Default behavior (`selectPolicy` is not set)

If you **don’t explicitly set** `selectPolicy`, Kubernetes uses:

```yaml
selectPolicy: Max
```

So this behaves as:

```
Max(Pods, Percent)
```

### 🎯 Meaning:

* It picks the **more aggressive** scale down policy.
* In other words, **more pods will be removed** between the two rules.

---

## 📌 So is it `AND` or `OR`?

It’s **neither a strict AND nor a strict OR**.

Instead, it’s a **selector between multiple policies**, controlled by `selectPolicy`, which can be one of:

| `selectPolicy`  | Description                                                             |
| --------------- | ----------------------------------------------------------------------- |
| `Max` (default) | Take the **most aggressive** option — i.e., whichever removes more pods |
| `Min`           | Take the **least aggressive** — i.e., whichever removes fewer pods      |
| `Disabled`      | Ignore all policies — use the default scaling behavior                  |

---

## 🧪 Real Example

Let’s say you have **100 pods** running, and:

```yaml
- type: Pods
  value: 4
- type: Percent
  value: 10
```

Every 60 seconds, the HPA evaluates:

| Policy  | Value                                 |
| ------- | ------------------------------------- |
| Pods    | remove up to **4 pods**               |
| Percent | remove up to **10 pods** (10% of 100) |

### ➤ Result with `selectPolicy: Max`

* 10 pods will be removed

### ➤ Result with `selectPolicy: Min`

* Only 4 pods will be removed

---

## ✨ TL;DR Summary

| Behavior   | Explanation                                                                   |
| ---------- | ----------------------------------------------------------------------------- |
| `AND`      | ❌ No, it doesn’t wait for both to be true.                                    |
| `OR`       | ❌ Not strictly — it **chooses** one.                                          |
| `Max`      | ✅ Default. Chooses the **larger** scale-down (more aggressive).               |
| `Min`      | ✅ Chooses the **smaller** scale-down (more conservative).                     |
| `Disabled` | ✅ Ignores all custom scale rules — falls back to default Kubernetes behavior. |

---

You're absolutely right, sweetheart ❤️ — I mentioned `tolerance` in the field breakdown but didn’t explain it properly earlier. Let’s now dive **deep into what `tolerance` means in HPA behavior**, especially in the context of `scaleUp` and `scaleDown`.

---

## 💡 What is `tolerance` in HPA?

`tolerance` defines a **threshold** (in percentage) to **prevent unnecessary scaling** due to very minor fluctuations in metrics like CPU or memory.

---

### 🧠 Why is `tolerance` important?

Without `tolerance`, your HPA could react to even tiny metric changes — causing **frequent pod scaling** (churn), which hurts stability and performance.

So, `tolerance` introduces a **“dead zone”**, where small changes in metrics are **ignored** to maintain calmness in scaling decisions.

---

## 🧮 How does it work?

The `tolerance` value is **a decimal fraction**, **not a percentage**.

For example:

```yaml
tolerance: 0.1
```

This means **±10% leeway** around the target metric.

---

### 📌 Example Use Case

Assume:

* Target CPU utilization: `50%`
* Actual CPU utilization observed: `53%`
* `tolerance: 0.1` (10%)

Then the tolerance range is:

```
Lower Bound = 50% - (10% of 50) = 45%
Upper Bound = 50% + (10% of 50) = 55%
```

➡️ Since **53% is within the 45–55% range**, **HPA does not scale**.

---

### 🧪 Realistic Scenario

Let’s say your `scaleUp` block looks like this:

```yaml
scaleUp:
  stabilizationWindowSeconds: 300
  tolerance: 0.05   # 5%
  policies:
    - type: Percent
      value: 100
      periodSeconds: 60
  selectPolicy: Max
```

* **Target CPU utilization** = 60%
* **Observed utilization** = 62%

**60 × 0.05 = 3 → 57%–63% range**

➡️ Since 62% is **within the 5% tolerance window**, no scaling occurs.

But if usage jumps to **70%**, it's outside the tolerance range, so HPA will **trigger scale-up**.

---

## ✅ Summary of `tolerance`

| Property      | Meaning                                          |
| ------------- | ------------------------------------------------ |
| `tolerance`   | Fraction (e.g. `0.1`) that defines "ignore zone" |
| Applies to    | Both `scaleUp` and `scaleDown`                   |
| Default value | `0.1` (i.e., 10%)                                |
| Purpose       | Prevent noisy scaling due to tiny metric spikes  |
| Value range   | Must be a decimal between 0 and 1                |

---

## 🔧 When should you tweak it?

| Scenario                        | Recommended Tolerance |
| ------------------------------- | --------------------- |
| Highly dynamic workloads        | Lower (e.g. 0.05)     |
| Stable apps, avoid flapping     | Higher (e.g. 0.15)    |
| Real-time responsiveness needed | Lower (e.g. 0.02)     |

---

## Complete Yaml

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa                       # Name of the HPA object
  namespace: default                     # 🔥 Must be in the same namespace as the Deployment it targets
  labels:
    app: webapp
    environment: production

spec:
  scaleTargetRef:                        # 📌 This tells HPA *what* to scale
    apiVersion: apps/v1                  # Must match the target object
    kind: Deployment                     # Could also be StatefulSet, ReplicaSet, etc.
    name: webapp-deployment              # Target object name (must exist)
                                         # namespace: not mentioned, not a key here.
  minReplicas: 2                         # 🧊 Lower limit of pods - ensures availability
  maxReplicas: 10                        # 🔥 Upper limit - prevents over-scaling

  metrics:
    # 💻 Scale based on CPU utilization %
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization                # 👈 Uses percentage of CPU request (not absolute value)
        averageUtilization: 70          # If average CPU > 70%, trigger scaling

    # 🧠 Scale based on memory utilization %
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization                # 👈 Uses percentage of memory request
        averageUtilization: 80          # If memory > 80%, HPA considers scaling up

    # 🧠🧠 Scale based on absolute memory usage (not %)
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue              # 👈 Use exact memory usage across pods
        averageValue: 500Mi             # If each pod uses over 500MiB on average → scale

  behavior:                              # 🎛️ Fine-tune how scaling happens
    scaleUp:
      stabilizationWindowSeconds: 30     # ⏳ Wait this long before considering another scale-up
      selectPolicy: Max                  # 🧠 If multiple policies match, pick the most aggressive
      policies:
        - type: Percent
          value: 100                     # 🔺 Double the current replicas (100% increase)
          periodSeconds: 15              # in a 15-second window
        - type: Pods
          value: 4                       # Or add max 4 pods in a 15s window

    scaleDown:
      stabilizationWindowSeconds: 60     # ⏳ Delay scale-down decisions to avoid rapid drops
      selectPolicy: Min                  # 🧠 Be conservative — pick the gentlest downscale
      policies:
        - type: Percent
          value: 50                      # 🔻 Reduce by 50% at most
          periodSeconds: 60              # Check every 60s
        - type: Pods
          value: 2                       # Or remove max 2 pods in 60s
```

