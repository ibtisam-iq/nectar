## 📜 How Certs Are Issued in Kubernetes  

### 1️⃣ Install **cert-manager**
- A Kubernetes controller that **automates obtaining and renewing certs**
- Watches `CertificateRequest`, `Issuer`, `ClusterIssuer` objects.
- Talks to Let’s Encrypt to perform HTTP-01 or DNS-01 challenges.
- Creates a Kubernetes **Secret** containing your cert and private key.

👉 Think of `cert-manager` like your **"certificate office"** inside the cluster.

---

### 2️⃣ Define a `ClusterIssuer`
- Tells cert-manager **how and where to request certs**.
- Specifies Let’s Encrypt ACME server endpoint.
- Chooses **HTTP-01 challenge** type.

Why `ClusterIssuer` and not `Issuer`?  
- `ClusterIssuer` is **cluster-wide**.
- `Issuer` is **namespace-scoped**.

Example:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@ibtisam-iq.com
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

**Important parts:**
- `server` → Let’s Encrypt API endpoint
- `privateKeySecretRef` → Secret to store your ACME account’s private key  
- `solvers` → Defines **how cert-manager proves domain ownership** (via HTTP-01 challenge)

---

### 3️⃣ cert-manager Issues a Certificate  
When an Ingress requests TLS using a **certificate name**, cert-manager:
- Talks to Let’s Encrypt.
- Serves a challenge file via a temporary Ingress.
- Let’s Encrypt accesses `http://ibtisam-iq.com/.well-known/acme-challenge/...`
- If successful → cert-manager creates a **Secret** with your cert+key.

---

### 4️⃣ Deploy NGINX Ingress Controller  
It’s a pod running inside your cluster that:
- **Listens on ports 80/443**
- **Handles SSL Termination**
- **Routes traffic** to services based on Ingress rules.

👉 Think of it like your **gatekeeper**.

Install:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

Check:
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

### 5️⃣ Define an Ingress Resource  
This YAML describes:
- **Host:** your domain
- **Paths:** which services handle which URLs
- **TLS:** which Secret contains your cert+key

Example:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ibtisam-ingress
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
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

**Key Points:**
- `annotations` → Connects to ClusterIssuer
- `tls.secretName` → Name of Secret cert-manager will create
- `rules.host` → Domain name
- `backend.service.name` → Internal service name
- `backend.service.port` → Service port

---

## 📊 How Everything Connects  

```plaintext
             ┌──────────────────────────────────────┐
             │                User                   │
             │   (Browser HTTPS request to your site) │
             └──────────────────────────────────────┘
                               │
                     (DNS → Load Balancer)
                               │
                               ▼
                  ┌────────────────────┐
                  │ NGINX Ingress Ctrlr │
                  │ (Port 443 listener) │
                  └────────────────────┘
                       │ 1. TLS Termination (decrypt)
                       │ 2. Route to Service
                               │
                               ▼
                     ┌────────────────┐
                     │ K8s Service     │
                     │ (ClusterIP)     │
                     └────────────────┘
                               │
                               ▼
                         ┌────────┐
                         │ Pod(s) │
                         └────────┘
```

---

## 📝 Demo Stack Setup Summary  

1. Install cert-manager  
2. Apply ClusterIssuer  
3. Install NGINX Ingress Controller  
4. Deploy your Application Service  
5. Deploy Ingress Resource (with annotations and TLS block)

---

## ✅ Expected Final State  

```bash
kubectl get certificate
kubectl get secret ibtisam-tls
kubectl get ingress
kubectl get svc
```

✅ You’ll have:
- TLS cert created and stored in `ibtisam-tls`
- Ingress routing working with HTTPS
- Automatic renewal via cert-manager

---

## 📖 Closing Concept  

- **cert-manager** → The automated cert management controller  
- **ClusterIssuer** → A set of instructions on how cert-manager should request certs  
- **Secret** → Holds the cert and private key for your domain  
- **Ingress Controller** → NGINX running in-cluster, handling TLS termination and routing  
- **Ingress Resource** → YAML definition linking domains to services


