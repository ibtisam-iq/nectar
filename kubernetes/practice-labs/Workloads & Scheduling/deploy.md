The yaml for the existing Deployment is available at `/opt/course/16/cleaner.yaml`. Persist your changes at `/opt/course/16/cleaner-new.yaml` on `ckad7326` but also make sure the Deployment is running.

```bash
# Check the current deployment manifest
cat /opt/course/16/cleaner.yaml

# Copy to a new file
cp /opt/course/16/cleaner.yaml /opt/course/16/cleaner-new.yaml

# Edit the new file as per question requirements
vi /opt/course/16/cleaner-new.yaml

# Apply the new deployment
kubectl apply -f /opt/course/16/cleaner-new.yaml

# Verify that it's running
kubectl get deploy,rs,pods -n <namespace>
```

## Q1 Canary Deployment

On cluster2, a new deployment called `cube-alpha-apd` has been created in the `alpha-ns-apd` namespace using the image `kodekloud/webapp-color:v2`. This deployment will test a **newer version** of the `alpha app`.

Configure the deployment in such a way that the `alpha-apd-service` service routes less than **40% of traffic** to the new deployment.

> **NOTE: - Do not increase the replicas of the `ruby-alpha-apd` deployment.**

```bash
root@student-node ~ ➜  k get po -n alpha-ns-apd --show-labels 
NAME                              READY   STATUS    RESTARTS   AGE    LABELS
cube-alpha-apd-6f8fd88867-28n56   1/1     Running   0          2m3s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-7sbt8   1/1     Running   0          2m3s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-l26cj   1/1     Running   0          2m3s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-xwzbt   1/1     Running   0          2m3s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-z4j4b   1/1     Running   0          2m3s   alpha=v1,pod-template-hash=6f8fd88867
ruby-alpha-apd-684b685879-27kv4   1/1     Running   0          2m4s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-7hwpn   1/1     Running   0          2m4s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-7q88b   1/1     Running   0          2m3s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-g8vvf   1/1     Running   0          2m4s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-s2f9f   1/1     Running   0          2m3s   alpha=v1,pod-template-hash=684b685879

root@student-node ~ ➜  k describe svc -n alpha-ns-apd alpha-apd-service 
Name:                     alpha-apd-service
Namespace:                alpha-ns-apd
Labels:                   app=alpha-apd-service
Annotations:              <none>
Selector:                 alpha=v1
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.70.250
IPs:                      10.43.70.250
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30640/TCP
Endpoints:                10.42.1.12:8080,10.42.1.14:8080,10.42.1.13:8080 + 7 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  kubectl -n alpha-ns-apd scale deployment cube-alpha-apd --replicas=3
deployment.apps/cube-alpha-apd scaled

root@student-node ~ ➜  k describe svc -n alpha-ns-apd alpha-apd-service 
Name:                     alpha-apd-service
Namespace:                alpha-ns-apd
Labels:                   app=alpha-apd-service
Annotations:              <none>
Selector:                 alpha=v1              # sharing the common label
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.70.250
IPs:                      10.43.70.250
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30640/TCP
Endpoints:                10.42.1.12:8080,10.42.1.13:8080,10.42.1.15:8080 + 5 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  
```

Thanks for the detailed output 🙌

Let’s analyze what’s going on:

### Current State

* **Deployments:**

  * `ruby-alpha-apd` → 5 Pods
  * `cube-alpha-apd` → 5 Pods
* **Service `alpha-apd-service`:**

  * Selector → `alpha=v1`
  * That means **all 10 Pods** (5 ruby + 5 cube) are matching.
* So traffic is currently distributed **\~50/50** (because both sets have the same number of replicas).

### Requirement

> Configure the deployment so that `alpha-apd-service` routes **less than 40%** traffic to the new `cube-alpha-apd` deployment.
> ⚠️ **You cannot increase ruby-alpha-apd replicas.**

This means we need to **reduce `cube-alpha-apd` replicas**, so it makes up less than 40% of the total Pods.

### Math

* `ruby-alpha-apd` = 5 replicas
* If `cube-alpha-apd` = 2 replicas → Total = 7 Pods

  * Cube share = 2/7 ≈ **28%** ✅ (less than 40%)
* If `cube-alpha-apd` = 3 replicas → Total = 8 Pods

  * Cube share = 3/8 = **37.5%** ✅ (still less than 40%)
* If `cube-alpha-apd` = 4 replicas → Total = 9 Pods

  * Cube share = 4/9 ≈ **44%** ❌ (too high)

So you can scale `cube-alpha-apd` down to **2 or 3 replicas**.

### Command

To scale to 3 replicas (safe, closer to 40% but still below):

```bash
kubectl -n alpha-ns-apd scale deployment cube-alpha-apd --replicas=3
```

Or scale to 2 replicas (more conservative, \~28%):

```bash
kubectl -n alpha-ns-apd scale deployment cube-alpha-apd --replicas=2
```

### Verify

```bash
kubectl -n alpha-ns-apd get pods -o wide
kubectl -n alpha-ns-apd describe svc alpha-apd-service
```

You should see only **8 pods (5 ruby + 3 cube)** or **7 pods (5 ruby + 2 cube)** behind the service.

---

## Q2 Canary Deployment

A new deployment called `frontend-v2` has been created in the default namespace using the image `kodekloud/webapp-color:v2`. This deployment will be used to test a newer version of the same app.

Configure the deployment in such a way that the service called `frontend-service` routes less than **20%** of traffic to the new deployment.
Do not increase the replicas of the `frontend` deployment.

```bash
controlplane ~ ➜  k get deploy
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
frontend      5/5     5            5           11m
frontend-v2   2/2     2            2           8m18s

controlplane ~ ➜  k get po --show-labels 
NAME                           READY   STATUS    RESTARTS   AGE     LABELS
frontend-8b5db9bd-6x2fk        1/1     Running   0          11m     app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-c285m        1/1     Running   0          11m     app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-hsxfs        1/1     Running   0          11m     app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-kgzvj        1/1     Running   0          11m     app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-qlrsf        1/1     Running   0          11m     app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-v2-79b6c9cff4-9ptf5   1/1     Running   0          8m23s   app=frontend,pod-template-hash=79b6c9cff4,version=v2
frontend-v2-79b6c9cff4-rbqsb   1/1     Running   0          8m23s   app=frontend,pod-template-hash=79b6c9cff4,version=v2

controlplane ~ ➜  k describe svc frontend-service 
Name:                     frontend-service
Namespace:                default
Labels:                   app=myapp
Annotations:              <none>
Selector:                 app=frontend    # sharing the common label
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.236.179
IPs:                      172.20.236.179
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30080/TCP
Endpoints:                172.17.0.7:8080,172.17.0.5:8080,172.17.0.6:8080 + 4 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

controlplane ~ ➜  k scale deployment frontend-v2 --replicas 1
deployment.apps/frontend-v2 scaled

controlplane ~ ➜  k get po --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
frontend-8b5db9bd-6x2fk        1/1     Running   0          13m   app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-c285m        1/1     Running   0          13m   app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-hsxfs        1/1     Running   0          13m   app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-kgzvj        1/1     Running   0          13m   app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-8b5db9bd-qlrsf        1/1     Running   0          13m   app=frontend,pod-template-hash=8b5db9bd,version=v1
frontend-v2-79b6c9cff4-rbqsb   1/1     Running   0          10m   app=frontend,pod-template-hash=79b6c9cff4,version=v2

controlplane ~ ➜  
```

We have now established that the new version v2 of the application is working as expected.

We can now safely redirect all users to the v2 version.

```bash
controlplane ~ ➜  k edit svc frontend-service 
service/frontend-service edited

controlplane ~ ➜  k describe svc frontend-service 
Name:                     frontend-service
Namespace:                default
Labels:                   app=myapp
Annotations:              <none>
Selector:                 app=frontend,version=v2       # version: v2 added now.
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.236.179
IPs:                      172.20.236.179
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  30080/TCP
Endpoints:                172.17.0.10:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

controlplane ~ ➜  
```

Scale down the `v1` version of the apps to `0` replicas and scale up the new(`v2`) version to `5` replicas.

```bash
controlplane ~ ➜  k scale deployment frontend-v2 --replicas 5
deployment.apps/frontend-v2 scaled

controlplane ~ ➜  k scale deployment frontend --replicas 0
deployment.apps/frontend scaled

controlplane ~ ➜  k get po --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
frontend-v2-79b6c9cff4-6d9c5   1/1     Running   0          45s   app=frontend,pod-template-hash=79b6c9cff4,version=v2
frontend-v2-79b6c9cff4-8c7gv   1/1     Running   0          45s   app=frontend,pod-template-hash=79b6c9cff4,version=v2
frontend-v2-79b6c9cff4-kmph2   1/1     Running   0          45s   app=frontend,pod-template-hash=79b6c9cff4,version=v2
frontend-v2-79b6c9cff4-rbqsb   1/1     Running   0          17m   app=frontend,pod-template-hash=79b6c9cff4,version=v2
frontend-v2-79b6c9cff4-z76sf   1/1     Running   0          45s   app=frontend,pod-template-hash=79b6c9cff4,version=v2

controlplane ~ ➜  
```

Now delete the deployment called `frontend` completely.

```bash
controlplane ~ ➜  k delete deployments.apps frontend
deployment.apps "frontend" deleted
```

---

## Q3

An application called `results-apd` is running on cluster2. In the weekly meeting, the team decides to upgrade the version of the existing image to `1.23.3` and wants to store the **new version** of the image in a file `/root/records/new-image-records.txt` on the cluster2-controlplane instance.

```bash
echo "1.23.3" > /root/records/new-image-records.txt   # wrong, but is tag only.
echo "nginx:1.23.3" > /root/records/new-image-records.txt
```

---

## Q4 Deployment is paused.

```bash
cluster1-controlplane ~ ➜  k get po -n kube-system   # No clue
NAMESPACE     NAME                                            READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-5745477d4d-bs7tc        1/1     Running   0          117m
kube-system   canal-5k7vk                                     2/2     Running   0          117m
kube-system   canal-jnvlq                                     2/2     Running   0          117m
kube-system   canal-v5k88                                     2/2     Running   0          117m
kube-system   coredns-7484cd47db-ftpkp                        1/1     Running   0          117m
kube-system   coredns-7484cd47db-qqkdp                        1/1     Running   0          117m
kube-system   etcd-cluster1-controlplane                      1/1     Running   0          117m
kube-system   kube-apiserver-cluster1-controlplane            1/1     Running   0          117m
kube-system   kube-controller-manager-cluster1-controlplane   1/1     Running   0          117m
kube-system   kube-proxy-l75zs                                1/1     Running   0          117m
kube-system   kube-proxy-pxd5v                                1/1     Running   0          117m
kube-system   kube-proxy-sc89b                                1/1     Running   0          117m
kube-system   kube-scheduler-cluster1-controlplane            1/1     Running   0          117m
kube-system   metrics-server-6f7dd4c4c4-2m9jn                 1/1     Running   0          97m

cluster1-controlplane ~ ➜  k get deploy black-cka25-trb 
NAME              READY   UP-TO-DATE   AVAILABLE   AGE             # Problem UP-TO-DATE=0
black-cka25-trb   1/1     0            1           76s

cluster1-controlplane ~ ➜  k describe deployments.apps black-cka25-trb 
Name:                   black-cka25-trb
Replicas:               1 desired | 0 updated | 1 total | 1 available | 0 unavailable
Conditions:
  Type           Status   Reason
  ----           ------   ------
  Available      True     MinimumReplicasAvailable
  Progressing    Unknown  DeploymentPaused                         # Found the culprit
OldReplicaSets:  black-cka25-trb-7bdc648c8c (1/1 replicas created)
NewReplicaSet:   <none>

cluster1-controlplane ~ ➜  k get deploy black-cka25-trb -o yaml
apiVersion: apps/v1
spec:
  paused: true                                                    # Spotted
  replicas: 1

cluster1-controlplane ~ ➜  k get po black-cka25-trb-7bdc648c8c-q94t9 -o yaml
apiVersion: v1
kind: Pod
spec:
  nodeName: cluster1-node02

cluster1-controlplane ~ ➜  k rollout status deployment black-cka25-trb  # Oh, I got it...
Waiting for deployment "black-cka25-trb" rollout to finish: 0 out of 1 new replicas have been updated...
^C

cluster1-controlplane ~ ➜  k get pods -o wide | grep black-cka25-trb
black-cka25-trb-7bdc648c8c-q94t9           1/1     Running   0               9m48s   172.17.2.20   cluster1-node02   <none>           <none>

cluster1-controlplane ~ ➜  k logs black-cka25-trb-7bdc648c8c-q94t9 

cluster1-controlplane ~ ➜  k rollout restart deployment black-cka25-trb 
error: deployments.apps "black-cka25-trb" can't restart paused deployment (run rollout resume first)

cluster1-controlplane ~ ✖ k rollout resume deployment black-cka25-trb 
deployment.apps/black-cka25-trb resumed

cluster1-controlplane ~ ➜  k rollout restart deployment black-cka25-trb 
deployment.apps/black-cka25-trb restarted

cluster1-controlplane ~ ➜  k get deploy black-cka25-trb 
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
black-cka25-trb   1/1     1            1           18m 
```

---

## Q5: Replica=0

`stream-deployment` deployment is not up to date. observed 0  under the **UP-TO-DATE** it should be 1 , Troubleshoot, fix the issue and make sure deployment is up to date.

```bash
controlplane:~$ k get po
No resources found in default namespace.
controlplane:~$ k get deployments.apps 
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
stream-deployment   0/0     0            0           4m25s
controlplane:~$ k describe deployments.apps stream-deployment 
Name:                   stream-deployment
Replicas:               0 desired | 0 updated | 0 total | 0 available | 0 unavailable   # replica is 0
NewReplicaSet:   stream-deployment-79cb7b68c (0/0 replicas created)
Events:          <none>

controlplane:~$ k edit deployments.apps stream-deployment     # change replica: 1
deployment.apps/stream-deployment edited
controlplane:~$ k get deployments.apps 
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
stream-deployment   0/1     1            0           5m5s
controlplane:~$ k get deployments.apps 
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
stream-deployment   1/1     1            1           5m9s
controlplane:~$ 
```

---

## Q6

The deployment named `video-app` has experienced multiple rolling updates and rollbacks. Your task is to total revision of this deployment and record the image name used in 3rd revision to file `app-file.txt` in this format `REVISION_TOTAL_COUNT,IMAGE_NAME`.

```bash
controlplane:~$ k rollout history deployment video-app 
deployment.apps/video-app 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>

controlplane:~$ k rollout history deployment video-app --revision 3
deployment.apps/video-app with revision #3
Pod Template:
  Labels:       app=video-app
        pod-template-hash=775488848c
  Containers:
   redis:
    Image:      redis:7.0.13
    Port:       <none>
    Host Port:  <none>
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
  Node-Selectors:       <none>
  Tolerations:  <none>

controlplane:~$ echo "3,redis:7.0.13" > app-file.txt
controlplane:~$ cat app-file.txt 
3,redis:7.0.13
controlplane:~$ 
```
---

## Q7

Create a `Redis` deployment in the default namespace with the following specifications:

Name: redis
Image: redis:alpine
Replicas: 1
Labels: app=redis
CPU Request: 0.2 CPU (200m)
Container Port: 6379
Volumes:
- An emptyDir volume named data, mounted at /redis-master-data.
- A ConfigMap volume named redis-config, mounted at /redis-master.The ConfigMap has already been created for you. Do not create it again.

```bash
controlplane ~ ➜  k replace -f 5.yaml --force
deployment.apps/redis replaced

controlplane ~ ➜  k get deploy
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deploy   4/4     4            4           14m
redis          1/1     1            1           6s

controlplane ~ ➜  k get cm 
NAME               DATA   AGE
kube-root-ca.crt   1      135m
redis-config       1      12m

controlplane ~ ➜  cat 5.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: redis
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: redis
    spec:
      volumes:
        - name: data
          emptyDir: {}
        - name: redis-config    # I just put random name here, the question becomes incorrect.
          configMap:
            name: redis-config
      containers:
      - image: redis:alpine
        name: redis
        volumeMounts:
          - name: redis-config
            mountPath: /redis-master
          - name: data
            mountPath: /redis-master-data
        resources:
          request: 
            cpu: "200m"
        ports:
        - containerPort: 6379
        resources: {}
status: {}

controlplane ~ ➜  
```

---

## Q8

From student-node `ssh cluster1-controlplane` to solve this question.

Create a deployment named `logging-deployment` in the namespace `logging-ns` with `1` replica, with the following specifications:

The main container should be named `app-container`, use the image `busybox`, and should start by creating a log directory `/var/log/app` and run the below command to simulate generating logs :

```bash
while true; do 
  echo "Log entry" >> /var/log/app/app.log
  sleep 5
done
```
Add a co-located container named `log-agent` that also uses the `busybox` image and runs the commands:

```bash
touch /var/log/app/app.log
tail -f /var/log/app/app.log
```
`log-agent` logs should display the entries logged by the main `app-container`

```bash
cluster1-controlplane ~ ➜  cat 2.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: logging-deployment
  name: logging-deployment
  namespace: logging-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logging-deployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: logging-deployment
    spec:
      volumes:
        - name: abc
          emptyDir: {}
      containers:
      - image: busybox
        name: app-container
        volumeMounts:
          - name: abc
            mountPath: /var/log/app
        command:
          - sh
          - -c
        args:
          - while true; do echo "Log entry" >> /var/log/app/app.log; sleep 5; done
      - image: busybox
        volumeMounts:
          - name: abc
            mountPath: /var/log/app
        name: log-agent
        command:
          - sh
          - -c
          - touch /var/log/app/app.log; tail -f /var/log/app/app.log
status: {}

cluster1-controlplane ~ ➜  k logs -n logging-ns logging-deployment-7bdd98cff6-z8rjk -c log-agent
Log entry
Log entry
```

