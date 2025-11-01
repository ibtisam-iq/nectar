## Calico Installation

Utilize the official Calico definition file, available at Calico Installation Guide, to deploy the Calico CNI on the cluster.

Make sure to configure the CIDR to `172.17.0.0/16` and set the encapsulation method to `VXLAN`.

After installing the CNI, check if the pods can successfully communicate with each other.

```bash
# Don't use kubectl apply -f <>
# The CustomResourceDefinition "installations.operator.tigera.io" is invalid: metadata.annotations: Too long: may not be more than 262144 bytes

cluster4-controlplane ~ ➜  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml
namespace/tigera-operator created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgpfilters.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/caliconodestatuses.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipreservations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/tiers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/adminnetworkpolicies.policy.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/apiservers.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/imagesets.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/installations.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/tigerastatuses.operator.tigera.io created
serviceaccount/tigera-operator created
clusterrole.rbac.authorization.k8s.io/tigera-operator created
clusterrolebinding.rbac.authorization.k8s.io/tigera-operator created
deployment.apps/tigera-operator created

cluster4-controlplane ~ ➜  curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/custom-resources.yaml -O
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   777  100   777    0     0   4802      0 --:--:-- --:--:-- --:--:--  4826

cluster4-controlplane ~ ➜  ls
custom-resources.yaml

cluster4-controlplane ~ ➜  vi custom-resources.yaml 

cluster4-controlplane ~ ➜  cat custom-resources.yaml 
# This section includes base Calico installation configuration.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    ipPools:
    - name: default-ipv4-ippool
      blockSize: 26
      cidr: 172.17.0.0/16                     # 192.168.0.0/16
      encapsulation: VXLAN                    # VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()

---

# This section configures the Calico API server.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}


cluster4-controlplane ~ ➜  k apply -f custom-resources.yaml 
installation.operator.tigera.io/default created
apiserver.operator.tigera.io/default created

cluster4-controlplane ~ ➜  k run nginx --image nginx
pod/nginx created

cluster4-controlplane ~ ➜  k get po -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP               NODE                    NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          7s    172.17.181.133   cluster4-controlplane   <none>           <none>

cluster4-controlplane ~ ➜  
```

---


## Install Containerd

```bash
ubuntu:~$ wget https://github.com/containerd/containerd/releases/download/v2.0.4/containerd-2.0.4-linux-amd64.tar.gz
ubuntu:~$ ls
containerd-2.0.4-linux-amd64.tar.gz  filesystem
ubuntu:~$ sudo tar -xzvf -C /usr/local containerd-2.0.4-linux-amd64.tar.gz
bin/
bin/ctr
bin/containerd-stress
bin/containerd
bin/containerd-shim-runc-v2
ubuntu:~$ containerd --version
containerd github.com/containerd/containerd/v2 v2.0.4 1a43cb6a1035441f9aca8f5666a9b3ef9e70ab20

# Set System Parameters

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
```

---

## Install  debian package for cri-dockerd

```bash
root@cluster5-controlplane ~ ➜  dpkg -i cri-dockerd_0.3.16.3-0.ubuntu-jammy_amd64.deb 
Selecting previously unselected package cri-dockerd.
(Reading database ... 18376 files and directories currently installed.)
Preparing to unpack cri-dockerd_0.3.16.3-0.ubuntu-jammy_amd64.deb ...
Unpacking cri-dockerd (0.3.16~3-0~ubuntu-jammy) ...
Setting up cri-dockerd (0.3.16~3-0~ubuntu-jammy) ...
Created symlink /etc/systemd/system/multi-user.target.wants/cri-docker.service → /lib/systemd/system/cri-docker.service.
Created symlink /etc/systemd/system/sockets.target.wants/cri-docker.socket → /lib/systemd/system/cri-docker.socket.
/usr/sbin/policy-rc.d returned 101, not running 'start cri-docker.service cri-docker.socket'

root@cluster5-controlplane ~ ➜  systemctl start cri-docker.service

root@cluster5-controlplane ~ ➜  systemctl enable cri-docker.service

root@cluster5-controlplane ~ ➜  systemctl status cri-docker.service
● cri-docker.service - CRI Interface for Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/cri-docker.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2025-11-01 08:57:19 UTC; 24s ago
```

---

## Cluster Setup

There are two VMs `controlplane` and `node-summer`, create a two Node Kubeadm Kubernetes cluster with them. Kubeadm, kubelet and kubectl are already installed.

First make `controlplane` the controlplane. For this we should:

- Use Kubernetes version v1.33.3
- Use a Pod-Network-Cidr of 192.168.0.0/16
- Ignore preflight errors for NumCPU and Mem
- Copy the default kubectl admin.conf to /root/.kube/config

```bash
kubeadm init --kubernetes-version=1.33.3 --pod-network-cidr 192.168.0.0/16 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem

cp /etc/kubernetes/admin.conf /root/.kube/config

kubectl version

kubectl get pod -A
```
Join `node-summer` as a worker Node to the cluster.

```bash
# generate a new token OR use the one printed out "kubeadm init" before
kubeadm token create --print-join-command

ssh node-summer
    kubeadm join 172.30.1.2:6443 --token ...
    exit

controlplane:~$ k get no
NAME           STATUS   ROLES           AGE    VERSION
controlplane   Ready    control-plane   7m1s   v1.33.2
node-summer    Ready    <none>          12s    v1.33.2
controlplane:~$ 
```

---

## Join Node using Kubeadm

The Node `node01` is not yet part of the cluster, join it using kubeadm.

```bash
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE     VERSION
controlplane   Ready    control-plane   4d12h   v1.33.2
controlplane:~$ kubeadm token create --print-join-command
kubeadm join 172.30.1.2:6443 --token ukxc7d.cx0j05kw50wflz6v --discovery-token-ca-cert-hash sha256:a6a509290240a52bf6e8776227b83b7fc69d4765636a8ec54988e2d0d919a4cc 
controlplane:~$ ssh node01
Last login: Mon Feb 10 22:06:42 2025 from 10.244.0.131
node01:~$ kubeadm join 172.30.1.2:6443 --token ukxc7d.cx0j05kw50wflz6v --discovery-token-ca-cert-hash sha256:a6a509290240a52bf6e8776227b83b7fc69d4765636a8ec54988e2d0d919a4cc
[preflight] Running pre-flight checks
[preflight] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[preflight] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 501.346689ms
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

node01:~$ exit
logout
Connection to node01 closed.
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE     VERSION
controlplane   Ready    control-plane   4d12h   v1.33.2
node01         Ready    <none>          38s     v1.33.2
controlplane:~$ 
```

---

## Linux Services

List the services on your Linux operating system that are associated with Kubernetes. Save the output to a file named `services.csv`.

```bash
controlplane:~$ sudo systemctl list-unit-files --type service --all | grep kube
kubelet.service                              enabled         enabled
podman-kube@.service                         disabled        enabled
controlplane:~$ sudo systemctl list-unit-files --type service --all | grep kube > services.csv
```

## Kubeadm Certification Management

Using kubeadm, read out the expiration date of the apiserver certificate and write it into `/root/apiserver-expiration`.

```bash
controlplane:~$ kubeadm certs check-expiration
[check-expiration] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[check-expiration] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Aug 19, 2026 09:03 UTC   360d            ca                      no      
apiserver                  Aug 19, 2026 09:03 UTC   360d            ca                      no      
apiserver-etcd-client      Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
apiserver-kubelet-client   Aug 19, 2026 09:03 UTC   360d            ca                      no      
controller-manager.conf    Aug 19, 2026 09:03 UTC   360d            ca                      no      
etcd-healthcheck-client    Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
etcd-peer                  Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
etcd-server                Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
front-proxy-client         Aug 19, 2026 09:03 UTC   360d            front-proxy-ca          no      
scheduler.conf             Aug 19, 2026 09:03 UTC   360d            ca                      no      
super-admin.conf           Aug 19, 2026 09:03 UTC   360d            ca                      no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Aug 17, 2035 09:03 UTC   9y              no      
etcd-ca                 Aug 17, 2035 09:03 UTC   9y              no      
front-proxy-ca          Aug 17, 2035 09:03 UTC   9y              no      
controlplane:~$ echo "Aug 19, 2026 09:03 UTC" > /root/apiserver-expiration
controlplane:~$
```

Using kubeadm, renew the certificates of the `apiserver` and `scheduler.conf`.

```bash
controlplane:~$ kubeadm certs renew apiserver
[renew] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[renew] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.

certificate for serving the Kubernetes API renewed
controlplane:~$ 
controlplane:~$ 
controlplane:~$ kubeadm certs renew scheduler.conf
[renew] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[renew] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.

certificate embedded in the kubeconfig file for the scheduler manager to use renewed
controlplane:~$ 
controlplane:~$ kubeadm certs check-expiration 
[check-expiration] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[check-expiration] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Aug 19, 2026 09:03 UTC   360d            ca                      no      
apiserver                  Aug 23, 2026 21:52 UTC   364d            ca                      no      
apiserver-etcd-client      Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
apiserver-kubelet-client   Aug 19, 2026 09:03 UTC   360d            ca                      no      
controller-manager.conf    Aug 19, 2026 09:03 UTC   360d            ca                      no      
etcd-healthcheck-client    Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
etcd-peer                  Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
etcd-server                Aug 19, 2026 09:03 UTC   360d            etcd-ca                 no      
front-proxy-client         Aug 19, 2026 09:03 UTC   360d            front-proxy-ca          no      
scheduler.conf             Aug 23, 2026 21:53 UTC   364d            ca                      no      
super-admin.conf           Aug 19, 2026 09:03 UTC   360d            ca                      no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Aug 17, 2035 09:03 UTC   9y              no      
etcd-ca                 Aug 17, 2035 09:03 UTC   9y              no      
front-proxy-ca          Aug 17, 2035 09:03 UTC   9y              no      
controlplane:~$ 
```

---

## Kubernetes PKI Essentials

```bash
ls /etc/kubernetes/
admin.conf  controller-manager.conf  kubelet.conf  manifests  pki  scheduler.conf  super-admin.conf
controlplane:~$ ls /etc/kubernetes/pki/
apiserver-etcd-client.crt     apiserver-kubelet-client.key  ca.crt  front-proxy-ca.crt      front-proxy-client.key
apiserver-etcd-client.key     apiserver.crt                 ca.key  front-proxy-ca.key      sa.key
apiserver-kubelet-client.crt  apiserver.key                 etcd    front-proxy-client.crt  sa.pub

controlplane:~$ sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | egrep 'Subject:|Issuer:|DNS:|IP Address:'
        Issuer: CN = kubernetes
        Subject: CN = kube-apiserver
                DNS:controlplane, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP Address:10.96.0.1, IP Address:172.30.1.2
controlplane:~$ sudo openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -text | egrep 'Subject:|Issuer:'
        Issuer: CN = kubernetes
        Subject: CN = kubernetes
```

---

## Check the current version and the target version

Run the appropriate command to check the current version of the API server, controller manager, scheduler, kube-proxy, CoreDNS, and etcd.

```bash
controlplane:~$ kubeadm upgrade plan
[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade/config] Use 'kubeadm init phase upload-config --config your-config-file' to re-upload it.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: 1.33.2
[upgrade/versions] kubeadm version: v1.33.2
[upgrade/versions] Target version: v1.33.4
[upgrade/versions] Latest version in the v1.33 series: v1.33.4

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE           CURRENT   TARGET
kubelet     controlplane   v1.33.2   v1.33.4

Upgrade to the latest version in the v1.33 series:

COMPONENT                 NODE           CURRENT    TARGET
kube-apiserver            controlplane   v1.33.2    v1.33.4
kube-controller-manager   controlplane   v1.33.2    v1.33.4
kube-scheduler            controlplane   v1.33.2    v1.33.4
kube-proxy                               1.33.2     v1.33.4
CoreDNS                                  v1.12.0    v1.12.0
etcd                      controlplane   3.5.21-0   3.5.21-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.33.4

Note: Before you can perform this upgrade, you have to update kubeadm to v1.33.4.

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
_____________________________________________________________________

controlplane:~$
```

---

## Change Service CIDR

```bash
controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i service-cluster-ip-range
    - --service-cluster-ip-range=172.20.0.0/16

controlplane ~ ➜  vi /etc/kubernetes/manifests/kube-apiserver.yaml

controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep -i service-cluster-ip-range
    - --service-cluster-ip-range=172.20.0.0/16

controlplane ~ ➜  vi /etc/kubernetes/manifests/kube-controller-manager.yaml

controlplane ~ ➜  systemctl restart kubelet

controlplane ~ ➜  k get po -n kube-system 
NAME                                       READY   STATUS    RESTARTS        AGE
calico-kube-controllers-587f6db6c5-mthp4   1/1     Running   1 (2m2s ago)    39m
canal-j8t2z                                2/2     Running   0               39m
canal-jjhrz                                2/2     Running   0               39m
canal-m9fwl                                2/2     Running   0               39m
coredns-6678bcd974-g554m                   1/1     Running   0               39m
coredns-6678bcd974-q4wd7                   1/1     Running   0               39m
etcd-controlplane                          1/1     Running   0               39m
kube-apiserver-controlplane                1/1     Running   0               2m9s
kube-controller-manager-controlplane       1/1     Running   0               95s
kube-proxy-qdkmk                           1/1     Running   0               39m
kube-proxy-svqxh                           1/1     Running   0               39m
kube-proxy-xflvx                           1/1     Running   0               39m
kube-scheduler-controlplane                1/1     Running   2 (2m46s ago)   39m

controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep -i service-cluster-ip-range
    - --service-cluster-ip-range=100.96.0.0/12

controlplane ~ ➜  cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i service-cluster-ip-range
    - --service-cluster-ip-range=100.96.0.0/12

controlplane ~ ➜  kubectl -n kube-system describe pod kube-apiserver-controlplane | grep service-cluster-ip-range
      --service-cluster-ip-range=100.96.0.0/12

controlplane:~$ k -n kube-system edit svc kube-dns
error: services "kube-dns" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-312847560.yaml"
error: Edit cancelled, no valid changes were saved.
controlplane:~$ k replace -f /tmp/kubectl-edit-312847560.yaml --force
service "kube-dns" deleted from kube-system namespace
The Service "kube-dns" is invalid: spec.clusterIPs: Invalid value: ["100.96.0.10"]: failed to allocate IP 100.96.0.10: the provided network does not match the current range

controlplane:~$ vim /var/lib/kubelet/config.yaml

controlplane:~$ k -n kube-system edit cm kubelet-config
configmap/kubelet-config edited

controlplane:~$ kubeadm upgrade node phase kubelet-config
controlplane:~$ systemctl daemon-reload
controlplane:~$ systemctl restart kubelet

controlplane:~$ kubectl edit cm -n kube-system kubeadm-config                             
configmap/kubeadm-config edited

controlplane:~$ kubectl run netshoot --image=nicolaka/netshoot --command sleep --command "3600"
controlplane:~$ k get po
NAME       READY   STATUS    RESTARTS   AGE
netshoot   1/1     Running   0          4m42s
controlplane:~$ k exec -it netshoot -- bash
netshoot:~# cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 100.96.0.10
options ndots:5
netshoot:~# nslookup google.com
;; communications error to 100.96.0.10#53: timed out
^C
netshoot:~# exit

controlplane:~$ k run po --image nginx --port 80 --expose
service/po created
pod/po created
controlplane:~$ k get po,svc
NAME           READY   STATUS    RESTARTS   AGE
pod/netshoot   1/1     Running   0          8m59s
pod/po         1/1     Running   0          6s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   3d1h
service/po           ClusterIP   10.108.69.195   <none>        80/TCP    6s
controlplane:~$ k exec -it po -- sh
# cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 100.96.0.10
options ndots:5
```

---

## 📂 Files under `/var/lib/kubelet/pki/`

Node `node1` has been added to the cluster using kubeadm and TLS bootstrapping.

Find the **Issuer** and **Extended Key Usage** values on `node1` for:

- **Kubelet Client Certificate**, the one used for outgoing connections to the kube-apiserver
- **Kubelet Server Certificate**, the one used for incoming connections from the kube-apiserver

Write the information into file `/opt/course/3/certificate-info.txt`.

### 1. `kubelet-client-current.pem` (symlink to `kubelet-client-<date>.pem`)

* **Purpose**:
  This is the **Kubelet Client Certificate**.
  → Used when the kubelet talks *outbound* to the **kube-apiserver** (for example, registering itself, reporting node status, or fetching workload instructions).

### 2. `kubelet.crt`

* **Purpose**:
  This is the **Kubelet Server Certificate**.
  → Used when the **apiserver** connects *into* the kubelet (for example, to get logs, exec into containers, or for health checks).

### 3. `kubelet.key`

* **Purpose**:
  This is just the **private key** for the kubelet server certificate (`kubelet.crt`).
  → You don’t check EKU or Issuer here — `openssl` will fail for this because it’s not a certificate, only a key.

# 🧭 Exam Decision Flow

If you get asked **“Kubelet Client Certificate”**
➡️ Look at **`kubelet-client-current.pem`**

If you get asked **“Kubelet Server Certificate”**
➡️ Look at **`kubelet.crt`**

If you see `.key` → ignore (not needed for Issuer/EKU).
If you see dated file (like `kubelet-client-2025-09-22-10-49-53.pem`) → same as current symlink, but always use `-current.pem` for consistency.

# 🔎 Example Commands

```bash
# Client cert (outgoing to API)
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout | egrep "Issuer:|Extended Key Usage"

# Server cert (incoming from API)
openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout | egrep "Issuer:|Extended Key Usage"
```


```bash
controlplane ~ ➜  k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   55m   v1.34.0
node01         Ready    <none>          54m   v1.34.0
node02         Ready    <none>          54m   v1.34.0

controlplane ~ ➜  ssh node01
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-1083-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

node01 ~ ➜  ls /var/lib/kubelet/pki/
kubelet-client-2025-09-22-10-49-53.pem  kubelet-client-current.pem  kubelet.crt  kubelet.key

node01 ~ ➜  openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -text | grep -i Issuer
        Issuer: CN = kubernetes

node01 ~ ➜  openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -text | grep -i "Extended Key Usage" -1
                Digital Signature
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication

node01 ~ ➜  openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -noout -text | grep -i Issuer
        Issuer: CN = node01-ca@1758538193

node01 ~ ➜  openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -noout -text | grep -i "Extended Key Usage" -1
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication

node01 ~ ➜  exit
logout
Connection to node01 closed.

controlplane ~ ➜  openssl x509 -in /etc/kubernetes/pki/apiserver
apiserver.crt                 apiserver-etcd-client.key     apiserver-kubelet-client.crt  
apiserver-etcd-client.crt     apiserver.key                 apiserver-kubelet-client.key  

# same as /var/lib/kubelet/pki/kubelet-client-current.pem
controlplane ~ ➜  openssl x509 -in /etc/kubernetes/pki/apiserver-kubelet-client.crt -noout -text | grep -i Issuer
        Issuer: CN = kubernetes

# same as /var/lib/kubelet/pki/kubelet-client-current.pem
controlplane ~ ➜  openssl x509 -in /etc/kubernetes/pki/apiserver-kubelet-client.crt -noout -text | grep -i "Extended Key Usage" -1
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication

controlplane ~ ➜  cat > /opt/course/3/certificate-info.txt
-bash: /opt/course/3/certificate-info.txt: No such file or directory

controlplane ~ ✖ mkdir -p /opt/course/3/

controlplane ~ ➜  cat > /opt/course/3/certificate-info.txt
Issuer: CN = kubernetes
X509v3 Extended Key Usage: TLS Web Client Authentication

Issuer: CN = node01-ca@1758538193
X509v3 Extended Key Usage: TLS Web Server Authentication

controlplane ~ ➜  
```
