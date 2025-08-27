
- `/var/log/pods`
- `/var/log/containers`
- `crictl ps` + `crictl logs`
- `docker ps` + `docker logs` (in case when Docker is used)
- kubelet logs: `/var/log/syslog` or `journalctl`
```bash
journalctl | grep apiserver
cat /var/log/syslog | grep apiserver
```
---

## vim setup
```bash
set expandtab
set tabstop=2
set shiftwidth=2
```
---


## Ingress

The Nginx Ingress Controller has been installed.

Create a new Ingress resource called `world` for domain name `world.universe.mine` . The domain points to the K8s Node IP via `/etc/hosts` .

The Ingress resource should have two routes pointing to the existing Services:

`http://world.universe.mine:30080/europe/`

and

`http://world.universe.mine:30080/asia/`

```bash
controlplane:~$ k get deploy -n world 
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
asia     2/2     2            2           105s
europe   2/2     2            2           105s
controlplane:~$ k expose deployment asia -n world --port 80
service/asia exposed
controlplane:~$ k expose deployment europe -n world --port 80
service/europe exposed
controlplane:~$ k get svc -n world 
NAME     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
asia     ClusterIP   10.104.4.232     <none>        80/TCP    27s
europe   ClusterIP   10.103.132.146   <none>        80/TCP    11s
controlplane:~$ k get ingressclasses.networking.k8s.io 
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       8m44s
controlplane:~$ vi ingress.yaml
controlplane:~$ k apply -f ingress.yaml 
ingress.networking.k8s.io/world created
controlplane:~$ k get ingress
No resources found in default namespace.
controlplane:~$ k get ingress -n world 
NAME    CLASS   HOSTS                 ADDRESS      PORTS   AGE
world   nginx   world.universe.mine   172.30.1.2   80      15s
controlplane:~$ k get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.109.137.75   <none>        80:30080/TCP,443:30443/TCP   17m
ingress-nginx-controller-admission   ClusterIP   10.104.104.54   <none>        443/TCP                      17m
controlplane:~$ cat /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
127.0.0.1 ubuntu
127.0.0.1 host01
127.0.0.1 controlplane
172.30.1.2 world.universe.mine
controlplane:~$ http://world.universe.mine:30080/europe/
bash: http://world.universe.mine:30080/europe/: No such file or directory
controlplane:~$ curl http://world.universe.mine:30080/europe/
hello, you reached EUROPE
controlplane:~$ curl http://world.universe.mine:30080/asia/
hello, you reached ASIA
```
---

## NetworkPolicy

There are existing Pods in Namespace `space1` and `space2` .

```bash
controlplane:~$ k get po -n space1 
NAME     READY   STATUS    RESTARTS   AGE     
app1-0   1/1     Running   0          4m44s   
controlplane:~$ k get po -n space2  
NAME              READY   STATUS    RESTARTS   AGE    
microservice1-0   1/1     Running   0          5m3s   
microservice2-0   1/1     Running   0          5m3s   

controlplane:~$ k get svc -n space1
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
app1   ClusterIP   10.111.213.35   <none>        80/TCP    33m
controlplane:~$ k get svc -n space2
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
microservice1   ClusterIP   10.109.230.189   <none>        80/TCP    33m
microservice2   ClusterIP   10.110.221.96    <none>        80/TCP    33m

controlplane:~$ k get ns --show-labels
NAME                 STATUS   AGE    LABELS
space1               Active   6m5s   kubernetes.io/metadata.name=space1
space2               Active   6m5s   kubernetes.io/metadata.name=space2
```

We need a new NetworkPolicy named `np` that restricts all Pods in Namespace `space1` to only have outgoing traffic to Pods in Namespace `space2` . Incoming traffic not affected.

We also need a new NetworkPolicy named `np` that restricts all Pods in Namespace `space2` to only have incoming traffic from Pods in Namespace `space1` . Outgoing traffic not affected.

The NetworkPolicies should still allow outgoing DNS traffic on port `53` TCP and UDP.

```bash
controlplane:~$ cat netpol.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np
  namespace: space1
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:        
        matchLabels:
         kubernetes.io/metadata.name: space2
  - ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53

---

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np
  namespace: space2
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: 
       matchLabels:
         kubernetes.io/metadata.name: space1

# these should work
k -n space1 exec app1-0 -- curl -m 1 microservice1.space2.svc.cluster.local
k -n space1 exec app1-0 -- curl -m 1 microservice2.space2.svc.cluster.local
k -n space1 exec app1-0 -- nslookup tester.default.svc.cluster.local
k -n kube-system exec -it validate-checker-pod -- curl -m 1 app1.space1.svc.cluster.local

# these should not work
k -n space1 exec app1-0 -- curl -m 1 tester.default.svc.cluster.local
k -n kube-system exec -it validate-checker-pod -- curl -m 1 microservice1.space2.svc.cluster.local
k -n kube-system exec -it validate-checker-pod -- curl -m 1 microservice2.space2.svc.cluster.local
k -n default run nginx --image=nginx:1.21.5-alpine --restart=Never -i --rm  -- curl -m 1 microservice1.space2.svc.cluster.local
```

All Pods in Namespace `default` with label `level=100x` should be able to communicate with Pods with label `level=100x` in Namespaces `level-1000` , `level-1001` and `level-1002` . Fix the existing NetworkPolicy np-100x to ensure this.

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-100x
  namespace: default
spec:
  podSelector:
    matchLabels:
      level: 100x
  policyTypes:
  - Egress
  egress:
  - to:
     - namespaceSelector:
        matchLabels:
         kubernetes.io/metadata.name: level-1000
       podSelector:
         matchLabels:
           level: 100x
  - to:
     - namespaceSelector:
        matchLabels:
         kubernetes.io/metadata.name: level-1000 # CHANGE to level-1001
       podSelector:
         matchLabels:
           level: 100x
  - to:
     - namespaceSelector:
        matchLabels:
         kubernetes.io/metadata.name: level-1002
       podSelector:
         matchLabels:
           level: 100x
  - ports:
    - port: 53
      protocol: TCP
    - port: 53
      protocol: UDP

controlplane:~$ k get po
NAME       READY   STATUS    RESTARTS   AGE
tester-0   1/1     Running   0          12m
kubectl exec tester-0 -- curl tester.level-1000.svc.cluster.local
kubectl exec tester-0 -- curl tester.level-1001.svc.cluster.local
kubectl exec tester-0 -- curl tester.level-1002.svc.cluster.local
```

my-app-deployment and cache-deployment deployed, and my-app-deployment deployment exposed through a service named my-app-service . Create a NetworkPolicy named my-app-network-policy to restrict incoming and outgoing traffic to my-app-deployment pods with the following specifications:

Allow incoming traffic only from pods.
Allow incoming traffic from a specific pod with the label app=trusted
Allow outgoing traffic to pods.
Deny all other incoming and outgoing traffic.

```bash
controlplane:~$ vi abc.yaml
controlplane:~$ k apply -f abc.yaml 
networkpolicy.networking.k8s.io/my-app-network-policy created
controlplane:~$ cat abc.yaml 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-network-policy
spec:
  podSelector:
    matchLabels:
      app: my-app   # Select my-app-deployment pods
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: trusted   # Allow incoming from trusted pods only
  egress:
  - to:
    - podSelector: {}     # Allow outgoing to any pods
```
---

## RBAC
There are existing Namespaces `ns1` and `ns2`. Create ServiceAccount `pipeline` in both Namespaces.

These SAs should be allowed to view almost everything in the whole cluster. You can use the default ClusterRole `view` for this.

These SAs should be allowed to `create` and `delete` Deployments in their Namespace.

Verify everything using `kubectl auth can-i` .
```bash
controlplane:~$ k create sa pipeline -n ns1 
serviceaccount/pipeline created
controlplane:~$ k create sa pipeline -n ns2 
serviceaccount/pipeline created
controlplane:~$ k get clusterrole
NAME                                                                   CREATED AT
view                                                                   2025-08-19T09:03:53Z
controlplane:~$ k create clusterrolebinding abc --help

Usage:
  kubectl create clusterrolebinding NAME --clusterrole=NAME [--user=username] [--group=groupname]
[--serviceaccount=namespace:serviceaccountname] [--dry-run=server|client|none] [options]

controlplane:~$ k create clusterrolebinding abc --clusterrole view --serviceaccount=ns2:pipeline --serviceaccount=ns1:pipeline
clusterrolebinding.rbac.authorization.k8s.io/abc created
controlplane:~$ k create role abc -n ns1 --verb=create,delete --resource=deployments
role.rbac.authorization.k8s.io/abc created
controlplane:~$ k create role abc -n ns2 --verb=create,delete --resource=deployments
role.rbac.authorization.k8s.io/abc created
controlplane:~$ k create rolebinding abc -n ns1 --role abc --serviceaccount=ns1:pipeline   
rolebinding.rbac.authorization.k8s.io/abc created
controlplane:~$ k create rolebinding abc -n ns2 --role abc --serviceaccount=ns2:pipeline
rolebinding.rbac.authorization.k8s.io/abc created

# namespace ns1 deployment manager
k auth can-i delete deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i create deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n ns1 # NO
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n default # NO

# namespace ns2 deployment manager
k auth can-i delete deployments --as system:serviceaccount:ns2:pipeline -n ns2 # YES
k auth can-i create deployments --as system:serviceaccount:ns2:pipeline -n ns2 # YES
k auth can-i update deployments --as system:serviceaccount:ns2:pipeline -n ns2 # NO
k auth can-i update deployments --as system:serviceaccount:ns2:pipeline -n default # NO

# cluster wide view role
k auth can-i list deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i list deployments --as system:serviceaccount:ns1:pipeline -A # YES
k auth can-i list pods --as system:serviceaccount:ns1:pipeline -A # YES
k auth can-i list pods --as system:serviceaccount:ns2:pipeline -A # YES
k auth can-i list secrets --as system:serviceaccount:ns2:pipeline -A # NO (default view-role doesn't allow)
```
There is existing Namespace `applications`.
User `smoke` should be allowed to `create` and `delete` `Pods, Deployments and StatefulSets` in Namespace `applications`.
User smoke should have `view` permissions (like the permissions of the default `ClusterRole` named `view` ) in all Namespaces but not in `kube-system`.

```bash
controlplane:~$ k create role abc --verb=create,delete --resource=pods,deployments,statefulsets -n applications 
role.rbac.authorization.k8s.io/abc created
controlplane:~$ k create rolebinding -n applications abc --user=smoke --role=abc    
rolebinding.rbac.authorization.k8s.io/abc created

controlplane:~$ k get ns
NAME                 STATUS   AGE
applications         Active   20m
default              Active   4d11h
kube-node-lease      Active   4d11h
kube-public          Active   4d11h
kube-system          Active   4d11h
local-path-storage   Active   4d11h

controlplane:~$ k create rolebinding abc -n applications --clusterrole=view --user=smoke
error: failed to create rolebinding: rolebindings.rbac.authorization.k8s.io "abc" already exists
controlplane:~$ k create rolebinding abcd -n applications --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n default --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n kube-node-lease --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n kube-public --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n local-path-storage --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created

controlplane:~$ k auth can-i create deployments --as smoke -n applications
yes
controlplane:~$ k auth can-i get secrets --as smoke -n applications
no

# applications
k auth can-i create deployments --as smoke -n applications # YES
k auth can-i delete deployments --as smoke -n applications # YES
k auth can-i delete pods --as smoke -n applications # YES
k auth can-i delete sts --as smoke -n applications # YES
k auth can-i delete secrets --as smoke -n applications # NO
k auth can-i list deployments --as smoke -n applications # YES
k auth can-i list secrets --as smoke -n applications # NO
k auth can-i get secrets --as smoke -n applications # NO

# view in all namespaces but not kube-system
k auth can-i list pods --as smoke -n default # YES
k auth can-i list pods --as smoke -n applications # YES
k auth can-i list pods --as smoke -n kube-public # YES
k auth can-i list pods --as smoke -n kube-node-lease # YES
k auth can-i list pods --as smoke -n kube-system # NO
```

Create a new role named “sa-creator” that will allow creating service accounts in the default namespace.
```bash
controlplane:~$ k create sa sa-creator
serviceaccount/sa-creator created

controlplane:~$ k api-resources | grep -i serviceacc
serviceaccounts                     sa           v1                                true         ServiceAccount

controlplane:~$ k create role sa-creator --verb create --resource serviceaccounts
role.rbac.authorization.k8s.io/sa-creator created

controlplane:~$ k create role sa-creatorr --verb create --resource sa
role.rbac.authorization.k8s.io/sa-creatorr created
```
---

## Affinity

There is a Pod YAML provided at `/root/hobby.yaml`. That Pod should be preferred to be only scheduled on Nodes where Pods with label `level=restricted` are running. For the topologyKey use `kubernetes.io/hostname`. There are no taints on any Nodes which means no tolerations are needed.

```bash

controlplane:~$ k get po --show-labels 
NAME         READY   STATUS    RESTARTS   AGE    LABELS
restricted   1/1     Running   0          115s   level=restricted
controlplane:~$ k get po --show-labels -o wide
NAME         READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES   LABELS
restricted   1/1     Running   0          2m14s   192.168.1.4   node01   <none>           <none>            level=restricted
controlplane:~$ vi hobby.yaml 
controlplane:~$ k apply -f hobby.yaml 
pod/hobby-project created
controlplane:~$ k get po -o wide
NAME            READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
hobby-project   1/1     Running   0          11s   192.168.1.5   node01   <none>           <none>
restricted      1/1     Running   0          13m   192.168.1.4   node01   <none>           <none>

Extend the provided YAML at /root/hobby.yaml :

  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: level
              operator: In
              values:
              - restricted
          topologyKey: kubernetes.io/hostname

Another way to solve the same requirement would be:

...
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              level: restricted
          topologyKey: kubernetes.io/hostname
```


---

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
