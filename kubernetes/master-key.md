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
apiVersion: v1
kind: PersistentVolume
metadata:
  name: foo-pv
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual

  claimRef:             # Reserves foo-pv for foo-pvc, preventing other PVCs from binding.
    name: foo-pvc
    namespace: foo

  hostPath:
    path: "/mnt/data"
    type: DirectoryOrCreate

  hostPath:
    path: /dev/nvme0n1     # ✅ Use this raw block device
    type: BlockDevice      # ✅ Must be BlockDevice

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
    volumeAttributes:
          foo: bar
```

```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
  - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 8Gi
  storageClassName: slow
  # No storageClassName; Triggers dynamic provisioning and uses default (if any available, else remains unbound)
  # storageClassName: "" Opt-out of default/dynamic provisioning, Only binds to PVs with no SC
  volumeAttributesClassName: gold
  
  selector:               # Filters PVs by labels (e.g., matchLabels, matchExpressions). Cannot be used with dynamic provisioning.
    matchLabels:
      release: "stable"
  volumeName: foo-pv      # Explicitly binds to a named PV, bypassing matching criteria except for validation.
```

```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
# provisioner: kubernetes.io/no-provisioner ; No provisioner, only static provisioning, for local storage
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer # Delays provisioning until a Pod using the PVC is scheduled.
                   # Immediate (default): Provisions the PV as soon as the PVC is created.
```


```bash
volumes:
  - name: cache-volume
    emptyDir:
      sizeLimit: 500Mi
      medium: Memory

volumes:
  - name: config-vol
    configMap:
      name: my-config
      items:
      - key: log_level
        path: log_level.conf

volumes:
  - name: secret-vol
    secret:
      secretName: my-secret

volumes:
    - name: mypd
      persistentVolumeClaim:
        claimName: myclaim

volumes:
  - name: pod-info
    downwardAPI:
      items:
      - path: "labels"
        fieldRef:
          fieldPath: metadata.labels

volumes:
  - name: image-vol
    image:
      reference: quay.io/crio/artifact:v2
      pullPolicy: IfNotPresent

```

| Scope              | Fields                                                                             |
| ------------------ | ---------------------------------------------------------------------------------- |
| **Pod Only**       | `fsGroup`, `fsGroupChangePolicy`, `supplementalGroups`, `supplementalGroupsPolicy` |
| **Container Only** | `capabilities`, `allowPrivilegeEscalation`, `privileged`, `readOnlyRootFilesystem`                                         |
| **Both**           | `runAsUser`, `runAsGroup`, `seccompProfile`, `appArmorProfile`, `seLinuxOptions`, `runAsNonRoot`   |


### ✅ 1. SSH into Node
`minikube ssh`	  `ssh -i key username@ip`		 `docker exec -it <node name> </bin/bash> or <bash> or </bin/sh> or <sh>`
curl <pod_IP:service_port / service IP:servive_port>



# NodePort    30000 => container's 8081
curl http://localhost:30000 OR curl http://<worker-node-private-ip>:30000
# ClusterIP
kubectl run test --image=busybox -it --rm --restart=Never -- sh # and then inside the shell: wget <service-name>.<namespace>.svc.cluster.local:<port>

# ✅ 2. Access from Laptop via Public IP + NodePort
curl http://<node-ip>:<nodePort> OR http://54.242.167.17:30000
```

kubectl port-forward svc/my-service 8080:80 # <local-port>:<remote-port> # open in browser: http://localhost:8080

service-name.dev.svc.cluster.local
