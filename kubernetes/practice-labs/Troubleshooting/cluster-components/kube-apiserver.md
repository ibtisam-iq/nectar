# `kube-apiserver` Troubeshooting

## Wrong Manifest

- ONLY one container, also exited and no increment in Attempt count found
- `journalctl -u kubelet -f | grep apiserver`        # takes some time
- `journalctl | grep apiserver` 

### 1 Incorrect key name in the manifest:   #  apiVersio: v1

`crictl ps -a kube-apiserver` you will not get any newly created, but there is only one, and exited now... on checking logs, you just find shutting ... information.

```bash
controlplane:~$ k get po
The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?

controlplane ~ ➜  crictl ps -a | grep -i kube-apiserver            # only one, Attempt count is not increasing, and exited now.
4e12d9ef55515       90550c43ad2bc       34 minutes ago      Exited              kube-apiserver            0                   

controlplane ~ ✖ crictl logs 4e12d9ef55515
nothing, just graceful shutting...

/var/log/pods # nothing
crictl logs # nothing

controlplane:~$ tail -f /var/log/syslog | grep apiserver
2025-08-23T09:39:22.105074+00:00 controlplane kubelet[27556]: E0823 09:39:22.104435   27556 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(Object 'apiVersion' is missing in '{\"apiVersio\":\"v1\",\"kind\"

controlplane ~ ➜  tail -f /var/log/syslog | grep apiserver
tail: cannot open '/var/log/syslog' for reading: No such file or directory
tail: no files remaining

controlplane ~ ✖ journalctl | grep apiserver    # apiersion
Oct 04 09:12:20 controlplane kubelet[18566]: E1004 09:12:20.237127   18566 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(Object 'apiVersion' is missing in '{\"apiersion\":\"v1\",\"kind\":\"Pod\",\"metadata\"

controlplane ~ ➜  journalctl -u kubelet -f | grep apiserver         # takes some time
Oct 04 09:20:00 controlplane kubelet[18566]: E1004 09:20:00.237825   18566 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(Object 'apiVersion' is missing in '{\"apiersion\":\"v1\",\"kind\":\"Pod\",\"metadata\"

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
50edcbbb78f04       90550c43ad2bc       About a minute ago   Running             kube-apiserver            1                   
4e12d9ef55515       90550c43ad2bc       42 minutes ago       Exited              kube-apiserver            0                  
```

### 2 Wrong YAML in the manifest `*metadata;*`

```bash
controlplane:~$ cat /var/log/syslog | grep apiserver
2025-08-23T11:21:56.530696+00:00 controlplane kubelet[1504]: E0823 11:21:56.530513    1504 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(yaml: line 4: could not find expected ':'), please check config file" path="/etc/kubernetes/manifests/kube-apiserver.yaml"

---

controlplane ~ ➜  k get po
The connection to the server controlplane:6443 was refused - did you specify the right host or port?

controlplane ~ ✖ tail -f /var/log/syslog | grep apiserver
tail: cannot open '/var/log/syslog' for reading: No such file or directory
tail: no files remaining

controlplane ~ ✖ crictl ps -a | grep kube-apiserver        # it takes some time to exit.
50edcbbb78f04       90550c43ad2bc       5 minutes ago       Running             kube-apiserver            1                   
4e12d9ef55515       90550c43ad2bc       46 minutes ago      Exited              kube-apiserver            0                   

controlplane ~ ➜  crictl ps -a | grep kube-apiserver        # ONLY ONE, no increment in attempt is found
50edcbbb78f04       90550c43ad2bc       6 minutes ago        Exited              kube-apiserver            1                   

controlplane ~ ➜  crictl ps -a | grep kube-apiserver        # NO newly created, no increment in attempt is found
50edcbbb78f04       90550c43ad2bc       7 minutes ago        Exited              kube-apiserver            1                   

controlplane ~ ➜  journalctl -u kubelet -f | grep apiserver     # metadata;
Oct 04 09:37:32 controlplane kubelet[30820]: E1004 09:37:32.159027   30820 file.go:187] "Could not process manifest file" err="/etc/kubernetes/manifests/kube-apiserver.yaml: couldn't parse as pod(yaml: line 4: could not find expected ':'), please check config file" path="/etc/kubernetes/manifests/kube-apiserver.yaml"
^C
```

---

## Wrong Flag key

- Only ONE container, exited, but increment in Attempt count is found and new container id assigned each time
- `crictl ps -a | grep kube-apiserver`
- `crictl logs <recent-exited-container-id>`

### 1 Incorrect or unknown flag/args

```bash
controlplane:~$ k get po
The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?

watch crictl ps                                          #  kube-apiserver pod is not found

controlplane ~ ➜  crictl ps -a | grep kube-apiserver    # increment in Attempt count is found and new container id assigned each time
1cd66227e2094       90550c43ad2bc       8 seconds ago        Exited              kube-apiserver            3                   

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
5cfe56f342989       90550c43ad2bc       10 seconds ago       Exited              kube-apiserver            4                  

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
9d13d0c4e8eb4       90550c43ad2bc       35 seconds ago      Exited              kube-apiserver             5                   

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
48ff6336dcb99       90550c43ad2bc       3 minutes ago       Exited              kube-apiserver             6                   

controlplane ~ ➜  

controlplane:~$ ls /var/log/pods/kube-system_kube-apiserver-controlplane_e0ee64f88fb19c12ee94f5b24507f060/kube-apiserver/6.log # the lowest
2025-08-23T08:51:03.639438796Z stderr F Error: unknown flag: --this-is-very-wrong

controlplane:~$ cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-ace5309febe6b93e42a1d04d055bc4025b85d8511ddcd1aa83a995129c3c
c03c.log   # see carefully, you will see > 1 log files # the lowest
2025-08-23T08:26:41.615226434Z stderr F Error: unknown flag: --this-is-very-wrong

controlplane ~ ➜  crictl logs ca815ceaedaa5   # make sure you pick the recent exited ID, otherwise it says  
Error: unknown flag: --this-is-very-wrong

controlplane ~ ➜  crictl logs 78bf16ea3c819
Error: unknown flag: --client-ca-fil

cat /var/log/containers/kube-apiserver-controlplane_kube-system_kube-apiserver-95d67ca47280ee0bd9599c6ba2a166fffd4e4d6138d8caaed8
2ec77c40bc8ef3.log 
2025-08-23T11:39:36.36137879Z stderr F Error: unknown flag: --authorization-modus
```

---

## Incorrect Flag Value

- Only ONE container, exited, but increment in Attempt count is found and new container id assigned each time
- `crictl ps -a | grep kube-apiserver`
- `crictl logs <recent-exited-container-id>`
- 

### 1 `--etcd-servers=this-is-very-wrong`

```bash
controlplane:~$ crictl ps -a | grep -i api
0f807c1fd6be8       ee794efa53d85       36 seconds ago      Exited              kube-apiserver            6                   
966fa119db367       ee794efa53d85       15 minutes ago      Exited              kube-apiserver            1

controlplane:~$ crictl logs 0f807c1fd6be8
I1022 07:42:23.333363       1 options.go:249] external host was not specified, using 172.30.1.2
I1022 07:42:23.335597       1 server.go:147] Version: v1.33.2
I1022 07:42:23.335774       1 server.go:149] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
I1022 07:42:23.920004       1 shared_informer.go:350] "Waiting for caches to sync" controller="node_authorizer"
I1022 07:42:23.920191       1 shared_informer.go:350] "Waiting for caches to sync" controller="*generic.policySource[*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicy,*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicyBinding,k8s.io/apiserver/pkg/admission/plugin/policy/validating.Validator]"
W1022 07:42:23.920610       1 logging.go:55] [core] [Channel #1 SubChannel #3]grpc: addrConn.createTransport failed to connect to {Addr: "this-is-very-wrong", ServerName: "this-is-very-wrong", }. Err: connection error: desc = "transport: Error while dialing: dial tcp: address this-is-very-wrong: missing port in address"
```

### 2 `--etcd-servers=hhttps://127.0.0.1:2379`

```bash
controlplane ~ ➜  k get po
Unable to connect to the server: net/http: TLS handshake timeout

controlplane ~ ✖ k get po
Get "https://controlplane:6443/api/v1/namespaces/default/pods?limit=500": dial tcp 192.168.122.59:6443: connect: connection refused - error from a previous attempt: read tcp 192.168.122.59:52870->192.168.122.59:6443: read: connection reset by peer

controlplane ~ ✖ k get po
The connection to the server controlplane:6443 was refused - did you specify the right host or port?

controlplane ~ ✖ crictl ps -a | grep kube-apiserver
92cc100b3538e       90550c43ad2bc       7 seconds ago        Running             kube-apiserver            2                  
dc9c3995e65ea       90550c43ad2bc       50 seconds ago       Exited              kube-apiserver            1                   
9c5efe33fc25b       90550c43ad2bc       5 minutes ago        Exited              kube-apiserver            1                  

controlplane ~ ➜  k get po
Get "https://controlplane:6443/api/v1/namespaces/default/pods?limit=500": dial tcp 192.168.122.59:6443: connect: connection refused - error from a previous attempt: read tcp 192.168.122.59:51308->192.168.122.59:6443: read: connection reset by peer

controlplane ~ ✖ k get po
The connection to the server controlplane:6443 was refused - did you specify the right host or port?

controlplane ~ ✖ crictl ps -a | grep kube-apiserver
92cc100b3538e       90550c43ad2bc       44 seconds ago       Exited              kube-apiserver            2                   d2c50cd1c8a8f       kube-apiserver-controlplane                kube-system
9c5efe33fc25b       90550c43ad2bc       5 minutes ago        Exited              kube-apiserver            1                   330e29cd1ad2b       kube-apiserver-controlplane                kube-system

controlplane ~ ➜  crictl logs 92cc100b3538e
E1004 12:54:14.732200   44290 log.go:32] "ContainerStatus from runtime service failed" err="rpc error: code = NotFound desc = an error occurred when try to find container \"92cc100b3538e\": not found" containerID="92cc100b3538e"
FATA[0000] rpc error: code = NotFound desc = an error occurred when try to find container "92cc100b3538e": not found 

controlplane ~ ✖ crictl ps -a | grep kube-apiserver
92d0aa46a5c56       90550c43ad2bc       36 seconds ago      Exited              kube-apiserver            3                   d2c50cd1c8a8f       kube-apiserver-controlplane                kube-system
9c5efe33fc25b       90550c43ad2bc       6 minutes ago       Exited              kube-apiserver            1                   330e29cd1ad2b       kube-apiserver-controlplane                kube-system

controlplane ~ ➜  crictl logs 92d0aa46a5c56
I1004 12:53:48.214726       1 options.go:263] external host was not specified, using 192.168.122.59
I1004 12:53:48.217455       1 server.go:150] Version: v1.34.0
I1004 12:53:48.217484       1 server.go:152] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""

W1004 12:53:48.812197       1 logging.go:55] [core] [Channel #2 SubChannel #3]grpc: addrConn.createTransport failed to connect to {Addr: "hhttps://127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: Error while dialing: dial tcp: address hhttps://127.0.0.1:2379: too many colons in address"

I1004 12:53:48.816504       1 shared_informer.go:349] "Waiting for caches to sync" controller="node_authorizer"
I1004 12:53:48.821808       1 shared_informer.go:349] "Waiting for caches to sync" controller="*generic.policySource[*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicy,*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicyBinding,k8s.io/apiserver/pkg/admission/plugin/policy/validating.Validator]"
I1004 12:53:48.827938       1 plugins.go:157] Loaded 14 mutating admission controller(s) successfully in the following order: NamespaceLifecycle,LimitRanger,ServiceAccount,NodeRestriction,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,RuntimeClass,DefaultIngressClass,PodTopologyLabels,MutatingAdmissionPolicy,MutatingAdmissionWebhook.
I1004 12:53:48.827955       1 plugins.go:160] Loaded 13 validating admission controller(s) successfully in the following order: LimitRanger,ServiceAccount,PodSecurity,Priority,PersistentVolumeClaimResize,RuntimeClass,CertificateApproval,CertificateSigning,ClusterTrustBundleAttest,CertificateSubjectRestriction,ValidatingAdmissionPolicy,ValidatingAdmissionWebhook,ResourceQuota.
I1004 12:53:48.828121       1 instance.go:239] Using reconciler: lease

W1004 12:54:06.097526       1 logging.go:55] [core] [Channel #1 SubChannel #6]grpc: addrConn.createTransport failed to connect to {Addr: "hhttps://127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: Error while dialing: dial tcp: address hhttps://127.0.0.1:2379: too many colons in address"
F1004 12:54:08.829270       1 instance.go:232] Error creating leases: error creating storage factory: context deadline exceeded

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
3a784eb4e3160       90550c43ad2bc       2 seconds ago        Running             kube-apiserver            5                   
bddf1716825c5       90550c43ad2bc       About a minute ago   Exited              kube-apiserver            4                   
9c5efe33fc25b       90550c43ad2bc       8 minutes ago        Exited              kube-apiserver            1                   
```

### 3 `--etcd-servers=http://127.0.0.1:2379`

```bash
controlplane ~ ➜  k get po                                   # command run on the sopt, left the clue
Unable to connect to the server: net/http: TLS handshake timeout     

controlplane ~ ✖ k get po                                     # command run later, clue is discharged now
The connection to the server controlplane:6443 was refused - did you specify the right host or port?

controlplane ~ ✖ crictl ps -a | grep kube-apiserver            # increment in Attempt count is found and new container id assigned each time.
875e3d275cbbf       90550c43ad2bc       44 seconds ago      Exited              kube-apiserver            8                   
a70fd3b479f3a       90550c43ad2bc       44 minutes ago      Exited              kube-apiserver            0                   

controlplane ~ ➜  journalctl -f | grep kube-apiserver          # no clue
Oct 04 12:32:01 controlplane kubelet[26874]: E1004 12:32:01.825021   26874 pod_workers.go:1324] "Error syncing pod, skipping" err="failed to \"StartContainer\" for \"kube-apiserver\" with CrashLoopBackOff: \"back-off 5m0s restarting failed container=kube-apiserver pod=kube-apiserver-controlplane_kube-system(d9039397fbadad7ce61c6b358522651b)\"" pod="kube-system/kube-apiserver-controlplane" podUID="d9039397fbadad7ce61c6b358522651b"
^C

controlplane ~ ✖ ls /var/log/                    # no clue
calico  containers  journal  pods

controlplane ~ ➜  crictl ps -a | grep kube-apiserver 
875e3d275cbbf       90550c43ad2bc       3 minutes ago       Exited              kube-apiserver            8                   
a70fd3b479f3a       90550c43ad2bc       47 minutes ago      Exited              kube-apiserver            0                   

controlplane ~ ➜  crictl logs 875e3d275cbbf         # got the clue
I1004 12:30:06.216174       1 options.go:263] external host was not specified, using 192.168.122.59
I1004 12:30:06.218464       1 server.go:150] Version: v1.34.0
I1004 12:30:06.218486       1 server.go:152] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
W1004 12:30:07.227347       1 logging.go:55] [core] [Channel #2 SubChannel #3]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: Error while dialing: dial tcp 127.0.0.1:2379: operation was canceled"
W1004 12:30:07.227718       1 logging.go:55] [core] [Channel #2 SubChannel #5]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "error reading server preface: read tcp 127.0.0.1:34990->127.0.0.1:2379: read: connection reset by peer"
I1004 12:30:07.229011       1 shared_informer.go:349] "Waiting for caches to sync" controller="node_authorizer"
I1004 12:30:07.243541       1 shared_informer.go:349] "Waiting for caches to sync" controller="*generic.policySource[*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicy,*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicyBinding,k8s.io/apiserver/pkg/admission/plugin/policy/validating.Validator]"
I1004 12:30:07.309779       1 plugins.go:157] Loaded 14 mutating admission controller(s) successfully in the following order: NamespaceLifecycle,LimitRanger,ServiceAccount,NodeRestriction,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,RuntimeClass,DefaultIngressClass,PodTopologyLabels,MutatingAdmissionPolicy,MutatingAdmissionWebhook.
I1004 12:30:07.309811       1 plugins.go:160] Loaded 13 validating admission controller(s) successfully in the following order: LimitRanger,ServiceAccount,PodSecurity,Priority,PersistentVolumeClaimResize,RuntimeClass,CertificateApproval,CertificateSigning,ClusterTrustBundleAttest,CertificateSubjectRestriction,ValidatingAdmissionPolicy,ValidatingAdmissionWebhook,ResourceQuota.
I1004 12:30:07.310094       1 instance.go:239] Using reconciler: lease
W1004 12:30:24.797484       1 logging.go:55] [core] [Channel #10 SubChannel #12]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "error reading server preface: read tcp 127.0.0.1:42360->127.0.0.1:2379: read: connection reset by peer"
F1004 12:30:27.311302       1 instance.go:232] Error creating leases: error creating storage factory: context deadline exceeded

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
9c5efe33fc25b       90550c43ad2bc       21 seconds ago      Running             kube-apiserver            1                   
a70fd3b479f3a       90550c43ad2bc       About an hour ago   Exited              kube-apiserver            0                   
```

### 4. `--etcd-cafile=/etc/kubernetes/pki/ca.crt`


```bash
controlplane ~ ➜  k get po
Unable to connect to the server: net/http: TLS handshake timeout

controlplane ~ ✖ k get po
The connection to the server controlplane:6443 was refused - did you specify the right host or port?

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
db279e0cd1629       90550c43ad2bc       5 seconds ago       Running             kube-apiserver            2                   b4cccabf494ad       kube-apiserver-controlplane                kube-system
fb9993d37b709       90550c43ad2bc       47 seconds ago      Exited              kube-apiserver            1                   b4cccabf494ad       kube-apiserver-controlplane                kube-system
6bc780d60126e       90550c43ad2bc       6 minutes ago       Exited              kube-apiserver            9                   d2c50cd1c8a8f       kube-apiserver-controlplane                kube-system
9c5efe33fc25b       90550c43ad2bc       34 minutes ago      Exited              kube-apiserver            1                   330e29cd1ad2b       kube-apiserver-controlplane                kube-system

controlplane ~ ➜  crictl logs db279e0cd1629
I1004 13:22:28.139880       1 options.go:263] external host was not specified, using 192.168.122.59
I1004 13:22:28.142169       1 server.go:150] Version: v1.34.0
I1004 13:22:28.142194       1 server.go:152] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
W1004 13:22:28.815384       1 logging.go:55] [core] [Channel #1 SubChannel #3]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: Error while dialing: dial tcp 127.0.0.1:2379: operation was canceled"
W1004 13:22:28.815474       1 logging.go:55] [core] [Channel #2 SubChannel #4]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: Error while dialing: dial tcp 127.0.0.1:2379: operation was canceled"
I1004 13:22:28.816885       1 shared_informer.go:349] "Waiting for caches to sync" controller="node_authorizer"
W1004 13:22:28.818377       1 logging.go:55] [core] [Channel #1 SubChannel #6]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority"
I1004 13:22:28.824842       1 shared_informer.go:349] "Waiting for caches to sync" controller="*generic.policySource[*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicy,*k8s.io/api/admissionregistration/v1.ValidatingAdmissionPolicyBinding,k8s.io/apiserver/pkg/admission/plugin/policy/validating.Validator]"
I1004 13:22:28.830353       1 plugins.go:157] Loaded 14 mutating admission controller(s) successfully in the following order: NamespaceLifecycle,LimitRanger,ServiceAccount,NodeRestriction,TaintNodesByCondition,Priority,DefaultTolerationSeconds,DefaultStorageClass,StorageObjectInUseProtection,RuntimeClass,DefaultIngressClass,PodTopologyLabels,MutatingAdmissionPolicy,MutatingAdmissionWebhook.
I1004 13:22:28.830370       1 plugins.go:160] Loaded 13 validating admission controller(s) successfully in the following order: LimitRanger,ServiceAccount,PodSecurity,Priority,PersistentVolumeClaimResize,RuntimeClass,CertificateApproval,CertificateSigning,ClusterTrustBundleAttest,CertificateSubjectRestriction,ValidatingAdmissionPolicy,ValidatingAdmissionWebhook,ResourceQuota.
I1004 13:22:28.830528       1 instance.go:239] Using reconciler: lease
W1004 13:22:28.831306       1 logging.go:55] [core] [Channel #7 SubChannel #8]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: Error while dialing: dial tcp 127.0.0.1:2379: operation was canceled"

W1004 13:22:44.750990       1 logging.go:55] [core] [Channel #2 SubChannel #5]grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379", ServerName: "127.0.0.1:2379", BalancerAttributes: {"<%!p(pickfirstleaf.managedByPickfirstKeyType={})>": "<%!p(bool=true)>" }}. Err: connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority"
F1004 13:22:48.831756       1 instance.go:232] Error creating leases: error creating storage factory: context deadline exceeded

controlplane ~ ➜  journalctl -f | grep kube-apiserver # no clue

```

#### 🔎 What’s happening?

* The API server is trying to connect to **etcd** on `127.0.0.1:2379`.
* Every attempt fails (`connection reset by peer`, `EOF`, `context deadline exceeded`).
* At the end, it **crashes** with:

  ```
  Error creating leases: error creating storage factory: context deadline exceeded
  ```
* This means: **the API server cannot talk to etcd**, so it can’t store cluster state → it dies.

#### 🚩 Key log hints

* `grpc: addrConn.createTransport failed to connect to 127.0.0.1:2379` → API server is trying to connect to etcd.
* `connection reset by peer / EOF` → etcd is either **down**, **crashing**, or **not listening** on port `2379`.

#### 🛠 How to troubleshoot (CKA-style checklist)

1. **Check etcd pod** (usually a static pod under `/etc/kubernetes/manifests/`):

   ```bash
   crictl ps | grep etcd
   crictl logs <etcd-container-id>
   ```

   → If etcd isn’t running, fix its manifest.

2. **Check if etcd is listening on 2379:**

   ```bash
   netstat -plnt | grep 2379
   ```

   → If nothing is listening, etcd failed.

3. **Look at etcd logs:**

   ```bash
   crictl logs <etcd-container-id>
   ```

   → Errors like “certificate invalid” or “data dir missing” will show up.

4. **Verify certificates** (common exam issue):

   * API server uses `--etcd-certfile`, `--etcd-keyfile`, `--etcd-cafile`.
   * Paths are in `/etc/kubernetes/manifests/kube-apiserver.yaml`.
   * If these files are wrong, expired, or missing, API server → etcd comms fail.

5. **Check `/var/lib/etcd`** (default etcd data dir):

   ```bash
   ls -l /var/lib/etcd
   ```

   → If empty or corrupted → etcd won’t start.

✅ **Rule to remember for exam**:
If `kube-apiserver` fails with `127.0.0.1:2379` errors → **always check etcd first**. The API server **depends on etcd**. Without etcd, the API server can’t store/retrieve cluster state → it will crash.

---

## Probe Misconfiguration

- `k get po` shows pod is running, but not ready and restating...
- Restarting means `crictl ps -a | grep kube-apiserver` shows one pod at a time, which is running; however, multiple containers are created, and exited.

## 1 Probe misconfiguration

when you run `kubectl get nodes` OR `kubectl get pod -A` threw :- `The connection to the server 172.30.1.2:6443 was refused - did you specify the right host or port?`

need to wait for few seconds to make above command work again but above error will come again after few second

```bash

controlplane ~ ➜  k get po -n kube-system kube-apiserver-controlplane 
NAME                          READY   STATUS    RESTARTS        AGE
kube-apiserver-controlplane   0/1     Running   2 (3m27s ago)   12m

controlplane:~$ k describe po -n kube-system kube-apiserver-controlplane 

  Warning  Unhealthy       117s (x77 over 17m)  kubelet  Startup probe failed: Get "https://172.30.1.2:6433/livez": dial tcp 172.30.1.2:6433: connect: connection refused
  Normal   Killing         37s (x3 over 13m)    kubelet  Container kube-apiserver failed startup probe, will be restarted

controlplane ~ ➜  crictl ps -a | grep kube-apiserver     # no probelm is found here, yet because it takes 4 min
648ebd77be54f       90550c43ad2bc       2 minutes ago       Running             kube-apiserver            0                   

controlplane ~ ➜  k get po
No resources found in default namespace.

# After passing 4 min

controlplane ~ ➜  crictl ps -a | grep kube-apiserver  
56065aa8f76e4       90550c43ad2bc       29 seconds ago      Running             kube-apiserver            1                   
648ebd77be54f       90550c43ad2bc       5 minutes ago       Exited              kube-apiserver            0                   

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
38e4a086a20a0       90550c43ad2bc       45 seconds ago      Running             kube-apiserver            2                   
56065aa8f76e4       90550c43ad2bc       5 minutes ago       Exited              kube-apiserver            1

controlplane ~ ➜  crictl ps -a | grep kube-apiserver
0873450d71969       90550c43ad2bc       30 seconds ago      Running             kube-apiserver            3                   
38e4a086a20a0       90550c43ad2bc       5 minutes ago       Exited              kube-apiserver            2                   

# The liveness, readiness, and startup probes are incorrectly configured to use port 6433 instead of the actual API server port 6443.
controlplane:~$ vi /etc/kubernetes/manifests/kube-apiserver.yaml     
controlplane:~$ systemctl restart kubelet

/var/logs/pods and /var/logs/container        # no clue found
```

---

## Node status is `NotReady`

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
