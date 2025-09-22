# 📘 Kubernetes Pod `hostname` and `subdomain`

In Kubernetes, every Pod gets a **hostname** and can optionally be assigned a **subdomain**. These fields are part of the Pod spec and directly influence **Pod DNS resolution**.

---

## 🔑 1. Default Behavior

* By default, a Pod’s **hostname** = the Pod’s `metadata.name`.
* The Pod is reachable only via its **IP address** (not stable, changes on restart).
* The Service (if created) provides a stable DNS name.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-1
spec:
  containers:
  - name: nginx
    image: nginx:1-alpine
```

Inside the Pod:

```bash
hostname   # output: web-1
```

DNS available:

* Service FQDN (if exposed):

  ```
  <service>.<namespace>.svc.cluster.local
  ```
* No Pod-level DNS entry exists.

---

## 🔑 2. Setting `spec.hostname`

You can override the default Pod hostname with `spec.hostname`.

```yaml
spec:
  hostname: custom-host
```

Effect:

* Inside the Pod → `hostname = custom-host`.
* **No DNS entry created** (still only Service DNS is usable).

Use case:

* When you need a specific hostname inside the container (for legacy apps, logging, monitoring).

---

## 🔑 3. Adding `spec.subdomain`

When `spec.subdomain` is set along with `hostname`, Kubernetes creates a **Pod-specific DNS entry** under the Service domain.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: section100
spec:
  hostname: section100
  subdomain: section
  containers:
  - name: nginx
    image: nginx:1-alpine
```

And you have a Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: section
spec:
  clusterIP: None     # Headless Service
  selector:
    app: your-app
  ports:
  - port: 80
```

Now, the Pod is resolvable at:

```
<section-hostname>.<subdomain>.<namespace>.svc.cluster.local
```

Example:

```
section100.section.lima-workload.svc.cluster.local
```

This DNS name **follows the Pod** even if its IP changes.

---

## 🔑 4. Service DNS

Every Service always gets its own stable DNS entry, independent of `hostname`/`subdomain`:

```
<service>.<namespace>.svc.cluster.local
```

Example:

```
section.lima-workload.svc.cluster.local
```

This resolves to the **Service ClusterIP** (for normal Services) or to **Pod IPs directly** (for Headless Services).

---

## 📌 Scenarios Summary

| Case                                     | `hostname` | `subdomain` | Service Type | Pod FQDN                                      | Service FQDN                           |
| ---------------------------------------- | ---------- | ----------- | ------------ | --------------------------------------------- | -------------------------------------- |
| Default                                  | Pod name   | none        | ClusterIP    | ❌ Not available                               | ✅ `<svc>.<ns>.svc.cluster.local`       |
| Custom hostname only                     | custom     | none        | ClusterIP    | ❌ Not available                               | ✅                                      |
| Hostname + Subdomain (ClusterIP Service) | section100 | section     | ClusterIP    | ✅ `section100.section.<ns>.svc.cluster.local` | ✅                                      |
| Hostname + Subdomain (Headless Service)  | section100 | section     | Headless     | ✅ Pod FQDN resolves directly to Pod IP        | ✅ Service FQDN resolves to all Pod IPs |

---

## 🔑 5. When to Use

* **`hostname` only**:
  Use when the app inside the Pod expects a particular hostname but doesn’t need DNS resolution.

* **`hostname` + `subdomain`**:
  Use with a Service (usually **Headless**) when you need **stable per-Pod DNS**.
  Example use cases:

  * StatefulSets (e.g., databases like Cassandra, Kafka, MongoDB).
  * When Pods must talk to each other by stable names instead of changing IPs.

---

## ✅ Key Formula for Pod FQDN

When both `hostname` and `subdomain` are set:

```
<hostname>.<subdomain>.<namespace>.svc.cluster.local
```

When only Service exists:

```
<service>.<namespace>.svc.cluster.local
```

---

## 🔍 Quick DNS Test

Deploy a temporary Pod:

```bash
kubectl run dns-test --image=busybox:1.28 -it --restart=Never -- nslookup <fqdn>
```

Example:

```bash
nslookup section100.section.lima-workload.svc.cluster.local
```

---

✨ **In summary**:

* `hostname` = container’s hostname.
* `subdomain` + Service = stable Pod-level DNS.
* Service DNS always exists, Pod DNS only exists if you set both.
* This is critical in **StatefulSets and Headless Services** where Pods must be uniquely addressable.

---
