## Q1

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

## Q2
In the `ckad-multi-containers` namespaces, create a `ckad-neighbor-pod` pod that matches the following requirements.

Pod has an **emptyDir** volume named `my-vol`.

The first container named `main-container`, runs `nginx:1.16` image. This container mounts the `my-vol` volume at `/usr/share/nginx/html` path.

The second container is a co-located container named `neighbor-container`, and runs the `busybox:1.28` image. This container mounts the volume `my-vol` at `/var/log` path.

**Every 5 seconds**, this container should write the `current date` along with greeting message `Hi I am from neighbor container` to `index.html` in the `my-vol` volume.

```bash
root@student-node ~ ✖ k replace -f 1.yaml --force
pod "ckad-neighbor-pod" deleted
pod/ckad-neighbor-pod replaced

root@student-node ~ ➜  cat 1.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: ckad-neighbor-pod
  namespace: ckad-multi-containers
spec:
  volumes:
    - name: my-vol
      emptyDir: {}
  containers:
    - name: main-container
      image: nginx:1.16
      volumeMounts:
        - name: my-vol
          mountPath: /usr/share/nginx/html
    - name: neighbor-container
      image: busybox:1.28
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
            echo "$(date) - Hi I am from neighbor container" > /var/log/index.html;
            sleep 5;
          done
      volumeMounts:
        - name: my-vol
          mountPath: /var/log
root@student-node ~ ➜  k get po -n ckad-multi-containers 
NAME                READY   STATUS    RESTARTS   AGE
ckad-neighbor-pod   2/2     Running   0          15s
```

---

## Q3

An existing nginx pod, `my-pod-cka` and Persistent Volume Claim (PVC) named `my-pvc-cka` are available. Your task is to implement the following modifications:

- Update the pod to include a `sidecar` container that uses the `busybox` image. Ensure that this sidecar container remains operational by including an appropriate command `"tail -f /dev/null"` .

Share the `shared-storage` volume between the main application and the sidecar container, mounting it at the path `/var/www/shared` . Additionally, ensure that the sidecar container has `read-only access` to this shared volume.

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

In Kubernetes, each `volume` entry under `spec.volumes` must have a **unique name**. If you define two volumes with the same `name`, you’ll get:

```
spec.volumes[1].name: Duplicate value: "shared-storage"
```

And if you try to add two different sources (like `persistentVolumeClaim` + `emptyDir`) under the same volume, you’ll get:

```
spec.volumes[0].persistentVolumeClaim: Forbidden: may not specify more than 1 volume type
```

### How to handle your case (adding a sidecar)

If your **main container already mounts a PVC**, you don’t need to redefine the `volumes` block.

Instead, in the sidecar container, simply **reuse the existing volume** by mounting it with the same `name`.

✅ Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod-cka
spec:
  volumes:
  - name: shared-storage              # Already defined PVC
    persistentVolumeClaim:
      claimName: my-pvc

  containers:
  - name: main-app
    image: nginx
    volumeMounts:
    - name: shared-storage
      mountPath: /usr/share/nginx/html

  - name: sidecar                     # Sidecar reuses the same volume
    image: busybox
    command: [ "sh", "-c", "echo 'Hello from sidecar' >> /data/sidecar.log; sleep 3600" ]
    volumeMounts:
    - name: shared-storage
      mountPath: /data
```

👉 Key takeaway:

* **Never duplicate the `volumes` section** for a sidecar.
* Just mount the **existing volume** into the sidecar container.

---
