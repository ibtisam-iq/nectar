## `etcdctl` and `etcdutl` binaries are installed

```bash
# save the backup as /opt/ibtisam.db
export ETCDCTL_API=3
etcdctl snapshot save /opt/ibtisam.db
    --endpoints 127.0.0.1:2379
    --cert=/etc/kubernetes/pki/etcd/server.crt
    --key=/etc/kubernetes/pki/etcd/server.key
    --cacert=/etc/kubernetes/pki/etcd/ca.crt

# restore
etcdutl snapshot restore /opt/ibtisam.db --data-dir /var/lib/etcd/backup

# Now, edit `--data-dir` location (mandatory) and Volume Mounts (if required) in `/etc/kubernetes/manifests/etcd.yaml`.
systemctl restart kubelet
watch crictl ps
# it can take a few mintues.
```
> **Note:**
> 
> controlplane ~ ✖ etcdutl snapshot restore /opt/ibtisam.db --data-dir=/var/lib/etcd/
> 
> Error: data-dir "/var/lib/etcd/" not empty or could not be read

---

## `etcdctl` and `etcdutl` binaries are not installed

```bash
# save the backup as /opt/ibtisam.db
controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd/backup/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
error: exec: "ETCDCTL_API=3": executable file not found in $PATH: unknown

controlplane ~ ✖ export ETCDCTL_API=3

controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- etcdctl snapshot save /var/lib/etcd/backup/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
Error: could not open /var/lib/etcd/backup/ibtisam.db.part (open /var/lib/etcd/backup/ibtisam.db.part: no such file or directory)
command terminated with exit code 5

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- mkdir -p /var/lib/etcd/backup/
error: exec: "mkdir": executable file not found in $PATH: unknown

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- etcdctl snapshot save /var/lib/etcd/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
{"level":"info","ts":"2025-08-04T08:15:23.920801Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/var/lib/etcd/ibtisam.db.part"}
{"level":"info","ts":"2025-08-04T08:15:23.928325Z","logger":"client","caller":"v3@v3.5.21/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2025-08-04T08:15:23.928373Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"127.0.0.1:2379"}
{"level":"info","ts":"2025-08-04T08:15:24.120010Z","logger":"client","caller":"v3@v3.5.21/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2025-08-04T08:15:24.120097Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"127.0.0.1:2379","size":"4.2 MB","took":"now"}
{"level":"info","ts":"2025-08-04T08:15:24.120165Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/var/lib/etcd/ibtisam.db"}
Snapshot saved at /var/lib/etcd/ibtisam.db

controlplane ~ ➜  ls -l /var/lib/etcd/
total 4128
-rw------- 1 root root 4218912 Aug  4 08:15 ibtisam.db
drwx------ 4 root root    4096 Aug  4 06:17 member

controlplane ~ ➜  cp /var/lib/etcd/ibtisam.db /opt/ibtisam.db

controlplane ~ ➜  ls -l /opt/ibtisam.db 
-rw------- 1 root root 4218912 Aug  4 08:17 /opt/ibtisam.db

# restore
controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- etcdutl snapshot restore /var/lib/etcd/ibtisam.db --data-dir /var/lib/etcd/backup
error: exec: "etcdutl": executable file not found in $PATH: unknown

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- etcdctl snapshot restore /var/lib/etcd/ibtisam.db --data-dir /var/lib/etcd/backup
Deprecated: Use `etcdutl snapshot restore` instead.

2025-08-04T08:26:37Z    info    snapshot/v3_snapshot.go:265     restoring snapshot      {"path": "/var/lib/etcd/ibtisam.db", "wal-dir": "/var/lib/etcd/backup/member/wal", "data-dir": "/var/lib/etcd/backup", "snap-dir": "/var/lib/etcd/backup/member/snap", "initial-memory-map-size": 0}
2025-08-04T08:26:37Z    info    membership/store.go:138 Trimming membership information from the backend...
2025-08-04T08:26:37Z    info    membership/cluster.go:421       added member    {"cluster-id": "cdf818194e3a8c32", "local-member-id": "0", "added-peer-id": "8e9e05c52164694d", "added-peer-peer-urls": ["http://localhost:2380"], "added-peer-is-learner": false}
2025-08-04T08:26:37Z    info    snapshot/v3_snapshot.go:293     restored snapshot       {"path": "/var/lib/etcd/ibtisam.db", "wal-dir": "/var/lib/etcd/backup/member/wal", "data-dir": "/var/lib/etcd/backup", "snap-dir": "/var/lib/etcd/backup/member/snap", "initial-memory-map-size": 0} 



Every 2.0s: crictl ps                                                                                                                controlplane: Mon Aug  4 08:42:45 2025

CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD
                  NAMESPACE
9dc476ef26bba       499038711c081       42 seconds ago      Running             etcd                      0                   faa2552bcf491       etcd-controlplane
                  kube-system
6518ecab33fa5       8d72586a76469       43 seconds ago      Running             kube-scheduler            2                   f696e6c7eff61       kube-scheduler-controlpla
ne                kube-system
b62ea4b95d1b0       1d579cb6d6967       2 minutes ago       Running             kube-controller-manager   2                   2786dd75a9711       kube-controller-manager-c
ontrolplane       kube-system
2aacb9fa0e4f0       6331715a2ae96       2 hours ago         Running             calico-kube-controllers   0                   857e400da0314       calico-kube-controllers-5
745477d4d-cvh4q   kube-system
11cf37d306af6       ead0a4a53df89       2 hours ago         Running             coredns                   0                   15fc43ad65062       coredns-7484cd47db-dpdtg
                  kube-system
bb1da48d9e35f       ead0a4a53df89       2 hours ago         Running             coredns                   0                   066b0d2818b2c       coredns-7484cd47db-pwjqg
                  kube-system
d8be9b6e3e150       c9fe3bce8a6d8       2 hours ago         Running             kube-flannel              0                   b633c57f49b33       canal-bn9v4
                  kube-system
ebf595f67642d       feb26d4585d68       2 hours ago         Running             calico-node               0                   b633c57f49b33       canal-bn9v4
                  kube-system
cc9ddc27d1910       f1184a0bd7fe5       2 hours ago         Running             kube-proxy                0                   79a58dea2612c       kube-proxy-7wb5z
                  kube-system
9efa8a481d67d       6ba9545b2183e       2 hours ago         Running             kube-apiserver            0                   f9cde1f1f1329       kube-apiserver-controlpla
ne                kube-system

```
