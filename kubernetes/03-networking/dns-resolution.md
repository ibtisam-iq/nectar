# Kubernetes DNS Resolution — Structured Notes (with Hands‑On)

These notes combine **clear theory** with the **exact commands and outputs** you practiced, organized as step‑by‑step “methods.” Use them directly in your Nectar repo.

---

## Why DNS matters in Kubernetes

* Pods are **ephemeral**; their IPs change.
* Services provide **stable names** and **load balancing** for pods.
* Kubernetes’ DNS (CoreDNS) lets you resolve names → IPs so workloads can discover each other reliably.

---

## Quick Concepts Map

* **Service FQDN format:**

  ```
  <service>.<namespace>.svc.cluster.local
  ```
* **Pod FQDN format (direct pod record):**

  ```
  <pod-ip-with-dashes>.<namespace>.pod.cluster.local
  ```
* **Namespace rule (selection):** A Service **only selects pods within its own namespace** (via label selectors).
* **Client access:** A client pod in **any** namespace can access a Service in **another** namespace using the Service’s **FQDN**.
* **Search paths:** Inside a pod, short names are expanded using `/etc/resolv.conf` search suffixes (e.g., `<ns>.svc.cluster.local`, `svc.cluster.local`, `cluster.local`).

> **Your Question → Answer**
>
> * **Q:** *Namespace of what — the service’s ns or the target pod’s ns in the FQDN?*
>   **A:** It’s the **Service’s namespace** in the FQDN.
>
> * **Q:** *Must a Service be in the same namespace as the pods it fronts?*
>   **A:** **Yes.** Service selectors only match pods **in the same namespace**.
>
> * **Q:** *Are “same‑ns” and “cross‑ns” two different ways?*
>   **A:** **Yes.** Case 1 uses a short name within the same ns; Case 2 uses a full FQDN across namespaces.
>
> * **Q:** *But you said Service and pods must be in the same ns — then how can other namespaces reach it?*
>   **A:** Selection is same‑ns only; **clients** from other namespaces can **still access** the Service via its **FQDN**.

---

## Lab Setup Used (from your session)

```bash
# 1) Create a namespace
kubectl create ns amor

# 2) Run an nginx pod and expose it as a Service in the same namespace
kubectl run nginx -n amor --image nginx --port 80 --expose

# 3) Inspect resources
kubectl get all -n amor -o wide
# Example outputs seen:
# pod/nginx   IP=172.17.3.2
# service/nginx   ClusterIP=172.20.173.104  PORT=80/TCP  SELECTOR=run=nginx

# 4) Launch a test pod (BusyBox) in the DEFAULT namespace for cross‑ns tests
kubectl run test-pod --image busybox --restart=Never -it -- sh
```

---

## Method 1 — **Same Namespace Resolution** (short name works)

**Goal:** From a client pod **in `amor`**, resolve the `nginx` Service **by short name**.

```bash
# Start a test shell in the SAME namespace (amor)
kubectl run dns-test -n amor --image=busybox:1.28 --restart=Never -it -- sh

# Inside the shell:
nslookup nginx
# Expected: resolves to the Service ClusterIP (e.g., 172.20.173.104)

# You can also verify your search suffixes:
cat /etc/resolv.conf
# Look for lines like:
# search amor.svc.cluster.local svc.cluster.local cluster.local
```

**Why this works:** The short name `nginx` is expanded to `nginx.amor.svc.cluster.local` because the pod’s search path includes its own namespace `amor`.

---

## Method 2 — **Cross‑Namespace Resolution** (use FQDN)

**Goal:** From a client pod **in `default`**, resolve the `nginx` Service in `amor`.

**What you did and saw:**

```bash
# Inside the BusyBox shell (namespace: default)
nslookup nginx
# Result: NXDOMAIN (because it tries nginx.default.svc.cluster.local first)

nslookup nginx.amor.svc.cluster.local
# Result: Name: nginx.amor.svc.cluster.local
#         Address: 172.20.173.104   <-- Service ClusterIP
```

**Why the first query failed:** Your client pod is in `default`, so the short name `nginx` is expanded to `nginx.default.svc.cluster.local`, which doesn’t exist. Supplying the **FQDN** points to the Service in `amor`.

> **Pitfall you hit:**
> The short name does **not** jump namespaces. Always include `<service>.<namespace>.svc.cluster.local` when crossing namespaces.

---

## Method 3 — **Direct Pod DNS Record** (bypassing the Service)

**Goal:** Resolve a **pod’s** DNS name using the pod‑record format.

**What you did and saw:**

```bash
# Given the pod IP from `kubectl get pods -n amor -o wide` was 172.17.3.2
nslookup 172-17-3-2.amor.pod.cluster.local
# Result: Name: 172-17-3-2.amor.pod.cluster.local
#         Address: 172.17.3.2
```

**Important notes:**

* This works using CoreDNS’s pod records, but pod IPs are **ephemeral**.
* Prefer Service DNS for stability and load balancing.
* If you need **stable per‑pod** names (e.g., StatefulSets), use a **Headless Service** (`spec.clusterIP: None`).

> **Pitfall you hit:**
> `nslookup 172-17-3-2.amor.pod.cluster.local:80` failed. DNS names **never include ports**. Use ports only with the client program (e.g., `wget <name>:80`).

---

## Optional Verification — Check HTTP reachability (after DNS resolves)

DNS success ≠ network success. After you resolve a name with `nslookup`, verify actual connectivity if needed:

```bash
# From your session:
wget nginx.amor.svc.cluster.local
# Saved: index.html (HTTP 200 from nginx)
```

*(You chose `wget`. Avoid `curl` here if you want to keep tooling consistent.)*

---

## Troubleshooting Cheatsheet

* **NXDOMAIN on short name across namespaces** → Use the **FQDN** (`<svc>.<ns>.svc.cluster.local`).
* **No resolution at all** → Check CoreDNS pods:

  ```bash
  kubectl -n kube-system get pods -l k8s-app=kube-dns
  ```
* **Wrong namespace in FQDN** → Remember the FQDN uses the **Service’s namespace**.
* **For Pod DNS** → Ensure the dashed IP form is exact: `172-17-3-2.<ns>.pod.cluster.local`.
* **Ports in DNS** → Never put `:80` in `nslookup`. Use ports only with client commands (`wget`, app config, etc.).
* **Confirm search domains** → Inside the client pod: `cat /etc/resolv.conf`.

---

## Copy‑Paste: Full Demo (as you ran it)

```bash
# Create ns + app + service
kubectl create ns amor
kubectl run nginx -n amor --image nginx --port 80 --expose
kubectl get all -n amor -o wide

# Cross-namespace client (default)
kubectl run test-pod --image busybox --restart=Never -it -- sh
# In the shell:
nslookup nginx                              # → NXDOMAIN (default ns)
nslookup nginx.amor.svc.cluster.local       # → 172.20.173.104 (ClusterIP)

# Optional reachability check
wget nginx.amor.svc.cluster.local           # → index.html saved

# Pod DNS record
# First, get pod IP:
# kubectl get pod -n amor -o wide
# Example IP: 172.17.3.2
nslookup 172-17-3-2.amor.pod.cluster.local  # → 172.17.3.2
```

---

## Key Takeaways (1‑minute recap)

* Use **Service DNS** for normal traffic: `<svc>.<ns>.svc.cluster.local`.
* **Same ns**: short name works; **cross ns**: use FQDN.
* Service selectors are **same‑namespace only**.
* **Pod DNS** exists but is **unstable**; use a **Headless Service** for stable per‑pod names.
* Don’t include ports in DNS queries; ports belong to the transport/client.

---

```bash
controlplane ~ ➜ k create ns amor namespace/amor created
controlplane ~ ➜ k run nginx -n amor --image nginx --port 80 --expose
service/nginx created
pod/nginx created
controlplane ~ ➜ k get all -n amor
NAME READY STATUS RESTARTS AGE
pod/nginx 1/1 Running 0 41s
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
service/nginx ClusterIP 172.20.173.104 <none> 80/TCP 41s
controlplane ~ ➜ k get all -n amor -o wide
NAME READY STATUS RESTARTS AGE IP NODE NOMINATED NODE READINESS GATES
pod/nginx 1/1 Running 0 55s 172.17.3.2 node02 <none> <none>
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE SELECTOR
service/nginx ClusterIP 172.20.173.104 <none> 80/TCP 55s run=nginx
controlplane ~ ➜ k run test-pod --image busybox --restart=Never -it -- sh
If you don't see a command prompt, try pressing enter. /

# nslookup nginx
Server: 172.20.0.10
Address: 172.20.0.10:53
** server can't find nginx.jjmk3mhvn4fa6vbk.svc.cluster.local: NXDOMAIN

# nslookup nginx.amor.svc.cluster.local
Server: 172.20.0.10
Address: 172.20.0.10:53
Name: nginx.amor.svc.cluster.local
Address: 172.20.173.104 /

# wget nginx.amor.svc.cluster.local
Connecting to nginx.amor.svc.cluster.local (172.20.173.104:80)
saving to 'index.html' index.html 100% |***************************************************************************************************************************| 615 0:00:00 ETA 'index.html' saved /

# wget 172-17-3-2.amor.pod.cluster.local
Connecting to 172-17-3-2.amor.pod.cluster.local (172.17.3.2:80)
wget: can't open 'index.html': File exists /

# wget 172-17-3-2.amor.pod.cluster.local:80
Connecting to 172-17-3-2.amor.pod.cluster.local:80 (172.17.3.2:80)
wget: can't open 'index.html': File exists /

# nslookup 172-17-3-2.amor.pod.cluster.local:80
Server: 172.20.0.10 Address: 172.20.0.10:53
** server can't find 172-17-3-2.amor.pod.cluster.local:80:

# nslookup 172-17-3-2.amor.pod.cluster.local
Server: 172.20.0.10
Address: 172.20.0.10:53
Name: 172-17-3-2.amor.pod.cluster.local
Address: 172.17.3.2 /
#
```
