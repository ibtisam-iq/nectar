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

when you run kubectl get nodes OR kubectl get pod -A threw :- The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?

need to wait for few seconds to make above command work again but above error will come again after few second

```bash
controlplane:~$ k describe po -n kube-system kube-apiserver-controlplane 
Name:                 kube-apiserver-controlplane
    State:          Running
      Started:      Thu, 28 Aug 2025 01:06:29 +0000
    Last State:     Terminated
      Reason:       Error
      Exit Code:    137
      Started:      Thu, 28 Aug 2025 01:01:59 +0000
      Finished:     Thu, 28 Aug 2025 01:06:29 +0000
    Ready:          False
    Restart Count:  2
    Liveness:     http-get https://172.30.1.2:6433/livez delay=10s timeout=15s period=10s #success=1 #failure=8
    Readiness:    http-get https://172.30.1.2:6433/readyz delay=0s timeout=15s period=1s #success=1 #failure=3
    Startup:      http-get https://172.30.1.2:6433/livez delay=10s timeout=15s period=10s #success=1 #failure=24
Events:
  Type     Reason          Age                  From     Message
  ----     ------          ----                 ----     -------
  Normal   Killing         9m39s (x2 over 11m)  kubelet  Stopping container kube-apiserver
  Normal   SandboxChanged  9m7s (x2 over 10m)   kubelet  Pod sandbox changed, it will be killed and re-created.
  Warning  Unhealthy       117s (x77 over 17m)  kubelet  Startup probe failed: Get "https://172.30.1.2:6433/livez": dial tcp 172.30.1.2:6433: connect: connection refused
  Normal   Killing         37s (x3 over 13m)    kubelet  Container kube-apiserver failed startup probe, will be restarted
  Normal   Pulled          7s (x6 over 17m)     kubelet  Container image "registry.k8s.io/kube-apiserver:v1.33.2" already present on machine
  Normal   Created         7s (x6 over 17m)     kubelet  Created container: kube-apiserver
  Normal   Started         7s (x6 over 17m)     kubelet  Started container kube-apiserver

# The liveness, readiness, and startup probes are incorrectly configured to use port 6433 instead of the actual API server port 6443.
controlplane:~$ vi /etc/kubernetes/manifests/kube-apiserver.yaml     
controlplane:~$ systemctl restart kubelet

/var/logs/pods and /var/logs/container        # no clue found
```
---
```bash
controlplane:~$ kubectl get nodes
NAME           STATUS     ROLES           AGE   VERSION
controlplane   NotReady   control-plane   8d    v1.33.2
node01         Ready      <none>          8d    v1.33.2
controlplane:~$ k describe no controlplane 
Name:               controlplane
Roles:              control-plane
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=controlplane
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=
                    node.kubernetes.io/exclude-from-external-load-balancers=

Taints:             node.kubernetes.io/unreachable:NoExecute
                    node-role.kubernetes.io/control-plane:NoSchedule
                    node.kubernetes.io/unreachable:NoSchedule
Unschedulable:      false

Conditions:
  Type                 Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----                 ------    -----------------                 ------------------                ------              -------
  NetworkUnavailable   False     Thu, 28 Aug 2025 03:07:13 +0000   Thu, 28 Aug 2025 03:07:13 +0000   FlannelIsUp         Flannel is running on this node
  MemoryPressure       Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure         Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure          Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready                Unknown   Thu, 28 Aug 2025 03:17:14 +0000   Thu, 28 Aug 2025 03:18:43 +0000   NodeStatusUnknown   Kubelet stopped posting node 

controlplane:~$ systemctl restart kubelet
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   8d    v1.33.2
node01         Ready    <none>          8d    v1.33.2
controlplane:~$ 
```
Sweetheart, nice debugging step by step 👌

Here’s what happened in your case:

### Why the controlplane went `NotReady`

* From your `kubectl describe node controlplane`, the key part is:

  ```
  MemoryPressure       Unknown
  DiskPressure         Unknown
  PIDPressure          Unknown
  Ready                Unknown
  Reason: NodeStatusUnknown
  Message: Kubelet stopped posting node status.
  ```

  This means **the kubelet stopped sending heartbeats** to the API server, so the control-plane marked the node as `NotReady`.

* That’s why you saw taints like:

  ```
  node.kubernetes.io/unreachable
  node.kubernetes.io/unreachable:NoSchedule
  ```

  → API server could not reach the kubelet.

### Why restarting kubelet fixed it

* When you ran:

  ```bash
  systemctl restart kubelet
  ```

  → the kubelet service restarted and reconnected to the API server.
* Once it started sending node heartbeats again (`NodeStatus`), the `NotReady` cleared and the node returned to `Ready`.

So essentially, the kubelet had **crashed / hung / lost connectivity** for some time, and a restart reestablished communication.

### How to see *why* kubelet failed

Instead of just restarting, you’d usually check logs to find the root cause:

```bash
# See current kubelet logs
journalctl -u kubelet -xe

# Or stream logs as they come
journalctl -u kubelet -f
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

video-app deployment replicas 0. fix this issue

expected: 2 replicas

```bash
controlplane:~$ k get po -A
NAMESPACE            NAME                                      READY   STATUS             RESTARTS      AGE
kube-system          kube-controller-manager-controlplane      0/1     CrashLoopBackOff   1 (4s ago)    6s

controlplane:~$ k describe po -n kube-system kube-controller-manager-controlplane 
Name:                 kube-controller-manager-controlplane
Namespace:            kube-system
    Command:
      kube-controller-manegaar
    State:          Waiting
      Reason:       RunContainerError
    Last State:     Terminated
      Reason:       StartError
      Message:      failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "kube-controller-manegaar": executable file not found in $PATH: unknown
      Exit Code:    128
      Started:      Thu, 01 Jan 1970 00:00:00 +0000
      Finished:     Wed, 27 Aug 2025 23:31:22 +0000
    Ready:          False
    Restart Count:  2
Events:
  Type     Reason   Age               From     Message
  ----     ------   ----              ----     -------

  Warning  Failed   3s (x3 over 27s)  kubelet  Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "kube-controller-manegaar": executable file not found in $PATH: unknown
  Warning  BackOff  3s (x5 over 25s)  kubelet  Back-off restarting failed container kube-controller-manager in pod kube-controller-manager-controlplane_kube-system(c2086dde319f21250262f5d5edcf3af3)

controlplane:~$ k edit po -n kube-system kube-controller-manager-controlplane 
Edit cancelled, no changes made.
controlplane:~$ vi /etc/kubernetes/manifests/kube-controller-manager.yaml 
controlplane:~$ systemctl restart kubelet
controlplane:~$ k get po -A
NAMESPACE            NAME                                      READY   STATUS    RESTARTS      AGE
kube-system          kube-controller-manager-controlplane      1/1     Running   0             56s
controlplane:~$ k get deploy
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
video-app   2/2     2            2           4m18s
controlplane:~$ 
```
---

## Kubelet

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

In controlplane node, something problem with kubelet configuration files, fix that issue.

- location: /var/lib/kubelet/config.yaml and /etc/kubernetes/kubelet.conf

```bash
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   8d    v1.33.2
node01         Ready    <none>          8d    v1.33.2
controlplane:~$ k run test --image nginx
pod/test created
controlplane:~$ k get po
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          9s

controlplane:~$ journalctl -u kubelet -f      

Aug 27 22:35:53 controlplane kubelet[37845]: E0827 22:35:53.418423   37845 run.go:72] "command failed" err="failed to construct kubelet dependencies: unable to load client CA file /etc/kubernetes/pki/CA.CERTIFICATE: open /etc/kubernetes/pki/CA.CERTIFICATE: no such file or directory"
Aug 27 22:35:53 controlplane systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE

controlplane:~$ vi /var/lib/kubelet/config.yaml     # correct     clientCAFile: /etc/kubernetes/pki/ca.crt
controlplane:~$ systemctl restart kubelet

controlplane:~$ journalctl -u kubelet -f
Aug 27 22:45:11 controlplane kubelet[40112]: E0827 22:45:11.297088   40112 controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://172.30.1.2:64433333/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/controlplane?timeout=10s\": dial tcp: address 64433333: invalid port" interval="3.2s"

controlplane:~$ vi /etc/kubernetes/kubelet.conf     # correct 6443
controlplane:~$ systemctl restart kubelet
```

---

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

## Probe is failing for api-server

- All main 4 pods are kept on restarting.
- `k get no` works sometimes, and then failed... So, we can't debug using `kubectl`.
- Whenever you get this error, you can wait for 10-15 seconds for the kubectl command to work again, but the issue recurs after few seconds.


```bash
cluster4-controlplane ~ ➜  k get po
The connection to the server cluster4-controlplane:6443 was refused - did you specify the right host or port?

cluster4-controlplane ~ ✖ crictl ps -a
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD                                             NAMESPACE
2f3b05dd6df6a       c2e17b8d0f4a3       2 minutes ago       Exited              kube-apiserver            17                  d75f87fb08e88       kube-apiserver-cluster4-controlplane            kube-system
8bf6904ce04b1       6331715a2ae96       2 minutes ago       Exited              calico-kube-controllers   16                  5cec129eb419d       calico-kube-controllers-5745477d4d-bv27d        kube-system
e4abe2a3f8443       a389e107f4ff1       4 minutes ago       Exited              kube-scheduler            11                  5877f565237e8       kube-scheduler-cluster4-controlplane            kube-system
bfbbc3e9b78fd       8cab3d2a8bd0f       5 minutes ago       Exited              kube-controller-manager   11                  afa9e6be0280b       kube-controller-manager-cluster4-controlplane   kube-system
847466cf084ea       ead0a4a53df89       About an hour ago   Running             coredns                   0                   db97c8694be46       coredns-7484cd47db-zc5vv                        kube-system
8e79b09792248       ead0a4a53df89       About an hour ago   Running             coredns                   0                   2c2b590d6e49b       coredns-7484cd47db-8zx9c                        kube-system
72b3eaaab1f04       c9fe3bce8a6d8       About an hour ago   Running             kube-flannel              0                   774a4b7a7c146       canal-m9t4m                                     kube-system
f0d517661be4c       feb26d4585d68       About an hour ago   Running             calico-node               0                   774a4b7a7c146       canal-m9t4m                                     kube-system
686d28561813d       7dd6ea186aba0       About an hour ago   Exited              install-cni               0                   774a4b7a7c146       canal-m9t4m                                     kube-system
7e4c8560a189b       040f9f8aac8cd       About an hour ago   Running             kube-proxy                0                   56aa52b375a6e       kube-proxy-c7gxs                                kube-system
81ff4a9ffb073       a9e7e6b294baf       About an hour ago   Running             etcd                      0                   79c723a82c168       etcd-cluster4-controlplane                      kube-system

cluster4-controlplane ~ ✖ journalctl -u kubelet -f | grep -i api-server
^C

cluster4-controlplane ~ ✖ journalctl -u kubelet -f | grep -i apiserver
Sep 14 16:52:53 cluster4-controlplane kubelet[23847]: I0914 16:52:53.296371   23847 status_manager.go:890] "Failed to get status for pod" podUID="bc07aa168cb55415fdfa9ff33bcf3228" pod="kube-system/kube-apiserver-cluster4-controlplane" err="Get \"https://cluster4-controlplane:6443/api/v1/namespaces/kube-system/pods/kube-apiserver-cluster4-controlplane\": dial tcp 192.168.67.177:6443: connect: connection refused"
^C

cluster4-controlplane ~ ➜  crictl logs 2f3b05dd6df6a                                 # no clue

cluster4-controlplane ~ ➜  sudo netstat -tulnp | grep 6443

cluster4-controlplane ~ ✖ vi /etc/kubernetes/manifests/kube-apiserver.yaml             # just changed the port only, no change for host.

cluster4-controlplane ~ ➜  systemctl restart kubelet

cluster4-controlplane ~ ➜  k get po
No resources found in default namespace.

cluster4-controlplane ~ ➜  crictl ps -a
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD                                             NAMESPACE
2896357489b7c       6331715a2ae96       3 minutes ago       Running             calico-kube-controllers   20                  5cec129eb419d       calico-kube-controllers-5745477d4d-bv27d        kube-system
6172aa3ed1f68       a389e107f4ff1       3 minutes ago       Running             kube-scheduler            13                  5877f565237e8       kube-scheduler-cluster4-controlplane            kube-system
13c11161c8072       c2e17b8d0f4a3       3 minutes ago       Running             kube-apiserver            0                   27c282fe47817       kube-apiserver-cluster4-controlplane            kube-system
f0ba3efa9047d       8cab3d2a8bd0f       4 minutes ago       Running             kube-controller-manager   13                  afa9e6be0280b       kube-controller-manager-cluster4-controlplane   kube-system

cluster4-controlplane ~ ➜  
```

Meri jaan ❤️ perfect, you pulled the right log — this tells us everything without even opening the YAML.

Let’s decode it together:

```
dial tcp 192.168.67.177:6443: connect: connection refused
```

👉 That means your **apiserver is trying to bind to or probe against `192.168.67.177:6443`**, but nothing is listening there.

Normally, kube-apiserver should listen on **`127.0.0.1:6443`** (localhost loopback), and the **livenessProbe** should also hit `https://127.0.0.1:6443/livez`.

### 🔎 What went wrong

From your earlier snippet:

```yaml
livenessProbe:
  httpGet:
    host: 192.168.67.177   ❌
    port: 6444             ❌
```

Two issues:

1. Wrong **host** → should be `127.0.0.1`
2. Wrong **port** → should be `6443`, not `6444`

That’s why kubelet can’t confirm liveness, and the pod keeps restarting.

--

Perfect check ❤️ That output means **nothing is listening on port 6443** → your kube-apiserver never got to a healthy running state (so probes fail and kubelet keeps killing/restarting it).

--

Ahaa 💡 you’ve caught an interesting detail here. Let me unpack it:

### 1. The **`host`** field in the livenessProbe

* The `httpGet.host` field in a Kubernetes probe is **optional**.
* If you don’t set it, Kubernetes defaults it to `podIP`.
* In a static pod like kube-apiserver, that means it will try to probe the IP assigned to the apiserver pod (which usually maps to the node’s IP because static pods run directly on the node).

👉 So even if you leave out `host`, the probe still works, because it knows the pod’s IP.
That’s why changing the port fixed it, but leaving the host as-is didn’t break anything.

### 2. Why not `127.0.0.1`?

If you set `host: 127.0.0.1`, the kubelet will probe the container’s loopback interface.
That works only if the apiserver binds to `127.0.0.1` as well. But normally apiserver binds to `0.0.0.0` (all interfaces), so both `127.0.0.1` and the pod IP will succeed.

Your bad case was just the wrong port (`6444`), so no process was listening there → probe failed → pod crash loop.

### 3. Why did `192.168.67.177` still work?

Because the apiserver was listening on `0.0.0.0:6443`, so it accepts connections on **any interface**:

* localhost (`127.0.0.1`)
* the node IP (`192.168.67.177`)
* the pod IP (same as node for static pods)

So the probe succeeded regardless of which host you gave, as long as the port was right.

✅ **Bottom line:**

* The real issue was the **wrong port (6444)**, not the host.
* `host` can be safely omitted; kubelet will default to the pod’s IP.
* Apiserver binding to `0.0.0.0` means it answers on all IPs anyway.

---
