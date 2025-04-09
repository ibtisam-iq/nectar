# Probes in Kubernetes: A Deep Dive into Readiness & Liveness

This guide explores the behavior of Pods during startup, runtime issues, and container crashes using Kubernetes readiness and liveness probes. Through real-world scenarios, we analyze how traffic routing, container health checks, and probe configurations interact.

---

## Case 1: Basic Pod with No Delay

### Scenario

A single pod is exposed through a service. The container starts instantly, and traffic is served immediately.

### Behavior

- Pod is marked `Ready & Running` as soon as the container starts.
- Service routes traffic successfully without delay.

### YAML Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: webapp
    type: dev
  name: pod-with-no-delay-1
spec:
  containers:
  - name: abcd
    image: kodekloud/webapp-delayed-start
    ports:
    - containerPort: 8080
      protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: pod-with-no-delay-svc
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
    nodePort: 30090
  selector:
    type: dev
  type: NodePort
```

---

## Case 2: Delayed Container Startup Without Readiness Probe

### Scenario

Pod starts immediately, but the container has an intentional 80-second delay before it begins serving traffic.

### Problem

- Pod is marked `Ready & Running`, even though the container is not serving traffic.
- Service routes traffic to the pod too early — **requests fail**.

### Root Cause

Kubernetes, by default, assumes the container is ready unless told otherwise via a **readiness probe**.

### Solution

Introduce a readiness probe to verify if the application is ready to accept traffic.

### YAML Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: webapp
    type: prod
  name: pod-with-80s-delay
spec:
  containers:
  - name: abcd
    image: kodekloud/webapp-delayed-start
    ports:
    - containerPort: 8080
      protocol: TCP
    env:
    - name: APP_START_DELAY  # Simulates delayed application start
      value: "80"
---
apiVersion: v1
kind: Service
metadata:
  name: pod-with-80s-delay-svc
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    type: prod
  type: NodePort
```

---

## Case 3: Multiple Pods — One with Delay, No Readiness Probe

### Scenario

Two pods (one delayed) are connected to a single service.

### Problem

- Pod 1 serves traffic correctly.
- Pod 2 receives traffic **before it's ready**, causing intermittent request failures.

### Root Cause

Traffic is load-balanced across all service endpoints, including unready pods.

### YAML Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: webapp
    type: abc
  name: pod-with-no-delay-2
spec:
  containers:
  - name: abcd
    image: kodekloud/webapp-delayed-start
    ports:
    - containerPort: 8080
      protocol: TCP
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: webapp
    type: abc
  name: pod-with-80s-delay-no-readiness-probe
spec:
  containers:
  - name: abcd
    image: kodekloud/webapp-delayed-start
    ports:
    - containerPort: 8080
      protocol: TCP
    env:
    - name: APP_START_DELAY
      value: "80"
---
apiVersion: v1
kind: Service
metadata:
  name: svc-for-both-pods
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: webapp
    type: abc
  type: NodePort
```

---

## Case 4: Add Readiness Probe to Delayed Pod

### Solution

Apply a readiness probe to the delayed pod only. Kubernetes will exclude it from service endpoints until it's truly ready.

### Benefit

- No traffic is lost.
- Traffic is only routed to healthy containers.
- Seamless transition when the delayed pod becomes ready.

### YAML Manifest (relevant pod)

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: webapp
    type: abc
  name: pod-with-80s-delay-and-readiness-probe
spec:
  containers:
  - name: abcd
    image: kodekloud/webapp-delayed-start
    ports:
    - containerPort: 8080
      protocol: TCP
    env:
    - name: APP_START_DELAY
      value: "80"
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
```

---

## Case 5: Using Liveness Probe for Runtime Failure Recovery

### Scenario

An application crashes or becomes unresponsive after startup (e.g., frozen by hitting `/freeze`).

### Problem

- Container is alive but not functional.
- Kubernetes sees it as `Ready`, leading to failed traffic.

### Solution

Use a liveness probe to monitor continuous health. If it fails, Kubernetes restarts the container.

### YAML Manifest (delayed pod)

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: webapp
    type: abc
  name: pod-with-80s-delay-and-liveness-probe
spec:
  containers:
  - name: abcd
    image: kodekloud/webapp-delayed-start
    ports:
    - containerPort: 8080
      protocol: TCP
    env:
    - name: APP_START_DELAY
      value: "80"
    livenessProbe:
      httpGet:
        path: /live
        port: 8080
      initialDelaySeconds: 90   # Delay before first probe (matches container delay)
      periodSeconds: 3          # Frequency of check
```

---

## Readiness vs Liveness Probes

| Feature        | Readiness Probe                     | Liveness Probe                              |
| -------------- | ----------------------------------- | ------------------------------------------- |
| Purpose        | Determines if pod can serve traffic | Determines if container should be restarted |
| Failure Action | Removed from service endpoint       | Container is restarted                      |
| Use Case       | Delayed startup, dependency check   | Deadlock detection, freeze recovery         |

---

## Advanced Probe Examples

### HTTP-based Readiness Probe

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 2
  successThreshold: 1
```

### TCP Socket-based Probe

```yaml
readinessProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 20
```

### Exec-based Probe

```yaml
readinessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 10
  periodSeconds: 20
```

### Liveness Probe (HTTP)

```yaml
livenessProbe:
  httpGet:
    path: /live
    port: 8080
  initialDelaySeconds: 90
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 2
  successThreshold: 1
```

---

## Final Note

Both probes are essential tools in building **resilient**, **zero-downtime**, and **self-healing** applications in Kubernetes. Use readiness to ensure traffic is routed only when ready, and liveness to recover from failures or crashes.

---


