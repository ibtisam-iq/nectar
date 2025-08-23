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
