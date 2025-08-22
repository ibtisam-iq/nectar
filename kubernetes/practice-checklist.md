# Kubernetes Practice Checklist ✅

This file lists all the major **Kubernetes concepts, resources, and tasks** you should practice one by one.  
Use it as a **roadmap + progress tracker**.

---

## 1. Kubernetes Resources (API Objects)

- [ ] Pod, Deployment, ReplicaSet, StatefulSet, DaemonSet
- [ ] Job, CronJob
- [ ] Service (ClusterIP, NodePort, LoadBalancer, ExternalName)
- [ ] IngressClass, Ingress, ClusterIssuer
- [ ] GatewayClass, Gateway, HTTPRoute 
- [ ] ConfigMap, Secret
- [ ] PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass
- [ ] Namespace, ServiceAccount, Role, RoleBinding, ClusterRole, ClusterRoleBinding
- [ ] NetworkPolicy
- [ ] ResourceQuota, LimitRange, PriorityClass, PodDisruptionBudgets (PDB)
- [ ] CustomResourceDefinition (CRD) `crd: Extend the Kubernetes API with CustomResourceDefinitions`
- [ ] HorizontalPodAutoscaler (HPA), VerticalPodAutoscaler (VPA) 

---

## 2. PodSpec Concepts (Fields / Sections)

- [ ] containers, initContainers, sidecar containers
- [ ] env, envFrom
- [ ] volumes (emptyDir, hostPath, configMap, secret, PVC, projected, downwardAPI)
- [ ] securityContext (pod-level & container-level)
- [ ] resources (requests & limits)
- [ ] probes (livenessProbe, readinessProbe, startupProbe)
- [ ] affinity / antiAffinity (nodeAffinity, podAffinity, podAntiAffinity)
- [ ] tolerations
- [ ] nodeSelector, nodeName, priorityClassName, schedularName, serviceAccountName, imagePullSecrets
- [ ] labels & selectors, matchLabels & matchExpressions
- [ ] restartPolicy
- [ ] topologySpreadConstraints
- [ ] lifecycle hooks (postStart, preStop)
- [ ] terminationGracePeriodSeconds
- [ ] dnsPolicy / hostNetwork / hostPID

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

- [ ] Helm, Kustomize
- [ ] Operators
- [ ] Cluster Autoscaler
- [ ] Admission Controllers (Mutating & Validating webhooks)
- [ ] API Aggregation & Extension

---

## 5. Kubectl Administrative Commands

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
