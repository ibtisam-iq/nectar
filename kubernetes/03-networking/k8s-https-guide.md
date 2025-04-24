# 📖 Securing Kubernetes with Ingress, TLS, Cert-Manager, and Let’s Encrypt: A Complete Guide

This documentation guides you how to configure **secure HTTPS traffic** for `https://ibtisam-iq.com` in Kubernetes using **Ingress**, **TLS certificates**, **Cert-Manager**, and an **Ingress Controller** with **SSL termination**. Designed like a lesson plan, it walks you through concepts, setup, workflows, and debugging in a logical order, connecting all components to prepare you for real-world deployment or certifications like CKA.

---

## 🧠 Lesson 1: Understanding TLS/SSL Certificates

### What is a TLS/SSL Certificate?
A **TLS/SSL certificate** is a digital passport for your website, ensuring **encrypted** and **authenticated** communication between a client (e.g., browser) and a server. When a user visits `https://ibtisam-iq.com`, the server presents a TLS certificate to:
- Prove its **identity** ("I am ibtisam-iq.com")
- Provide a **public key** for encrypting data

### Certificate Contents
| Field                | Description                                      |
|----------------------|--------------------------------------------------|
| **Common Name (CN)** | Domain name (e.g., `ibtisam-iq.com`)            |
| **Public Key**       | Encrypts session data                           |
| **CA Signature**     | Signed by a trusted Certificate Authority (CA)  |
| **Validity Period**  | Certificate’s active timeframe (90 days for Let’s Encrypt) |
| **Issuer**           | CA that issued the certificate (e.g., Let’s Encrypt) |

### Public vs. Private Key
| **Public Key**                     | **Private Key**                       |
|------------------------------------|---------------------------------------|
| Shared in the TLS certificate      | Stored securely in a Kubernetes Secret|
| Encrypts data sent to the server   | Decrypts data received by the server |

### Why TLS?
- **Encryption**: Prevents man-in-the-middle (MITM) attacks
- **Authentication**: Verifies the server’s legitimacy
- **Trust**: Avoids browser "Not Secure" warnings

In Kubernetes, TLS certificates enable **secure HTTPS traffic** for `https://ibtisam-iq.com` via the **Ingress Controller**.

---

## 📜 Lesson 2: Certificate Authorities and Let’s Encrypt

### What is a Certificate Authority (CA)?
A **CA** is a trusted entity that verifies domain ownership and issues TLS certificates. Examples:
- **Free CA**: **Let’s Encrypt** (automated, ideal for `ibtisam-iq.com`)
- **Paid CAs**: DigiCert, GlobalSign, Sectigo (offer warranties, advanced validation)

**Let’s Encrypt** is popular because it’s:
- Free and open
- Automated via tools like Cert-Manager
- Trusted by browsers and reliable for production

### Verifying Domain Ownership: HTTP-01 Challenge
Let’s Encrypt uses the **HTTP-01 challenge** to confirm you control `ibtisam-iq.com`:
1. It requests a file at `http://ibtisam-iq.com/.well-known/acme-challenge/<token>`.
2. If your server (via Ingress) serves the correct token, Let’s Encrypt issues the certificate.

**Note**: This requires your **Ingress Controller** to be accessible on port 80.

---

## 🎛️ Lesson 3: Cert-Manager and ClusterIssuer

### What is Cert-Manager?
**Cert-Manager** is a Kubernetes controller that **automates TLS certificate management** for `ibtisam-iq.com`, handling:
- Requesting certificates from Let’s Encrypt
- Validating domains via HTTP-01 challenges
- Storing certificates in **Kubernetes Secrets**
- Renewing certificates ~30 days before expiry (Let’s Encrypt certificates last 90 days)

### Installation
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml
```

Cert-Manager uses **Custom Resource Definitions (CRDs)** like `Certificate` and `ClusterIssuer`.

### ClusterIssuer vs. Issuer
| Type              | Scope        | Use Case                               |
|-------------------|--------------|----------------------------------------|
| **Issuer**        | Namespace    | Certificates for apps in one namespace |
| **ClusterIssuer** | Cluster-wide | Shared TLS for `ibtisam-iq.com` across namespaces |

**ClusterIssuer** is ideal for production setups like `ibtisam-iq.com`.

### Configuring ClusterIssuer
A **ClusterIssuer** tells Cert-Manager how to request certificates for `ibtisam-iq.com`. It specifies:
- The CA’s ACME server (e.g., Let’s Encrypt)
- Email for notifications
- The **solver** for domain verification (e.g., HTTP-01)
- The **Secret** to store the private key

**ClusterIssuer YAML**:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: admin@ibtisam-iq.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Key Fields
| Field                     | Purpose                                                                 |
|---------------------------|-------------------------------------------------------------------------|
| `name`                    | Unique identifier (e.g., `letsencrypt-prod`)                            |
| `acme.server`             | Let’s Encrypt’s API endpoint                                           |
| `email`                   | Contact for expiry notices (e.g., `admin@ibtisam-iq.com`)              |
| `privateKeySecretRef`     | Secret to store the private key for certificate issuance               |
| `solvers`                 | Configures HTTP-01 challenge via the Ingress Controller                |

---

## 🔐 Lesson 4: Kubernetes Secrets: Storing TLS Certificates

### What is a Secret?
A **Kubernetes Secret** stores sensitive data, such as the TLS certificate and private key for `ibtisam-iq.com`. Cert-Manager stores the **public certificate** and **private key** in a **Kubernetes Secret** of type `kubernetes.io/tls`. Cert-Manager creates two types of Secrets:
- **Private key Secret** (via `privateKeySecretRef`): Used during certificate issuance
- **TLS Secret** (via `Certificate.spec.secretName` or Ingress `tls.secretName`): Stores the certificate and private key for HTTPS

**Example TLS Secret**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ibtisam-tls
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-certificate>
  tls.key: <base64-encoded-private-key>
```

Inspect it:
```bash
kubectl get secret ibtisam-tls -o yaml
```

The **Ingress Controller** uses this Secret for **SSL termination**.

---

## 🎧 Lesson 5: Ingress Controller and Ingress Resource

### What is an Ingress Controller?
An **Ingress Controller** (e.g., NGINX) is software running as a pod in your cluster that:
- Listens on **ports 80 (HTTP)** and **443 (HTTPS)**
- Watches **Ingress resources** for routing rules
- Performs **SSL termination** for `https://ibtisam-iq.com`
- Routes traffic to **Services**

**Installation (NGINX)**:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```
### Why an Ingress Controller?
- **Centralized routing**: Manages all external traffic
- **TLS handling**: Enables HTTPS without app-level configuration
- **Flexibility**: Supports host/path-based routing, redirects, and rewrites

### What is an Ingress Resource?
An **Ingress resource** defines routing rules for `ibtisam-iq.com`, specifying:
- Which domain to match (e.g., `ibtisam-iq.com`)
- Which paths to route (e.g., `/`)
- Which Service to target (e.g., `bankapp-service`)
- TLS settings for HTTPS

**Ingress YAML**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ibtisam-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - ibtisam-iq.com
    secretName: ibtisam-tls
  rules:
  - host: ibtisam-iq.com
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

### Field Breakdown
| Field                            | Purpose                                                                 |
|----------------------------------|------------------------------------------------------------------------|
| `annotations`                    | Instructs Cert-Manager and NGINX (e.g., enforce SSL redirects)          |
| `spec.tls`                       | Enables HTTPS for `ibtisam-iq.com`                                     |
| `secretName`                     | References the TLS Secret (`ibtisam-tls`)                              |
| `spec.rules`                     | Defines routing rules for HTTP traffic                                 |
| `host`                           | Matches `ibtisam-iq.com`                                               |
| `http.paths.path`                | Matches the URL path (e.g., `/`)                                       |
| `backend.service.name/port`      | Targets `bankapp-service` on port 80                                   |

### SSL Termination
The Ingress Controller:
1. Receives HTTPS traffic for `ibtisam-iq.com`
2. Decrypts it using the private key from `ibtisam-tls`
3. Forwards plain HTTP to `bankapp-service`

---

## 📝 Lesson 6: Optional Certificate Resource

For explicit certificate management, you can create a **Certificate** resource instead of relying on Ingress annotations. However, Cert-Manager can automatically generate certificates when the Ingress is annotated.

**Certificate YAML**:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ibtisam-cert
  namespace: default
spec:
  secretName: ibtisam-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: ibtisam-iq.com
  dnsNames:
    - ibtisam-iq.com
```

Cert-Manager watches this resource, requests a certificate from Let’s Encrypt, and stores it in `ibtisam-tls`.

---

## 🔄 Lesson 7: End-to-End Workflow

### HTTPS Request Flow
1. A user visits `https://ibtisam-iq.com`.
2. The **Ingress Controller** (NGINX) receives the request on port 443.
3. It matches the request to the **Ingress resource** for `ibtisam-iq.com`.
4. Using the TLS certificate from `ibtisam-tls`, it **decrypts** the traffic.
5. It routes the plain HTTP request to `bankapp-service:80`.
6. The Service forwards the request to the application **Pods**.

### Certificate Issuance Flow
1. Cert-Manager detects the Ingress annotation (`cert-manager.io/cluster-issuer`) or a `Certificate` resource.
2. It uses the **ClusterIssuer** (`letsencrypt-prod`) to request a certificate.
3. Cert-Manager generates a **private key** and stores it in the Secret specified by `privateKeySecretRef` (`letsencrypt-prod-private-key`).
4. It creates a temporary Ingress to serve `http://ibtisam-iq.com/.well-known/acme-challenge/<token>` for the **HTTP-01 challenge**.
5. Let’s Encrypt verifies the challenge and issues the certificate.
6. Cert-Manager stores the certificate and private key in `ibtisam-tls`.
7. The **Ingress Controller** uses `ibtisam-tls` for **SSL termination**.

---

## 📊 Lesson 8: Visual Diagram

**Mermaid Diagram**:
```mermaid
sequenceDiagram
    User->>Ingress Controller: Visits https://ibtisam-iq.com
    Ingress Controller->>Ingress Resource: Matches ibtisam-iq.com
    Ingress Controller->>Secret: Uses ibtisam-tls for SSL termination
    Ingress Controller->>Service: Routes to bankapp-service:80
    Service->>Pods: Forwards to application
    Cert-Manager->>ClusterIssuer: Uses letsencrypt-prod
    Cert-Manager->>Let's Encrypt: Requests certificate
    Let's Encrypt->>Ingress Controller: HTTP-01 challenge (/acme-challenge)
    Let's Encrypt-->>Cert-Manager: Issues certificate
    Cert-Manager->>Secret: Stores in ibtisam-tls
```
### Traffic Flow
```plaintext
User Browser (HTTPS)
       │
       ▼
Ingress Controller (NGINX/Traefik)
  ├── Uses Secret (my-site-tls)
  ├── Performs SSL Termination
  ├── Matches Ingress Rule (host/path ```plaintext
  │
  └── Forwards HTTP
       │
       ▼
    Service (my-service:80)
       │
       ▼
     Application Pods
```

### Certificate Issuance
```plaintext
Cert-Manager
  ├── Watches Ingress/Certificate
  ├── Uses ClusterIssuer
  ├── Generates Private Key → Stores in Secret (privateKeySecretRef)
  ├── Requests Cert from Let’s Encrypt
  ├── Completes HTTP-01 Challenge
  └── Stores Cert + Key in Secret (spec.secretName)
```

---

## 🛠️ Lesson 9: Setup Steps (What to Do When)

Follow these steps to secure `https://ibtisam-iq.com`:

1. **Ensure your application is running**:
   - Deploy `bankapp-service` and confirm it’s reachable internally.
   ```bash
   kubectl get svc bankapp-service
   ```

2. **Install Cert-Manager**:
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml
   ```

3. **Create ClusterIssuer**:
   Apply the ClusterIssuer YAML (see Lesson 3).
   ```bash
   kubectl apply -f clusterissuer.yaml
   ```

4. **Install Ingress Controller (NGINX)**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
   ```

5. **Apply Ingress Resource**:
   Apply the Ingress YAML (see Lesson 5).
   ```bash
   kubectl apply -f ingress.yaml
   ```

6. **(Optional) Create Certificate Resource**:
   If not using Ingress annotations, apply the Certificate YAML (see Lesson 6).
   ```bash
   kubectl apply -f certificate.yaml
   ```

---

## ⛑️ Lesson 10: Debugging and Troubleshooting

If `https://ibtisam-iq.com` doesn’t work, check these:

- **Cert-Manager logs**:
  ```bash
  kubectl logs -l app=cert-manager -n cert-manager
  ```
- **Ingress events**:
  ```bash
  kubectl describe ingress ibtisam-ingress
  ```
- **Certificate events**:
  ```bash
  kubectl describe certificate ibtisam-cert
  ```
- **HTTP-01 challenge**:
  Ensure `http://ibtisam-iq.com/.well-known/acme-challenge/` is accessible.
- **Service reachability**:
  Verify `bankapp-service` is running:
  ```bash
  kubectl get svc bankapp-service
  ```
- **DNS and ports**:
  Confirm `ibtisam-iq.com` resolves to the Ingress Controller and ports 80/443 are open.

**Pro Tip for CKA**:
- Use `kubectl describe` and `kubectl logs` to diagnose issues.
- Check if the Ingress Controller is routing `.well-known` paths correctly.
- Verify DNS settings for `ibtisam-iq.com`.

---

## ✅ Lesson 11: Key Components and Roles

| Component            | Role                                                                 |
|---------------------|----------------------------------------------------------------------|
| **Let’s Encrypt**   | Issues TLS certificates for `ibtisam-iq.com`                         |
| **HTTP-01 Challenge**| Proves control of `ibtisam-iq.com` via HTTP request                 |
| **Cert-Manager**    | Automates certificate issuance, renewal, and storage                 |
| **ClusterIssuer**   | Defines Let’s Encrypt settings for Cert-Manager                     |
| **Kubernetes Secret**| Stores TLS certificate and private key (`ibtisam-tls`)              |
| **Ingress Controller**| Routes traffic, terminates SSL for `ibtisam-iq.com`                |
| **Ingress Resource**| Configures routing and TLS for `ibtisam-iq.com`                    |
| **Certificate Resource**| Explicitly requests a certificate (optional)                       |

---

## 🛠️ Lesson 12: Why Separate Components?

- **Cert-Manager**: Manages certificate lifecycle
- **Ingress Controller**: Routes traffic and terminates SSL
- **ClusterIssuer**: Provides CA configuration
- **Secrets**: Securely store sensitive data

These components enable **automated, secure HTTPS** in Kubernetes.

---

## 🎯 Lesson 13: Analogy – The Airport

- **Cert-Manager**: Security team verifying passenger identities
- **ClusterIssuer**: Security policy for issuing boarding passes
- **Let’s Encrypt**: Passport authority issuing credentials
- **Ingress Controller**: Gate officer checking boarding passes and directing passengers
- **Ingress Resource**: Flight schedule board guiding passengers to gates
- **Secret**: Locked safe storing boarding passes
- **Certificate Resource**: Formal passport application

---

## 📚 Lesson 14: Summary and Next Steps

### Summary
**Cert-Manager** is a Kubernetes add-on that automates the issuance, renewal, and management of TLS certificates for `ibtisam-iq.com`. It integrates with Certificate Authorities (CAs) like Let’s Encrypt to simplify securing HTTPS traffic. Using the **ClusterIssuer** resource, Cert-Manager defines how to communicate with Let’s Encrypt, specifying the ACME endpoint, email (`admin@ibtisam-iq.com`), HTTP-01 challenge solver, and private key storage. Cert-Manager watches **ClusterIssuer**, **Certificate**, and annotated **Ingress** resources in Kubernetes’ declarative model, triggering certificate requests when needed. Once issued, certificates are stored in **Kubernetes Secrets** (e.g., `ibtisam-tls`) for use by the Ingress Controller. This automation ensures `ibtisam-iq.com` remains secure with minimal manual effort, paving the way for testing and advanced configurations.

**Next Steps**:
- Test your setup by visiting `https://ibtisam-iq.com`.
- Monitor certificate renewals (every ~60 days).
- Explore advanced Ingress features like path-based routing or DNS-01 challenges.
- Review Cert-Manager logs for expiry notifications.

For more details:
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Let’s Encrypt](https://letsencrypt.org/)
