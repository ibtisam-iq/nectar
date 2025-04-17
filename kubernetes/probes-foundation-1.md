# 🧠 Understanding Pod Status, Container States, and Probes in Kubernetes

In Kubernetes, **Probes** (liveness, readiness, startup) are essential for maintaining healthy application workloads. However, to fully appreciate **why probes are needed** and **how they function**, it's crucial to first understand:

- The **ephemeral nature of Pods**
- **Pod lifecycle and phases**
- **Container states** and how containers behave inside a Pod
- **Pod conditions** and what they signify
- **Crash loops** and restart policies

This document connects all the dots to give you the clearest picture, so you’ll never forget why and when to use probes.

---

## 🌀 Pods Are Ephemeral

Pods in Kubernetes are **not long-lived entities**. Think of them like temporary containers for your app's logic. Once scheduled to a Node, they stay there until:

- They complete execution (if configured to do so)
- They crash and exit
- They are explicitly deleted
- The Node itself dies

Pods are **never rescheduled to another Node**. Instead, Kubernetes creates a **new Pod with a new UID**.

---

## 🔁 Pod Lifecycle Phases

Kubernetes provides a high-level **`.status.phase`** field to show where the Pod is in its lifecycle.

| Phase     | Meaning |
|-----------|--------|
| `Pending` | Pod accepted but containers not started yet (e.g. pulling image). |
| `Running` | Pod is on a node; at least one container is active. |
| `Succeeded` | All containers completed successfully and won't restart. |
| `Failed` | All containers exited with failure. |
| `Unknown` | Pod state could not be retrieved (e.g., communication error with Node). |

> ⚠️ `CrashLoopBackOff` is **not a phase**, it's an event shown in `kubectl get pods` when containers keep crashing.

---

## 🔎 Container States (Inside Pods)

Each container has a more granular lifecycle state. You can inspect these using:

```bash
kubectl describe pod <pod-name>
```

### 1. `Waiting`
Container is not yet running. It's usually pulling images, applying secrets, or waiting for conditions.

### 2. `Running`
Container is actively running. Any `postStart` hook has completed.

### 3. `Terminated`
Container exited, either due to success or failure. You’ll see `exit code`, `reason`, and `start/finish time`.

---

## 🚨 CrashLoopBackOff Explained

This is a common issue and it's related to probe misconfiguration, resource limits, app bugs, etc.

### Sequence:
1. A container crashes
2. Kubernetes tries to restart it (based on `restartPolicy`)
3. If crashes continue, **exponential backoff** kicks in
4. You'll see the status `CrashLoopBackOff`

### Common Causes:
- App bugs or misconfig
- Not enough CPU/memory
- Failing probes
- Missing Secrets/configs

---

## 🔄 Container Restart Policies

Controlled by `restartPolicy` in Pod spec:

| Value     | Behavior |
|-----------|----------|
| `Always` | Always restart (default) |
| `OnFailure` | Restart only if exit code is non-zero |
| `Never` | Never restart the container |

> 🧠 `restartPolicy` applies to **init containers and app containers**, not sidecars in `initContainers`.

---

## 📶 Pod Conditions

These are boolean-type checkpoints that the Kubelet uses to evaluate Pod health.

| Condition             | Meaning |
|-----------------------|---------|
| `PodScheduled`        | Pod has been assigned to a Node |
| `Initialized`         | All init containers completed successfully |
| `ContainersReady`     | All main containers in Pod are healthy and ready |
| `Ready`               | Pod is fully ready to serve traffic |
| `PodReadyToStartContainers` | Networking and sandbox setup complete (beta feature) |

---

## 🔗 Connecting the Dots to Probes

Why are all of the above concepts **critical to understand probes**?

Because Kubernetes does **not inherently know if your app is healthy** just because the container is running.

You could have a case where:

- Container is `Running`
- Pod is `Ready`
- But your app has crashed inside (e.g. 500 errors, memory leak)

To solve this, Kubernetes offers:

- **Liveness Probes**: Is the app alive or dead? Restart if it’s dead.
- **Readiness Probes**: Is the app ready to serve traffic?
- **Startup Probes**: Did the app start up correctly? (esp. for slow booting apps)

Each of these probes uses the pod/container lifecycle information + pod conditions to decide **what actions to take and when**.

---
## 🤔 Continue Reading...

- Please click [here](probes-foundation-2.md) to read the next part of this guide.
- Case studies and examples are also available [here](probes-case-studies.md).
- Debugging and troubleshooting tips can be found [here](probes-debugging.md).
- Best practices and recommendations are outlined [here](probes-best-practices.md).

