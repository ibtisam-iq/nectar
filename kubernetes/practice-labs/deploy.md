On cluster2, a new deployment called cube-alpha-apd has been created in the alpha-ns-apd namespace using the image kodekloud/webapp-color:v2. This deployment will test a newer version of the alpha app.

Configure the deployment in such a way that the alpha-apd-service service routes less than 40% of traffic to the new deployment.


NOTE: - Do not increase the replicas of the ruby-alpha-apd deployment.

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
Selector:                 alpha=v1
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

An application called results-apd is running on cluster2. In the weekly meeting, the team decides to upgrade the version of the existing image to 1.23.3 and wants to store the new version of the image in a file /root/records/new-image-records.txt on the cluster2-controlplane instance.

```bash
echo "1.23.3" > /root/records/new-image-records.txt   # wrong, but is tag only.
echo "nginx:1.23.3" > /root/records/new-image-records.txt
```

---

On cluster1, a new deployment called cube-alpha-apd has been created in the alpha-ns-apd namespace using the image kodekloud/webapp-color:v2. This deployment will test a newer version of the alpha app.

Configure the deployment in such a way that the alpha-apd-service service routes less than 40% of traffic to the new deployment.


NOTE: - Do not increase the replicas of the ruby-alpha-apd deployment.

```bash
root@student-node ~ ➜  k get po -n alpha-ns-apd --show-labels
NAME                              READY   STATUS    RESTARTS   AGE    LABELS
cube-alpha-apd-6f8fd88867-l7tx9   1/1     Running   0          100s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-swr84   1/1     Running   0          100s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-t4sch   1/1     Running   0          100s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-xg8jw   1/1     Running   0          100s   alpha=v1,pod-template-hash=6f8fd88867
cube-alpha-apd-6f8fd88867-xt6ph   1/1     Running   0          100s   alpha=v1,pod-template-hash=6f8fd88867
ruby-alpha-apd-684b685879-48b8x   1/1     Running   0          100s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-br644   1/1     Running   0          100s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-dcfkl   1/1     Running   0          100s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-h64pl   1/1     Running   0          100s   alpha=v1,pod-template-hash=684b685879
ruby-alpha-apd-684b685879-lt8jt   1/1     Running   0          100s   alpha=v1,pod-template-hash=684b685879

root@student-node ~ ➜  k describe svc -n alpha-ns-apd 
Name:                     alpha-apd-service
Namespace:                alpha-ns-apd
Labels:                   app=alpha-apd-service
Annotations:              <none>
Selector:                 alpha=v1
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.97.93
IPs:                      10.43.97.93
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31194/TCP
Endpoints:                10.42.3.17:8080,10.42.3.16:8080,10.42.3.18:8080 + 7 more...
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  kubectl -n alpha-ns-apd scale deployment cube-alpha-apd --replicas=3
deployment.apps/cube-alpha-apd scaled

root@student-node ~ ➜  
```

Got it 👍 Let’s break this down step by step.

### Current Situation

* **Namespace:** `alpha-ns-apd`
* **New Deployment:** `cube-alpha-apd` (5 pods)
* **Old Deployment:** `ruby-alpha-apd` (5 pods)
* **Service:** `alpha-apd-service`

  * Selector → `alpha=v1`
  * Currently matching **all pods** from both deployments since they both have `alpha=v1`.

👉 This means **all 10 pods** (5 old + 5 new) are behind the service.
👉 That results in **50% traffic** to each deployment.

### Requirement

* Send **less than 40% traffic** to the new deployment (`cube-alpha-apd`).
* Cannot increase replicas of `ruby-alpha-apd`.

### Solution

Since the service is distributing traffic evenly across all pods that match its selector, the **only way to control traffic split** is by adjusting the **replica count of the new deployment**.

#### Step 1. Scale down `cube-alpha-apd`

If we scale `cube-alpha-apd` to **3 pods**, we get:

* 5 pods → `ruby-alpha-apd`
* 3 pods → `cube-alpha-apd`

Traffic distribution:

* `cube-alpha-apd`: 3 / (5 + 3) = **37.5%** ✅
* `ruby-alpha-apd`: 62.5%

#### Step 2. Apply scaling

```bash
kubectl -n alpha-ns-apd scale deployment cube-alpha-apd --replicas=3
```

#### Step 3. Verify

```bash
kubectl get pods -n alpha-ns-apd -o wide
kubectl describe svc alpha-apd-service -n alpha-ns-apd
```

Check that:

* `cube-alpha-apd` has **3 pods**.
* `ruby-alpha-apd` still has **5 pods**.
* Service Endpoints show 8 total (5 old + 3 new).

✅ Now the new deployment receives **<40% traffic** through the service.

---

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
