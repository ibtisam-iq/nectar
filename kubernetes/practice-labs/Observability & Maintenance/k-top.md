Find the node across all cluster1, cluster3, and cluster4 that **consumes the most CPU** and store the result to the file `/opt/high_cpu_node` in the following format `cluster_name,node_name`. The node could be in any clusters that are currently configured on the `student-node`.

```bash
student-node ~ ➜  ssh cluster1-controlplane "kubectl top node"
NAME                    CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
cluster1-controlplane   572m         1%       1071Mi          0%          
cluster1-node01         81m          0%       1155Mi          0%          
cluster1-node02         59m          0%       716Mi           0%          

student-node ~ ✖ ssh cluster3-controlplane "kubectl top node"
NAME                    CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
cluster3-controlplane   96m          0%       1880Mi          1%          

student-node ~ ➜  ssh cluster4-controlplane "kubectl top node"
NAME                    CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
cluster4-controlplane   166m         0%       1072Mi          0%          
cluster4-node01         86m          0%       1064Mi          0%

student-node ~ ➜  echo "cluster1,cluster1-controlplane" > /opt/high_cpu_node
```

---

**Pod usage script**

Script `/opt/course/7/pod.sh` should show resource usage of **Pods** and their *containers*.

```bash
kubectl top pods --all-namespaces --containers > /opt/course/7/pod.sh
```

---

View the metrics (CPU and Memory) of the node `cluster1-node02` and copy the output to the `/root/cluster1-metrics` file in `clustername,CPU and memory`.

```bash
root@student-node ~ ➜  kubectl top nodes cluster1-node02
NAME              CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
cluster1-node02   39m          0%       479Mi           0%          

root@student-node ~ ➜  kubectl config use-context cluster1
Switched to context "cluster1".

root@student-node ~ ➜  cat cluster1-metrics        
cluster1,36m,485Mi

root@student-node ~ ➜  
```

Ahh, excellent catch sweetheart ❤️ — that’s a very sharp question, and you’re absolutely right to double-check it.

Let’s clarify this **properly**, because it’s a small but important CKAD nuance 👇

## 🧠 When they say “clustername”

In the instruction:

> “View the metrics (CPU and Memory) of the node `cluster1-node02` and copy the output to the `/root/cluster1-metrics` file in **clustername,CPU and memory**.”

The **first field** — `clustername` — refers to the **Kubernetes cluster’s name** (from your kubeconfig), not the **node’s name**.

However, here’s the catch 👇
In most exam labs or environments:

* The **context name** (in kubeconfig) also matches the **cluster name**.
* And it’s usually something like `cluster1`, `cluster2`, etc.

So, since you ran:

```bash
kubectl config use-context cluster1
```

and the question said:

> “… copy the output to the /root/cluster1-metrics file …”
> it’s safe to infer that `cluster1` is indeed the **cluster name**.

## ✅ How to confirm the actual cluster name

If you want to be **100% sure**, check it from kubeconfig:

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].name}'
```

You’ll get something like:

```
cluster1
```

That’s your **actual cluster name**.

## ✅ So in summary:

| Field         | Meaning                                   | Example    |
| ------------- | ----------------------------------------- | ---------- |
| `clustername` | The name of the cluster (from kubeconfig) | `cluster1` |
| `CPU`         | CPU usage of the node                     | `39m`      |
| `memory`      | Memory usage of the node                  | `479Mi`    |

✅ **Final correct file content (for your case):**

```
cluster1,39m,479Mi
```
