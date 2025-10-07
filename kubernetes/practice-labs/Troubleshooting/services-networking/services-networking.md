# 🚀 Kubernetes Services – Troubleshooting Rules

## 🔹 1. No Endpoints Assigned

* Service is created, but:

  * Pods don’t have the **labels** matching the Service’s `selector`.
  * Or Service `selector` itself is wrong.
* Fix: Ensure **`spec.selector` matches Pod labels**.

## 🔹 2. Wrong Port Configuration

* **Endpoint is present**, but Service doesn’t forward traffic because:

  * Wrong **port number** (e.g., using `8080` instead of Pod’s `80`).
  * Wrong **protocol** (e.g., `UDP` instead of `TCP`).
* Fix: Align Service `port/targetPort` with Pod `containerPort`.

## 🔹 3. Wrong NodePort Configuration
- Sometimes, question tells to click a button on terminal, on clicking.. this url shows port, and this pod is misconfigured in service manifest.

---

## Q1 Pod doesn't have label

```bash
controlplane:~$ kubectl port-forward svc/nginx-service 8080:80
^Ccontrolplane:~$ k describe po nginx-pod 
Name:             nginx-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             node01/172.30.2.2
Start Time:       Wed, 27 Aug 2025 22:25:03 +0000
Labels:           <none>

controlplane:~$ k describe svc nginx-service 
Name:                     nginx-service

Selector:                 app=nginx-pod
IP:                       10.99.175.81
IPs:                      10.99.175.81
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                

controlplane:~$ k label po nginx-pod app=nginx-pod
pod/nginx-pod labeled

controlplane:~$ kubectl port-forward svc/nginx-service 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

---

## Q2: Endpoint is not yet assigned, wrong label

```bash
cluster1-controlplane ~ ➜  k describe svc curlme-cka01-svcn 
Name:                     curlme-cka01-svcn
Namespace:                default
Selector:                 run=curlme-ckaO1-svcn                 # 0 not O 
Type:                     ClusterIP
IP:                       172.20.218.134
IPs:                      172.20.218.134
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                
Events:                   <none>


cluster1-controlplane ~ ➜  k get po -o wide curlme-cka01-svcn curlpod-cka01-svcn --show-labels 
NAME                 READY   STATUS    RESTARTS   AGE    IP            NODE              NOMINATED NODE   READINESS GATES   LABELS
curlme-cka01-svcn    1/1     Running   0          4m4s   172.17.1.11   cluster1-node01   <none>           <none>            run=curlme-cka01-svcn
curlpod-cka01-svcn   1/1     Running   0          4m4s   172.17.3.12   cluster1-node02   <none>           <none>            run=curlpod-cka01-svcn
```

---

## Q3: Endpoint is assigned, but wrong port 

```bash
cluster1-controlplane ~ ➜  k get po purple-app-cka27-trb -o yaml | grep -i image:
  - image: nginx
    image: docker.io/library/nginx:latest

cluster1-controlplane ~ ➜  k get po purple-app-cka27-trb -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP            NODE              NOMINATED NODE   READINESS GATES
purple-app-cka27-trb   1/1     Running   0          32m   172.17.1.22   cluster1-node01   <none>           <none>

cluster1-controlplane ~ ➜  k describe svc purple-svc-cka27-trb 
Name:                     purple-svc-cka27-trb
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=purple-app-cka27-trb
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.10.168
IPs:                      172.20.10.168
Port:                     app  8080/TCP                                # set it to 80
TargetPort:               8080/TCP                                     # set it to 80
Endpoints:                172.17.1.22:8080
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster1-controlplane ~ ➜
```
---

## Q4: Wrong Protocol
A pod called `pink-pod-cka16-trb` is created in the `default` namespace in cluster4. This app runs on port `tcp/5000`, and it is to be exposed to end-users using an ingress resource called `pink-ing-cka16-trb` such that it becomes accessible using the command `curl http://kodekloud-pink.app` on the `cluster4-controlplane` host. There is an ingress.yaml file under the root folder in cluster4-controlplane. Create an **ingress resource** by following the command and continue with the task.

However, even after creating the ingress resource, it is not working. Troubleshoot and fix this issue, making any necessary changes to the objects.

```bash
cluster4-controlplane ~ ➜  k get po pink-pod-cka16-trb -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: pink-pod-cka16-trb
spec:
  containers:
    ports:
    - containerPort: 80
      protocol: TCP
cluster4-controlplane ~ ➜  k describe svc pink-svc-cka16-trb 
Name:                     pink-svc-cka16-trb
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=pink-app-cka16-trb
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.39.102
IPs:                      172.20.39.102
Port:                     <unset>  5000/UDP                                # wrong protocol
TargetPort:               80/UDP
Endpoints:                172.17.1.3:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster4-controlplane ~ ➜  k edit svc pink-svc-cka16-trb                    # just change the protocol to TCP
service/pink-svc-cka16-trb edited

cluster4-controlplane ~ ➜  cat ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pink-ing-cka16-trb
spec:
  ingressClassName: nginx
  rules:
    - host: kodekloud-pink.app
      http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: pink-svc-cka16-trb
                port:
                  number: 5000                                                # ingress resource never contains protocol, just port number only

cluster4-controlplane ~ ➜  k apply -f ingress.yaml 
ingress.networking.k8s.io/pink-ing-cka16-trb created

cluster4-controlplane ~ ➜  curl http://kodekloud-pink.app
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
<p><em>Thank you for using nginx.</em></p>
```

### 🔎 What you actually have

Pod (`pink-pod-cka16-trb`):

```yaml
containers:
  ports:
  - containerPort: 80   # ✅ Pod is listening on 80
```

Service (`pink-svc-cka16-trb`):

```
Port:        5000/UDP     # ❌ wrong, it should be TCP
TargetPort:  80/UDP       # points to Pod’s port (80), but also marked UDP
Endpoints:   172.17.1.3:80
```

### 🚨 What went wrong

1. The **exam question said**: *“App runs on port 5000”* → we assumed Pod’s containerPort = 5000.
2. But in reality, the Pod YAML shows `containerPort: 80`.

   * That means the Pod app is **actually running on 80, not 5000**.
3. The Service was created incorrectly:

   * Used `port: 5000` with **UDP**, while it should be TCP.
   * Service should expose **TCP 80**, not UDP 5000.

---

## Q5: Both containers share same port within a pod.

There is a deployment with two containers, one is running, and other restarting...

```bash
k describe deployments.apps -n management collect-data # no clue
k describe po -n management collect-data-5759c5c888-gvf2z
Warning  BackOff    14s (x13 over 2m35s)  kubelet            Back-off restarting failed container httpd in pod collect-data-5759c5c888-gvf2z_management(9d91ca38-197d-48fc-8916-d22e54cd899b)
controlplane:~$ k logs -n management deploy/collect-data -c nginx # all good
controlplane:~$ k logs -n management deploy/collect-data -c httpd
Found 2 pods, using pod/collect-data-5759c5c888-gvf2z
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.0.7. Set the 'ServerName' directive globally to suppress this message
(98)Address in use: AH00072: make_sock: could not bind to address [::]:80
(98)Address in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
no listening sockets available, shutting down
AH00015: Unable to open logs

The issue seems that both containers have processes that want to listen on port 80. Depending on container creation order and speed, the first will succeed, the other will fail.

Solution: remove one container.

controlplane:~$ k get deploy -n management 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
collect-data   0/2     2            0           29m
controlplane:~$ k edit deploy -n management collect-data 
deployment.apps/collect-data edited
controlplane:~$ k rollout restart deployment -n management collect-data 
deployment.apps/collect-data restarted
controlplane:~$ k get deploy -n management collect-data 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
collect-data   2/2     2            2           31m
```
---

## Q6

The error is pretty clear:

```
spec.ports[0].nodePort: Invalid value: 32345: provided port is already allocated
```

That means **another Service in your cluster is already using NodePort `32345`**, and Kubernetes won’t allow duplicates.

### 🔧 Fix options:

1. **Check which Service is already using that NodePort:**

   ```bash
   kubectl get svc -A | grep 32345
   ```

   This will show you the service that already has `32345` assigned.

2. **Pick a different NodePort in the range 30000–32767**
   Example, edit your YAML and change:

   ```yaml
   ports:
   - port: 80
     targetPort: 80
     nodePort: 32346   # change this
   type: NodePort
   ```

3. **Reapply the Service:**

   ```bash
   kubectl apply -f /tmp/kubectl-edit-76677757.yaml
   ```

---

##  Q7

```bash
root@controlplane ~ ➜  k describe po -n triton webapp-mysql-7bd5857746-hrnnn 
Name:             webapp-mysql-7bd5857746-hrnnn
Namespace:        triton
Priority:         0
Service Account:  default
Node:             controlplane/192.168.121.159
Start Time:       Tue, 07 Oct 2025 20:30:39 +0000
Labels:           name=webapp-mysql
                  pod-template-hash=7bd5857746
Annotations:      <none>
Status:           Pending
IP:               
IPs:              <none>
Controlled By:    ReplicaSet/webapp-mysql-7bd5857746
Containers:
  webapp-mysql:
    Container ID:   
    Image:          mmumshad/simple-webapp-mysql
    Image ID:       
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment:
      DB_Host:      mysql
      DB_User:      root
      DB_Password:  paswrd
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-9xjnx (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   False 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-9xjnx:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason                  Age                    From               Message
  ----     ------                  ----                   ----               -------
  Normal   Scheduled               5m27s                  default-scheduler  Successfully assigned triton/webapp-mysql-7bd5857746-hrnnn to controlplane
  Warning  FailedCreatePodSandBox  5m27s                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "b1f2d3d14c84321dd0b5ff7041449db641159f6676d660f742bce390b1b5cd9d": plugin type="weave-net" name="weave" failed (add): unable to allocate IP address: Post "http://127.0.0.1:6784/ip/b1f2d3d14c84321dd0b5ff7041449db641159f6676d660f742bce390b1b5cd9d": dial tcp 127.0.0.1:6784: connect: connection refused

root@controlplane ~ ➜  ls /opt/cni/bin/
bandwidth  dhcp   firewall     host-local  LICENSE   macvlan  ptp        sbr     tap     vlan  weave-ipam  weave-plugin-2.8.1
bridge     dummy  host-device  ipvlan      loopback  portmap  README.md  static  tuning  vrf   weave-net

root@controlplane ~ ➜  ls /etc/cni/net.d/
10-weave.conflist

root@controlplane ~ ➜  k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   32m   v1.33.0

root@controlplane ~ ➜  k get po -A
NAMESPACE     NAME                                   READY   STATUS              RESTARTS   AGE
kube-system   coredns-674b8bbfcf-2gsl6               1/1     Running             0          34m
kube-system   coredns-674b8bbfcf-57q4d               1/1     Running             0          34m
kube-system   etcd-controlplane                      1/1     Running             0          34m
kube-system   kube-apiserver-controlplane            1/1     Running             0          34m
kube-system   kube-controller-manager-controlplane   1/1     Running             0          34m
kube-system   kube-proxy-g9h2x                       1/1     Running             0          34m
kube-system   kube-scheduler-controlplane            1/1     Running             0          34m
triton        mysql                                  0/1     ContainerCreating   0          8m40s
triton        webapp-mysql-7bd5857746-hrnnn          0/1     ContainerCreating   0          8m40s

root@controlplane ~ ➜  kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.apps/weave-net created

root@controlplane ~ ➜  k get po -A
NAMESPACE     NAME                                   READY   STATUS    RESTARTS   AGE
kube-system   coredns-674b8bbfcf-2gsl6               1/1     Running   0          36m
kube-system   coredns-674b8bbfcf-57q4d               1/1     Running   0          36m
kube-system   etcd-controlplane                      1/1     Running   0          36m
kube-system   kube-apiserver-controlplane            1/1     Running   0          36m
kube-system   kube-controller-manager-controlplane   1/1     Running   0          36m
kube-system   kube-proxy-g9h2x                       1/1     Running   0          36m
kube-system   kube-scheduler-controlplane            1/1     Running   0          36m
kube-system   weave-net-kv8dz                        2/2     Running   0          16s
triton        mysql                                  1/1     Running   0          11m
triton        webapp-mysql-7bd5857746-hrnnn          1/1     Running   0          11m

root@controlplane ~ ➜  
```

Perfect — this is a **CNI failure** case, and you’ve gathered exactly the right data, sweetheart ❤️.

Let’s break it down carefully and solve it step by step 👇

## 🧩 The core error:

```
Failed to create pod sandbox:
rpc error: code = Unknown desc = failed to setup network for sandbox ...
plugin type="weave-net" name="weave" failed (add):
unable to allocate IP address: Post "http://127.0.0.1:6784/ip/...": dial tcp 127.0.0.1:6784: connect: connection refused
```

This line tells the full story:

> kubelet is trying to contact the **Weave Net CNI** plugin via `127.0.0.1:6784`, but the **Weave Net daemon isn’t running** on the node — or it crashed.

## 🧠 Why this happens

Kubernetes relies on a **CNI plugin** to handle pod networking (assign IPs, connect pods, etc.).
Weave Net runs as **a DaemonSet** — meaning **a pod per node**.

If the weave pod isn’t running or is failing, no pod on that node can start because the network setup step fails.
That’s exactly why your pods stay in **ContainerCreating / Pending** state.

## 🧾 Evidence

* ✅ CNI binaries exist: `/opt/cni/bin/weave-net` and `/opt/cni/bin/weave-ipam`
* ✅ Config exists: `/etc/cni/net.d/10-weave.conflist`
* ❌ But weave Net DaemonSet isn’t functioning (port 6784 unreachable).

---

