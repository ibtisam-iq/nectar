# Kubernetes Probes - Foundation & Advanced Understanding

This document builds upon our foundational understanding of Pod lifecycle, container states, and pod conditions to introduce one of Kubernetes' most intelligent and proactive capabilities: **Probes**. Probes help Kubernetes determine the health and readiness of containers inside Pods.

---

## 🚦 What is a Probe?
A **probe** is a diagnostic performed **periodically by the Kubelet** on a container. Based on the results of this check, Kubernetes can decide:

- Should the container be restarted?
- Should the container be considered ready to receive traffic?
- Is the container still starting up and needs time?

In essence, probes **make your containers observable**, and allow Kubernetes to act when things go wrong **_before_ users notice.**

Kubelet performs the probe using one of four **check mechanisms**, and there are **three probe types** (liveness, readiness, and startup).

---

## 🧪 Probe Check Mechanisms
When defining a probe, you must choose **one of these four mechanisms** to run the check. Each performs a different type of check against the container:

### 1. `exec`
Runs a command **inside the container**. If the command exits with code `0`, the container is considered healthy.

```yaml
exec:
  command:
    - cat
    - /tmp/healthy
```

📌 Use case: Check for the presence of a file, status of a background task, or process-specific health indicators.

⚠️ **Warning:** Spawns a process every time the check runs — not recommended for clusters with high Pod density.

---

### 2. `httpGet`
Makes an **HTTP GET request** to the container on a specific `port` and `path`. Status codes between `200-399` mean success.

```yaml
httpGet:
  path: /healthz
  port: 8080
```

📌 Use case: Most web services expose a `/health` or `/ping` endpoint.

---

### 3. `tcpSocket`
Performs a **TCP socket check**. If the port is open, the container is considered healthy.

```yaml
tcpSocket:
  port: 3306
```

📌 Use case: Simple readiness of services like MySQL, Redis, etc., without needing HTTP.

---

### 4. `grpc`
Performs a **gRPC health check** by calling the standard `Check` method.

```yaml
grpc:
  port: 50051
```

📌 Use case: Microservices using gRPC protocol with built-in health server.

---

## 🧾 Probe Outcomes
Each time a probe runs, it results in one of three outcomes:

- ✅ **Success**: Container passed the probe.
- ❌ **Failure**: Container failed the check; action depends on the type of probe.
- ❓ **Unknown**: Check couldn’t be completed (e.g., timeout); kubelet tries again.

---

## 🔁 Types of Probes
There are three types of probes, each serving a distinct purpose in a container’s lifecycle:

### 1. **Liveness Probe**
Checks **if the container is alive** (or stuck). 

If this probe **fails**, the container is killed and restarted according to its `restartPolicy`.

📌 Use Case:
- Detect deadlocks
- Restart broken apps

🔧 _Defaults to **Success** if not defined._

---

### 2. **Readiness Probe**
Checks **if the container is ready to serve traffic**. 

If this probe **fails**, the container is **removed from the Service load balancer endpoints**.

📌 Use Case:
- Wait for app to connect to DB
- Temporarily take service down for internal operations

🔧 _Defaults to **Success** after initial delay._

---

### 3. **Startup Probe**
Checks whether the application has **finished starting**. Until it succeeds, Kubernetes **disables the liveness and readiness probes**.

📌 Use Case:
- Applications with heavy boot time: migrations, warmups
- Avoid early restarts from failing liveness checks

🔧 _Defaults to **Success** if not defined._

---

## 🔍 Probes In-Depth: Fields That Matter
Let’s dive into the **key configuration fields** that fine-tune how probes behave:

### `initialDelaySeconds`
⏱️ Time (in seconds) to wait **after the container starts** before running the probe.

🔧 Default: `0`

📌 Use Case:
- Your app takes 10s to boot up? Set this to `10`.

---

### `periodSeconds`
🔁 How often (in seconds) to run the probe. 

🔧 Default: `10`

📌 Use Case:
- Lower for rapid detection (5s), higher to reduce CPU/network traffic.

---

### `timeoutSeconds`
🛑 If a probe takes more than this time (in seconds), it’s considered a **failure**.

🔧 Default: `1`

📌 Use Case:
- Slow network or backend? Consider bumping this to `3-5`.

---

### `failureThreshold`
🚨 Number of consecutive **failures** before the probe is considered failed.

🔧 Default: `3`

📌 Use Case:
- Avoid false alarms due to temporary blips.

---

### `successThreshold`
✅ Number of consecutive **successes** required to mark a previously failed probe as **passed**.

🔧 Default: `1`

📌 Use Case:
- Ensure your service stabilizes before re-adding to the load balancer.

---

## 🧠 Summary: How These Fields Work Together
Imagine you define this startup probe:

```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 5
  failureThreshold: 12
```

📌 This gives your container **60 seconds (12 × 5)** to start responding to `/health` endpoint.

Once the startup probe succeeds, Kubernetes enables **liveness** and **readiness** probes. From here:
- Liveness probes keep the container alive
- Readiness probes ensure traffic goes only to ready instances

---

## 🚦 When to Use Which Probe?
| Probe Type      | Purpose                                  | Kubernetes Reaction                  |
|------------------|------------------------------------------|--------------------------------------|
| `livenessProbe`  | Detect if container is dead or stuck     | Kill & restart container             |
| `readinessProbe` | Control traffic during boot & maintenance| Remove from Service endpoint         |
| `startupProbe`   | Delay other probes until app is started  | Give extra time before restarts      |

---

## ✅ Best Practices
- Prefer `httpGet` or `tcpSocket` over `exec` in high-density clusters.
- Define `readinessProbe` even if it duplicates `livenessProbe` — they serve **different purposes**.
- Tune thresholds based on app characteristics — there’s no one-size-fits-all.


