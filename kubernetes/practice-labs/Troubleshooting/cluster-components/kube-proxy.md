## Kube-proxy

```bash
root@controlplane ~ ➜  k get no
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   12m   v1.33.0

root@controlplane ~ ➜  k get po -n kube-system kube-proxy-7c4nn 
NAME               READY   STATUS             RESTARTS      AGE
kube-proxy-7c4nn   0/1     CrashLoopBackOff   3 (45s ago)   86s

root@controlplane ~ ➜  k logs -n kube-system kube-proxy-7c4nn 
E1007 21:05:58.635373       1 run.go:74] "command failed" err="failed complete: open /var/lib/kube-proxy/configuration.conf: no such file or directory"

root@controlplane ~ ➜  ls /var/lib/kube-proxy/
kubeconfig.conf

root@controlplane ~ ➜  cat /var/lib/kube-proxy/kubeconfig.conf 
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    server: https://controlplane:6443
  name: default
contexts:
- context:
    cluster: default
    namespace: default
    user: default
  name: default
current-context: default
users:
- name: default
  user:
    tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token

root@controlplane ~ ➜  k get po -n kube-system kube-proxy-7c4nn -o yaml | grep command -A 5
  - command:
    - /usr/local/bin/kube-proxy
    - --config=/var/lib/kube-proxy/configuration.conf
    - --hostname-override=$(NODE_NAME)
    env:
    - name: NODE_NAME

root@controlplane ~ ➜  k get cm -n kube-system 
NAME                                                   DATA   AGE
coredns                                                1      17m
extension-apiserver-authentication                     6      17m
kube-apiserver-legacy-service-account-token-tracking   1      17m
kube-proxy                                             2      17m
kube-root-ca.crt                                       1      16m
kubeadm-config                                         1      17m
kubelet-config                                         1      17m
weave-net                                              0      16m

root@controlplane ~ ➜  k describe cm -n kube-system kube-proxy 
Name:         kube-proxy
Namespace:    kube-system
Labels:       app=kube-proxy
Annotations:  kubeadm.kubernetes.io/component-config.hash: sha256:906b8697200819e8263843f43965bb3614545800b82206dcee8ef93a08bc4f4b

Data
====
config.conf:
----
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
bindAddressHardFail: false
clientConnection:
  acceptContentTypes: ""
  burst: 0
  contentType: ""
  kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
  qps: 0
clusterCIDR: 10.244.0.0/16
configSyncPeriod: 0s
conntrack:
  maxPerCore: null
  min: null
  tcpBeLiberal: false
  tcpCloseWaitTimeout: null
  tcpEstablishedTimeout: null
  udpStreamTimeout: 0s
  udpTimeout: 0s
detectLocal:
  bridgeInterface: ""
  interfaceNamePrefix: ""
detectLocalMode: ""
enableProfiling: false
healthzBindAddress: ""
hostnameOverride: ""
iptables:
  localhostNodePorts: null
  masqueradeAll: false
  masqueradeBit: null
  minSyncPeriod: 0s
  syncPeriod: 0s
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: ""
  strictARP: false
  syncPeriod: 0s
  tcpFinTimeout: 0s
  tcpTimeout: 0s
  udpTimeout: 0s
kind: KubeProxyConfiguration
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
    text:
      infoBufferSize: "0"
  verbosity: 0
metricsBindAddress: ""
mode: ""
nftables:
  masqueradeAll: false
  masqueradeBit: null
  minSyncPeriod: 0s
  syncPeriod: 0s
nodePortAddresses: null
oomScoreAdj: null
portRange: ""
showHiddenMetricsForVersion: ""
winkernel:
  enableDSR: false
  forwardHealthCheckVip: false
  networkName: ""
  rootHnsEndpointName: ""
  sourceVip: ""

kubeconfig.conf:
----
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    server: https://controlplane:6443
  name: default
contexts:
- context:
    cluster: default
    namespace: default
    user: default
  name: default
current-context: default
users:
- name: default
  user:
    tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token


BinaryData
====

Events:  <none>

root@controlplane ~ ➜  k edit ds -n kube-system kube-proxy 
daemonset.apps/kube-proxy edited

root@controlplane ~ ➜  k get po -n kube-system kube-proxy-7c4nn -o yaml | grep command -A 3
Error from server (NotFound): pods "kube-proxy-7c4nn" not found

root@controlplane ~ ✖ k get po -n kube-system kube-proxy-9dt2c -o yaml | grep command -A 3
  - command:
    - /usr/local/bin/kube-proxy
    - --config=/var/lib/kube-proxy/config.conf                          # made change here
    - --hostname-override=$(NODE_NAME)

root@controlplane ~ ➜  k get po -n kube-system kube-proxy-9dt2c 
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-9dt2c   1/1     Running   0          85s

root@controlplane ~ ➜   
```

Perfect — you’ve collected all the key clues here. Let’s analyze this step-by-step and fix the `kube-proxy` CrashLoopBackOff issue.

### 🧩 Problem Summary

Your `kube-proxy` pod is crashing with this error:

```
failed complete: open /var/lib/kube-proxy/configuration.conf: no such file or directory
```

But when we check your node:

```
/var/lib/kube-proxy/
└── kubeconfig.conf
```

➡️ The **`configuration.conf`** file (which kube-proxy expects) is missing.

### 🧠 Root Cause

From the Pod definition:

```
--config=/var/lib/kube-proxy/configuration.conf
```

But in your ConfigMap (`kube-proxy`), this configuration file is actually named **`config.conf`**, not `configuration.conf`.

So:

* Kube-proxy tries to read `/var/lib/kube-proxy/configuration.conf`
* But the mounted ConfigMap only provides `/var/lib/kube-proxy/config.conf`
* Hence the **“no such file or directory”** error.

### 🛠️ How to Fix

You have **two possible fixes**, choose one:

#### ✅ Option 1 (Recommended): Match the flag to the file name

Edit the kube-proxy DaemonSet to use the correct filename (`config.conf`).

```bash
kubectl -n kube-system edit daemonset kube-proxy
```

Find the section like this:

```yaml
command:
  - /usr/local/bin/kube-proxy
  - --config=/var/lib/kube-proxy/configuration.conf
  - --hostname-override=$(NODE_NAME)
```

👉 Change it to:

```yaml
command:
  - /usr/local/bin/kube-proxy
  - --config=/var/lib/kube-proxy/config.conf
  - --hostname-override=$(NODE_NAME)
```

Then save and exit.

Kubernetes will automatically restart the DaemonSet pods.

---

### 🔍 The two different files

There are **two separate configuration files** involved in kube-proxy:

| File                                                        | Purpose                                                                                                                        | Source                                                                  |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| `/var/lib/kube-proxy/config.conf` (or `configuration.conf`) | **KubeProxyConfiguration** — main config that tells kube-proxy how to behave (mode, clusterCIDR, iptables/IPVS settings, etc.) | Comes from the **ConfigMap** `kube-proxy`                               |
| `/var/lib/kube-proxy/kubeconfig.conf`                       | **Kubeconfig** — tells kube-proxy *how to talk to the API server* (credentials, server URL, CA, token)                         | Mounted as a separate file, or referenced *inside* the ConfigMap config |

### 🧠 Why `--config` should point to `config.conf`, not `kubeconfig.conf`

* The `--config` flag **expects a `KubeProxyConfiguration` object**, not a kubeconfig file.
* Inside that `KubeProxyConfiguration`, there’s a line:

  ```yaml
  clientConnection:
    kubeconfig: /var/lib/kube-proxy/kubeconfig.conf
  ```

  👆 This tells kube-proxy where to find the kubeconfig (API access credentials).

So, kube-proxy first reads:

```
--config=/var/lib/kube-proxy/config.conf
```

And *from within that file*, it finds:

```
clientConnection.kubeconfig=/var/lib/kube-proxy/kubeconfig.conf
```

That’s why:

* ✅ `/var/lib/kube-proxy/config.conf` (from ConfigMap) → the main config
* ✅ `/var/lib/kube-proxy/kubeconfig.conf` (mounted) → API credentials

### 🧩 So in summary:

* Your intuition was right to ask about `kubeconfig.conf`,
* But the binary’s `--config` flag points to the *main config*, which **internally references** `kubeconfig.conf`.

That’s why we don’t point directly to it.

