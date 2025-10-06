**Reference**
- Well-Known Labels, Annotations and Taints
- Kubernetes API
- Setup tools (kubeadm)
- Command line tool (kubectl)
- Component tools (etcd, kube-apiserver, kube-controller-manager, kube-scheduler)

**Static Pods:** `pod/etcd-ibtisam-iq, pod/kube-apiserver-ibtisam-iq, pod/kube-controller-manager-ibtisam-iq, pod/kube-scheduler-ibtisam-iq`

**Daemonsets (1/1):** `daemonset.apps/calico-node, daemonset.apps/kube-proxy`

**Deployments:** `deployment.apps/calico-kube-controllers (1/1), deployment.apps/coredns (2/2), deployment.apps/local-path-provisioner (1/1)`

```bash
set expandtab
set tabstop=2
set shiftwidth=2
k config set-context --current --namespace <tomcat-namespace-devops> # set the ns permanently
kubectl config set-context $(kubectl config current-context) --namespace=prod

--control-plane-endpoint: Stable API server endpoint for HA (supports DNS or load balancer).
--upload-certs: Shares certificates for additional control planes.
--pod-network-cidr: Sets Calico’s pod IP range (10.244.0.0/16).
--apiserver-advertise-address: Control plane’s private IP.

Container runs: `<command or ENTRYPOINT> <args or CMD>`
kubectl run mypod --image=busybox --restart=Never -- echo "Hi"` # args: ["echo", "Hi"]
kubectl run mypod --image=busybox --restart=Never --command -- echo "Hello from BusyBox"
kubectl run shellpod --image=busybox --restart=Never --command -- sh -c "echo Hello && date" # Using Shell Logic with sh -c
k run alpine-app --image alpine -- 'echo "Main application is running"; sleep 3600' # wrong, you need to open the shell in order to multiple commands
k run alpine-app --image alpine --command -- sh -c 'echo "Main application is running"; sleep 3600' # correct 
k run test-pod --image busybox --restart=Never -it -- sh
    wget or nslookup serviceName.ns.svc.cluster.local
    nslookup pod-id-address.namespace.pod.cluster.local

openssl x509 -in ibtisam.crt -text -noout

kubectl port-forward svc/my-service 8080:80 # <local-port>:<remote-port> # open in browser: http://localhost:8080

service-name.dev.svc.cluster.local
<section-hostname>.<subdomain>.<namespace>.svc.cluster.local

node01 ~ ➜  cat /var/lib/kubelet/config.yaml | grep -i staticPodPath:
staticPodPath: /etc/kubernetes/manifestss

sudo ls /opt/cni/bin/
sudo ls /etc/cni/net.d/

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

kubeadm init --help
kubeadm init --kubernetes-version=1.33.3 --pod-network-cidr 192.168.0.0/16 --ignore-preflight-errors=NumCPU
cp /etc/kubernetes/admin.conf /root/.kube/config
kubectl version
kubectl get pod -A
kubeadm token create --print-join-command
ssh node-summer
    kubeadm join 172.30.1.2:6443 --token ...
kubeadm certs check-expiration
kubeadm certs renew <>
kubeadm upgrade plan
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text
sudo systemctl list-unit-files --type service --all | grep kube

controlplane ~ ➜  echo '$USER' && sleep 5
$USER
controlplane ~ ➜  echo $USER && sleep 5
root
controlplane ~ ➜  echo "$USER && sleep 5"
root && sleep 5
controlplane ~ ➜  echo "$USER" && sleep 5
root

# Access a Pod directly
curl http://<pod-ip>:<container-port>
# Example: curl http://10.244.0.5:8081

# Access a Service via ClusterIP
curl http://<service-cluster-ip>:<service-port>
# Example: curl http://10.96.0.15:80

# Launch a temporary Pod with an interactive shell
kubectl run test --image=busybox -it --rm --restart=Never -- sh

  # Inside the Pod shell, test Service access
  wget -qO- <service-name>.<namespace>.svc.cluster.local:<port>
  # Example: wget amor.amor.svc.cluster.local:80

  # wget 172-17-2-2.default.pod.cluster.local

# From a local machine or external network:
curl http://<node-public-ip>:<nodePort>
# Example: curl http://54.242.167.17:30000

# From the node itself (via SSH):
curl http://localhost:<nodePort>
curl http://<private-node-ip>:<nodePort>
# Example: curl http://172.31.29.71:30000

# Forward to a Service
kubectl port-forward svc/<service-name> <local-port>:<service-port>
# Example: kubectl port-forward svc/amor 8080:80

# Forward to a Pod
kubectl port-forward pod/<pod-name> <local-port>:<pod-port>
# Example: kubectl port-forward pod/amor-pod 8080:80

# On your local machine, access the application
curl http://localhost:8080
# Or open in browser: http://localhost:8080

# If the IngressController is exposed via NodePort:
curl http://<node-ip>:<nodePort>/<path>
# Example: curl http://54.242.167.17:30080/asia

# If DNS is configured:
curl http://<domain-name>
# Example: curl http://local.ibtisam-iq.com

# For testing with a specific host header (bypassing DNS):
curl -H "Host: local.ibtisam-iq.com" http://<node-ip>:<ingress-nodePort>/<path>
# Example: curl -H "Host: local.ibtisam-iq.com" http://54.242.167.17:30080/asia
```

```yaml
rules:
- apiGroups:
  - ""
  resources:
  - '*'
  verbs:
  - '*'

rules:
- apiGroups:
  - ""
  - apps
  - batch
  - extensions
  resources:
  - '*'
  verbs:
  - '*'

env:
    - name:
      value or valueFrom

spec:
  suspend: true                   # Starts the Job in a suspended state (default: false)
  completions: 12                 # Default: 1
  parallelism: 4                  # Default: 1
  completionMode: Indexed         # Default: nonIndexed  
  backoffLimitPerIndex: 1         # Allows 1 retry per index
  maxFailedIndexes: 5             # Terminates the Job if 5 indices fail
  backoffLimit: 4                 # Specifies the number of retries for failed Pods (default: 6)
  activeDeadlineSeconds: 600      # Limits the Job duration to 600 seconds    # overrides backoffLimit
  ttlSecondsAfterFinished: 300    # automatic deletetion of job & its pods after completion    # cleanup
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

---


- `key=value` then operator: `Equal`
- If only the `key`, and not `value` then operator: `Exists`
- Affinity: You can use `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt` and `Lt`.
- Guaranteed: values of requests must equal limits, Burstable: At least one resource request or limit, BestEffort: No requests or limits are defined in any container 
- `targetPort`: The port on the Pod where traffic is forwarded (e.g., 8080). Can be a numeric port or a named port (e.g., http) defined in the Pod’s containerPort.
- `vi ~/.bashrc` → export KUBECONFIG=/root/my-kube-config → `source ~/.bashrc`
- Core K8s controllers (HPA, VPA, PDB) → same namespace only → no namespace allowed inside targetRef.
- controlplane:~$ kubectl exec secure-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
- If you're only using static provisioning and want the PV to be bound to a PVC without any storage class, you can leave it out or set it explicitly to an empty string ("").    storageClassName: ""  # This disables dynamic provisioning for this PV.
- `busybox` has a default entrypoint of `/bin/sh`, no `CMD` and a default command of `sh -c`.
- while doing curl inside the pod, curl <hostname> is mostly the service name (ClusterIP).
- `<section-hostname>.<subdomain>.<namespace>.svc.cluster.local`
- `--serviceaccount=namespace:serviceaccountname`
- To enable an API `v1alpha1`, add the `--runtime-config=rbac.authorization.k8s.io/v1alpha1` option to the kube-apiserver.yaml file
- If the exam asks about **CoreDNS config backup** → you back up the ConfigMap. `k get cm coredns -n kube-system -o yaml > /opt/coredns_backup.yaml`
- Update Cluster Domain → `k -n kube-system edit cm coredns` → `k -n kube-system rollout restart deploy coredns`
- `root@cka3962:~# iptables-save | grep p2-service` Write the iptables rules of node `cka3962` belonging the created Service `p2-service`.
- Mount without `subPath` → full directory; mount with `subPath` → single file/key only.
- If your `DB_USER = root`, then your `DB_Password` must match the value of `MYSQL_ROOT_PASSWORD` inside the MySQL Pod.
- **MySQL 5.6** needs at least ~512Mi–1Gi to initialize databases. With only 256Mi, InnoDB runs out of memory during startup, so the kernel kills the process.
- Always add at least one label in *metadata.labels* `app.kubernetes.io/name: <resource-name>`
- Use `env` when mapping specific keys → env vars; use `envFrom` when importing all keys from a ConfigMap/Secret.
- Use liveness probes to know when to restart a container.
- Probe failed → Update the probe port to match `containerPort`.

- PVC requires some time for binding. So, be patient.
- The manifest related to volume (pvc, pv), and resource field in pod/deployment.... delete all fields, and the apply.
- An `HTTPRoute` does not have to be in the same namespace as the `Gateway`, but it does have to be in the same namespace as the `Service` it references (unless you explicitly allow cross-namespace routing via `backendRefs.namespaces`).
- Use `kubectl api-resource` for interacting the imperative commands for **ResourceQuota and Role, ClusterRole**. Resources are plural here.
- In Kubernetes, each `volume` entry under `spec.volumes` must have a **unique name**. And if you try to add two different sources (like `persistentVolumeClaim` + `emptyDir`) under the same volume, you’ll also get an error.
- Unlike `hostPath` volumes (which **can create a path automatically** if it doesn’t exist → type: `DirectoryOrCreate`), a **local PersistentVolume (PV)** in Kubernetes expects that the directory (or device) already exists on the node.
- With `hostPath`, the `nodeAffinity` is a precaution; with `local`, it’s mandatory.
- Want to use controlplane? → Add **toleration**.
- Want to delete a PVC? → First **delete the Pod** using it.
- Manifest not deployed
  - ensure CRDs are installed first: no matches for kind "Persistentvolumeclaim" in version "v1"
  - strict decoding error: unknown field "metadata.app"
  - error: unable to decode "13.yaml": json: cannot unmarshal bool into Go struct field ObjectMeta.metadata.annotations of type string
- Application is crashing
  - `k describe`: wrong command, args, cm, secret, pvc, volume, image and its tag, probe, cpu, memory, mountPath
  - `k logs`: missing env var, multiple containers share same port within one pod, a required file is masked due to wrong `mountPath`
- Application is pending
  - wrong `nodeName`, `kube-controller-manager` pod is crashed, wrong schedular, wrong node labels for affininity, node is tainted 
- Kubelet Troubleshooting
  - `kubelet --version` → `whereis kubelet`
  - `ps aux | grep kubelet` → `systemctl status kubelet` → `systemctl restart kubelet` → `/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf`
  - `journalctl -u kubelet -f`
  - `/var/lib/kubelet/kubeadm-flags.env` && `/var/lib/kubelet/config.yaml` && `/etc/kubernetes/kubelet.conf`
- Apiserver is crashed
  - Only ONE container, exited now, however; no increment in *Attempt* count found → Incorrect Manifest: `journalctl -u kubelet -f | grep apiserver`
  - Only ONE container, exited now, but increment in *Attempt* count is found and new container id assigned each time → Incorrect args
    -  `crictl ps -a | grep kube-apiserver` && `crictl logs <recent-exited-container-id>`
    -  `--etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt`
    -  `--etcd-servers=https://127.0.0.1:2379`
- Apiserver is restarting...
  - ONE container at a time, which is running; however, multiple containers are created, and exited → Incorrect Probe


### What to Remember About Nginx Paths in CKA

* `/etc/nginx/nginx.conf` → **main config file** (may include `conf.d/*.conf`).
* `/etc/nginx/conf.d/default.conf` → **default server block (virtual host)** → where you change `root`, `listen`, or proxy settings.
* `/usr/share/nginx/html` → **NGINX web server default location, default static web root** → where default `index.html` lives.
* `/var/log/nginx/error.log` → **check errors if Pod fails or returns bad responses**.


## Use quotes ""

```bash
resources:
      requests:
        memory: "10Gi"
        cpu: "500m"
      limits:
        memory: "10Gi"
        cpu: "500m"

commnad:
- sleep
- "3600"

command: ["sleep", "5"]

env:
    - name: NGINX_PORT
      value: "8080"

root@student-node ~ ➜  k create cj simple-node-job -n ckad-job --schedule "*/30 * * * *" --image node -- sh -c "ps -eaf"

nginx.ingress.kubernetes.io/ssl-redirect: "false"

appVersion: "1.20.0"

images:
  - name: nginx
    newTag: "1.23"
```
---
