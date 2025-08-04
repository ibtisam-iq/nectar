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
> controlplane ~ ✖ etcdutl snapshot restore /opt/ibtisam.db --data-dir=/var/lib/etcd/
> Error: data-dir "/var/lib/etcd/" not empty or could not be read
