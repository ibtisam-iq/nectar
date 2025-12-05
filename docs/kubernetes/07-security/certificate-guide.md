## 📌 Who Actually Creates the `Certificate` Resource in Kubernetes?

There are **two possible ways** a `Certificate` resource appears in your cluster:

---

### ① You Create It Manually  
👉 Sometimes, you manually define a `Certificate` resource using YAML and apply it.  
**Example:**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ibtisam-iq-tls
  namespace: default
spec:
  secretName: ibtisam-iq-tls-secret
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  dnsNames:
  - "ibtisam-iq.com"
```

✔️ This tells cert-manager:
- **What domain to secure**
- **Which ClusterIssuer to use**
- **Where to store the resulting certificate (in a Secret)**  
→ cert-manager watches this `Certificate` object and **automatically requests a real cert from the CA** via the Issuer.

---

### ② Auto-Created via Ingress Annotations  
👉 If you don’t manually create a `Certificate`, cert-manager can **auto-generate one for you** when you annotate your Ingress like this:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-production"
```

✔️ Here’s what happens:
1. You apply the Ingress with this annotation.
2. cert-manager **detects this annotation**.
3. cert-manager **auto-creates a corresponding `Certificate` resource** behind the scenes.
4. It proceeds to talk to the ClusterIssuer, run the ACME challenge, and eventually store the certificate inside a Secret (with the same name you provided under `tls.secretName` in your Ingress YAML).

**Example Ingress**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ibtisam-iq-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-production"
spec:
  tls:
  - hosts:
    - ibtisam-iq.com
    secretName: ibtisam-iq-tls-secret
  rules:
  - host: ibtisam-iq.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

✔️ In this case:
- cert-manager sees that you want a cert for `ibtisam-iq.com`.
- It **auto-creates a `Certificate` object in the background** with:
  - DNS Name `ibtisam-iq.com`
  - ClusterIssuer reference
  - Secret name `ibtisam-iq-tls-secret`
- Then starts issuing it via the CA.

---

## 📌 How to See These Auto-Created Certificates  
To see the Certificates (manual or auto-generated):
```bash
kubectl get certificates -A
```

**You’ll find something like:**
```
NAMESPACE   NAME               READY   SECRET                  AGE
default     ibtisam-iq-tls     True    ibtisam-iq-tls-secret   2m
```

---

## 📌 Recap: Who Creates the `Certificate`  
✅ **You — if you manually write the YAML**  
✅ **cert-manager — if you annotate the Ingress with `cert-manager.io/cluster-issuer`**

In both cases:
- **cert-manager watches the `Certificate` resources**
- Starts the **issuance + challenge**
- Stores result in the **Secret**

