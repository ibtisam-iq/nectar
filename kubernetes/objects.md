# Kubernetes Objects & Resources

## 1. Introduction
Kubernetes objects and resources are persistent entities that make up the cluster and are used to manage the deployment, scaling, and management of applications in the Kubernetes system. These objects represent the desired state of your cluster, defining how workloads run and how resources are managed.

### **Objects vs. Resources**
In Kubernetes, the term **"resource"** has two meanings:

1. **Kubernetes API Resources (Objects)** – These are high-level entities that define the desired state of applications and cluster components (e.g., Pods, Deployments, Services). They are managed by the Kubernetes API and persist as part of the cluster's state.

2. **Cluster Resources (Compute Resources)** – These refer to system capabilities like CPU, memory (RAM), storage, and networking bandwidth. Kubernetes schedules workloads based on these resources and ensures fair distribution among different workloads.

Understanding both meanings is essential for managing workloads efficiently.

---

## 2. Core Kubernetes Objects

### **Pod**
- The smallest and simplest deployable unit in Kubernetes.
- Can contain one or more containers that share storage and network.
- Managed by higher-level controllers like `Deployments` or `StatefulSets`.

### **ReplicationController**
- An older controller that ensures a specified number of pod replicas are running.
- Replaced by `ReplicaSet` in most modern use cases but still available for legacy support.

### **ReplicaSet**
- Ensures a specified number of pod replicas are running at all times.
- Replaces failed pods to maintain the desired count.
- Successor to `ReplicationController` with better support for label selectors.

### **Deployment**
- Manages `ReplicaSets` and allows rolling updates and rollbacks.
- Used for declarative pod management.

### **StatefulSet**
- Used for stateful applications requiring stable network identities.
- Maintains ordered, persistent storage and networking.

### **DaemonSet**
- Ensures that a copy of a pod runs on all or some nodes.
- Typically used for logging, monitoring, or networking applications.

### **Job & CronJob**
- **Job**: Runs a one-time task until completion.
- **CronJob**: Schedules `Jobs` to run at specific intervals.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| Pods                               | po              | `kubectl get pods`            | `kubectl run <name> --image=<image>` |
| Deployments                        | deploy         | `kubectl get deployments`      | `kubectl create deployment <name> --image=<image>` |
| ReplicaSets                        | rs              | `kubectl get replicasets`      | -                           |
| ReplicationControllers             | rc              | `kubectl get replicationcontrollers` | `kubectl create replicationcontroller <name>` |
| DaemonSets                         | ds              | `kubectl get daemonsets`       | `kubectl create daemonset <name>` |
| StatefulSets                       | -               | `kubectl get statefulsets`     | `kubectl create statefulset <name> --image=<image>` |
| Jobs                               | -               | `kubectl get jobs`            | `kubectl create job <name> --image=<image>` |
| CronJobs                           | -               | `kubectl get cronjobs`         | `kubectl create cronjob <name> --schedule="* * * * *" --image=<image>` |

---

## 3. Service-related Objects

### **Service**
- Provides stable network access to pods, abstracting their dynamic nature.
- Supports different types: `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`.

### **Ingress**
- Manages external HTTP/S access to services.
- Supports routing, TLS termination, and virtual hosting.

### **Endpoint & EndpointSlice**
- **Endpoint**: Represents backend pod IPs for a service.
- **EndpointSlice**: Improves scalability by splitting endpoints into smaller chunks.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| Services                           | svc             | `kubectl get services`        | `kubectl expose pod <name> --port=80 --target-port=8080 --name=<service>` |
| Endpoints                          | ep              | `kubectl get endpoints`        | -                           |
| Ingresses                          | ing             | `kubectl get ingresses`        | `kubectl create ingress <name> --rule=<host>/=<service>:<port>` |
| IngressResource Statuses            | -               | `kubectl get ingressresourcestatuses` | -                           |
| IngressClass                         | -               | `kubectl get ingressclasses`    | -                           |
| IngressClassSpec                     | -               | `kubectl get ingressclassspecs`  | - |
| IngressClassParameters              | -               | `kubectl get ingressclassparameters` | - |
| IngressResource                    | -               | `kubectl get ingressresources` | `kubectl create ingress resource <name> --api-version=<api-version>` |
| EndpointSlices                     | eps             | `kubectl get endpointslices`   | -                           |

---

## 4. Configuration Objects

### **ConfigMap**
- Stores non-sensitive configuration data as key-value pairs.
- Can be mounted as environment variables or volumes.

### **Secret**
- Stores sensitive data like passwords or API keys.
- Encrypted at rest and accessible only to authorized pods.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| ConfigMaps                         | cm              | `kubectl get configmaps`       | `kubectl create configmap <name> --from-literal=key=value` |
| Secrets                            | -               | `kubectl get secrets`         | `kubectl create secret generic <name> --from-literal=key=value` |

---

## 5. Storage Objects

### **PersistentVolume (PV)**
- Represents a physical storage resource in a cluster.
- Can be manually provisioned or dynamically allocated.

### **PersistentVolumeClaim (PVC)**
- Requests storage from a PersistentVolume.
- Defines storage capacity and access modes.

### **StorageClass**
- Defines different storage provisioning policies.
- Used for dynamic volume provisioning.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| PersistentVolumes                  | pv              | `kubectl get pv`              | -                           |
| PersistentVolumeClaims             | pvc             | `kubectl get pvc`             | `kubectl create pvc <name> --storage=1Gi` |
| StorageClasses                     | -               | `kubectl get storageclasses`  | -                           |
| LocalPVs                            | -               | `kubectl get localpv`         | -                           |

---

## 6. Security & Access Control

### **ServiceAccount**
- Provides an identity for pods to interact with the Kubernetes API securely.

### **Role & RoleBinding**
- **Role**: Defines access rules within a namespace.
- **RoleBinding**: Grants permissions defined in a Role to users or service accounts.

### **ClusterRole & ClusterRoleBinding**
- **ClusterRole**: Similar to Role but applies cluster-wide.
- **ClusterRoleBinding**: Grants ClusterRole permissions across all namespaces.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| ServiceAccounts                    | sa              | `kubectl get serviceaccounts` | `kubectl create serviceaccount <name>` |
| Roles                               | -               | `kubectl get roles`            | `kubectl create role <name er> --verb=get --resource=pods` |
| RoleBindings                       | -               | `kubectl get rolebindings`    | `kubectl create rolebinding <name> --role=<role-name> --serviceaccount=<sa-name>` |
| ClusterRoles                        | -               | `kubectl get clusterroles`    | `kubectl create clusterrole <name> --verb=get --resource=pods` |
| ClusterRoleBindings                | -               | `kubectl get clusterrolebindings` | `kubectl create clusterrolebinding <name> --clusterrole=<cluster-role-name> --serviceaccount=<sa-name>` |
| Secret (for ServiceAccount tokens)  | -               | `kubectl get secrets`         | `kubectl create secret generic <name> --from-literal=key=value` |

---

## 7. Networking Objects

### **NetworkPolicy**
- Defines rules for pod-to-pod communication.
- Controls traffic flow within the cluster.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| NetworkPolicies                    | -               | `kubectl get networkpolicies`  | `kubectl create networkpolicy <name> --pod-selector=<label>` |

---

## 8. Cluster Management Objects

### **Namespace**
- Provides logical partitioning of cluster resources.
- Useful for managing multiple environments (e.g., dev, test, production) in the same cluster.

### **PodDisruptionBudget (PDB)**
- Defines the minimum number of pods that must remain available during voluntary disruptions (e.g., upgrades).
- Helps maintain high availability of applications.

### **PriorityClass**
- Assigns priorities to pods, ensuring higher-priority pods get scheduled first when resources are scarce.
- Used to prevent starvation of critical workloads.

### **ResourceQuota**
- Limits the amount of CPU, memory, and other resources a namespace can use.
- Helps prevent any single workload from consuming excessive cluster resources.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| Clusters                          | -                | `kubectl get clusters`         | -                           |
| Namespaces                         | ns              | `kubectl get namespaces`       | `kubectl create namespace <name>` |
| Nodes                              | no              | `kubectl get nodes`           | -                           |
| ComponentStatuses                  | cs              | `kubectl get componentstatuses` | -                           |
| ResourceQuotas                     | quota           | `kubectl get resourcequotas`   | `kubectl create quota <name> --hard=cpu=2,memory=1Gi` |
| LimitRanges                        | limits         | `kubectl get limitranges`      | -                           |
| PodDisruptionBudgets               | pdb             | `kubectl get pdb`              | `kubectl create pdb <name> --selector=<label>` |
| PodSecurityPolicies                | psp             | `kubectl get podsecuritypolicies` | -                           |
| PodTemplates                       | -               | `kubectl get podtemplates`     | -                           |
| ThirdPartyResources                | -               | `kubectl get thirdpartyresources` | -                           |
| Events                             | ev              | `kubectl get events`           | -                           |
| HorizontalPodAutoscalers           | hpa             | `kubectl get hpa`              | `kubectl autoscale deployment <name> --min=1 --max=5 --cpu-percent=80` |

---

## 9. Custom Resources

### **Custom Resource Definitions (CRDs)**
- Extend Kubernetes API with new objects.
- Used for defining application-specific configurations.

### **Operators**
- Automate application management using CRDs and controllers.
- Encapsulate operational knowledge into Kubernetes-native constructs.

---

## Summary
- Kubernetes objects (API resources) define the state of workloads, networking, storage, and security.
- Kubernetes resources (compute resources) allocate and control system capabilities like CPU, memory, and storage.
- They work together to build scalable, resilient, and manageable applications.
- Understanding Kubernetes objects and resources is key to managing clusters effectively.