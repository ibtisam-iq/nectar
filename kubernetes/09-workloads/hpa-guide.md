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

