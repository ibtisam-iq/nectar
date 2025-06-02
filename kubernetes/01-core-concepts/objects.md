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

### [**Pod**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/09-workloads/pod-guide.md)
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
- [**Job**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/09-workloads/jobs-guide.md): Runs a one-time task until completion.
- [**CronJob**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/09-workloads/cron-job-guide.md): Schedules `Jobs` to run at specific intervals.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| Pods                               | po              | `kubectl get pods`            | `kubectl run <name> --image=<image>` |
| Deployments                        | deploy         | `kubectl get deployments`      | `kubectl create deployment <name> --image=<image>` |
| ReplicaSets                        | rs              | `kubectl get replicasets`      | -                           |
| ReplicationControllers             | rc              | `kubectl get replicationcontrollers` | - |
| DaemonSets                         | ds              | `kubectl get daemonsets`       | - |
| StatefulSets                       | -               | `kubectl get statefulsets`     | - |
| Jobs                               | -               | `kubectl get jobs`            | `kubectl create job <name> --image=<image>` |
| CronJobs                           | -               | `kubectl get cronjobs`         | `kubectl create cronjob <name> --schedule="* * * * *" --image=<image>` |

---

## 3. Service-related Objects

### [**Service**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/03-networking/services-guide.md)
- Provides stable network access to pods, abstracting their dynamic nature.
- Supports different types: `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`.

### [**Ingress**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/03-networking/k8s-https-guide.md)
- Manages external HTTP/S access to services.
- Supports routing, TLS termination, and virtual hosting.

### **Endpoint & EndpointSlice**
- [**Endpoint**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/03-networking/endpoints-guide.md): Represents backend pod IPs for a service.
- **EndpointSlice**: Improves scalability by splitting endpoints into smaller chunks.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| Services                           | svc             | `kubectl get services`        | `kubectl expose pod <name> --port=80 --target-port=8080 --name=<service>` --protocol=TCP --type=<>|
| Ingresses                          | ing             | `kubectl get ingresses`        | `kubectl create ingress <name> --rule=<host>/=<service>:<port>` |
| IngressClass                         | -               | `kubectl get ingressclasses`    | -                           |
| Endpoints                          | ep              | `kubectl get endpoints`        | -                           |
| EndpointSlices                     | eps             | `kubectl get endpointslices`   | -                           |

---

## 4. [Networking](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/03-networking/networking-in-k8s.md) Objects

### [**NetworkPolicy**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/03-networking/network-policy-guide.md)
- Defines rules for pod-to-pod communication.
- Controls traffic flow within the cluster.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| NetworkPolicies                    | netpol               | `kubectl get networkpolicies`  | - |

---

## 5. [Storage](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/04-storage/README.md) Objects

### [**PersistentVolume (PV)**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/04-storage/pv-guide.md)
- Represents a physical storage resource in a cluster.
- Can be manually provisioned or dynamically allocated.

### [**PersistentVolumeClaim (PVC)**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/04-storage/pvc-guide.md)
- Requests storage from a PersistentVolume.
- Defines storage capacity and access modes.

### [**StorageClass**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/04-storage/storage-class.md)
- Defines different storage provisioning policies.
- Used for dynamic volume provisioning.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| PersistentVolumes                  | pv              | `kubectl get pv`              | -                           |
| PersistentVolumeClaims             | pvc             | `kubectl get pvc`             | - |
| StorageClasses                     | -               | `kubectl get storageclasses`  | -                           |
| LocalPVs                            | -               | `kubectl get localpv`         | -                           |

---

## 6. Configuration Objects

### [**ConfigMap**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/06-resource-management/configmap-guide.md)
- Stores non-sensitive configuration data as key-value pairs.
- Can be mounted as environment variables or volumes.

### [**Secret**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/06-resource-management/secret-guide.md)
- Stores sensitive data like passwords or API keys.
- Encrypted at rest and accessible only to authorized pods.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| ConfigMaps                         | cm              | `kubectl get configmaps`       | `kubectl create configmap <name> --from-literal=key=value` |
| Secrets                            | -               | `kubectl get secrets`         | `kubectl create secret generic <name> --from-literal=key=value` |

---

## 7. [Security & Access Control](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/07-security/rbac.md)

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

## 8. Cluster Management Objects 

### **Namespace**
- Provides logical partitioning of cluster resources.
- Useful for managing multiple environments (e.g., dev, test, production) in the same cluster.

### **PodDisruptionBudget (PDB)**
- Defines the minimum number of pods that must remain available during voluntary disruptions (e.g., upgrades).
- Helps maintain high availability of applications.

### [**PriorityClass**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/05-scheduling-and-affinity/priority-class.md)
- Assigns priorities to pods, ensuring higher-priority pods get scheduled first when resources are scarce.
- Used to prevent starvation of critical workloads.

### [**ResourceQuota**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/06-resource-management/01-resource-quota-guide.md)
- Limits the amount of total resources (e.g. CPU, memory, and storage etc.) a **namespace** can use.
- Helps prevent any single workload from consuming excessive cluster resources.

### [**LimitRange**](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/06-resource-management/02-limit-range-guide.md)
- Sets default resource limits for **individual pods or containers** within a **namespace**.
- Ensures pods don't consume more resources than intended.

### **ComponentStatuses**
- Provides status information about cluster components (e.g., nodes, control plane components).
- Useful for monitoring cluster health.
- **Note:** This is not a resource that can be created or deleted.

| Resource Type                     | Abbreviated Alias | Fetch Command                  | Create Command (Imperative) |
|------------------------------------|------------------|--------------------------------|-----------------------------|
| Clusters                          | -                | `kubectl get clusters`         | -                           |
| Namespaces                         | ns              | `kubectl get namespaces`       | `kubectl create namespace <name>` |
| Nodes                              | no              | `kubectl get nodes`           | -                           |
| ResourceQuotas                     | quota           | `kubectl get resourcequotas`   | `kubectl create quota <name> --hard=cpu=2,memory=1Gi` |
| LimitRanges                        | limits         | `kubectl get limitranges`      | -                           |
| PodDisruptionBudgets               | pdb             | `kubectl get pdb`              | `kubectl create pdb <name> --selector=<label>` |
| Events                             | ev              | `kubectl get events`           | -                           |
| HorizontalPodAutoscalers           | hpa             | `kubectl get hpa`              | `kubectl autoscale deployment <name> --min=1 --max=5 --cpu-percent=80` |
| ComponentStatuses                  | cs              | `kubectl get componentstatuses` | -                           |
| PriorityClasses                    | pc              | `kubectl get priorityclasses`  | `kubectl create pc` |

---

## 9. Custom Resources

### **Custom Resource Definitions (CRDs)**
- Extend Kubernetes API with new objects.
- Used for defining application-specific configurations.

### **Operators**
- Automate application management using CRDs and controllers.
- Encapsulate operational knowledge into Kubernetes-native constructs.

---

```bash
controlplane ~ ➜  kubectl api-resources
NAME                                SHORTNAMES   APIVERSION                        NAMESPACED   KIND
bindings                                         v1                                true         Binding
componentstatuses                   cs           v1                                false        ComponentStatus
configmaps                          cm           v1                                true         ConfigMap
endpoints                           ep           v1                                true         Endpoints
events                              ev           v1                                true         Event
limitranges                         limits       v1                                true         LimitRange
namespaces                          ns           v1                                false        Namespace
nodes                               no           v1                                false        Node
persistentvolumeclaims              pvc          v1                                true         PersistentVolumeClaim
persistentvolumes                   pv           v1                                false        PersistentVolume
pods                                po           v1                                true         Pod
podtemplates                                     v1                                true         PodTemplate
replicationcontrollers              rc           v1                                true         ReplicationController
resourcequotas                      quota        v1                                true         ResourceQuota
secrets                                          v1                                true         Secret
serviceaccounts                     sa           v1                                true         ServiceAccount
services                            svc          v1                                true         Service
mutatingwebhookconfigurations                    admissionregistration.k8s.io/v1   false        MutatingWebhookConfiguration
validatingadmissionpolicies                      admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicy
validatingadmissionpolicybindings                admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicyBinding
validatingwebhookconfigurations                  admissionregistration.k8s.io/v1   false        ValidatingWebhookConfiguration
customresourcedefinitions           crd,crds     apiextensions.k8s.io/v1           false        CustomResourceDefinition
apiservices                                      apiregistration.k8s.io/v1         false        APIService
controllerrevisions                              apps/v1                           true         ControllerRevision
daemonsets                          ds           apps/v1                           true         DaemonSet
deployments                         deploy       apps/v1                           true         Deployment
replicasets                         rs           apps/v1                           true         ReplicaSet
statefulsets                        sts          apps/v1                           true         StatefulSet
selfsubjectreviews                               authentication.k8s.io/v1          false        SelfSubjectReview
tokenreviews                                     authentication.k8s.io/v1          false        TokenReview
localsubjectaccessreviews                        authorization.k8s.io/v1           true         LocalSubjectAccessReview
selfsubjectaccessreviews                         authorization.k8s.io/v1           false        SelfSubjectAccessReview
selfsubjectrulesreviews                          authorization.k8s.io/v1           false        SelfSubjectRulesReview
subjectaccessreviews                             authorization.k8s.io/v1           false        SubjectAccessReview
horizontalpodautoscalers            hpa          autoscaling/v2                    true         HorizontalPodAutoscaler
cronjobs                            cj           batch/v1                          true         CronJob
jobs                                             batch/v1                          true         Job
certificatesigningrequests          csr          certificates.k8s.io/v1            false        CertificateSigningRequest
leases                                           coordination.k8s.io/v1            true         Lease
endpointslices                                   discovery.k8s.io/v1               true         EndpointSlice
events                              ev           events.k8s.io/v1                  true         Event
flowschemas                                      flowcontrol.apiserver.k8s.io/v1   false        FlowSchema
prioritylevelconfigurations                      flowcontrol.apiserver.k8s.io/v1   false        PriorityLevelConfiguration
helmchartconfigs                                 helm.cattle.io/v1                 true         HelmChartConfig
helmcharts                                       helm.cattle.io/v1                 true         HelmChart
addons                                           k3s.cattle.io/v1                  true         Addon
etcdsnapshotfiles                                k3s.cattle.io/v1                  false        ETCDSnapshotFile
nodes                                            metrics.k8s.io/v1beta1            false        NodeMetrics
pods                                             metrics.k8s.io/v1beta1            true         PodMetrics
ingressclasses                                   networking.k8s.io/v1              false        IngressClass
ingresses                           ing          networking.k8s.io/v1              true         Ingress
networkpolicies                     netpol       networking.k8s.io/v1              true         NetworkPolicy
runtimeclasses                                   node.k8s.io/v1                    false        RuntimeClass
poddisruptionbudgets                pdb          policy/v1                         true         PodDisruptionBudget
clusterrolebindings                              rbac.authorization.k8s.io/v1      false        ClusterRoleBinding
clusterroles                                     rbac.authorization.k8s.io/v1      false        ClusterRole
rolebindings                                     rbac.authorization.k8s.io/v1      true         RoleBinding
roles                                            rbac.authorization.k8s.io/v1      true         Role
priorityclasses                     pc           scheduling.k8s.io/v1              false        PriorityClass
csidrivers                                       storage.k8s.io/v1                 false        CSIDriver
csinodes                                         storage.k8s.io/v1                 false        CSINode
csistoragecapacities                             storage.k8s.io/v1                 true         CSIStorageCapacity
storageclasses                      sc           storage.k8s.io/v1                 false        StorageClass
volumeattachments                                storage.k8s.io/v1                 false        VolumeAttachment
ingressroutes                                    traefik.containo.us/v1alpha1      true         IngressRoute
ingressroutetcps                                 traefik.containo.us/v1alpha1      true         IngressRouteTCP
ingressrouteudps                                 traefik.containo.us/v1alpha1      true         IngressRouteUDP
middlewares                                      traefik.containo.us/v1alpha1      true         Middleware
middlewaretcps                                   traefik.containo.us/v1alpha1      true         MiddlewareTCP
serverstransports                                traefik.containo.us/v1alpha1      true         ServersTransport
tlsoptions                                       traefik.containo.us/v1alpha1      true         TLSOption
tlsstores                                        traefik.containo.us/v1alpha1      true         TLSStore
traefikservices                                  traefik.containo.us/v1alpha1      true         TraefikService
ingressroutes                                    traefik.io/v1alpha1               true         IngressRoute
ingressroutetcps                                 traefik.io/v1alpha1               true         IngressRouteTCP
ingressrouteudps                                 traefik.io/v1alpha1               true         IngressRouteUDP
middlewares                                      traefik.io/v1alpha1               true         Middleware
middlewaretcps                                   traefik.io/v1alpha1               true         MiddlewareTCP
serverstransports                                traefik.io/v1alpha1               true         ServersTransport
serverstransporttcps                             traefik.io/v1alpha1               true         ServersTransportTCP
tlsoptions                                       traefik.io/v1alpha1               true         TLSOption
tlsstores                                        traefik.io/v1alpha1               true         TLSStore
traefikservices                                  traefik.io/v1alpha1               true         TraefikService
```

---

## Summary
- Kubernetes objects (API resources) define the state of [workloads](https://github.com/ibtisam-iq/nectar/tree/main/kubernetes/09-workloads), [networking](https://github.com/ibtisam-iq/nectar/tree/main/kubernetes/03-networking), [storage](https://github.com/ibtisam-iq/nectar/tree/main/kubernetes/04-storage), and [security](https://github.com/ibtisam-iq/nectar/tree/main/kubernetes/07-security).
- Kubernetes resources ([compute resources](https://github.com/ibtisam-iq/nectar/tree/main/kubernetes/06-resource-management)) allocate and control system capabilities like CPU, memory, and storage.
- They work together to build scalable, resilient, and manageable applications.
- Understanding Kubernetes objects and resources is key to managing clusters effectively.
