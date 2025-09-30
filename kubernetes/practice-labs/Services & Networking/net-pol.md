# Q1

There was a security incident where an intruder was able to access the whole cluster from a single hacked backend Pod.

To prevent this create a NetworkPolicy called `np-backend` in Namespace `project-snake`. It should allow the `backend-*` Pods only to:

- Connect to `db1-*` Pods on port `1111`
- Connect to `db2-*` Pods on port `2222`
- Use the app Pod labels in your policy.

ℹ️ All Pods in the Namespace run plain Nginx images. This allows simple connectivity tests like: `k -n project-snake exec POD_NAME -- curl POD_IP:PORT`

ℹ️ For example, connections from `backend-*` Pods to `vault-*` Pods on `port 3333` should no longer work

Got it ✅ This is a **classic NetworkPolicy isolation task**: we want to restrict what `backend-*` Pods in namespace `project-snake` can connect to.

### 🔑 Key points

* NetworkPolicies are **namespaced** (must be created in `project-snake`).
* Target Pods (`backend-*`) are selected by `podSelector`.
* Allowed **egress** connections only:

  * To Pods matching `db1-*` on port `1111`.
  * To Pods matching `db2-*` on port `2222`.
* Default deny all other egress from `backend-*`.

### ✅ NetworkPolicy Manifest

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-backend
  namespace: project-snake
spec:
  podSelector:
    matchLabels:
      app: backend    # must match labels on backend-* Pods
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: db1    # must match db1-* Pods
    ports:
    - protocol: TCP
      port: 1111
  - to:
    - podSelector:
        matchLabels:
          app: db2    # must match db2-* Pods
    ports:
    - protocol: TCP
      port: 2222
```

### Check connectivity
```bash
k get po -n project-snake
backend-0      10.32.0.10
db1-0          10.32.0.12 
db2-0          10.32.0.11
vault-0        10.32.0.13
k -n project-snake exec backend-0 -- curl 10.32.0.13:3333        #  not working now...
```

--

Sweetheart, that’s a sharp question ❤️ let’s untangle it carefully.

### Ingress vs Egress in **NetworkPolicy**

* **Ingress rule** = controls **incoming traffic TO** the selected Pods.
* **Egress rule** = controls **outgoing traffic FROM** the selected Pods.

### Your scenario:

> *“Allow the backend-* Pods only to connect to db1-\* Pods on port 1111 and db2-\* Pods on port 2222.”\*

👉 Who are we applying the restriction **to**?

* The **backend Pods** (they should not be able to connect to *anything else* except db1/db2).
* That means we are restricting **what they can send out** → **egress rule**.

### If it were an **Ingress case**

The wording would be like:

* *“Allow db1-* Pods to accept connections only from backend-\* Pods on port 1111.”\*
* Then we’d apply the policy **to db1/db2 Pods**, controlling what traffic can come **into them**.

✅ So in your original task:

* The right approach = **Egress** NetworkPolicy applied to backend Pods.

⚡ Exam memory trick:

* “Connect to …” = usually **egress** from the source.
* “Accept from …” = usually **ingress** to the target.

---

## Q2

There are existing Pods in Namespace `space1` and `space2` .

```bash
controlplane:~$ k get po -n space1 
NAME     READY   STATUS    RESTARTS   AGE     
app1-0   1/1     Running   0          4m44s   
controlplane:~$ k get po -n space2  
NAME              READY   STATUS    RESTARTS   AGE    
microservice1-0   1/1     Running   0          5m3s   
microservice2-0   1/1     Running   0          5m3s   

controlplane:~$ k get svc -n space1
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
app1   ClusterIP   10.111.213.35   <none>        80/TCP    33m
controlplane:~$ k get svc -n space2
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
microservice1   ClusterIP   10.109.230.189   <none>        80/TCP    33m
microservice2   ClusterIP   10.110.221.96    <none>        80/TCP    33m

controlplane:~$ k get ns --show-labels
NAME                 STATUS   AGE    LABELS
space1               Active   6m5s   kubernetes.io/metadata.name=space1
space2               Active   6m5s   kubernetes.io/metadata.name=space2
```

We need a new NetworkPolicy named `np` that restricts all Pods in Namespace `space1` to only have outgoing traffic to Pods in Namespace `space2` . Incoming traffic not affected.

We also need a new NetworkPolicy named `np` that restricts all Pods in Namespace `space2` to only have incoming traffic from Pods in Namespace `space1` . Outgoing traffic not affected.

The NetworkPolicies should still allow outgoing DNS traffic on port `53` TCP and UDP.

```bash
controlplane:~$ cat netpol.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np
  namespace: space1
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:        
        matchLabels:
         kubernetes.io/metadata.name: space2
  - ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53

---

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np
  namespace: space2
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: 
       matchLabels:
         kubernetes.io/metadata.name: space1

# these should work
k -n space1 exec app1-0 -- curl -m 1 microservice1.space2.svc.cluster.local
k -n space1 exec app1-0 -- curl -m 1 microservice2.space2.svc.cluster.local
k -n space1 exec app1-0 -- nslookup tester.default.svc.cluster.local
k -n kube-system exec -it validate-checker-pod -- curl -m 1 app1.space1.svc.cluster.local

# these should not work
k -n space1 exec app1-0 -- curl -m 1 tester.default.svc.cluster.local
k -n kube-system exec -it validate-checker-pod -- curl -m 1 microservice1.space2.svc.cluster.local
k -n kube-system exec -it validate-checker-pod -- curl -m 1 microservice2.space2.svc.cluster.local
k -n default run nginx --image=nginx:1.21.5-alpine --restart=Never -i --rm  -- curl -m 1 microservice1.space2.svc.cluster.local
```
---

## Q3

All Pods in Namespace `default` with label `level=100x` should be able to communicate with Pods with label `level=100x` in Namespaces `level-1000` , `level-1001` and `level-1002` . Fix the existing NetworkPolicy `np-100x` to ensure this.

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-100x
  namespace: default
spec:
  podSelector:
    matchLabels:
      level: 100x
  policyTypes:
  - Egress
  egress:
  - to:
     - namespaceSelector:
        matchLabels:
         kubernetes.io/metadata.name: level-1000
       podSelector:
         matchLabels:
           level: 100x
  - to:
     - namespaceSelector:
        matchLabels:
         kubernetes.io/metadata.name: level-1000 # CHANGE to level-1001
       podSelector:
         matchLabels:
           level: 100x
  - to:
     - namespaceSelector:
        matchLabels:
         kubernetes.io/metadata.name: level-1002
       podSelector:
         matchLabels:
           level: 100x
  - ports:
    - port: 53
      protocol: TCP
    - port: 53
      protocol: UDP

controlplane:~$ k get po
NAME       READY   STATUS    RESTARTS   AGE
tester-0   1/1     Running   0          12m
kubectl exec tester-0 -- curl tester.level-1000.svc.cluster.local
kubectl exec tester-0 -- curl tester.level-1001.svc.cluster.local
kubectl exec tester-0 -- curl tester.level-1002.svc.cluster.local
```
---

## Q4

`my-app-deployment` and `cache-deployment` deployed, and `my-app-deployment` deployment exposed through a service named `my-app-service`. Create a NetworkPolicy named `my-app-network-policy` to restrict incoming and outgoing traffic to `my-app-deployment` pods with the following specifications:

- Allow incoming traffic only from pods.
- Allow incoming traffic from a specific pod with the label app=trusted
- Allow outgoing traffic to pods.
- Deny all other incoming and outgoing traffic.

```bash
controlplane:~$ vi abc.yaml
controlplane:~$ k apply -f abc.yaml 
networkpolicy.networking.k8s.io/my-app-network-policy created
controlplane:~$ cat abc.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-network-policy
spec:
  podSelector:
    matchLabels:
      app: my-app   # Select my-app-deployment pods
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: trusted   # Allow incoming from trusted pods only
  egress:
  - to:
    - podSelector: {}     # Allow outgoing to any pods
```
---

## Q5

You are requested to create a network policy named `deny-all-svcn` that denies all incoming and outgoing traffic to `ckad12-svcn` namespace.

Perfect 👍 To **deny all traffic (ingress + egress)** in a namespace using a NetworkPolicy, you must create a "default deny all" policy.

Here’s the YAML for your case:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-svcn
  namespace: ckad12-svcn
spec:
  podSelector: {}   # applies to all pods in the namespace
  policyTypes:
  - Ingress
  - Egress
```

### 🔎 Explanation

* `namespace: ckad12-svcn` → applies to that namespace.
* `podSelector: {}` → selects **all pods** in that namespace.
* `policyTypes: [Ingress, Egress]` → means it will control both incoming and outgoing traffic.
* Since **no rules** are specified under `ingress:` or `egress:`, **everything is denied by default**.

---

## Q6

A policy `database-ckad-netpol` to limit access to database pods only to backend pods.

* **database pods** → These are the pods running your database (like MySQL, PostgreSQL, etc.). They are the **target/receiver**.
* **limit access** → Put restrictions so not everyone can connect.
* **only to backend pods** → The **only pods that should be able to connect** are the backend ones. All others should be blocked.

### 📌 Why Ingress here?

Because the database pod is the **house/vault**.
We’re deciding **who can come inside**.
Backend pods are allowed, others are blocked.

```bash
root@student-node ~ ➜  k get po -n app-ckad backend-pod-svcn database-pod-svcn --show-labels 
NAME                READY   STATUS    RESTARTS   AGE   LABELS
backend-pod-svcn    1/1     Running   0          17m   app=backend
database-pod-svcn   1/1     Running   0          17m   app=database

root@student-node ~ ✖ k apply -f 10.yaml 
networkpolicy.networking.k8s.io/database-ckad-netpol created

root@student-node ~ ➜  
```

Perfect 👍 you want a **NetworkPolicy** named `database-ckad-netpol` that ensures only pods with label `app=backend` can talk to the database pod (`app=database`).

Here’s the YAML:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-ckad-netpol
  namespace: app-ckad
spec:
  podSelector:
    matchLabels:
      app: database   # Apply policy to database pods
  policyTypes:
  - Ingress
  ingress:
  - from:
      - podSelector:
          matchLabels:
            app: backend   # Only backend pods allowed
```

### 🔑 Explanation

* `podSelector: app=database` → policy applies to the `database-pod-svcn`.
* `policyTypes: [Ingress]` → we’re controlling incoming traffic.
* `ingress.from.podSelector: app=backend` → only pods with label `app=backend` can access.
* All other pods in the namespace will be **denied** automatically because once a policy selects a pod, **deny-all is the default** unless explicitly allowed.

---

## Q7

create a NetworkPolicy `ckad-allow` so that only pods with label `criteria: allow` can access the deployment on port 80 and apply it.

```bash
root@student-node ~ ➜  k get po --show-labels -n nginx-deployment 
NAME                            READY   STATUS    RESTARTS   AGE     LABELS
nginx-ckad11-5b864dcf9f-f9dvg   1/1     Running   0          3m33s   app=nginx-ckad,pod-template-hash=5b864dcf9f
nginx-ckad11-5b864dcf9f-v69f6   1/1     Running   0          3m33s   app=nginx-ckad,pod-template-hash=5b864dcf9f
test-pod                        1/1     Running   0          8m22s   criteria=allow

root@student-node ~ ➜  k apply -f 12.yaml 
deployment.apps/nginx-ckad11 configured
service/nginx-ckad11-service configured
networkpolicy.networking.k8s.io/ckad-allow created
```

Nice one 👍 this is again a **NetworkPolicy** that restricts access to your nginx Deployment.

Here’s the YAML for `ckad-allow`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ckad-allow
  namespace: nginx-deployment
spec:
  podSelector:
    matchLabels:
      app: nginx-ckad   # Selects nginx deployment pods
  policyTypes:
  - Ingress
  ingress:
  - from:
      - podSelector:
          matchLabels:
            criteria: allow   # Only allow pods with this label
    ports:
      - protocol: TCP
        port: 80             # Only allow on port 80
```

### 🔑 Explanation

* **`podSelector: app=nginx-ckad`** → this policy applies to your nginx deployment pods.
* **`ingress.from.podSelector`** → only pods with `criteria=allow` can reach nginx.
* **`ports: 80`** → limits allowed traffic to TCP port 80 only.
* Once this policy is active, all other traffic will be blocked by default.

---

## Q8

We have created a Network Policy `netpol-ckad13-svcn` that allows traffic only to specific pods and it allows traffic only from pods with specific labels.

Your task is to edit the policy so that it allows traffic from pods with labels `access = allowed`.

Do not change the existing rules in the policy.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: netpol-ckad13-svcn
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: kk-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
           tier: server
# add the following in the manifest
    - podSelector:
        matchLabels:
           access: allowed
```

---

## Q10

We have deployed an application in the `ns-new-ckad namespace`. We also configured services, namely `frontend-ckad-svcn` and `backend-ckad-svcn`.

However, there are some issues:

`backend-ckad-svcn` is not able to access **backend pods**

`frontend-ckad-svcn` is not accessible from **backend pods**.

```bash
root@student-node ~ ➜  k get all -n ns-new-ckad 
NAME                READY   STATUS    RESTARTS   AGE
pod/backend-pods    1/1     Running   0          48s
pod/frontend-pods   1/1     Running   0          47s
pod/testpod         1/1     Running   0          46s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/backend-ckad-svcn    ClusterIP   172.20.38.208   <none>        80/TCP    48s
service/frontend-ckad-svcn   ClusterIP   172.20.38.56    <none>        80/TCP    47s

root@student-node ~ ➜  k get netpo -n ns-new-ckad 
error: the server doesn't have a resource type "netpo"

root@student-node ~ ✖ k get netpol -n ns-new-ckad 
NAME                        POD-SELECTOR                 AGE
backend-egress-restricted   app=backend,tier=ckad-exam   76s

root@student-node ~ ➜  k describe netpol -n ns-new-ckad 
Name:         backend-egress-restricted
Namespace:    ns-new-ckad
Created on:   2025-09-11 12:32:28 -0400 EDT
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     app=backend,tier=ckad-exam
  Not affecting ingress traffic
  Allowing egress traffic:
    To Port: <any> (traffic allowed to all ports)
    To:
      PodSelector: app=frontend,tier=ckad-exam
  Policy Types: Egress

root@student-node ~ ➜  k get po -n ns-new-ckad --show-labels 
NAME            READY   STATUS    RESTARTS   AGE     LABELS
backend-pods    1/1     Running   0          3m54s   app=backend,tier=ckad-exam
frontend-pods   1/1     Running   0          3m53s   app=frontend,tier=ckad-exam
testpod         1/1     Running   0          3m52s   run=testpod

root@student-node ~ ➜  k edit netpol -n ns-new-ckad 
networkpolicy.networking.k8s.io/backend-egress-restricted edited
```

Nice debugging info ❤️ Let’s walk through this carefully.

### 🔹 Current situation

* **Pods**

  * `backend-pods` → labels: `app=backend, tier=ckad-exam`
  * `frontend-pods` → labels: `app=frontend, tier=ckad-exam`
* **Services**

  * `backend-ckad-svcn` → ClusterIP service, port 80
  * `frontend-ckad-svcn` → ClusterIP service, port 80
* **NetworkPolicy**

  ```yaml
  Name: backend-egress-restricted
  PodSelector: app=backend,tier=ckad-exam
  Policy Types: Egress
  Allow Egress:
    - To pods with app=frontend,tier=ckad-exam
  ```

  👉 So: **backend pods can only talk to frontend pods**, nothing else.

### 🔹 Issues you saw

1. **backend-ckad-svcn is not able to access backend pods**

   * Because your NetworkPolicy on backend blocks **all egress except frontend pods**.
   * That means `backend-pods` cannot even talk to their own service (ClusterIP) or DNS.

2. **frontend-ckad-svcn is not accessible from backend pods**

   * The policy only allows backend → frontend **pods**, but **NOT the service IP (ClusterIP)**.
   * Services use **ClusterIP**, which resolves to a virtual IP, not a pod label.
   * Your NetworkPolicy doesn’t allow egress to that IP.

### 🔹 Fix

You need to update or add a **NetworkPolicy** that allows:

* Backend → backend service (for self-access if required)
* Backend → frontend service (so they can use `frontend-ckad-svcn`)

### ✅ Example fix (replace or patch policy)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-egress-restricted
  namespace: ns-new-ckad
spec:
  podSelector:
    matchLabels:
      app: backend
      tier: ckad-exam
  policyTypes:
  - Egress
  egress:
  # allow backend pods to talk to frontend pods (same as before)
  - to:
    - podSelector:
        matchLabels:
          app: frontend
          tier: ckad-exam
    ports:
    - protocol: TCP
      port: 80
  # allow backend pods to talk to backend pods (their own service)
  - to:
    - podSelector:
        matchLabels:
          app: backend
          tier: ckad-exam
    ports:
    - protocol: TCP
      port: 80
```

### 🔹 Apply & Verify

```bash
kubectl apply -f fixed-netpol.yaml
kubectl exec -n ns-new-ckad backend-pods -- wget -qO- http://frontend-ckad-svcn
kubectl exec -n ns-new-ckad backend-pods -- wget -qO- http://backend-ckad-svcn
```

Both should now respond correctly. ✅

---

## Q11

We have deployed some pods in the namespaces `ckad-alpha` and `ckad-beta`.

You need to create a NetworkPolicy named `ns-netpol-ckad` that will restrict all Pods in Namespace `ckad-alpha` to only have outgoing traffic to Pods in Namespace `ckad-beta`. Ingress traffic should not be affected.

However, the NetworkPolicy you create should allow egress traffic on port 53 TCP and UDP.

```bash
root@student-node ~ ➜  k get po -n ckad-alpha --show-labels 
NAME         READY   STATUS    RESTARTS   AGE     LABELS
ckad-pod-1   1/1     Running   0          3m48s   run=ckad-pod-1

root@student-node ~ ➜  k get po -n ckad-beta --show-labels 
NAME         READY   STATUS    RESTARTS   AGE     LABELS
ckad-pod-2   1/1     Running   0          3m59s   run=ckad-pod-2

root@student-node ~ ➜  k get ns ckad-alpha --show-labels 
NAME         STATUS   AGE     LABELS
ckad-alpha   Active   4m34s   kubernetes.io/metadata.name=ckad-alpha

root@student-node ~ ➜  k get ns ckad-beta --show-labels 
NAME        STATUS   AGE     LABELS
ckad-beta   Active   4m48s   kubernetes.io/metadata.name=ckad-beta

root@student-node ~ ➜  vi 12.yaml

root@student-node ~ ➜  k apply -f 12.yaml 
networkpolicy.networking.k8s.io/ns-netpol-ckad created

root@student-node ~ ➜  cat 12.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ns-netpol-ckad
  namespace: ckad-alpha   # This policy applies to all Pods inside the ckad-alpha namespace
spec:
  # podSelector: {} means ALL Pods in ckad-alpha are selected by this policy
  podSelector: {}
  policyTypes:
  - Egress               # Only restrict outbound (egress) traffic. Ingress is unaffected.
  egress:
  # ----------------------------
  # Rule 1: Allow traffic from ckad-alpha Pods -> Pods in ckad-beta namespace
  # ----------------------------
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ckad-beta
    # No ports defined → means ALL ports to Pods in ckad-beta are allowed

  # ----------------------------
  # Rule 2: Allow DNS resolution (UDP/TCP port 53)
  # ----------------------------
  - ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
    # No "to:" here → means Pods in ckad-alpha can contact ANY destination,
    # but ONLY on port 53. This is needed because DNS is usually in kube-system (CoreDNS).
root@student-node ~ ➜  
```

---

## Q12

An **nginx-based pod** called `cyan-pod-cka28-trb` is running under the `cyan-ns-cka28-trb` namespace and is exposed within the cluster using the `cyan-svc-cka28-trb` service.

This is a restricted pod, so a network policy called `cyan-np-cka28-trb` has been created in the **same namespace** to apply some restrictions on this pod.

Two other pods called `cyan-white-cka28-trb` and `cyan-black-cka28-trb` are also running in the `default` namespace.

The nginx-based app running on the `cyan-pod-cka28-trb` pod is exposed internally on the default nginx port (`80`).

Expectation: This app should only be accessible from the `cyan-white-cka28-trb` pod.

Problem: This app is not accessible from anywhere.

Troubleshoot this issue and fix the connectivity as per the requirement listed above.

Note: You can exec into `cyan-white-cka28-trb` and `cyan-black-cka28-trb` pods and test connectivity using the **curl** utility.

You may update the network policy, but make sure it is not deleted from the `cyan-ns-cka28-trb` namespace.

```bash
cluster1-controlplane ~ ➜  k get po,netpol,svc -n cyan-ns-cka28-trb 
NAME                     READY   STATUS    RESTARTS   AGE
pod/cyan-pod-cka28-trb   1/1     Running   0          2m30s

NAME                                                POD-SELECTOR             AGE
networkpolicy.networking.k8s.io/cyan-np-cka28-trb   app=cyan-app-cka28-trb   2m28s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/cyan-svc-cka28-trb   ClusterIP   172.20.64.203   <none>        80/TCP    2m29s

cluster1-controlplane ~ ➜  k get po --show-labels 
NAME                                          READY   STATUS    RESTARTS      AGE     LABELS
cyan-black-cka28-trb                          1/1     Running   0             4m2s    app=cyan-black-cka28-trb
cyan-white-cka28-trb                          1/1     Running   0             4m3s    app=cyan-white-cka28-trb

cluster1-controlplane ~ ➜  k get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   34m

cluster1-controlplane ~ ➜  k get netpol -n cyan-ns-cka28-trb 
NAME                POD-SELECTOR             AGE
cyan-np-cka28-trb   app=cyan-app-cka28-trb   12m

cluster1-controlplane ~ ➜  k get netpol -n cyan-ns-cka28-trb -o yaml
apiVersion: v1
items:
- apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    creationTimestamp: "2025-09-14T16:00:48Z"
    generation: 1
    name: cyan-np-cka28-trb
    namespace: cyan-ns-cka28-trb
    resourceVersion: "4379"
    uid: 0786691c-3faa-479b-b2e6-6bcca2e5e4f3
  spec:
    egress:
    - ports:
      - port: 8080
        protocol: TCP
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: default
      ports:
      - port: 8080
        protocol: TCP
    podSelector:
      matchLabels:
        app: cyan-app-cka28-trb
    policyTypes:
    - Ingress
    - Egress
kind: List
metadata:
  resourceVersion: ""

cluster1-controlplane ~ ✖ k edit netpol -n cyan-ns-cka28-trb 
networkpolicy.networking.k8s.io/cyan-np-cka28-trb edited

cluster1-controlplane ~ ➜  k -n default exec -it cyan-white-cka28-trb -- curl -sI cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local
HTTP/1.1 200 OK
Server: nginx/1.14.2
Date: Sun, 14 Sep 2025 16:17:48 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 04 Dec 2018 14:44:49 GMT
Connection: keep-alive
ETag: "5c0692e1-264"
Accept-Ranges: bytes


cluster1-controlplane ~ ➜  k -n default exec -it cyan-black-cka28-trb -- curl -sI cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local
^Ccommand terminated with exit code 130

cluster1-controlplane ~ ✖ k get netpol -n cyan-ns-cka28-trb -o yaml
apiVersion: v1
items:
- apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    creationTimestamp: "2025-09-14T16:00:48Z"
    generation: 3
    name: cyan-np-cka28-trb
    namespace: cyan-ns-cka28-trb
    resourceVersion: "5016"
    uid: 0786691c-3faa-479b-b2e6-6bcca2e5e4f3
  spec:
    egress:
    - ports:
      - port: 8080
        protocol: TCP
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: default
        podSelector:                                # added
          matchLabels:
            app: cyan-white-cka28-trb
      ports:
      - port: 80                                    # changed from 8080 to 80
        protocol: TCP
    podSelector:
      matchLabels:
        app: cyan-app-cka28-trb
    policyTypes:
    - Ingress
    - Egress
kind: List
metadata:
  resourceVersion: ""

cluster1-controlplane ~ ➜  

```

Got it 👍 Let’s carefully troubleshoot step by step.

---

### 🔎 Problem Analysis

1. **Pod & Service Setup**

   * Pod: `cyan-pod-cka28-trb` (nginx-based, listening on port **80**)
   * Service: `cyan-svc-cka28-trb` → Port **80/TCP**, targets the pod.

2. **Other Pods**

   * `cyan-white-cka28-trb` (default namespace) ✅ should access nginx.
   * `cyan-black-cka28-trb` (default namespace) ❌ should be denied.

   **Issues:**

   * Only **port 8080** is allowed, but nginx runs on **80**.
   * Ingress allows *all pods* in `default` namespace → too permissive.
   * Egress is restricted to port 8080 only, blocking DNS, kube API, etc.

### ✅ Fix Plan

We need:

* Allow ingress **only from `cyan-white-cka28-trb` pod** in `default` namespace on port **80**.
* Deny traffic from `cyan-black-cka28-trb`.

### 🔬 Test After Applying

```bash
# From cyan-white pod
k -n default exec -it cyan-white-cka28-trb -- curl -sI cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local
# Should return 200 OK

# From cyan-black pod
k -n default exec -it cyan-black-cka28-trb -- curl -sI cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local
# Should hang/deny
```

--

Got it ✅ Let’s anchor back to the **exam question** itself:

> *Expectation: This app should only be accessible from the cyan-white-cka28-trb pod.*
> *Problem: This app is not accessible from anywhere.*
> *You may update the network policy, but make sure it is not deleted.*

That means the **grading script** will only check:

* Can `cyan-white-cka28-trb` access the nginx service on port **80**? ✅
* Is `cyan-black-cka28-trb` denied? ✅

You already achieved both with your edited **Ingress rule**.
The question never mentioned fixing or tightening **Egress**.

### 🎯 Answer for the exam

* **No, you don’t need to change the egress section** for this task.
* The requirement is **only about ingress restrictions**, which you’ve already fixed.
* Leave `egress` as-is unless the exam explicitly asks for it.

---

## Q13

In Namespace `venus` you'll find two Deployments named `api` and `frontend`. Both Deployments are exposed inside the cluster using Services. Create a NetworkPolicy named `np1` which **restricts outgoing tcp connections from Deployment frontend** and **only allows those going to Deployment api**. Make sure the NetworkPolicy still allows outgoing traffic on UDP/TCP ports 53 for DNS resolution.

**Test using:** `wget www.google.com` and `wget api:222` from a Pod of Deployment frontend.

Got it ❤️ This is a **classic exam-style NetworkPolicy** question. No worries — I’ll break it down step by step so you understand what’s happening, why we do it, and how to not get confused in the real exam.

## 🚩 The Scenario

* **Namespace:** `venus`
* **Deployments:**

  * `frontend` (our Pod will run from here — egress should be restricted).
  * `api` (only allowed destination for frontend).
* Both are exposed by **Services**.
* We need a **NetworkPolicy (np1)** that:

  1. Blocks *all outgoing traffic* from `frontend`.
  2. Only allows:

     * Outgoing traffic **to `api` Deployment**.
     * Outgoing traffic **to DNS (tcp/udp 53)**.

## 🧠 Mental Model for the Exam

Think of NetworkPolicies as **firewall rules at the Pod level**:

* `podSelector`: **Who the rule applies to** (our `frontend` Pods).
* `policyTypes`: Direction of rules — here we need **Egress**.
* `egress`: **What traffic is allowed** (everything else is denied).

**Important:** In Kubernetes, when you define *any* `egress` in a NetworkPolicy, everything else is denied by default (so you must explicitly allow DNS, API, etc.).

## ✅ Solution YAML

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np1
  namespace: venus
spec:
  podSelector:
    matchLabels:
      id: frontend    # apply to frontend Deployment Pods
  policyTypes:
  - Egress
  egress:
  # 1) Allow traffic to API Pods
  - to:
    - podSelector:
        matchLabels:
          id: api     # target API Deployment Pods
    ports:
    - protocol: TCP
      port: 2222       # match API service/container port
  # 2) Allow DNS traffic (UDP/TCP 53)
  - to:
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

---
