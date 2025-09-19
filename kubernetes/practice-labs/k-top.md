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
