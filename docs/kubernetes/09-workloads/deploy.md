
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

Perfect ❤️ Sweetheart Ibtisam — here you go:
Below are the **full answers, YAML snippets, and clear reasoning** for every advanced Deployment question.
Each one is explained like an instructor would do in a real CKA prep lab — so you’ll never again be confused by tricky English wording. 🧠✨

### 🧩 Q1 — Hidden Timeout

> Make Kubernetes mark rollout as failed if not completed within 12 minutes.

✅ **Answer:**

```yaml
spec:
  progressDeadlineSeconds: 720
```

🧠 **Reasoning:**
12 minutes × 60 = 720 seconds.
This sets the maximum time Kubernetes waits for rollout progress before showing `ProgressDeadlineExceeded`.

### 🧩 Q2 — Instant Traffic Problem

> Pods get traffic too quickly; must stay stable for 25 seconds before “Available.”

✅ **Answer:**

```yaml
spec:
  minReadySeconds: 25
```

🧠 **Reasoning:**
`minReadySeconds` enforces that after a Pod becomes Ready, Kubernetes waits 25 seconds before considering it “Available.”
This prevents traffic from hitting unstable Pods.

### 🧩 Q3 — Rollback Policy

> Keep only the last 4 old versions for rollback.

✅ **Answer:**

```yaml
spec:
  revisionHistoryLimit: 4
```

🧠 **Reasoning:**
Kubernetes stores old ReplicaSets for rollback. This setting keeps only the last 4, deleting older ones automatically.

### 🧩 Q4 — Aggressive Rollout

> Allow 2 Pods unavailable, 1 extra Pod during rollout.

✅ **Answer:**

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 2
      maxSurge: 1
```

🧠 **Reasoning:**

* `maxUnavailable: 2` → Up to 2 Pods can go down during update.
* `maxSurge: 1` → Only 1 additional Pod (beyond desired replicas) may be created.

### 🧩 Q5 — Time Calculation Trap

>

```yaml
progressDeadlineSeconds: 600
minReadySeconds: 15
```

Pods take 5 min to become Ready + 20 sec stable.

✅ **Answer:**
The rollout will **succeed**, because:

* Total = 5 min 20 sec = 320 sec < 600 sec.
* Rollout completes before hitting the progress deadline.

🧠 **Reasoning:**
`progressDeadlineSeconds` measures total time since rollout start.
As long as total progress < 600 seconds, it succeeds.

### 🧩 Q6 — Clean History

> Keep **no previous versions** (delete all old ReplicaSets).

✅ **Answer:**

```yaml
spec:
  revisionHistoryLimit: 0
```

🧠 **Reasoning:**
Setting it to `0` means Kubernetes **will not retain** any previous ReplicaSets — you lose rollback capability but save resources.

### 🧩 Q7 — Confusing Wording

> “Become Available only after Pods stay Ready for a while; fail rollout if not achieved in 10 minutes.”

✅ **Answer:**

```yaml
spec:
  minReadySeconds: <some delay>   # e.g. 10 or 20 seconds
  progressDeadlineSeconds: 600
```

🧠 **Reasoning:**
Two controls are needed:

* `minReadySeconds` → delay before marking available,
* `progressDeadlineSeconds` → timeout if rollout not finished in 10 minutes.

### 🧩 Q8 — RollingUpdate Mix

> Must follow all four conditions (availability, surge, stability, rollout timeout).

✅ **Answer:**

```yaml
spec:
  minReadySeconds: 10
  progressDeadlineSeconds: 480
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 2
```

🧠 **Reasoning:**
This combines all behaviors:

* `minReadySeconds` = stability delay,
* `progressDeadlineSeconds` = fail after 8 min (480 sec),
* `maxUnavailable` + `maxSurge` = control update speed.

### 🧩 Q9 — Behavior Understanding

> `revisionHistoryLimit: 0` and 5 rollouts later, what happens?

✅ **Answer:**
You’ll only see **the active ReplicaSet** — all previous ones are deleted.

```bash
kubectl get rs
```

Will show **just 1 ReplicaSet** (the current one).

🧠 **Reasoning:**
With `0`, Kubernetes deletes all old ReplicaSets immediately after new ones are created — no rollback history.

### 🧩 Q10 — Real-World Scenario

> Extend rollout timeout to 20 min; Pods stable for 10 sec before available.

✅ **Answer:**

```yaml
spec:
  minReadySeconds: 10
  progressDeadlineSeconds: 1200
```

🧠 **Reasoning:**
20 min × 60 = 1200 seconds.
You’re combining rollout timeout (`progressDeadlineSeconds`) and Pod stability delay (`minReadySeconds`).

## 💡 Quick Summary Table (for Flash Memory)

| Field                     | Controls                            | Example                        | Exam Clue Phrase                    |
| ------------------------- | ----------------------------------- | ------------------------------ | ----------------------------------- |
| `minReadySeconds`         | Delay before marking Pod available  | `minReadySeconds: 10`          | “Wait before Pod becomes available” |
| `progressDeadlineSeconds` | Max rollout time                    | `progressDeadlineSeconds: 600` | “Fail rollout if no progress”       |
| `revisionHistoryLimit`    | Number of old ReplicaSets to keep   | `revisionHistoryLimit: 5`      | “Keep last X versions”              |
| `maxUnavailable`          | Pods that can go down during update | `maxUnavailable: 1`            | “At most 1 Pod unavailable”         |
| `maxSurge`                | Extra Pods during update            | `maxSurge: 2`                  | “Allow 2 extra Pods during rollout” |

### ❤️ Bonus: Mental Shortcuts for the Exam

| Question Type                         | Your Brain Should Think Instantly |
| ------------------------------------- | --------------------------------- |
| “wait before available”               | → `minReadySeconds`               |
| “timeout before fail”                 | → `progressDeadlineSeconds`       |
| “rollback versions / old ReplicaSets” | → `revisionHistoryLimit`          |
| “faster or safer rollout”             | → `strategy.rollingUpdate`        |
| “delete all old versions”             | → `revisionHistoryLimit: 0`       |

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
