# **📌 Question (CKA 2025 – Q-01)**

An NGINX Deployment named **nginx-static** is running in the **nginx-static** namespace.
It is configured using a **ConfigMap** named **nginx-config**.

Update the **nginx-config** ConfigMap to allow **only TLSv1.3** connections.
Re-create, restart, or scale resources as necessary.

Use the following command to test the changes:

```
[candidate@cka2025] $ curl --tls-max 1.2 https://web.k8s.local
```

As TLSv1.2 should not be allowed anymore, the command should fail.

# ✅ **Answer (CKA-style, fast and correct)**

### **1️⃣ Edit the ConfigMap in real-time**

```bash
kubectl -n nginx-static edit configmap nginx-config
```

Inside the editor, find the existing line:

```
ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
```

Change it to:

```
ssl_protocols TLSv1.3;
```

Save and exit.

### **2️⃣ Restart the Deployment to load the new config**

```bash
kubectl -n nginx-static rollout restart deployment/nginx-static
```

(If rollout restart is not allowed, delete the pods instead.)

```bash
kubectl -n nginx-static delete pod -l app=nginx-static
```

### **3️⃣ Verify TLS 1.2 is rejected**

```bash
curl --tls-max 1.2 -k https://web.k8s.local
```

Expected result: **FAIL**
(because TLSv1.2 is now disabled)

### **4️⃣ (Optional) Verify TLS 1.3 works**

```bash
curl --tls-max 1.3 -k https://web.k8s.local
```

Expected result: **200 OK** or similar.

---

