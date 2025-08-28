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
