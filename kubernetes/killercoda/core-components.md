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
