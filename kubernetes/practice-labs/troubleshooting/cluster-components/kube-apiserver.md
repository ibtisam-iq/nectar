## Apiserver Crash 

## 1 Incorrect or unknown flag/args

```bash
controlplane:~$ k get po
The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?
watch crictl ps     #  kube-apiserver pod is not found

controlplane:~$ ls /var/log/pods/kube-system_kube-apiserver-controlplane_e0ee64f88fb19c12ee94f5b24507f060/kube-apiserver/6.log # the lowest
2025-08-23T08:51:03.639438796Z stderr F Error: unknown flag: --this-is-very-wrong

controlplane:~$ cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-ace5309febe6b93e42a1d04d055bc4025b85d8511ddcd1aa83a995129c3c
c03c.log   # see carefully, you will see > 1 log files # the lowest
2025-08-23T08:26:41.615226434Z stderr F Error: unknown flag: --this-is-very-wrong
```

```bash
cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-95d67ca47280ee0bd9599c6ba2a166fffd4e4d6138d8caaed8
2ec77c40bc8ef3.log 
2025-08-23T11:39:36.36137879Z stderr F Error: unknown flag: --authorization-modus
```

---

## 2 Incorrect flag value:    # --etcd-servers=hhttps://127.0.0.1:2379

```bash
controlplane:~$ k get po    # no result, stuck
watch crictl ps             #  kube-apiserver pod is not found

crictl ps -a                # get pod ID
controlplane:~$ crictl logs 60c420d4a22fe
W0823 09:18:03.588631       1 logging.go:55] [core] [Channel #1 SubChannel #3]grpc: addrConn.createTransport failed to connect to {Addr: "hhttps://127.0.0.1:2379", ServerName: "127.0.0.1:2379", }. Err: connection error: desc = "transport: Error while dialing: dial tcp: address hhttps://127.0.0.1:2379: too many colons in address"
F0823 09:18:07.593672       1 instance.go:226] Error creating leases: error creating storage factory: context deadline exceeded
```

---

## 3 Incorrect key name in the manifest:   #  apiVersio: v1

```bash
controlplane:~$ k get po
The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?

/var/log/pods # nothing
crictl logs # nothing

controlplane:~$ tail -f /var/log/syslog | grep apiserver
2025-08-23T09:39:22.105074+00:00 controlplane kubelet[27556]: E0823 09:39:22.104435   27556 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(Object 'apiVersion' is missing in '{\"apiVersio\":\"v1\",\"kind\"
journalctl | grep apiserver # same message like tail -f /var/log/syslog | grep apiserver
```

---

## 4 Wrong YAML in the manifest `*metadata;*`

```bash
controlplane:~$ cat /var/log/syslog | grep apiserver
2025-08-23T11:21:56.530696+00:00 controlplane kubelet[1504]: E0823 11:21:56.530513    1504 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(yaml: line 4: could not find expected ':'), please check config file" path="/etc/kubernetes/manifests/kube-apiserver.yaml"
```

---

## 5 Probe misconfiguration

when you run `kubectl get nodes` OR `kubectl get pod -A` threw :- `The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?`

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

## 6 Node status is `NotReady`

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
