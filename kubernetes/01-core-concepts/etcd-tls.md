# etcd TLS for Kubernetes

These notes explain how TLS works with etcd in Kubernetes, the meaning of each certificate, and the **correct**, refined behavior of `--insecure-skip-tls-verify` based on the updated learning.

---

## 1. Understanding Client Authentication in etcd

etcd can run in two modes regarding client authentication:

### **Case 1 — `--client-cert-auth=false`**

* etcd does **NOT** require client authentication.
* No client certificate needed.
* No private key needed.
* Anyone can connect.
* `--insecure-skip-tls-verify` is unnecessary because CA validation is not enforced at all.

### **Case 2 — `--client-cert-auth=true` (Default in Kubernetes)**

* etcd **requires** client authentication using certificates.
* You **must** provide:

  * `--cert`
  * `--key`
* Without these, you get:

  ```
  tls: certificate required
  ```

**Important:** In kubeadm-based clusters, this flag is ALWAYS `true`.

---

## 2. What `--insecure-skip-tls-verify` Actually Does

`--insecure-skip-tls-verify` has **one single purpose:**

### ✔ It skips server certificate (CA) validation.

It disables only:

* CA verification (`--cacert`)

### ❌ It does NOT skip:

* client certificate requirement
* client key requirement
* mutual TLS
* authentication enforcement

### Final Behavior:

> **`--insecure-skip-tls-verify` removes the need for CA, but NEVER replaces cert & key when client authentication is enabled.**

---

## 3. Correct Behavior Summary

### **If `client-cert-auth=false`:**

* `--cert` → optional
* `--key` → optional
* `--cacert` → optional
* `--insecure-skip-tls-verify` → optional and unnecessary
* etcd is open for anyone to connect

### **If `client-cert-auth=true` (Kubernetes default):**

* `--cert` → required
* `--key` → required
* `--cacert` → optional ONLY IF you use `--insecure-skip-tls-verify`
* `--insecure-skip-tls-verify` skips CA validation, but NOT authentication

This is why your command worked:

* You provided cert + key → authentication successful
* You skipped CA → allowed
* etcd accepted the request

```bash
controlplane ~ ➜  k exec -it -n kube-system etcd-controlplane -- sh
sh-5.2# etcdctl --endpoints 127.0.0.1:2379 --insecure-skip-tls-verify --cert=/etc/kubernetes/pki/etcd/server.crt \         
> --key=/etc/kubernetes/pki/etcd/server.key endpoint health
127.0.0.1:2379 is healthy: successfully committed proposal: took = 10.727387ms
sh-5.2# 
```

---

## 4. What Each TLS File Means

### 🔹 **CA Certificate (`--cacert`)**

* Validates server certificate.
* Ensures you are connecting to the REAL etcd server.
* Skipped when `--insecure-skip-tls-verify` is used.

### 🔹 **Client Certificate (`--cert`)**

* Identifies the client.
* Required when `client-cert-auth=true`.
* Example identities: `kube-apiserver`, `admin`.

### 🔹 **Client Private Key (`--key`)**

* Proves the client truly owns the certificate.
* Required whenever client certificate is required.

---

## 5. Summary Table

| File                       | Purpose                        | Required when client-cert-auth=true?       |
| -------------------------- | ------------------------------ | ------------------------------------------ |
| **CA (`--cacert`)**        | validates server's certificate | No (if using `--insecure-skip-tls-verify`) |
| **Client Cert (`--cert`)** | identifies the client          | Yes                                        |
| **Client Key (`--key`)**   | proves client identity         | Yes                                        |

---

## 6. Error Messages Explained

### ❌ Missing cert/key:

```
tls: certificate required
```

Means: etcd demands client authentication.

### ❌ Missing CA without skip flag:

```
x509: certificate signed by unknown authority
```

Means: server certificate cannot be validated.

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

Or, if skipping CA:

```
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --insecure-skip-tls-verify \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

---

## 8. One-Line Master Summary

> **`--insecure-skip-tls-verify` only removes CA validation. It does NOT remove the need for client certificate & key if client authentication is enabled.**
