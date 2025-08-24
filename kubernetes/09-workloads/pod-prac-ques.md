# 🧠 20 Pod Exam Practice Questions (CKA Style)

This document contains a set of **20 realistic CKA-style Pod practice questions along with YAML manifests** to truly sharpen your speed and accuracy:  

---

### 1. Create a basic Pod named `web-pod` using the image `nginx:1.21`.

---

### 2. Create a Pod `multi-container-pod` with:
- two containers
- first container: `nginx`
- second container: `busybox` running `sleep 3600`

---

### 3. Create a Pod `custom-port-pod` that exposes container port `8080`.

---

### 4. Create a Pod `env-var-pod` with:
- image: `nginx`
- environment variable: `ENVIRONMENT=production`

---

### 5. Create a Pod `config-envfrom-pod` which imports environment variables from a ConfigMap named `app-config`.

---

### 6. Create a Pod `mount-volume-pod` that:
- uses an `emptyDir` volume
- mounts it inside the container at `/data`

---

### 7. Create a Pod `node-selector-pod` that schedules on nodes having label `env=dev`.

---

### 8. Create a Pod `toleration-pod` that can tolerate the following taint:
```
key=maintenance, value=true, effect=NoSchedule
```

---

### 9. Create a Pod `readiness-probe-pod`:
- http readiness probe on path `/ready` and port `8080`
- initial delay 5 seconds, period 10 seconds

---

### 10. Create a Pod `liveness-probe-pod`:
- tcpSocket liveness probe on port `3306`
- initial delay 10 seconds

---

### 11. Create a Pod `restart-onfailure-pod`:
- restartPolicy should be `OnFailure`

---

### 12. Create a Pod `resource-limits-pod`:
- set container requests:
  - cpu: `100m`
  - memory: `200Mi`
- set container limits:
  - cpu: `500m`
  - memory: `512Mi`

---

### 13. Create a Pod `command-args-pod` that:
- image: `busybox`
- runs command: `["/bin/sh", "-c", "echo Hello Kubernetes; sleep 3600"]`

---

### 14. Create a Pod `securitycontext-pod`:
- container runs as user `1000`
- volume files should belong to group `2000`

---

### 15. Create a Pod `host-network-pod`:
- container should use **hostNetwork: true**

---

### 16. Create a Pod `pod-affinity-pod` that:
- schedules **preferably** near Pods with label `app=frontend`

---

### 17. Create a Pod `pod-anti-affinity-pod` that:
- **avoids** scheduling on nodes where `app=backend` Pods are already running

---

### 18. Create a Pod `secret-envfrom-pod`:
- load all environment variables from a Secret named `db-credentials`

---

### 19. Create a Pod `custom-dns-pod`:
- dnsPolicy should be set to `ClusterFirstWithHostNet`

---

### 20. Create a Pod `hostpath-volume-pod`:
- mount host path `/var/log` into container at `/log`

---

# ✍️ How to Practice:

- Open a plain text editor (like VS Code)
- Read one question → Quickly write the YAML from scratch
- Check against your notes / kubernetes.io if stuck
- Target time = **less than 2 minutes per Pod**  

> Speed + YAML muscle memory = Exam domination 🔥

---

# 📜 CKA Pod Practice - Answer Key (YAMLs)

---

### 1. `web-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.21
```

---

### 2. `multi-container-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
```

---

### 3. `custom-port-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-port-pod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 8080
```

---

### 4. `env-var-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-var-pod
spec:
  containers:
  - name: nginx
    image: nginx
    env:
    - name: ENVIRONMENT
      value: production
```

---

### 5. `config-envfrom-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-envfrom-pod
spec:
  containers:
  - name: nginx
    image: nginx
    envFrom:
    - configMapRef:
        name: app-config
```

---

### 6. `mount-volume-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mount-volume-pod
spec:
  volumes:
  - name: data-volume
    emptyDir: {}
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data-volume
      mountPath: /data
```

---

### 7. `node-selector-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: node-selector-pod
spec:
  nodeSelector:
    env: dev
  containers:
  - name: nginx
    image: nginx
```

---

### 8. `toleration-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: toleration-pod
spec:
  tolerations:
  - key: maintenance
    value: "true"
    effect: NoSchedule
  containers:
  - name: nginx
    image: nginx
```

---

### 9. `readiness-probe-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-probe-pod
spec:
  containers:
  - name: app
    image: nginx
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
```

---

### 10. `liveness-probe-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-probe-pod
spec:
  containers:
  - name: db
    image: mysql
    livenessProbe:
      tcpSocket:
        port: 3306
      initialDelaySeconds: 10
```

---

### 11. `restart-onfailure-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restart-onfailure-pod
spec:
  restartPolicy: OnFailure
  containers:
  - name: busybox
    image: busybox
    command: ["false"]
```

---

### 12. `resource-limits-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limits-pod
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "100m"
        memory: "200Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
```

---

### 13. `command-args-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: command-args-pod
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["/bin/sh", "-c", "echo Hello Kubernetes; sleep 3600"]
```

---

### 14. `securitycontext-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: securitycontext-pod
spec:
  securityContext:
    fsGroup: 2000
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsUser: 1000
```

---

### 15. `host-network-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: host-network-pod
spec:
  hostNetwork: true
  containers:
  - name: nginx
    image: nginx
```

---

### 16. `pod-affinity-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-affinity-pod
spec:
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - frontend
          topologyKey: kubernetes.io/hostname
  containers:
  - name: nginx
    image: nginx
```

---

### 17. `pod-anti-affinity-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-anti-affinity-pod
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - backend
        topologyKey: kubernetes.io/hostname
  containers:
  - name: nginx
    image: nginx
```

---

### 18. `secret-envfrom-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-envfrom-pod
spec:
  containers:
  - name: nginx
    image: nginx
    envFrom:
    - secretRef:
        name: db-credentials
```

---

### 19. `custom-dns-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns-pod
spec:
  dnsPolicy: ClusterFirstWithHostNet
  hostNetwork: true
  containers:
  - name: nginx
    image: nginx
```

---

### 20. `hostpath-volume-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-volume-pod
spec:
  volumes:
  - name: log-volume
    hostPath:
      path: /var/log
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: log-volume
      mountPath: /log
```

---
Create a pod named redis-pod that uses the image redis:7 and exposes port 6379 . Use the command redis-server /redis-master/redis.conf to store redis configuration data and store this in an emptyDir volume. Mount the redis-config configmap as a volume to the pod for use within the container.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-pod
  labels:
    app: redis
spec:
  containers:
  - name: redis
    image: redis:7
    # Start Redis with a custom config file path
    command: ["redis-server", "/redis-master/redis.conf"]

    ports:
    - containerPort: 6379  # Redis default port

    volumeMounts:
    # Mount the emptyDir volume for Redis data persistence (lifetime = Pod's lifecycle)
    - name: redis-data
      mountPath: /data

    # Mount ConfigMap containing redis.conf into the container
    - name: redis-config
      mountPath: /redis-master
      # Each key in ConfigMap becomes a file, here /redis-master/redis.conf
      # Ensure your ConfigMap has a key named 'redis.conf'

  volumes:
  # EmptyDir for ephemeral Redis storage (wiped when Pod is deleted)
  - name: redis-data
    emptyDir: {}

  # ConfigMap for Redis configuration
  - name: redis-config
    configMap:
      name: redis-config   # This must exist beforehand
      # Optional: specify key-to-path mapping
      items:
      - key: redis.conf    # key inside ConfigMap
        path: redis.conf   # file created inside container
```
```bash
controlplane:~$ k logs redis-pod 
1:C 24 Aug 2025 15:38:20.095 # Fatal error, can't open config file '/redis-master/redis.conf': No such file or directory
controlplane:~$ k describe cm redis-config 
Name:         redis-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
maxmemory:
----
2mb

maxmemory-policy:
----
allkeys-lru


BinaryData
====

Events:  <none>
controlplane:~$ k delete cm redis-config 
configmap "redis-config" deleted
controlplane:~$ vi 1.yaml
controlplane:~$ cat 1.yaml 
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
data:
  redis.conf: |-
    # Redis configuration file
    bind 0.0.0.0
    port 6379
    dir /data
    maxmemory 2mb
    maxmemory-policy allkeys-lru
controlplane:~$ k apply -f 1.yaml 
configmap/redis-config created
controlplane:~$ k get po
NAME        READY   STATUS              RESTARTS   AGE
redis-pod   0/1     ContainerCreating   0          96s
controlplane:~$ k replace -f abcd.yaml --force
pod "redis-pod" deleted
pod/redis-pod replaced
controlplane:~$ k get po
NAME        READY   STATUS    RESTARTS   AGE
redis-pod   1/1     Running   0          5s
```

---

# 🛡️ Important Tip for CKA

During exam:
- Always check quickly if apiVersion/kind are right
- Set name correctly (you lose marks if names differ)
- If you forget, search "Pod spec" inside kubernetes.io official docs
