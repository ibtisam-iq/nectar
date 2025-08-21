# Kubernetes Practice Checklist ✅

This file lists all the major **Kubernetes concepts, resources, and tasks** you should practice one by one.  
Use it as a **roadmap + progress tracker**.

---

## 1. Kubernetes Resources (API Objects)

- [ ] Pod
- [ ] Deployment
- [ ] ReplicaSet
- [ ] StatefulSet
- [ ] DaemonSet
- [ ] Job
- [ ] CronJob
- [ ] Service (ClusterIP, NodePort, LoadBalancer, ExternalName)
- [ ] Ingress
- [ ] ConfigMap
- [ ] Secret
- [ ] PersistentVolume (PV)
- [ ] PersistentVolumeClaim (PVC)
- [ ] StorageClass
- [ ] Namespace
- [ ] ServiceAccount
- [ ] Role
- [ ] RoleBinding
- [ ] ClusterRole
- [ ] ClusterRoleBinding
- [ ] NetworkPolicy
- [ ] LimitRange
- [ ] ResourceQuota

---

## 2. PodSpec Concepts (Fields / Sections)

- [ ] containers
- [ ] initContainers
- [ ] sidecar containers
- [ ] volumes (emptyDir, hostPath, configMap, secret, PVC, projected, downwardAPI)
- [ ] securityContext (pod-level & container-level)
- [ ] resources (requests & limits)
- [ ] probes (livenessProbe, readinessProbe, startupProbe)
- [ ] affinity / antiAffinity (nodeAffinity, podAffinity, podAntiAffinity)
- [ ] tolerations
- [ ] nodeSelector
- [ ] topologySpreadConstraints
- [ ] lifecycle hooks (postStart, preStop)
- [ ] restartPolicy
- [ ] terminationGracePeriodSeconds
- [ ] dnsPolicy / hostNetwork / hostPID
- [ ] priorityClassName

---

## 3. Cluster Ops Topics (Administration / CKA)

- [ ] kubeadm init / join
- [ ] kubeadm upgrade
- [ ] kubeadm reset
- [ ] etcd backup & restore
- [ ] Manage static pods
- [ ] Certificate management (renew, inspect, troubleshoot)
- [ ] Node maintenance (drain, cordon, uncordon)
- [ ] Cluster troubleshooting (Pods pending, CrashLoopBackOff, Node NotReady, DNS issues)
- [ ] RBAC setup (Roles, RoleBindings, ClusterRoles, ClusterRoleBindings)
- [ ] Network plugin install (Calico, Flannel, Cilium, etc.)
- [ ] CoreDNS config & troubleshooting
- [ ] kubeconfig management (contexts, users, clusters)
- [ ] Scheduling debugging (taints, tolerations, affinity)
- [ ] Logging & monitoring basics
- [ ] Upgrading worker nodes
- [ ] Backup & restore manifests
- [ ] Resource usage monitoring (kubectl top, metrics-server)

---

## 4. Extra (Advanced / Nice-to-Have)

- [ ] Helm basics
- [ ] CustomResourceDefinition (CRD)
- [ ] Operators
- [ ] PodDisruptionBudgets (PDB)
- [ ] HorizontalPodAutoscaler (HPA)
- [ ] VerticalPodAutoscaler (VPA)
- [ ] Cluster Autoscaler
- [ ] Admission Controllers (Mutating & Validating webhooks)
- [ ] API Aggregation & Extension

---

