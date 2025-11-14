# etcd TLS Notes for Kubernetes (CKA-Ready)

These notes explain how TLS works with etcd in Kubernetes, what each certificate file means, and how the `--insecure-skip-tls-verify` flag behaves.

---

## 1. When `--insecure-skip-tls-verify` Works

`--insecure-skip-tls-verify` **only works if etcd is NOT enforcing client certificate authentication.**

This requires:

```
--client-cert-auth=false
```

In Kubernetes (kubeadm clusters), client certificate authentication is **always enabled**, so:

* `--insecure-skip-tls-verify` does **not** allow unauthenticated access.
* etcd will still demand client certificate + key.
* You will still see: `tls: certificate required`.

**Conclusion:** In Kubernetes, `--insecure-skip-tls-verify` is effectively useless.

---

## 2. What `--insecure-skip-tls-verify` Actually Skips

### **It only skips:**

* **Server certificate validation** (CA verification)

### **It does NOT skip:**

* Client certificate (`--cert`)
* Client private key (`--key`)

This is because etcd enforces **mutual TLS (mTLS)**.

### Final Truth:

> **`--insecure-skip-tls-verify` removes the need for `--cacert`, but NOT for `--cert` and `--key`.**

---

## 3. Understanding the TLS Files

### 🔹 **CA Certificate (`--cacert`)**

* CA = Certificate Authority.
* Validates the SERVER certificate.
* Ensures you are talking to the *real* etcd server.

Analogy: passport office validating passports.

### 🔹 **Client Certificate (`--cert`)**

* Identifies the **client** (you).
* Proves to etcd: "This request comes from an authorized component (API server/admin)."

### 🔹 **Client Private Key (`--key`)**

* Proves you OWN the identity in the certificate.
* Like your real signature.

---

## 4. Table Summary

| TLS File                   | Purpose                  | Proves                         |
| -------------------------- | ------------------------ | ------------------------------ |
| **CA (`--cacert`)**        | Validate server identity | "This is real etcd"            |
| **Client Cert (`--cert`)** | Identify the client      | "This is kube-apiserver/admin" |
| **Client Key (`--key`)**   | Authenticate the client  | "I own this identity"          |

---

## 5. Error Messages and Meaning

### **Without cert/key:**

```
tls: certificate required
```

Reason: etcd demands client authentication.

### **Wrong or missing CA:**

```
x509: certificate signed by unknown authority
```

Reason: server cert cannot be validated.

---

## 6. The Golden Rule (Memorize for CKA)

In Kubernetes:

* You **must** provide:

  * `--cert`
  * `--key`
  * `--cacert` (unless you're testing and skipping verification)

* `--insecure-skip-tls-verify` **cannot** bypass client authentication.

* etcd uses **mutual TLS**, so both sides must authenticate.

---

## 7. Correct etcdctl Example (Kubernetes)

```
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  endpoint health
```

Expected output:

```
https://127.0.0.1:2379 is healthy
```

---

## 8. One-Line Summary

> **`--insecure-skip-tls-verify` only skips CA validation. It does NOT skip client authentication. etcd in Kubernetes ALWAYS requires cert + key.**
