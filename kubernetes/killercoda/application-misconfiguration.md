## Application Misconfigured

```bash
controlplane:~$ k describe po -n application1 api-6768cbb9cc-hz5wt 
Events:
  Warning  Failed     1s (x7 over 62s)  kubelet            Error: configmap "category" not found
controlplane:~$ k get cm -n application1
NAME                 DATA   AGE
configmap-category   1      4m25s

controlplane:~$ k edit deploy -n application1
deployment.apps/api edited
controlplane:~$ k rollout restart deployment -n application1 api 
deployment.apps/api restarted
controlplane:~$ k get deployments.apps -n application1
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
api    3/3     3            3           10m
```
---

```bash
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE    VERSION
controlplane   Ready    control-plane   4d7h   v1.33.2
controlplane:~$ k describe po management-frontend-7b897f454f-2zpgh 
Name:             management-frontend-7b897f454f-2zpgh
Node:             staging-node1/      # cause
Status:           Pending
IP:               
IPs:              <none>
Events:            <none>            # effect, no events, not scheduled yet
controlplane:~$ k get events         # nothing special

controlplane:~$ k edit deploy management-frontend 
deployment.apps/management-frontend edited
controlplane:~$ k rollout restart deployment management-frontend 
deployment.apps/management-frontend restarted
controlplane:~$ k get po
NAME                                   READY   STATUS        RESTARTS   AGE
management-frontend-5987bc84b5-9hnsd   1/1     Running       0          4s
management-frontend-5987bc84b5-fczz4   1/1     Running       0          4s
management-frontend-5987bc84b5-gbr5k   1/1     Running       0          7s
management-frontend-5987bc84b5-h9mzz   1/1     Running       0          6s
management-frontend-5987bc84b5-ms7hl   1/1     Running       0          6s
```
---


There is a deployment with two containers, one is running, and other restarting...

```bash
k describe deployments.apps -n management collect-data # no clue
k describe po -n management collect-data-5759c5c888-gvf2z
Warning  BackOff    14s (x13 over 2m35s)  kubelet            Back-off restarting failed container httpd in pod collect-data-5759c5c888-gvf2z_management(9d91ca38-197d-48fc-8916-d22e54cd899b)
controlplane:~$ k logs -n management deploy/collect-data -c nginx # all good
controlplane:~$ k logs -n management deploy/collect-data -c httpd
Found 2 pods, using pod/collect-data-5759c5c888-gvf2z
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.0.7. Set the 'ServerName' directive globally to suppress this message
(98)Address in use: AH00072: make_sock: could not bind to address [::]:80
(98)Address in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
no listening sockets available, shutting down
AH00015: Unable to open logs

The issue seems that both containers have processes that want to listen on port 80. Depending on container creation order and speed, the first will succeed, the other will fail.

Solution: remove one container.

controlplane:~$ k get deploy -n management 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
collect-data   0/2     2            0           29m
controlplane:~$ k edit deploy -n management collect-data 
deployment.apps/collect-data edited
controlplane:~$ k rollout restart deployment -n management collect-data 
deployment.apps/collect-data restarted
controlplane:~$ k get deploy -n management collect-data 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
collect-data   2/2     2            2           31m
```
---

Create a Pod named pod1 of image nginx:alpine
Make key tree of ConfigMap trauerweide available as environment variable TREE1
Mount all keys of ConfigMap birke as volume. The files should be available under /etc/birke/*
Test env+volume access in the running Pod

```bash
k run pod1 --image nginx:alpine
pod/pod1 created
k edit po pod1     # mountPath: /etc/birke , not /etc/birke/*
error: pods "pod1" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-654694799.yaml"
error: Edit cancelled, no valid changes were saved.
controlplane:~$ k replace -f /tmp/kubectl-edit-654694799.yaml --force
pod "pod1" deleted
pod/pod1 replaced
controlplane:~$ k get po
NAME   READY   STATUS    RESTARTS   AGE
pod1   1/1     Running   0          5s

controlplane:~$ kubectl exec pod1 -- env | grep "TREE1=trauerweide"eide"
TREE1=trauerweide
controlplane:~$ k get cm
NAME               DATA   AGE
birke              3      19m
kube-root-ca.crt   1      4d9h
trauerweide        1      20m
controlplane:~$ kubectl exec pod1 -- cat /etc/birke/tree
birkecontrolplane:~$ 
controlplane:~$ kubectl exec pod1 -- cat /etc/birke/level
3controlplane:~$ 
controlplane:~$ kubectl exec pod1 -- cat /etc/birke/department
parkcontrolplane:~$
parkcontrolplane:~$ k describe cm birke 
Name:         birke
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
department:
----
park

level:
----
3

tree:
----
birke


BinaryData
====

Events:  <none>
```
---

```bash
controlplane:~$ k logs goapp-deployment-77549cf8d6-rr5q4
Error: PORT environment variable not set
controlplane:~$ k edit deployments.apps goapp-deployment 
deployment.apps/goapp-deployment edited
controlplane:~$ k get po
NAME                              READY   STATUS    RESTARTS   AGE
goapp-deployment-9d4fb95f-rq2fc   1/1     Running   0          7s
controlplane:~$ k get svc
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
goapp-service   ClusterIP   10.111.109.109   <none>        8080/TCP   11m
kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP    5d
controlplane:~$ curl http://10.111.109.109:8080
Hello, Kubernetes! Here is a UUID: f3f5e0f0-7786-4f2d-90a2-2510b737aec3
controlplane:~$ 

      env:
        - name: PORT
          value: "8080"         # MUST match the port your app expects
```
---

## 6 # wrong configmap name
```bash
Events:
  Type     Reason       Age                From               Message
  ----     ------       ----               ----               -------
  Normal   Scheduled    25s                default-scheduler  Successfully assigned default/nginx-deployment-756cb747fb-9w28f to node01
  Warning  FailedMount  10s (x6 over 25s)  kubelet            MountVolume.SetUp failed for volume "nginx-config" : configmap "nginx-config" not found
controlplane:~$ k get cm
NAME               DATA   AGE
kube-root-ca.crt   1      8d
nginx-configmap    1      5m12s

controlplane:~$ k edit deployments.apps nginx-deployment 
error: deployments.apps "nginx-deployment" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-110261693.yaml"
error: Edit cancelled, no valid changes were saved.
controlplane:~$ k replace -f /tmp/kubectl-edit-110261693.yaml --force
deployment.apps "nginx-deployment" deleted
The Deployment "nginx-deployment" is invalid: spec.template.spec.initContainers[0].volumeMounts[0].name: Not found: "nginx-config"
controlplane:~$ vi /tmp/kubectl-edit-110261693.yaml
controlplane:~$ k replace -f /tmp/kubectl-edit-110261693.yaml --force
deployment.apps/nginx-deployment replaced

controlplane:~$ k get po
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6bc9ddf66b-z2h67   1/1     Running   0          17s
controlplane:~$
```

---

## 7 wrong command

```bash
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------

  Warning  Failed     10s (x2 over 11s)  kubelet            Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "shell": executable file not found in $PATH: unknown
  Warning  BackOff    9s (x2 over 10s)   kubelet            Back-off restarting failed container echo-container in pod hello-kubernetes_default(547408a1-1adb-44eb-bee2-b2bbfa1d0449)

spec:
  containers:
  - command:
    - shell                  # sh not shell
    - -c
    - while true; do echo 'Hello Kubernetes'; sleep 5; done
```
---

## 8 wrong image tag

```bash
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  14s   default-scheduler  Successfully assigned default/nginx-pod to node01
  Normal   Pulling    14s   kubelet            Pulling image "nginx:ltest"
  Warning  Failed     4s    kubelet            Failed to pull image "nginx:ltest": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:ltest": failed to resolve reference "docker.io/library/nginx:ltest": docker.io/library/nginx:ltest: not found
  Warning  Failed     4s    kubelet            Error: ErrImagePull
  Normal   BackOff    3s    kubelet            Back-off pulling image "nginx:ltest"
  Warning  Failed     3s    kubelet            Error: ImagePullBackOff
```
---

## 9 wrong pvc name, then wrong pvc storageClassName, then wrong tag
```bash
Events:
  Type     Reason            Age                 From               Message   
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  21s   default-scheduler  0/2 nodes are available: persistentvolumeclaim "pvc-redis" not found. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

  Warning  FailedScheduling  5m54s               default-scheduler  0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

  Normal   Scheduled         2m5s                default-scheduler  Successfully assigned default/redis-pod to node01
  Normal   Pulling           66s (x3 over 2m5s)  kubelet            Pulling image "redis:latested"
  Warning  Failed            55s (x3 over 113s)  kubelet            Failed to pull image "redis:latested": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/redis:latested": failed to resolve reference "docker.io/library/redis:latested": docker.io/library/redis:latested: not found
  Warning  Failed            55s (x3 over 113s)  kubelet            Error: ErrImagePull
  Normal   BackOff           30s (x4 over 113s)  kubelet            Back-off pulling image "redis:latested"
  Warning  Failed            30s (x4 over 113s)  kubelet            Error: ImagePullBackOff
```
---

## 10 wrong node label (it is restricted to change any pod feature)

```bash
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  72s   default-scheduler  0/2 nodes are available: 1 node(s) didn't match Pod's node affinity/selector, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

controlplane:~$ k get po -o yaml frontend 
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: NodeName
            operator: In
            values:
            - frontend

controlplane:~$ k label no node01 NodeName=frontend
error: 'NodeName' already has a value (frontendnodes), and --overwrite is false
controlplane:~$ k label no node01 NodeName=frontend --overwrite 
node/node01 labeled

NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          5m26s
controlplane:~$
```

---

## 11 wrong accesssMode in PVC

```bash
controlplane:~$ k get pvc,pv
NAME                               STATUS    VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/my-pvc-cka   Pending   my-pv-cka   0                         standard       <unset>                 82s

NAME                         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/my-pv-cka   100Mi      RWO            Retain           Available           standard       <unset>                          83s
controlplane:~$ k get sc
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  8d
controlplane:~$ k get po
NAME         READY   STATUS    RESTARTS   AGE
my-pod-cka   0/1     Pending   0          2m14s

Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  2m31s  default-scheduler  0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

controlplane:~$ k describe pvc my-pvc-cka 
Name:          my-pvc-cka
Events:
  Type     Reason          Age                  From                         Message
  ----     ------          ----                 ----                         -------
  Warning  VolumeMismatch  8s (x15 over 3m30s)  persistentvolume-controller  Cannot bind to requested volume "my-pv-cka": incompatible accessMode

controlplane:~$ k edit pvc my-pvc-cka 
error: persistentvolumeclaims "my-pvc-cka" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-2244335843.yaml"
error: Edit cancelled, no valid changes were saved.
controlplane:~$ k replace -f /tmp/kubectl-edit-2244335843.yaml --force
persistentvolumeclaim "my-pvc-cka" deleted
persistentvolumeclaim/my-pvc-cka replaced

controlplane:~$ k get pvc
NAME         STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
my-pvc-cka   Bound    my-pv-cka   100Mi      RWO            standard       <unset>                 13s
controlplane:~$ k get po
NAME         READY   STATUS    RESTARTS   AGE
my-pod-cka   1/1     Running   0          5m34s
controlplane:~$ 
```

---
postgres-deployment.yaml template is there, now we can't create object due to some issue in that, check and fix the issue

```bash
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Warning  Failed     8s (x2 over 10s)  kubelet            Error: secret "postgres-secrte" not found

Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Warning  Failed     2s (x3 over 18s)  kubelet            Error: couldn't find key db_user in Secret default/postgres-secret

controlplane:~$ k describe secrets postgres-secret 
Name:         postgres-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password:  11 bytes
username:  7 bytes

controlplane:~$ cat postgres-deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres-container
          image: postgres:latest
          env:
            - name: POSTGRES_DB
              value: mydatabase
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-secrte               # secret
                  key: db_user                        # username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: db_password                    # password
          ports:
            - containerPort: 5432
