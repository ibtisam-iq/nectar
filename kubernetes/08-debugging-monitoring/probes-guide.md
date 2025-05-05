# Kubernetes Probes: Comprehensive Guide

This document consolidates and organizes the essential concepts, configurations, and best practices for **Kubernetes Probes** (liveness, readiness, and startup). It provides a clear understanding of why probes are critical, how they function within the Pod lifecycle, and how to configure them effectively for resilient workloads.

---

## 🧠 Introduction to Pods and Probes

### Why Probes Matter
Pods in Kubernetes are **ephemeral**, meaning they are temporary entities that can crash, complete, or be deleted. Kubernetes does not inherently know if an application inside a container is healthy just because the container is running. Probes address this by enabling Kubernetes to:

- Monitor container health (`livenessProbe`).
- Determine if a container is ready to serve traffic (`readinessProbe`).
- Allow extra time for slow-starting applications (`startupProbe`).

Without probes, a container could be in a `Running` state but fail to serve requests (e.g., due to deadlocks or memory leaks), leading to service disruptions.

### Pod Lifecycle and Phases
Understanding the Pod lifecycle is critical for configuring probes effectively. The `.status.phase` field indicates a Pod’s high-level state:

| Phase       | Description |
|-------------|-------------|
| `Pending`   | Pod accepted but containers not yet started (e.g., pulling images). |
| `Running`   | Pod assigned to a node; at least one container is active. |
| `Succeeded` | All containers completed successfully and won’t restart. |
| `Failed`    | All containers exited with failure. |
| `Unknown`   | Pod state couldn’t be retrieved (e.g., node communication error). |

> **Note**: `CrashLoopBackOff` is not a phase but an event indicating repeated container crashes with exponential backoff.

### Container States
Each container within a Pod has a granular lifecycle state, visible via `kubectl describe pod <pod-name>`:

| State       | Description |
|-------------|-------------|
| `Waiting`   | Container not yet running (e.g., pulling images or applying secrets). |
| `Running`   | Container is active; any `postStart` hook has completed. |
| `Terminated`| Container has exited (success or failure), with details like exit code and reason. |

### Pod Conditions
Pod conditions are boolean checkpoints used by the Kubelet to evaluate Pod health:

| Condition                    | Description |
|------------------------------|-------------|
| `PodScheduled`               | Pod assigned to a node. |
| `Initialized`                | All init containers completed successfully. |
| `ContainersReady`            | All main containers are healthy and ready. |
| `Ready`                      | Pod is fully ready to serve traffic. |
| `PodReadyToStartContainers`  | Networking and sandbox setup complete (beta feature). |

### Container Restart Policies
The `restartPolicy` in a Pod spec dictates container restart behavior:

| Policy       | Behavior |
|--------------|----------|
| `Always`     | Always restart (default). |
| `OnFailure`  | Restart only if exit code is non-zero. |
| `Never`      | Never restart. |

> **Note**: Applies to init and app containers, not sidecars in `initContainers`.

### CrashLoopBackOff
`CrashLoopBackOff` occurs when a container repeatedly crashes, triggering exponential backoff restarts. Common causes include:

- Application bugs or misconfigurations.
- Insufficient CPU/memory.
- Failing probes.
- Missing secrets or configs.

---

## 🚦 Understanding Probes

### What is a Probe?
A **probe** is a periodic diagnostic performed by the Kubelet on a container. Probes allow Kubernetes to:

- Restart unhealthy containers (`livenessProbe`).
- Prevent traffic to unready containers (`readinessProbe`).
- Delay other probes for slow-starting apps (`startupProbe`).

Probes make containers **observable**, enabling proactive management before users notice issues.

### Probe Check Mechanisms
Probes use one of four mechanisms to check container health:

1. **exec**: Runs a command inside the container. Success if exit code is `0`.
   ```yaml
   exec:
     command:
       - cat
       - /tmp/healthy
   ```
   - **Use Case**: Check file existence or process-specific health.
   - **Warning**: Spawns a process each time, avoid in high-density clusters.

2. **httpGet**: Sends an HTTP GET request. Success if status code is `200-399`.
   ```yaml
   httpGet:
     path: /healthz
     port: 8080
   ```
   - **Use Case**: Web services with `/health` or `/ping` endpoints.

3. **tcpSocket**: Checks if a TCP port is open. Success if connection is established.
   ```yaml
   tcpSocket:
     port: 3306
   ```
   - **Use Case**: Databases or services without HTTP (e.g., MySQL, Redis).

4. **grpc**: Calls the gRPC `Check` method. Success if response is `OK`.
   ```yaml
   grpc:
     port: 50051
   ```
   - **Use Case**: gRPC-based microservices with health servers.

### Probe Outcomes
Each probe results in one of three outcomes:

- **Success**: Container passed the check.
- **Failure**: Container failed; action depends on probe type.
- **Unknown**: Check couldn’t complete (e.g., timeout); Kubelet retries.

### Types of Probes
Kubernetes supports three probe types, each with a distinct role:

1. **Liveness Probe**
   - **Purpose**: Detects if a container is alive or stuck (e.g., deadlocks).
   - **Action**: If it fails, the container is killed and restarted per `restartPolicy`.
   - **Use Case**: Restart broken apps or resolve deadlocks.
   - **Default**: Assumes success if not defined.

2. **Readiness Probe**
   - **Purpose**: Determines if a container is ready to serve traffic.
   - **Action**: If it fails, the container is removed from Service load balancer endpoints.
   - **Use Case**: Wait for database connections or during maintenance.
   - **Default**: Assumes success after initial delay.

3. **Startup Probe**
   - **Purpose**: Ensures an application has started before enabling liveness/readiness probes.
   - **Action**: Delays other probes until it succeeds, preventing premature restarts.
   - **Use Case**: Apps with long startup times (e.g., migrations, warmups).
   - **Default**: Assumes success if not defined.

---

## 🔍 Configuring Probes

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

### Key Configuration Fields
Fine-tune probe behavior using these fields:

| Field                  | Description                                      | Default |
|------------------------|--------------------------------------------------|---------|
| `initialDelaySeconds` | Delay before probe starts (seconds).            | 0       |
| `periodSeconds`       | Frequency of probe execution (seconds).         | 10      |
| `timeoutSeconds`      | Time before probe is considered failed (seconds). | 1       |
| `failureThreshold`    | Consecutive failures before action is taken.    | 3       |
| `successThreshold`    | Consecutive successes to mark probe as passed.  | 1       |

#### Example Configuration
```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 5
  failureThreshold: 12
```
- **Effect**: Allows 60 seconds (`12 × 5`) for the app to start responding to `/health`.

### How Fields Work Together
- `initialDelaySeconds` prevents premature probe failures during startup.
- `periodSeconds` balances detection speed and resource usage.
- `timeoutSeconds` accommodates slow networks or backends.
- `failureThreshold` avoids false positives from temporary issues.
- `successThreshold` ensures stability before re-adding to load balancers.

---

## 🚦 When to Use Which Probe?

| Probe Type       | Purpose                                  | Kubernetes Action                  |
|------------------|------------------------------------------|------------------------------------|
| `livenessProbe`  | Detect if container is dead or stuck     | Kill and restart container         |
| `readinessProbe` | Control traffic during boot/maintenance  | Remove from Service endpoints      |
| `startupProbe`   | Delay other probes until app starts      | Prevent premature restarts         |

## 🧪 Probe Check Mechanisms: When to Use What

| Type        | Use Case                                                     | Example                |
|-------------|--------------------------------------------------------------|------------------------|
| HTTP GET    | App exposes `/health`, `/ready`, etc.                       | Web servers, APIs      |
| TCP Socket  | Port-based readiness (e.g., DB, services with no HTTP)      | Redis, PostgreSQL      |
| Exec        | Fine-grained in-container check using shell commands        | Check file existence   |


---

## ✅ Best Practices for Probes

### General Guidelines
1. **Always Use Readiness Probes for Delayed-Start Apps**
   - Prevent traffic to apps still initializing (e.g., awaiting database connections or cache warm-up).

2. **Use Liveness Probes for Long-Running Containers**
   - Automatically restart containers in deadlock or hung states, but only if the app might not crash naturally.

3. **Separate Liveness and Readiness Probes**
   - Use distinct endpoints (e.g., `/live` vs. `/ready`) to avoid confusing signals.
   - Same probe for both may lead to unnecessary restarts.

4. **Design Lightweight Probes**
   - Use simple endpoints like `/healthz` or `/ready` that return `200 OK`.
   - Avoid external dependencies (e.g., database queries) to minimize latency and failure points.

### Configuration Best Practices
5. **Set `initialDelaySeconds` for Slow-Starting Apps**
   - Match the delay to the app’s startup time (e.g., `80s` for a 70s boot).

6. **Tune `periodSeconds`, `timeoutSeconds`, and `failureThreshold`**
   - Use `timeoutSeconds: 2` for HTTP probes to handle network variability.
   - Lower `periodSeconds` (e.g., `5s`) for faster detection, or increase (e.g., `15s`) to reduce resource usage.
   - Set `failureThreshold` to avoid false positives (e.g., `5` for flaky networks).

7. **Prefer `httpGet` or `tcpSocket` Over `exec`**
   - `exec` spawns processes, which can strain high-density clusters.

### Probe Hygiene Checklist
- ✅ Clearly separate readiness and liveness roles.
- ✅ Match delays to application startup times.
- ✅ Define `/live` and `/ready` endpoints in the application.
- ✅ Avoid slow or expensive probe logic.
- ✅ Test failure scenarios (e.g., `/crash` or `/freeze`) in staging.

### Pro Tips
- **Readiness failures** only remove the pod from traffic, not restart it.
- **Liveness failures** trigger restarts, so use cautiously to avoid unnecessary cycling.
- Test probe configurations in staging to simulate failures and ensure correct behavior.

---

## 🧪 Example: Complete Probe Configuration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: app-container
    image: my-app:latest
    livenessProbe:
      httpGet:
        path: /live
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 10
      timeoutSeconds: 2
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      timeoutSeconds: 2
      failureThreshold: 3
    startupProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 0
      periodSeconds: 5
      failureThreshold: 12
```

- **Startup Probe**: Allows 60s for the app to start.
- **Liveness Probe**: Checks `/live` every 10s, restarting after 3 failures.
- **Readiness Probe**: Checks `/ready` every 5s, removing from Service if it fails.

---

## 🧠 Summary
Probes are Kubernetes’ mechanism for ensuring application health and availability. By understanding the Pod lifecycle, container states, and probe configurations, you can design resilient workloads that:

- Automatically recover from failures (`livenessProbe`).
- Only receive traffic when ready (`readinessProbe`).
- Avoid premature restarts during startup (`startupProbe`).

Following best practices, such as using lightweight probes, tuning thresholds, and testing failure scenarios, ensures your applications remain stable and performant in production.

---

## Further Reading

- [Probes Case Studies](probes-case-studies.md)
- [Debugging and Troubleshooting](probe-debugging.md)