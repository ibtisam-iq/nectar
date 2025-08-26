
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

## Apiserver Crash 
```bash
#1 incorrect flag
controlplane:~$ k get po
The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?
watch crictl ps     #  kube-apiserver pod is not found

controlplane:~$ ls /var/log/pods/kube-system_kube-apiserver-controlplane_e0ee64f88fb19c12ee94f5b24507f060/kube-apiserver/6.log # the lowest
2025-08-23T08:51:03.639438796Z stderr F Error: unknown flag: --this-is-very-wrong

controlplane:~$ cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-ace5309febe6b93e42a1d04d055bc4025b85d8511ddcd1aa83a995129c3c
c03c.log   # see carefully, you will see > 1 log files # the lowest
2025-08-23T08:26:41.615226434Z stderr F Error: unknown flag: --this-is-very-wrong

#2 incorrect flag value:    # --etcd-servers=hhttps://127.0.0.1:2379
controlplane:~$ k get po    # no result, stuck
watch crictl ps             #  kube-apiserver pod is not found

crictl ps -a                # get pod ID
controlplane:~$ crictl logs 60c420d4a22fe
W0823 09:18:03.588631       1 logging.go:55] [core] [Channel #1 SubChannel #3]grpc: addrConn.createTransport failed to connect to {Addr: "hhttps://127.0.0.1:2379", ServerName: "127.0.0.1:2379", }. Err: connection error: desc = "transport: Error while dialing: dial tcp: address hhttps://127.0.0.1:2379: too many colons in address"
F0823 09:18:07.593672       1 instance.go:226] Error creating leases: error creating storage factory: context deadline exceeded

#3 incorrect key name in the manifest:   #  apiVersio: v1
controlplane:~$ k get po
The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?

/var/log/pods # nothing
crictl logs # nothing

controlplane:~$ tail -f /var/log/syslog | grep apiserver
2025-08-23T09:39:22.105074+00:00 controlplane kubelet[27556]: E0823 09:39:22.104435   27556 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(Object 'apiVersion' is missing in '{\"apiVersio\":\"v1\",\"kind\"
journalctl | grep apiserver # same message like tail -f /var/log/syslog | grep apiserver
```
---

## Apiserver Misconfigured

```bash
#1      # There is wrong YAML in the manifest at metadata;
controlplane:~$ cat /var/log/syslog | grep apiserver
2025-08-23T11:21:56.530696+00:00 controlplane kubelet[1504]: E0823 11:21:56.530513    1504 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(yaml: line 4: could not find expected ':'), please check config file" path="/etc/kubernetes/manifests/kube-apiserver.yaml"

#2
cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-95d67ca47280ee0bd9599c6ba2a166fffd4e4d6138d8caaed8
2ec77c40bc8ef3.log 
2025-08-23T11:39:36.36137879Z stderr F Error: unknown flag: --authorization-modus
```
---

## Kube Controller Manager Misconfigured

```bash
# kube-controller-manager-controlplane restarting...

crictl logs 9cef2cf7061d6  # no clue
cat /var/log/syslog | grep kube-controller-manager # no clue
journalctl | grep kube-controller-manager
cat /var/log/containers/kube-controller-manager-controlplane_kube-system_kube-controller-manager-d559f74bec79087e6e77a69ff8a9c42f46c4666b7310898f2132eea9b6e72dce.log
2025-08-23T13:10:02.535173834Z stderr F Error: unknown flag: --project-sidecar-insertion
```

---

## Kubelet Misconfigured

```bash
k get po -A   # all good, all running
controlplane:~$ k run nginx --image nginx
pod/nginx created
controlplane:~$ k describe po nginx
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  35s   default-scheduler  0/2 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }, 1 node(s) had untolerated taint {node.kubernetes.io/unreachable: }. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

controlplane:~$ systemctl status kubelet    # all running...
controlplane:~$ k get no                    
NAME           STATUS     ROLES           AGE    VERSION
controlplane   Ready      control-plane   4d4h   v1.33.2
node01         NotReady   <none>          4d4h   v1.33.2

node01:~$ journalctl -u kubelet -f
Aug 23 13:53:14 node01 kubelet[8691]: E0823 13:53:14.926448    8691 run.go:72] "command failed" err="failed to parse kubelet flag: unknown flag: --improve-speed"
Aug 23 13:53:14 node01 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE

node01:~$ ls /var/lib/kubelet/    
actuated_pods_state   checkpoints  cpu_manager_state  kubeadm-flags.env     pki      plugins_registry  pods
allocated_pods_state  config.yaml  device-plugins     memory_manager_state  plugins  pod-resources
node01:~$ cat /var/lib/kubelet/kubeadm-flags.env     # remove --improve-speed
KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10 --improve-speed"

1) --kubeconfig=/etc/kubernetes/kubelet.conf
2) --config=/var/lib/kubelet/config.yaml
3) cat /var/lib/kubelet/kubeadm-flags.env
```
---
## Application Misconfigured

```bash
#1
controlplane:~$ k describe po -n application1 api-6768cbb9cc-hz5wt 
Events:
  Warning  Failed     1s (x7 over 62s)  kubelet            Error: configmap "category" not found
controlplane:~$ k get cm -n application1
NAME                 DATA   AGE
configmap-category   1      4m25s

controlplane:~$ k edit deploy -n application1
deployment.apps/api edited
controlplane:~$ k rollout restart deployment -n application1 api 
deployment.apps/api restarted
controlplane:~$ k get deployments.apps -n application1
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
api    3/3     3            3           10m

#2
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE    VERSION
controlplane   Ready    control-plane   4d7h   v1.33.2
controlplane:~$ k describe po management-frontend-7b897f454f-2zpgh 
Name:             management-frontend-7b897f454f-2zpgh
Node:             staging-node1/      # cause
Status:           Pending
IP:               
IPs:              <none>
Events:            <none>            # effect, no events, not scheduled yet
controlplane:~$ k get events         # nothing special

controlplane:~$ k edit deploy management-frontend 
deployment.apps/management-frontend edited
controlplane:~$ k rollout restart deployment management-frontend 
deployment.apps/management-frontend restarted
controlplane:~$ k get po
NAME                                   READY   STATUS        RESTARTS   AGE
management-frontend-5987bc84b5-9hnsd   1/1     Running       0          4s
management-frontend-5987bc84b5-fczz4   1/1     Running       0          4s
management-frontend-5987bc84b5-gbr5k   1/1     Running       0          7s
management-frontend-5987bc84b5-h9mzz   1/1     Running       0          6s
management-frontend-5987bc84b5-ms7hl   1/1     Running       0          6s

#3
There is a deployment with two containers, one is running, and other restarting...

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

# 4
Create a Pod named pod1 of image nginx:alpine
Make key tree of ConfigMap trauerweide available as environment variable TREE1
Mount all keys of ConfigMap birke as volume. The files should be available under /etc/birke/*
Test env+volume access in the running Pod

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

# 5
controlplane:~$ k logs goapp-deployment-77549cf8d6-rr5q4
Error: PORT environment variable not set
controlplane:~$ k edit deployments.apps goapp-deployment 
deployment.apps/goapp-deployment edited
controlplane:~$ k get po
NAME                              READY   STATUS    RESTARTS   AGE
goapp-deployment-9d4fb95f-rq2fc   1/1     Running   0          7s
controlplane:~$ k get svc
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
goapp-service   ClusterIP   10.111.109.109   <none>        8080/TCP   11m
kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP    5d
controlplane:~$ curl http://10.111.109.109:8080
Hello, Kubernetes! Here is a UUID: f3f5e0f0-7786-4f2d-90a2-2510b737aec3
controlplane:~$ 

      env:
        - name: PORT
          value: "8080"         # MUST match the port your app expects
```

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

Perfect exam-style YAML task ❤️ Let’s carefully construct the pod definition.

---

### 🔹 Requirements Breakdown

* Pod name: **`alpine-pod-pod`**
* Image: **`alpine:latest`**
* Container name: **`alpine-container`**
* Use **command**: `/bin/sh`
* Use **args**: `["-c", "tail -f /config/log.txt"]`
* Mount a **volume** named `config-volume` from an existing **ConfigMap** `log-configmap`
* Mount path: `/config`
* Restart policy: **Never**

---

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
