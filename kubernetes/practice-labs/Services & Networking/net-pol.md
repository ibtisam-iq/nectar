
## 🌍 Step 1: Understand how NetworkPolicies “think”

Think of Kubernetes networking like a city:

* **Pods** = houses
* **Traffic (Ingress/Egress)** = people moving in/out of those houses
* **NetworkPolicy** = gatekeeper rules (who can enter or leave)

Now, a **NetworkPolicy never applies globally** — it only applies to **pods selected by `podSelector`** inside that namespace.

So, every NetworkPolicy has a “scope”:
👉 “Which pods am I protecting?” → defined by `.spec.podSelector`.



## ⚙️ Step 2: Identify “which pods” the question is about

Let’s read your question carefully:

> backend-ckad-svcn is not able to access backend pods
> frontend-ckad-svcn is not accessible from backend pods

We’ll decode this sentence slowly.



### 🔹 First clue: “backend-ckad-svcn is not able to access backend pods”

* `backend-ckad-svcn` → is a **Service**.
  A service sends **traffic to pods** that match its selector.
* It says “not able to access backend pods,” meaning:

  * **The backend service’s traffic can’t reach its own backend pods.**
  * That means **something is blocking incoming traffic to backend pods**.
  * Therefore, the issue is about **Ingress to backend pods**.

✅ **Conclusion #1:**
The affected pods are **backend pods**, and the problem is with **Ingress**.



### 🔹 Second clue: “frontend-ckad-svcn is not accessible from backend pods”

This means:

* Backend pods are trying to reach **frontend pods (via frontend service)**.
* But they can’t.
* So the traffic is **leaving backend pods**, going **outward** to frontend pods.
* That’s an **Egress issue** (outgoing connection from backend).

✅ **Conclusion #2:**

* The pods causing the issue: **backend pods**
* The traffic direction: **Egress (outgoing)** toward frontend pods



### 🧭 Step 3: The mental model

| Question to ask yourself                       | If answer is “yes” → | Direction   | `policyTypes` |
| ---------------------------------------------- | -------------------- | ----------- | ------------- |
| “Are we controlling who can reach these pods?” | incoming traffic     | **Ingress** | `Ingress`     |
| “Are we controlling where these pods can go?”  | outgoing traffic     | **Egress**  | `Egress`      |



## 🧩 Step 4: Apply it to your case

| Situation                        | Pods involved | Direction   | Explanation                           |
| -------------------------------- | ------------- | ----------- | ------------------------------------- |
| `backend-svcn` → `backend pods`  | backend pods  | **Ingress** | Service traffic entering backend pods |
| `backend pods` → `frontend-svcn` | backend pods  | **Egress**  | Outgoing connection to frontend pods  |

So, **two NetworkPolicies** are needed:

1. **Allow Ingress to backend pods** from backend service (or from pods with matching labels).
2. **Allow Egress from backend pods** to frontend pods.

Here’s a golden rule 💫

> * **Ingress** = who can talk **TO** me
> * **Egress** = who I can talk **TO**

Or simply:

> “Ingress = In → to me”
> “Egress = Exit → from me”


---

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
root@student-node ~ ➜  k get svc,ep,po -n ns-new-ckad 
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/backend-ckad-svcn    ClusterIP   172.20.124.142   <none>        80/TCP    32s
service/frontend-ckad-svcn   ClusterIP   172.20.36.92     <none>        80/TCP    31s

NAME                           ENDPOINTS        AGE
endpoints/backend-ckad-svcn    <none>           32s
endpoints/frontend-ckad-svcn   172.17.1.17:80   31s

NAME                READY   STATUS    RESTARTS   AGE
pod/backend-pods    1/1     Running   0          32s
pod/frontend-pods   1/1     Running   0          31s
pod/testpod         1/1     Running   0          31s

root@student-node ~ ➜  k get po -n ns-new-ckad --show-labels 
NAME            READY   STATUS    RESTARTS   AGE   LABELS
backend-pods    1/1     Running   0          86s   app=backend,tier=ckad-exam
frontend-pods   1/1     Running   0          85s   app=frontend,tier=ckad-exam
testpod         1/1     Running   0          85s   run=testpod

root@student-node ~ ➜  k describe svc -n ns-new-ckad backend-ckad-svcn 
Name:                     backend-ckad-svcn
Namespace:                ns-new-ckad
Labels:                   app=backend
                          tier=ckad-exam
Annotations:              <none>
Selector:                 app=back-end,tier=ckadexam                # wrong
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.124.142
IPs:                      172.20.124.142
Port:                     http  80/TCP
TargetPort:               80/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  k edit svc -n ns-new-ckad backend-ckad-svcn 
service/backend-ckad-svcn edited

root@student-node ~ ➜  k get ep -n ns-new-ckad 
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                           ENDPOINTS        AGE
endpoints/backend-ckad-svcn    172.17.1.16:80   3m5s                                            # issue 1 is fixed
endpoints/frontend-ckad-svcn   172.17.1.17:80   3m4s

root@student-node ~ ➜  k get netpol -n ns-new-ckad backend-egress-restricted -o yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  creationTimestamp: "2025-10-25T07:44:24Z"
  generation: 1
  name: backend-egress-restricted
  namespace: ns-new-ckad
  resourceVersion: "2521"
  uid: 59dd441d-39b3-406f-b115-4942ee092f45
spec:
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: frontend
          tier: ckad-exam
  podSelector:
    matchLabels:
      app: backend
      tier: ckad-exam
  policyTypes:
  - Egress

root@student-node ~ ➜  k edit netpol -n ns-new-ckad backend-egress-restricted -o yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  creationTimestamp: "2025-10-25T07:44:24Z"
  generation: 2
  name: backend-egress-restricted
  namespace: ns-new-ckad
  resourceVersion: "4348"
  uid: 59dd441d-39b3-406f-b115-4942ee092f45
spec:
  egress:
  - {}                                                        # issue 2 is also fixed
  podSelector:
    matchLabels:
      app: backend
      tier: ckad-exam
  policyTypes:
  - Egress

root@student-node ~ ➜  
```

Absolutely, sweetheart 💙
Let’s write a **complete, exam-style explanation** — from the problem statement to final resolution — as if it were part of your **CKAD learning documentation.**

This will give you full clarity on what was happening, what you were supposed to notice, and *why* the exam’s final manifest was correct.


### 🧩 CKAD Question Breakdown — NetworkPolicy (backend-egress-restricted)



### 🧭 Scenario

In the Kubernetes namespace `ns-new-ckad`, an application is deployed with the following components:

| Resource | Name                 | Labels                                   | Purpose               |
| -------- | -------------------- | ---------------------------------------- | --------------------- |
| Pod      | `backend-pods`       | `app=backend, tier=ckad-exam`            | Backend service pod   |
| Pod      | `frontend-pods`      | `app=frontend, tier=ckad-exam`           | Frontend service pod  |
| Pod      | `testpod`            | `run=testpod`                            | Testing pod           |
| Service  | `backend-ckad-svcn`  | selector: `app=backend, tier=ckad-exam`  | Exposes backend pods  |
| Service  | `frontend-ckad-svcn` | selector: `app=frontend, tier=ckad-exam` | Exposes frontend pods |



### ⚠️ Problem Description

There were **two issues** reported:

1. `backend-ckad-svcn` could not access backend pods
2. `frontend-ckad-svcn` was not accessible from backend pods



### Issue 1 — Backend service not accessing backend pods

**Root cause:**
The `backend-ckad-svcn` Service was using the wrong label selector (`app=back-end, tier=ckadexam`), which did not match the labels on the backend pods (`app=backend, tier=ckad-exam`).

**Fix:**
Edit the Service and correct the label selector:

```bash
kubectl edit svc backend-ckad-svcn -n ns-new-ckad
```

After correction:

```yaml
selector:
  app: backend
  tier: ckad-exam
```

✅ This immediately assigned the proper endpoint:

```
endpoints/backend-ckad-svcn → 172.17.1.16:80
```

Issue #1 was resolved.



### Issue 2 — Frontend service not accessible from backend pods

After fixing the first issue, the second issue remained.

Backend pods still couldn’t reach the frontend service, even though the frontend service and its endpoint (`172.17.1.17:80`) were healthy.

A NetworkPolicy named **`backend-egress-restricted`** was applied in the namespace.
This was the cause of the restriction.



### 📜 Given NetworkPolicy (before fix)

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
  - to:
    - podSelector:
        matchLabels:
          app: frontend
          tier: ckad-exam
```


### 🔍 Deep Analysis

### 1. **Who does this policy apply to?**

The `podSelector` in the `spec` targets:

```yaml
app: backend
tier: ckad-exam
```

→ Therefore, the **backend pods** are the affected ones.



### 2. **Which direction is controlled?**

```yaml
policyTypes:
- Egress
```

→ This NetworkPolicy controls **outgoing (egress)** traffic **from backend pods**.



### 3. **What traffic is allowed?**

```yaml
egress:
- to:
  - podSelector:
      matchLabels:
        app: frontend
        tier: ckad-exam
```

→ This allows traffic **only to pods with app=frontend, tier=ckad-exam**.

Sounds correct… right?

Not exactly.



### 4. **The hidden catch**

Kubernetes Services are **virtual IPs** (ClusterIPs) that don’t have labels.

When the backend pod tries to access the frontend using:

```
curl http://frontend-ckad-svcn:80
```

it’s not directly connecting to the frontend pod IP.

It first talks to:

```
frontend service ClusterIP → 172.20.36.92
```

Then kube-proxy forwards the traffic to the frontend pod IP (172.17.1.17).

So, the traffic path looks like this:

```
backend-pod (172.17.1.16) ──> Service IP (172.20.36.92) ──> frontend-pod (172.17.1.17)
```

But the NetworkPolicy only allowed traffic **to pods with labels**, not to the **Service IP (ClusterIP)**.

Since ClusterIPs don’t have labels, the backend’s egress traffic to 172.20.36.92 was blocked.

That’s why:

* `curl 172.17.1.17:80` → ✅ works
* `curl frontend-ckad-svcn` → ❌ fails



## 🧠 The Real Cause of Issue #2

> The NetworkPolicy restricted backend pods’ egress to only pod labels, blocking access to Service IPs (ClusterIP range).



### ✅ Correct Solution (from exam)

The exam’s solution simplified the policy to allow **all egress traffic**, effectively removing the restriction.

### ✅ Fixed Manifest

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
  - {}
```



### 🧩 Why this Works

Let’s interpret line by line:

### 1️⃣ `policyTypes: [Egress]`

Means:
We’re controlling **outgoing** connections from backend pods.

### 2️⃣ `egress: - {}`

The `{}` represents an **empty object** (no restrictions).
So this means:

> “Allow egress to all IPs, all ports, and all namespaces.”

This is equivalent to:

```yaml
egress:
- to:
  - namespaceSelector: {}
    podSelector: {}
```

It effectively removes any limitation on outgoing traffic.

Thus, the backend pod can once again:
✅ Access the frontend service (ClusterIP)
✅ Resolve DNS
✅ Communicate freely within the cluster



### 💬 Why not delete the policy?

Because in CKAD, you usually **can’t delete exam resources** — you must fix the existing one.

By changing `egress: - to:` → `egress: - {}`, you make the policy **logically allow everything**, while keeping it defined in the cluster.



### ⚙️ Verification

From the `backend-pods`:

```bash
kubectl exec -n ns-new-ckad backend-pods -- curl -sI http://frontend-ckad-svcn
```

✅ Expected output:

```
HTTP/1.1 200 OK
```

Frontend service is accessible again.



### 📘 Final Understanding

| Concept                 | Meaning                                                                           |
| ----------------------- | --------------------------------------------------------------------------------- |
| `policyTypes: [Egress]` | Only outgoing traffic from selected pods is controlled                            |
| `egress: []`            | Denies all egress traffic                                                         |
| `egress: - {}`          | Allows all egress traffic (unrestricted)                                          |
| Service IPs (ClusterIP) | Have **no labels**, so cannot be matched by `podSelector`                         |
| Exam purpose            | To test understanding of egress isolation and the `{}` syntax meaning “allow all” |


### 🧠 Final Summary (for your notes)

> * **Who:** Policy applies to backend pods
> * **What:** Egress was restricted
> * **Symptom:** Backend pods couldn’t access frontend service
> * **Cause:** Egress limited to pod labels (no Service IP access)
> * **Fix:** Allow unrestricted egress using `- {}`
> * **Lesson:** `{}` inside `egress` or `ingress` means “allow all,”
>   while empty list (`[]`) means “deny all.”

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

## Q14

We have already deployed:

A pod named `secure-pod`
A service named `secure-service` that targets this pod
Currently, both incoming and outgoing network connections to/from secure-pod are failing.

Your task is to troubleshoot and fix the issue so that:

Incoming connections from the pod `webapp-color` to `secure-pod` are successful.

```bash
controlplane ~ ➜  k get po --show-labels 
NAME           READY   STATUS    RESTARTS   AGE    LABELS
secure-pod     1/1     Running   0          80s    run=secure-pod
webapp-color   1/1     Running   0          104s   name=webapp-color

controlplane ~ ➜  k describe networkpolicies.networking.k8s.io default-deny 
Name:         default-deny
Namespace:    default
Created on:   2025-10-06 12:08:13 +0000 UTC
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Not affecting egress traffic
  Policy Types: Ingress

controlplane ~ ➜  k get -o yaml networkpolicies.networking.k8s.io default-deny 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  creationTimestamp: "2025-10-06T12:08:13Z"
  generation: 1
  name: default-deny
  namespace: default
  resourceVersion: "2192"
  uid: 64b77884-8b8e-449c-86f5-e8939137a175
spec:
  podSelector: {}
  policyTypes:
  - Ingress

controlplane ~ ✖ k get po,ep,svc
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME               READY   STATUS    RESTARTS   AGE
pod/secure-pod     1/1     Running   0          5m11s
pod/webapp-color   1/1     Running   0          5m35s

NAME                       ENDPOINTS             AGE
endpoints/kubernetes       192.168.56.139:6443   25m
endpoints/secure-service   172.17.0.8:80         5m11s

NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/kubernetes       ClusterIP   172.20.0.1     <none>        443/TCP   25m
service/secure-service   ClusterIP   172.20.62.30   <none>        80/TCP    5m11s

controlplane ~ ➜  k edit -o yaml networkpolicies.networking.k8s.io default-deny
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  creationTimestamp: "2025-10-06T12:08:13Z"
  generation: 3
  name: default-deny
  namespace: default
  resourceVersion: "2983"
  uid: 64b77884-8b8e-449c-86f5-e8939137a175
spec:
  ingress:
  - from:
    - podSelector:
        matchLabels:
          name: webapp-color
    ports:
    - port: 80
      protocol: TCP
  podSelector:
    matchLabels:
      run: secure-pod
  policyTypes:
  - Ingress

controlplane ~ ➜  k exec webapp-color -it -- sh
/opt # secure-service.default.svc.cluster.local
sh: secure-service.default.svc.cluster.local: not found
/opt # nslookup secure-service.default.svc.cluster.local
nslookup: can't resolve '(null)': Name does not resolve

Name:      secure-service.default.svc.cluster.local
Address 1: 172.20.62.30 secure-service.default.svc.cluster.local
/opt # nc -v -z -w 5 secure-service 80
secure-service (172.20.62.30:80) open
/opt # exit
```

---

## Q15

```bash
controlplane ~ ➜  ls
deny-all.yaml  deploy.yaml  netpol-1.yaml  netpol-2.yaml  netpol-3.yaml

controlplane ~ ➜  cat deploy.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-checker
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: frontend
    spec:
      containers:
        - name: checker
          image:  kubernetesway/mysql-connection-checker
          env:
            - name: MYSQL_HOST
              value: mysql-service.backend.svc.cluster.local
            - name: MYSQL_PORT
              value: '3306'
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: mysql
          image: mysql:8
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: rootpassword
            - name: MYSQL_DATABASE
              value: mydb
            - name: MYSQL_USER
              value: myuser
            - name: MYSQL_PASSWORD
              value: mypassword
          ports:
            - containerPort: 3306
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-persistent-storage
          emptyDir: {}  # Replace with a PVC in production

controlplane ~ ➜  cat deny-all.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: frontend
spec:
  podSelector: {}  # Selects all pods in the namespace
  policyTypes:
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: backend
spec:
  podSelector: {}  # Selects all pods in the namespace
  policyTypes:
    - Ingress
---
controlplane ~ ➜  cat netpol-1.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-from-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress

  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
      
      ports:
        - protocol: TCP
          port: 3306

controlplane ~ ➜  cat netpol-2.yaml               # this is the right one, the least priviledge
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 3306

controlplane ~ ➜  cat netpol-3.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-nothing
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress: []   

controlplane ~ ➜  vi egress-to-backend.yaml 

controlplane ~ ➜  cat egress-to-backend.yaml   # Newly deployed, although backend is now listening incoming, but frontend is blocking outgoing 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-to-backend
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
          podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 3306
    - ports:
        - protocol: UDP
          port: 53

controlplane ~ ➜  k create ns frontend
namespace/frontend created

controlplane ~ ➜  k create ns backend
namespace/backend created

controlplane ~ ➜  k apply -f deny-all.yaml -f netpol-2.yaml -f egress-to-backend.yaml 
networkpolicy.networking.k8s.io/deny-all-egress created
networkpolicy.networking.k8s.io/deny-all-ingress created
networkpolicy.networking.k8s.io/allow-frontend-to-backend created
networkpolicy.networking.k8s.io/egress-to-backend created

controlplane ~ ➜  k apply -f deploy.yaml 
deployment.apps/mysql-checker created
service/mysql-service created
deployment.apps/mysql created

controlplane ~ ➜  k get po -n frontend 
NAME                             READY   STATUS   RESTARTS      AGE
mysql-checker-8674b5755f-46p2w   0/1     Error    1 (12s ago)   21s

controlplane ~ ➜  k get po -n frontend 
NAME                             READY   STATUS   RESTARTS      AGE
mysql-checker-8674b5755f-46p2w   0/1     Error    2 (24s ago)   39s

controlplane ~ ➜  k get po -n backend 
NAME                     READY   STATUS    RESTARTS   AGE
mysql-84f67f9849-f4q85   1/1     Running   0          62s

controlplane ~ ➜  k logs -n frontend mysql-checker-8674b5755f-46p2w 
Checking connection to mysql-service.backend.svc.cluster.local:3306...
mysql-service.backend.svc.cluster.local (172.20.68.4:3306) open
✅ Successfully connected to mysql-service.backend.svc.cluster.local:3306

controlplane ~ ➜  k get po -n frontend 
NAME                             READY   STATUS    RESTARTS      AGE
mysql-checker-8674b5755f-46p2w   1/1     Running   3 (66s ago)   97s

controlplane ~ ➜  k get po -n frontend 
NAME                             READY   STATUS    RESTARTS      AGE
mysql-checker-8674b5755f-46p2w   1/1     Running   3 (10m ago)   10m

controlplane ~ ➜  k exec -it -n frontend mysql-checker-8674b5755f-46p2w -- nc -vz mysql-service.backend.svc.cluster.local 3306
mysql-service.backend.svc.cluster.local (172.20.68.4:3306) open
```

--

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-to-backend
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
          podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 3306
    - ports:
        - protocol: UDP
          port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 3306
```
