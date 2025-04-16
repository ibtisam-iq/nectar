# ReadWriteMany (RWX) Example with NFS

In certain scenarios, multiple pods need to **read from and write to the same storage location concurrently**. Kubernetes handles these requirements using **ReadWriteMany (RWX)** access modes. While most common cloud block storage solutions (like EBS or GCE PD) do not support RWX, **NFS (Network File System)** is a widely used option to enable this.

This section demonstrates how to set up **shared storage using NFS with RWX access** in Kubernetes.

---

## 🎯 When to Use RWX Volumes
Use **ReadWriteMany (RWX)** volumes when:
- Multiple pods need to **read/write files to the same storage directory**
- You’re running **web server clusters sharing static content**
- **Microservices exchange data files or logs through a shared directory**
- **Data pipelines** need to store temporary or intermediate files accessible by multiple jobs
- You need to perform **log aggregation** in a central location

---

## 🛠️ StorageClass for NFS

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-sc
provisioner: example.com/nfs  # Replace this with your NFS CSI driver name
parameters:
  archiveOnDelete: "false"  # Optional: defines what happens to storage after PVC deletion
```

- **StorageClass** acts as a storage type template.
- The `provisioner` specifies the external storage plugin (in this case, an NFS CSI driver).
- `archiveOnDelete` is an example parameter (depending on the provisioner implementation).

---

## 📦 PersistentVolumeClaim (PVC) Requesting RWX Access

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
    - ReadWriteMany  # RWX access mode
  resources:
    requests:
      storage: 5Gi
  storageClassName: nfs-sc
```

- Requests **5Gi of shared storage**
- Specifies **ReadWriteMany (RWX)** so multiple pods can mount and write concurrently
- Uses the previously defined **nfs-sc** StorageClass

---

## 🐳 Pod Using the Shared Volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
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

- Deploys a **Pod running NGINX**
- Mounts the **shared-pvc** at `/usr/share/nginx/html`
- If multiple pods use the same PVC with RWX access, they can all **read/write files in the same directory**

---

## 📝 Why RWX matters:
Without RWX support:
- **Pods can’t safely share storage** (with RWO, only one pod can mount the volume as read-write)
- NFS (or other RWX-providing systems) **unlocks this shared access pattern**

---

## ✅ Summary  
This example demonstrates how to:
- **Provision a StorageClass for NFS**
- **Create a PersistentVolumeClaim (PVC)** requesting RWX access
- **Deploy a pod that mounts and uses the shared volume**

By using **NFS with ReadWriteMany access**, multiple pods can **share, read, and write** to the same persistent storage concurrently — enabling reliable and scalable shared data use cases in Kubernetes.

---

**Example Use Cases:**

Click [here](rwx-nfs-volume-example.md) — let’s extend your guide like a pro with an example!


