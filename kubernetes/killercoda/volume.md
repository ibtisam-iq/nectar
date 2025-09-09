## Persistant volume

### 🔹 Requirements Breakdown

* Pod name: **`alpine-pod-pod`**
* Image: **`alpine:latest`**
* Container name: **`alpine-container`**
* Use **command**: `/bin/sh`
* Use **args**: `["-c", "tail -f /config/log.txt"]`
* Mount a **volume** named `config-volume` from an existing **ConfigMap** `log-configmap`
* Mount path: `/config`
* Restart policy: **Never**

### ✅ Final YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine-pod-pod
spec:
  restartPolicy: Never
  containers:
  - name: alpine-container
    image: alpine:latest
    command:
    - /bin/sh
    - -c
    - tail -f /config/log.txt
    volumeMounts:
    - name: config-volume
      mountPath: /config
  volumes:
  - name: config-volume
    configMap:
      name: log-configmap
```
---

```bash
 volumes:
  - name: shared-storage
    hostPath:
      path: "/var/www/shared"
      type: DirectoryOrCreate
  - name: shared-storage
    persistentVolumeClaim:
      claimName: my-pvc-cka

controlplane:~$ k replace -f /tmp/kubectl-edit-3424260573.yaml --force
pod "my-pod-cka" deleted
The Pod "my-pod-cka" is invalid: spec.volumes[1].name: Duplicate value: "shared-storage"

  volumes:
  - name: shared-storage
    hostPath:
      path: "/var/www/shared"
      type: DirectoryOrCreate
    persistentVolumeClaim:
      claimName: my-pvc-cka

controlplane:~$ k replace -f /tmp/kubectl-edit-3424260573.yaml --force
The Pod "my-pod-cka" is invalid: 
* spec.volumes[0].persistentVolumeClaim: Forbidden: may not specify more than 1 volume type
```
---

An existing nginx pod, my-pod-cka and Persistent Volume Claim (PVC) named my-pvc-cka are available. Your task is to implement the following modifications:

NOTE:- PVC to PV binding and my-pod-cka pods sometimes takes around 2Mins to Up & Running So Please wait
Update the pod to include a sidecar container that uses the busybox image. Ensure that this sidecar container remains operational by including an appropriate command "tail -f /dev/null" .

Share the shared-storage volume between the main application and the sidecar container, mounting it at the path /var/www/shared . Additionally, ensure that the sidecar container has read-only access to this shared volume.

Got it 👍 this is a **sidecar container with shared PVC mount** use case.
Since you already have an **nginx pod (`my-pod-cka`)** and a **PVC (`my-pvc-cka`)**, we’ll just update the pod spec.

Here’s how the updated `my-pod-cka` YAML would look:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod-cka
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: shared-storage
          mountPath: /var/www/shared   # main container gets full access

    - name: busybox-sidecar
      image: busybox
      command: [ "sh", "-c", "tail -f /dev/null" ]
      volumeMounts:
        - name: shared-storage
          mountPath: /var/www/shared   # sidecar mounts the same PVC
          readOnly: true               # sidecar has READ-ONLY access

  volumes:
    - name: shared-storage
      persistentVolumeClaim:
        claimName: my-pvc-cka
```

Exactly 👍 no need to use a `hostPath` here.

The **question already tells you**:

* A **PVC (`my-pvc-cka`)** exists.
* That PVC is already bound to some **PV**.
* Your job is just to mount that same PVC into both containers.

So this part:

```yaml
volumes:
  - name: shared-storage
    persistentVolumeClaim:
      claimName: my-pvc-cka
```

is **all that’s required** ✅

🔑 Why not `hostPath`?

* `hostPath` ties storage to a specific node’s filesystem (not portable, not recommended for exam scenarios unless explicitly asked).
* Since a PVC is already provided, Kubernetes will ensure the volume is provisioned/attached from the bound PV, no need to mess with host paths.

So in your pod update, just keep the **PVC reference** exactly as you showed — **no `hostPath` needed**.

---

Your task involves setting up storage components in a Kubernetes cluster. Follow these steps:

Step 1: Create a Storage Class named blue-stc-cka with the following properties:

- Provisioner: kubernetes.io/no-provisioner
- Volume binding mode: WaitForFirstConsumer
Step 2: Create a Persistent Volume (PV) named blue-pv-cka with the following properties:

- Capacity: 100Mi
- Access mode: ReadWriteOnce
- Reclaim policy: Retain
- Storage class: blue-stc-cka
- Local path: /opt/blue-data-cka
- Node affinity: Set node affinity to create this PV on controlplane .
Step 3: Create a Persistent Volume Claim (PVC) named blue-pvc-cka with the following properties:

- Access mode: ReadWriteOnce
- Storage class: blue-stc-cka
- Storage request: 50Mi
The volume should be bound to blue-pv-cka 

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
## PVC is pending

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

```bash
controlplane:~$ k describe pvc postgres-pvc 
Name:          postgres-pvc

Events:
  Type     Reason          Age                 From                         Message     # reduce pvc size, correct pvc accessMode
  ----     ------          ----                ----                         -------
  Warning  VolumeMismatch  11s (x7 over 101s)  persistentvolume-controller  Cannot bind to requested volume "postgres-pv": requested PV is too small

  Warning  VolumeMismatch  7s (x3 over 37s)  persistentvolume-controller  Cannot bind to requested volume "postgres-pv": incompatible accessMode
```
---

Volume name should be volume-share of type emptyDir.

After creating the pod, exec into the first container i.e volume-container-devops-1, and just for testing create a file blog.txt with any content under the mounted path of first container i.e /tmp/blog.

The file blog.txt should be present under the mounted path /tmp/games on the second container volume-container-devops-2 as well, since they are using a shared volume.

```bash
thor@jumphost ~$ k get po
NAME                  READY   STATUS    RESTARTS   AGE
volume-share-devops   2/2     Running   0          9s

thor@jumphost ~$ k exec volume-share-devops -it -c volume-container-devops-1 -- sh
sh-5.2# touch /tmp/blog/blog.txt
sh-5.2# ls /tmp/blog/blog.txt 
/tmp/blog/blog.txt
sh-5.2# exit
exit

thor@jumphost ~$ k exec volume-share-devops -it -c volume-container-devops-2 -- sh
sh-5.2# ls /tmp/games/
blog.txt
sh-5.2# 
```
---

Create a pod named webserver.

Create an emptyDir volume shared-logs.

Create two containers from nginx and ubuntu images with latest tag only and remember to mention tag i.e nginx:latest, nginx container name should be nginx-container and ubuntu container name should be sidecar-container on webserver pod.

Add command on sidecar-container "sh","-c","while true; do cat /var/log/nginx/access.log /var/log/nginx/error.log; sleep 30; done"

Mount the volume shared-logs on both containers at location /var/log/nginx, all containers should be up and running.

Got it 👍 Thanks for pasting the full manifest.

Here’s why the lab marked it wrong:

* In the `nginx-container`, the **volumeMount** shows `- mountPath: /var/log/nginx`.
* But in the YAML, Kubernetes interprets `/var/log/nginx` and `/var/log/nginx/` as two **different strings**.
* The grader is strict and expects exactly **`/var/log/nginx/` (with trailing slash)**.

That’s why you got ❌ even though functionally your pod works.

✅ Corrected YAML (only the mountPath needs fixing):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webserver
spec:
  volumes:
    - name: shared-logs
      emptyDir: {}
  containers:
    - name: nginx-container
      image: nginx:latest
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx/   # <- notice the trailing slash
    - name: sidecar-container
      image: ubuntu:latest
      command: ["sh", "-c", "while true; do cat /var/log/nginx/access.log /var/log/nginx/error.log; sleep 30; done"]
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx/   # <- same here
```

---
