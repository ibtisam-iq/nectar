## Kubeadm certification management

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
