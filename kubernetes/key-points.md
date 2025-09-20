💯 You got it, sweetheart — that’s the hidden **exam trick**. Let me break it down clearly:

### ✅ Rule of Thumb for CKAD

Whenever you create **any resource** (Pod, Deployment, Job, CronJob, Service, ConfigMap, Secret, etc.):

* **Always add at least one label** in `metadata.labels`.
* Safest choice:

  ```yaml
  labels:
    app.kubernetes.io/name: <resource-name>
  ```
* This way, no matter what their script uses to check, your object will be picked up.

### 🚀 Takeaway

* If the question says *“create a Pod/Deployment/etc.”* → add labels, even if not asked.
* Labels won’t hurt you, but missing them **can cost you points**.

---

```bash
root@student-node ~ ➜  k describe svc route-apd-svc
Name:                     route-apd-svc
Labels:                   app=route-apd-svc
Selector:                 version=v1         # one label, which shares between 2 pods, so it routed the traffic to both pods.
Type:                     NodePort

Endpoints:                172.17.1.5:8080,172.17.1.7:8080    # 2 pods

root@student-node ~ ➜  k get po -o wide --show-labels
NAME                         READY   STATUS    RESTARTS   AGE     IP            NODE                 LABELS
blue-apd-5ffd7768b8-lt2jj    1/1     Running   0          17m     172.17.1.5    cluster3-node01      type-one=blue,version=v1
green-apd-84bb78c876-k9bnr   1/1     Running   0          12m     172.17.1.7    cluster3-node01      type-two=green,version=v1
```
---

Create two environment variables for the above pod with below specifications:
`GREETINGS` with the data from configmap `ckad02-config1-aecs`

```bash
env:                                # not envFrom, it doesn't support key value.
      - name: GREETINGS
        valueFrom:
          configMapKeyRef:
            key: greetings.how
            name: ckad02-config1-aecs
```
---

## same namespace of backed as of targeted service

```bash
root@student-node ~ ➜  k get svc -n global-space 
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
default-backend-service   ClusterIP   10.43.232.194   <none>        80/TCP     3m36s
food-service              ClusterIP   10.43.167.191   <none>        8080/TCP   3m36s

root@student-node ~ ➜  kubectl config use-context cluster2
Switched to context "cluster2".

root@student-node ~ ➜  k get po -n ingress-nginx 
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-56p6j       0/1     Completed   0          5m58s
ingress-nginx-admission-patch-ktwd8        0/1     Completed   0          5m58s
ingress-nginx-controller-7446d746c-596xt   1/1     Running     0          5m58s

root@student-node ~ ➜  k describe deploy -n ingress-nginx ingress-nginx-controller | grep -i Args -5
    Args:
      /nginx-ingress-controller
      --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
      --election-id=ingress-controller-leader
      --watch-ingress-without-class=true
      --default-backend-service=global-space/default-backend-service

root@student-node ~ ➜  cat 11.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-resource-xnz
  namespace: global-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /eat
        pathType: Prefix
        backend: 
          service:
            name: food-service
            port:
              number: 8080

root@student-node ~ ➜  k apply -f 11.yaml 
ingress.networking.k8s.io/ingress-resource-xnz created
```
---

## Reserving a PersistentVolume

If the PersistentVolume exists and has not reserved PersistentVolumeClaims through its `claimRef` field, then the PersistentVolume and PersistentVolumeClaim will be bound.

The binding happens regardless of some volume matching criteria, including node affinity. The control plane still checks that storage class, access modes, and requested storage size are valid.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: foo-pvc
  namespace: foo
spec:
  storageClassName: "" # Empty string must be explicitly set otherwise default StorageClass will be set
  volumeName: foo-pv
```

This method does not guarantee any binding privileges to the PersistentVolume. If other PersistentVolumeClaims could use the PV that you specify, you first need to reserve that storage volume. Specify the relevant PersistentVolumeClaim in the claimRef field of the PV so that other PVCs can not bind to it.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: foo-pv
spec:
  storageClassName: ""
  claimRef:
    name: foo-pvc
    namespace: foo
```

When we create pv and pvc without specifing any `storageClassName`, it by-default picks, `local-path` storageClass for pvc, which specifies `VolumeBindingMode:     WaitForFirstConsumer`, so pvc remains pending, unless you deployed a pod.

```bash
root@student-node ~ ➜  vi 4.yaml

root@student-node ~ ➜  k apply -f 4.yaml 
persistentvolume/cloudstack-pv created
persistentvolumeclaim/cloudstack-pvc created

root@student-node ~ ➜  k get pv,pvc
NAME                             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/cloudstack-pv   128Mi      RWO            Retain           Available                          <unset>                          7s

NAME                                   STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/cloudstack-pvc   Pending                                      local-path     <unset>                 7s

root@student-node ~ ➜  k describe pvc cloudstack-pvc 
Name:          cloudstack-pvc
Namespace:     default
StorageClass:  local-path
Status:        Pending
Volume:        
Events:
  Type    Reason                Age                From                         Message
  ----    ------                ----               ----                         -------
  Normal  WaitForFirstConsumer  11s (x5 over 66s)  persistentvolume-controller  waiting for first consumer to be created before binding

root@student-node ~ ➜  k describe sc local-path 
Name:                  local-path
IsDefaultClass:        Yes
Provisioner:           rancher.io/local-path
Parameters:            <none>
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>

root@student-node ~ ➜  vi 4.yaml                               # pod manifest is added now.

root@student-node ~ ➜  k apply -f 4.yaml 
persistentvolume/cloudstack-pv unchanged
persistentvolumeclaim/cloudstack-pvc unchanged
pod/task-pv-pod created

root@student-node ~ ➜  k get pvc                               # pod is deployed, and pvc is bound.
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
cloudstack-pvc   Bound    pvc-0466a964-3e52-40b4-b4ba-9ab0fa84c663   50Mi       RWO            local-path     <unset>                 3m11s

root@student-node ~ ➜  cat 4.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cloudstack-pv
spec:
  capacity:
    storage: 128Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/opt/cloudstack-pv"

---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cloudstack-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi

---

apiVersion: v1
kind: Pod
metadata:
  name: task-pv-pod
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: cloudstack-pvc
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage

# PVC is bound, pod is not deployed, but specify the volumeName, and storageClassName: ""

root@student-node ~ ➜  vi 1.yaml

root@student-node ~ ➜  k apply -f 1.yaml 
persistentvolume/data-pv-ckad02-str created
persistentvolumeclaim/data-pvc-ckad02-str created

root@student-node ~ ➜  k get pvc
NAME                  STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-pvc-ckad02-str   Bound    data-pv-ckad02-str   128Mi      RWO                           <unset>                 5s

root@student-node ~ ➜  cat 1.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-pv-ckad02-str
spec:
  capacity:
    storage: 128Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/opt/data-pv-ckad02-str"

---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc-ckad02-str
spec:
  storageClassName: ""                                    # added
  volumeName: data-pv-ckad02-str                          # added
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi

root@student-node ~ ➜  
```
---

## PVC Expansion

* If a **StorageClass** has

  ```yaml
  allowVolumeExpansion: true
  ```

  then any PVC created from that StorageClass can be **resized directly** by editing its `spec.resources.requests.storage`.

### Important notes:

1. **Only expansion is supported** → you cannot shrink a PVC.
2. Some volume plugins (e.g., AWS EBS, GCE PD, CSI drivers) support it, but not all.
3. If the PVC is already mounted to a Pod:

   * The underlying volume may expand immediately,
   * But the filesystem inside the container might need a **filesystem resize** (K8s does this automatically for most drivers).
4. If `allowVolumeExpansion` is missing or `false` → PVC resize attempt will be rejected.

---

## Use quotes ""

```bash
resources:
      requests:
        memory: "10Gi"
        cpu: "500m"
      limits:
        memory: "10Gi"
        cpu: "500m"

commnad:
- sleep
- "3600"

command: ["sleep", "5"]

root@student-node ~ ➜  k create cj simple-node-job -n ckad-job --schedule "*/30 * * * *" --image node -- sh -c "ps -eaf"

nginx.ingress.kubernetes.io/ssl-redirect: "false"
```
---

- PVC requires some time for binding. So, be patient.
- The manifest related to volume (pvc, pv), and resource field in pod/deployment.... delete all fields, and the apply.
- An `HTTPRoute` does not have to be in the same namespace as the `Gateway`, but it does have to be in the same namespace as the `Service` it references (unless you explicitly allow cross-namespace routing via `backendRefs.namespaces`).
- Use `kubectl api-resource` for interacting the imperative commands for **ResourceQuota and Role, ClusterRole**. Resources are plural here.
- In Kubernetes, each `volume` entry under `spec.volumes` must have a **unique name**. And if you try to add two different sources (like `persistentVolumeClaim` + `emptyDir`) under the same volume, you’ll also get an error.
- Unlike `hostPath` volumes (which **can create a path automatically** if it doesn’t exist → type: `DirectoryOrCreate`), a **local PersistentVolume (PV)** in Kubernetes expects that the directory (or device) already exists on the node.
- With `hostPath`, the `nodeAffinity` is a precaution; with `local`, it’s mandatory.

---

### **Toleration for controlplane scheduling**

* By default, the **controlplane/master node** is tainted to prevent regular workloads from running there.
* Taint looks like this (you can verify with `kubectl describe node controlplane | grep Taint`):

```
node-role.kubernetes.io/control-plane:NoSchedule
```

* If you want your Pod to run **on the controlplane node**, you must add a **toleration** in the Pod spec:

```yaml
spec:
  tolerations:
  - key: "node-role.kubernetes.io/control-plane"
    operator: "Exists"
    effect: "NoSchedule"
```

👉 Without this, the Pod will stay **Pending** because the scheduler won’t place it on the tainted node.

---

### **PVC deletion rule**

* A **PersistentVolumeClaim (PVC)** cannot be deleted while it is **still mounted by any Pod**.
* If you try to delete it directly, you’ll get stuck in `Terminating` state.
* You must first:

  1. **Delete the Pod(s)** using that PVC.
  2. Then delete the PVC.
  3. The underlying PV deletion depends on the **ReclaimPolicy** (`Retain`, `Delete`, or `Recycle`).

---

🔑 **Quick exam memory tip:**

* Want to use controlplane? → Add **toleration**.
* Want to delete a PVC? → First **delete the Pod** using it.
