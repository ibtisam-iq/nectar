# ⚡ cURL --resolve vs -H "Host:" — Practical DNS Tricks for DevOps

In DevOps, we often need to test services **before DNS propagation**, **behind ingress controllers**, or on **custom ports**.  
This is where `curl --resolve` becomes your secret weapon — it simulates DNS entries *without modifying `/etc/hosts`.*

---

<details>
<summary><b>📑 Table of Contents</b></summary>

1. [🧩 The Problem](#-the-problem)
2. [⚙️ The Solution — `--resolve`](#️-the-solution---resolve)
3. [⚖️ Comparison — `--resolve` vs `-H "Host:"`](#️-comparison---resolve-vs--h-host)
4. [🌐 DNS Resolution Flow](#-dns-resolution-flow)
5. [☸️ Real-World Kubernetes Example](#️-realworld-kubernetes-example)
6. [🔐 HTTPS & SNI Behavior](#-https--sni-behavior)
7. [🧰 DevOps Advantages](#-devops-advantages)
8. [🧩 Summary Cheat Sheet](#-summary-cheat-sheet)
9. [⚡ Quick Recap](#-quick-recap)
10. [👨‍💻 Author Meta](#-author-meta)

</details>

---

## 🧩 The Problem

You have a service available internally:

```

192.168.102.154:31568

```

but it only serves requests for the hostname:

```

sam.com

````

If you try:

```bash
curl https://sam.com:31568/
````

💥 It fails because **DNS doesn’t know how to resolve `sam.com`** to that IP.

---

## ⚙️ The Solution — `--resolve`

`curl --resolve` lets you manually tell curl *which IP* a hostname should resolve to, temporarily.

```bash
curl -k --resolve sam.com:31568:192.168.102.154 https://sam.com:31568/
```

| Flag                                      | Description                                                             |
| ----------------------------------------- | ----------------------------------------------------------------------- |
| `-k`                                      | Ignore SSL certificate validation (useful for self-signed certs).       |
| `--resolve sam.com:31568:192.168.102.154` | Maps `sam.com` on port `31568` to IP `192.168.102.154`.                 |
| `https://sam.com:31568/`                  | Uses hostname in the URL so the correct `Host` header and SNI are sent. |

---

### 🧠 Deep Dive: What Happens Internally

1. `curl` skips DNS lookup for `sam.com`.
2. It directly connects to `192.168.102.154:31568`.
3. It sends `Host: sam.com` in the request.
4. The web server (NGINX, Ingress, Apache, etc.) routes it correctly.
5. `-k` ensures SSL issues don’t block testing.

✅ **Result:** The app responds as if DNS already existed.

---

## ⚖️ Comparison — `--resolve` vs `-H "Host:"`

The `-H "Host:"` flag **only changes the HTTP header**, not DNS lookup.

### ❌ Example 1 — Fails (no DNS entry)

```bash
curl -k -H "Host: sam.com" https://sam.com:31568/
```

If `sam.com` isn’t in DNS, curl can’t reach the server at all.

---

### ✅ Example 2 — Works (using IP)

```bash
curl -k -H "Host: sam.com" https://192.168.102.154:31568/
```

Here:

* Curl connects to IP directly
* Sends `Host: sam.com`
* The server routes correctly

✅ Works — but SNI (for HTTPS) still uses the IP, not the hostname.

---

| Feature                  | `--resolve`            | `-H "Host:"`              |
| ------------------------ | ---------------------- | ------------------------- |
| Changes DNS resolution   | ✅ Yes                  | ❌ No                      |
| Sends custom Host header | ✅ Yes                  | ✅ Yes                     |
| Works without DNS        | ✅                      | ⚠️ Only with IP           |
| Affects HTTPS SNI        | ✅                      | ❌                         |
| Ideal for                | DNS override & testing | Quick vhost testing on IP |

---

## 🌐 DNS Resolution Flow

### 🧠 Normal DNS Flow

```text
curl https://sam.com
  │
  ▼
[System Resolver]
  │
  ▼
[DNS Server] → Returns IP
  │
  ▼
Connects to IP → Sends Host: sam.com
```

✅ Works only if DNS exists.

---

### ⚙️ `/etc/hosts` Override

```bash
192.168.102.154 sam.com
```

```text
curl → System Resolver → /etc/hosts ✅ → Connects → Host: sam.com
```

✅ Works system-wide
⚠️ Needs `sudo`, permanent until removed.

---

### 💡 `--resolve` Override (Best for Testing)

```bash
curl -k --resolve sam.com:31568:192.168.102.154 https://sam.com:31568/
```

```text
curl → Internal Resolver ✅ → Skips DNS → Connects → Host: sam.com
```

✅ Temporary
✅ No root access
✅ Proper SNI for HTTPS

---

### 🧭 Priority Order

| Source       | Priority   | Scope         | Notes              |
| ------------ | ---------- | ------------- | ------------------ |
| `--resolve`  | 🔺 Highest | Per curl call | Safest & temporary |
| `/etc/hosts` | Medium     | System-wide   | Requires sudo      |
| DNS          | Lowest     | Default       | Needs propagation  |

---

## ☸️ Real-World Kubernetes Example

When testing Kubernetes **Ingress** before DNS is live, `--resolve` is a lifesaver.

### Example Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: production
spec:
  rules:
    - host: sam.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-service
                port:
                  number: 80
```

If you try to curl using IP directly:

```bash
curl http://192.168.102.154
```

❌ You’ll get `404 Not Found` — missing `Host: sam.com`.

---

### ✅ Use `--resolve`

```bash
curl --resolve sam.com:80:192.168.102.154 http://sam.com
```

For HTTPS:

```bash
curl -k --resolve sam.com:443:192.168.102.154 https://sam.com
```

✅ Pretends DNS exists
✅ Routes correctly through Ingress

---

### 🖼️ Visual Flow

```text
Client (curl)
   ├── Manual map: sam.com → 192.168.102.154
   └── Connects to IP
           │
           ▼
     NGINX Ingress
           │
     Matches Host: sam.com
           ▼
     Routes to myapp-service
```

---

### 💡 Pro Tip for Automation

```bash
INGRESS_IP=$(kubectl get ingress myapp-ingress -n production -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -k --resolve sam.com:443:$INGRESS_IP https://sam.com
```

✅ Perfect for CI/CD validation before DNS changes.

---

## 🔐 HTTPS & SNI Behavior

| Scenario                                        | Host Header | SNI Sent | HTTPS Works? |
| ----------------------------------------------- | ----------- | -------- | ------------ |
| `curl -H "Host:" https://IP`                    | sam.com     | IP       | ❌            |
| `curl --resolve sam.com:443:IP https://sam.com` | sam.com     | sam.com  | ✅            |

💡 **SNI** (Server Name Indication) ensures the correct SSL certificate is presented.

---

## 🧰 DevOps Advantages

| Use Case                     | Why `--resolve` Helps            |
| ---------------------------- | -------------------------------- |
| 🧪 Test Ingress before DNS   | No need to edit `/etc/hosts`     |
| 🧱 Multiple vhosts on one IP | Perfect for multi-domain ingress |
| 🔒 SSL/TLS validation        | Sends correct SNI                |
| 🧭 Troubleshoot routing      | Verify host-based routing        |
| ⚙️ CI/CD testing             | Automatable and non-invasive     |

---

## 🧩 Summary Cheat Sheet

| Scenario            | Recommended Command                              |
| ------------------- | ------------------------------------------------ |
| DNS not ready       | `curl --resolve host:port:IP https://host:port/` |
| Multi-domain test   | Multiple `--resolve` flags                       |
| Quick vhost test    | `curl -H "Host: host.com" https://IP:port/`      |
| System-wide mapping | `/etc/hosts`                                     |
| Ignore SSL mismatch | Add `-k`                                         |

---

## ⚡ Quick Recap

> Think of `--resolve` as a **temporary DNS record**,
> and `-H "Host:"` as a **fake name tag**.
> Both tell the server “I’m calling *sam.com*,”
> but only `--resolve` tells curl *where to find it.*

💬 **Quote:**

> 🧠 *“`--resolve` lets you see tomorrow’s DNS today.”*
> Before DNS goes live, you can already test, verify, and automate routing checks like a pro.

---
