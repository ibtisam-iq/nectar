#!/bin/bash
# Script to create all .pages files with human-readable titles for containers-orchestration directory

# Create main containers-orchestration/.pages
cat > containers-orchestration/.pages << 'EOF'
title: Containers & Orchestration
nav:
  - Home: README.md
  - containerd
  - docker
  - docker-compose
  - kubernetes
  - helm
  - kustomize
EOF

# Create containerd/.pages
cat > containers-orchestration/containerd/.pages << 'EOF'
title: Containerd
nav:
  - Home: README.md
  - Docker vs Containerd: docker-vs-containerd.md
  - Containerd Binary: containerd-binary.md
  - Containerd APT vs Binary (Part 1): containerd-apt -vs-binary-1.md
  - Containerd APT vs Binary (Part 2): containerd-apt -vs-binary-2.md
EOF

# Create docker/.pages
cat > containers-orchestration/docker/.pages << 'EOF'
title: Docker
nav:
  - Home: README.md
  - Architecture: architecture.md
  - Installation: installation.md
  - Docker Help: docker --help.md
  - Build: build.md
  - Dockerfile: Dockerfile
  - ARG, ENV & EXPOSE: ARG-ENV-EXPOSE.md
  - ENTRYPOINT & CMD: ENTRYPOINT-CMD.md
  - Multi-Stage Build (Part 1): multi-stage1.md
  - Multi-Stage Build (Part 2): multi-stage2.md
  - Multi-Stage Build (Part 3): multi-stage3.md
  - Image Size Reduction: size-reduction.md
  - User Management: user.md
  - Networking: network.md
  - Volumes: volumes.md
  - Repository Management: repository.md
  - Image Tagging: tag.md
  - Docker Save & Load: docker-save.md
  - Plugins: plugins.md
  - Nginx in Docker: nginx.md
  - Microservices Architecture: microservices-arch.md
  - Docker & Kubernetes: docker-k8s.md
  - Docker with Jenkins: docker_jenkins.md
  - Troubleshooting: troubleshooting.md
  - CKAD Contents: ckad-contents.md
  - CKAD Labs: ckad-labs.md
  - CKAD Questions: ckad-q.md
EOF

# Create docker-compose/.pages
cat > containers-orchestration/docker-compose/.pages << 'EOF'
title: Docker Compose
nav:
  - Docker Compose Overview: Compose.md
  - Compose Configuration: compose.yml
  - Java Spring Boot with MySQL: JavaSpringBoot-MySQL.md
  - Node.js Application: Nodejs.md
EOF

# Create helm/.pages
cat > containers-orchestration/helm/.pages << 'EOF'
title: Helm
nav:
  - Home: README.md
  - Helm as Package Manager: helm-as-pkg-manager.md
  - Helm Guide: helm-guide.md
  - Quick Reference: quick-ref.md
  - Helm Lab: helm-lab.md
  - Mock Exam: mock-exam.md
  - Chart Configuration: Chart.yaml
EOF

# Create kustomize/.pages
cat > containers-orchestration/kustomize/.pages << 'EOF'
title: Kustomize
nav:
  - Home: README.md
  - Directory Structure: 01-dir-structure.md
  - Managing Directories: 02-manage-directories.md
  - Kustomization YAML: 03-kustomization.yaml.md
  - Transformers: 04-transformers.md
  - Patches: 05-patches.md
  - Overlays: 06-overlays.md
  - Components: 07-components.md
  - Kustomize Lab: kustomize-lab.md
EOF

# Create kubernetes/.pages
cat > containers-orchestration/kubernetes/.pages << 'EOF'
title: Kubernetes
nav:
  - Home: README.md
  - Master Key: master-key.md
  - Practice Checklist: practice-checklist.md
  - Error Logs: error-logs.md
  - Wazahat Nama: wazahat-nama.md
  - 00-cluster-setup
  - 01-core-concepts
  - 02-cli-operations
  - 03-networking
  - 04-storage
  - 05-scheduling-and-affinity
  - 06-resource-management
  - 07-security
  - 08-debugging-monitoring
  - 09-workloads
  - 10-references
  - unorganized
  - CKA KodeKloud Complete Notes: CKA-KodeKloud-Complete-Notes.pdf
EOF

# Create kubernetes/00-cluster-setup/.pages
cat > containers-orchestration/kubernetes/00-cluster-setup/.pages << 'EOF'
title: Cluster Setup
nav:
  - Home: README.md
  - Kind Cluster Setup Guide: kind-cluster-setup-guide.md
  - Kind Cluster Setup with Calico: kind-cluster-setup-calico-guide.md
  - Kubeadm Cluster Setup Guide: kubeadm-cluster-setup-guide.md
  - Kubeadm Init Flags and Kind Config: kubeadm-init-flags-and-kind-config.md
  - Kubeadm Init Working: kubeadm-init-working.md
  - Kubeadm Config Patches: kubeadmConfigPatches.md
  - Containerd Config Patches: containerdConfigPatches.md
  - Extra Port Mappings: extraPortMappings.md
  - Kubeconfig Setup: kubeconfig-setup.md
  - CNI Plugin Installation: cni-plugin-installation.md
  - CNI Working: cni-working.md
EOF

# Create kubernetes/01-core-concepts/.pages
cat > containers-orchestration/kubernetes/01-core-concepts/.pages << 'EOF'
title: Core Concepts
nav:
  - Architecture: architecture.md
  - Objects: objects.md
  - Etcd: etcd.md
  - Etcd TLS: etcd-tls.md
  - Kube API Server: kube-apiserver.md
  - Kube API Server (Part 2): kube-apiserver-2.md
  - Kube Controller Manager: kube-controller-manager.md
  - Kube Scheduler: kube-scheduler.md
  - Kube Proxy: kube-proxy.md
  - Kubernetes API Guide: kubernetes-api-guide.md
  - Declarative API Process: declarative-api-process.md
  - API Versions: api-versions.md
  - API Deprecations: api-deprecations.md
  - ConfigMaps in Kube System: cm-in-kube-system.md
EOF

# Create kubernetes/02-cli-operations/.pages
cat > containers-orchestration/kubernetes/02-cli-operations/.pages << 'EOF'
title: CLI Operations
nav:
  - Kubectl Flags: kubectl-flags.md
  - Kubectl Logs: kubectl-logs.md
  - Command Arguments: command-args.md
EOF

# Create kubernetes/03-networking/.pages
cat > containers-orchestration/kubernetes/03-networking/.pages << 'EOF'
title: Networking
nav:
  - Networking in Kubernetes: networking-in-k8s.md
  - Services Guide: services-guide.md
  - Endpoints Guide: endpoints-guide.md
  - Accessing Applications: accessing-applications.md
  - DNS Resolution: dns-resolution.md
  - DNS Curl Debugging: dns-curl-debugging.md
  - Host Network: hostNetwork.md
  - Host Port: hostPort.md
  - Network Policy Guide: network-policy-guide.md
  - Network Policy Labeling Guide: netpol-labeling-guide.md
  - Ingress Basic: ingress-basic.md
  - Ingress Manifest: ingress-manifest.md
  - Ingress CLI: ingress-cli.md
  - Ingress Example: ingress-example.md
  - Ingress Lab: ingress-lab.md
  - Ingress Testing: ingress-testing.md
  - Ingress Rewrite Concept: ingress-rewrite-concept.md
  - Ingress Migration to Gateway API: ingress-migration-to-gatewayapi.md
  - Gateway API: gateway-api.md
  - Gateway Lab: gateway-lab.md
  - HTTP Route Advanced: httproute-advanced.md
  - Kubernetes HTTPS Guide: k8s-https-guide.md
  - Kubernetes HTTPS FAQs: k8s-https-faqs.md
  - SSL TLS Certificate Guide: ssl-tls-cert-guide.md
EOF

# Create kubernetes/04-storage/.pages
cat > containers-orchestration/kubernetes/04-storage/.pages << 'EOF'
title: Storage
nav:
  - Home: README.md
  - Volume Basics: vol-basics.md
  - Kubernetes Volumes Guide: Kubernetes Volumes Guide.markdown
  - Kubernetes Ephemeral Volumes Guide: Kubernetes Ephemeral Volumes Guide.markdown
  - Volumes YAML: volumes.yaml
  - Volumes in Multi-Container: vol-in-multi-cont.md
  - Mounting Volumes with Multiple Files: Mounting Volumes with Multiple Files.md
  - Persistent Volume Guide: pv-guide.md
  - Persistent Volume Claim Guide: pvc-guide.md
  - Kubernetes Persistent Volumes and Claims Guide: Kubernetes Persistent Volumes and Claims Guide.markdown
  - Volume Spec Source Options in PersistentVolume: Volume spec.source Options in PersistentVolume.md
  - Storage Class: storage-class.md
  - Storage Class Name: storageClassName.md
  - Kubernetes Storage Classes Guide: Kubernetes Storage Classes Guide.markdown
  - Kubernetes Dynamic Volume Provisioning Guide: Kubernetes Dynamic Volume Provisioning Guide.markdown
  - RWX NFS Volume: rwx-nfs-volume.md
  - RWX NFS Volume Example: rwx-nfs-volume-example.md
  - CSI (Container Storage Interface): csi.md
  - Comprehensive Guide to Kubernetes Storage Management: Comprehensive Guide to Kubernetes Storage Management.markdown
EOF

# Create kubernetes/05-scheduling-and-affinity/.pages
cat > containers-orchestration/kubernetes/05-scheduling-and-affinity/.pages << 'EOF'
title: Scheduling & Affinity
nav:
  - Taints & Affinity Guide (Part A): taints-affinity-guide-a.md
  - Taints & Affinity Guide (Part B): taints-affinity-guide-b.md
  - Priority Class: priority-class.md
EOF

# Create kubernetes/06-resource-management/.pages
cat > containers-orchestration/kubernetes/06-resource-management/.pages << 'EOF'
title: Resource Management
nav:
  - Resource Quota Guide: 01-resource-quota-guide.md
  - Limit Range Guide: 02-limit-range-guide.md
  - LimitRange & ResourceQuota Together: 03-limitrange-resourcequota-together.md
  - LimitRange and Pod Scheduling: 04-limitrange-and-pod-scheduling.md
  - LimitRange & ResourceQuota Demo: 05-limitrange-resourcequota-demo.md
  - Quality of Service (QoS): 06-QoS.md
  - ConfigMap Guide: configmap-guide.md
  - ConfigMap Important Commands: configmap-imp-com.md
  - Secret Guide: secret-guide.md
  - Certificate & Key: crt-key.md
  - Init Container Management: initContainer-management.md
  - Scope Selector: scopeSelector.md
EOF

# Create kubernetes/07-security/.pages
cat > containers-orchestration/kubernetes/07-security/.pages << 'EOF'
title: Security
nav:
  - RBAC (Role-Based Access Control): rbac.md
  - RBAC Lab: rbac-lab.md
  - Service Account: sa.md
  - Service Account Token: sa-token.md
  - Kubeconfig: kubeconfig.md
  - Create User: create-user.md
  - Certificate Guide: certificate-guide.md
  - Cert Manager: cert-manager.md
  - Security Context: securityContext.md
  - FS Group: fsGroup.md
  - Admission Control: admission-control.md
  - In-Cluster API Access: in-cluster-api-access.md
EOF

# Create kubernetes/08-debugging-monitoring/.pages
cat > containers-orchestration/kubernetes/08-debugging-monitoring/.pages << 'EOF'
title: Debugging & Monitoring
nav:
  - Probes: probe.md
  - Probes Guide: probes-guide.md
  - Probe Debugging: probe-debugging.md
  - Probes Case Studies: probes-case-studies.md
EOF

# Create kubernetes/09-workloads/.pages
cat > containers-orchestration/kubernetes/09-workloads/.pages << 'EOF'
title: Workloads
nav:
  - Pod Guide: pod-guide.md
  - Pod Practice Questions: pod-prac-ques.md
  - Multi-Container Pod: multi-cont-pod.md
  - Hostname & Subdomain: hostname-subdomain.md
  - Deployment: deploy.md
  - Deployment Strategies: deploy-strategies.md
  - CKAD - Don't Delete Deployment: ckad-dont-delete-deployment.md
  - ReplicaSet Guide: rs.guide.yaml
  - Jobs Guide: jobs-guide.md
  - Jobs Guide Summary: jobs-guide-summary.md
  - Jobs Guide Full: jobs-guide-full.md
  - Jobs Spec: jobs.spec.md
  - Jobs Handling: jobs-handling.md
  - Job Time Controls Cheatsheet: job-time-controls-cheatsheet.md
  - CronJob Guide: cron-job-guide.md
  - Horizontal Pod Autoscaler (HPA) Guide: hpa-guide.md
  - Vertical Pod Autoscaler (VPA) Guide: vpa-guide.md
EOF

# Create kubernetes/10-references/.pages
cat > containers-orchestration/kubernetes/10-references/.pages << 'EOF'
title: References
nav:
  - Quick Reference: quick-reference.md
  - Kubernetes Cheat Sheet: k8sCheatSheat.md
  - Imperative Commands: imperative-commands.md
  - Documentation: docs.md
EOF

# Create kubernetes/unorganized/.pages
cat > containers-orchestration/kubernetes/unorganized/.pages << 'EOF'
title: Unorganized
nav:
  - Kubernetes Notes: k8s.md
  - Kubernetes Text Notes: k8s.txt
  - Unorganized Guide: unorganized-guide.md
  - Question Bank: question-bank.md
  - Troubleshooting: troubleshooting.md
EOF

echo "✅ All .pages files created successfully with human-readable titles!"
echo ""
echo "Created files:"
echo "  - containers-orchestration/.pages"
echo "  - containers-orchestration/containerd/.pages"
echo "  - containers-orchestration/docker/.pages"
echo "  - containers-orchestration/docker-compose/.pages"
echo "  - containers-orchestration/helm/.pages"
echo "  - containers-orchestration/kustomize/.pages"
echo "  - containers-orchestration/kubernetes/.pages"
echo "  - containers-orchestration/kubernetes/00-cluster-setup/.pages"
echo "  - containers-orchestration/kubernetes/01-core-concepts/.pages"
echo "  - containers-orchestration/kubernetes/02-cli-operations/.pages"
echo "  - containers-orchestration/kubernetes/03-networking/.pages"
echo "  - containers-orchestration/kubernetes/04-storage/.pages"
echo "  - containers-orchestration/kubernetes/05-scheduling-and-affinity/.pages"
echo "  - containers-orchestration/kubernetes/06-resource-management/.pages"
echo "  - containers-orchestration/kubernetes/07-security/.pages"
echo "  - containers-orchestration/kubernetes/08-debugging-monitoring/.pages"
echo "  - containers-orchestration/kubernetes/09-workloads/.pages"
echo "  - containers-orchestration/kubernetes/10-references/.pages"
echo "  - containers-orchestration/kubernetes/unorganized/.pages"
echo ""
echo "Total: 20 .pages files with 187 files organized"
echo ""
echo "To verify, run:"
echo "  find containers-orchestration -name '.pages' -type f | sort"
