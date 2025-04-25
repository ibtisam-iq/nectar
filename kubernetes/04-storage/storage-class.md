## Storage Class in Kubernetes

A `StorageClass` defines how storage should be provisioned dynamically. It provides a way to **dynamically provision PVs**. Defines how PVs are created on-demand.

### Key Characteristics:
- **Provisioner**: The component that creates the PV (e.g., AWS EBS, GCE PD, etc.).
- Tells Kubernetes what provisioner to use (e.g., AWS EBS, NFS, hostPath, etc).
- Defines **reclaim policies** (Delete, Retain, Recycle).
- Used by PVC to dynamically provision PV.

---

### StorageClass Example for AWS EBS

```yaml
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
```

---

### StorageClass Example for NFS

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs
provisioner: nfs.csi.k8s.io
parameters:
  server: nfs-server.example.com
  share: /exported/path
mountOptions:
  - vers=4.1
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

---

### StorageClass Example for CSI (EBS CSI Driver)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-sc
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

---

### PVC Using StorageClass

```yaml
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

- The `StorageClass` must be created before the PVC. The PVC will then use the `StorageClass` to dynamically provision a PV.

> ⏳ As soon as this PVC is applied, Kubernetes will **automatically provision an EBS volume**, create a matching PV, and bind it to this PVC.
