cka-pod pod exposed internally within the service name cka-service and for cka-pod monitor(access through svc) purpose deployed cka-cronjob cronjob that run every minute .

Now cka-cronjob cronjob not working as expected, fix that issue.

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

Create a job named countdown-devops.

The spec template should be named countdown-devops (under metadata), and the container should be named container-countdown-devops

Utilize image debian with latest tag (ensure to specify as debian:latest), and set the restart policy to Never.

Execute the command sleep 5

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
```
