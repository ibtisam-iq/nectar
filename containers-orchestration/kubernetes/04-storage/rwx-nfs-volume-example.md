# 🗂️ RWX NFS Volume Example in Kubernetes

This guide demonstrates how to set up and use a **ReadWriteMany (RWX)** NFS-backed volume in Kubernetes. RWX volumes allow multiple pods to read and write to the same storage simultaneously, making them ideal for shared storage use cases like collaborative applications, shared logs, or clustered workloads.

This demo showcases how to:
- Deploy an **NFS server** inside your Kubernetes cluster
- Create a **StorageClass** for dynamic NFS-backed volumes
- Create a **PersistentVolumeClaim (PVC)** with **ReadWriteMany (RWX)** access
- Deploy **multiple pods** sharing the same storage
- Simulate **concurrent file writes** into the shared storage  
Perfect for:
- Web clusters sharing files
- Log aggregation
- Data processing pipelines

By the end of this guide, you’ll have a fully functional RWX setup and understand its practical applications in Kubernetes environments.

---

## 📦 Multi-Pod Deployment Sharing the Same NFS Volume

Here’s a **Deployment** with **two replicas** (pods) sharing the same **shared-pvc** volume:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: nginx
          volumeMounts:
            - mountPath: "/usr/share/nginx/html"
              name: shared-storage
      volumes:
        - name: shared-storage
          persistentVolumeClaim:
            claimName: shared-pvc
```

- **2 NGINX pods will run concurrently**
- Both mount the same **shared-pvc** using RWX access
- Shared data in `/usr/share/nginx/html` is visible to both pods

---

## 🛠️ NFS Server Deployment in Kubernetes (for Local Testing)

If you don’t have an external NFS server, you can quickly set one up **inside your Kubernetes cluster** for testing:

### NFS Server Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-server
  template:
    metadata:
      labels:
        app: nfs-server
    spec:
      containers:
        - name: nfs-server
          image: itsthenetwork/nfs-server-alpine:latest
          ports:
            - containerPort: 2049
          securityContext:
            privileged: true
          env:
            - name: SHARED_DIRECTORY
              value: /nfsshare
          volumeMounts:
            - name: nfs-data
              mountPath: /nfsshare
      volumes:
        - name: nfs-data
          emptyDir: {}
```

### NFS Server Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nfs-service
spec:
  selector:
    app: nfs-server
  ports:
    - protocol: TCP
      port: 2049
      targetPort: 2049
  clusterIP: None  # Headless service
```

> This deploys a simple NFS server inside your cluster and exposes it on port 2049.

---

## 📊 Simulating Concurrent File Writes

To verify that multiple pods can **write to the same NFS volume concurrently**:

### Updated NGINX Pod Writing Files

Replace `nginx` with a simple **busybox pod** that writes to a shared file in a loop:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: writer-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: writer
  template:
    metadata:
      labels:
        app: writer
    spec:
      containers:
        - name: writer
          image: busybox
          command: ["/bin/sh", "-c"]
          args:
            - while true;
              do
                echo "Written by $(hostname) at $(date)" >> /shared-data/output.log;
                sleep 5;
              done
          volumeMounts:
            - name: shared-storage
              mountPath: "/shared-data"
      volumes:
        - name: shared-storage
          persistentVolumeClaim:
            claimName: shared-pvc
```

### What this does:
- Runs **2 busybox pods**
- Each pod writes its hostname and timestamp to `/shared-data/output.log` every 5 seconds
- Both pods use the same **RWX NFS-backed volume**

You can **inspect the log file** from any pod:

```bash
kubectl exec -it <one-writer-pod> -- tail -f /shared-data/output.log
```

You should see entries being added by both pods — confirming **concurrent writing works as expected**.

---

## 📌 AccessModes in Kubernetes are **Pod-level permissions** — NOT Node-level

Here’s how they really work:

| Access Mode  | Meaning                                                 | Scope        |
|:-------------|:---------------------------------------------------------|:---------------|
| `ReadWriteOnce` (RWO) | **One Pod can mount it as read-write**. It may still be accessed from multiple nodes, but **only one pod at a time can have it mounted read-write**. | **Per Pod** |
| `ReadOnlyMany` (ROX) | **Many Pods can mount it read-only at the same time** — across one or multiple nodes. | **Per Pod** |
| `ReadWriteMany` (RWX) | **Many Pods can mount it as read-write simultaneously** — across multiple nodes. | **Per Pod** |

### ✅ So — **the unit of access is always the pod.**

It’s **not about the node** directly, though nodes come into play because:
- Some volume types (like local disks or `hostPath`) are node-bound, so pods must run on the same node.
- Distributed storage backends like **NFS** or **CSI drivers supporting RWX** can allow pods on different nodes to share the same volume concurrently.


## ✅ Real-world Example in the above YAML

In the above example:
- 2 **pods** (Busybox containers)
- Both mount the same **PVC with RWX access**
- Both are allowed to **read/write concurrently**  
  — because:
  - **NFS** supports network file sharing  
  - **PVC is RWX**
  - **Pods, no matter which nodes they land on, can share it**

---

## 📦 Components Deployed

### ✅ NFS Server (inside Kubernetes)
- Runs a lightweight **Alpine-based NFS server**
- Shares `/nfsshare` via NFS on port `2049`
- Headless service for direct internal access

### ✅ StorageClass
- Named `nfs-sc`
- Uses a placeholder provisioner `example.com/nfs` (replace this with your NFS CSI driver)

### ✅ PersistentVolumeClaim
- Named `shared-pvc`
- Requests **5Gi** storage
- AccessMode: **ReadWriteMany**

### ✅ Writer Deployment
- **2 busybox pods**
- Each pod:
  - Writes its hostname + timestamp to `/shared-data/output.log` every 5 seconds
  - Shares the same `shared-pvc` with RWX access

---

## 🚀 Deployment Instructions

### 1️⃣ Apply the RWX Demo
```bash
kubectl apply -f rwx-nfs-demo.yaml
```

---

### 2️⃣ Verify Deployments and Pods
Check the status of everything:
```bash
kubectl get all
```
You should see:
- `nfs-server` pod
- `nfs-service`
- `writer-deployment` with 2 pods

---

### 3️⃣ Check Concurrent File Writes

List the writer pods:
```bash
kubectl get pods -l app=writer
```

Pick any one pod name and tail the shared log:
```bash
kubectl exec -it <one-writer-pod> -- tail -f /shared-data/output.log
```

✔️ **Expected Output:**  
Entries like:
```bash
Written by writer-deployment-6c9fd44c9c-wv5r2 at Mon Apr 15 10:00:05 UTC 2025
Written by writer-deployment-6c9fd44c9c-jlsmv at Mon Apr 15 10:00:10 UTC 2025
```
Both pods are successfully **writing to the same log file** concurrently via RWX NFS volume.

---

## 📌 Notes

- Replace `example.com/nfs` in the **StorageClass** with your actual NFS CSI driver provisioner if using a real dynamic storage provisioner.
- This demo uses `emptyDir` on the NFS server for simplicity. In production, replace it with a **hostPath** or **PersistentVolume** for data persistence.
- The NFS server here is for **testing purposes only**. In production, you'd typically have an **external NFS server**.

---

## 🎯 What You Learn Here

✅ How to set up a **multi-pod RWX volume system in Kubernetes**  
✅ How **ReadWriteMany (RWX)** access enables shared persistent storage  
✅ How to test **concurrent writes** from multiple pods  
✅ Deploying a **headless NFS service** for in-cluster shared volumes

---

## ✅ Final Thoughts

With this:
- You’ve deployed an **in-cluster NFS server**
- Created a **StorageClass, PVC, and RWX volume**
- Mounted it to **multiple pods**
- Successfully simulated **concurrent file writes**

> This is a solid demonstration of **RWX volume patterns** in Kubernetes, perfect for clustering, shared logs, or collaborative pipelines.