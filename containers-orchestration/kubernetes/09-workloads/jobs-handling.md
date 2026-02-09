## Advanced Job Handling: Failures, Policies, and Success Criteria

### Handling Pod and Container Failures

In Kubernetes, containers and Pods can fail for multiple reasons, such as:

- Container exits with a non-zero code (e.g., software bug)
- Container is OOMKilled (e.g., memory overuse)
- Pod is evicted (e.g., node reboot, upgrade, or preemption)

Depending on the **`.spec.template.spec.restartPolicy`**, the behavior differs:

- `OnFailure`: Failed container restarts on the same Pod.
- `Never`: No restart; Pod is terminated, and Job controller may spawn a new one.

**Your application must be designed to handle re-execution**, possibly in a different Pod, especially for temporary files, locks, partial outputs, etc.

---

### Backoff Policy

To limit retries, configure **`.spec.backoffLimit`** (default: 6). Failed Pods are retried with **exponential back-off**:

```
10s → 20s → 40s … capped at 6 minutes
```

A Job fails when either:
1. Number of Pods in Failed phase >= backoffLimit
2. Pod restarts (with `OnFailure`) >= backoffLimit

> 🛠️ **Debug Tip**: Use `restartPolicy: Never` and enable persistent logging for better visibility into Job failures.

---

### Backoff Limit Per Index (Indexed Jobs)

Indexed Jobs can track failures **per index** using:

```yaml
.spec.backoffLimitPerIndex: 1
.spec.maxFailedIndexes: 5
```

Example YAML:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: job-backoff-limit-per-index-example
spec:
  completions: 10
  parallelism: 3
  completionMode: Indexed
  backoffLimitPerIndex: 1
  maxFailedIndexes: 5
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: example
        image: python
        command:
        - python3
        - -c
        - |
          import os, sys
          print("Hello world")
          if int(os.environ.get("JOB_COMPLETION_INDEX")) % 2 == 0:
            sys.exit(1)
```

In this setup:
- Even indexes fail (0,2,4,6,8)
- Max failed indexes is not exceeded
- So Job completes with a **Failed condition**

Result:
```yaml
status:
  completedIndexes: 1,3,5,7,9
  failedIndexes: 0,2,4,6,8
  succeeded: 5
  failed: 10
  conditions:
  - type: FailureTarget
    reason: FailedIndexes
    message: Job has failed indexes
  - type: Failed
    reason: FailedIndexes
    message: Job has failed indexes
```

> ✅ Use `.spec.podFailurePolicy.rules[*].action: FailIndex` to **avoid retries for permanently failing indexes**.

---

### Pod Failure Policy

You can finely control Pod failure behavior using:

```yaml
.spec.podFailurePolicy.rules
```

It allows decisions based on:
- **Exit codes**
- **Pod conditions** (e.g., DisruptionTarget)

Available actions:
- `FailJob`: Immediately fail the Job
- `Ignore`: Don’t count towards backoff limit
- `Count`: Default failure behavior
- `FailIndex`: For indexed jobs only

Example YAML:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: job-pod-failure-policy-example
spec:
  completions: 12
  parallelism: 3
  backoffLimit: 6
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: main
        image: docker.io/library/bash:5
        command: ["bash"]
        args:
        - -c
        - echo "Hello world!" && sleep 5 && exit 42
  podFailurePolicy:
    rules:
    - action: FailJob
      onExitCodes:
        containerName: main
        operator: In
        values: [42]
    - action: Ignore
      onPodConditions:
      - type: DisruptionTarget
```

> 🚨 Only Pods in `Failed` phase are evaluated by the failure policy.
> Terminating pods are **not** considered failed until they reach a terminal phase.

---

### Success Policy (Indexed Jobs)

The **`.spec.successPolicy`** defines **custom success criteria** for Indexed Jobs.

You can specify:
- `succeededIndexes`: Indexes to monitor
- `succeededCount`: How many of those indexes must succeed

Use Cases:
- Partial success (e.g., simulations)
- Leader-worker models (e.g., MPI, PyTorch)

Example YAML:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: job-success
spec:
  parallelism: 10
  completions: 10
  completionMode: Indexed
  successPolicy:
    rules:
      - succeededIndexes: 0,2-3
        succeededCount: 1
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: main
        image: busybox
        command: ["sh", "-c", "echo done"]
```

This Job will succeed once **one Pod** from the set {0, 2, 3} completes successfully.

> 🧠 **Indexed Job Feature Requirements**:
> - `completionMode: Indexed` is **required** for backoff per index and success policies.
> - `restartPolicy: Never` is required for most advanced failure handling features.

---

### Recap Table
| Feature | Field | Use Case |
|--------|-------|----------|
| Retry limits | `backoffLimit` | Retry on any pod failure, exponential delay |
| Retry per index | `backoffLimitPerIndex`, `maxFailedIndexes` | Indexed jobs - retry control for each index |
| Failure control | `podFailurePolicy` | Exit code or condition-based failure behavior |
| Partial success | `successPolicy` | Custom rule-based Job completion |

---

## Next Topic

- [Cron Job Guide](cron-job-guide.md)

