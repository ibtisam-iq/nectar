## Q1 Main PID: 1557 (code=exited, status=0/SUCCESS)

```bash
controlplane:~$ systemctl status kubelet
○ kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: inactive (dead) since Thu 2025-08-28 00:38:35 UTC; 34s ago
   Duration: 19min 57.555s
       Docs: https://kubernetes.io/docs/
    Process: 1557 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exite>
   Main PID: 1557 (code=exited, status=0/SUCCESS)
        CPU: 12.016s

Aug 28 00:19:24 controlplane kubelet[1557]: E0828 00:19:24.090558    1557 kuberuntime_manager.go:1161] "killPodWithSyncResult failed" err="faile>
Aug 28 00:38:35 controlplane systemd[1]: Stopping kubelet.service - kubelet: The Kubernetes Node Agent...
Aug 28 00:38:35 controlplane systemd[1]: kubelet.service: Deactivated successfully.
Aug 28 00:38:35 controlplane systemd[1]: Stopped kubelet.service - kubelet: The Kubernetes Node Agent.
Aug 28 00:38:35 controlplane systemd[1]: kubelet.service: Consumed 12.016s CPU time.

It means:
- The kubelet process with PID 1557 has exited.
- Exit code 0/SUCCESS = it did not crash; it just stopped cleanly.
- So right now, kubelet is not running.

controlplane:~$ systemctl restart kubelet
controlplane:~$ systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Thu 2025-08-28 00:39:23 UTC; 9s ago
       Docs: https://kubernetes.io/docs/
   Main PID: 13299 (kubelet)
      Tasks: 10 (limit: 2614)
     Memory: 73.7M (peak: 73.9M)
        CPU: 300ms
     CGroup: /system.slice/kubelet.service
             └─13299 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf -->

Aug 28 00:39:25 controlplane kubelet[13299]: E0828 00:39:25.406898   13299 kubelet.go:3311] "Failed creating a mirror pod" err="pods \"kube-cont>

controlplane:~$ 
```

---

## Q2 Wrong Binary Path (code=exited, status=203/EXEC)

```bash
candidate@cka1024:~$ k get node (1 node cluster)
E0423 12:27:08.326639   12871 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.100.41:6443/api?timeout=32s\": dial tcp 192.168.100.41:6443: connect: connection refused"
The connection to the server 192.168.100.41:6443 was refused - did you specify the right host or port?

Okay, this looks very wrong. First we check if the kubelet is running:

candidate@cka1024:~$ sudo -i

root@cka1024:~# ps aux | grep kubelet
root       12892  0.0  0.1   7076  ...  0:00 grep --color=auto kubelet

No kubectl process running, just the grep command itself is displayed. We check if the kubelet is configured as service, which is default for a kubeadm installation:

➜ root@cka1024:~# service kubelet status
○ kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: inactive (dead) since Sun 2025-03-23 08:16:52 UTC; 1 month 0 days ago
   Duration: 2min 46.830s
       Docs: https://kubernetes.io/docs/
   Main PID: 7346 (code=exited, status=0/SUCCESS)
        CPU: 5.956s
...

We can see it's not running (inactive) in this line:

Active: inactive (dead) since Sun 2025-03-23 08:16:52 UTC; 1 month 0 days ago
But the kubelet is configured as a service with config at /usr/lib/systemd/system/kubelet.service, let's try to start it:

➜ root@cka1024:~# service kubelet start

➜ root@cka1024:~# service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: activating (auto-restart) (Result: exit-code) since Wed 2025-04-23 12:31:07 UTC; 2s ago
       Docs: https://kubernetes.io/docs/
    Process: 13014 ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EX>
   Main PID: 13014 (code=exited, status=203/EXEC)
        CPU: 10ms

Apr 23 12:31:07 cka1024 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Above we see it's trying to execute /usr/local/bin/kubelet in this line:

Process: 13014 ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EX>
It does so with some arguments defined in its service config file. A good way to find errors and get more info is to run the command manually:

root@cka1024:~# /usr/local/bin/kubelet
-bash: /usr/local/bin/kubelet: No such file or directory

root@cka1024:~# whereis kubelet
kubelet: /usr/bin/kubelet
That's the issue: wrong path to the kubelet binary.

root@cka1024:~# vim /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf   # ExecStart=/usr/bin/kubelet from /usr/local/bin/kubelet

In the very last line we updated the binary path to /usr/bin/kubelet.

Now we reload the service:

root@cka1024:~# systemctl daemon-reload

root@cka1024:~# service kubelet restart

root@cka1024:~# service kubelet status
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Wed 2025-04-23 12:33:25 UTC; 5s ago
       Docs: https://kubernetes.io/docs/
   Main PID: 13124 (kubelet)
      Tasks: 9 (limit: 1317)
     Memory: 88.3M (peak: 88.6M)
        CPU: 1.093s
     CGroup: /system.slice/kubelet.service
             └─13124 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/ku>
...

root@cka1024:~# ps aux | grep kubelet
root       13124  9.2  7.1 1896084 82432 ?       Ssl  12:33   0:01 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10
...
That looks much better. We can wait for the containers to appear, which can take a minute:

root@cka1024:~# watch crictl ps
CONTAINER      ...  CREATED           STATE       NAME                      ...
ccfbd17742b05  ...  25 seconds ago    Running     kube-controller-manager   ...
ff3910e3c8c6c  ...  25 seconds ago    Running     kube-scheduler            ...
9b49473786774  ...  25 seconds ago    Running     kube-apiserver            ...
f5de1f6e11d5c  ...  26 seconds ago    Running     etcd                      ...

Also the node should be available, give it a bit of time though:

root@cka1024:~# k get node
NAME      STATUS   ROLES           AGE   VERSION
cka1024   Ready    control-plane   31d   v1.33.1

Finally we create the requested Pod:

root@cka1024:~# k run success --image nginx:1-alpine
pod/success created

root@cka1024:~# k get pod success -o wide
NAME      READY   STATUS    ...   NODE      NOMINATED NODE   READINESS GATES
success   1/1     Running   ...   cka1024   <none>           <none>
```

---

## Q3 Unknown Flag

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

## Q4 Mistake in Config Files

In controlplane node, something problem with kubelet configuration files, fix that issue.

- location: `/var/lib/kubelet/config.yaml` and `/etc/kubernetes/kubelet.conf`

```bash
controlplane ~ ➜  k get no
NAME           STATUS     ROLES           AGE   VERSION
controlplane   Ready      control-plane   13m   v1.33.0
node01         NotReady   <none>          13m   v1.33.0
controlplane:~$ k run test --image nginx
pod/test created
controlplane:~$ k get po
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          9s

node01 ~ ✖ systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
     Active: activating (auto-restart) 
   Main PID: 10112 (code=exited, status=1/FAILURE)

controlplane:~$ journalctl -u kubelet -f      

Aug 27 22:35:53 controlplane kubelet[37845]: E0827 22:35:53.418423   37845 run.go:72] "command failed" err="failed to construct kubelet dependencies: unable to load client CA file /etc/kubernetes/pki/CA.CERTIFICATE: open /etc/kubernetes/pki/CA.CERTIFICATE: no such file or directory"
Aug 27 22:35:53 controlplane systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE

controlplane:~$ vi /var/lib/kubelet/config.yaml     # correct     clientCAFile: /etc/kubernetes/pki/ca.crt
controlplane:~$ systemctl restart kubelet

controlplane:~$ journalctl -u kubelet -f
Aug 27 22:45:11 controlplane kubelet[40112]: E0827 22:45:11.297088   40112 controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://172.30.1.2:64433333/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/controlplane?timeout=10s\": dial tcp: address 64433333: invalid port" interval="3.2s"

controlplane:~$ vi /etc/kubernetes/kubelet.conf     # correct 6443
controlplane:~$ systemctl restart kubelet

---
node01 ~ ➜  systemctl status kubelet               # correct 6443, it is set 6553
● kubelet.service - kubelet: The Kubernetes Node Agent
     Active: active (running) since Tue 2025-10-07 20:21:34 UTC; 15s ago

Oct 07 20:21:41 node01 kubelet[16969]: E1007 20:21:41.306369   16969 kubelet_node_status.go:107] "Unable to register node with API server" err="Post \"https://controlplan>
Oct 07 20:21:42 node01 kubelet[16969]: E1007 20:21:42.033633   16969 reflector.go:200] "Failed to watch" err="failed to list *v1.CSIDriver: Get \"https://controlplane:655>
Oct 07 20:21:42 node01 kubelet[16969]: E1007 20:21:42.848181   16969 event.go:368] "Unable to write event (may retry after sleeping)" err="Post \"https://controlplane:655>
Oct 07 20:21:43 node01 kubelet[16969]: E1007 20:21:43.125198   16969 reflector.go:200] "Failed to watch" err="failed to list *v1.Service: Get \"https://controlplane:6553/>
Oct 07 20:21:43 node01 kubelet[16969]: E1007 20:21:43.556554   16969 reflector.go:200] "Failed to watch" err="failed to list *v1.RuntimeClass: Get \"https://controlplane:>
Oct 07 20:21:44 node01 kubelet[16969]: E1007 20:21:44.977721   16969 eviction_manager.go:292] "Eviction manager: failed to get summary stats" err="failed to get node info>
Oct 07 20:21:45 node01 kubelet[16969]: E1007 20:21:45.518560   16969 reflector.go:200] "Failed to watch" err="failed to list *v1.Node: Get \"https://controlplane:6553/api>
Oct 07 20:21:47 node01 kubelet[16969]: E1007 20:21:47.330880   16969 controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://controlplane:6553/a>
Oct 07 20:21:47 node01 kubelet[16969]: I1007 20:21:47.709175   16969 kubelet_node_status.go:75] "Attempting to register node" node="node01"
Oct 07 20:21:47 node01 kubelet[16969]: E1007 20:21:47.712846   16969 kubelet_node_status.go:107] "Unable to register node with API server" err="Post \"https://controlplan>


node01 ~ ✖ journalctl -u kubelet -f 
Oct 07 20:22:12 node01 kubelet[16969]: E1007 20:22:12.864212   16969 event.go:368] "Unable to write event (may retry after sleeping)" err="Post \"https://controlplane:6553/api/v1/namespaces/default/events\": dial tcp 192.168.211.184:6553: connect: connection refused" event="&Event{ObjectMeta:{node01.186c4f125c69f780  default    0 0001-01-01 00:00:00 +0000 UTC <nil> <nil> map[] map[] [] [] []},InvolvedObject:ObjectReference{Kind:Node,Namespace:,Name:node01,UID:node01,APIVersion:,ResourceVersion:,FieldPath:,},Reason:Starting,Message:Starting kubelet.,Source:EventSource{Component:kubelet,Host:node01,},FirstTimestamp:2025-10-07 20:21:34.673475456 +0000 UTC m=+0.183081277,LastTimestamp:2025-10-07 20:21:34.673475456 +0000 UTC m=+0.183081277,Count:1,Type:Normal,EventTime:0001-01-01 00:00:00 +0000 UTC,Series:nil,Action:,Related:nil,ReportingController:kubelet,ReportingInstance:node01,}"

```
---

## Q5 Kubelet Uninstalled

As a Kubernetes administrator, you are unable to run any of the kubectl commands on the cluster. Troubleshoot the problem and get the cluster to a functioning state.

```bash
cluster2-controlplane ~ ➜  k get po
The connection to the server cluster2-controlplane:6443 was refused - did you specify the right host or port?

cluster2-controlplane ~ ✖ systemctl status kubelet
Unit kubelet.service could not be found.

cluster2-controlplane ~ ➜  systemctl restart kubelet
Failed to restart kubelet.service: Unit kubelet.service not found.

cluster2-controlplane ~ ✖ kubelet --version
-bash: kubelet: command not found

cluster2-controlplane ~ ✖ crictl ps -a            # kube-api is missing
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD                                             NAMESPACE
1113de67362a1       ead0a4a53df89       3 hours ago         Running             coredns                   0                   6b0e9856ba2cb       coredns-7484cd47db-d49n4                        kube-system
d6007d7699fc0       6331715a2ae96       3 hours ago         Running             calico-kube-controllers   0                   28a813d9bfaf5       calico-kube-controllers-5745477d4d-f85nw        kube-system
f132952240e20       ead0a4a53df89       3 hours ago         Running             coredns                   0                   bf10e9065f69b       coredns-7484cd47db-z9587                        kube-system
aba9eb828077b       c9fe3bce8a6d8       3 hours ago         Running             kube-flannel              0                   69bb68b050027       canal-9rt2t                                     kube-system
bab59c97d4639       feb26d4585d68       3 hours ago         Running             calico-node               0                   69bb68b050027       canal-9rt2t                                     kube-system
92606c940e47b       7dd6ea186aba0       3 hours ago         Exited              install-cni               0                   69bb68b050027       canal-9rt2t                                     kube-system
60301c825929b       040f9f8aac8cd       3 hours ago         Running             kube-proxy                0                   26c8826e3f4b3       kube-proxy-ztbtw                                kube-system
3543947ce7882       a9e7e6b294baf       3 hours ago         Running             etcd                      0                   c63740a8910c6       etcd-cluster2-controlplane                      kube-system
e6030f877ef30       a389e107f4ff1       3 hours ago         Exited              kube-scheduler            0                   2fff814eb5b2a       kube-scheduler-cluster2-controlplane            kube-system
bf6948a625326       8cab3d2a8bd0f       3 hours ago         Exited              kube-controller-manager   0                   0e9a58616d301       kube-controller-manager-cluster2-controlplane   kube-system

cluster2-controlplane ~ ➜  kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"32", GitVersion:"v1.32.0", GitCommit:"70d3cc986aa8221cd1dfb1121852688902d3bf53", GitTreeState:"clean", BuildDate:"2024-12-11T18:04:20Z", GoVersion:"go1.23.3", Compiler:"gc", Platform:"linux/amd64"}

cluster2-controlplane ~ ➜  sudo apt-mark unhold kubelet && \
sudo apt-get update && sudo apt-get install -y kubelet='1.32.0' && \
sudo apt-mark hold kubelet
kubelet was already not on hold.
Hit:2 http://archive.ubuntu.com/ubuntu jammy InRelease                                                                                                     
Fetched 21.6 MB in 2s (8,802 kB/s)                           
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Package kubelet is not available, but is referred to by another package.
This may mean that the package is missing, has been obsoleted, or
is only available from another source

E: Version '1.32.0' for 'kubelet' was not found

cluster2-controlplane ~ ✖ apt-cache madison kubelet
   kubelet | 1.32.9-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.8-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.7-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.6-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.5-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.4-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.3-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.2-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.1-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubelet | 1.32.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages

cluster2-controlplane ~ ➜  sudo apt-mark unhold kubelet && sudo apt-get update && sudo apt-get install -y kubelet='1.32.0-1.1' && sudo apt-mark hold kubelet
kubelet was already not on hold.
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                              
The following NEW packages will be installed:
  kubelet
0 upgraded, 1 newly installed, 0 to remove and 80 not upgraded.
Preparing to unpack .../kubelet_1.32.0-1.1_amd64.deb ...
Unpacking kubelet (1.32.0-1.1) ...
Setting up kubelet (1.32.0-1.1) ...
kubelet set on hold.

cluster2-controlplane ~ ➜  systemctl restart kubelet

cluster2-controlplane ~ ➜  k get no
NAME                    STATUS   ROLES           AGE    VERSION
cluster2-controlplane   Ready    control-plane   171m   v1.32.0
cluster2-node01         Ready    <none>          171m   v1.32.0

cluster2-controlplane ~ ➜  kubelet --version
Kubernetes v1.32.0 
```

Got it sweetheart ❤️ this is happening because the **new Kubernetes apt repo** (`pkgs.k8s.io`) does **not** package versions like plain `1.32.0`.
Instead, the packages are named with the **full deb version string**, for example:

```
kubelet=1.32.0-1.1
```

That’s why `apt` couldn’t find `1.32.0` directly.

### 🔹 Step 1: Check available kubelet versions

Run:

```bash
apt-cache madison kubelet
```

You’ll see output like:

```
  kubelet | 1.32.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb/ ...
  kubelet | 1.31.2-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb/ ...
```

---


