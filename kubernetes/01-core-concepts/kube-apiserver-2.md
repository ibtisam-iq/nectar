```yaml
# Manifest 1
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.102.134:6443
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.102.134
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-issuer=https://kubernetes.default.svc.cluster.local
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=172.20.0.0/16
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
    image: registry.k8s.io/kube-apiserver:v1.33.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 192.168.102.134
        path: /livez
        port: 6443
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-apiserver
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 192.168.102.134
        path: /readyz
        port: 6443
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 250m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 192.168.102.134
        path: /livez
        port: 6443
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /etc/ca-certificates
      name: etc-ca-certificates
      readOnly: true
    - mountPath: /etc/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /usr/local/share/ca-certificates
      name: usr-local-share-ca-certificates
      readOnly: true
    - mountPath: /usr/share/ca-certificates
      name: usr-share-ca-certificates
      readOnly: true
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/ca-certificates
      type: DirectoryOrCreate
    name: etc-ca-certificates
  - hostPath:
      path: /etc/kubernetes/pki
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /usr/local/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-local-share-ca-certificates
  - hostPath:
      path: /usr/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-share-ca-certificates
status: {}
```

Great catch ❤️ — this is one of those things that often confuses people in CKA prep, because you expect to see `containerPort:` in the pod spec, but here you don’t. Let’s break it down:

### 🔑 Why no `containerPort` in kube-apiserver manifest?

* `containerPort` in a Pod manifest is **only metadata** for Kubernetes (used for Service definition, network policy, etc).
* It **does not actually open a port** inside the container. Ports are opened by the process running inside the container (in this case, the `kube-apiserver` binary).
* Since this is a **static pod** (created directly by `kubelet` from `/etc/kubernetes/manifests/kube-apiserver.yaml`), there is no Service automatically referencing it. So Kubernetes doesn’t need to know `containerPort`.
* The **kube-apiserver** itself listens on `--secure-port=6443` (defined in the command args).
* Additionally, `hostNetwork: true` is set → the pod shares the host’s network namespace.
  That means the API server is directly reachable on the host IP (`192.168.102.134:6443`) without needing port mapping.

### 📝 Rule of Thumb for CKA:

👉 **If `hostNetwork: true`, you don’t need `containerPort`. The process inside the pod listens directly on the host network.**


### 🧠 What to remember for the exam:

* `containerPort:` = **declarative metadata**, not required if you’re not exposing ports via Service/Pod definitions.
* In control-plane static pods (like `kube-apiserver`, `kube-scheduler`, `kube-controller-manager`, `etcd`) → you won’t see `containerPort`. Instead, ports are controlled by command-line flags (`--secure-port`, `--etcd-servers`, etc).
* `hostNetwork: true` → Pod skips port mapping and uses host’s network stack.

✅ **Exam tip:**
If you’re asked *why kube-apiserver listens on 6443 even though no containerPort is defined*, the answer is:
*“Because it uses `hostNetwork: true`, and the `kube-apiserver` binary itself opens port 6443 as defined by `--secure-port=6443`. `containerPort` is optional metadata, not an actual port binding.”*


```bash
# Mnifest 2
controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-apiserver.yaml 
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.102.164:6443
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.102.164
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-issuer=https://kubernetes.default.svc.cluster.local
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=172.20.0.0/16
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
    image: registry.k8s.io/kube-apiserver:v1.34.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 192.168.102.164
        path: /livez
        port: probe-port
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: kube-apiserver
    ports:
    - containerPort: 6443
      name: probe-port
      protocol: TCP
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 192.168.102.164
        path: /readyz
        port: probe-port
        scheme: HTTPS
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 250m
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 192.168.102.164
        path: /livez
        port: probe-port
        scheme: HTTPS
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /etc/ca-certificates
      name: etc-ca-certificates
      readOnly: true
    - mountPath: /etc/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /usr/local/share/ca-certificates
      name: usr-local-share-ca-certificates
      readOnly: true
    - mountPath: /usr/share/ca-certificates
      name: usr-share-ca-certificates
      readOnly: true
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/ca-certificates
      type: DirectoryOrCreate
    name: etc-ca-certificates
  - hostPath:
      path: /etc/kubernetes/pki
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /usr/local/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-local-share-ca-certificates
  - hostPath:
      path: /usr/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-share-ca-certificates
status: {}
```

Perfect observation again 👌 — this second manifest is a slightly different variant of kube-apiserver, and yes, here you actually see a `ports:` section with `containerPort: 6443`.

Now let’s clear the confusion:

### 🔎 Why is `ports.containerPort` present here, but absent in your earlier manifest?

* **First manifest (no `containerPort`)**:
  The kube-apiserver pod is running with `--secure-port=6443` and `hostNetwork: true`. Since probes were defined with `port: 6443` directly, Kubernetes didn’t *need* a named `containerPort`.

* **Second manifest (with `containerPort`)**:
  Here, the probes (`livenessProbe`, `readinessProbe`, `startupProbe`) don’t reference the port number `6443` directly.
  Instead, they reference a **named port**:

  ```yaml
  port: probe-port
  ```

  And in order for `probe-port` to mean something, you need:

  ```yaml
  ports:
  - containerPort: 6443
    name: probe-port
  ```

  Otherwise Kubernetes wouldn’t know which port the name `probe-port` refers to.

### 🔑 So, the difference is:

* **Without `containerPort`:** Probes (or Services) use the numeric port (`6443`).
* **With `containerPort`:** Probes (or Services) use a *named port* (`probe-port`), which must be mapped to a real number via `containerPort`.

### 🧠 Exam takeaway:

* `containerPort` is **not required** for a container to listen on a port. The process itself opens the port.
* You **must define `containerPort` only if you want to use named ports** in probes or Services.
* If you’re using just numbers (e.g., `port: 6443`), you can omit it.
* With `hostNetwork: true`, port binding still happens on the host’s IP, but `containerPort` metadata can still be used for probes and Service discovery.

✅ **One-liner rule for exam:**
👉 *Use `containerPort` only when you want to reference the port by name (e.g., in probes or Services). If you reference the port by number directly, `containerPort` is optional.*
