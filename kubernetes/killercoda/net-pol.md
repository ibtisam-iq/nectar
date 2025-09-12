You are requested to create a network policy named deny-all-svcn that denies all incoming and outgoing traffic to ckad12-svcn namespace.

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

A policy database-ckad-netpol to limit access to database pods only to backend pods.

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

create a NetworkPolicy .i.e. ckad-allow so that only pods with label criteria: allow can access the deployment on port 80 and apply it.

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

We have created a Network Policy netpol-ckad13-svcn that allows traffic only to specific pods and it allows traffic only from pods with specific labels.

Your task is to edit the policy so that it allows traffic from pods with labels access = allowed.

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

We have deployed an application in the ns-new-ckad namespace. We also configured services, namely frontend-ckad-svcn and backend-ckad-svcn.


However, there are some issues:

backend-ckad-svcn is not able to access backend pods

frontend-ckad-svcn is not accessible from backend pods.

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

We have deployed some pods in the namespaces ckad-alpha and ckad-beta.

You need to create a NetworkPolicy named ns-netpol-ckad that will restrict all Pods in Namespace ckad-alpha to only have outgoing traffic to Pods in Namespace ckad-beta . Ingress traffic should not be affected.


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

A new payment service has been introduced. Since it is a sensitive application, it is deployed in its own namespace critical-space. Inspect the resources and service created.


You are requested to make the new application available at /pay. Create an ingress resource named ingress-ckad09-svcn for the payment application to make it available at /pay.

```bash
root@student-node ~ ➜  k get po -n ingress-nginx 
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-6dhz8       0/1     Completed   0          76s
ingress-nginx-admission-patch-pkv5s        0/1     Completed   0          76s
ingress-nginx-controller-68bb49f4f-kkr98   1/1     Running     0          76s

root@student-node ~ ➜  k get svc,po -n critical-space 
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/pay-service   ClusterIP   172.20.122.122   <none>        8282/TCP   103s

NAME                              READY   STATUS    RESTARTS   AGE
pod/webapp-pay-7df499586f-48cxm   1/1     Running   0          103s

root@student-node ~ ➜  k get po -n ingress-nginx ingress-nginx-controller-68bb49f4f-kkr98 -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: ingress-nginx-controller-68bb49f4f-kkr98
  namespace: ingress-nginx
spec:
  containers:
  - args:
    - /nginx-ingress-controller
    - --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
    - --election-id=ingress-controller-leader
    - --watch-ingress-without-class=true
    - --default-backend-service=app-space/default-backend-service        # Notice here
    - --controller-class=k8s.io/ingress-nginx
    - --ingress-class=nginx
    - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
    - --validating-webhook=:8443
    - --validating-webhook-certificate=/usr/local/certificates/cert
    - --validating-webhook-key=/usr/local/certificates/key


root@student-node ~ ➜  k get svc -n app-space 
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
default-backend-service   ClusterIP   172.20.122.209   <none>        80/TCP     7m48s    # present here, that's why controller pod is ruuning
video-service             ClusterIP   172.20.49.211    <none>        8080/TCP   7m48s
wear-service              ClusterIP   172.20.72.245    <none>        8080/TCP   7m48s

root@student-node ~ ➜  k get svc -n critical-space 
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
pay-service   ClusterIP   172.20.122.122   <none>        8282/TCP   8m13s

root@student-node ~ ➜  vi 11.yaml

root@student-node ~ ➜  k apply -f 11.yaml 
ingress.networking.k8s.io/ingress-ckad09-svcn created

root@student-node ~ ➜  k describe ingress -n critical-space 
Name:             ingress-ckad09-svcn
Labels:           <none>
Namespace:        critical-space
Address:          
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /pay   pay-service:8282 (172.17.1.7:8080)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    22s   nginx-ingress-controller  Scheduled for sync

root@student-node ~ ➜  cat 11.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-ckad09-svcn
  namespace: critical-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /pay
        pathType: Prefix
        backend:
          service:
            name: pay-service
            port:
              number: 8282 
```

Exactly ❤️ you’ve done it right.

Let’s read your `kubectl describe ingress` carefully:

```
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /pay   pay-service:8282 (172.17.1.7:8080)
```

### What this means

* **Default backend: `<default>`**
  👉 This just shows that the **Ingress Controller Pod itself** has a global default backend (configured via `--default-backend-service=app-space/default-backend-service`).
  👉 It’s **not coming from your Ingress resource**. Your Ingress does **not** define any `defaultBackend` section — so you’re ✅ safe.

* **Rules**

  * Path `/pay` → `pay-service:8282` (and we can see it’s sending traffic to Pod IP `172.17.1.7:8080` behind the service).
  * That’s exactly what the task wanted.


### Conclusion

Your Ingress **does not contain a backend service definition itself** — it only defines a rule.
The mention of `<default>` is just informational, showing the controller’s global default backend, not part of your YAML.

**Exactly ✅ you got it.**

Let me clear this up for you step by step:

### 1. Where the default backend is set

In your **Ingress Controller Pod args** (`ingress-nginx-controller` in `ingress-nginx` namespace), you have:

```yaml
--default-backend-service=app-space/default-backend-service
```

👉 This means the controller itself will use `default-backend-service` in the **`app-space` namespace** whenever:

* A request doesn’t match any Ingress rule, or
* An Ingress has no rules/paths defined.

### 2. Where your Ingress lives

Your Ingress resource:

* Namespace = `critical-space`
* Rules = only `/pay` → `pay-service:8282`

👉 This Ingress has **no defaultBackend field**, so it never overrides anything.
👉 It only routes requests for `/pay` to `pay-service`.


### 3. How they connect

* **Global default backend** = comes from the controller (in `app-space`).
* **Ingress-specific rules** = come from your Ingress (in `critical-space`).
* They do **not need to be in the same namespace**. The controller doesn’t care; it just knows where to send unmatched traffic globally.

✅ So yes: the default backend service in the controller args belongs to `app-space`, and it does **not** have to match the namespace where you created your Ingress (`critical-space`).

