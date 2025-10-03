# 📦 Kubernetes Volumes – Troubleshooting Rules

## 🔹 1. PVC Pending

* Symptoms:

  * `STATUS = Pending`
  * `CAPACITY` & `ACCESS MODES` are **empty** → no matching PV bound.

* Causes:

  * **Mismatch** between PVC & PV:

    * `accessModes` don’t match (`ReadWriteOnce` vs `ReadOnlyMany`).
    * `storage` request > PV’s available capacity.
    * `storageClassName` mismatch.
    * PV not in `Available` state (already bound).

## 🔹 2. StorageClass Troubles

* If PVC specifies `storageClassName`, it must match:

  * PV’s `storageClassName` (for static binding), OR
  * A valid SC object (for dynamic provisioning).
* If PVC sets `storageClassName: ""` → means **no storage class**, binding must be with a manually created PV.

## 🔹 3. Mounting Volumes with Multiple Files

* **Mount directory** → when you need all contents (multiple files/keys).
* **Mount with subPath** → when you need just one file or want to avoid overwriting existing directory.

* **No `subPath` → whole directory mounted.**
* **With `subPath` → single file/key mounted.**

---

## Q1 PVC is pending, wrong PVC accessMode

```bash
controlplane:~$ k get pvc
NAME     STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
my-pvc   Pending                                      standard       <unset>                 98s
controlplane:~$ k get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
my-pv   100Mi      RWO            Retain           Available           standard       <unset>                          17s
controlplane:~$ k describe pvc my-pvc 
Name:          my-pvc
Namespace:     default
StorageClass:  standard
Status:        Pending
Volume:        
Labels:        <none>
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      
Access Modes:  
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type     Reason              Age               From                         Message
  ----     ------              ----              ----                         -------
  Warning  ProvisioningFailed  4s (x4 over 35s)  persistentvolume-controller  storageclass.storage.k8s.io "standard" not found
controlplane:~$ k get sc
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  8d

controlplane:~$ k edit pvc my-pvc 
error: persistentvolumeclaims "my-pvc" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-3501973448.yaml"
error: Edit cancelled, no valid changes were saved.
controlplane:~$ k replace -f /tmp/kubectl-edit-3501973448.yaml --force
persistentvolumeclaim "my-pvc" deleted
persistentvolumeclaim/my-pvc replaced
controlplane:~$ k get pvc
NAME     STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
my-pvc   Bound    my-pv    100Mi      RWO            standard       <unset>                 4s
controlplane:~$ k describe pvc my-pvc 
Name:          my-pvc
Namespace:     default
StorageClass:  standard
Status:        Bound
Volume:        my-pv
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      100Mi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>
controlplane:~$ 
```

Ahh, sweetheart ❤️ you’ve hit one of those Kubernetes PVC/PV binding quirks that often confuses people (and is a **hot CKA exam trap**). Let’s break it down carefully:

### 🔑 What you’re seeing

Your PVC says:

```
StorageClass: standard
```

But your cluster’s available storage classes are:

```
NAME                   PROVISIONER             ...
local-path (default)   rancher.io/local-path
```

There is **no `standard` StorageClass** in your cluster. That’s why the event shows:

```
Warning  ProvisioningFailed  ...  storageclass.storage.k8s.io "standard" not found
```

### 🎯 Why this happens

* **PVC references a StorageClass (`standard`)** that doesn’t exist.
* The **provisioning controller** looks for that class → doesn’t find it → complains.
* Meanwhile, you **also have a static PV (`my-pv`)** with:

  ```
  storageClassName: standard
  ```

  So the PVC and PV could match *if other conditions (capacity + accessModes)* align.

👉 But the **error comes first from the dynamic provisioning path**: Kubernetes always tries to use the StorageClass defined in the PVC.
If it doesn’t exist, you see that "not found" event — even if eventually the static PV could be bound manually.

### ✅ Why it worked after you fixed accessMode/capacity

Once you aligned:

* PVC requested capacity ≤ PV’s capacity
* PVC’s accessMode matched PV’s accessMode

Then the binder saw:
👉 “Hey, I already have a **static PV** with `storageClassName=standard` available!”

So it skipped dynamic provisioning, and directly **bound the PVC to your PV** — even though the `standard` StorageClass object itself doesn’t exist.

That’s why the misleading error appeared earlier — Kubernetes first *tries provisioning dynamically* but only later falls back to matching a static PV.

### 🛠️ How to avoid this confusion

1. If you want to use **dynamic provisioning**:

   * Make sure the StorageClass exists (`standard` in your case).
   * Example:

     ```bash
     kubectl get sc
     ```

     → If not found, either create it or use the default (`local-path` in your cluster).

2. If you want to use a **static PV/PVC binding** (like you did):

   * Ensure both PV and PVC have the **same `storageClassName`** (can even be `""`/empty).
   * Example:

     ```yaml
     storageClassName: ""
     ```

     in both PV and PVC → tells Kubernetes “don’t use dynamic provisioning, just bind statically.”

### ⚡ Golden Rule (CKA tip)

* **PVC with `storageClassName` set** → triggers dynamic provisioning unless an existing PV matches.
* **PVC with `storageClassName: ""`** → skips provisioning and only looks for matching PVs.
* **Error messages** can be misleading because they always mention "StorageClass not found" even if the real issue is AccessMode/Capacity mismatch.

👉 So in your case, sweetheart:

* The error showed up because Kubernetes was looking for a `standard` StorageClass that didn’t exist.
* But after you fixed accessModes/capacity, the PVC successfully matched the static PV, so binding succeeded regardless.

---
