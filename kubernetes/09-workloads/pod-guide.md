# 📚 Complete Kubernetes Pod Guide

# 1. What is a Pod?

- A **Pod** is the **smallest deployable unit** in Kubernetes.
- A Pod is **a wrapper around one or more containers** that share:
  - **Networking** (same IP address and ports)
  - **Storage** (via shared/mounted volumes)
  - **Metadata** (labels, annotations)
  
✅ **Real World Analogy:**  
Imagine a **pod** like a **shared room** where different **containers (people)** can live together, share the same **address (IP)** and **storage shelves (volumes)**.

---
# 2. Pod Lifecycle

| Phase | Meaning |
|:------|:--------|
| Pending | Pod accepted, but containers not started yet |
| Running | All containers started and healthy |
| Succeeded | All containers completed successfully (exit 0) |
| Failed | Containers failed (non-zero exit code) |
| Unknown | Node failure, can't get Pod status |

---

# 3. Pod Structure Overview

✅ A Pod YAML usually has **four parts**:

| Section | Purpose |
|:--------|:--------|
| `apiVersion` | API group/version |
| `kind` | Always `Pod` here |
| `metadata` | name, namespace, labels, annotations, uid, resourceVersion, generation, creationTimestamp,  deletionTimestamp, deletionGracePeriodSeconds etc. |
| `spec` | Pod specification (containers, volumes, etc.) |

---

# 4. Pod YAML — Basic Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod            # mandatory
  labels:
    app: myapp
spec:
  containers:
  - name: mycontainer 
    image: nginx         # mandatory
```

✅ Minimal viable Pod!  
Only **name** and **containers/image** are mandatory.

---

# 5. Deep Dive: Important Pod Fields

### 5.1 Pod-Level Fields

| Field | Purpose |
|:------|:--------|
| `restartPolicy` | How containers restart (Always, OnFailure, Never) |
| `nodeSelector` | Select Node with matching labels |
| `nodeName` | Select a Node directly with its name |
| `affinity` | Advanced scheduling rules (preferred/required) |
| `tolerations` | Allow Pod to run on tainted nodes |
| `volumes` | Define shared volumes |
| `securityContext` | Pod-wide security (e.g., fsGroup) |
| `serviceAccountName` | Attach a Service Account for permissions |
| `hostNetwork` | Share node's network namespace (true/false) |
| `dnsPolicy` | Set how DNS is handled |
| `priorityClassName` |  |
| `schedularName` |  |
| `imagePullSecrets` |  |
| `enableServiceLinks` | Indicates whether information about services should be injected into pod's environment variables, matching the syntax of Docker links. Optional: Defaults to true.  |
---

### 5.2 Container-Level Fields

Inside `containers:`

| Field | Purpose |
|:------|:--------|
| `name` | Name of the container |
| `image` | Docker image name |
| `imagePullPolicy` | 
| `ports` | Exposed ports |
| `env` | Manually set environment variables |
| `envFrom` | Import env vars from ConfigMap/Secret |
| `command` | Override ENTRYPOINT |
| `args` | Override CMD |
| `volumeMounts` | Mount volumes inside container |
| `resources` | Requests and Limits for CPU/Memory |
| `securityContext` | Container-specific security (e.g., runAsUser) |
| `readinessProbe` | Checks app is ready |
| `livenessProbe` | Checks app is alive |

---

# 6. Pod Networking

✅ All containers inside a Pod share:
- **Same IP address**
- **Same port space**

✅ Communication inside Pod = **localhost**

✅ To talk **outside Pod**, use **Services** (ClusterIP, NodePort, LoadBalancer).

---

# 7. Multiple Containers in a Pod

✅ Containers **inside the same Pod**:
- Share Volumes
- Share Network
- Useful for helper tasks (sidecars)

Example YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multicontainer-pod
spec:
  containers:
  - name: app
    image: nginx
  - name: helper
    image: busybox
    command: ["sleep", "3600"]
```

✅ **Real-world example:**  
- nginx + busybox sidecar
- app + log collector
- database + backup agent

---

# 8. Volume Usage Inside Pod

Volumes are **declared at Pod level** and **mounted inside containers**.

Example:

```yaml
spec:
  volumes:
  - name: data-volume
    emptyDir: {}
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data-volume
      mountPath: /data
```

---
# 9. Pod Restart Policies

| Policy | Behavior |
|:-------|:---------|
| `Always` | Restart containers whenever they die (default) |
| `OnFailure` | Restart only if exit code ≠ 0 |
| `Never` | Never restart |

🚨 Important: **RestartPolicy applies to the whole Pod, not each container separately.**

---

# 10. Probes (Health Checks)

✅ **Readiness Probe** = "Is app ready to accept traffic?"  
✅ **Liveness Probe** = "Is app still alive?"

Example:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
livenessProbe:
  tcpSocket:
    port: 80
```

✅ If liveness probe fails, container is **killed** and **restarted**.

---

# 11. Pod Scheduling

- `nodeSelector`: simple scheduling by node labels
- `affinity` / `antiAffinity`: advanced scheduling
- `tolerations`: allow scheduling on tainted nodes

---

# 12. Pod SecurityContext

Pod and Container can both define **securityContext**:

```yaml
securityContext:
  runAsUser: 1000
  fsGroup: 2000
```

- `runAsUser` → container runs as specific user.
- `fsGroup` → shared ownership for volumes.

--- 

# 13. Pod Management with kubectl

| Command | Purpose |
|:--------|:--------|
| `kubectl run` | Quickly create a Pod (for testing) |
| `kubectl create -f pod.yaml` | Create Pod from YAML |
| `kubectl get pods` | List Pods |
| `kubectl describe pod podname` | Detailed info |
| `kubectl delete pod podname` | Delete Pod |

---

# 14. Common Mistakes in Exam

| Mistake | How to avoid |
|:--------|:-------------|
| Misspelling `containers:` | Always align list items correctly |
| Missing `image:` in container | Every container **must** have `image:` |
| Wrong indentation under `volumeMounts:` | YAML is space-sensitive! |
| Wrong probe structure | Always check the probe fields (httpGet, tcpSocket, initialDelaySeconds, etc.) |
| Forgetting `restartPolicy` when needed | Especially for Jobs/CronJobs |

---

# 📌 Final CKA Fast Cram

✅ Pod = one or more containers sharing network and volumes.  
✅ At **Pod level**, define things like restartPolicy, nodeSelector, affinity, tolerations, volumes.  
✅ At **Container level**, define image, ports, env, command, args, probes, volumeMounts, securityContext.

✅ Best speed = muscle memory of writing Pods manually!  

---

# 📄 Quick Reference Diagram

```
Pod
├── Metadata
├── Spec
│   ├── Containers
│   │   ├── Name
│   │   ├── Image
│   │   ├── Ports
│   │   ├── Env
│   │   ├── Command/Args
│   │   ├── VolumeMounts
│   │   ├── Probes
│   ├── Volumes
│   ├── RestartPolicy
│   ├── NodeSelector
│   ├── Affinity
│   ├── Tolerations
│   ├── ServiceAccountName
```

---

# 🧠 Full Pod YAML Cram Sheet with Comments


```bash
apiVersion: v1
kind: Pod
metadata:
  name: mypod                # Pod name (metadata level)
  labels:
    app: myapp                # Labels (optional, but often used)
spec:                         # --> POD-LEVEL SPEC STARTS HERE
  restartPolicy: Always       # Pod-level (Always, OnFailure, Never)
  nodeSelector:               # Pod-level (simple scheduling)
    disktype: ssd
  tolerations:                # Pod-level (to match node taints)
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "NoSchedule"
  affinity:                   # Pod-level (advanced scheduling)
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - node1
  serviceAccountName: myserviceaccount  # Pod-level (IAM link)
  hostNetwork: false           # Pod-level (true/false, shares Node's network?)
  dnsPolicy: ClusterFirst      # Pod-level (DNS rules)
  securityContext:             # Pod-level security (applies to all containers)
    fsGroup: 2000

  volumes:                     # Pod-level volumes
  - name: myvolume
    emptyDir: {}
  imagePullSecrets:            # Pod-level (secret for private registry)
    - ibtisam-secret
  containers:                  # --> CONTAINER LIST STARTS HERE
  - name: mycontainer          # Container-level (required)
    image: nginx:latest        # Container-level (required)
    imagePullPolicy: Always    # Container-level (Always, IfNotPresent, Never)
    ports:                     # Container-level (optional)
    - containerPort: 80

    env:                        # Container-level (manual env vars)
    - name: ENVIRONMENT
      value: production
    - name: MY_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName

    envFrom:                    # Container-level (import from ConfigMap/Secret)
    - configMapRef:
        name: my-config

    command: ["nginx"]           # Container-level (overrides default ENTRYPOINT)
    args: ["-g", "daemon off;"]  # Container-level (overrides default CMD)

    volumeMounts:                # Container-level (mount volume into path)
    - name: myvolume
      mountPath: /usr/share/nginx/html

    resources:                   # Container-level (CPU/memory requests and limits)
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"

    resizePolicy:
    - resourceName: cpu
      restartPolicy: NotRequired # Default, but explicit here
    - resourceName: memory
      restartPolicy: RestartContainer

    securityContext:             # Container-level (individual container security)
      runAsUser: 1000

    readinessProbe:              # Container-level (ready to serve traffic?)
      httpGet:
        path: /
        port: 80

    livenessProbe:               # Container-level (still alive?)
      tcpSocket:
        port: 80
```
