# Kubernetes Volumes: Deep Dive into PV, PVC, StorageClass

This documentation provides a production-grade understanding of Kubernetes storage management using Persistent Volumes (PV), Persistent Volume Claims (PVC), and Storage Classes.

---

## 📦 1. [PersistentVolume (PV)](pv-guide.md)

A **PersistentVolume (PV)** is a piece of storage in the cluster that has been provisioned by an administrator or dynamically by Kubernetes using a **StorageClass**. It’s a cluster-wide resource.

### Key Characteristics:

- Cluster-scoped object (not namespace-bound).
- Has details about **capacity, access modes, storage backend**, etc.
- Can be **manually created** (Static) or created on demand via **StorageClass** (Dynamic).

#### ❗ Key Hint
> If you **manually write a PV**, it’s static provisioning. If you only write a PVC and `StorageClass` handles volume creation, it’s dynamic.

---

## 📄 2. [PersistentVolumeClaim (PVC)](pvc-guide.md)

A **PersistentVolumeClaim (PVC)** is a request for storage by a user. It specifies size, access modes, and storage class. The **developer** or **app owner**, usually within a namespace, creates a PVC.

### Key Characteristics:

- Namespace-scoped object.
- Describes **how much space** is needed and **how it should be accessed** (ReadWriteOnce, ReadOnlyMany, etc).
- Kubernetes **will bind a matching PV** with the PVC.

---

## ⚙️ 3. Using PVC in a Pod (Claims As Volumes)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-using-pvc
spec:
  containers:
    - name: myapp
      image: nginx
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"  # Where the data will appear in container
          name: html-volume
  volumes:
    - name: html-volume
      persistentVolumeClaim:
        claimName: pvc-manual # The PVC we created earlier # This PVC must already exist
```

### 🧠 Breakdown:

| Section                                       | Explanation                                                                 |
|-----------------------------------------------|-----------------------------------------------------------------------------|
| `volumeMounts.mountPath`                      | Where the data will be stored inside the container                          |
| `volumes.persistentVolumeClaim.claimName`     | Which PVC this Pod will use to mount storage                                |
| PVC                                           | Must exist and be bound to a suitable PV or use a dynamic StorageClass      |

This ensures data persists even if the Pod is restarted or rescheduled on a different node.

---

## ⚡ 4. Dynamic Provisioning with [StorageClass](storage-class.md) (e.g., AWS EBS)

A `StorageClass` defines how storage should be provisioned dynamically. It provides a way to **dynamically provision PVs**. Defines how PVs are created on-demand.

### Key Characteristics:
- **Provisioner**: The component that creates the PV (e.g., AWS EBS, GCE PD, etc.).
- Tells Kubernetes what provisioner to use (e.g., AWS EBS, NFS, hostPath, etc).
- Defines **reclaim policies** (Delete, Retain, Recycle).
- Used by PVC to dynamically provision PV.

### PVC Using StorageClass

```yaml
# Create a StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc # Name of the storage class (usually dynamic provisioner)
provisioner: kubernetes.io/aws-ebs  # Defines which external provisioner to use
parameters:
  type: gp2  # General purpose SSD
  fsType: ext4  # Filesystem type
reclaimPolicy: Delete  # Automatically delete volume when PVC is deleted
volumeBindingMode: WaitForFirstConsumer  # Delay volume binding until pod is scheduled
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ebs-sc  # Links to the above StorageClass # This will trigger dynamic provisioning
```

## ⚡ 5. Mounted Volumes

- **EmptyDir**: A temporary directory that exists only while the Pod is running.
- **HostPath**: A directory on the host machine.
- **ConfigMap**: A way to store configuration data as key-value pairs.
- **Secret**: A way to store sensitive information (e.g., passwords, API keys).
- **PersistentVolumeClaim**: A request for storage that can be fulfilled by a PersistentVolume.

### How to Mount Volumes
```yaml
volumeMounts:
  - name: demo-volume # name of volume mentioned in volumes.name
    mountPath: /data
volumes:
  - name: demo-volume
    emptyDir: {}
```
Click [here](volume-mounting.md) for more information on volume mounting.

---

## 📌 6. Pod Example Using Dynamic PVC

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bankapp-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bankapp-db
  template:
    metadata:
      labels:
        app: bankapp-db
    spec:
      containers:
        - name: postgres
          image: postgres:15
          ports:
            - containerPort: 5432
          volumeMounts:
            - mountPath: /var/lib/postgresql/data  # Default path for Postgres data # Inside container path
              name: db-volume # Must match volume name below
      volumes:
        - name: db-volume
          persistentVolumeClaim:
            claimName: ebs-pvc # This PVC must already exist
```

### 🔐 Security & Best Practices

| Best Practice                              | Why It Matters                                                            |
|--------------------------------------------|---------------------------------------------------------------------------|
| `ReadWriteOnce` for DBs                      | Prevent data corruption from multi-node write access                      |
| `volumeBindingMode: WaitForFirstConsumer`  | Prevents PV creation until Pod is scheduled (optimizes storage location)  |
| `Retain` reclaim policy (for prod)           | Avoids accidental data loss                                              |
| Use `StorageClass` for dynamic volumes       | Scales with your app automatically                                         |

---

## 📡 7. ReadWriteMany Example with NFS

Sometimes, we underwent **a situation where multiple pods need to read and write to the same storage location concurrently**.

In Kubernetes:
- `ReadWriteOnce (RWO)` → One pod can read/write.
- `ReadOnlyMany (ROX)` → Many pods can read.
- `ReadWriteMany (RWX)` → Many pods can read and write.

But most common cloud provisioners like EBS, GCE PD, etc., **don’t support RWX** — so to achieve **shared read-write storage** for multiple pods, we often use **NFS (or other RWX-capable storage systems)**.

> Click [here](rwx-nfs-volume.md) to know **how to set up a Kubernetes volume with ReadWriteMany access using NFS** — so multiple pods can mount the same volume concurrently and perform both read and write operations on it.

---

## 🔗 Relationship Between PV, PVC, and StorageClass

Here's how they work together:

### 📦 Static Provisioning
- You **create a PersistentVolume (PV)** manually.
- Then a **PersistentVolumeClaim (PVC)** binds to it based on specs (e.g., size, access mode).
- ❌ **No StorageClass** is needed.

### ⚙️ Dynamic Provisioning *(Most Common in Production)*
- You **create a StorageClass** first.
- Then a **PVC** requests storage using that **StorageClass**.
- Kubernetes **automatically provisions a matching PV** for that PVC using the defined StorageClass.

---

## 📌 AccessModes in Kubernetes are **Pod-level permissions** — NOT Node-level

Here’s how they really work:

| Access Mode  | Meaning                                                 | Scope        |
|:-------------|:---------------------------------------------------------|:---------------|
| `ReadWriteOnce` (RWO) | **One Pod can mount it as read-write**. It may still be accessed from multiple nodes, but **only one pod at a time can have it mounted read-write**. | **Per Pod** |
| `ReadOnlyMany` (ROX) | **Many Pods can mount it read-only at the same time** — across one or multiple nodes. | **Per Pod** |
| `ReadWriteMany` (RWX) | **Many Pods can mount it as read-write simultaneously** — across multiple nodes. | **Per Pod** |

#### ✅ So — **the unit of access is always the pod.**

---

## 🛡️ Reclaim Policies (What happens after PVC is deleted?)

| Policy  | Description                                                                 |
|---------|-----------------------------------------------------------------------------|
| Retain  | Keep the PV data after PVC deletion. Manual cleanup needed.                |
| Delete  | Automatically delete the storage backend when PVC is deleted.              |
| Recycle | *(Deprecated)* Basic scrub + reuse. Not recommended anymore.               |

## ✅ Visual Diagram: Integration Flow

```
User applies PVC
   ↓
PVC references StorageClass (if dynamic)
   ↓
StorageClass provisions PV (e.g., AWS EBS or NFS volume)
   ↓
PVC gets bound to the new PV
   ↓
Pod mounts PVC as a volume
```

---

## 🔐 Best Practices

| Area           | Recommendation                                                   |
|----------------|------------------------------------------------------------------|
| Reclaim Policy | Use `Retain` for critical apps (DBs), `Delete` for temp data     |
| Access Modes   | `ReadWriteOnce` for DBs, `ReadOnlyMany` for shared content       |
| StorageClass   | Use for dynamic provisioning with CSI drivers                    |
| Binding Mode   | Use `WaitForFirstConsumer` to improve pod scheduling             |
| Monitoring     | Watch PVC binding status: `kubectl get pvc`                      |

---

## ✅ Summary Table

| Component | Static Provisioning | Dynamic Provisioning | Purpose                          | Created By        |
|----------|----------------------|-----------------------| ----------------------------------|-------------------|
| PV       | Created manually     | Created automatically by K8s | Provides raw storage             | Admin / K8s       |
| PVC      | Must match PV        | Must reference StorageClass | Requests storage                 | Developer / User  |
| StorageClass | Not Required | Required | Defines how storage is provisioned | Admin            |
| storageClassName | Must match PV & PVC | Required only in PVC | 
| hostPath/NFS/etc | Defined in PV       | Defined in StorageClass |
| Use Case | On-premises, legacy systems | Cloud-native, scalable workloads |




