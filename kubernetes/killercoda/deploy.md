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
