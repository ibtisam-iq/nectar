## Q1

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

## Q2

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

## Q3

`postgres-deployment.yaml` template is there, now we can't create object due to some issue in that, check and fix the issue

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
```

---

## Q4 wrong image tag

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
