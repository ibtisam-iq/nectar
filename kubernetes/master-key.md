[**YAML**](https://github.com/ibtisam-iq/nectar/blob/main/yaml/README.md) & [KodeKloud YAML Free One Hour Practice Lab](https://kodekloud.com/pages/free-labs/kubernetes/yaml), [**Objects**](./01-core-concepts/objects.md)

**Static Pods:** `pod/etcd-ibtisam-iq, pod/kube-apiserver-ibtisam-iq, pod/kube-controller-manager-ibtisam-iq, pod/kube-scheduler-ibtisam-iq`

**Daemonsets (1/1):** `daemonset.apps/calico-node, daemonset.apps/kube-proxy`

**Deployments:** `deployment.apps/calico-kube-controllers (1/1), deployment.apps/coredns (2/2), deployment.apps/local-path-provisioner (1/1)`

`busybox` has a default entrypoint of `/bin/sh`, no `CMD` and a default command of `sh -c`.

Container runs: `<command or ENTRYPOINT> <args or CMD>`

```bash
    env:
    - name: ENVIRONMENT
      value: production
    - name: MY_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: PLAYER_INITIAL_LIVES
      valueFrom:
        configMapKeyRef:                # secretKeyRef
            name: game-demo           
            key: player_initial_lives

    envFrom:
    - configMapRef:                     # secretRef
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
  volumeMode: Filesystem    # Default
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain    # Default
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
```

```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
  - ReadWriteOnce
  volumeMode: Filesystem     # Default
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
allowVolumeExpansion: true    # You can only expand a PVC if its storage class's allowVolumeExpansion field is set to true.
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

kubectl config set-context $(kubectl config current-context) --namespace=prod

```bash
node01 ~ ➜  cat /var/lib/kubelet/config.yaml | grep -i staticPodPath:
staticPodPath: /etc/kubernetes/manifestss

sudo ls /opt/cni/bin/
sudo ls /etc/cni/net.d/
```
```yaml
spec:
  suspend: true                   # Starts the Job in a suspended state (default: false)
  completions: 12                 # Default: 1
  parallelism: 4                  # Default: 1
  completionMode: Indexed         # Default: nonIndexed  
  backoffLimitPerIndex: 1         # Allows 1 retry per index
  maxFailedIndexes: 5             # Terminates the Job if 5 indices fail
  backoffLimit: 4                 # Specifies the number of retries for failed Pods (default: 6)
  activeDeadlineSeconds: 600      # Limits the Job duration to 600 seconds
  ttlSecondsAfterFinished: 300    # automatic deletetion of job & its pods after completion
---
# Default
  backoffLimit: 6
  completionMode: NonIndexed
  completions: 1
  manualSelector: false
  parallelism: 1
  podReplacementPolicy: TerminatingOrFailed
  selector:
    matchLabels:
      batch.kubernetes.io/controller-uid: e9892e6c-33c0-4dc8-a6ff-d557b9d7a67c
  suspend: false
```
- `key=value` then operator: `Equal`
- If only the `key`, and not `value` then operator: `Exists`
- Affinity: You can use `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt` and `Lt`.
```yaml
env:
    - name:
      value or valueFrom
