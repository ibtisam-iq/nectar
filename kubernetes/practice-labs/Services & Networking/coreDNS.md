## CoreDNS Config Backup

* **CoreDNS actually runs as a Deployment** in `kube-system`.

  ```bash
  kubectl get deploy -n kube-system coredns
  ```

  will show the Deployment that manages the Pods.

* But the **configuration of CoreDNS** (the `Corefile`) is stored in a **ConfigMap** named `coredns`.
  The Deployment just mounts this ConfigMap into the Pods.

### So:

* If the exam asks about **CoreDNS config backup** → you back up the **ConfigMap**.

  ```bash
  kubectl get cm coredns -n kube-system -o yaml > /opt/course/16/coredns_backup.yaml
  ```

* If they specifically ask for the **Deployment manifest** → you’d back up the Deployment YAML:

  ```bash
  kubectl get deploy coredns -n kube-system -o yaml > /opt/course/16/coredns_deploy_backup.yaml
  ```

🔑 **Exam tip:**

* **ConfigMap** → CoreDNS settings (Corefile).
* **Deployment** → How CoreDNS Pods run (replicas, containers, resources, etc.).

---

## Update Cluster Domain

The CoreDNS configuration in the cluster needs to be updated:

Update the CoreDNS configuration in the cluster so that DNS resolution for cka.local works exactly like cluster.local and in addition to it.


Test your configuration using the jrecord/nettools image by executing the following commands:

`nslookup kubernetes.default.svc.cluster.local`
`nslookup kubernetes.default.svc.cka.local`

Perfect CKA-style task, sweetheart ❤️ Let’s solve it step by step.

## 🔧 Step 1: Edit the CoreDNS ConfigMap

The CoreDNS configuration lives in a ConfigMap called `coredns` in the `kube-system` namespace.

Open it:

```bash
kubectl -n kube-system edit configmap coredns
```

Inside you’ll see a section like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        ...
    }
```

---

## 🔧 Step 2: Add `cka.local`

Change the **`kubernetes` plugin line** to include both domains:

```diff
-        kubernetes cluster.local in-addr.arpa ip6.arpa {
+        kubernetes cluster.local cka.local in-addr.arpa ip6.arpa {
             pods insecure
             fallthrough in-addr.arpa ip6.arpa
             ttl 30
         }
```

Save and exit.
Kubernetes will automatically restart the CoreDNS pods after the ConfigMap update.

---

## 🔧 Step 3: Verify CoreDNS Pods Restart

```bash
kubectl -n kube-system rollout restart deployment coredns
kubectl -n kube-system get pods -l k8s-app=kube-dns
```

Wait until the CoreDNS pods are `Running`.

---

## 🔧 Step 4: Test with nettools

Run a temporary pod:

```bash
kubectl run -it --rm nettools --image=jrecord/nettools --restart=Never -- /bin/sh
```

Inside the pod, run:

```bash
nslookup kubernetes.default.svc.cluster.local
nslookup kubernetes.default.svc.cka.local
```

✅ Both should resolve to the **same cluster IP**.

---

```bash
cluster3-controlplane ~ ➜  kubectl -n kube-system edit configmap coredns
configmap/coredns edited

cluster3-controlplane ~ ➜  kubectl -n kube-system rollout restart deployment coredns
deployment.apps/coredns restarted

cluster3-controlplane ~ ➜  kubectl -n kube-system get pods -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-58849b6465-d8tpj   1/1     Running   0          20s

cluster3-controlplane ~ ➜  kubectl run -it --rm nettools --image=jrecord/nettools --restart=Never -- /bin/sh
If you don't see a command prompt, try pressing enter.
sh-4.4# nslookup kubernetes.default.svc.cluster.local
Server:         10.43.0.10
Address:        10.43.0.10#53

Name:   kubernetes.default.svc.cluster.local
Address: 10.43.0.1

sh-4.4# nslookup kubernetes.default.svc.cka.local
Server:         10.43.0.10
Address:        10.43.0.10#53

Name:   kubernetes.default.svc.cka.local
Address: 10.43.0.1

sh-4.4# e
```
