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
controlplane ~ ➜  k get svc
NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   172.20.0.1     <none>        443/TCP   36m
service/my-nginx     ClusterIP   172.20.195.2   <none>        80/TCP    42s

controlplane ~ ➜  k get po -o wide
NAME       READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
my-nginx   1/1     Running   0          52s   172.17.2.3   node02   <none>           <none>

controlplane ~ ➜  curl http//:172.17.2.3:80
curl: (6) Could not resolve host: http

controlplane ~ ✖ curl http://172.17.2.3:80                        # 1) Accessing via pod ip directly
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>

controlplane ~ ➜  curl http://172.20.195.2:80                    # 2) Accessing via service ip
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
-----------------------------------------------------------------
controlplane ~ ➜  k port-forward deployment.apps/abc 7070:80    # 3) Port-forwarding (just ignore, another example)
Forwarding from 127.0.0.1:7070 -> 80
Forwarding from [::1]:7070 -> 80
Handling connection for 7070
Handling connection for 7070

controlplane ~ ➜  curl http://localhost:7070/
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
------------------------------------------------------------------
controlplane ~ ➜  k run test --image busybox --restart=Never --rm -it -- sh
If you don't see a command prompt, try pressing enter.

/ # wget my-nginx                                                              # service name
Connecting to my-nginx (172.20.195.2:80)
saving to 'index.html'
index.html           100% |***************************************************************************************************************************|   615  0:00:00 ETA
'index.html' saved

/ # nslookup my-nginx.default.svc.cluster.local                                # service name (provide full adddress)
Server:         172.20.0.10
Address:        172.20.0.10:53

Name:   my-nginx.default.svc.cluster.local
Address: 172.20.195.2


/ # nslookup 172-17-2-3.default.pod.cluster.local                            # pod-ip
Server:         172.20.0.10
Address:        172.20.0.10:53


Name:   172-17-2-3.default.pod.cluster.local
Address: 172.17.2.3

/ # wget 172-17-2-3.default.pod.cluster.local                                # pod-ip
Connecting to 172-17-2-3.default.pod.cluster.local (172.17.2.3:80)
wget: can't open 'index.html': File exists

/ # wget --spider http://172-17-2-3.default.pod.cluster.local
Connecting to 172-17-2-3.default.pod.cluster.local (172.17.2.3:80)
remote file exists

/ # wget -qO- http://172-17-2-3.default.pod.cluster.local
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
/ # 
```

---

I see what’s happening here 👍

Let’s break it down:

### 🔎 Step 1: Your `nslookup` output

```bash
/ # nslookup 172-17-2-3.default.pod.cluster.local
Server:         172.20.0.10
Address:        172.20.0.10:53

Name:   172-17-2-3.default.pod.cluster.local
Address: 172.17.2.3
```

✅ This shows that **ClusterDNS (`coredns`) correctly resolved** the Pod DNS name into its Pod IP `172.17.2.3`.

### 🔎 Step 2: Your `wget` output

```bash
/ # wget 172-17-2-3.default.pod.cluster.local
Connecting to 172-17-2-3.default.pod.cluster.local (172.17.2.3:80)
wget: can't open 'index.html': File exists
```

* `wget` tries to **save the response into `index.html`** by default.
* The error `File exists` means that there is already a file named `index.html` in your current directory inside the container/pod.
* So, this is **not a networking problem** — your Pod is reachable, but `wget` just refuses to overwrite the file.

### ✅ How to fix it

You have several options:

1. **Overwrite the existing file**

   ```bash
   wget -O index.html http://172-17-2-3.default.pod.cluster.local
   ```

   (forces saving to `index.html` again)

2. **Save with a different filename**

   ```bash
   wget -O pod.html http://172-17-2-3.default.pod.cluster.local
   ```

3. **Just test connectivity without saving**

   ```bash
   wget --spider http://172-17-2-3.default.pod.cluster.local
   ```

   (checks if it’s reachable but doesn’t save the file)

4. **See what’s inside the response**

   ```bash
   wget -qO- http://172-17-2-3.default.pod.cluster.local
   ```

   (prints response to stdout)

---
