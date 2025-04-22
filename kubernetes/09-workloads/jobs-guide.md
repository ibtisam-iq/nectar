# Kubernetes Job Deep Dive

This guide provides an in-depth look at the Kubernetes `Job` resource. Jobs are used to run batch or finite-duration tasks in Kubernetes, where a specified number of Pods are created to run to completion.

---

## What is a Job in Kubernetes?

A `Job` in Kubernetes ensures that a specified number of Pods successfully terminate (complete) execution. Unlike a Deployment that runs long-lived applications, Jobs are used for short-lived, one-off tasks such as database migrations, data processing, report generation, or backups.

Jobs are part of the `batch/v1` API group.

---

```text
Usage:
  kubectl create job NAME --image=image [--from=cronjob/name] -- [COMMAND] [args...] [options]

m@ibtisam-iq:~$ kubectl create job abc --image nginx -o yaml --dry-run=client
apiVersion: batch/v1
kind: Job
metadata:
  creationTimestamp: null
  name: abc
spec:
  template:
    metadata:
      creationTimestamp: null
    spec:
      containers:
      - image: nginx
        name: abc
        resources: {}
      restartPolicy: Never
status: {}
```
---

## Job Spec Overview

A basic Job YAML manifest might look like this:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  completions: 1
  parallelism: 1
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
```

### Key Fields:

- **`completions`**: The number of times the job needs to complete successfully. Default is 1.
- **`parallelism`**: Maximum number of Pods the job can run in parallel. Controls the concurrency.
- **`template`**: Pod template that describes the work to be done. Each Pod will execute this template.
- **`restartPolicy`**: Must be `OnFailure` or `Never` for Jobs. `Always` is not permitted.

---

## How a Job Works

When a Job is created:

1. The Job controller creates one or more Pods using the specified template.
2. These Pods run the task to completion.
3. When enough Pods complete successfully (`completions`), the Job is marked as `Complete`.
4. If Pods fail, they may be retried depending on the backoff policy.

---

## Pod Failure Handling

If a Pod fails (exits with non-zero), the Job may retry it depending on:

### `restartPolicy`
- **`Never`**: Pod is not restarted.
- **`OnFailure`**: Pod is restarted by Kubernetes if it fails.

### `backoffLimit`
- Limits the number of retries for failed Pods before the entire Job is marked as `Failed`.

```yaml
spec:
  backoffLimit: 4  # default is 6
```

If a Pod fails more than `backoffLimit` times, the Job is terminated with status `Failed`.

---

## Parallelism and Completions

### Parallel Jobs
- Run multiple Pods at once.
- Example: transcoding multiple videos simultaneously.

```yaml
spec:
  parallelism: 5
  completions: 10
```

This configuration means 5 Pods can run at the same time until a total of 10 successful completions are achieved.

### Single Pod Job
```yaml
spec:
  completions: 1
  parallelism: 1
```
This runs one Pod that must complete once.

---

## Job Termination and Cleanup

### Manual Deletion
When a Job completes, the Pods it created are usually not deleted automatically. You may want to check logs first.

```bash
kubectl delete jobs/pi
kubectl delete -f job.yaml
```

Deleting the Job will cascade delete its Pods.

---

## Automatic Termination Mechanisms

### `.spec.backoffLimit`
Stops retrying failed Pods after N attempts.

### `.spec.activeDeadlineSeconds`
Sets a timeout for the whole Job. All Pods will be terminated when the Job exceeds this time.

```yaml
spec:
  activeDeadlineSeconds: 100
```

This ensures that a Job does not run forever. Even if Pods keep retrying, the entire Job fails when the deadline is hit.

### Precedence:
`activeDeadlineSeconds` > `backoffLimit`

Once the time limit is reached, Job fails regardless of backoff status.

---

## Example: Job with Timeout

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-with-timeout
spec:
  backoffLimit: 5
  activeDeadlineSeconds: 100
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
```

Note: The `activeDeadlineSeconds` should be defined in the **Job spec**, not just in the Pod template.

---

## Terminal Job Conditions

Jobs end in one of two terminal conditions:

- **Complete** → Job succeeded (condition: `type: Complete`)
- **Failed** → Job failed (condition: `type: Failed`)

### Reasons for Job Failure:
- Pod failures exceeded `backoffLimit`
- Job ran longer than `activeDeadlineSeconds`
- `podFailurePolicy` rules triggered a job failure
- For Indexed Jobs: too many failed indexes

### Reasons for Job Success:
- Number of Pods that completed = `completions`
- Success conditions defined in `.spec.successPolicy` are met

### Version Differences:
- **v1.30 and earlier**: Marks Job Complete/Failed as soon as finalizers are removed.
- **v1.31 and later**: Waits for all Pods to actually terminate before setting Complete/Failed.

You can customize this with `JobManagedBy` and `JobPodReplacementPolicy` feature gates.

---

## Job Pod Termination

Once success or failure conditions are met:
- Job controller sets `FailureTarget` or `SuccessCriteriaMet`.
- All Pods are terminated.
- Only then is the Job marked Complete or Failed.

### Practical Use:
- If you want to save compute resources, wait until `Failed` before spawning a new Job.
- If you want fast retry, act on `FailureTarget` immediately (but be careful of resource overlap).

---

## Automatic Job Cleanup

Too many completed Jobs can overload the Kubernetes API server.

### CronJob-managed Jobs
If a CronJob manages your Jobs, it can clean up old Jobs via history limits.

### TTL Controller
Set `.spec.ttlSecondsAfterFinished` to enable automatic deletion of Jobs after completion:

```yaml
spec:
  ttlSecondsAfterFinished: 100
```

After 100 seconds, Job and Pods will be deleted. If set to 0, deletion is immediate. If unset, the Job is not auto-deleted.

### Recommendation:
Always set this for one-off Jobs to prevent orphaned Pods from consuming cluster resources unnecessarily.

---

## Common Job Patterns

### 1. One Job Per Work Item
- Simple but resource-intensive for large workloads.
- Good for independent and isolated tasks.

### 2. One Job for All Work Items
- Lower overhead
- Uses Pod parallelism or work queues
- Better for scale

### 3. Pod = One Work Item
- Each Pod picks one unit of work
- Often easier to modify code this way

### 4. Pod = Multiple Work Items
- Optimized for large batches
- Requires code support to fetch from queue/bucket

### 5. Collaborative Jobs via Headless Service
- For jobs needing Pod-to-Pod communication (e.g., distributed computing)
- Use headless `Service` to let Pods discover and talk to each other

```yaml
kind: Service
spec:
  clusterIP: None
```

This lets each Pod in the Job get a stable DNS entry via the Service.

## Further Reading

- [Kubernetes Jobs: Deep Dive into `.spec` Configuration](jobs-1.md)
- [Advanced Job Handling: Failures, Policies, and Success Criteria](jobs-2.md)
- [Cron Job Guide](cron-job-guide.md)