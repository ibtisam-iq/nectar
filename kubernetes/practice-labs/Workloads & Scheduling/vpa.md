## Q1
Create a VPA named `cache-vpa` for a stateful application named `cache-statefulset` in the `caching` namespace. The VPA should set optimal CPU and memory requests for newly created pods but must not evict existing pods. Configure the VPA to operate in `Initial` mode to achieve this behavior.

```bash
cluster2-controlplane ~ ➜  vi 7.yaml

cluster2-controlplane ~ ➜  k apply -f 7.yaml 
verticalpodautoscaler.autoscaling.k8s.io/cache-vpa created

cluster2-controlplane ~ ➜  k get vpa -n caching 
NAME        MODE      CPU   MEM   PROVIDED   AGE
cache-vpa   Initial                          10s

cluster2-controlplane ~ ➜  k get statefulsets.apps -n caching 
NAME                READY   AGE
cache-statefulset   3/3     5m35s

cluster2-controlplane ~ ➜  cat 7.yaml 
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
    name: cache-vpa
    namespace: caching
spec:
    targetRef:
        apiVersion: "apps/v1"
        kind: StatefulSet
        name: cache-statefulset
    updatePolicy:
      updateMode: "Initial"

cluster2-controlplane ~ ➜  kubectl describe vpa cache-vpa -n caching
Name:         cache-vpa
Namespace:    caching
Labels:       <none>
Annotations:  <none>
API Version:  autoscaling.k8s.io/v1
Kind:         VerticalPodAutoscaler
Metadata:
  Creation Timestamp:  2025-09-14T14:33:59Z
  Generation:          1
  Resource Version:    11579
  UID:                 47d37403-ef75-4285-8abe-e3a66b3f65da
Spec:
  Target Ref:
    API Version:  apps/v1
    Kind:         StatefulSet
    Name:         cache-statefulset
  Update Policy:
    Update Mode:  Initial
Status:
  Conditions:
    Last Transition Time:  2025-09-14T14:34:14Z
    Status:                True
    Type:                  RecommendationProvided
  Recommendation:
    Container Recommendations:
      Container Name:  cache-container
      Lower Bound:
        Cpu:     25m
        Memory:  262144k
      Target:
        Cpu:     25m
        Memory:  262144k
      Uncapped Target:
        Cpu:     25m
        Memory:  262144k
      Upper Bound:
        Cpu:     2284m
        Memory:  2388533492
Events:          <none>

cluster2-controlplane ~ ✖ kubectl get  vpa cache-vpa -n caching
NAME        MODE      CPU   MEM       PROVIDED   AGE
cache-vpa   Initial   25m   262144k   True       3m
```

Perfect execution sweetheart ❤️

Let’s break down what you did and why it’s correct:

### 🔎 What this does

* **`targetRef`** → points to your `cache-statefulset` (correct).
* **`updateMode: Initial`** →

  * VPA **only sets requests/limits on pod creation**.
  * No live evictions of existing pods.
  * Exactly what the question asked.
* VPA controller will watch usage → recommend/request **CPU & memory** for new pods.

### 📊 Current status

```
k get vpa -n caching
NAME        MODE      CPU   MEM   PROVIDED   AGE
cache-vpa   Initial                          10s
```

* `MODE` shows **Initial** → ✅ correct.
* `CPU / MEM` empty now because VPA needs time & metrics to generate recommendations.
* After a few minutes, run:

  ```bash
  kubectl describe vpa cache-vpa -n caching
  ```

  → you’ll see **recommendations** (like `cpu: 100m → 300m`, `memory: 256Mi → 512Mi`).

### 🚀 Next Steps

* If you **delete one of the cache pods**, the new pod created by the StatefulSet will come up with the **recommended CPU/memory** requests.
* Existing pods stay untouched because of `Initial` mode.

---

## Q2

Create a VPA named `api-vpa` in `Auto` Mode for a deployment named `api-deployment` in the `services` namespace. The VPA should automatically adjust CPU and memory requests but must ensure that the **CPU requests do not exceed 1 cores and memory requests do not exceed 1Gi**. Additionally, set a minimum CPU request of `600m` and a minimum memory request of `600Mi`. The **containerName** in VPA should explicitly match the container name inside `api-deployment`.

```bash
cluster1-controlplane ~ ➜  k get deploy -n services api-deployment -o yaml | grep -i containers -5
    spec:
      containers:
        name: api-container

cluster1-controlplane ~ ➜  vi 5.yaml

cluster1-controlplane ~ ➜  k apply -f 5.yaml 
verticalpodautoscaler.autoscaling.k8s.io/api-vpa created

cluster1-controlplane ~ ➜  k get vpa -n services 
NAME      MODE   CPU    MEM     PROVIDED   AGE
api-vpa   Auto   600m   600Mi   True       2m17s

cluster1-controlplane ~ ➜  cat 5.yaml 
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
    name: api-vpa
    namespace: services
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: api-deployment
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: api-container
      minAllowed:
        cpu: 600m
        memory: 600Mi
      maxAllowed:
        cpu: 1
        memory: 1Gi
      controlledResources: ["cpu", "memory"]

cluster1-controlplane ~ ➜  
```
