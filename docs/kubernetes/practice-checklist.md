# Kubernetes Practice Checklist ✅

This file lists all the major **Kubernetes concepts, resources, and tasks** you should practice one by one.  
Use it as a **roadmap + progress tracker**.

---

## 1. Kubernetes Resources (API Objects)

- [ ] Pod, Deployment, ReplicaSet, StatefulSet, DaemonSet
- [ ] Job, CronJob
- [ ] Service (ClusterIP, NodePort, LoadBalancer, ExternalName), EndpointSlice
- [ ] IngressClass, `Ingress`, ClusterIssuer     `includes IngressClass, ingress-nginx controller, and all annotations` 
- [ ] GatewayClass, `Gateway`, HTTPRoute
- [ ] ConfigMap `ConfigMaps, Configure a Pod to Use a ConfigMap`, Secret `Secrets, Distribute Credentials Securely Using Secrets`
- [ ] PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass
  - volume: all types of volumes injected pod manifest files, local pv
  - pv: pv, pvc, storage class, claim as volume, walkthrough (pv with hostpath, pvc, and pod manifest)
  - Ephemeral Volumes: CSI ephemeral volumes, Generic ephemeral volumes... pod manifests
- [ ] Namespace, ServiceAccount `sa: Configure Service Accounts for Pods`, Role, RoleBinding, ClusterRole, ClusterRoleBinding
- [ ] NetworkPolicy  `Network Policy, Declare Network Policy`
- [ ] ResourceQuota, LimitRange, PriorityClass, PodDisruptionBudgets (PDB)
- [ ] CustomResourceDefinition (CRD)     `crd: Extend the Kubernetes API with CustomResourceDefinitions`
- [ ] HorizontalPodAutoscaler (HPA) `hpa: Horizontal Pod Autoscaling, HorizontalPodAutoscaler Walkthrough (Metrics Server)`, VerticalPodAutoscaler (VPA) `vpa: Autoscaling Workloads`, `resize`

---

## 2. PodSpec Concepts (Fields / Sections)

- [ ] containers, `initContainers`, sidecar containers `+ Creating a Pod that has an init container + sidecar containers`
- [ ] command and args `command: Define a Command and Arguments for a Container`
- [ ] env, envFrom `environment variables: Define Environment Variables for a Container (value) + Expose Pod Information to Containers Through Environment Variables (valueFrom)`
- [ ] volumes (emptyDir, hostPath, configMap, secret, PVC, projected, downwardAPI)
- [ ] `securityContext` (pod-level & container-level)
- [ ] resources (requests & limits) `Quota: Configure Memory and CPU Quotas for a Namespace`
- [ ] qosClass `qos: Configure Quality of Service for Pods`
- [ ] resizePolicy `resize: Resize CPU and Memory Resources assigned to Containers`
- [ ] `probes` (livenessProbe, readinessProbe, startupProbe)
- [ ] affinity / antiAffinity (nodeAffinity, podAffinity, podAntiAffinity)
- [ ] tolerations
- [ ] nodeSelector, nodeName, priorityClassName, schedularName, `serviceAccountName`, imagePullSecrets
- [ ] labels & selectors, matchLabels & matchExpressions `Labels: Labels and Selectors, Recommended Labels`
- [ ] restartPolicy
- [ ] topologySpreadConstraints
- [ ] lifecycle hooks (postStart, preStop)
- [ ] terminationGracePeriodSeconds
- [ ] dnsPolicy / hostNetwork / hostPID

---

## 3. Cluster Ops Topics (Administration / CKA)

- [ ] kubeadm init / join, kubeadm upgrade, kubeadm reset `kubeadm init`
  - Installing kubeadm `container runtimes`
  - Troubleshooting kubeadm
  - Creating a cluster with kubeadm `container runtimes`
  - Creating Highly Available Clusters with kubeadm
  - Set up a High Availability etcd Cluster with kubeadm
  - Upgrading kubeadm clusters
- [ ] `etcd` backup & restore
- [ ] Manage `static pods`
- [ ] `Admission control`
- [ ] Authentication, Authorization, RBAC setup (Roles, RoleBindings, ClusterRoles, ClusterRoleBindings), Admission Controllers, Certificate Signing Requests
  -  Controlling Access to the Kubernetes API
  -  `Accessing the Kubernetes API` from a pod
    - Certificate Signing Requests
          - `csr/certificate: Issue a Certificate for a Kubernetes API Client Using A CertificateSigningRequest (Manage TLS Certificates in a Cluster)`   
- [ ] Certificate management (renew, inspect, troubleshoot)
- [ ] Node maintenance (drain, cordon, uncordon)
- [ ] Cluster troubleshooting (Pods pending, CrashLoopBackOff, Node NotReady, DNS issues)
- [ ] `Network plugin` install (Calico, Flannel, Cilium, etc.)
- [ ] CoreDNS config & troubleshooting
- [ ] KubeProxy troubleshooting
- [ ] kubeconfig management (contexts, users, clusters)   `kubeconfig`
- [ ] Scheduling debugging (taints, tolerations, affinity)
- [ ] Logging & monitoring basics
- [ ] Upgrading worker nodes
- [ ] Backup & restore manifests
- [ ] Resource usage monitoring (kubectl top, metrics-server)
- [ ] API deprecation, API Groups
- [ ] - kubelet, kube-apiserver, kube-controller-manager, kube-proxy, ports

---

## 4. Advanced

- [ ] Helm, Kustomize
- [ ] Operators
- [ ] Cluster Autoscaler
- [ ] Admission Controllers (Mutating & Validating webhooks)
- [ ] API Aggregation & Extension

---

## 5. Controllers, Operators & CRDs

> 📌 **Note:**  
> - **Controller** → manages **built-in Kubernetes resources** (Pods, Deployments, Services, etc.).  
> - **Operator** → is also a **controller**, but it manages **Custom Resources (CRDs)** that extend Kubernetes (like Prometheus, MySQLCluster, VPA, etc.).  
> - 👉 Every **Operator is a Controller**, but not every Controller is an Operator.

### Built-in Controllers
- [ ] Deployment Controller, ReplicaSet Controller, StatefulSet Controller, DaemonSet Controller
- [ ] Job & CronJob Controller
- [ ] Node Controller
- [ ] Namespace Controller
- [ ] Service Controller
- [ ] PV & PVC Controllers
- [ ] EndpointSlice Controller
- [ ] HPA Controller (Horizontal Pod Autoscaler)

### Add-on Controllers
- [ ] Ingress Controller (NGINX, HAProxy, Traefik, etc.)
- [ ] Cert-Manager Controller (TLS certificates)
- [ ] Cluster Autoscaler

### CRDs (Custom Resource Definitions)
- [ ] VerticalPodAutoscaler (VPA)
- [ ] PodDisruptionBudget (PDB)
- [ ] Custom Metrics CRDs
- [ ] External Secrets CRD
- [ ] Monitoring CRDs (Prometheus, Alertmanager, ServiceMonitor, etc.)

### Operators
- [ ] Prometheus Operator
- [ ] MySQL/Postgres Operators
- [ ] etcd Operator
- [ ] ElasticSearch Operator
- [ ] ArgoCD Operator

---

## 6. Kubectl Administrative Commands

- [ ] kubectl get (pods, svc, deployments, nodes, etc.)
- [ ] kubectl describe (pods, nodes, events)
- [ ] kubectl logs (single & multi-container pods, previous logs)
- [ ] kubectl exec (run commands inside containers, open interactive shell)
- [ ] kubectl port-forward
- [ ] kubectl scale (deployments, statefulsets, replicasets)
- [ ] kubectl autoscale (deployments, statefulsets, replicasets)
- [ ] kubectl set image (rolling update pods)
- [ ] kubectl rollout (status, history, undo)
- [ ] kubectl top (pods, nodes — requires metrics-server)
- [ ] kubectl drain / cordon / uncordon
- [ ] kubectl edit (live edit resources)
- [ ] kubectl delete (resources, labels, selectors)
- [ ] kubectl apply -f (idempotent)
- [ ] kubectl replace -f (force replace)
- [ ] kubectl diff -f (compare manifests with live state)
- [ ] kubectl label (add/remove labels)
- [ ] kubectl annotate (add/remove annotations)
- [ ] kubectl config (view/set contexts, users, clusters)
- [ ] kubectl api-resources / api-versions
- [ ] kubectl explain (understand fields)
- [ ] `kubectl auth` 
