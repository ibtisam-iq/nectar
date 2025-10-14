
## 🧠 Full Example: `nginx-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment        # Name of the Deployment
  labels:
    app: nginx
spec:
  replicas: 3                   # Number of Pod replicas you want to run
  minReadySeconds: 10           # 👇 Even after Ready, wait at least 10 seconds after a Pod becomes Ready
                                # before marking it as "Available" — ensures stability
                                # The key is NOT present by-default

  progressDeadlineSeconds: 600  # 👇 Kubernetes waits up to 10 minutes (600 sec)
                                # for the Deployment to make progress (Pods becoming Ready)
                                # If rollout takes longer, it’s marked as "Failed"
                                # The key is present by-default

  revisionHistoryLimit: 10      # 👇 Keep the last 10 old ReplicaSets
                                # (so you can roll back if needed)
                                # Older ReplicaSets beyond this number are deleted automatically
                                # The key is present by-default

  selector:
    matchLabels:
      app: nginx                # 👇 Selects Pods with label "app=nginx"
                                # This MUST match the labels in the Pod template below

  strategy:                     # 👇 Defines how updates (rolling updates) happen
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1         # 👇 During update, at most 1 Pod can be unavailable
      maxSurge: 1               # 👇 During update, at most 1 extra Pod can be created (above desired count)

  template:                     # 👇 Template for Pods that will be created
    metadata:
      labels:
        app: nginx              # 👇 Must match the selector above
    spec:
      containers:
      - name: nginx
        image: nginx:latest     # 👇 Container image to run
        ports:
        - containerPort: 80     # 👇 Exposes port 80 in each Pod
        readinessProbe:         # 👇 Optional: ensures Pod is fully ready before traffic
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

---

### 💡 How These Fields Work *Together* During a Rollout

Let’s walk through this step-by-step:

1. **Deployment starts an update**
   K8s begins replacing old Pods with new ones.

2. **`progressDeadlineSeconds` timer starts**
   K8s expects new Pods to become Ready within this deadline (e.g., 600s).
   If they don’t → rollout is marked as **Failed**.

3. **Each new Pod becomes Ready**
   The Pod passes its readiness probe (if defined).

4. **`minReadySeconds` applies**
   Even after Ready, K8s waits 10 more seconds before counting it as *Available* — to confirm stability.

5. **Old ReplicaSets** are trimmed
   Once rollout is complete, K8s keeps only the last `revisionHistoryLimit` (5 here).
   The 6th oldest version is deleted to save cluster resources.

---

### ⚙️ TL;DR (Quick Summary)

| Field                     | Function                                                                    | Default        | Why You Might Change It                              |
| ------------------------- | --------------------------------------------------------------------------- | -------------- | ---------------------------------------------------- |
| `minReadySeconds`         | Ensures Pods stay stable for a few seconds before marking them as available | `0`            | Add delay to catch flaky Pods                        |
| `progressDeadlineSeconds` | Time before rollout is considered failed                                    | `600` (10 min) | Increase if Pods take longer to initialize           |
| `revisionHistoryLimit`    | How many old ReplicaSets (versions) to keep                                 | `10`           | Lower to save resources, or raise for safer rollback |

---

Excellent observation, sweetheart 💡 You’ve hit on a subtle detail about **`--record`** and the **`CHANGE-CAUSE`** field in rollout history.

### 🔎 Why you see `<none>` in `CHANGE-CAUSE`

```bash
k rollout history deployment abc
deployment.apps/abc 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

* By default, Kubernetes doesn’t log *why* a change happened.
* The `CHANGE-CAUSE` column is filled only if you explicitly add the annotation **`kubernetes.io/change-cause`**.
* `kubectl` used to support `--record` for this, but the flag is now **deprecated**.

### ✅ Current best practice

Instead of `--record`, you should use:

```bash
kubectl annotate deployment abc kubernetes.io/change-cause="Updated to nginx:1.29.1"
```

Then check:

```bash
kubectl rollout history deployment abc
```

You’ll see:

```
REVISION  CHANGE-CAUSE
1         <none>
2         Updated to nginx:1.29.1
```

### 🕐 When should you use it (with respect to a Deployment)?

You add a `change-cause` when you want **human-readable documentation of why you updated a Deployment**.
For example:

* When you **create** the Deployment:

  ```bash
  kubectl create deployment abc --image=nginx \
    --record  # (old way)
  ```

  or:

  ```bash
  kubectl annotate deployment abc kubernetes.io/change-cause="Initial deployment with nginx:latest"
  ```

* When you **update the image**:

  ```bash
  kubectl set image deploy abc nginx=nginx:1.29.1 \
    --record  # (old way)
  ```

  or:

  ```bash
  kubectl annotate deployment abc kubernetes.io/change-cause="Upgraded to nginx:1.29.1"
  ```

### ⚠️ Key point

* `--record` is deprecated, but you **can still use it in CKA exam labs** (it will work).
* In production or modern clusters, use:

  ```bash
  kubectl annotate deployment <name> kubernetes.io/change-cause="Your message"
  ```

👉 So, to answer you directly:

* Yes, without `--record` or manual annotation, `CHANGE-CAUSE` will always be `<none>`.
* You should use it **at creation or update time** to track the reason for changes.

---

Exactly ❤️ you’ve just confirmed it yourself — the **`--record` flag has been removed** from `kubectl` in newer Kubernetes versions.

### 🔎 What happened

* In **older versions** (≤1.18), `--record` was valid and would automatically add the annotation `kubernetes.io/change-cause`.
* In **newer versions** (>=1.19+), it was first **deprecated**, and in your cluster it looks like it’s been **completely removed**.
  That’s why you see:

  ```
  error: unknown flag: --record
  ```

### ✅ Modern replacement

Now, if you want to track why a change happened, you need to **manually add an annotation** with `kubectl annotate`.

For example:

```bash
kubectl create deployment abc2 --image=nginx
kubectl annotate deployment abc2 kubernetes.io/change-cause="Initial deployment with nginx"
```

If you update later:

```bash
kubectl set image deployment abc2 nginx=nginx:1.29.1
kubectl annotate deployment abc2 kubernetes.io/change-cause="Upgraded to nginx:1.29.1"
```

Then:

```bash
kubectl rollout history deployment abc2
```

Will show:

```
REVISION  CHANGE-CAUSE
1         Initial deployment with nginx
2         Upgraded to nginx:1.29.1
```

### 🕐 When to add `change-cause`

* **When you create** a Deployment → to document the initial purpose.
* **When you update** it (image, replicas, etc.) → to document why the change was made.
* This helps a lot during **rollbacks** because you can pick the right revision by reading the `CHANGE-CAUSE`.

⚡ So the takeaway:
👉 `--record` is **gone** in modern clusters.
👉 Use `kubectl annotate … kubernetes.io/change-cause="..."` instead.

---

```bash
controlplane ~ ➜  k create deploy abc --image nginx -r 3
deployment.apps/abc created

controlplane ~ ➜  k set image deploy abc nginx=nginx:1.29.1 
deployment.apps/abc image updated

controlplane ~ ➜  k rollout status deployment abc
deployment "abc" successfully rolled out

controlplane ~ ➜  k rollout history deployment abc
deployment.apps/abc 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>


controlplane ~ ➜  k set image deploy abc nginx=nginx:1.29.1 --revision
error: unknown flag: --revision
See 'kubectl set image --help' for usage.

controlplane ~ ✖ k set image deploy abc nginx=nginx:1.29.1 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/abc image updated

controlplane ~ ➜  k rollout history deployment abc
deployment.apps/abc 
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deploy abc nginx=nginx:1.29.1 --record=true


controlplane ~ ➜  kubectl annotate deployment abc kubernetes.io/change-cause="Upgraded to nginx:1.29.1"
deployment.apps/abc annotated

controlplane ~ ➜  k rollout history deployment abc
deployment.apps/abc 
REVISION  CHANGE-CAUSE
1         <none>
2         Upgraded to nginx:1.29.1


controlplane ~ ➜  k set image deploy abc nginx=nginx:1.29.0 --record
Flag --record has been deprecated, --record will be removed in the future
deployment.apps/abc image updated

controlplane ~ ➜  k rollout undo deployment abc --to-revision ^C

controlplane ~ ✖ k rollout history deployment abc
deployment.apps/abc 
REVISION  CHANGE-CAUSE
1         <none>
2         Upgraded to nginx:1.29.1
3         kubectl set image deploy abc nginx=nginx:1.29.0 --record=true


controlplane ~ ➜  k rollout undo deployment abc --to-revision=2
deployment.apps/abc rolled back

controlplane ~ ➜  k rollout history deployment abc
deployment.apps/abc 
REVISION  CHANGE-CAUSE
1         <none>
3         kubectl set image deploy abc nginx=nginx:1.29.0 --record=true
4         Upgraded to nginx:1.29.1


controlplane ~ ➜  k describe deploy abc | grep -i image
    Image:         nginx:1.29.1

controlplane ~ ➜  k create deploy abc2 --image nginx --record
error: unknown flag: --record
See 'kubectl create deployment --help' for usage.

controlplane ~ ✖  
```
