## PersistentVolumeClaim (PVC)

A **PersistentVolumeClaim (PVC)** is a request for storage by a user. It specifies size, access modes, and storage class. The **developer** or **app owner**, usually within a namespace, creates a PVC.

### Key Characteristics:

- Namespace-scoped object.
- Describes **how much space** is needed and **how it should be accessed** (ReadWriteOnce, ReadOnlyMany, etc).
- Kubernetes **will bind a matching PV** with the PVC.

---

### Key Fields in PVC YAML

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-manual
spec:
  accessModes:
    - ReadWriteOnce  # Can be mounted on one node # Matches the PV
  resources:
    requests:
      storage: 10Gi  # Requested size # Must be <= available PV
  storageClassName: manual  # Matches the PV or StorageClass
# storageClassName: aws-ebs
# storageClassName: nfs
# storageClassName: csi-sc

```
- The value of `storageClassName` is not fixed; it can be any name, but it **must match** the name of the `StorageClass` or the value in the PV and PVC manifest for proper binding.
- 🔄 This PVC will only bind to a PV that also has `storageClassName: manual`.
> 📌 PVC binds to a suitable PV if `accessModes`, `storageClassName`, and `requests.storage` match.
---

## ⚙️ Using PVC in a Pod (Claims As Volumes)

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

## Futher Reading