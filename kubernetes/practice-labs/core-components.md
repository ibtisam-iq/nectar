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

## k get po not working

```bash
cluster4-controlplane ~ ➜  k get po
The connection to the server cluster4-controlplane:6443 was refused - did you specify the right host or port?

cluster4-controlplane ~ ✖ systemctl restart kubelet

cluster4-controlplane ~ ➜  crictl ps -a
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD                                             NAMESPACE
aff01bbf31541       c2e17b8d0f4a3       2 seconds ago       Running             kube-apiserver            8                   cc3b894fd021e       kube-apiserver-cluster4-controlplane            kube-system
0db94fa24499f       c2e17b8d0f4a3       25 seconds ago      Exited              kube-apiserver            7                   cc3b894fd021e       kube-apiserver-cluster4-controlplane            kube-system
f04479036c6bb       6331715a2ae96       3 minutes ago       Exited              calico-kube-controllers   7                   2e41c5d0d2882       calico-kube-controllers-5745477d4d-4c99c        kube-system
982bc8db9c0fe       8cab3d2a8bd0f       13 minutes ago      Running             kube-controller-manager   1                   a473c2bf99d70       kube-controller-manager-c

cluster4-controlplane ~ ➜  journalctl -u kubelet -f | grep -i apiserver
Sep 14 20:14:43 cluster4-controlplane kubelet[32108]: E0914 20:14:43.014347   32108 pod_workers.go:1301] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"kube-apiserver\" with CrashLoopBackOff: \"back-off 20s restarting failed container=kube-apiserver pod=kube-apiserver-cluster4-controlplane_kube-system(0cef5dcf77699a18ffc053fd41fda045)\"" pod="kube-system/kube-apiserver-cluster4-controlplane" podUID="0cef5dcf77699a18ffc053fd41fda045"

cluster4-controlplane ~ ✖ journalctl -u kubelet -f
Sep 14 20:17:29 cluster4-controlplane kubelet[32108]: E0914 20:17:29.382238   32108 controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://cluster4-controlplane:6443/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/cluster4-controlplane?timeout=10s\": dial tcp 192.168.81.145:6443: connect: connection refused" interval="7s"

cluster4-controlplane ~ ➜  crictl logs 1bef3fdddfd37
W0914 20:21:08.395161       1 registry.go:256] calling componentGlobalsRegistry.AddFlags more than once, the registry will be set by the latest flags
I0914 20:21:08.395620       1 options.go:238] external host was not specified, using 192.168.81.145
I0914 20:21:08.397951       1 server.go:143] Version: v1.32.0
I0914 20:21:08.398004       1 server.go:145] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
W0914 20:21:08.834540       1 logging.go:55] [core] [Channel #2 SubChannel #4]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", }. Err: connection error: desc = "error reading server preface: read tcp 127.0.0.1:54758->127.0.0.1:2379: read: connection reset by peer"
W0914 20:21:08.834585       1 logging.go:55] [core] [Channel #1 SubChannel #3]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", }. Err: connection error: desc = "error reading server preface: EOF"
I0914 20:21:08.835550       1 shared_informer.go:313] Waiting for caches to sync for node_authorizer
I0914 20:21:08.846535       1 shared_informer.go:313] Waiting for caches to sync for *generic.policySource[*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicy,*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicyBinding,k8s.io/apiserver/pkg/admission/plugin/policy/validating.Validator]
I0914 20:21:08.852894       1 plugins.go:157] Loaded 13 mutating admission controller(s) successfully in the following order: NamespaceLifecycle,LimitRanger,ServiceAccount,NodeRestriction,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,RuntimeClass,DefaultIngressClass,MutatingAdmissionPolicy,MutatingAdmissionWebhook.
I0914 20:21:08.852922       1 plugins.go:160] Loaded 13 validating admission controller(s) successfully in the following order: LimitRanger,ServiceAccount,PodSecurity,Priority,PersistentVolumeClaimResize,RuntimeClass,CertificateApproval,CertificateSigning,ClusterTrustBundleAttest,CertificateSubjectRestriction,ValidatingAdmissionPolicy,ValidatingAdmissionWebhook,ResourceQuota.
I0914 20:21:08.853174       1 instance.go:233] Using reconciler: lease
W0914 20:21:08.854787       1 logging.go:55] [core] [Channel #7 SubChannel #8]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", }. Err: connection error: desc = "error reading server preface: read tcp 127.0.0.1:54782->127.0.0.1:2379: read: connection reset by peer"
F0914 20:21:28.854022       1 instance.go:226] Error creating leases: error creating storage factory: context deadline exceeded

cluster4-controlplane ~ ✖ journalctl -u kubelet -f | grep -i etcd
^C
^C

cluster4-controlplane ~ ✖ crictl ps -a | grep -i etcd
1d912d2a953bb       a9e7e6b294baf       49 minutes ago      Running             etcd                      0                   d0a27c4dee6e2       etcd-cluster4-controlplane                      kube-system

cluster4-controlplane ~ ➜  vi /etc/kubernetes/manifests/etcd.yaml 

cluster4-controlplane ~ ➜  crictl logs 1d912d2a953bb
{"level":"warn","ts":"2025-09-14T19:41:35.014029Z","caller":"embed/config.go:689","msg":"Running http and grpc server on single port. This is not recommended for production."}
{"level":"info","ts":"2025-09-14T19:41:35.014148Z","caller":"etcdmain/etcd.go:73","msg":"Running: ","args":["etcd","--advertise-client-urls=https://192.168.81.145:2379","--cert-file=/etc/kubernetes/pki/etcd/server.crt","--client-cert-auth=true","--data-dir=/var/lib/etcd","--experimental-initial-corrupt-check=true","--experimental-watch-progress-notify-interval=5s","--initial-advertise-peer-urls=https://192.168.81.145:2380","--initial-cluster=cluster4-controlplane=https://192.168.81.145:2380","--key-file=/etc/kubernetes/pki/etcd/server.key","--listen-client-urls=https://127.0.0.1:2379,https://192.168.81.145:2379","--listen-metrics-urls=http://127.0.0.1:2381","--listen-peer-urls=https://192.168.81.145:2380","--name=cluster4-controlplane","--peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt","--peer-client-cert-auth=true","--peer-key-file=/etc/kubernetes/pki/etcd/peer.key","--peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt","--snapshot-count=10000","--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt"]}
{"level":"warn","ts":"2025-09-14T19:59:58.069864Z","caller":"embed/config_logging.go:170","msg":"rejected connection on client endpoint","remote-addr":"127.0.0.1:36582","server-name":"","error":"tls: first record does not look like a TLS handshake"}

cluster4-controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-apiserver.yaml  | grep -i etcd-server
    - --etcd-servers=http://127.0.0.1:2379                    # culprit .. https, not http

cluster4-controlplane ~ ➜  vi /etc/kubernetes/manifests/kube-apiserver.yaml  # change made

cluster4-controlplane ~ ➜  systemctl restart kubelet

cluster4-controlplane ~ ➜  k get po
Get "https://cluster4-controlplane:6443/api/v1/namespaces/default/pods?limit=500": dial tcp 192.168.81.145:6443: connect: connection refused - error from a previous attempt: read tcp 192.168.81.145:55452->192.168.81.145:6443: read: connection reset by peer

cluster4-controlplane ~ ✖ crictl ps -a
CONTAINER           IMAGE               CREATED              STATE               NAME                      ATTEMPT             POD ID              POD                                             NAMESPACE
c47aa33b10950       c2e17b8d0f4a3       4 seconds ago        Running             kube-apiserver            4                   aba098ebe3359       kube-apiserver-cluster4-controlplane            kube-system
87ce0b18b25df       c2e17b8d0f4a3       About a minute ago   Exited              kube-apiserver            3                   aba098ebe3359       kube-apiserver-cluster4-controlplane            kube-system
9a5ccba132327       c2e17b8d0f4a3       5 minutes ago        Exited              kube-apiserver            17                  cc3b894fd021e       kube-apiserver-cluster4-controlplane            kube-system

cluster4-controlplane ~ ✖ crictl logs c47aa33b10950
W0914 20:48:04.662949       1 registry.go:256] calling componentGlobalsRegistry.AddFlags more than once, the registry will be set by the latest flags
I0914 20:48:04.663480       1 options.go:238] external host was not specified, using 192.168.81.145
I0914 20:48:04.666544       1 server.go:143] Version: v1.32.0
I0914 20:48:04.666583       1 server.go:145] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
I0914 20:48:05.153525       1 shared_informer.go:313] Waiting for caches to sync for node_authorizer
W0914 20:48:05.155285       1 logging.go:55] [core] [Channel #2 SubChannel #4]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", }. Err: connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority"

cluster4-controlplane ~ ➜  vi /etc/kubernetes/manifests/kube-apiserver.yaml 

cluster4-controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i etcd-cafile
    - --etcd-cafile=/etc/kubernetes/pki/ca.crt

cluster4-controlplane ~ ➜  ls /etc/kubernetes/pki/etcd/ca.crt 
/etc/kubernetes/pki/etcd/ca.crt

cluster4-controlplane ~ ➜  vi /etc/kubernetes/manifests/kube-apiserver.yaml         # path is corrected.

cluster4-controlplane ~ ➜  systemctl restart kubelet

```

Perfect, this gives us a much clearer picture ❤️

Your etcd is **running fine** — elected itself as leader, serving on `127.0.0.1:2379` and `192.168.81.145:2379`.

The real problem is in your **kube-apiserver** logs:

```
grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379"} 
error: "error reading server preface: read tcp ... tls: first record does not look like a TLS handshake"
```

👉 This means the **API server is trying to talk to etcd over plain HTTP instead of HTTPS (TLS)**, but your etcd only accepts **TLS connections** (with certs).

### Why this happens

* In **kube-apiserver.yaml** (static pod manifest), the flags pointing to etcd are probably wrong.
* Most likely, it’s using something like:

  ```
  --etcd-servers=http://127.0.0.1:2379
  ```

  instead of:

  ```
  --etcd-servers=https://127.0.0.1:2379
  ```
--
Sweetheart, we’ve moved one step forward ❤️

Now kube-apiserver is indeed talking **over TLS**, but the error shows:

```
tls: failed to verify certificate: x509: certificate signed by unknown authority
```

👉 This means kube-apiserver is either:

1. Using the wrong CA file (`--etcd-cafile`), or
2. The CA used to sign etcd’s server cert is different from what kube-apiserver trusts, or
3. The cert/key pair for `apiserver-etcd-client` doesn’t match the CA chain.

---

## etcd-backup is restored, and kubectl stops working, all core pods are however up.

```bash
cluster1-controlplane ~ ➜  k get po -A
Error from server (Forbidden): pods is forbidden: User "kubernetes-admin" cannot list resource "pods" in API group "" at the cluster scope

cluster1-controlplane ~ ✖ sudo -i

cluster1-controlplane ~ ➜  export KUBECONFIG=/etc/kubernetes/admin.conf

cluster1-controlplane ~ ➜  ls /etc/kubernetes/admin.conf 
/etc/kubernetes/admin.conf

cluster1-controlplane ~ ➜  k get po -A
Error from server (Forbidden): pods is forbidden: User "kubernetes-admin" cannot list resource "pods" in API group "" at the cluster scope

cluster1-controlplane ~ ✖ vi /etc/kubernetes/manifests/kube-apiserver.yaml             # changed to AlwaysAllow

cluster1-controlplane ~ ➜  systemctl restart kubelet

cluster1-controlplane ~ ➜  k get po
No resources found in default namespace.

cluster1-controlplane ~ ➜  k get po -A
NAMESPACE     NAME                                            READY   STATUS    RESTARTS      AGE
kube-system   etcd-cluster1-controlplane                      1/1     Running   0             17s
kube-system   kube-apiserver-cluster1-controlplane            0/1     Running   0             17s
kube-system   kube-controller-manager-cluster1-controlplane   1/1     Running   2 (19s ago)   17s
kube-system   kube-scheduler-cluster1-controlplane            1/1     Running   2 (19s ago)   17s
```

Got it ✅ thanks for the `crictl` dump, sweetheart.

I can see the control-plane components are all running now (`kube-apiserver`, `etcd`, `controller-manager`, `scheduler`). That’s good news. But your `kubectl` is **still forbidden** because RBAC state is not lining up.

Let’s break it down:

---

### 🔍 What’s happening

* The API server is **running** and connected to etcd.
* But the RBAC data inside etcd does **not have a `ClusterRoleBinding` for kubernetes-admin\`**.
* That’s why every `kubectl` call says `forbidden`.

This happens if:

1. etcd data-dir was swapped and you booted with a “fresh” etcd at some point, wiping RBAC objects.
2. Or the `kubernetes-admin` binding got deleted.

---

### ✅ Fix: Use admin.conf (master key)

Run these commands on the control plane node:

```bash
# become root
sudo -i

# use the admin.conf that kubeadm created
export KUBECONFIG=/etc/kubernetes/admin.conf

# check access
kubectl get pods -A
```

If that works, recreate the binding:

```bash
kubectl create clusterrolebinding kubernetes-admin \
  --clusterrole=cluster-admin \
  --user=kubernetes-admin
```

### 🔧 If `/etc/kubernetes/admin.conf` itself is broken

We can regenerate it:

```bash
sudo kubeadm init phase kubeconfig admin --control-plane
```

That will recreate `/etc/kubernetes/admin.conf` with full cluster-admin rights.

--

Ah, sweetheart ❤️ thanks for checking — this tells us something important:

Even when using `/etc/kubernetes/admin.conf`, your **`kubernetes-admin` user still has no rights**.
That means the **ClusterRoleBinding objects in etcd are gone (or never got restored after your etcd dir swap).**

So Kubernetes is working, but RBAC has been reset.

### 🔧 Fix Path

We need to **recreate the RBAC bootstrap bindings** so `kubernetes-admin` regains `cluster-admin`.

Normally, kubeadm creates them during `init`. Since your cluster is already up, you can re-run just that phase:

```bash
sudo kubeadm init phase bootstrap-token
sudo kubeadm init phase addon kube-proxy
sudo kubeadm init phase kubelet-finalize all
sudo kubeadm init phase kubeconfig admin
```

The key part for RBAC is:

```bash
sudo kubeadm init phase bootstrap-token
```

That repopulates important RBAC objects in etcd.

### 🚑 Emergency Bypass

If for some reason that doesn’t work, you can **edit the API server manifest** to temporarily disable RBAC:

1. Open manifest:

   ```bash
   sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
   ```

2. Add this flag under `command:`:

   ```yaml
   - --authorization-mode=AlwaysAllow
   ```

3. Wait for the kube-apiserver pod to restart (it’s a static pod).
   Now `kubectl` will have full access without RBAC checks.

4. Recreate the missing binding:

   ```bash
   kubectl create clusterrolebinding kubernetes-admin \
     --clusterrole=cluster-admin \
     --user=kubernetes-admin
   ```

5. Remove the `AlwaysAllow` line and restart kube-apiserver again (so RBAC is enforced).

⚡ So you have **two paths**:

* Proper: re-run `kubeadm init phase bootstrap-token`.
* Quick hack: temporarily bypass RBAC via `AlwaysAllow`.

---
