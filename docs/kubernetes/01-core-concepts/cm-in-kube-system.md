Most of the **ConfigMaps** (`cm`) you see in `kube-system` are not created manually but generated automatically during cluster bootstrapping (via `kubeadm`, add-ons, or the control plane components themselves). Let’s break them down one by one so you can see **how they’re formed** and what files/configs contributed:

## 📌 Breakdown of ConfigMaps in `kube-system`

1. **`canal-config`**

   * Created by: **Calico/Canal CNI plugin** when deployed.
   * Source: The YAML manifest you applied for **Canal** includes a `ConfigMap` defining network settings (like CNI conf, Felix, etc.).
   * Example: It usually contains CNI network settings (pod CIDR, backend type, etc.).

2. **`coredns`**

   * Created by: The **CoreDNS add-on** deployed by kubeadm.
   * Source: From the CoreDNS YAML manifest (`/etc/kubernetes/addons/coredns.yaml` or downloaded from `k8s.gcr.io`).
   * Contents: The CoreDNS **Corefile**, which defines DNS server configuration.

3. **`extension-apiserver-authentication`**

   * Created by: **kube-apiserver**.
   * Source: kube-apiserver writes it automatically when it starts.
   * Contents: Authentication-related config (client CA, request header settings) used by aggregated API servers (like metrics-server).

4. **`kube-apiserver-legacy-service-account-token-tracking`**

   * Created by: **kube-apiserver**.
   * Purpose: Helps track usage of legacy service account tokens.
   * Source: Internal kube-apiserver process, not from a manifest.

5. **`kube-proxy`**

   * Created by: kubeadm when deploying the **kube-proxy DaemonSet**.
   * Source: Generated from `kubeadm-config` during `kubeadm init`.
   * Contents: Proxy mode, cluster CIDR, iptables/ipvs config, etc.

6. **`kube-root-ca.crt`**

   * Created by: The **Controller Manager**.
   * Source: Automatically injected into every namespace so pods can talk to the API server securely.
   * Contents: Cluster root CA certificate.
   * `cat /etc/kubernetes/pki/ca.crt`
     

7. **`kubeadm-config`**

   * Created by: **kubeadm** during `kubeadm init`.
   * Source: Whatever you passed in your `kubeadm init` config file (like `ClusterConfiguration`, `InitConfiguration`).
   * Contents: Cluster-wide settings (API server, networking, certificates directory, etc.).

8. **`kubelet-config`**     

   * Created by: **kubeadm**.
   * Source: Derived from your kubeadm init configuration.
   * Contents: The Kubelet’s configuration (cgroup driver, TLS settings, cluster DNS, etc.).
   * Used by the `kubelet-config-x.y` ConfigMap, which kubeadm uses for upgrading kubelet configs.
   * `cat /var/lib/kubelet/config.yaml`

---

### ⚙️ So, how are they formed?

* **kubeadm init** generates some (`kubeadm-config`, `kubelet-config`, `kube-proxy`).
* **Add-ons** you applied (like Canal, CoreDNS) create their own ConfigMaps from YAML manifests.
* **Control plane components** (`kube-apiserver`, `controller-manager`) create and maintain some automatically (`extension-apiserver-authentication`, `kube-root-ca.crt`, etc.).

👉 So yes, you’re right — **some came from files you (or kubeadm) applied**, others are **generated dynamically** by the control plane.

---


## 📌 ConfigMaps in `kube-system` (CKA Prep)

| ConfigMap                                                | Who Creates It          | Source Type                             | Where Values Come From / File Path                                                                            | What You Might Need It For in CKA                                       |
| -------------------------------------------------------- | ----------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| **canal-config**                                         | Canal (CNI) add-on      | **Literal YAML** (inline)               | Part of `canal.yaml` manifest (downloaded/applied)                                                            | Check **Pod CIDR**, CNI backend configs                                 |
| **coredns**                                              | CoreDNS add-on          | **Literal YAML** (inline)               | From the `coredns.yaml` addon manifest (applied by kubeadm)                                                   | Confirm **cluster DNS IP** (`.spec.dnsPolicy`, `stubDomains`, etc.)     |
| **extension-apiserver-authentication**                   | kube-apiserver          | **Files**                               | From `/etc/kubernetes/pki/ca.crt`, `/etc/kubernetes/pki/front-proxy-ca.crt`, request-header args              | Needed if troubleshooting **auth for metrics-server / API aggregation** |
| **kube-apiserver-legacy-service-account-token-tracking** | kube-apiserver          | **Internal (runtime state)**            | Generated internally by API server                                                                            | Rarely needed; can be ignored in CKA                                    |
| **kube-proxy**                                           | kubeadm                 | **Literal (generated)**                 | Derived from `ClusterConfiguration` in kubeadm → applied as ConfigMap                                         | Check **mode (iptables/ipvs)**, cluster CIDR, proxy settings            |
| **kube-root-ca.crt**                                     | kube-controller-manager | **File**                                | From `/etc/kubernetes/pki/ca.crt` (cluster CA)                                                                | Verify cluster CA being injected into pods; cert troubleshooting        |
| **kubeadm-config**                                       | kubeadm                 | **Literal (or file if you passed one)** | - If you gave kubeadm a config file → it’s stored here.  <br> - If not → kubeadm’s defaults are written here. | Useful to check **podSubnet**, `serviceSubnet`, image repo, etc.        |
| **kubelet-config**                                       | kubeadm                 | **Literal (generated)**                 | kubeadm renders kubelet defaults into ConfigMap (`kubelet-config-x.y`)                                        | Inspect kubelet params: **cgroupDriver**, cluster DNS, TLS, etc.        |

---

### 🎯 Exam Angle (CKA)

* If the question asks you to confirm **Pod CIDR / Service CIDR** →
  🔍 `kubectl get cm kubeadm-config -n kube-system -o yaml`

* If you need **DNS cluster IP** or DNS config →
  🔍 `kubectl get cm coredns -n kube-system -o yaml`

* If troubleshooting **CNI networking** →
  🔍 `kubectl get cm canal-config -n kube-system -o yaml`

* If checking **kubelet configuration** →
  🔍 `kubectl get cm kubelet-config -n kube-system -o yaml`

* If dealing with **API aggregation / metrics-server errors** →
  🔍 `kubectl get cm extension-apiserver-authentication -n kube-system -o yaml`

---

⚡ So the shortcut for CKA is:

* **Cluster networking values** → `kubeadm-config`, `canal-config`
* **Cluster DNS values** → `coredns`
* **Kubelet params** → `kubelet-config`
* **Certs/aggregation** → `extension-apiserver-authentication`, `kube-root-ca.crt`

---

### 📌 kube-proxy Config Summary (CKA Prep)

1. **Where does the config come from?**

   * `kube-proxy` uses a **ConfigMap** in the `kube-system` namespace called **`kube-proxy`**.
   * This ConfigMap has two keys:

     * **`config.conf`** → `KubeProxyConfiguration` (mode: iptables/ipvs, clusterCIDR, etc.)
     * **`kubeconfig.conf`** → kubeconfig for talking to the API server.

2. **Are these real files on the host?**

   * ❌ No.
   * On the **host node**, `/var/lib/kube-proxy/` does **not exist**.
   * These keys are mounted as **virtual files only inside the kube-proxy Pod container**.

3. **Where do they appear?**

   * Inside each kube-proxy Pod at:

     ```
     /var/lib/kube-proxy/config.conf
     /var/lib/kube-proxy/kubeconfig.conf
     ```
   * Mounted by the DaemonSet from the `kube-proxy` ConfigMap.
   * That’s why the container’s `--config` flag points to `/var/lib/kube-proxy/config.conf`.

4. **How to inspect them?**

   * From the cluster (fastest):

     ```bash
     kubectl -n kube-system get cm kube-proxy -o yaml
     ```
   * From inside a Pod (runtime view):

     ```bash
     kubectl -n kube-system exec -it <kube-proxy-pod> -- cat /var/lib/kube-proxy/config.conf
     ```

5. **CKA exam angle:**

   * If asked about **proxy mode**, **clusterCIDR**, or how kube-proxy connects to the API server → check the **`kube-proxy` ConfigMap**.
   * Don’t waste time searching `/etc/kubernetes/` or `/var/lib/` on the host — these files only live in the kube-proxy Pod.

---

✅ **Final takeaway:**
`config.conf` and `kubeconfig.conf` are **not host files**. They are **keys in the `kube-proxy` ConfigMap**, which Kubernetes mounts into the kube-proxy Pods at `/var/lib/kube-proxy/`. To check them in the exam, read the ConfigMap (`kubectl get cm`) or exec into a kube-proxy Pod — not on the host.

