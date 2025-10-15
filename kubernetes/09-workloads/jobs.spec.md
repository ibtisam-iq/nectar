# Kubernetes Jobs: Deep Dive into `.spec` Configuration

## 🧠 Overview
A **Kubernetes Job** ensures that a **task runs to completion**. Unlike Deployments (which keep pods running), Jobs run **one-off or batch tasks** and terminate successfully once a desired number of pods complete successfully. In this guide, we will explore the `.spec` field of a Job in **intellectual depth**, breaking down each possible option, use case, and real-world scenario.

---

## 📌 Basic Job Anatomy
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

---

## 🔍 1. `spec.template`

The `template` field is **required** and defines the **Pod template** that Kubernetes will use to spawn pods for the Job. It follows the exact structure as a regular Pod definition.

### Key Requirements:
- Must have a valid container spec
- Must set `restartPolicy` to either:
  - `Never` (recommended): Let Kubernetes handle failures by creating new Pods.
  - `OnFailure`: Container restarts within the same Pod.
  - ❌ `Always` is **not allowed** in Jobs.

### Example:
```yaml
spec:
  template:
    spec:
      containers:
      - name: task
        image: busybox
        command: ["sh", "-c", "echo Hello"]
      restartPolicy: Never
```

---

## 🔁 2. `spec.backoffLimit`

Controls how many times a Pod can **fail** before the Job is marked as **Failed**.

### Default:
```yaml
backoffLimit: 6
```

### Example Use Case:
```yaml
backoffLimit: 2
```
Try the pod 2 times. If both fail, mark the Job as failed.

---

## ⚙️ 3. `spec.parallelism`

Defines how many Pods can **run concurrently** at any moment.

### Values:
- Default: `1`
- `0`: Job is **paused**

### Example:
```yaml
parallelism: 3
```
Run 3 Pods simultaneously until the required number of completions is reached.

### Use Case Scenarios:
- **Parallel downloads** from a list
- **Batch processing** large datasets

---

## 🎯 4. `spec.completions`

The total number of **successful Pods** required to consider the Job **complete**.

### Example:
```yaml
completions: 5
```
Job finishes when **5 pods** succeed.

### Behavior Based on Parallelism:
If `parallelism: 2`, two Pods run simultaneously until 5 completions are reached.

### Default:
- If **unset**, defaults to `1`.

### Use Cases:
- Running 5 independent data extraction tasks

---

## 🧠 Job Execution Patterns

### 1. Non-parallel (Default):
```yaml
# completions and parallelism are both unset
defaults to:
completions: 1
parallelism: 1
```
Only one Pod runs and completes.

---

### 2. Fixed Completion Count:
```yaml
completions: 6
parallelism: 3
```
Run 3 Pods at once. Finish when 6 Pods succeed.

---

### 3. Work Queue Style:
```yaml
parallelism: 4
# completions is unset
```
- Each Pod **pulls work from a queue** (Redis, Kafka, etc.)
- Once **any Pod** succeeds and **all have exited**, the Job is done

---

## ⏹️ 5. `spec.suspend`

Temporarily pause the Job.

```yaml
suspend: true
```
- Active Pods are deleted
- No new Pods are created

### Use Cases:
- CI/CD pipelines that trigger Jobs, but wait for approval
- Queued tasks held until external validation

---

## 🧲 6. `spec.selector`

Defines the label selector for the pods **owned** by this Job.

### Example:
```yaml
selector:
  matchLabels:
    job-name: custom-batch
```
> ⚠️ Usually **not needed**. If misconfigured, the Job may **not detect its own Pods**.

### Use Case:
- Running multiple Jobs with custom pod labels

---

## 🧮 7. `spec.completionMode`

Specifies how the Job calculates completion.

### Types:
- `NonIndexed` (default): All Pods are equal.
- `Indexed`: Each Pod gets an **index (0 to N-1)**.

```yaml
completionMode: Indexed
```

### Indexed Mode Details:
Pods get their index via:
- Annotation: `batch.kubernetes.io/job-completion-index`
- Label: `batch.kubernetes.io/job-completion-index`
- Env Var: `JOB_COMPLETION_INDEX`
- Hostname: `<job-name>-<index>`

### Use Case:
- **Partitioned computation**
- Worker coordination using deterministic indexes

---

## 💡 Lab Example: Complex Indexed Job
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: indexed-example
spec:
  parallelism: 3
  completions: 6
  backoffLimit: 2
  completionMode: Indexed
  template:
    metadata:
      labels:
        app: partition-worker
    spec:
      containers:
      - name: compute
        image: busybox
        command: ["sh", "-c", "echo My index is $JOB_COMPLETION_INDEX"]
        env:
        - name: JOB_COMPLETION_INDEX
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
      restartPolicy: Never
```

### Use Case:
- 6 Workers each compute a **different chunk** of data (index 0–5).
- Up to 3 Pods can run simultaneously.

---

## ✅ Best Practices
- Set `restartPolicy: Never` unless container-level retries are needed.
- Use `Indexed` for shard-based processing.
- Avoid using `selector` unless advanced customization is needed.
- Use `backoffLimit` to control retry behavior.
- Observe Job status via:
```bash
kubectl get jobs
kubectl describe job <job-name>
kubectl logs jobs/<job-name>
```

## Futher Reading

- [Advanced Job Handling: Failures, Policies, and Success Criteria](jobs-2.md)
- [Cron Job Guide](cron-job-guide.md)

---

## ⚙️ UNDERSTANDING KUBERNETES JOB — ALL CRUCIAL FIELDS

### 🧩 1. `.spec.completions`

**Meaning:**
How many **successful Pods** must complete before the Job itself is marked as *complete*.

**Simple explanation:**
If you want a task to run 5 times successfully, you set `completions: 5`.

**Example:**

```yaml
spec:
  completions: 5
```

**Analogy:**
Imagine you need to bake 5 cakes 🍰 — each cake represents one successful Pod.
Once all 5 are baked, the Job is complete.

---

### 🧩 2. `.spec.parallelism`

**Meaning:**
How many Pods can run **at the same time**.

**Example:**

```yaml
spec:
  parallelism: 2
```

**Analogy:**
You have 5 cakes to bake (`completions: 5`), but only 2 ovens (`parallelism: 2`).
So only 2 Pods bake simultaneously, then the next two, and so on.

---

### 🧩 3. `.spec.completionMode`

**Meaning:**
Specifies how Kubernetes tracks completion of Pods.

Two options:

* `NonIndexed` (default)
* `Indexed`

**Example:**

```yaml
spec:
  completionMode: Indexed
```

**Explanation:**

* **NonIndexed:** Pods are *anonymous* — doesn’t matter which Pod finishes which part.
* **Indexed:** Each Pod gets a unique index (0, 1, 2, …), and K8s tracks completion of each index individually.

**Real-world analogy:**
Imagine 5 workers doing different numbered tasks.
With `Indexed`, K8s knows worker 0 finished task 0, worker 1 finished task 1, etc.

---

### 🧩 4. `.spec.backoffLimit`

**Meaning:**
How many times to **retry a failed Pod** before considering the Job failed.

**Example:**

```yaml
spec:
  backoffLimit: 4
```

**Explanation:**
If a Pod fails, K8s retries it (with exponential backoff).
After 4 retries, if it still fails → Job fails.

**Analogy:**
You let someone retry a test 4 times before marking them as failed.

---

### 🧩 5. `.spec.backoffLimitPerIndex`

**(only used with `completionMode: Indexed`)**

**Meaning:**
How many times each indexed Pod can fail before its index is marked failed.

**Example:**

```yaml
spec:
  backoffLimitPerIndex: 2
```

**Explanation:**
When each index (e.g., 0, 1, 2) fails more than 2 times → that index is marked failed.
The Job may still continue for other indexes if allowed.

---

### 🧩 6. `.spec.maxFailedIndexes`

**Meaning:**
Maximum number of *different indexes* that are allowed to fail before the Job is marked failed.

**Example:**

```yaml
spec:
  maxFailedIndexes: 3
```

**Explanation:**
In an Indexed Job of 10 Pods, if more than 3 indexes fail → Job fails.

---

### 🧩 7. `.spec.activeDeadlineSeconds`

**Meaning:**
The **total time** (in seconds) the Job is allowed to run — regardless of retries or Pods.

**Example:**

```yaml
spec:
  activeDeadlineSeconds: 600
```

**Explanation:**
After 10 minutes, K8s stops the Job even if it’s incomplete.

**Analogy:**
You tell a worker: “Finish your work in 10 minutes — no matter what, time’s up!”

---

### 🧩 8. `.spec.ttlSecondsAfterFinished`

**Meaning:**
How long to keep the Job and its Pods **after completion or failure**, before auto-deletion.

**Example:**

```yaml
spec:
  ttlSecondsAfterFinished: 60
```

**Explanation:**
After 1 minute of finishing, the Job and its Pods are cleaned up automatically.

**Analogy:**
Like auto-deleting temporary files after they finish processing.

---

### 🧩 9. `.spec.podReplacementPolicy`

**Meaning:**
Specifies **how Pods are replaced** when a retry occurs (for Indexed jobs).

**Possible values:**

* `Never` (default)
* `Failed`

**Example:**

```yaml
spec:
  podReplacementPolicy: Failed
```

**Explanation:**

* `Never`: keeps failed Pods (good for debugging).
* `Failed`: deletes failed Pods before starting new ones.

---

### 🧩 10. `.spec.selector`

**Meaning:**
Label selector to identify Pods belonging to this Job.
Usually autogenerated, but can be defined manually (rarely needed).

**Example:**

```yaml
spec:
  selector:
    matchLabels:
      app: batch-task
```

---

### 🧩 11. `JOB_COMPLETION_INDEX` (Environment Variable)

**Meaning:**
Available *inside each Pod* in an Indexed Job.
It gives the **index number** assigned to that Pod (0, 1, 2, …).

**Example:**

```yaml
spec:
  completionMode: Indexed
  completions: 3
  parallelism: 3
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo My index is $JOB_COMPLETION_INDEX"]
```

**Explanation:**
K8s automatically injects this variable into the Pod’s environment.
Useful when each Pod must process a specific part of a dataset (like partition 0, 1, 2).

**Analogy:**
Each worker has a number badge and knows which file to process.

---

## 💡 Visual Summary

| Field                     | Purpose                                       | Works With           | Analogy                            |
| ------------------------- | --------------------------------------------- | -------------------- | ---------------------------------- |
| `completions`             | Total Pods that must succeed                  | Always               | Total cakes to bake                |
| `parallelism`             | Pods that run at the same time                | Always               | Number of ovens                    |
| `completionMode`          | Tracks Pods individually or not               | Indexed / NonIndexed | Named vs anonymous workers         |
| `backoffLimit`            | Retry attempts before Job fails               | Always               | Retry attempts for test            |
| `backoffLimitPerIndex`    | Retry per indexed Pod                         | Indexed              | Each worker’s retry limit          |
| `maxFailedIndexes`        | Allowed failed indexes before overall failure | Indexed              | Tolerated failed workers           |
| `activeDeadlineSeconds`   | Total time limit for Job                      | Always               | “Finish in 10 minutes”             |
| `ttlSecondsAfterFinished` | Auto-delete after finish                      | Always               | Auto-cleanup timer                 |
| `podReplacementPolicy`    | Replace failed Pods or not                    | Indexed              | Replace failed worker or keep logs |
| `selector`                | Match Pods                                    | Always               | Identify which Pods belong         |
| `JOB_COMPLETION_INDEX`    | Pod’s index environment variable              | Indexed              | Worker number badge                |

---
