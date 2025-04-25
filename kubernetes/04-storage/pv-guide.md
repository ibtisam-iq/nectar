## PersistentVolume (PV)

A **PersistentVolume (PV)** is a piece of storage in the cluster that has been provisioned by an administrator or dynamically by Kubernetes using a **StorageClass**. It’s a cluster-wide resource.

### Key Characteristics:

- Cluster-scoped object (not namespace-bound).
- Has details about **capacity, access modes, storage backend**, etc.
- Can be **manually created** (Static) or created on demand via **StorageClass** (Dynamic).

### 🔍 Is `storageClassName` required in a PV?
- **Static provisioning**: Recommended to include it and match the PVC's `storageClassName`.
- **Manual binding (no dynamic provisioning)**: Set to `""` (empty string) to prevent Kubernetes from dynamic provisioning.
- **Dynamic provisioning**: You even do **not** create the PV. Kubernetes auto-creates it using the `StorageClass`.

---

## ✅ Example: HostPath (for local testing only; static provisioning)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
spec:
  capacity:
    storage: 10Gi  # Total size of the volume
  accessModes:
    - ReadWriteOnce  # Can be mounted as read-write by a single pod
  persistentVolumeReclaimPolicy: Retain  # Keeps the volume data after PVC is deleted
  storageClassName: manual  # Matches with PVC's storageClassName
  hostPath:
    path: "/mnt/data"  # Simulated path on the node; not used in production (used only for local testing)
    type: DirectoryOrCreate  # Create the directory if it doesn't exist
```
- For production environments, use a **StorageClass** to dynamically provision PVs.
- `hostPath` is not suitable for production environments as it relies on the node's file system.
- `Retain` reclaim policy is used here for demonstration purposes; in production, use `Delete` or `Recycle` reclaim policies.
- `ReadWriteOnce` access mode is used here for demonstration purposes; in production, use `ReadWriteMany` or `ReadOnlyMany` access modes.
- `10Gi` capacity is used here for demonstration purposes; in production, use a suitable capacity value.
> 🔥 **Note:** In production, this might use `awsElasticBlockStore`, `nfs`, or `csi drivers` instead of hostPath.

---

## ✅ Example: AWS EBS (Elastic Block Store) (static provisioning)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-ebs
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: aws-ebs
  awsElasticBlockStore:
    volumeID: vol-0123456789abcdef0  # Pre-created EBS volume ID
    fsType: ext4
```

### 📘 TL;DR:

| Property                | Value                                     |
|-------------------------|-------------------------------------------|
| Volume source           | Manually provided (`awsElasticBlockStore` with a fixed volume ID) |
| storageClassName role  | Tag to match with PVC                    |
| Who provisions the volume? | **You** (manually in AWS or on local node)  |
| Provisioning type       | ✅ **Static provisioning**                    |

---

## ✅ Example: NFS (ReadWriteMany)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteMany  # Can be mounted as RW by multiple nodes
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs
  nfs:
    path: /exported/path # points to the exported path of the NFS server, which is already set up manually.
    server: nfs-server.example.com # indicates a static NFS server, which is managed outside Kubernetes.
```

> **Note:** The **entire PV** is defined by the user, meaning **you're manually provisioning the volume**. Kubernetes isn't responsible for creating this storage; you're simply informing Kubernetes to use the specified NFS server.

---

### ✅ Example: CSI Volume (Generic CSI Plugin)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-csi
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: csi-sc
  csi:
    driver: ebs.csi.aws.com  # CSI driver name
    volumeHandle: vol-0abcd1234cdef5678  # Unique volume ID
    fsType: ext4
```
### Why It's Static Provisioning:

- **Manual EBS Volume Reference**: The `csi.volumeHandle` points to a pre-existing EBS volume (e.g., `vol-0abcd1234cdef5678`). This volume is manually created in AWS.

- **CSI Driver Reference**: The use of `csi.driver` (`ebs.csi.aws.com`) points to the CSI driver, but the volume itself is already provisioned by the user, not dynamically by Kubernetes.

- **User-Defined PV**: You're telling Kubernetes to use an already-created EBS volume, meaning you're manually provisioning the volume.

- **storageClassName**: The presence of the `storageClassName` (e.g., `csi-sc`) is still useful for matching the PVC, but it doesn't trigger dynamic provisioning here.

---

## 🚦 How to Know Whether a PV is Static or Dynamic?

| Clue | Static Provisioning | Dynamic Provisioning |
|------|---------------------|-----------------------|
| PV Manifest Exists | ✅ Yes | ❌ No |
| PVC references a known `storageClassName` | ✅ Optional | ✅ Required |
| PV has `storageClassName` matching PVC | ✅ Yes | 🚫 Auto-filled |
| PVC triggers StorageClass provisioning | ❌ No | ✅ Yes |
| PV created manually by admin | ✅ Yes | ❌ No |

### ❗ Key Hint
> If you **manually write a PV**, it’s static provisioning. If you only write a PVC and `StorageClass` handles volume creation, it’s dynamic.

---

### 📚 Further Reading
