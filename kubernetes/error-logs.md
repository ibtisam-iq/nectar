## Application

```bash
Warning  Failed       1s (x7 over 62s)  kubelet           Error: configmap "category" not found
Warning  Failed     8s (x2 over 10s)  kubelet            Error: secret "postgres-secrte" not found
Warning  Failed     2s (x3 over 18s)  kubelet            Error: couldn't find key db_user in Secret default/postgres-secret
Warning  FailedMount  10s (x6 over 25s)  kubelet          MountVolume.SetUp failed for volume "nginx-config" : configmap "nginx-config" not found

Warning  Failed     10s (x2 over 11s)  kubelet            Error: exec: "shell": executable file not found in $PATH: unknown  # wrong command
E0912 10:41:23.738713       1 run.go:72] "command failed" err="stat /etc/kubernetes/scheduler.config: no such file or directory" # wrong arg
Warning  Failed     4s    kubelet            Failed to pull image "nginx:ltest"

Warning  FailedScheduling  72s   default-scheduler  0/2  nodes are available: 1 node(s) didn't match Pod's node affinity/selector
Warning  FailedScheduling  21s   default-scheduler  0/2  nodes are available: persistentvolumeclaim "pvc-redis" not found.
Warning  FailedScheduling  31s   default-scheduler  0/2  nodes are available: pod has unbound immediate PersistentVolumeClaims.
Warning  FailedScheduling  23s   default-scheduler  0/42 nodes available: insufficient cpu

Warning  Unhealthy  4s (x8 over 34s)  kubelet            Readiness probe failed: stat: can't stat '/tmp/healthy': No such file or directory
k exec space-alien-welcome-message-generator-5c945bc5f9-m9nkb -- touch /tmp/ready

Warning Failed 3s (x3 over 17s) kubelet Error: failed to write "200000": .../cpu.cfs_quota_us: invalid argument   # wrong cpu

Node:             staging-node1/      # cause
Status:           Pending               
IPs:              <none>
Events:           <none>

controlplane:~$ k logs -n management deploy/collect-data -c httpd
(98)Address in use: AH00072: make_sock: could not bind to address [::]:80
(98)Address in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
both containers share same containerPort, either change one of them, or delete.

k edit po pod1     # mountPath: /etc/birke , not /etc/birke/*

controlplane:~$ k logs goapp-deployment-77549cf8d6-rr5q4
Error: PORT environment variable not set

NAME                READY   UP-TO-DATE   AVAILABLE   AGE
stream-deployment   0/0     0            0           4m25s   # replica = 0
black-cka25-trb     1/1     0            1           76s     # Progressing    Unknown  DeploymentPaused
web-ui-deployment   0/1     1            0           4m16s   # pod is yet pending, no scheduling yet

controlplane:~$ k edit deployments.apps postgres-deployment  # add  --env=POSTGRES_PASSWORD=<any-value> # Just keeps restarting because of Postgres startup failure
                                                             # MYSQL_ROOT_PASSWORD for MYSQL
cluster3-controlplane ~ ➜  curl http://cluster3-controlplane:31020
    <h3> Failed connecting to the MySQL database. </h3>
<h2> Environment Variables: DB_Host=ClusterIP svc name <mysql-svc-wl05>; DB_Database=<optional>; DB_User=<mandatory>; DB_Password=<mandatory>;
cluster3-controlplane ~ ➜  k edit po -n canara-wl05 webapp-pod-wl05   # webpod, not database pod.


no matches for kind "Persistentvolumeclaim" in version "v1"
no matches for kind "Persistentvolume" in version "apps/v1"
Error from server (BadRequest): strict decoding error: unknown field "metadata.app"

spec.ports[0].nodePort: Invalid value: 32345: provided port is already allocated
kubectl get svc -A | grep 32345

root@student-node ~ ➜  k logs ckad-flash89-aom --all-containers # CrashLoopBackOff
nginx: [alert] could not open error log file: open() "/var/log/nginx/error.log" failed (2: No such file or directory)
root@student-node ~ ➜  vi ckad-flash89.yaml         # mountPath: /var/log/ to /var/log/nginx


volumeMounts:
  - name: nginx-conf-vol
    mountPath: /etc/nginx/conf.d/default.conf  # Target file path inside container
    subPath: default.conf                      # Key from ConfigMap, Use subPath (when mounting one specific key to a file path)

root@student-node ~ ➜  k logs -n ingress-nginx ingress-nginx-controller-685f679564-m69vw
F0911 00:54:26.128505      55 main.go:83] No service with name default-backend-service found in namespace default: services "default-backend-service" not found  # problem spotted

The Pod "my-pod-cka" is invalid: spec.volumes[1].name: Duplicate value: "shared-storage"
* spec.volumes[0].persistentVolumeClaim: Forbidden: may not specify more than 1 volume type
If volume let say it is PVC in use, and you are asked to append a sidecar container, just add it without add new `volumes` section, instaed use the already in-use.


Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:dev:my-sa" cannot list resource "pods" in API group "" in the namespace "dev"
Error from server (Forbidden): pods/log is forbidden: User "system:serviceaccount:dev:my-sa" cannot get resource "pods/log" in API group "" in the namespace "dev"

cluster1-controlplane ~ ➜  k apply -f peach-pod-cka05-str.yaml 
The Pod "peach-pod-cka05-str" is invalid: spec.containers[0].volumeMounts[0].name: Not found: "peach-pvc-cka05-str"
Kubernetes expects the volumeMount.name to exactly match volumes.name — not the PVC name.

```

---

## Kubelet

```bash
candidate@cka1024:~$ sudo -i
root@cka1024:~# ps aux | grep kubelet
root       12892  0.0  0.1   7076  ...  0:00 grep --color=auto kubelet
root@cka1024:~# whereis kubelet
kubelet: /usr/bin/kubelet

controlplane:~$ systemctl status kubelet
   Main PID: 1557 (code=exited, status=0/SUCCESS) # Exit code 0/SUCCESS = it did not crash; it just stopped cleanly → systemctl restart kubelet
   Main PID: 13014 (code=exited, status=203/EXEC) # vim /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf → ExecStart=/usr/bin/kubelet

cluster2-controlplane ~ ✖ kubelet --version      # kubelet is uninstalled
-bash: kubelet: command not found

node01:~$ journalctl -u kubelet -f

# cat /var/lib/kubelet/kubeadm-flags.env     # remove --improve-speed
Aug 23 13:53:14 node01 kubelet[8691]: E0823 13:53:14.926448    8691 run.go:72] "command failed" err="failed to parse kubelet flag: unknown flag: --improve-speed"
Aug 23 13:53:14 node01 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE

# vi /var/lib/kubelet/config.yaml     # correct     clientCAFile: /etc/kubernetes/pki/ca.crt
Aug 27 22:35:53 controlplane kubelet[37845]: E0827 22:35:53.418423   37845 run.go:72] "command failed" err="failed to construct kubelet dependencies: unable to load client CA file /etc/kubernetes/pki/CA.CERTIFICATE: open /etc/kubernetes/pki/CA.CERTIFICATE: no such file or directory"
Aug 27 22:35:53 controlplane systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE

# vi /etc/kubernetes/kubelet.conf     # correct 6443 
Aug 27 22:45:11 controlplane kubelet[40112]: E0827 22:45:11.297088   40112 controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://172.30.1.2:64433333/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/controlplane?timeout=10s\": dial tcp: address 64433333: invalid port" interval="3.2s"

cluster3-controlplane ~ ➜  k apply -f elastic-app-cka02-arch.yaml   # manifest is provided, just added initContainer, failed because pod is already running
The Pod "elastic-app-cka02-arch" is invalid: spec.initContainers: Forbidden: pod updates may not add or remove containers
cluster3-controlplane ~ ✖ k replace -f elastic-app-cka02-arch.yaml --force
pod "elastic-app-cka02-arch" deleted
pod/elastic-app-cka02-arch replaced
```

---

## Kube-apiserver

```bash
# Wrong Manifest;  ONLY one container, also exited and no increment in Attempt count found

controlplane ~ ➜  journalctl -u kubelet -f | grep apiserver         # takes some time
Oct 04 09:20:00 controlplane kubelet[18566]: E1004 09:20:00.237825   18566 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(Object 'apiVersion' is missing in '{\"apiersion\":\"v1\",\"kind\":\"Pod\",\"metadata\"

controlplane ~ ➜  journalctl -u kubelet -f | grep apiserver     # metadata;
Oct 04 09:37:32 controlplane kubelet[30820]: E1004 09:37:32.159027   30820 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(yaml: line 4: could not find expected ':'), please check config file" path="/etc/kubernetes/manifests/kube-apiserver.yaml"

---

# Wrong Flag Key; Only ONE container, exited, but increment in Attempt count is found and new container id assigned each time
controlplane ~ ➜  crictl logs ca815ceaedaa5   # make sure you pick the recent exited ID, otherwise it says  
Error: unknown flag: --this-is-very-wrong

---

# Wrong Flag Value; Only ONE container, exited, but increment in Attempt count is found and new container id assigned each time

--etcd-servers=hhttps://127.0.0.1:2379
controlplane ~ ➜  crictl logs 92d0aa46a5c56
W1004 12:54:06.097526       1 logging.go:55] [core] [Channel #1 SubChannel #6]grpc: addrConn.createTransport failed to connect to {Addr: "hhttps://127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: Error while dialing: dial tcp: address hhttps://127.0.0.1:2379: too many colons in address"
F1004 12:54:08.829270       1 instance.go:232] Error creating leases: error creating storage factory: context deadline exceeded

--etcd-servers=http://127.0.0.1:2379
controlplane ~ ➜  crictl logs 875e3d275cbbf
W1004 12:30:24.797484       1 logging.go:55] [core] [Channel #10 SubChannel #12]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "error reading server preface: read tcp 127.0.0.1:42360->127.0.0.1:2379: read: connection reset by peer"
F1004 12:30:27.311302       1 instance.go:232] Error creating leases: error creating storage factory: context deadline exceeded

--etcd-cafile=/etc/kubernetes/pki/ca.crt
controlplane ~ ➜  crictl logs db279e0cd1629
W1004 13:22:44.750990       1 logging.go:55] [core] [Channel #2 SubChannel #5]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority"
F1004 13:22:48.831756       1 instance.go:232] Error creating leases: error creating storage factory: context deadline exceeded

---

# Probe Misconfiguration; `crictl ps -a | grep kube-apiserver` shows ONE container at a time, which is running; however, multiple containers are created, and exited.

controlplane ~ ➜  k get po -n kube-system kube-apiserver-controlplane 
NAME                          READY   STATUS    RESTARTS        AGE
kube-apiserver-controlplane   0/1     Running   2 (3m27s ago)   12m

---

# Node status is `NotReady`

controlplane:~$ kubectl get nodes
NAME           STATUS     ROLES           AGE   VERSION
controlplane   NotReady   control-plane   8d    v1.33.2
node01         Ready      <none>          8d    v1.33.2
controlplane:~$ k describe no controlplane 
Conditions:
  Type                 Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----                 ------    -----------------                 ------------------                ------              -------
  NetworkUnavailable   False     Thu, 28 Aug 2025 03:07:13 +0000   Thu, 28 Aug 2025 03:07:13 +0000   FlannelIsUp         Flannel is running on this node
  MemoryPressure       Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure         Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure          Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready                Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node 

controlplane:~$ systemctl restart kubelet
```
