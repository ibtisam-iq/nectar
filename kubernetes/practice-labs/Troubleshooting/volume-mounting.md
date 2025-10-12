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

##  PVC is pending: reduce pvc size, wrong pvc `accessMode`

```bash
controlplane:~$ k describe pvc postgres-pvc 
Name:          postgres-pvc

Events:
  Type     Reason          Age                 From                         Message     # reduce pvc size, wrong pvc accessMode
  ----     ------          ----                ----                         -------
  Warning  VolumeMismatch  11s (x7 over 101s)  persistentvolume-controller  Cannot bind to requested volume "postgres-pv": requested PV is too small

  Warning  VolumeMismatch  7s (x3 over 37s)  persistentvolume-controller  Cannot bind to requested volume "postgres-pv": incompatible accessMode
```

---

## Q2 Pod is pending

Wrong PVC Name, then wrong pvc storageClassName, then wrong tag

```bash
Events:
  Type     Reason            Age                 From               Message   
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  21s   default-scheduler  0/2 nodes are available: persistentvolumeclaim "pvc-redis" not found. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

  Warning  FailedScheduling  5m54s               default-scheduler  0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

  Normal   Scheduled         2m5s                default-scheduler  Successfully assigned default/redis-pod to node01
  Normal   Pulling           66s (x3 over 2m5s)  kubelet            Pulling image "redis:latested"
  Warning  Failed            55s (x3 over 113s)  kubelet            Failed to pull image "redis:latested": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/redis:latested": failed to resolve reference "docker.io/library/redis:latested": docker.io/library/redis:latested: not found
  Warning  Failed            55s (x3 over 113s)  kubelet            Error: ErrImagePull
  Normal   BackOff           30s (x4 over 113s)  kubelet            Back-off pulling image "redis:latested"
  Warning  Failed            30s (x4 over 113s)  kubelet            Error: ImagePullBackOff
```

---

## Q3 wrong `accesssMode` in PVC

```bash
controlplane:~$ k get pvc,pv
NAME                               STATUS    VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/my-pvc-cka   Pending   my-pv-cka   0                         standard       <unset>                 82s

NAME                         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/my-pv-cka   100Mi      RWO            Retain           Available           standard       <unset>                          83s
controlplane:~$ k get sc
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  8d
controlplane:~$ k get po
NAME         READY   STATUS    RESTARTS   AGE
my-pod-cka   0/1     Pending   0          2m14s

Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  2m31s  default-scheduler  0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

controlplane:~$ k describe pvc my-pvc-cka 
Name:          my-pvc-cka
Events:
  Type     Reason          Age                  From                         Message
  ----     ------          ----                 ----                         -------
  Warning  VolumeMismatch  8s (x15 over 3m30s)  persistentvolume-controller  Cannot bind to requested volume "my-pv-cka": incompatible accessMode

controlplane:~$ k edit pvc my-pvc-cka 
error: persistentvolumeclaims "my-pvc-cka" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-2244335843.yaml"
error: Edit cancelled, no valid changes were saved.
controlplane:~$ k replace -f /tmp/kubectl-edit-2244335843.yaml --force
persistentvolumeclaim "my-pvc-cka" deleted
persistentvolumeclaim/my-pvc-cka replaced

controlplane:~$ k get pvc
NAME         STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
my-pvc-cka   Bound    my-pv-cka   100Mi      RWO            standard       <unset>                 13s
controlplane:~$ k get po
NAME         READY   STATUS    RESTARTS   AGE
my-pod-cka   1/1     Running   0          5m34s
controlplane:~$ 
```

---

## Q4: could not open error log file: open() `/var/log/nginx/error.log`

```bash
root@student-node ~ ➜  cat ckad-flash89.yaml 

apiVersion: v1
kind: Pod
metadata:
  name: ckad-flash89-aom
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: flash-logs
          mountPath: /var/log
    - name: busybox
      image: busybox
      command:
        - /bin/sh
        - -c
        - sleep 10000
      volumeMounts:
        - name: flash-logs
          mountPath: /usr/src
  volumes:
    - name: flash-logs
      emptyDir: {}

root@student-node ~ ➜  k get po ckad-flash89-aom 
NAME               READY   STATUS             RESTARTS      AGE
ckad-flash89-aom   1/2     CrashLoopBackOff   6 (89s ago)   7m3s

root@student-node ~ ➜  k describe po ckad-flash89-aom 
Name:             ckad-flash89-aom
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Warning  BackOff    115s (x26 over 7m15s)  kubelet            Back-off restarting failed container nginx in pod ckad-flash89-aom_default(b0a635cf-ba87-4c02-952c-d1dc1c542037)  

root@student-node ~ ➜  k logs ckad-flash89-aom --all-containers 
nginx: [alert] could not open error log file: open() "/var/log/nginx/error.log" failed (2: No such file or directory)
2025/09/12 00:59:52 [emerg] 1#1: open() "/var/log/nginx/error.log" failed (2: No such file or directory)

root@student-node ~ ➜  vi ckad-flash89.yaml         # mountPath: /var/log/ to /var/log/nginx

root@student-node ~ ➜  k replace -f ckad-flash89.yaml --force
pod "ckad-flash89-aom" deleted
pod/ckad-flash89-aom replaced

root@student-node ~ ➜  k get po
NAME               READY   STATUS    RESTARTS   AGE
ckad-flash89-aom   2/2     Running   0          11s 
```

Nice catch — let’s debug this one together 👇

### What’s happening

* You created a Pod with **2 containers**:

  * `nginx` (mounts `/var/log`)
  * `busybox` (mounts `/usr/src`)
* Both share the same `emptyDir` volume `flash-logs`.

### Why it’s failing

* The `nginx` container expects to write logs into `/var/log/nginx/error.log`.
* But since `/var/log` is mounted with an **emptyDir volume**, the **original `/var/log` contents from the nginx image are hidden/overwritten**.
* That means the `/var/log/nginx/` directory doesn’t exist anymore → nginx fails to open its log file → container crashes.

👉 That’s why you see:

```
nginx: [alert] could not open error log file: open() "/var/log/nginx/error.log" failed (2: No such file or directory)
```

### How to fix it

Instead of mounting over **`/var/log`** (which wipes nginx’s expected directories), mount over a **subdirectory**, e.g. `/var/log/nginx`.

#### Fixed Pod spec:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ckad-flash89-aom
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: flash-logs
      mountPath: /var/log/nginx   # mount at subdir, not /var/log
  - name: busybox
    image: busybox
    command: ["/bin/sh", "-c", "sleep 10000"]
    volumeMounts:
    - name: flash-logs
      mountPath: /usr/src
  volumes:
  - name: flash-logs
    emptyDir: {}
```

### Why this works

* The nginx container keeps its `/var/log` folder structure intact.
* Your shared `emptyDir` volume now just replaces `/var/log/nginx`.
* Both containers can still write/read logs into the shared volume.

---

## Q5

Troubleshoot and resolve the issue with the deployment named `nginx-frontend` in the `cka4974` namespace, which is currently failing to run. Note that the application is intended to serve traffic on port `81`.


```bash
cluster4-controlplane ~ ➜  k get deploy -n cka4974 nginx-frontend 
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
nginx-frontend   0/1     1            0           50s

cluster4-controlplane ~ ➜  k describe svc -n cka4974 
Name:                     nginx-frontend
Namespace:                cka4974
Labels:                   <none>
Annotations:              <none>
Selector:                 app=nginx-broken
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.38.155
IPs:                      172.20.38.155
Port:                     <unset>  81/TCP
TargetPort:               81/TCP
NodePort:                 <unset>  30081/TCP
Endpoints:                
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster4-controlplane ~ ➜  k describe po -n cka4974 nginx-frontend-64f67d769f-rw5jr 
Name:             nginx-frontend-64f67d769f-rw5jr
    Mounts:
      /etc/nginx/conf.d/default.conf from nginx-conf-vol (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-xccn4 (ro)
Events:
  
  Warning  Failed     42s (x6 over 3m42s)   kubelet            Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error mounting "/var/lib/kubelet/pods/0765e28b-3faf-4e1a-97e2-dfa193977b96/volumes/kubernetes.io~configmap/nginx-conf-vol" to rootfs at "/etc/nginx/conf.d/default.conf": mount /var/lib/kubelet/pods/0765e28b-3faf-4e1a-97e2-dfa193977b96/volumes/kubernetes.io~configmap/nginx-conf-vol:/etc/nginx/conf.d/default.conf (via /proc/self/fd/6), flags: 0x5001: not a directory: unknown
  
cluster4-controlplane ~ ➜  k get cm -n cka4974 
NAME                 DATA   AGE
kube-root-ca.crt     1      7m11s
nginx-default-conf   1      7m11s

cluster4-controlplane ~ ➜  k describe cm -n cka4974 nginx-default-conf 
Name:         nginx-default-conf
Namespace:    cka4974
Labels:       <none>
Annotations:  <none>

Data
====
default.conf:
----
server {
listen       81;
listen  [::]:81;
server_name  localhost;

#access_log  /var/log/nginx/host.access.log  main;

location / {
    root   /usr/share/nginx/html;
    index  index.html index.htm;
}

#error_page  404              /404.html;

# redirect server error pages to the static page /50x.html
#
error_page   500 502 503 504  /50x.html;
location = /50x.html {
    root   /usr/share/nginx/html;
}

# proxy the PHP scripts to Apache listening on 127.0.0.1:80
#
#location ~ \.php$ {
#    proxy_pass   http://127.0.0.1;
#}

# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
#
#location ~ \.php$ {
#    root           html;
#    fastcgi_pass   127.0.0.1:9000;
#    fastcgi_index  index.php;
#    fastcgi_param  SCRIPT_FILENAME  /scripts;
#    include        fastcgi_params;
#}

# deny access to .htaccess files, if Apache's document root
# concurs with nginx's one
#
#location ~ /\.ht {
#    deny  all;
#}
}



BinaryData
====

Events:  <none>

cluster4-controlplane ~ ➜  k get po -o yaml -n cka4974 nginx-frontend-64f67d769f-rw5jr 
apiVersion: v1

    volumeMounts:
    - mountPath: /etc/nginx/conf.d/default.conf
      name: nginx-conf-vol

cluster4-controlplane ~ ➜  k edit deploy -n cka4974 nginx-frontend 
deployment.apps/nginx-frontend edited

cluster4-controlplane ~ ➜  k rollout restart deployment -n cka4974 nginx-frontend 
deployment.apps/nginx-frontend restarted

cluster4-controlplane ~ ➜  k get deploy -n cka4974 
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
nginx-frontend   1/1     1            1           10m

cluster4-controlplane ~ ➜  k describe svc -n cka4974
Name:                     nginx-frontend
Namespace:                cka4974
Labels:                   <none>
Annotations:              <none>
Selector:                 app=nginx-broken
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.38.155
IPs:                      172.20.38.155
Port:                     <unset>  81/TCP
TargetPort:               81/TCP
NodePort:                 <unset>  30081/TCP
Endpoints:                172.17.1.13:81
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster4-controlplane ~ ➜  k describe po -n cka4974 nginx-frontend-6d7b9b8987-rnxqb 
Name:             nginx-frontend-6d7b9b8987-rnxqb
    Mounts:
      /etc/nginx/conf.d/default.conf from nginx-conf-vol (rw,path="default.conf")
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-6hnqj (ro)  
```

This error is a **mounting issue** between your Pod and the ConfigMap. Let’s dissect it step by step:

### 🔎 Error Explanation

```
error mounting "/var/lib/kubelet/pods/.../volumes/kubernetes.io~configmap/nginx-conf-vol" 
to rootfs at "/etc/nginx/conf.d/default.conf": 
not a directory: unknown
```

👉 This means Kubernetes is trying to mount a **ConfigMap volume** into **`/etc/nginx/conf.d/default.conf`**, but:

* The **source** (`nginx-conf-vol`) is a directory (ConfigMaps are mounted as dirs by default).
* The **target** (`/etc/nginx/conf.d/default.conf`) is expected to be a file, not a directory.

So kubelet complains: *"not a directory"*.

### 🛠 Common Causes

1. **You mounted the whole ConfigMap volume directly into a file path.**

   * Example:

     ```yaml
     volumeMounts:
       - name: nginx-conf-vol
         mountPath: /etc/nginx/conf.d/default.conf
     ```

     This is invalid unless you use `subPath`.

2. **Wrong use of ConfigMap keys.**

   * By default, a ConfigMap mounts as a folder where each key becomes a file.

### ✅ How to Fix

#### Option 1: Use `subPath` (when mounting one specific key to a file path)

If your ConfigMap has a key like `default.conf`, mount it like this:

```yaml
volumeMounts:
  - name: nginx-conf-vol
    mountPath: /etc/nginx/conf.d/default.conf  # Target file path inside container
    subPath: default.conf                      # Key from ConfigMap
```

Your ConfigMap should look like:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: cka24456
data:
  default.conf: |
    server {
      listen 80;
      server_name localhost;
      ...
    }
```

#### Option 2: Mount the whole directory (if multiple configs)

```yaml
volumeMounts:
  - name: nginx-conf-vol
    mountPath: /etc/nginx/conf.d
```

This way, all ConfigMap keys become files under `/etc/nginx/conf.d/`.

### ⚡ Summary

* **Problem**: You’re mounting a ConfigMap (directory) into a file path.
* **Fix**:

  * Use `subPath` if mounting a **single file**.
  * Or mount the ConfigMap into a **directory**, not into a file path.

---
