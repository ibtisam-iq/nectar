# 📌 Imperative Ingress Creation in Kubernetes

You can create an Ingress resource in Kubernetes using the CLI with the following command:

```bash
kubectl create ingress NAME \
  --rule=host/path=service:port[,tls[=secret]] \
  --class <> --annotation <>
```

This creates an **Ingress** object using an *imperative* approach (without writing a YAML file).

---

## 🧭 What is Ingress?

Ingress acts like a **smart router** for HTTP/HTTPS traffic. It defines how external traffic should be routed to services within the cluster based on:

- Hostnames
- URL paths
- Optional TLS/HTTPS settings

---

## 🧠 Understanding the Command

| Part | Meaning |
|------|---------|
| `kubectl create ingress` | Instructs Kubernetes to create an Ingress resource |
| `NAME` | The name you assign to the Ingress object |
| `--rule=` | Defines the routing rule |
| `host/path` | The external domain and URL path to match |
| `service:port` | The internal service and port to route traffic to |
| `tls[=secret]` *(optional)* | Enables HTTPS with optional TLS secret for cert & key |

---

## ✅ Example 1: Basic HTTP Routing

```bash
kubectl create ingress my-ingress \
  --rule=example.com/foo=frontend-svc:80
```

📌 This routes:

- Any HTTP request to `http://example.com/foo`
- ➡️ to the `frontend-svc` service on port `80`.

---

## ✅ Example 2: HTTPS Routing with TLS

```bash
kubectl create ingress secure-ingress \
  --rule=example.com/=frontend-svc:80,tls=my-tls-secret
```

📌 This sets up:

- HTTPS routing (`https://example.com/`)
- TLS termination using the secret `my-tls-secret`
- Routes to `frontend-svc` on port `80`.

---

## 🧩 Why Use Ingress?

Ingress offers:

- 🧭 **URL routing** – Path- or host-based traffic control
- 🔐 **TLS termination** – Use HTTPS with certificates
- 🎛️ **Centralized access** – One entry point for multiple services

With Ingress, you **don’t need to expose each service individually**.

---

## 🔄 Alternatives to Ingress

| Method | Purpose | When to Use |
|--------|---------|-------------|
| **NodePort** | Expose service on a static port on every node | Quick testing or internal access |
| **LoadBalancer** | Provision external cloud load balancer | Cloud environments like AWS, GCP, Azure |
| **Port Forwarding** | Forwards cluster port to local machine | Local debugging |
| **Ingress** | Smart HTTP(S) routing | Production web traffic |
| **Service Mesh (e.g., Istio)** | Deep control over traffic | Microservices observability and security |

---

## 🚀 When Should You Use Ingress?

Use Ingress if:

- You have **multiple HTTP(S) services**.
- You want **path/host-based routing**.
- You need **TLS (HTTPS) support**.
- You prefer a **centralized entry point** to your cluster.

---

## 🛠️ Ingress Controller Is Required!

> ❗ Ingress **won’t work out-of-the-box**.  
You must deploy an **Ingress Controller** in your cluster like:

- NGINX
- Traefik
- HAProxy
- AWS ALB Controller (for EKS)

The controller enforces the Ingress rules you've defined.

---

## 🔐 TLS with Ingress

To enable HTTPS:

1. Generate or obtain a TLS certificate and key.
2. Store them as a Kubernetes secret:

```bash
kubectl create secret tls my-tls-secret \
  --cert=cert.pem \
  --key=key.pem
```

3. Reference this secret in your Ingress rule:

```bash
--rule=example.com/=service:port,tls=my-tls-secret
```

---

✅ With this knowledge, you can route traffic smartly and securely inside your Kubernetes cluster using a single command!
