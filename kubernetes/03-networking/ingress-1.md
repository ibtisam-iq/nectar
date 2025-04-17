# 📖 Kubernetes Ingress + TLS + Cert-Manager + SSL Termination - 1

## 🔒 What is a TLS Certificate? Why Do We Need It?

TLS (previously SSL) is a protocol that **encrypts communication between a client (browser, mobile app) and a server**.

When you access a website via `https://`, the server sends a **TLS certificate** to prove:
- **Its identity** (I am indeed `example.com`)
- It has a **public key** that can be used to encrypt messages sent to it

A TLS certificate contains:
- **Common Name (CN)**: The domain the certificate is issued for  
- **Public Key**: Used to encrypt the session key  
- **CA Signature**: A digital signature from a trusted CA (like Let's Encrypt, DigiCert)  
- **Validity Period**: When the certificate is valid  
- **Issuer**: The name of the CA  

We need this for:
- **Encryption**: So nobody can eavesdrop or tamper
- **Authentication**: So we know the server is legitimate

---

## 📜 What is a CA? Why Let’s Encrypt? What’s HTTP-01 Challenge?

A **Certificate Authority (CA)** is a trusted company/entity that:
- Verifies you’re the owner of a domain
- Issues a signed certificate for you

**Let’s Encrypt** is a free, automated CA.  
In production, people often use paid CAs like:
- **DigiCert**
- **GlobalSign**
- **Sectigo**
- **GoDaddy**

But Let’s Encrypt is reliable for most production workloads too.

**HTTP-01 Challenge** is how Let’s Encrypt proves domain ownership:
- It makes an HTTP request to `http://your-domain/.well-known/acme-challenge/xyz`
- If the correct file is there (served by your Ingress), Let’s Encrypt knows you control the domain.

---

## 🎛️ Cert-Manager and ClusterIssuer: Why, What, How?

**Cert-Manager** is a Kubernetes tool that:
- **Automates TLS certificate management**
- Handles renewals, requests, and verifications with CAs like Let’s Encrypt

We need it because:
- Manually generating, requesting, and managing certs is tedious
- Cert-manager integrates with Kubernetes natively (via CRDs like ClusterIssuer and Certificate)

**ClusterIssuer** is a cluster-wide certificate authority configuration:
- Specifies Let’s Encrypt endpoint, email, solvers
- Tells cert-manager **how to request certificates**

**Key fields**
```yaml
privateKeySecretRef:
  name: my-site-tls
```
- Cert-manager generates a **private key** for your domain and saves it in a Secret named `my-site-tls`.
- **Private key stays in your cluster** (never sent to Let’s Encrypt)
- **Let’s Encrypt issues a certificate signed by their private key**
- The public certificate + your private key is stored in a Kubernetes **Secret**

**Solvers**
- Describe **how to solve the HTTP-01 challenge**
- Typically uses your Ingress Controller to respond to Let’s Encrypt’s requests

---

## 🔐 Kubernetes Secrets: Where Is the TLS Key Stored?

**Secrets** are Kubernetes resources used to store sensitive data:
- When cert-manager obtains a TLS certificate, it saves:
  - **public certificate**
  - **private key**
  
Example:
```bash
kubectl get secret my-site-tls -o yaml
```

**This Secret is mounted/used by the Ingress Controller to perform SSL termination.**

---

## 🎧 Ingress Controller: Internals and Connection to Ingress Resource

**Ingress Controller**
- A pod running inside your cluster
- Listens for incoming traffic on **port 80 (HTTP) and 443 (HTTPS)**
- Watches for changes to **Ingress resources**
- Maps incoming requests to **services running inside the cluster**
- Handles **SSL termination**
- Manages routing, redirects, and path-based rules

**SSL termination**
- The process where the Ingress Controller:
  1. Receives encrypted HTTPS traffic
  2. Decrypts it using the TLS certificate stored in the Secret
  3. Forwards plain HTTP to the correct service internally

If you don’t configure SSL termination, Kubernetes won’t handle HTTPS traffic.

---

## 📑 Ingress Resource YAML — Field by Field Explanation

Let’s break it down:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - mydomain.com
    secretName: my-site-tls
  rules:
  - host: mydomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

Explanation:
| Section                          | Purpose |
|:----------------------------------|:-------------------------------------------------------------------|
| `apiVersion, kind`               | Standard Kubernetes resource metadata |
| `annotations`                    | Tells cert-manager to use `letsencrypt-prod` ClusterIssuer |
| `spec.tls`                       | Tells Ingress Controller to use TLS for `mydomain.com` |
| `secretName`                     | The Secret containing the cert + private key |
| `spec.rules`                     | Defines HTTP routing rules |
| `host`                            | Hostname to match incoming requests |
| `http.paths.path`                 | URL path to match |
| `backend.service.name/port`      | Which Kubernetes service to send the request to |

---

## 🔄 Complete End-to-End Flow

**When a user accesses `https://mydomain.com`:**
1. Request arrives at Ingress Controller (NGINX, Traefik)
2. Ingress Controller finds the matching Ingress rule (`host: mydomain.com`)
3. Decrypts HTTPS traffic using the TLS certificate stored in `my-site-tls` Secret
4. Routes plain HTTP to `my-service:80` based on Ingress rules

---

## 📝 YAML & Command Workflow

1️⃣ Install cert-manager  
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml
```

2️⃣ Apply ClusterIssuer  
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: you@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

3️⃣ Deploy Ingress Controller (NGINX)  
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

4️⃣ Apply Ingress Resource  
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - mydomain.com
    secretName: my-site-tls
  rules:
  - host: mydomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

---

## 📊 Visual Diagram

Here’s a conceptual diagram:
```plaintext
User Browser (HTTPS)
       │
       ▼
Ingress Controller (NGINX)
  ├── Uses TLS Secret (my-site-tls)
  ├── SSL Termination (Decrypt HTTPS)
  ├── Matches Ingress Rule (host/path)
  │
  └── Forwards plain HTTP
       │
       ▼
    my-service:80
       │
       ▼
     Your Pods
```

---

## ✅ Summary of Dependencies

| Component | Purpose |
|:-----------|:---------------------------------------------------|
| **CA (Let's Encrypt)** | Verifies domain ownership, issues cert |
| **HTTP-01 Challenge** | Verifies domain by HTTP request |
| **cert-manager** | Automates certificate management |
| **ClusterIssuer** | Defines how to get certificates |
| **Secret** | Stores the private key and certificate |
| **Ingress Controller** | Receives, terminates HTTPS, routes |
| **Ingress Resource** | Defines routing + TLS settings |
