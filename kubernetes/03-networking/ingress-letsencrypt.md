# 🔐 Kubernetes Ingress + Let's Encrypt TLS Setup (Banking App)

This guide explains how to secure your Kubernetes **Banking App** using:

- **Ingress**: To expose HTTP/HTTPS services to the outside world
- **Cert-Manager**: For automatic TLS certificate management via Let’s Encrypt

---

## 🚪 Part 1: Ingress — Entry Point for Your App

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bankapp-ingress
```

### 🔍 Purpose:
Defines an Ingress resource to route **external traffic** to internal Kubernetes services (like `bankapp-service`).

---

### 🔧 Annotations Explained:

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```
➡️ Tells cert-manager to issue TLS certs using the `letsencrypt-prod` ClusterIssuer.

```yaml
  nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
```
➡️ Forces HTTPS. All HTTP traffic is redirected to HTTPS.

```yaml
  nginx.ingress.kubernetes.io/rewrite-target: /
```
➡️ Rewrites paths like `/login` to `/` for backend services expecting root path.

```yaml
  nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
```
➡️ Informs NGINX that the backend service uses **HTTP**, not HTTPS.

---

### 🌐 Routing Rules

```yaml
spec:
  ingressClassName: nginx
  rules:
    - host: www.ibtisam-iq.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: bankapp-service
                port:
                  number: 80
```

This means:

> If a request comes to `www.ibtisam-iq.com/` (or any path under it), route it to `bankapp-service` on port `80`.

---

### 🔒 TLS Configuration

```yaml
tls:
  - hosts:
      - www.ibtisam-iq.com
    secretName: ibtisamx-tls
```

- Enables **HTTPS** for the domain
- TLS cert and private key are stored in a secret named `ibtisamx-tls`
- `cert-manager` auto-creates this secret after issuing the cert

---

## 📜 Part 2: ClusterIssuer — TLS Certificate Provider Setup

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
```

### 🔍 Purpose:

A **ClusterIssuer** instructs cert-manager how to request certificates from Let’s Encrypt for **entire cluster**.

---

### 🔧 ACME Settings

```yaml
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
```

- Production endpoint of Let’s Encrypt

> 💡 For testing, use:
>
> `https://acme-staging-v02.api.letsencrypt.org/directory`

```yaml
    email: muhammad@ibtisam-iq.com
```

- Email used by Let’s Encrypt for expiry and renewal notifications

```yaml
    privateKeySecretRef:
      name: letsencrypt-prod
```

- Secret to store the **ACME account private key**

---

### 🔍 Solver: HTTP-01 Challenge

```yaml
    solvers:
      - http01:
          ingress:
            class: nginx
```

- Uses HTTP-01 challenge
- Let’s Encrypt hits a special HTTP endpoint
- NGINX Ingress must respond with the challenge
- Once verified, cert is issued and stored

---

## 🔗 Visual Flow

```
User → www.ibtisam-iq.com (Ingress)
     → Cert-Manager handles cert issuance via HTTP-01
     → TLS secret (ibtisamx-tls) is created
     → Ingress uses this secret to terminate HTTPS
     → Traffic forwarded to bankapp-service:80
```

---

## 🧠 Why This Setup?

✅ **Automatic HTTPS** via Let’s Encrypt  
✅ **Path-based routing** with Ingress  
✅ **TLS certificate renewal** is automatic  
✅ **Public access** with strong encryption and central control

---

Would you like to extend this guide with:

- YAML manifest breakdown for `bankapp-service`?
- Self-signed cert fallback?
- Ingress class-based routing for multi-domain apps?
