## Q1

Your task involves setting up storage components in a Kubernetes cluster. Follow these steps:

**Step 1**: Create a Storage Class named `blue-stc-cka` with the following properties:

- Provisioner: kubernetes.io/no-provisioner
- Volume binding mode: WaitForFirstConsumer

**Step 2**: Create a Persistent Volume (PV) named `blue-pv-cka` with the following properties:

- Capacity: 100Mi
- Access mode: ReadWriteOnce
- Reclaim policy: Retain
- Storage class: blue-stc-cka
- Local path: /opt/blue-data-cka
- Node affinity: Set node affinity to create this PV on `controlplane`.

**Step 3**: Create a Persistent Volume Claim (PVC) named `blue-pvc-cka` with the following properties:

- Access mode: ReadWriteOnce
- Storage class: blue-stc-cka
- Storage request: 50Mi

The volume should be bound to `blue-pv-cka`. 

```bash
controlplane:~$ k get pv,pvc,sc
NAME                           CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/blue-pv-cka   100Mi      RWO            Retain           Available           blue-stc-cka   <unset>                          9s

NAME                                 STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/blue-pvc-cka   Pending                                      blue-stc-cka   <unset>                 9s

NAME                                               PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
storageclass.storage.k8s.io/blue-stc-cka           kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  9s
storageclass.storage.k8s.io/local-path (default)   rancher.io/local-path          Delete          WaitForFirstConsumer   false                  8d

Events:
  Type    Reason                Age                   From                         Message    # you haven't yet created pod 
  ----    ------                ----                  ----                         -------
  Normal  WaitForFirstConsumer  88s (x12 over 4m12s)  persistentvolume-controller  waiting for first consumer to be created before binding

Events:
  Type     Reason            Age   From               Message    # Your PV has node affinity set to controlplane.
  ----     ------            ----  ----               -------    # You need to add a toleration so your Pod can land on the controlplane node.
  Warning  FailedScheduling  2m1s  default-scheduler  0/2 nodes are available: 1 node(s) didn't find available persistent volumes to bind, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

Events:
  Type     Reason       Age               From               Message  # You’re using a local PV pointing to /opt/blue-data-cka on the controlplane node.
  ----     ------       ----              ----               -------  # It does not create the directory automatically. For a local PV, the path must already exist on the node.
  Normal   Scheduled    32s               default-scheduler  Successfully assigned default/test-pod-cka to controlplane
  Warning  FailedMount  1s (x7 over 32s)  kubelet            MountVolume.NewMounter initialization failed for volume "blue-pv-cka" : path "/opt/blue-data-cka" does not exist

controlplane:~$ sudo mkdir -p /opt/blue-data-cka
controlplane:~$ sudo chmod 777 /opt/blue-data-cka

controlplane:~$ k delete pvc blue-pvc-cka 
persistentvolumeclaim "blue-pvc-cka" deleted          # can't delete, pod is using this pvc
^Ccontrolplane:~$ k delete po test-pod-cka 
pod "test-pod-cka" deleted

controlplane:~$ k apply -f abc.yaml 
storageclass.storage.k8s.io/blue-stc-cka created
persistentvolume/blue-pv-cka created
persistentvolumeclaim/blue-pvc-cka created
pod/test-pod-cka created

controlplane:~$ k get po
NAME           READY   STATUS              RESTARTS   AGE
test-pod-cka   0/1     ContainerCreating   0          5s
controlplane:~$ k get po
NAME           READY   STATUS    RESTARTS   AGE
test-pod-cka   1/1     Running   0          8s
controlplane:~$ cat abc.yaml 
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: blue-stc-cka
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: blue-pv-cka
spec:
  capacity:
    storage: 100Mi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: blue-stc-cka
  local:
    path: /opt/blue-data-cka
#  type: DirectoryOrCreate   # Error from server (BadRequest): strict decoding error: unknown field "spec.local.type"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - controlplane
---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: blue-pvc-cka
spec:
  volumeName: blue-pv-cka          # If it were added, volumeBindingMode: WaitForFirstConsumer becomes nullified.
  storageClassName: blue-stc-cka
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi

---

apiVersion: v1
kind: Pod
metadata:
  name: test-pod-cka
spec:
  tolerations:
  - key: "node-role.kubernetes.io/control-plane"
    operator: "Exists"
    effect: "NoSchedule"
  containers:
  - name: test-container
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: blue-pvc-cka
controlplane:~$ vi abc.yaml 
controlplane:~$ 
```

---

## Q2 Projected Volume

In the `ckad14-sa-projected` namespace, configure the `ckad14-api-pod` Pod to include a **projected volume** named `vault-token`.

Mount the service account token to the container at `/var/run/secrets/tokens`, with an expiration time of `7000` seconds.

Additionally, set the intended audience for the token to `vault` and path to `vault-token`.

Got it ✅
You want to configure a Pod (`ckad14-api-pod`) in the **`ckad14-sa-projected`** namespace so that it uses a **projected volume** for a ServiceAccount token, with:

* **Volume name:** `vault-token`
* **Mount path:** `/var/run/secrets/tokens`
* **Expiration:** `7000s`
* **Audience:** `vault`
* **Path inside projected volume:** `vault-token`

Here’s the YAML you should edit/apply (key parts are the `projected` volume and its mount):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ckad14-api-pod
  namespace: ckad14-sa-projected
spec:
  containers:
  - name: main
    image: nginx   # or whatever the original image is
    volumeMounts:
    - name: vault-token
      mountPath: /var/run/secrets/tokens
      readOnly: true
  volumes:
  - name: vault-token
    projected:
      sources:
      - serviceAccountToken:
          path: vault-token
          expirationSeconds: 7000
          audience: vault
```

### Explanation

* `volumes.projected` → lets you combine sources; here we use `serviceAccountToken`.
* `path: vault-token` → the token file name inside `/var/run/secrets/tokens`.
* `expirationSeconds: 7000` → sets token validity.
* `audience: vault` → sets the intended audience claim in the JWT.
* `volumeMounts` → mounts the projected volume into the container.

👉 You can patch the existing pod like this if it already exists:

```bash
kubectl -n ckad14-sa-projected edit pod ckad14-api-pod
```

and add the **`volumeMounts`** + **`volumes`** sections exactly as above.

---

## Q3 PVC/PV Resizing

A persistent volume called `papaya-pv-ckad09-str` is already created with a storage capacity of `150Mi`. It's using the `papaya-stc-ckad09-str` storage class with the path `/opt/papaya-stc-ckad09-str`.

Also, a persistent volume claim named `papaya-pvc-ckad09-str` has been created on this cluster. This PVC has requested `50Mi` of storage from `papaya-pv-ckad09-str` volume. Resize the PVC to `80Mi` and make sure the PVC is in Bound state.

**Solution:** Delete the pv and pvc, get `-o yaml` and do editing, make sure remove all the extra fields.

Got it 👍 Let’s solve this step by step.

### 🔹 Situation

* **PV:** `papaya-pv-ckad09-str`

  * Size: `150Mi`
  * StorageClass: `papaya-stc-ckad09-str`
  * Path: `/opt/papaya-stc-ckad09-str`

* **PVC:** `papaya-pvc-ckad09-str`

  * Size: `50Mi`
  * Bound to the above PV.
  * Task: **Resize PVC from `50Mi` → `80Mi`**.

### 🔹 Steps to Resize the PVC

1. **Check if storage class allows expansion**
   Run:

   ```bash
   kubectl get sc papaya-stc-ckad09-str -o yaml | grep allowVolumeExpansion
   ```

   If `allowVolumeExpansion: true` is present → you can resize directly.
   If not present → you may need to edit the StorageClass and add:

   ```yaml
   allowVolumeExpansion: true
   ```

2. **Edit the PVC to request more storage**

   ```bash
   kubectl edit pvc papaya-pvc-ckad09-str
   ```

   Change:

   ```yaml
   resources:
     requests:
       storage: 50Mi
   ```

   To:

   ```yaml
   resources:
     requests:
       storage: 80Mi
   ```
Thanks for the details ❤️ this explains why your PVC is **Pending** instead of **Bound**.

👉 The issue is:

* The **PV** is created with the name `papaya-pv-ckad09-str`.
* The **PVC** is trying to bind to a PV with the name **`papaya-pvc-ckad09-str`** (notice the mismatch).
* Because of this, the PVC is stuck in **Pending**.

```bash
root@student-node ~ ➜  k describe pvc papaya-pvc-ckad09-str 
Name:          papaya-pvc-ckad09-str
Namespace:     default
StorageClass:  papaya-stc-ckad09-str
Status:        Pending
Volume:        papaya-pvc-ckad09-str              # wrong name
Labels:        <none>
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      0
Access Modes:  
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>

root@student-node ~ ➜  k get pv
NAME                   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                           STORAGECLASS            VOLUMEATTRIBUTESCLASS   REASON   AGE
papaya-pv-ckad09-str   150Mi      RWO            Retain           Available   default/papaya-pvc-ckad09-str   papaya-stc-ckad09-str   <unset>                          2m30s

root@student-node ~ ➜  vi 2.yaml

root@student-node ~ ✖ k replace -f 2.yaml  --force
persistentvolumeclaim "papaya-pvc-ckad09-str" deleted
persistentvolume "papaya-pv-ckad09-str" deleted
persistentvolumeclaim/papaya-pvc-ckad09-str replaced
persistentvolume/papaya-pv-ckad09-str replaced

root@student-node ~ ➜  k describe pvc papaya-pvc-ckad09-str 
Name:          papaya-pvc-ckad09-str
Namespace:     default
StorageClass:  papaya-stc-ckad09-str
Status:        Bound
Volume:        papaya-pv-ckad09-str
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      150Mi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       <none>
Events:        <none>

root@student-node ~ ➜  k get pv,pvc
NAME                                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS            VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/papaya-pv-ckad09-str   150Mi      RWO            Retain           Bound    default/papaya-pvc-ckad09-str   papaya-stc-ckad09-str   <unset>                          43s

NAME                                          STATUS   VOLUME                 CAPACITY   ACCESS MODES   STORAGECLASS            VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/papaya-pvc-ckad09-str   Bound    papaya-pv-ckad09-str   150Mi      RWO            papaya-stc-ckad09-str   <unset>                 44s

root@student-node ~ ➜  cat 2.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: papaya-pvc-ckad09-str
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 80Mi
  storageClassName: papaya-stc-ckad09-str
  volumeMode: Filesystem
  volumeName: papaya-pv-ckad09-str

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: papaya-pv-ckad09-str
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 150Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: papaya-pvc-ckad09-str
    namespace: default
  local:
    path: /opt/papaya-stc-ckad09-str
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - cluster1-controlplane
  persistentVolumeReclaimPolicy: Retain
  storageClassName: papaya-stc-ckad09-str
  volumeMode: Filesystem

root@student-node ~ ➜    
```

---

## Q4

A storage class called `coconut-stc-cka01-str` was created earlier. Use this storage class to create a persistent volume called `coconut-pv-cka01-str` as per below requirements:

- Capacity should be `100Mi`.

- The volume type should be `hostpath` and the path should be `/opt/coconut-stc-cka01-str`.

- Use `coconut-stc-cka01-str` storage class.

- This volume must be created on `cluster1-node01` (the `/opt/coconut-stc-cka01-str` directory already exists on this node).

- It must have a label with `key: storage-tier` with `value: gold`.

Also, create a persistent volume claim with the name `coconut-pvc-cka01-str` as per the below specs:

- Request `50Mi` of storage from `coconut-pv-cka01-str` PV. It must use **matchLabels** to use the PV.

- Use `coconut-stc-cka01-str` storage class.

- The access mode must be `ReadWriteMany`.

```bash
cluster1-controlplane ~ ➜  vi 10.yaml

cluster1-controlplane ~ ➜  k apply -f 10.yaml 
persistentvolume/coconut-pv-cka01-str created
persistentvolumeclaim/coconut-pvc-cka01-str created

cluster1-controlplane ~ ➜  k get pvc
NAME                    STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS            VOLUMEATTRIBUTESCLASS   AGE
coconut-pvc-cka01-str   Pending                                      coconut-stc-cka01-str   <unset>                 9s

cluster1-controlplane ~ ➜  k describe sc coconut-stc-cka01-str 
Name:            coconut-stc-cka01-str
IsDefaultClass:  No
Provisioner:           kubernetes.io/no-provisioner
Parameters:            type=local
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>

cluster1-controlplane ~ ➜  k get pvc
NAME                    STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS            VOLUMEATTRIBUTESCLASS   AGE
coconut-pvc-cka01-str   Pending                                      coconut-stc-cka01-str   <unset>                 49s

cluster1-controlplane ~ ➜  cat 10.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: coconut-pv-cka01-str
  labels:
    storage-tier: gold
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  storageClassName: coconut-stc-cka01-str
  hostPath:
    path: /opt/coconut-stc-cka01-str
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - cluster1-node01
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: coconut-pvc-cka01-str
spec:
  storageClassName: coconut-stc-cka01-str
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Mi
  selector:
    matchLabels:
      storage-tier: gold
```
In short: with `hostPath`, the `nodeAffinity` is a precaution; with `local`, it’s mandatory.

---

## Q5 

Create a Pod named `pod1` of image `nginx:alpine`
- Make key `tree` of ConfigMap `trauerweide` available as environment variable `TREE1`
- Mount all keys of ConfigMap `birke` as volume. The *files* should be available under `/etc/birke/*`
- Test env+volume access in the running Pod

```bash
k run pod1 --image nginx:alpine
pod/pod1 created
k edit po pod1     # mountPath: /etc/birke , not /etc/birke/*
error: pods "pod1" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-654694799.yaml"
error: Edit cancelled, no valid changes were saved.
controlplane:~$ k replace -f /tmp/kubectl-edit-654694799.yaml --force
pod "pod1" deleted
pod/pod1 replaced
controlplane:~$ k get po
NAME   READY   STATUS    RESTARTS   AGE
pod1   1/1     Running   0          5s

controlplane:~$ kubectl exec pod1 -- env | grep "TREE1=trauerweide"eide"
TREE1=trauerweide
controlplane:~$ k get cm
NAME               DATA   AGE
birke              3      19m
kube-root-ca.crt   1      4d9h
trauerweide        1      20m
controlplane:~$ kubectl exec pod1 -- cat /etc/birke/tree
birkecontrolplane:~$ 
controlplane:~$ kubectl exec pod1 -- cat /etc/birke/level
3controlplane:~$ 
controlplane:~$ kubectl exec pod1 -- cat /etc/birke/department
parkcontrolplane:~$
parkcontrolplane:~$ k describe cm birke 
Name:         birke
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
department:
----
park

level:
----
3

tree:
----
birke


BinaryData
====

Events:  <none>
```
---
