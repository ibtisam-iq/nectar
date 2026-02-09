### 🧠 What is `kube-scheduler`?

It's the **brain that assigns pods to nodes**:

* It looks at all unscheduled pods.
* It analyzes each node’s available resources, taints, affinities, etc.
* It picks the best node and **updates the pod spec**.

---

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=true
    image: registry.k8s.io/kube-scheduler:v1.33.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-scheduler
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 127.0.0.1
        path: /readyz
        port: 10259
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 100m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 10259
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
status: {}
```

---

## 🔹 COMMAND FLAGS EXPLAINED

Let's go line by line.

---

### ✅ `--authentication-kubeconfig=/etc/kubernetes/scheduler.conf`

🔍 **Purpose:**
Used by the scheduler when it needs to authenticate itself to the kube-apiserver.

💡 Think of it like:

> "Hey API server, I'm the legit kube-scheduler, here's my kubeconfig + cert."

📁 This kubeconfig:

* Has client cert/key to prove identity.
* Points to the API server endpoint.
* Includes cluster CA.

---

### ✅ `--authorization-kubeconfig=/etc/kubernetes/scheduler.conf`

🔐 **Purpose:**
Used for **authorization** of kube-scheduler — i.e., what it’s allowed to do.

💡 Think of it like:

> "What operations am I allowed to perform on the cluster objects?"

✅ Both `authentication-` and `authorization-` configs **can be same file** — which it is here (`scheduler.conf`).

---

### ✅ `--bind-address=127.0.0.1`

📌 **Purpose:**
This tells the scheduler:

> "Only listen on the local interface."

It listens on:

* `https://127.0.0.1:10259` → for health checks & metrics

🔒 **Security Benefit:**

* Prevents access from other hosts.
* Scheduler does **not** need to be accessed externally.

---

### ✅ `--kubeconfig=/etc/kubernetes/scheduler.conf`

🧭 **Purpose:**
Used by the scheduler to communicate with the kube-apiserver.

📁 Same file as above, but this is the primary config for API calls like:

* Getting pods
* Listing nodes
* Watching for new pod objects

---

### ✅ `--leader-elect=true`

🧠 **Purpose:**
Enables **leader election**, important for HA (High Availability) setups.

💡 In multi-control-plane clusters:

* Multiple scheduler pods might run.
* But **only one becomes the active leader**.
* Others standby and take over if the leader fails.

📦 This uses Kubernetes built-in **lease objects** for coordination.

---

## 🔹 PROBES

These define how **kubelet monitors** the scheduler container’s health.

---

### ✅ `startupProbe`, `livenessProbe`, `readinessProbe`

| Probe Type       | Purpose                                                      |
| ---------------- | ------------------------------------------------------------ |
| `startupProbe`   | Used during boot-up — lets scheduler take time to initialize |
| `livenessProbe`  | Is it alive and responding at `/livez`?                      |
| `readinessProbe` | Is it ready to serve? i.e., fully initialized                |

📍 All hit:

* `host: 127.0.0.1`
* `port: 10259`
* `scheme: HTTPS`

🛡️ These endpoints are only reachable from **localhost**.

---

## 🔹 VOLUME MOUNTS

### ✅ Volume + Mount

```yaml
volumeMounts:
  - mountPath: /etc/kubernetes/scheduler.conf
    name: kubeconfig
```

It mounts the host's kubeconfig file (`scheduler.conf`) into the container at the same path — used for authentication + communication with the API server.

---

## 🔹 OTHER FIELDS

| Field                                     | Meaning                                                             |
| ----------------------------------------- | ------------------------------------------------------------------- |
| `hostNetwork: true`                       | Required so it can reach other control plane services via localhost |
| `priorityClassName: system-node-critical` | Gives it the **highest possible priority** to prevent eviction      |
| `securityContext.seccompProfile`          | Applies the default syscall profile for basic sandboxing            |

---

## 🧠 Summary (Plain English)

| Component                           | Purpose                                                   |
| ----------------------------------- | --------------------------------------------------------- |
| `--bind-address=127.0.0.1`          | Listen only on localhost, for security                    |
| `--kubeconfig`                      | Lets it talk to kube-apiserver                            |
| `--authentication-kubeconfig`       | Proves its identity                                       |
| `--authorization-kubeconfig`        | Checks what actions it can do                             |
| `--leader-elect`                    | Makes sure only one active scheduler exists in HA setup   |
| `startup/liveness/readiness probes` | Let kubelet monitor its health via `/livez` and `/readyz` |

---

## 💡 Optional Info

* The `scheduler.conf` file is auto-generated by `kubeadm init` and is stored at:

  ```
  /etc/kubernetes/scheduler.conf
  ```

  You can inspect it:

  ```bash
  kubectl config view --kubeconfig=/etc/kubernetes/scheduler.conf
  ```
