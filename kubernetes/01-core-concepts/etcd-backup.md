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
controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd/backup/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kub
ernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "022c43b8ec0bf2ca17de9e5bfa14e46bdab45302ec5ae4557860a25b07af1401": OCI runtime exec failed: exec failed: unable to start container process: exec: "ETCDCTL_API=3": executable file not found in $PATH: unknown

controlplane ~ ✖ export ETCDCTL_API=3

controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- etcdctl snapshot save /var/lib/etcd/backup/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/et
cd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
Error: could not open /var/lib/etcd/backup/ibtisam.db.part (open /var/lib/etcd/backup/ibtisam.db.part: no such file or directory)
command terminated with exit code 5

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- mkdir -p /var/lib/etcd/backup/
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "c6ec84dace41d15508c7fba847ad7a1b563cb0fba9da4ed250c51e7c413070f9": OCI runtime exec failed: exec failed: unable to start container process: exec: "mkdir": executable file not found in $PATH: unknown

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- etcdctl snapshot save /var/lib/etcd/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/serve
r.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
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

controlplane ~ ➜  
```
