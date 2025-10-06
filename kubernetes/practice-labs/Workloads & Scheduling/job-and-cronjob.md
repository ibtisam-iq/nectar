
* `* * * * *` → **every minute** (runs 60 times in an hour).
* `*/1 * * * *` → **every minute** (runs 60 times in an hour). ## more accurate
* `*/30 * * * *` → **every 30 minute** (runs 2 times in an hour).
* `0 * * * *` → **every hour at minute 0** (runs once per hour, exactly on the hour).

### 🔹 `0 0 * * 0`

* First `0` → **minute 0**
* Second `0` → **hour 0** (midnight)
* `*` → any day of month
* `*` → any month
* Last `0` → **Sunday** (in cron, Sunday = 0 or 7)

✅ This means: **run once, exactly at 00:00 (midnight) on Sunday**.

### 🔹 `* 0 * * 0`

* First `*` → **every minute** (0–59)
* Second `0` → **hour 0** (midnight)
* Last `0` → Sunday

❌ This means: **run every minute between 00:00 and 00:59 on Sunday** (so 60 times in that hour).

👉 That’s why `0 0 * * 0` is the correct one for **“every Sunday at midnight”**.

---

## Q1

`cka-pod` pod exposed internally within the service name `cka-service` and for cka-pod monitor(access through svc) purpose deployed `cka-cronjob` cronjob that run `every minute`. Now `cka-cronjob` cronjob not working as expected, fix that issue.

```bash
controlplane:~$ k get cj
NAME          SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cka-cronjob   * * * * *   <none>     False     1        5s              56s
controlplane:~$ k get cj
NAME          SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cka-cronjob   * * * * *   <none>     False     1        37s             88s
controlplane:~$ k get cj
NAME          SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cka-cronjob   * * * * *   <none>     False     1        55s             106s
controlplane:~$ k get po
NAME                         READY   STATUS             RESTARTS      AGE
cka-cronjob-29272464-8hvj8   0/1     CrashLoopBackOff   4 (46s ago)   2m18s
cka-cronjob-29272465-97fqf   0/1     CrashLoopBackOff   3 (29s ago)   78s
cka-cronjob-29272466-d89vl   0/1     CrashLoopBackOff   1 (15s ago)   18s

controlplane:~$ k describe pod cka-cronjob-29272465-97fqf 
Name:             cka-cronjob-29272465-97fqf
Events:
  Type     Reason     Age                   From               Message
  ----     ------     ----                  ----               -------
  Normal   Started    78s (x5 over 2m48s)   kubelet            Started container curl-container
  Warning  BackOff    12s (x13 over 2m46s)  kubelet            Back-off restarting failed container curl-container in pod cka-cronjob-29272465-97fqf_default(60ee7211-185e-498b-9bc1-0d714d8dc353)
controlplane:~$ k logs cka-cronjob-29272465-97fqf
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (6) Could not resolve host: cka-pod # wrong host name

controlplane:~$ k edit cj cka-cronjob 
cronjob.batch/cka-cronjob edited

controlplane:~$ k get -o yaml cj cka-cronjob 
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cka-cronjob
          - command:
            - curl
            - cka-pod                      # change it, the host name is cka-service, not cka-pod
            image: curlimages/curl:latest

controlplane:~$ k run test --image curlimages/curl:latest -it -- sh
If you don't see a command prompt, try pressing enter.
~ $ curl cka-service
curl: (7) Failed to connect to cka-service port 80 after 0 ms: Could not connect to server # it's pinging on port 80 mentioned in svc, but no response
~ $ curl cka-service:80
curl: (7) Failed to connect to cka-service port 80 after 0 ms: Could not connect to server
~ $ curl cka-pod
curl: (6) Could not resolve host: cka-pod
~ $ curl cka-service                                # k label po cka-pod app=cka-pod fired from Tab2
<!DOCTYPE html>
<title>Welcome to nginx!</title>
<p><em>Thank you for using nginx.</em></p>
~ $ 


controlplane:~$ k describe po cka-pod 
Name:             cka-pod
    Image:          nginx:latest
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Thu, 28 Aug 2025 02:23:18 +0000
    Ready:          True
    Restart Count:  0
   
controlplane:~$ k describe svc cka-service 
Name:                     cka-service

Selector:                 app=cka-pod
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.107.195.27
IPs:                      10.107.195.27
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                                                    # culprit
controlplane:~$ k label po cka-pod app=cka-pod
pod/cka-pod labeled

controlplane:~$ k get cj cka-cronjob 
NAME          SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cka-cronjob   * * * * *   <none>     False     0        20s             35m
controlplane:~$ k get po
NAME                         READY   STATUS      RESTARTS   AGE
cka-cronjob-29272496-pfcmd   0/1     Completed   0          2m33s
cka-cronjob-29272497-wftzj   0/1     Completed   0          93s
cka-cronjob-29272498-dmvzh   0/1     Completed   0          33s
cka-pod                      1/1     Running     0          35m
test                         1/1     Running     0          26m
controlplane:~$ k get cj cka-cronjob 
NAME          SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cka-cronjob   * * * * *   <none>     False     0        58s             35m
controlplane:~$ k get cj cka-cronjob 
NAME          SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cka-cronjob   * * * * *   <none>     False     0        5s              35m
controlplane:~$ k get po
NAME                         READY   STATUS      RESTARTS   AGE
cka-cronjob-29272497-wftzj   0/1     Completed   0          2m17s
cka-cronjob-29272498-dmvzh   0/1     Completed   0          77s
cka-cronjob-29272499-29r8q   0/1     Completed   0          17s
cka-pod                      1/1     Running     0          36m
test                         1/1     Running     0          26m
controlplane:~$ k describe cj cka-cronjob 
Name:                          cka-cronjob
Namespace:                     default
Labels:                        <none>
Annotations:                   <none>
Schedule:                      * * * * *
Concurrency Policy:            Allow
Suspend:                       False
Successful Job History Limit:  3
Failed Job History Limit:      1
Starting Deadline Seconds:     <unset>
Selector:                      <unset>
Parallelism:                   <unset>
Completions:                   <unset>
Pod Template:
  Labels:  <none>
  Containers:
   curl-container:
    Image:      curlimages/curl:latest
    Port:       <none>
    Host Port:  <none>
    Command:
      curl
      cka-service
    Environment:     <none>
    Mounts:          <none>
  Volumes:           <none>
  Node-Selectors:    <none>
  Tolerations:       <none>
Last Schedule Time:  Thu, 28 Aug 2025 03:00:00 +0000
Active Jobs:         <none>
Events:
  Type    Reason            Age                  From                Message
  ----    ------            ----                 ----                -------
  Normal  SuccessfulCreate  36m                  cronjob-controller  Created job cka-cronjob-29272464
  Normal  SuccessfulCreate  35m                  cronjob-controller  Created job cka-cronjob-29272465
  Normal  SuccessfulCreate  34m                  cronjob-controller  Created job cka-cronjob-29272466
  Normal  SuccessfulCreate  33m                  cronjob-controller  Created job cka-cronjob-29272467
  Normal  SuccessfulCreate  32m                  cronjob-controller  Created job cka-cronjob-29272468
  Normal  SuccessfulCreate  31m                  cronjob-controller  Created job cka-cronjob-29272469
  Normal  SawCompletedJob   30m                  cronjob-controller  Saw completed job: cka-cronjob-29272464, condition: Failed
  Normal  SuccessfulCreate  30m                  cronjob-controller  Created job cka-cronjob-29272470
  Normal  SuccessfulDelete  29m                  cronjob-controller  Deleted job cka-cronjob-29272464
  Normal  SawCompletedJob   29m                  cronjob-controller  Saw completed job: cka-cronjob-29272465, condition: Failed
  Normal  SuccessfulCreate  29m                  cronjob-controller  Created job cka-cronjob-29272471
  Normal  SawCompletedJob   29m                  cronjob-controller  Saw completed job: cka-cronjob-29272466, condition: Failed
  Normal  SuccessfulDelete  29m                  cronjob-controller  Deleted job cka-cronjob-29272465
  Normal  SuccessfulCreate  28m                  cronjob-controller  Created job cka-cronjob-29272472
  Normal  SuccessfulDelete  28m                  cronjob-controller  Deleted job cka-cronjob-29272466
  Normal  SawCompletedJob   28m                  cronjob-controller  Saw completed job: cka-cronjob-29272467, condition: Failed
  Normal  SawCompletedJob   26m                  cronjob-controller  Saw completed job: cka-cronjob-29272468, condition: Failed
  Normal  SuccessfulDelete  26m                  cronjob-controller  Deleted job cka-cronjob-29272467
  Normal  SuccessfulDelete  25m                  cronjob-controller  Deleted job cka-cronjob-29272468
  Normal  SawCompletedJob   25m                  cronjob-controller  Saw completed job: cka-cronjob-29272469, condition: Failed
  Normal  SuccessfulDelete  24m                  cronjob-controller  Deleted job cka-cronjob-29272469
  Normal  SawCompletedJob   24m                  cronjob-controller  Saw completed job: cka-cronjob-29272470, condition: Failed
  Normal  SuccessfulCreate  24m (x4 over 27m)    cronjob-controller  (combined from similar events): Created job cka-cronjob-29272476
  Normal  SuccessfulDelete  24m                  cronjob-controller  Deleted job cka-cronjob-29272470
  Normal  SuccessfulDelete  103s (x23 over 22m)  cronjob-controller  (combined from similar events): Deleted job cka-cronjob-29272496
controlplane:~$ 
```

---
## Q2

Create a job named countdown-devops.

The spec template should be named `countdown-devops` (under metadata), and the container should be named `container-countdown-devops`

Utilize image `debian` with `latest` tag (ensure to specify as `debian:latest`), and set the restart policy to `Never`.

Execute the command `sleep 5`

```bash
thor@jumphost ~$ vi avc.yaml
thor@jumphost ~$ k apply -f avc.yaml 
job.batch/countdown-devops created
thor@jumphost ~$ k get po
NAME                     READY   STATUS    RESTARTS   AGE
countdown-devops-qhwbh   1/1     Running   0          4s
thor@jumphost ~$ cat avc.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: countdown-devops
spec:
  template:
    metadata:
      name: countdown-devops   # Pod template name
    spec:
      containers:
      - name: container-countdown-devops
        image: debian:latest
        command: ["sleep", "5"]
      restartPolicy: Never

thor@jumphost ~$
```

---

## Q3

In the `ckad-job` namespace, create a cronjob named `simple-node-job` to run every `30 minutes` to list all the running processes inside a container that used `node image` (**the command needs to be run in a shell**). In Unix-based operating systems, `ps -eaf` can be use to list all the running processes.

```bash
root@student-node ~ ➜  k create cj simple-node-job -n ckad-job --schedule "*/30 * * * *" --image node -- sh -c "ps -eaf"
cronjob.batch/simple-node-job created

apiVersion: batch/v1
kind: CronJob
            command:
            - sh
            - -c
            - ps -eaf
```

---
## Q4

In the `ckad-job` namespace, create a job named `very-long-pi` that simply computes a π (pi) to 1024 places and prints it out.

This job should be configured to **retry maximum 5 times** before marking this job failed, and the duration of this job **should not exceed 100 seconds**.

The job should use the container image `perl:5.34.0`.

The container should run a Perl command that calculates π (pi) to 1024 decimal places using:

`perl -Mbignum=bpi -wle 'print bpi(1024)'`

```bash
root@student-node ~ ➜  vi 2.yaml

root@student-node ~ ➜  k apply -f 2.yaml 
job.batch/very-long-pi created

root@student-node ~ ➜  k get job -n ckad-job 
NAME           STATUS    COMPLETIONS   DURATION   AGE
very-long-pi   Running   0/1           16s        16s

root@student-node ~ ➜  cat 2.yaml 
apiVersion: batch/v1
kind: Job
metadata:
  name: very-long-pi
  namespace: ckad-job
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(1024)"]
      restartPolicy: Never
  backoffLimit: 5                # retries before marking failed
  activeDeadlineSeconds: 100     # max duration


root@student-node ~ ➜  k get job -n ckad-job 
NAME           STATUS     COMPLETIONS   DURATION   AGE
very-long-pi   Complete   1/1           20s        46s
```

---

## Q5
In the `ckad-job` namespace, schedule a job called `learning-every-hour` that prints this message in the shell every hour **at 0 minutes**: `I will pass CKAD certification`. In case the container in pod failed for any reason, it should be restarted automatically. Use `alpine` image for the cronjob!

```bash
root@student-node ~ ➜  k create cj learning-every-hour -n ckad-job --image alpine --schedule "* * * * *" -- "echo 'I will pass CKAD certification'" # wrong
cronjob.batch/learning-every-hour created # wrong

root@student-node ~ ➜  k get cj -n ckad-job 
NAME                  SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
learning-every-hour   * * * * *   <none>     False     1        11s             24s

root@student-node ~ ➜  k get cj -n ckad-job
NAME                  SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
learning-every-hour   * * * * *   <none>     False     1        41s             54s

root@student-node ~ ➜  k get cj -n ckad-job
NAME                  SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
learning-every-hour   * * * * *   <none>     False     1        51s             64s

root@student-node ~ ➜  k get cj -n ckad-job
NAME                  SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
learning-every-hour   * * * * *   <none>     False     2        11s             84s

root@student-node ~ ➜  k logs -n ckad-job learning-every-hour-2929321
error: error from server (NotFound): pods "learning-every-hour-2929321" not found in namespace "ckad-job"

root@student-node ~ ✖ k logs -n ckad-job learning-every-hour-2929321
error: error from server (NotFound): pods "learning-every-hour-2929321" not found in namespace "ckad-job"

root@student-node ~ ✖ k get po -n ckad-job 
NAME                                 READY   STATUS              RESTARTS      AGE
learning-every-hour-29293210-5dxks   0/1     CrashLoopBackOff    4 (47s ago)   2m15s
learning-every-hour-29293211-4vth7   0/1     CrashLoopBackOff    3 (33s ago)   75s
learning-every-hour-29293212-mrx6f   0/1     RunContainerError   2 (2s ago)    15s

root@student-node ~ ➜  k edit cj -n ckad-job learning-every-hour 
Edit cancelled, no changes made.

root@student-node ~ ➜  k delete cj -n ckad-job learning-every-hour 
cronjob.batch "learning-every-hour" deleted

root@student-node ~ ➜  kubectl create cronjob learning-every-hour \
  --image=alpine \
  --schedule="0 * * * *" \
  --namespace=ckad-job \
  -- /bin/sh -c "echo 'I will pass CKAD certification.'"
cronjob.batch/learning-every-hour created

root@student-node ~ ➜  k get cj -n ckad-job 
NAME                  SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
learning-every-hour   0 * * * *   <none>     False     0        <none>          16s

root@student-node ~ ➜  k get cj -n ckad-job 
NAME                  SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
learning-every-hour   0 * * * *   <none>     False     0        <none>          44s

root@student-node ~ ➜  k get cj -n ckad-job 
NAME                  SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
learning-every-hour   0 * * * *   <none>     False     0        <none>          84s

root@student-node ~ ➜  
```

---

Good catch 🌟

Here’s the difference:

* `* * * * *` → **every minute** (runs 60 times in an hour).
* `0 * * * *` → **every hour at minute 0** (runs once per hour, exactly on the hour).

Your task explicitly said:

> "every hour at 0 minutes"

So ✅ the correct cron expression is **`0 * * * *`**, not `* * * * *`.

Nice 👌 this is a subtle but important **cron expression** detail.

---

***In the ckad-job namespace, schedule a job called learning-every-minute that prints this message in the shell every minute: I am practicing for CKAD certification.**

Perfect — let me explain why the CKAD grader insists on `*/1` instead of `*` for “every minute”:

### 1️⃣ `* * * * *` vs `*/1 * * * *`

* **`* * * * *`** → Literally means “every value of minute, hour, day, month, weekday” → works fine in standard Cron.
* **`*/1 * * * *`** → Means “every 1 minute” → also runs every minute.

Functionally, both are **identical**.

### 2️⃣ Why the grader rejects `* * * * *`

CKAD exam auto-graders are **scripted to check for exact text matches**, not the Cron logic itself.

* If the instructions say:

  > schedule a job every minute
  > the grader expects **`*/1 * * * *`** literally in the YAML.
* `* * * * *` will run correctly in Kubernetes, but the grader sees a mismatch in the string value.

### 3️⃣ Practical lesson

* Always **follow the exact syntax requested** in CKAD tasks.
* Logical equivalence doesn’t matter for auto-graders; **textual equivalence does**.

✅ So, for CKAD, always write:

```yaml
schedule: "*/1 * * * *"
```

Even though `* * * * *` works in real clusters.

---
## Q6
Create a cronjob called `dice` that runs every `one minute`. Use the Pod template located at `/root/throw-a-dice`. The image `throw-dice` randomly returns a value between 1 and 6. The result of 6 is considered success and all others are failure.

The job should be non-parallel and complete the task once. Use a backoffLimit of `25`.

If the task is not completed within `20` seconds the job should fail and pods should be terminated.

```bash
controlplane ~ ➜  cat throw-a-dice/throw-a-dice.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: throw-dice-pod
spec:
  containers:
  -  image: kodekloud/throw-dice
     name: throw-dice
  restartPolicy: Never

controlplane ~ ➜  cat 2.yaml 
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dice
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      activeDeadlineSeconds: 20
      backoffLimit: 25
      template:
        metadata:
          name: throw-dice-pod
        spec:
          containers:
          - image: kodekloud/throw-dice
            name: throw-dice
          restartPolicy: Never

controlplane ~ ➜  
```
