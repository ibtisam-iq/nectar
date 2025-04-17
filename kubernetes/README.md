# Kubernetes : A Deep Dive 

> 📦 **Part of the [Nectar](https://github.com/ibtisam-iq/nectar) Project** — a curated DevOps knowledge base and toolkit by [`Muhammad Ibtisam Iqbal`](https://www.linkedin.com/in/ibtisam-iq/).

Welcome to the **Kubernetes section of Nectar**!  
This guide provides a structured, beginner-to-advanced walkthrough of Kubernetes concepts, cluster setup, networking, workload management, and security — backed by clear examples and linked documentation.

Whether you're starting out or refining your Kubernetes skills, this space is designed to make complex ideas approachable and practical.

---

### 📂 Related Repositories You’ll Love

This section is part of a broader effort to make Kubernetes mastery easier, faster, and well-documented.  
Don’t miss out on these highly useful, complementary repositories:

- 🌿 **[SilverKube](https://github.com/ibtisam-iq/SilverKube)**  
  A dedicated collection of ready-to-use **YAML manifests** and stack configurations for various Kubernetes objects — perfect for hands-on practice, quick deployments, and configuration inspiration.

- 🎓 **[CKA-and-CKAD-prep](https://github.com/ibtisam-iq/CKA-and-CKAD-prep)**  
  Your go-to preparation companion for the **Certified Kubernetes Administrator (CKA)** and **Certified Kubernetes Application Developer (CKAD)** exams — covering every exam objective, complete with labs, imperative commands, and official doc links.

👉 Dive into these repos — each one crafted to complement your Kubernetes journey.

---

## 🌱 Overview of Kubernetes

**Kubernetes** (K8s) is an open-source platform that automates the deployment, scaling, and management of containerized applications. Originating from Google’s Borg system, it became the industry standard for container orchestration in 2014. Kubernetes simplifies managing microservices, ensuring **high availability**, **scalability**, and **resilience** in cloud-native environments.

---

## 🤩 Core Concepts

Kubernetes follows a **cluster-based [architecture](architecture.md)**, consisting of a control plane and worker nodes:
- **Control Plane:** Manages cluster state and schedules workloads  
- **Worker Nodes:** Run containerized applications  

Key [objects](objects.md) include:
- **Pods:** Smallest deployable units, encapsulating containers  
- **Deployments:** Manage stateless applications  
- **StatefulSets:** Manage stateful workloads  

It uses a **[declarative API](declarative-api-process.md)**, letting you define desired states in [YAML manifests](https://github.com/ibtisam-iq/nectar/tree/main/yaml), continuously reconciled by the system.

---

## ⚙️ Cluster Setup & Configuration

[Cluster setup](./cluster-setup/README.md) involves configuring:
- **Control plane components** (API server, controller manager, scheduler)  
- **Node networking**  

Important resources:
- [ConfigMaps](configmap-guide.md) for dynamic configuration  
- [Secrets](secret-guide.md) for secure data management  
- [Resource Quotas](resource-quota-guide.md) and [Limit Ranges](limit-range-guide.md) for [enforcing resource boundaries](limitrange-resourcequota-together.md) 

👉 See how to manage them together: [Resource Management Demo](limitrange-resourcequota-demo.md)

---

## 🚀 Workload Management

Kubernetes manages various workloads:
- **[Jobs](jobs-guide.md)** & **[CronJobs](cron-job-guide.md)** for batch/scheduled tasks  
- **Deployments** & **ReplicaSets** for stateless apps  
- **[Persistent Volumes (PVs)](pv-guide.md)** & **[PVCs](pvc-guide.md)** for stable [storage](storage-guide.md)
- **[StorageClasses](storage-class.md)** for dynamic provisioning  

Advanced storage:
- **[fsGroup](fsGroup.md)** for file system permissions  
- **[ReadWriteMany NFS Volumes](rwx-nfs-volume.md)** for concurrent multi-pod access  

---

## 🌐 Networking & Ingress

[Kubernetes networking](networking-in-k8s.md) uses a **flat network model**.  
Key concepts:
- **ClusterIP Services** for internal communication  
- **[Ingress](ingress-guide.md)** for external traffic routing, SSL termination, and load balancing  
- **[Network Policies](network-policy-guide.md)** for pod-level access control  

👉 Master your [Ingress controllers and configs](ingress-guide.md)

---

## 🔒 Security Best Practices

Kubernetes secures workloads through:
- **[RBAC](rbac.md)** for user/workload permissions  
- **[Security Contexts](securityContext.md)** for pod-level restrictions  
- **Secrets** for API keys and credentials  
- **Pod Security Policies (deprecated)** and **admission controllers** for policy enforcement  
- **[Taints and Tolerations](taints-affinity-guide-1.md)** for node workload isolation  

---

## 📈 Scaling & Resource Management

Kubernetes enables:
- **Horizontal scaling:** Adjust replicas via **Horizontal Pod Autoscalers (HPAs)**  
- **Vertical scaling:** Tune resources via **Vertical Pod Autoscalers (VPAs)**  
- **[Quotas](resource-quota-guide.md)** & **[Limit Ranges](limit-range-guide.md)** for fair usage enforcement  

---

## 🛠️ Debugging & Monitoring

Troubleshooting essentials:
- **[Logs & Events](kubectl-logs.md)** via `kubectl`  
- **[Probes (Liveness, Readiness, Startup)](probes-case-studies.md)** for pod health checks  
- Monitoring with **Prometheus**, **Grafana**, and **logging stacks** (Fluentd/Elasticsearch)

---

## 🎛️ Advanced Features

For production-ready clusters:
- **[Taints & Tolerations](taints-affinity-guide-1.md)** for node scheduling  
- **Affinity/Anti-Affinity rules** for workload colocation and separation  
- **Custom Resource Definitions (CRDs)** and **Operators** for extending Kubernetes  
- Node-specific scheduling with **Node Affinity**  

---

## 📚 Quick References & Official Documentation

[Quick references](quick-reference.md) and [cheatsheets](k8sCheatSheat.md) offer:
- Concise [imperative `kubectl` commands](imperative-commands.md)  
- Handy [flags](kubectl-flags.md)  
- Direct links to [official documentation](docs.md)  

They accelerate troubleshooting, simplify operations, and reinforce best practices.

## Contributing

Contributions are welcome! If you have additional guides, best practices, or corrections, please submit a pull request.


