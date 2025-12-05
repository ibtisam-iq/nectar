# Kubernetes Jobs: Comprehensive Documentation

This documentation provides a detailed, organized, and intellectually structured explanation of Kubernetes Jobs, based on the official Kubernetes documentation. It covers the concepts step-by-step, ensuring clarity and continuity, so you can fully understand how Jobs work, their configurations, and their advanced features. The goal is to leave no questions unanswered by presenting the material in a logical progression, starting with foundational concepts and building up to advanced use cases and patterns.

---

## 1. Introduction to Kubernetes Jobs

A **Kubernetes Job** is a workload resource designed to manage **one-off tasks** that run to completion and then stop. Unlike other Kubernetes resources like Deployments or ReplicaSets, which manage long-running processes (e.g., web servers), Jobs are ideal for short-lived, batch-oriented tasks.

### Key Characteristics of a Job
- **Task Completion**: A Job creates one or more Pods to execute a task. Once the task is complete (i.e., the required number of Pods successfully terminate), the Job is considered finished.
- **Pod Management**: The Job ensures that a specified number of Pods complete successfully. If a Pod fails or is deleted (e.g., due to a node failure), the Job creates a new Pod to replace it.
- **Cleanup**: Deleting a Job removes the Pods it created. Suspending a Job deletes its active Pods until it is resumed.
- **Parallelism**: Jobs can run multiple Pods in parallel for faster task completion.
- **CronJob Extension**: For recurring tasks, Jobs can be scheduled using a **CronJob**, which creates Jobs based on a defined schedule.

### Example Use Case
A simple Job might compute a mathematical value, such as π to 2000 decimal places, using a single Pod. If the Pod fails, the Job retries until it succeeds or reaches a retry limit.

---

## 2. How Jobs Work

A Job orchestrates Pods to achieve a task. Let’s break down the mechanics of how a Job operates:

### Job Lifecycle
1. **Creation**: You define a Job using a YAML manifest, specifying the task (via a Pod template) and configuration details like the number of completions or parallelism.
2. **Pod Creation**: The Job controller creates one or more Pods based on the Job’s configuration.
3. **Execution and Tracking**: The Job tracks the Pods’ progress, counting successful completions. If a Pod fails, the Job may create a replacement Pod, depending on the retry policy.
4. **Completion**: The Job is complete when the specified number of Pods terminate successfully.
5. **Cleanup**: Pods may persist after completion for logging or debugging unless cleaned up manually or via automated mechanisms like TTL (Time-To-Live).

### Key Job Behaviors
- **Retry on Failure**: If a Pod fails (e.g., due to a crash or node reboot), the Job creates a new Pod to retry the task, up to a configurable limit (`backoffLimit`).
- **Suspension**: You can suspend a Job, which terminates its active Pods. Resuming the Job restarts the Pods.
- **Parallel Execution**: Jobs can run multiple Pods simultaneously to process tasks faster, with configurable parallelism settings.

---

## 3. Writing a Job Specification

A Job is defined in a YAML manifest with required fields: `apiVersion`, `kind`, `metadata`, and `spec`. Below is a detailed breakdown of the Job specification.

### Basic Structure
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
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

### Key Fields
1. **apiVersion and kind**:
   - `apiVersion: batch/v1`: Specifies the Kubernetes API version for Jobs.
   - `kind: Job`: Declares the resource type as a Job.

2. **metadata**:
   - `name`: A unique name for the Job, which must be a valid DNS subdomain (up to 63 characters). The Job’s name is used to name its Pods.
   - Example: `name: pi`.

3. **spec**:
   - The `spec` section defines the Job’s behavior and Pod template.
   - Required subfield: `template`, which specifies the Pod(s) the Job will create.

4. **spec.template**:
   - Defines the Pod template, identical to a Pod specification but nested without `apiVersion` or `kind`.
   - Must include:
     - **Labels**: Appropriate labels for tracking (e.g., `batch.kubernetes.io/job-name`).
     - **RestartPolicy**: Must be `Never` or `OnFailure`. `Always` is not allowed for Jobs, as Jobs manage Pod restarts.
   - Example:
     ```yaml
     template:
       spec:
         containers:
         - name: pi
           image: perl:5.34.0
           command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
         restartPolicy: Never
     ```

5. **spec.backoffLimit**:
   - Specifies the number of retries for failed Pods before marking the Job as failed. Default is 6.
   - Example: `backoffLimit: 4`.

### Job Labels
- Jobs automatically assign labels with the `batch.kubernetes.io/` prefix, such as:
  - `batch.kubernetes.io/job-name`: Matches the Job’s name.
  - `batch.kubernetes.io/controller-uid`: A unique identifier for the Job.
- These labels are used to associate Pods with the Job.

---

## 4. Running a Job

Let’s walk through running the example Job that computes π.

### Example Job Manifest
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
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

### Steps to Run
1. **Apply the Job**:
   ```bash
   kubectl apply -f job.yaml
   ```
   Output: `job.batch/pi created`.

2. **Check Job Status**:
   ```bash
   kubectl describe job pi
   ```
   Provides details like start time, completion time, and Pod statuses.

3. **View Job Details**:
   ```bash
   kubectl get job pi -o yaml
   ```
   Example output:
   ```yaml
   Name:           pi
   Namespace:      default
   Selector:       batch.kubernetes.io/controller-uid=c9948307-e56d-4b5d-8302-ae2d7b7da67c
   Parallelism:    1
   Completions:    1
   Start Time:     Mon, 02 Dec 2019 15:20:11 +0200
   Completed At:   Mon, 02 Dec 2019 15:21:16 +0200
   Pods Statuses:  0 Running / 1 Succeeded / 0 Failed
   ```

4. **List Pods**:
   ```bash
   pods=$(kubectl get pods --selector=batch.kubernetes.io/job-name=pi --output=jsonpath='{.items[*].metadata.name}')
   echo $pods
   ```
   Output: `pi-5rwd7`.

5. **View Pod Logs**:
   ```bash
   kubectl logs $pods
   ```
   Outputs the computed value of π to 2000 places.

---

## 5. Types of Jobs

Jobs can be configured to handle different types of tasks, depending on whether they run sequentially or in parallel. There are three main types:

### 1. Non-Parallel Jobs
- **Description**: Runs a single Pod to completion. If the Pod fails, a new Pod is created until it succeeds.
- **Configuration**:
  - `.spec.completions`: Unset or set to 1.
  - `.spec.parallelism`: Unset or set to 1.
- **Use Case**: A single task, like running a script or a database migration.

### 2. Parallel Jobs with Fixed Completion Count
- **Description**: Runs multiple Pods to achieve a fixed number of successful completions. Each Pod is assigned a unique index (0 to `.spec.completions-1`) if using `Indexed` completion mode.
- **Configuration**:
  - `.spec.completions`: Set to the desired number of completions.
  - `.spec.parallelism`: Specifies how many Pods can run simultaneously (optional, defaults to 1).
  - `.spec.completionMode`: Set to `Indexed` for indexed assignments or `NonIndexed` (default) for homologous completions.
- **Use Case**: Processing a fixed set of tasks, like rendering frames in a video.

### 3. Parallel Jobs with a Work Queue
- **Description**: Pods coordinate via an external work queue (e.g., a message queue). Each Pod processes items independently, and the Job completes when all items are processed.
- **Configuration**:
  - `.spec.completions`: Unset.
  - `.spec.parallelism`: Set to the desired number of concurrent Pods.
- **Use Case**: Processing a dynamic set of tasks, like sending emails from a queue.

---

## 6. Controlling Parallelism

Parallelism determines how many Pods a Job runs concurrently, controlled by the `.spec.parallelism` field.

### Key Points
- **Value**: A non-negative integer. Defaults to 1 if unset. Setting to 0 pauses the Job.
- **Actual Parallelism**: May differ from the requested value due to:
  - **Fixed Completion Count**: Parallelism is capped by the number of remaining completions.
  - **Work Queue**: No new Pods are created after a Pod succeeds.
  - **Controller Delays**: The Job controller may throttle Pod creation due to resource constraints or previous failures.
  - **Graceful Shutdown**: Terminating Pods may still be running during shutdown.

### Example
```yaml
spec:
  completions: 10
  parallelism: 3
```
This Job runs up to 3 Pods concurrently to achieve 10 completions.

---

## 7. Completion Modes

Jobs with a fixed completion count (non-null `.spec.completions`) support two completion modes, introduced in Kubernetes v1.24:

### 1. NonIndexed (Default)
- **Description**: Pods are homologous; each successful Pod counts toward the total `.spec.completions`. The Job completes when the specified number of Pods succeed.
- **Use Case**: Tasks where the order or assignment doesn’t matter.

### 2. Indexed
- **Description**: Each Pod is assigned a unique index (0 to `.spec.completions-1`). The Job completes when one Pod succeeds for each index.
- **Mechanisms for Index Access**:
  - **Annotation**: `batch.kubernetes.io/job-completion-index`.
  - **Label**: `batch.kubernetes.io/job-completion-index` (Kubernetes v1.28+, requires `PodIndexLabel` feature gate).
  - **Hostname**: Pods have hostnames like `$(job-name)-$(index)`.
  - **Environment Variable**: `JOB_COMPLETION_INDEX`.
- **Use Case**: Tasks requiring static work assignment, like distributed computing with unique indices.
- **Note**: If multiple Pods run for the same index (e.g., due to node failures), only the first successful Pod counts, and others are deleted.

---

## 8. Handling Pod and Container Failures

Failures in Pods or containers are common, and Jobs provide mechanisms to handle them robustly.

### Container Failures
- **Causes**: Non-zero exit codes, memory limit violations, etc.
- **Behavior**:
  - If `restartPolicy: OnFailure`, the container is restarted in the same Pod.
  - If `restartPolicy: Never`, the Pod is considered failed, and a new Pod is created.
- **Program Considerations**: Your application must handle restarts, avoiding issues like duplicate output or incomplete files.

### Pod Failures
- **Causes**: Node reboots, evictions, or container failures with `restartPolicy: Never`.
- **Behavior**: The Job controller creates a new Pod to replace the failed one.
- **Backoff Policy**: Each failure counts toward `.spec.backoffLimit`. Retries use an exponential backoff delay (10s, 20s, 40s, up to 6 minutes).

### Backoff Limit
- **Default**: 6 retries.
- **Calculation**:
  - Counts Pods in `Failed` phase.
  - For `restartPolicy: OnFailure`, includes container retries in `Pending` or `Running` Pods.
- **Failure**: If the limit is reached, the Job is marked as failed, and running Pods are terminated.

### Advanced Failure Handling
1. **Backoff Limit Per Index (Kubernetes v1.29, Beta)**:
   - For Indexed Jobs, set `.spec.backoffLimitPerIndex` to limit retries per index.
   - Failed indices are recorded in `.status.failedIndexes`.
   - Example:
     ```yaml
     spec:
       completions: 10
       parallelism: 3
       completionMode: Indexed
       backoffLimitPerIndex: 1
       maxFailedIndexes: 5
     ```
   - If `maxFailedIndexes` is exceeded, the Job terminates all Pods and fails.

2. **Pod Failure Policy (Kubernetes v1.31, Stable)**:
   - Define rules in `.spec.podFailurePolicy` to handle failures based on container exit codes or Pod conditions.
   - Example:
     ```yaml
     spec:
       podFailurePolicy:
         rules:
         - action: FailJob
           onExitCodes:
             containerName: main
             operator: In
             values: [42]
         - action: Ignore
           onPodConditions:
             type: DisruptionTarget
     ```
   - **Actions**:
     - `FailJob`: Marks the Job as failed.
     - `Ignore`: Excludes the failure from `backoffLimit`.
     - `Count`: Applies default backoff behavior.
     - `FailIndex`: Avoids retries for a specific index (with `backoffLimitPerIndex`).
   - **Requirements**: Requires `restartPolicy: Never`.

---

## 9. Success Policy (Kubernetes v1.31, Beta)

For Indexed Jobs, the `.spec.successPolicy` allows you to define when a Job is considered successful, rather than requiring all `.spec.completions` to succeed.

### Configuration
- **Rules**:
  - `succeededIndexes`: Specifies which indices must succeed (e.g., `0,2-3`).
  - `succeededCount`: Specifies how many indices must succeed.
  - Both can be combined for flexible criteria.
- Example:
  ```yaml
  spec:
    parallelism: 10
    completions: 10
    completionMode: Indexed
    successPolicy:
      rules:
      - succeededIndexes: 0,2-3
        succeededCount: 1
  ```
  - The Job succeeds if any of indices 0, 2, or 3 succeed.

### Behavior
- The Job controller evaluates rules in order, stopping at the first match.
- On success, the Job gets a `SuccessCriteriaMet` condition, and lingering Pods are terminated.
- If a terminating policy (e.g., `backoffLimit` or `podFailurePolicy`) is met first, it takes precedence.

---

## 10. Job Termination and Cleanup

Jobs terminate under specific conditions, and cleanup ensures resources are managed efficiently.

### Termination Conditions
- **Success**:
  - The number of succeeded Pods equals `.spec.completions`.
  - The `.spec.successPolicy` criteria are met.
  - Condition: `Complete`.
- **Failure**:
  - Pod failures exceed `.spec.backoffLimit`.
  - Runtime exceeds `.spec.activeDeadlineSeconds`.
  - Indexed Job has failed indices (`backoffLimitPerIndex` or `maxFailedIndexes`).
  - A `podFailurePolicy` rule triggers `FailJob`.
  - Condition: `Failed`.

### Active Deadline
- Set via `.spec.activeDeadlineSeconds` to limit the Job’s duration.
- Example:
  ```yaml
  spec:
    activeDeadlineSeconds: 100
  ```
- Takes precedence over `backoffLimit`. If the deadline is reached, all Pods are terminated, and the Job fails with `reason: DeadlineExceeded`.

### Cleanup
- **Manual Cleanup**: Delete the Job with `kubectl delete job <name>`, which deletes its Pods.
- **TTL Mechanism (Kubernetes v1.23, Stable)**:
  - Set `.spec.ttlSecondsAfterFinished` to delete the Job and its Pods after a specified time.
  - Example:
    ```yaml
    spec:
      ttlSecondsAfterFinished: 100
    ```
  - If set to 0, the Job is deleted immediately after completion.
- **CronJob Cleanup**: For Jobs managed by CronJobs, cleanup is handled based on the CronJob’s policy.

### Pod Termination
- The Job controller adds `FailureTarget` or `SuccessCriteriaMet` conditions to trigger Pod termination.
- Pods respect `terminationGracePeriodSeconds` during shutdown.
- In Kubernetes v1.31+, terminal conditions (`Failed` or `Complete`) are delayed until all Pods are terminated.

---

## 11. Advanced Features

### Suspending a Job (Kubernetes v1.24, Stable)
- **Purpose**: Temporarily pause a Job’s execution.
- **Configuration**: Set `.spec.suspend: true`. Resume by setting to `false`.
- **Behavior**:
  - Suspending terminates active Pods with SIGTERM.
  - Resuming resets `.status.startTime` and restarts Pods.
  - Example:
    ```yaml
    spec:
      suspend: true
    ```
  - Patch to suspend:
    ```bash
    kubectl patch job/myjob --type=strategic --patch '{"spec":{"suspend":true}}'
    ```

### Mutable Scheduling Directives (Kubernetes v1.27, Stable)
- **Purpose**: Update Pod scheduling constraints (e.g., node affinity) for suspended Jobs before they start.
- **Fields**: Node affinity, node selector, tolerations, labels, annotations, scheduling gates.
- **Use Case**: Ensure Pods run in specific zones or on specific hardware.

### Custom Pod Selector
- **Purpose**: Override the default Pod selector for special cases, like taking over Pods from an old Job.
- **Configuration**:
  - Set `.spec.manualSelector: true` and define `.spec.selector`.
  - Example:
    ```yaml
    spec:
      manualSelector: true
      selector:
        matchLabels:
          batch.kubernetes.io/controller-uid: a8f3d00d-c6d2-11e5-9f87-42010af00002
    ```
  - **Warning**: Non-unique selectors can cause conflicts with other Jobs.

### Job Tracking with Finalizers (Kubernetes v1.26, Stable)
- **Purpose**: Ensure Pods are tracked until accounted for in the Job’s status.
- **Mechanism**: Pods are created with the `batch.kubernetes.io/job-tracking` finalizer, removed only after status updates.

### Elastic Indexed Jobs (Kubernetes v1.31, Stable)
- **Purpose**: Scale Indexed Jobs by adjusting `.spec.parallelism` and `.spec.completions` together.
- **Behavior**: Scaling down removes Pods with higher indices.
- **Use Case**: Dynamic scaling for batch workloads like MPI or PyTorch.

### Delayed Pod Replacement (Kubernetes v1.29, Beta)
- **Purpose**: Control when replacement Pods are created for terminating Pods.
- **Configuration**: Set `.spec.podReplacementPolicy: Failed` to create replacements only when Pods reach the `Failed` phase.
- **Default**:
  - Without `podFailurePolicy`: `TerminatingOrFailed` (immediate replacement).
  - With `podFailurePolicy`: `Failed`.

### External Controller Delegation (Kubernetes v1.32, Beta)
- **Purpose**: Delegate Job management to a custom controller.
- **Configuration**: Set `.spec.managedBy` to a value other than `kubernetes.io/job-controller`.
- **Warning**: Ensure the external controller is installed to avoid unreconciled Jobs.

---

## 12. Job Patterns

Jobs support various patterns for processing work items, each suited to different use cases. Below is a summary of key patterns:

### 1. Queue with Pod Per Work Item
- **Description**: Each Pod processes one work item from a queue.
- **Settings**: `.spec.completions = W`, `.spec.parallelism = any`.
- **Use Case**: Sending emails from a queue.

### 2. Queue with Variable Pod Count
- **Description**: Pods process multiple items from a queue, with no fixed completion count.
- **Settings**: `.spec.completions = null`, `.spec.parallelism = any`.
- **Use Case**: Processing a dynamic number of tasks.

### 3. Indexed Job with Static Work Assignment
- **Description**: Each Pod is assigned a unique index for static task assignment.
- **Settings**: `.spec.completions = W`, `.spec.parallelism = any`, `.spec.completionMode = Indexed`.
- **Use Case**: Distributed computing with fixed roles.

### 4. Job with Pod-to-Pod Communication
- **Description**: Pods communicate via a headless Service to collaborate.
- **Settings**: `.spec.completions = W`, `.spec.parallelism = W`.
- **Use Case**: Distributed algorithms requiring coordination.

### 5. Job Template Expansion
- **Description**: Create multiple Jobs from a template, each handling one work item.
- **Settings**: `.spec.completions = 1`, `.spec.parallelism = 1`.
- **Use Case**: Running parameterized tasks.

---

## 13. Alternatives to Jobs

While Jobs are ideal for batch tasks, other Kubernetes resources may be more suitable for different scenarios:

- **Bare Pods**: Suitable for single, non-retryable tasks. Unlike Jobs, Pods are not recreated on failure.
- **ReplicationController**: Manages long-running, non-terminating Pods (e.g., web servers).
- **Custom Controller Pod**: A Job creates a Pod that acts as a controller, spawning other Pods for complex workflows (e.g., Spark).

---

## 14. Best Practices

1. **Set Appropriate RestartPolicy**: Use `Never` for debugging to preserve failed Pod logs, or `OnFailure` for container retries.
2. **Define Backoff Limits**: Set `.spec.backoffLimit` to prevent excessive retries for logical errors.
3. **Use TTL for Cleanup**: Set `.spec.ttlSecondsAfterFinished` to automatically delete finished Jobs and avoid API server clutter.
4. **Leverage Success Policy**: For Indexed Jobs, use `.spec.successPolicy` to optimize completion criteria.
5. **Monitor Job Status**: Use `kubectl describe job` and `kubectl logs` to troubleshoot issues.
6. **Test Failure Handling**: Simulate failures to ensure your application handles retries and concurrency correctly.

---

## 15. Conclusion

Kubernetes Jobs provide a powerful mechanism for running one-off, batch-oriented tasks with robust failure handling, parallelism, and cleanup options. By understanding the Job specification, types, completion modes, and advanced features like success policies and elastic scaling, you can effectively manage a wide range of workloads. The patterns and best practices outlined here ensure that you can apply Jobs to diverse use cases, from simple scripts to complex distributed computations, with confidence and clarity.

For recurring tasks, consider using **CronJobs**. For deeper API details, refer to the **Kubernetes Job API documentation**.

## Further Reading

Click [here](jobs-guide-summary.md) to read the summary of this documentation.
