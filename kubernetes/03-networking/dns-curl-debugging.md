# 🧠 Kubernetes Service Connectivity: `nslookup` vs `curl`

This guide explains the difference between `nslookup` and `curl` when testing Kubernetes Services — what each one checks, when to use which, and how to interpret the results during CKAD/CKA exams.

---

## 🧩 1. The Two Layers of Service Access

When you test a Kubernetes Service from inside a pod, you’re checking **two separate layers**:

| Tool | Layer Tested | Purpose |
|------|---------------|----------|
| `nslookup` | DNS (CoreDNS) | Checks if the Service name resolves to a ClusterIP |
| `curl` | Network + Application | Checks if traffic can reach the Service and the app responds |

---

## ⚙️ 2. Example Commands

### ✅ DNS Test
```bash
nslookup nginx-svc.default.svc.cluster.local
```
**Checks:**
- Can the pod resolve the Service name using CoreDNS?
- Is DNS properly configured in the cluster?

**Example output:**
```
Name:   nginx-svc.default.svc.cluster.local
Address: 10.96.12.101
```
✅ DNS resolution works.

---

### ✅ Application Test
```bash
curl nginx-svc.default:80
```
**Checks:**
- Can the pod reach the Service ClusterIP on port 80?
- Are kube-proxy and service routing working?
- Are backend pods responding?

**Example output (for Nginx):**
```
<html>
<head><title>Welcome to nginx!</title></head>
<body>...</body>
</html>
```
✅ Application reachable and responding.

---

## 🧠 3. Difference in Depth

| Command | What it Tests | What Success Means |
|----------|----------------|--------------------|
| `nslookup svc-name.ns.svc.cluster.local` | CoreDNS DNS resolution | Service name → ClusterIP works |
| `curl svc-name.ns:port` | Network + application path | Service + Pod connectivity works |

### Analogy:
- `nslookup` = finding someone’s phone number 📞
- `curl` = actually calling them and getting a reply 👋

---

## 🧩 4. How Kubernetes Resolves Names

Inside any pod, `/etc/resolv.conf` includes:
```
search ns.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
```

When you type:
```bash
curl amor.amor:80
```
CoreDNS automatically expands it to:
```
amor.amor.svc.cluster.local
```
So you can use short or full DNS forms interchangeably.

---

## 🧰 5. How to Interpret Results in Exams

| `nslookup` Result | `curl` Result | Meaning |
|-------------------|----------------|----------|
| ✅ Works | ✅ Works | Everything is healthy |
| ❌ Fails | ❌ Fails | DNS/CoreDNS issue |
| ✅ Works | ❌ Fails | NetworkPolicy issue / wrong target port / no endpoints |
| ❌ Fails | ✅ Works | Misconfiguration (rare) |

---

## 🧩 6. Example CKAD Workflow

```bash
# Step 1: DNS Resolution Test
kubectl exec testpod -n alpha -- nslookup nginx-svc.alpha.svc.cluster.local

# Step 2: Application Connectivity Test
kubectl exec testpod -n alpha -- curl nginx-svc.alpha:80
```

### Result Meaning:
- Both ✅ → Service fully functional
- nslookup ✅ but curl ❌ → Routing or app issue
- Both ❌ → DNS/CoreDNS issue

---

## ⚡ 7. Common Exam Scenarios

| Exam Prompt | You Should Run | Layer Tested |
|--------------|----------------|---------------|
| “Verify if service name resolves” | `nslookup svc-name.ns.svc.cluster.local` | DNS |
| “Check if the pod can access the service” | `curl svc-name.ns:port` | Application |
| “Service resolves but not reachable” | Both commands | DNS + Network |
| “Pods can’t reach app even though DNS works” | `curl` only | NetworkPolicy or wrong port |

---

## 🧠 8. Flowchart for Debugging

```text
                ┌──────────────────────────┐
                │ Run nslookup             │
                │ (Check DNS resolution)   │
                └────────────┬─────────────┘
                             │
                  ┌───────────┴───────────┐
                  │                       │
               Works ✅               Fails ❌
                  │                       │
        ┌─────────┴─────────┐        ┌────┴─────────┐
        │ Run curl          │        │ Fix DNS/CoreDNS │
        │ (Check app reach) │        │ or Service name │
        └─────────┬─────────┘        └────────────────┘
                  │
          ┌───────┴────────┐
          │                │
        Works ✅         Fails ❌
          │                │
          │     ┌──────────┴───────────┐
          │     │ Check NetworkPolicy  │
          │     │ Ports / Endpoints    │
          │     └──────────────────────┘
```

---

## 🧭 9. Quick Reference Table

| Test Goal | Command | What It Proves |
|------------|----------|----------------|
| Check DNS resolution | `nslookup svc-name.ns.svc.cluster.local` | CoreDNS is resolving names |
| Check Service routing | `curl svc-name.ns:port` | Service forwards traffic correctly |
| Check ClusterIP access | `curl <ClusterIP>:<port>` | Network path works (bypass DNS) |
| Test both layers | Run both commands | Full connectivity verified |

---

## ❤️ 10. Summary (for CKAD Mindset)

| Command | Focus | Layer |
|----------|--------|--------|
| `nslookup` | “Can I find the service?” | DNS (CoreDNS) |
| `curl` | “Can I reach and talk to it?” | Network + App |

**Rule of thumb:**
> 🔹 If `nslookup` fails → DNS problem.  
> 🔹 If `nslookup` works but `curl` fails → NetworkPolicy or wrong port.  
> 🔹 If both work → everything is fine.

