# 🎯 Affinity / Anti-Affinity – Quick Rules

## 🔹 1. Node Affinity

* Mentions **node(s)** → it’s node affinity.
* Look for `nodeSelectorTerms` + `matchExpressions`.
* Example:

  * `"run only on node with label disktype=ssd"`.

## 🔹 2. Pod Affinity

* Mentions **pods / pod labels** → it’s pod affinity.
* Schedule **close to** other pods (same node / topology key).
* Example:

  * `"run with pods having app=frontend"`.

## 🔹 3. Pod Anti-Affinity

* Mentions **pods but keep apart** → pod anti-affinity.
* Example:

  * `"don’t run on same node as app=backend"`.
* Key:

  * `podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution` → **strict rule** (forces 1 per node).

## 🔹 4. Preferred vs Required

* **preferred** → soft rule (scheduler tries, but not guaranteed).
* **required** → hard rule (scheduler must obey).

✅ **Exam Trick**:

* If question says *"spread pods across nodes"* → **podAntiAffinity (required)**.
* If question says *"co-locate pods with X"* → **podAffinity**.
* If question says *"only on certain nodes"* → **nodeAffinity**.
* If questions says *prefer.. perferable*  → **preferred** → soft rule
* Run `k get no --show-lables` to check **labels** first, otherwise label the node. 

---

## Q1

There is a Pod YAML provided at `/root/hobby.yaml`. That Pod should be **preferred** to be only scheduled on Nodes where Pods with label `level=restricted` are running. For the topologyKey use `kubernetes.io/hostname`. There are no taints on any Nodes which means no tolerations are needed.

```bash

controlplane:~$ k get po --show-labels 
NAME         READY   STATUS    RESTARTS   AGE    LABELS
restricted   1/1     Running   0          115s   level=restricted
controlplane:~$ k get po --show-labels -o wide
NAME         READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES   LABELS
restricted   1/1     Running   0          2m14s   192.168.1.4   node01   <none>           <none>            level=restricted
controlplane:~$ vi hobby.yaml 
controlplane:~$ k apply -f hobby.yaml 
pod/hobby-project created
controlplane:~$ k get po -o wide
NAME            READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
hobby-project   1/1     Running   0          11s   192.168.1.5   node01   <none>           <none>
restricted      1/1     Running   0          13m   192.168.1.4   node01   <none>           <none>

Extend the provided YAML at /root/hobby.yaml :

  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: level
              operator: In
              values:
              - restricted
          topologyKey: kubernetes.io/hostname

Another way to solve the same requirement would be:

...
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              level: restricted
          topologyKey: kubernetes.io/hostname
```

---

## Q2

That Pod should be **required** to be only scheduled on Nodes where no Pods with label `level=restricted` are running.

For the topologyKey use `kubernetes.io/hostname`.

There are no taints on any Nodes which means no tolerations are needed.


```bash
controlplane:~$ vi hobby.yaml
 
controlplane:~$ k get po -o wide --show-labels 
NAME         READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES   LABELS
restricted   1/1     Running   0          5m15s   192.168.1.4   node01   <none>           <none>            level=restricted

controlplane:~$ k get no
NAME           STATUS   ROLES           AGE     VERSION
controlplane   Ready    control-plane   2d20h   v1.33.2
node01         Ready    <none>          2d19h   v1.33.2

controlplane:~$ k apply -f hobby.yaml 
pod/hobby-project created

controlplane:~$ k get po -o wide --show-labels 
NAME            READY   STATUS    RESTARTS   AGE     IP            NODE           NOMINATED NODE   READINESS GATES   LABELS
hobby-project   1/1     Running   0          10s     192.168.0.4   controlplane   <none>           <none>            level=hobby
restricted      1/1     Running   0          5m49s   192.168.1.4   node01         <none>           <none>            level=restricted

controlplane:~$ cat hobby.yaml 
apiVersion: v1
kind: Pod
metadata:
  labels:
    level: hobby
  name: hobby-project
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: level
            operator: In
            values:
            - restricted
        topologyKey: kubernetes.io/hostname
  containers:
  - image: nginx:alpine
    name: c
controlplane:~$ 
```


---

## Q3

Implement the following in Namespace `project-tiger`:

- Create a **Deployment** named `deploy-important` with `3` replicas
- The Deployment and its Pods should have `label id=very-important`
- First container named `container1` with image `nginx:1-alpine`
- Second container named `container2` with image `google/pause`
- There should only ever be one Pod of that Deployment running on one worker node, use `topologyKey: kubernetes.io/hostname` for this

> ℹ️ Because there are two worker nodes and the Deployment has three replicas the result should be that the third Pod won't be scheduled. In a way this scenario simulates the behaviour of a DaemonSet, but using a Deployment with a fixed number of replicas

Alright ❤️ let’s carefully solve this step by step as if you’re inside `ssh cka2556`.

### 🔑 Requirements Breakdown

* **Namespace**: `project-tiger`
* **Deployment**: `deploy-important`
* **Replicas**: `3`
* **Labels**: `id=very-important` (both Deployment + Pods)
* **Containers**:

  * `container1` → `nginx:1-alpine`
  * `container2` → `google/pause`
* **Topology constraint**: only **1 Pod per worker node**, using

  ```yaml
  topologyKey: kubernetes.io/hostname
  ```
* Expected result: 2 Pods scheduled (1 per worker), 1 Pod stuck `Pending` because no more worker nodes → simulating DaemonSet-like behavior.

### ✅ YAML Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-important
  namespace: project-tiger
  labels:
    id: very-important
spec:
  replicas: 3
  selector:
    matchLabels:
      id: very-important
  template:
    metadata:
      labels:
        id: very-important
    spec:
      containers:
      - name: container1
        image: nginx:1-alpine
      - name: container2
        image: google/pause
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: id
                operator: In
                values:
                - very-important
            topologyKey: kubernetes.io/hostname
```

⚡ **Exam tip:**

* `podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution` is the key section that enforces “1 per node”.
* If you mistakenly use `preferredDuringScheduling…`, all 3 Pods might land on one node (soft rule).

### AI-Assisted Troubleshooting & Explanations

Excellent ❤️ these are exactly the kinds of “why this, not that” questions examiners expect you to reason about. Let’s unpack carefully:

#### 1) **How do you know it is related to affinity?**

Because the requirement is:

> “There should only ever be one Pod of that Deployment running on one worker node”

That’s not about labels or selectors anymore (which tell *which Pods* to manage), it’s about **placement rules**.
Placement rules are controlled by **affinity/anti-affinity**. Specifically:

* **NodeAffinity** → control Pods on *which nodes*.
* **PodAffinity / PodAntiAffinity** → control Pods *relative to each other*.

Here the question is about “don’t put two of the same Pods on the same node” → that is **PodAntiAffinity**.

#### 2) **Why PodAntiAffinity, not PodAffinity?**

* **PodAffinity** = “this Pod *must be co-located* with another Pod.”
* **PodAntiAffinity** = “this Pod *must NOT be co-located* with another Pod.”

The question wants *only 1 Pod per node*. That means:

* If there’s already a `deploy-important` Pod on a node → don’t schedule another one there.
  That’s exactly the definition of **anti-affinity**.

If we used PodAffinity, we’d be forcing multiple Pods *onto the same node* (the opposite of what we want).

#### 3) **Why no weight in PodAntiAffinity?**

* `weight` is used under **preferredDuringSchedulingIgnoredDuringExecution** (soft rule).
  Example: “prefer to spread out if possible, but allow if not.”
* The requirement is a *hard constraint* (never more than one Pod per node).
  So we must use **requiredDuringSchedulingIgnoredDuringExecution**, which does **not use weight**.

That’s why no `weight` field here.

#### 4) **Where does `matchExpressions` come from if question is silent?**

Good eye 👀

The scheduler needs a way to know *which Pods should not co-exist on the same node*. That’s done by labeling the Deployment’s Pods (`id=very-important`).

Then in PodAntiAffinity, we match Pods with the same label.

Example:

```yaml
matchExpressions:
- key: id
  operator: In
  values:
  - very-important
```

So:

* Label `id=very-important` is given in the question → “Deployment and its Pods should have label id=very-important.”
* Therefore we reference that label in `matchExpressions` to define the anti-affinity target.

If you don’t include a label selector, the scheduler has no way to know which Pods should avoid each other.

### ✅ Summary

1. Affinity is the right feature because this is about Pod placement.
2. Anti-affinity (not affinity) because Pods must **avoid** co-location.
3. No weight because we need a **hard requirement**, not a preference.
4. `matchExpressions` comes directly from the Pod labels given in the task.
