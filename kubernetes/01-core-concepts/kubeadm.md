
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
