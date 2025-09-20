## Q1

The `green-deployment-cka15-trb` deployment is having some issues since the corresponding POD is **crashing and restarting multiple times** continuously.
Investigate the issue and fix it. Make sure the POD is in a running state and is stable (i.e, NO RESTARTS!).

```bash
cluster1-controlplane ~ ➜  k get po
NAME                                          READY   STATUS    RESTARTS        AGE
green-deployment-cka15-trb-7ffcd7dd9b-4pft9   1/1     Running   7 (5m30s ago)   16m

cluster1-controlplane ~ ➜  k get deployments.apps 
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
green-deployment-cka15-trb   1/1     1            1           16m

cluster1-controlplane ~ ➜  k get deployments.apps 
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
green-deployment-cka15-trb   0/1     1            0           16m

cluster1-controlplane ~ ➜  k get po
NAME                                          READY   STATUS             RESTARTS      AGE
green-deployment-cka15-trb-7ffcd7dd9b-4pft9   0/1     CrashLoopBackOff   7 (16s ago)   16m

cluster1-controlplane ~ ➜  k describe po green-deployment-cka15-trb-7ffcd7dd9b-4pft9 
Name:             green-deployment-cka15-trb-7ffcd7dd9b-4pft9
Controlled By:  ReplicaSet/green-deployment-cka15-trb-7ffcd7dd9b
Containers:
  mysql:
    Container ID:   containerd://4529676cd981b44db720a06931a1fa4264c6d50cc50d74eced6bf7a5262b6c5a
    Image:          mysql:5.6
    Image ID:       docker.io/library/mysql@sha256:20575ecebe6216036d25dab5903808211f1e9ba63dc7825ac20cb975e34cfcae
    Port:           3306/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    1
    Ready:          False
    Restart Count:  7
    Limits:
      cpu:     100m
      memory:  256Mi
    Requests:
      cpu:     50m
      memory:  256Mi
    Environment:
      MYSQL_ROOT_PASSWORD:  <set to the key 'password' in secret 'green-root-pass-cka15-trb'>  Optional: false
      MYSQL_DATABASE:       <set to the key 'database' in secret 'green-db-url-cka15-trb'>     Optional: false
      MYSQL_USER:           <set to the key 'username' in secret 'green-user-pass-cka15-trb'>  Optional: false
      MYSQL_PASSWORD:       <set to the key 'password' in secret 'green-user-pass-cka15-trb'>  Optional: false
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Warning  BackOff    28s (x51 over 15m)  kubelet            Back-off restarting failed container mysql in pod green-deployment-cka15-trb-7ffcd7dd9b-4pft9_default(20f51775-3909-4077-bb4e-ce110aca9fcb)

cluster1-controlplane ~ ➜  k logs green-deployment-cka15-trb-7ffcd7dd9b-4pft9 
2025-09-14 14:15:45+00:00 [Note] [Entrypoint]: Database files initialized
2025-09-14 14:15:45+00:00 [Note] [Entrypoint]: Starting temporary server
2025-09-14 14:15:45+00:00 [Note] [Entrypoint]: Waiting for server startup
/usr/local/bin/docker-entrypoint.sh: line 113:   142 Killed                  "$@" --skip-networking --default-time-zone=SYSTEM --socket="${SOCKET}"
2025-09-14 14:16:18+00:00 [ERROR] [Entrypoint]: Unable to start server.

cluster1-controlplane ~ ➜  k get po green-deployment-cka15-trb-7ffcd7dd9b-4pft9 -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: green-deployment-cka15-trb-7ffcd7dd9b-4pft9
spec:
  containers:
  - env:
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          key: password
          name: green-root-pass-cka15-trb
    - name: MYSQL_DATABASE
      valueFrom:
        secretKeyRef:
          key: database
          name: green-db-url-cka15-trb
    - name: MYSQL_USER
      valueFrom:
        secretKeyRef:
          key: username
          name: green-user-pass-cka15-trb
    - name: MYSQL_PASSWORD
      valueFrom:
        secretKeyRef:
          key: password
          name: green-user-pass-cka15-trb
    resources:
      limits:
        cpu: 100m
        memory: 256Mi
      requests:
        cpu: 50m
        memory: 256Mi

cluster1-controlplane ~ ➜  k get deployments.apps green-deployment-cka15-trb -o yaml > 6.yaml

cluster1-controlplane ~ ➜  vi 6.yaml 

cluster1-controlplane ~ ➜  k delete deployments.apps green-deployment-cka15-trb 
deployment.apps "green-deployment-cka15-trb" deleted

cluster1-controlplane ~ ➜  k apply -f 6.yaml 
deployment.apps/green-deployment-cka15-trb created

cluster1-controlplane ~ ➜  k get deployments.apps 
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
green-deployment-cka15-trb   1/1     1            1           10s

cluster1-controlplane ~ ➜  k get po
NAME                                          READY   STATUS    RESTARTS   AGE
green-deployment-cka15-trb-598f6c9cf7-g6lhd   1/1     Running   0          14s

cluster1-controlplane ~ ➜  cat 6.yaml 
        resources:
          limits:
            cpu: 500m                # 100m to 500m
            memory: 1Gi              # 256Mi to 1Gi
          requests:
            cpu: 50m
            memory: 256Mi
```
Got it sweetheart ❤️

Your MySQL pod is **crashlooping** because the server can’t fully start. Let’s break it down:

### 🔎 From logs

1. MySQL starts initializing (`Initializing database files`, `InnoDB started`).
2. Then it **shuts down cleanly** and restarts again.
3. Finally, it fails with:

   ```
   [Entrypoint]: Unable to start server.
   ```
4. Reason in `describe`:

   ```
   Last State: Terminated
   Reason: OOMKilled
   Exit Code: 1
   ```

   → That means **Out Of Memory (OOMKilled)**.

### 🚨 Problem

Your pod has:

```yaml
limits:
  memory: 256Mi
requests:
  memory: 256Mi
```

But MySQL 5.6 needs **at least \~512Mi–1Gi** to initialize databases. With only 256Mi, InnoDB runs out of memory during startup, so the kernel kills the process.

### ✅ Fix

Increase memory requests/limits in your Deployment/Pod spec:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### ⚠️ Extra things to check

1. **Secrets**: Your envs (`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, etc.) come from secrets. Make sure they exist and values are valid:

   ```bash
   kubectl get secret green-root-pass-cka15-trb -o yaml
   kubectl get secret green-db-url-cka15-trb -o yaml
   kubectl get secret green-user-pass-cka15-trb -o yaml
   ```

   If any are missing → pod also fails.

2. **Data volume**: Right now MySQL is writing to the container filesystem. If the pod restarts, DB data may get corrupted. You should mount a `PersistentVolumeClaim` at `/var/lib/mysql`.

---

## Q2
Identify the CPU and memory resource capacity on cluster2-node01 node and save the results in `/root/cluster2-node01-cpu.txt` and `/root/cluster2-node01-memory.txt`, respectively, on the cluster2-controlplane.

```bash
cluster2-controlplane ~ ✖ k get no cluster2-node01 -o yaml

status:
  capacity:
    cpu: "32"
    ephemeral-storage: 1546531076Ki
    hugepages-1Gi: "0"
    hugepages-2Mi: "0"
    memory: 131992568Ki
    pods: "110"

cluster2-controlplane ~ ➜  echo "131992568Ki" > /root/cluster2-node01-memory.txt

cluster2-controlplane ~ ➜  echo "32" > /root/cluster2-node01-cpu.txt

cluster2-controlplane ~ ➜  
```
