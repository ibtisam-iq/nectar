# Upgrade Kubernetes Components


1. Add the k8s repository with the required version
2. List all the available versions of the kubeadm package from the APT repositories
- `sudo apt-cache madison kubeadm`
3. Upgrade kubeadm binary, and check its versrion
- To allow downgrading with apt, explicitly pass --allow-downgrades
- `sudo apt-get install -y kubeadm=1.31.0-1.1 --allow-downgrades`
4. Verify the upgrade plan, and choose a version to upgrade it
```text
Specified version to downgrade to "v1.31.0" is too low; kubeadm can downgrade only 1 minor version at a time

error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR CoreDNSUnsupportedPlugins]: start version '1.12.0' not supported
        [ERROR CoreDNSMigration]: CoreDNS will not be upgraded: start version '1.12.0' not supported
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
laborant@cplane-01:~$ sudo kubeadm upgrade apply v1.32.3 --ignore-preflight-errors
flag needs an argument: --ignore-preflight-errors
To see the stack trace of this error execute with --v=5 or higher
laborant@cplane-01:~$ sudo kubeadm upgrade apply v1.32.3 --ignore-preflight-errors=CoreDNSUnsupportedPlugins,CoreDNSMigration 
```
5. Drain the node
6. Upgrade kubelet and kubectl binaries
7. Restart the kubelet & uncordon the node

```bash
controlplane ~ ➜  k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   66m   v1.33.0
node01         Ready    <none>          65m   v1.33.0
node02         Ready    <none>          65m   v1.33.0

controlplane ~ ➜  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | sudo tee /etc/apt/sources.list.d/kub
ernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /

controlplane ~ ➜  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
File '/etc/apt/keyrings/kubernetes-apt-keyring.gpg' exists. Overwrite? (y/N) y

controlplane ~ ➜  sudo apt update
Get:2 https://download.docker.com/linux/ubuntu jammy InRelease [48.8 kB]                                                   
Get:3 https://download.docker.com/linux/ubuntu jammy/stable amd64 Packages [65.5 kB]                                                                               
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.31/deb  InRelease [1,189 B]                                        
Get:4 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.31/deb  Packages [17.1 kB]
Get:5 http://security.ubuntu.com/ubuntu jammy-security InRelease [129 kB]                                                                                                 
Get:6 http://security.ubuntu.com/ubuntu jammy-security/multiverse amd64 Packages [48.5 kB]                                                                                
Get:7 http://security.ubuntu.com/ubuntu jammy-security/main amd64 Packages [3,207 kB]                                                                                     
Get:8 http://security.ubuntu.com/ubuntu jammy-security/universe amd64 Packages [1,270 kB]                                                                                 
Get:9 http://security.ubuntu.com/ubuntu jammy-security/restricted amd64 Packages [5,103 kB]                                                                               
Get:10 http://archive.ubuntu.com/ubuntu jammy InRelease [270 kB]                                                                                                          
Get:11 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [128 kB]                                                                                                  
Get:12 http://archive.ubuntu.com/ubuntu jammy-backports InRelease [127 kB]                                                                                                
Get:13 http://archive.ubuntu.com/ubuntu jammy/universe amd64 Packages [17.5 MB]                                                                                           
Get:14 http://archive.ubuntu.com/ubuntu jammy/main amd64 Packages [1,792 kB]                                                                                              
Get:15 http://archive.ubuntu.com/ubuntu jammy/multiverse amd64 Packages [266 kB]                                                                                          
Get:16 http://archive.ubuntu.com/ubuntu jammy/restricted amd64 Packages [164 kB]                                                                                          
Get:17 http://archive.ubuntu.com/ubuntu jammy-updates/multiverse amd64 Packages [75.9 kB]                                                                                 
Get:18 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 Packages [1,575 kB]                                                                                  
Get:19 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages [3,518 kB]                                                                                      
Get:20 http://archive.ubuntu.com/ubuntu jammy-updates/restricted amd64 Packages [5,290 kB]                                                                                
Get:21 http://archive.ubuntu.com/ubuntu jammy-backports/universe amd64 Packages [35.2 kB]                                                                                 
Get:22 http://archive.ubuntu.com/ubuntu jammy-backports/main amd64 Packages [83.2 kB]                                                                                     
Fetched 40.7 MB in 16s (2,484 kB/s)                                                                                                                                       
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
9 packages can be upgraded. Run 'apt list --upgradable' to see them.

controlplane ~ ➜  sudo apt-cache madison kubeadm
   kubeadm | 1.31.11-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.10-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.9-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.8-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.7-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.6-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.5-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.4-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.3-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.2-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.1-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages
   kubeadm | 1.31.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.31/deb  Packages

controlplane ~ ➜  sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm='1.31.0-*' && \
sudo apt-mark hold kubeadm
Canceled hold on kubeadm.
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                             
Hit:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.31/deb  InRelease                                                           
Hit:3 http://archive.ubuntu.com/ubuntu jammy InRelease                                                                                                            
Hit:4 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:5 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Hit:6 http://security.ubuntu.com/ubuntu jammy-security InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Selected version '1.31.0-1.1' (isv:kubernetes:core:stable:v1.31:pkgs.k8s.io [amd64]) for 'kubeadm'
The following packages will be DOWNGRADED:
  kubeadm
0 upgraded, 0 newly installed, 1 downgraded, 0 to remove and 9 not upgraded.
E: Packages were downgraded and -y was used without --allow-downgrades.

controlplane ~ ✖ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"33", EmulationMajor:"", EmulationMinor:"", MinCompatibilityMajor:"", MinCompatibilityMinor:"", GitVersion:"v1.33.0", GitCommit:"60a317eadfcb839692a68eab88b2096f4d708f4f", GitTreeState:"clean", BuildDate:"2025-04-23T13:05:48Z", GoVersion:"go1.24.2", Compiler:"gc", Platform:"linux/amd64"}

controlplane ~ ➜  sudo apt-mark unhold kubeadm && \
sudo apt-get update && \
sudo apt-get install -y kubeadm=1.31.0-1.1 --allow-downgrades && \
sudo apt-mark hold kubeadm
kubeadm was already not on hold.
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                                
Hit:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.31/deb  InRelease                                                             
Hit:3 http://security.ubuntu.com/ubuntu jammy-security InRelease                                                                                                    
Hit:4 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:5 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:6 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be DOWNGRADED:
  kubeadm
0 upgraded, 0 newly installed, 1 downgraded, 0 to remove and 9 not upgraded.
Need to get 11.4 MB of archives.
After this operation, 16.2 MB disk space will be freed.
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.31/deb  kubeadm 1.31.0-1.1 [11.4 MB]
Fetched 11.4 MB in 1s (7,672 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
dpkg: warning: downgrading kubeadm from 1.33.0-1.1 to 1.31.0-1.1
(Reading database ... 20567 files and directories currently installed.)
Preparing to unpack .../kubeadm_1.31.0-1.1_amd64.deb ...
Unpacking kubeadm (1.31.0-1.1) over (1.33.0-1.1) ...
Setting up kubeadm (1.31.0-1.1) ...
kubeadm set on hold.

controlplane ~ ➜  kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"31", GitVersion:"v1.31.0", GitCommit:"9edcffcde5595e8a5b1a35f88c421764e575afce", GitTreeState:"clean", BuildDate:"2024-08-13T07:35:57Z", GoVersion:"go1.22.5", Compiler:"gc", Platform:"linux/amd64"}

controlplane ~ ➜  sudo kubeadm upgrade plan
[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
W0805 16:34:43.952199   65205 configset.go:177] error unmarshaling configuration schema.GroupVersionKind{Group:"kubelet.config.k8s.io", Version:"v1beta1", Kind:"KubeletConfiguration"}: strict decoding error: unknown field "crashLoopBackOff"
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: 1.33.0
[upgrade/versions] kubeadm version: v1.31.0
I0805 16:34:48.157002   65205 version.go:261] remote version is much newer: v1.33.3; falling back to: stable-1.31
[upgrade/versions] Target version: v1.31.11

W0805 16:34:48.287666   65205 configset.go:177] error unmarshaling configuration schema.GroupVersionKind{Group:"kubelet.config.k8s.io", Version:"v1beta1", Kind:"KubeletConfiguration"}: strict decoding error: unknown field "crashLoopBackOff"

controlplane ~ ➜  sudo kubeadm upgrade apply v1.31.0
[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
W0805 16:38:33.520654   67882 configset.go:177] error unmarshaling configuration schema.GroupVersionKind{Group:"kubelet.config.k8s.io", Version:"v1beta1", Kind:"KubeletConfiguration"}: strict decoding error: unknown field "crashLoopBackOff"
[upgrade] Running cluster health checks
[upgrade/version] You have chosen to change the cluster version to "v1.31.0"
[upgrade/versions] Cluster version: v1.33.0
[upgrade/versions] kubeadm version: v1.31.0
[upgrade/version] FATAL: the --version argument is invalid due to these fatal errors:

        - Specified version to downgrade to "v1.31.0" is too low; kubeadm can downgrade only 1 minor version at a time

Please fix the misalignments highlighted above and try upgrading again
To see the stack trace of this error execute with --v=5 or higher

controlplane ~ ✖ echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kube
rnetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /

controlplane ~ ➜  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
File '/etc/apt/keyrings/kubernetes-apt-keyring.gpg' exists. Overwrite? (y/N) y

controlplane ~ ➜  sudo apt update
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                                              
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  InRelease [1,189 B]                                   
Get:3 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  Packages [11.2 kB]                 
Hit:4 http://archive.ubuntu.com/ubuntu jammy InRelease                                                         
Hit:5 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:6 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Hit:7 http://security.ubuntu.com/ubuntu jammy-security InRelease
Fetched 12.4 kB in 6s (2,123 B/s)
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
10 packages can be upgraded. Run 'apt list --upgradable' to see them.

controlplane ~ ➜  sudo apt-cache madison kubeadm
   kubeadm | 1.32.7-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubeadm | 1.32.6-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubeadm | 1.32.5-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubeadm | 1.32.4-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubeadm | 1.32.3-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubeadm | 1.32.2-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubeadm | 1.32.1-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages
   kubeadm | 1.32.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.32/deb  Packages

controlplane ~ ➜  sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y --allow-downgrades kubeadm='1.32.0-*' && \
sudo apt-mark hold kubeadm
Canceled hold on kubeadm.
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                                                           
Hit:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  InRelease                                                  
Hit:3 http://security.ubuntu.com/ubuntu jammy-security InRelease                                                                   
Hit:4 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:5 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:6 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Selected version '1.32.0-1.1' (isv:kubernetes:core:stable:v1.32:pkgs.k8s.io [amd64]) for 'kubeadm'
The following packages will be upgraded:
  kubeadm
1 upgraded, 0 newly installed, 0 to remove and 9 not upgraded.
Need to get 12.2 MB of archives.
After this operation, 12.7 MB of additional disk space will be used.
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  kubeadm 1.32.0-1.1 [12.2 MB]
Fetched 12.2 MB in 0s (28.8 MB/s)
debconf: delaying package configuration, since apt-utils is not installed
(Reading database ... 20567 files and directories currently installed.)
Preparing to unpack .../kubeadm_1.32.0-1.1_amd64.deb ...
Unpacking kubeadm (1.32.0-1.1) over (1.31.0-1.1) ...
Setting up kubeadm (1.32.0-1.1) ...
kubeadm set on hold.

controlplane ~ ➜  kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"32", GitVersion:"v1.32.0", GitCommit:"70d3cc986aa8221cd1dfb1121852688902d3bf53", GitTreeState:"clean", BuildDate:"2024-12-11T18:04:20Z", GoVersion:"go1.23.3", Compiler:"gc", Platform:"linux/amd64"}

controlplane ~ ➜  sudo kubeadm upgrade plan
[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade/config] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: 1.33.0
[upgrade/versions] kubeadm version: v1.32.0
I0805 16:43:19.867674   71967 version.go:261] remote version is much newer: v1.33.3; falling back to: stable-1.32
[upgrade/versions] Target version: v1.32.7


controlplane ~ ➜  sudo kubeadm upgrade apply v1.32.0
[upgrade] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[upgrade] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[upgrade/preflight] Running preflight checks
[upgrade] Running cluster health checks
[upgrade/preflight] You have chosen to upgrade the cluster version to "v1.32.0"
[upgrade/versions] Cluster version: v1.33.0
[upgrade/versions] kubeadm version: v1.32.0
[upgrade] Are you sure you want to proceed? [y/N]: y
[upgrade/preflight] Pulling images required for setting up a Kubernetes cluster
[upgrade/preflight] This might take a minute or two, depending on the speed of your internet connection
[upgrade/preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0805 16:44:04.961589   72426 checks.go:846] detected that the sandbox image "registry.k8s.io/pause:3.6" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.10" as the CRI sandbox image.
[upgrade/control-plane] Upgrading your static Pod-hosted control plane to version "v1.32.0" (timeout: 5m0s)...
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests421588564"
[upgrade/etcd] Non fatal issue encountered during upgrade: the desired etcd version "3.5.16-0" is older than the currently installed "3.5.21-0". Skipping etcd upgrade
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Renewing apiserver certificate
[upgrade/staticpods] Renewing apiserver-kubelet-client certificate
[upgrade/staticpods] Renewing front-proxy-client certificate
[upgrade/staticpods] Renewing apiserver-etcd-client certificate
[upgrade/staticpods] Moving new manifest to "/etc/kubernetes/manifests/kube-apiserver.yaml" and backing up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2025-08-05-16-44-22/kube-apiserver.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This can take up to 5m0s
[apiclient] Found 1 Pods for label selector component=kube-apiserver
[upgrade/staticpods] Component "kube-apiserver" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Renewing controller-manager.conf certificate
[upgrade/staticpods] Moving new manifest to "/etc/kubernetes/manifests/kube-controller-manager.yaml" and backing up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2025-08-05-16-44-22/kube-controller-manager.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This can take up to 5m0s
[apiclient] Found 1 Pods for label selector component=kube-controller-manager
[upgrade/staticpods] Component "kube-controller-manager" upgraded successfully!
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Renewing scheduler.conf certificate
[upgrade/staticpods] Moving new manifest to "/etc/kubernetes/manifests/kube-scheduler.yaml" and backing up old manifest to "/etc/kubernetes/tmp/kubeadm-backup-manifests-2025-08-05-16-44-22/kube-scheduler.yaml"
[upgrade/staticpods] Waiting for the kubelet to restart the component
[upgrade/staticpods] This can take up to 5m0s
[apiclient] Found 1 Pods for label selector component=kube-scheduler
[upgrade/staticpods] Component "kube-scheduler" upgraded successfully!
[upgrade/control-plane] The control plane instance for this node was successfully upgraded!
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upgrad/kubeconfig] The kubeconfig files for this node were successfully upgraded!
W0805 16:45:48.525458   72426 postupgrade.go:117] Using temporary directory /etc/kubernetes/tmp/kubeadm-kubelet-config665019520 for kubelet config. To override it set the environment variable KUBEADM_UPGRADE_DRYRUN_DIR
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config665019520/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade/kubelet-config] The kubelet configuration for this node was successfully upgraded!
[upgrade/bootstrap-token] Configuring bootstrap token and cluster-info RBAC rules
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade] SUCCESS! A control plane node of your cluster was upgraded to "v1.32.0".

[upgrade] Now please proceed with upgrading the rest of the nodes by following the right order.

controlplane ~ ➜  k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   91m   v1.33.0
node01         Ready    <none>          90m   v1.33.0
node02         Ready    <none>          90m   v1.33.0

controlplane ~ ➜  k drain controlplane --ignore-daemonsets 
node/controlplane cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/canal-f4q2f, kube-system/kube-proxy-pm5sr
evicting pod kube-system/calico-kube-controllers-5745477d4d-fbbmb
pod/calico-kube-controllers-5745477d4d-fbbmb evicted
node/controlplane drained

controlplane ~ ➜  sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y --allow-downgrades kubelet='1.32.0-*' kubectl='1.32.0-*' && \
sudo apt-mark hold kubelet kubectl
Canceled hold on kubelet.
Canceled hold on kubectl.
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                             
Hit:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  InRelease                                           
Hit:3 http://security.ubuntu.com/ubuntu jammy-security InRelease                                                                                  
Hit:4 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:5 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:6 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Selected version '1.32.0-1.1' (isv:kubernetes:core:stable:v1.32:pkgs.k8s.io [amd64]) for 'kubelet'
Selected version '1.32.0-1.1' (isv:kubernetes:core:stable:v1.32:pkgs.k8s.io [amd64]) for 'kubectl'
The following packages will be DOWNGRADED:
  kubectl kubelet
0 upgraded, 0 newly installed, 2 downgraded, 0 to remove and 10 not upgraded.
Need to get 26.4 MB of archives.
After this operation, 7,090 kB disk space will be freed.
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  kubectl 1.32.0-1.1 [11.3 MB]
Get:2 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  kubelet 1.32.0-1.1 [15.2 MB]
Fetched 26.4 MB in 1s (52.5 MB/s)
debconf: delaying package configuration, since apt-utils is not installed
dpkg: warning: downgrading kubectl from 1.33.0-1.1 to 1.32.0-1.1
(Reading database ... 20567 files and directories currently installed.)
Preparing to unpack .../kubectl_1.32.0-1.1_amd64.deb ...
Unpacking kubectl (1.32.0-1.1) over (1.33.0-1.1) ...
dpkg: warning: downgrading kubelet from 1.33.0-1.1 to 1.32.0-1.1
Preparing to unpack .../kubelet_1.32.0-1.1_amd64.deb ...
Unpacking kubelet (1.32.0-1.1) over (1.33.0-1.1) ...
Setting up kubectl (1.32.0-1.1) ...
Setting up kubelet (1.32.0-1.1) ...
kubelet set on hold.
kubectl set on hold.

controlplane ~ ➜  sudo systemctl daemon-reload
sudo systemctl restart kubelet

controlplane ~ ➜  k get no
NAME           STATUS                     ROLES           AGE   VERSION
controlplane   Ready,SchedulingDisabled   control-plane   94m   v1.32.0
node01         Ready                      <none>          94m   v1.33.0
node02         Ready                      <none>          93m   v1.33.0

controlplane ~ ➜  k uncordon controlplane 
node/controlplane uncordoned

controlplane ~ ➜  k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   95m   v1.32.0
node01         Ready    <none>          94m   v1.33.0
node02         Ready    <none>          94m   v1.33.0

controlplane ~ ➜  ssh controlplane
The authenticity of host 'controlplane (192.168.102.134)' can't be established.
ED25519 key fingerprint is SHA256:a4sl1treOVAPoI43lM0DAC6ScAAEYSyozNYWv1/mtJU.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'controlplane' (ED25519) to the list of known hosts.
root@controlplane's password: 


controlplane ~ ✖ ssh node01
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-1083-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

node01 ~ ➜  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernete
s.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /

node01 ~ ➜  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
File '/etc/apt/keyrings/kubernetes-apt-keyring.gpg' exists. Overwrite? (y/N) y

node01 ~ ➜  sudo apt update
Get:2 https://download.docker.com/linux/ubuntu jammy InRelease [48.8 kB]                                        
Get:3 http://security.ubuntu.com/ubuntu jammy-security InRelease [129 kB]                                                                            
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  InRelease [1,189 B]  
Get:4 https://download.docker.com/linux/ubuntu jammy/stable amd64 Packages [65.5 kB]                                    
Get:5 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  Packages [11.2 kB]      
Get:6 http://security.ubuntu.com/ubuntu jammy-security/universe amd64 Packages [1,270 kB]                              
Get:7 http://security.ubuntu.com/ubuntu jammy-security/main amd64 Packages [3,207 kB]
Get:8 http://security.ubuntu.com/ubuntu jammy-security/multiverse amd64 Packages [48.5 kB]
Get:9 http://security.ubuntu.com/ubuntu jammy-security/restricted amd64 Packages [5,103 kB]
Hit:10 http://archive.ubuntu.com/ubuntu jammy InRelease                                                                                                                   
Get:11 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [128 kB]                                                                                                  
Get:12 http://archive.ubuntu.com/ubuntu jammy-backports InRelease [127 kB]                                                                                                
Get:13 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages [3,518 kB]                                                                                      
Get:14 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 Packages [1,575 kB]                                                                                  
Get:15 http://archive.ubuntu.com/ubuntu jammy-updates/multiverse amd64 Packages [75.9 kB]                                                                                 
Get:16 http://archive.ubuntu.com/ubuntu jammy-updates/restricted amd64 Packages [5,290 kB]                                                                                
Get:17 http://archive.ubuntu.com/ubuntu jammy-backports/main amd64 Packages [83.2 kB]                                                                                     
Get:18 http://archive.ubuntu.com/ubuntu jammy-backports/universe amd64 Packages [35.2 kB]                                                                                 
Fetched 20.7 MB in 9s (2,295 kB/s)                                                                                                                                        
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
74 packages can be upgraded. Run 'apt list --upgradable' to see them.

node01 ~ ➜  exit
logout
Connection to node01 closed.

controlplane ~ ➜  k drain node01
node/node01 cordoned
error: unable to drain node "node01" due to error: cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): kube-system/canal-g8sck, kube-system/kube-proxy-9mj7s, continuing command...
There are pending nodes to be drained:
 node01
cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): kube-system/canal-g8sck, kube-system/kube-proxy-9mj7s

controlplane ~ ✖ k drain node01 --ignore-daemonsets 
node/node01 already cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/canal-g8sck, kube-system/kube-proxy-9mj7s
evicting pod kube-system/coredns-668d6bf9bc-dprjf
evicting pod kube-system/calico-kube-controllers-5745477d4d-gcbj4
pod/calico-kube-controllers-5745477d4d-gcbj4 evicted
pod/coredns-668d6bf9bc-dprjf evicted
node/node01 drained

controlplane ~ ➜  ssh node01
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-1083-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Tue Aug  5 16:58:08 2025 from 192.168.102.134

node01 ~ ➜  sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y --allow-downgrades kubelet='1.32.0-*' kubectl='1.32.0-*' && \
sudo apt-mark hold kubelet kubectl
Canceled hold on kubelet.
Canceled hold on kubectl.
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                
Hit:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  InRelease                                                        
Hit:3 http://archive.ubuntu.com/ubuntu jammy InRelease                                                                                                         
Hit:4 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:5 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Hit:6 http://security.ubuntu.com/ubuntu jammy-security InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Selected version '1.32.0-1.1' (isv:kubernetes:core:stable:v1.32:pkgs.k8s.io [amd64]) for 'kubelet'
Selected version '1.32.0-1.1' (isv:kubernetes:core:stable:v1.32:pkgs.k8s.io [amd64]) for 'kubectl'
The following packages will be DOWNGRADED:
  kubectl kubelet
0 upgraded, 0 newly installed, 2 downgraded, 0 to remove and 74 not upgraded.
Need to get 26.4 MB of archives.
After this operation, 7,090 kB disk space will be freed.
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  kubectl 1.32.0-1.1 [11.3 MB]
Get:2 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  kubelet 1.32.0-1.1 [15.2 MB]
Fetched 26.4 MB in 1s (35.3 MB/s) 
debconf: delaying package configuration, since apt-utils is not installed
dpkg: warning: downgrading kubectl from 1.33.0-1.1 to 1.32.0-1.1
(Reading database ... 17482 files and directories currently installed.)
Preparing to unpack .../kubectl_1.32.0-1.1_amd64.deb ...
Unpacking kubectl (1.32.0-1.1) over (1.33.0-1.1) ...
dpkg: warning: downgrading kubelet from 1.33.0-1.1 to 1.32.0-1.1
Preparing to unpack .../kubelet_1.32.0-1.1_amd64.deb ...
Unpacking kubelet (1.32.0-1.1) over (1.33.0-1.1) ...
Setting up kubectl (1.32.0-1.1) ...
Setting up kubelet (1.32.0-1.1) ...
kubelet set on hold.
kubectl set on hold.

node01 ~ ➜  sudo systemctl daemon-reload
sudo systemctl restart kubelet

node01 ~ ➜  exit
logout
Connection to node01 closed.

controlplane ~ ➜  k get no
NAME           STATUS                     ROLES           AGE    VERSION
controlplane   Ready                      control-plane   106m   v1.32.0
node01         Ready,SchedulingDisabled   <none>          105m   v1.32.0
node02         Ready                      <none>          105m   v1.33.0

controlplane ~ ➜  k uncordon node01
node/node01 uncordoned

controlplane ~ ➜  k drain node02 --ignore-daemonsets 
node/node02 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/canal-h5krl, kube-system/kube-proxy-2s7rp
evicting pod kube-system/coredns-668d6bf9bc-hxhmw
evicting pod kube-system/calico-kube-controllers-5745477d4d-np82j
pod/calico-kube-controllers-5745477d4d-np82j evicted
pod/coredns-668d6bf9bc-hxhmw evicted
node/node02 drained

controlplane ~ ➜  ssh node02
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-1083-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

node02 ~ ➜  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernete
s.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /

node02 ~ ➜  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
File '/etc/apt/keyrings/kubernetes-apt-keyring.gpg' exists. Overwrite? (y/N) y

node02 ~ ➜  sudo apt update
Get:2 https://download.docker.com/linux/ubuntu jammy InRelease [48.8 kB]                                                                   
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  InRelease [1,189 B]                                                         
Get:3 https://download.docker.com/linux/ubuntu jammy/stable amd64 Packages [65.5 kB]                                                             
Get:4 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  Packages [11.2 kB]                          
Hit:5 http://archive.ubuntu.com/ubuntu jammy InRelease                                                                                     
Get:6 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [128 kB]
Get:7 http://security.ubuntu.com/ubuntu jammy-security InRelease [129 kB]
Get:8 http://archive.ubuntu.com/ubuntu jammy-backports InRelease [127 kB]                                                                                                 
Get:9 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 Packages [1,575 kB]                                                                                   
Get:10 http://security.ubuntu.com/ubuntu jammy-security/universe amd64 Packages [1,270 kB]                                                                                
Get:11 http://archive.ubuntu.com/ubuntu jammy-updates/multiverse amd64 Packages [75.9 kB]                                                                                 
Get:12 http://archive.ubuntu.com/ubuntu jammy-updates/restricted amd64 Packages [5,290 kB]                                                                                
Get:13 http://security.ubuntu.com/ubuntu jammy-security/restricted amd64 Packages [5,103 kB]                                                                              
Get:14 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 Packages [3,518 kB]                                                                                      
Get:15 http://archive.ubuntu.com/ubuntu jammy-backports/universe amd64 Packages [35.2 kB]                                                                                 
Get:16 http://archive.ubuntu.com/ubuntu jammy-backports/main amd64 Packages [83.2 kB]                                                                                     
Get:17 http://security.ubuntu.com/ubuntu jammy-security/main amd64 Packages [3,207 kB]                                                                                    
Get:18 http://security.ubuntu.com/ubuntu jammy-security/multiverse amd64 Packages [48.5 kB]                                                                               
Fetched 20.7 MB in 9s (2,254 kB/s)                                                                                                                                        
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
74 packages can be upgraded. Run 'apt list --upgradable' to see them.

node02 ~ ➜  sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y --allow-downgrades kubelet='1.32.0-*' kubectl='1.32.0-*' && \
sudo apt-mark hold kubelet kubectl
Canceled hold on kubelet.
Canceled hold on kubectl.
Hit:2 https://download.docker.com/linux/ubuntu jammy InRelease                                                             
Hit:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  InRelease                          
Hit:3 http://archive.ubuntu.com/ubuntu jammy InRelease                                                                         
Hit:4 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:5 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Hit:6 http://security.ubuntu.com/ubuntu jammy-security InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Selected version '1.32.0-1.1' (isv:kubernetes:core:stable:v1.32:pkgs.k8s.io [amd64]) for 'kubelet'
Selected version '1.32.0-1.1' (isv:kubernetes:core:stable:v1.32:pkgs.k8s.io [amd64]) for 'kubectl'
The following packages will be DOWNGRADED:
  kubectl kubelet
0 upgraded, 0 newly installed, 2 downgraded, 0 to remove and 74 not upgraded.
Need to get 26.4 MB of archives.
After this operation, 7,090 kB disk space will be freed.
Get:1 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  kubectl 1.32.0-1.1 [11.3 MB]
Get:2 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.32/deb  kubelet 1.32.0-1.1 [15.2 MB]
Fetched 26.4 MB in 0s (55.8 MB/s) 
debconf: delaying package configuration, since apt-utils is not installed
dpkg: warning: downgrading kubectl from 1.33.0-1.1 to 1.32.0-1.1
(Reading database ... 17482 files and directories currently installed.)
Preparing to unpack .../kubectl_1.32.0-1.1_amd64.deb ...
Unpacking kubectl (1.32.0-1.1) over (1.33.0-1.1) ...
dpkg: warning: downgrading kubelet from 1.33.0-1.1 to 1.32.0-1.1
Preparing to unpack .../kubelet_1.32.0-1.1_amd64.deb ...
Unpacking kubelet (1.32.0-1.1) over (1.33.0-1.1) ...
Setting up kubectl (1.32.0-1.1) ...
Setting up kubelet (1.32.0-1.1) ...
kubelet set on hold.
kubectl set on hold.

node02 ~ ➜  sudo systemctl daemon-reload
sudo systemctl restart kubelet

node02 ~ ➜  exit
logout
Connection to node02 closed.

controlplane ~ ➜  k get no
NAME           STATUS                     ROLES           AGE    VERSION
controlplane   Ready                      control-plane   110m   v1.32.0
node01         Ready                      <none>          109m   v1.32.0
node02         Ready,SchedulingDisabled   <none>          109m   v1.32.0

controlplane ~ ➜  k uncordon node02
node/node02 uncordoned

controlplane ~ ➜  k get no -o wide
NAME           STATUS   ROLES           AGE    VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
controlplane   Ready    control-plane   110m   v1.32.0   192.168.102.134   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node01         Ready    <none>          110m   v1.32.0   192.168.102.186   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node02         Ready    <none>          110m   v1.32.0   192.168.102.99    <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26

controlplane ~ ➜  k run nginx --image nginx
pod/nginx created

controlplane ~ ➜  k get po -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          7s    172.17.2.7   node02   <none>           <none>

controlplane ~ ➜
```
