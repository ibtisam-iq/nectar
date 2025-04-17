# 📖 Kubernetes Ingress, TLS, Cert-Manager, and SSL Termination: A Practical Demo with `ibtisam-iq.com`

This guide demonstrates how to secure `https://ibtisam-iq.com` in Kubernetes using **Ingress**, **TLS certificates**, **Cert-Manager**, and an **Ingress Controller** with **SSL termination**. As a hands-on use case, it applies the concepts of TLS, Cert-Manager, and Ingress to a real-world scenario, guiding you step-by-step like an instructor. Designed for learners preparing for deployments or certifications like CKA, it covers setup, workflows, and verification, ensuring you understand how each component connects to secure your application.

---

## 🧠 Lesson 1: Understanding TLS and SSL Termination

### What is TLS?
**TLS (Transport Layer Security)**, often called SSL, encrypts communication between a client (e.g., browser) and a server, ensuring:
- **Confidentiality**: No eavesdropping on data
- **Integrity**: Data isn’t altered in transit
- **Authentication**: Users connect to the real `ibtisam-iq.com`

When users visit `https://ibtisam-iq.com`, TLS guarantees a secure connection.

### What is SSL/TLS Termination?
**SSL termination** occurs at the **Ingress Controller**, which:
1. Receives encrypted HTTPS traffic
2. Decrypts it using a TLS certificate’s private key
3. Forwards plain HTTP to internal services (e.g., `ibtisam-service`)

This centralizes encryption handling, simplifying communication within the cluster.

### Why TLS for `ibtisam-iq.com`?
- Prevents man-in-the-middle (MITM) attacks
- Verifies `ibtisam-iq.com`’s legitimacy
- Avoids browser “Not Secure” warnings

---

## 🔑 Lesson 2: Anatomy of a TLS Certificate

### What’s in a TLS Certificate?
A TLS certificate is a digital ID for `ibtisam-iq.com`, containing:
| Field                | Description                                      |
|----------------------|--------------------------------------------------|
| **Common Name (CN)** | Domain name (`ibtisam-iq.com`)                  |
| **Public Key**       | Encrypts data sent by clients                   |
| **Issuer**           | CA that issued it (e.g., Let’s Encrypt)         |
| **Validity Period**  | Active timeframe (90 days for Let’s Encrypt)    |
| **Signature**        | Proves CA trust                                 |
| **SHA-256 Fingerprint** | Unique certificate identifier                |

### Public vs. Private Key
| **Public Key**                     | **Private Key**                       |
|------------------------------------|---------------------------------------|
| Embedded in the certificate        | Kept secret in a Kubernetes Secret    |
| Shared with clients for encryption | Used by the server for decryption     |

For `ibtisam-iq.com`:
- **Issued To**: `ibtisam-iq.com`
- **Issued By**: Let’s Encrypt
- **Public Key**: Generated for your cluster
- **Fingerprint**: Unique to your certificate

---

## 🏛️ Lesson 3: Certificate Authorities and Let’s Encrypt

### What is a Certificate Authority (CA)?
A **CA** verifies domain ownership and issues TLS certificates. Options include:
- **Free**: Let’s Encrypt (automated, ideal for `ibtisam-iq.com`)
- **Paid**: DigiCert, GoDaddy, Sectigo (offer extended validation, warranties)

**Let’s Encrypt** is preferred for `ibtisam-iq.com` because it’s:
- Free and trusted by browsers
- Automated via Cert-Manager
- Suitable for production (despite 90-day validity)

**Production Note**: Paid CAs may be chosen for enterprises needing advanced validation, but Let’s Encrypt is reliable for most public services.

### HTTP-01 Challenge
Let’s Encrypt verifies you own `ibtisam-iq.com` via the **HTTP-01 challenge**:
1. It requests a file at `http://ibtisam-iq.com/.well-known/acme-challenge/<token>`.
2. Cert-Manager and the Ingress Controller serve the token.
3. If Let’s Encrypt validates the response, it issues the certificate.

**Requirement**: The Ingress Controller must be reachable on port 80.

---

## 🎛️ Lesson 4: Cert-Manager – Automating Certificate Management

### What is Cert-Manager?
**Cert-Manager** is a Kubernetes add-on that automates TLS certificate management for `ibtisam-iq.com`, handling:
- Requesting certificates from Let’s Encrypt
- Completing HTTP-01 challenges
- Storing certificates in **Kubernetes Secrets**
- Renewing certificates ~30 days before expiry

Without Cert-Manager, you’d manually manage certificates, which is error-prone.

### Installation
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml
```

Cert-Manager uses **Custom Resource Definitions (CRDs)** like `Certificate` and `ClusterIssuer`.

---

## 🏷️ Lesson 5: ClusterIssuer – Configuring Certificate Issuance

### What is a ClusterIssuer?
A **ClusterIssuer** is a cluster-wide resource that tells Cert-Manager how to request certificates for `ibtisam-iq.com`. It specifies:
- Let’s Encrypt’s ACME server
- Email for notifications (`admin@ibtisam-iq.com`)
- HTTP-01 challenge solver
- Secret for the private key

**ClusterIssuer vs. Issuer**:
| Type              | Scope        | Use Case                               |
|-------------------|--------------|----------------------------------------|
| **Issuer**        | Namespace    | Certificates for a single namespace    |
| **ClusterIssuer** | Cluster-wide | Shared TLS for `ibtisam-iq.com`        |

**ClusterIssuer** is preferred for `ibtisam-iq.com` due to its scalability.

### ClusterIssuer YAML
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
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Key Fields
| Field                     | Purpose                                                                 |
|---------------------------|-------------------------------------------------------------------------|
| `name`                    | Unique identifier (`letsencrypt-prod`)                                  |
| `acme.server`             | Let’s Encrypt’s API endpoint                                           |
| `email`                   | Contact for expiry notices (`admin@ibtisam-iq.com`)                    |
| `privateKeySecretRef`     | Secret for the ACME account’s private key                              |
| `solvers`                 | Configures HTTP-01 challenge via the Ingress Controller                |

---

## 🔐 Lesson 6: Kubernetes Secrets – Storing Certificates

### What is a Secret?
A **Kubernetes Secret** securely stores sensitive data, such as the TLS certificate and private key for `ibtisam-iq.com`. Cert-Manager creates:
- **ACME private key Secret** (`letsencrypt-prod-account-key`): For certificate issuance
- **TLS Secret** (`ibtisam-tls`): For HTTPS traffic

**TLS Secret Example**:
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

The **Ingress Controller** uses `ibtisam-tls` for **SSL termination**.

---

## 🌐 Lesson 7: Ingress Controller – The Gatekeeper

### What is an Ingress Controller?
An **Ingress Controller** (e.g., NGINX) is software running in your cluster that:
- Listens on **ports 80 (HTTP)** and **443 (HTTPS)**
- Terminates TLS traffic for `ibtisam-iq.com`
- Routes traffic to services based on **Ingress resources**
- Performs load balancing and path routing

**Installation (NGINX)**:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

Verify:
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

**Note**: The Ingress Controller is separate from Kubernetes core and must be installed.

---

## 📝 Lesson 8: Ingress Resource – Defining Routing Rules

### What is an Ingress Resource?
An **Ingress resource** is a YAML manifest that defines:
- Domain (`ibtisam-iq.com`)
- Routing paths (e.g., `/` to `ibtisam-service`)
- TLS settings (using `ibtisam-tls`)
- Cert-Manager instructions (via annotations)

**Ingress YAML**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ibtisam-ingress
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
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
            name: ibtisam-service
            port:
              number: 80
```

### Key Fields
| Field                            | Purpose                                                                 |
|----------------------------------|------------------------------------------------------------------------|
| `annotations`                    | Links to `letsencrypt-prod` and configures NGINX (e.g., SSL redirect)  |
| `ingressClassName`               | Specifies the Ingress Controller (NGINX)                               |
| `tls.secretName`                 | References `ibtisam-tls` for HTTPS                                     |
| `rules.host`                     | Matches `ibtisam-iq.com`                                               |
| `http.paths.path`                | Routes `/` to `ibtisam-service`                                        |
| `backend.service.name/port`      | Targets `ibtisam-service:80`                                           |

---

## 🔄 Lesson 9: End-to-End Workflow

### HTTPS Request Flow
1. A user visits `https://ibtisam-iq.com`.
2. The request hits the **Ingress Controller** (NGINX) via a load balancer on port 443.
3. The controller uses `ibtisam-tls` to **decrypt** the traffic.
4. It matches the request to the **Ingress resource** for `ibtisam-iq.com`.
5. It routes plain HTTP to `ibtisam-service:80`.
6. The service forwards the request to application pods (e.g., NGINX container).

### Certificate Issuance Flow
1. Cert-Manager detects the Ingress annotation (`cert-manager.io/cluster-issuer`).
2. It uses the **ClusterIssuer** (`letsencrypt-prod`) to request a certificate.
3. Cert-Manager generates an ACME private key and stores it in `letsencrypt-prod-account-key`.
4. It creates a temporary Ingress for `http://ibtisam-iq.com/.well-known/acme-challenge/<token>`.
5. Let’s Encrypt validates the **HTTP-01 challenge** and issues the certificate.
6. Cert-Manager stores the certificate and private key in `ibtisam-tls`.
7. The Ingress Controller uses `ibtisam-tls` for **SSL termination**.

**Diagram**:
```plaintext
User Browser (HTTPS)
       │
       ▼
Load Balancer → Ingress Controller (NGINX)
  ├── Uses Secret (ibtisam-tls)
  ├── Terminates SSL
  ├── Matches Ingress Rule (ibtisam-iq.com)
  │
  └── Forwards HTTP
       │
       ▼
    Service (ibtisam-service:80)
       │
       ▼
     Application Pods
```

**Certificate Issuance**:
```plaintext
Cert-Manager
  ├── Watches Ingress (cert-manager.io annotation)
  ├── Uses ClusterIssuer (letsencrypt-prod)
  ├── Stores ACME Key in Secret (letsencrypt-prod-account-key)
  ├── Requests Cert from Let’s Encrypt
  ├── Serves HTTP-01 Challenge
  └── Stores Cert in Secret (ibtisam-tls)
```

---

## 🛠️ Lesson 10: Demo Setup – Step-by-Step

Follow these steps to secure `https://ibtisam-iq.com`:

1. **Deploy Application Service**:
   - Create `ibtisam-service` (e.g., an NGINX container).
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Service
   metadata:
     name: ibtisam-service
     namespace: default
   spec:
     selector:
       app: ibtisam
     ports:
     - port: 80
       targetPort: 80
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: ibtisam-deployment
     namespace: default
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: ibtisam
     template:
       metadata:
         labels:
           app: ibtisam
       spec:
         containers:
         - name: nginx
           image: nginx:latest
           ports:
           - containerPort: 80
   EOF
   ```
   Verify:
   ```bash
   kubectl get svc ibtisam-service
   kubectl get pods -l app=ibtisam
   ```

2. **Install Cert-Manager**:
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml
   ```

3. **Create ClusterIssuer**:
   Apply the ClusterIssuer YAML (see Lesson 5).
   ```bash
   kubectl apply -f clusterissuer.yaml
   ```

4. **Install NGINX Ingress Controller**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
   ```

5. **Apply Ingress Resource**:
   Apply the Ingress YAML (see Lesson 8).
   ```bash
   kubectl apply -f ingress.yaml
   ```

---

## ✅ Lesson 11: Verifying the Setup

Check the final state:
```bash
kubectl get certificate
kubectl get secret ibtisam-tls
kubectl get ingress ibtisam-ingress
kubectl get svc ibtisam-service
```

**Expected Outcome**:
- A TLS certificate is stored in `ibtisam-tls`.
- HTTPS traffic to `https://ibtisam-iq.com` is routed to `ibtisam-service`.
- Cert-Manager automatically renews the certificate ~30 days before expiry.

Test:
- Visit `https://ibtisam-iq.com` in a browser.
- Check the certificate details (should show Let’s Encrypt as the issuer).

---

## ⛑️ Lesson 12: Troubleshooting Tips

If `https://ibtisam-iq.com` doesn’t work:
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
  kubectl describe certificate
  ```
- **HTTP-01 challenge**:
  Ensure `http://ibtisam-iq.com/.well-known/acme-challenge/` is accessible.
- **Service and DNS**:
  Verify `ibtisam-service` and DNS for `ibtisam-iq.com` are correct.
  ```bash
  kubectl get svc ibtisam-service
  nslookup ibtisam-iq.com
  ```

**CKA Tip**:
- Use `kubectl describe` to check resource events.
- Ensure ports 80/443 are open on the Ingress Controller.
- Validate DNS resolution for `ibtisam-iq.com`.

---

## 📊 Lesson 13: Key Components and Roles

| Component            | Role                                                                 |
|---------------------|----------------------------------------------------------------------|
| **Let’s Encrypt**   | Issues TLS certificates for `ibtisam-iq.com`                         |
| **HTTP-01 Challenge**| Proves ownership of `ibtisam-iq.com` via HTTP                        |
| **Cert-Manager**    | Automates certificate issuance, renewal, and storage                 |
| **ClusterIssuer**   | Configures Let’s Encrypt interaction for Cert-Manager                |
| **Kubernetes Secret**| Stores TLS certificate and private key (`ibtisam-tls`)              |
| **Ingress Controller**| Terminates SSL, routes traffic for `ibtisam-iq.com`                 |
| **Ingress Resource**| Defines routing and TLS for `ibtisam-iq.com`                        |

---

## 🎯 Lesson 14: Analogy – The Airport

- **Cert-Manager**: Security team issuing boarding passes
- **ClusterIssuer**: Policy for issuing passes
- **Let’s Encrypt**: Passport authority verifying identities
- **Ingress Controller**: Gate officer checking passes and directing passengers
- **Ingress Resource**: Flight schedule board
- **Secret**: Locked safe storing passes

---

## 📚 Lesson 15: Summary and Next Steps

### Summary
This demo showed how to secure `https://ibtisam-iq.com` using **Ingress**, **Cert-Manager**, and **Let’s Encrypt**. **Cert-Manager** automated certificate issuance by watching the **ClusterIssuer** and **Ingress resources**, coordinating with Let’s Encrypt via the **HTTP-01 challenge**. The **Ingress Controller** (NGINX) terminated SSL using the `ibtisam-tls` **Secret**, routing traffic to `ibtisam-service`. This setup ensures secure, scalable HTTPS with automatic renewals, applying theoretical concepts to a practical use case.

### Next Steps
- Monitor certificate renewals (~60 days).
- Add path-based routing (e.g., `/api` to another service).
- Explore DNS-01 challenges for wildcard certificates.
- Review Cert-Manager logs for issues.

For more details:
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Let’s Encrypt](https://letsencrypt.org/)

