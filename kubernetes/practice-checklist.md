# Kubernetes Practice Checklist ✅

This file lists all the major **Kubernetes concepts, resources, and tasks** you should practice one by one.  
Use it as a **roadmap + progress tracker**.

---

## 1. Kubernetes Resources (API Objects)

- [ ] Pod, Deployment, ReplicaSet, StatefulSet, DaemonSet
- [ ] Job, CronJob
- [ ] Service (ClusterIP, NodePort, LoadBalancer, ExternalName)
- [ ] IngressClass, `Ingress`, ClusterIssuer     `includes IngressClass, ingress-nginx controller, and all annotations` 
- [ ] GatewayClass, Gateway, HTTPRoute `Gateway API`
- [ ] ConfigMap, Secret
- [ ] PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass
  - volume: all types of volumes injected pod manifest files, local pv
  - pv: pv, pvc, storage class, claim as volume, walkthrough (pv with hostpath, pvc, and pod manifest)
  - Ephemeral Volumes: CSI ephemeral volumes, Generic ephemeral volumes... pod manifests
- [ ] Namespace, ServiceAccount, Role, RoleBinding, ClusterRole, ClusterRoleBinding
- [ ] NetworkPolicy  `Network Policy, Declare Network Policy`
- [ ] ResourceQuota, LimitRange, PriorityClass, PodDisruptionBudgets (PDB)
- [ ] CustomResourceDefinition (CRD)     `crd: Extend the Kubernetes API with CustomResourceDefinitions`
- [ ] HorizontalPodAutoscaler (HPA), `hpa: Horizontal Pod Autoscaling, HorizontalPodAutoscaler Walkthrough` VerticalPodAutoscaler (VPA) `vpa: Autoscaling Workloads`, `resize`

---

## 2. PodSpec Concepts (Fields / Sections)

- [ ] containers, initContainers, sidecar containers
- [ ] env, envFrom
- [ ] volumes (emptyDir, hostPath, configMap, secret, PVC, projected, downwardAPI)
- [ ] securityContext (pod-level & container-level)
- [ ] resources (requests & limits)
- [ ] resizePolicy `resize: Resize CPU and Memory Resources assigned to Containers`
- [ ] probes (livenessProbe, readinessProbe, startupProbe)
- [ ] affinity / antiAffinity (nodeAffinity, podAffinity, podAntiAffinity)
- [ ] tolerations
- [ ] nodeSelector, nodeName, priorityClassName, schedularName, `serviceAccountName`, imagePullSecrets
- [ ] labels & selectors, matchLabels & matchExpressions
- [ ] restartPolicy
- [ ] topologySpreadConstraints
- [ ] lifecycle hooks (postStart, preStop)
- [ ] terminationGracePeriodSeconds
- [ ] dnsPolicy / hostNetwork / hostPID

---

## 3. Cluster Ops Topics (Administration / CKA)

- [ ] kubeadm init / join, kubeadm upgrade, kubeadm reset
- [ ] etcd backup & restore
- [ ] Manage static pods
- [ ] Authentication, Authorization, RBAC setup (Roles, RoleBindings, ClusterRoles, ClusterRoleBindings), Admission Controllers, Certificate Signing Requests
    -  Controlling Access to the Kubernetes API
      - [Authenticating](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
         - [Authenticating with Bootstrap Tokens](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/)
      - [Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
         - [Dynamic Admission Control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
      - [Authorization](https://kubernetes.io/docs/reference/access-authn-authz/authorization/)
         - [Role Based Access Control](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
         - [Attribute Based Access Control](https://kubernetes.io/docs/reference/access-authn-authz/abac/)
         - [Node Authorization](https://kubernetes.io/docs/reference/access-authn-authz/node/)
         - [Webhook Authorization](https://kubernetes.io/docs/reference/access-authn-authz/webhook/)
      - [Certificate Signing Requests](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)
          - `csr/certificate: Issue a Certificate for a Kubernetes API Client Using A CertificateSigningRequest (Manage TLS Certificates in a Cluster)`   
- [ ] Certificate management (renew, inspect, troubleshoot)
- [ ] Node maintenance (drain, cordon, uncordon)
- [ ] Cluster troubleshooting (Pods pending, CrashLoopBackOff, Node NotReady, DNS issues)
- [ ] Network plugin install (Calico, Flannel, Cilium, etc.)
- [ ] CoreDNS config & troubleshooting
- [ ] kubeconfig management (contexts, users, clusters)
- [ ] Scheduling debugging (taints, tolerations, affinity)
- [ ] Logging & monitoring basics ``
- [ ] Upgrading worker nodes
- [ ] Backup & restore manifests
- [ ] Resource usage monitoring (kubectl top, metrics-server)

---

## 4. Extra (Advanced / Nice-to-Have)

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
