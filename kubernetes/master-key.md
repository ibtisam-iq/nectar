[**YAML**](https://github.com/ibtisam-iq/nectar/blob/main/yaml/README.md) & [KodeKloud YAML Free One Hour Practice Lab](https://kodekloud.com/pages/free-labs/kubernetes/yaml), [**Objects**](./01-core-concepts/objects.md)

**Static Pods:** `pod/etcd-ibtisam-iq, pod/kube-apiserver-ibtisam-iq, pod/kube-controller-manager-ibtisam-iq, pod/kube-scheduler-ibtisam-iq`

**Daemonsets (1/1):** `daemonset.apps/calico-node, daemonset.apps/kube-proxy`

**Deployments:** `deployment.apps/calico-kube-controllers (1/1), deployment.apps/coredns (2/2), deployment.apps/local-path-provisioner (1/1)`

`busybox` has a default entrypoint of `/bin/sh`, no `CMD` and a default command of `sh -c`.

Container runs: `<command or ENTRYPOINT> <args or CMD>`

```bash
    env:
    - name: PLAYER_INITIAL_LIVES
      valueFrom:
        configMapKeyRef:                # secretMapKeyRef
            name: game-demo           
            key: player_initial_lives

    envFrom:
    - configMapRef:                     # secretMapRef
        name: myconfigmap

    volumeMounts:
    - name: config-vol
      mountPath: "/config"
      readOnly: true

  volumes:
  - name: config-vol
    configMap:                              # secret
      name: my-config                       # secretName

      items:
      - key: app_mode
        path: mode.txt
```

```bash

spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual

  hostPath:
    path: "/mnt/data"
    type: DirectoryOrCreate

  awsElasticBlockStore:
    volumeID: vol-0123456789abcdef0
    fsType: ext4
    readOnly: true

  nfs:
    path: /exported/path
    server: nfs-server.ibtisam-iq.com
    readOnly: true

  csi:
    driver: ebs.csi.aws.com
    volumeHandle: vol-0abcd1234cdef5678
    fsType: ext4
    readOnly: true
```
