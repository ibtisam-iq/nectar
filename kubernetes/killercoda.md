```bash
set expandtab
set tabstop=2
set shiftwidth=2
```
---
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

#2 incorrect flag value:     # --etcd-servers=hhttps://127.0.0.1:2379
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

