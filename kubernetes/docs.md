# 📘 Kubernetes Docs — Personal Reference (CKA Focused)

A curated collection of official Kubernetes documentation links for quick navigation and CKA prep. Grouped by topic, sorted by importance.

---

## 📌 General Docs
- [Kubernetes Documentation (Home)](https://kubernetes.io/docs/home/)
- [Concepts Overview](https://kubernetes.io/docs/concepts/)

---

## 🚀 Getting Started
- [Getting Started](https://kubernetes.io/docs/setup/)
- [Production Environment Setup](https://kubernetes.io/docs/setup/production-environment/)
  - [Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
  - [Deployment Tools](https://kubernetes.io/docs/setup/production-environment/tools/)
    - [Kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)

---

## Concepts
- Overview
    - Kubernetes Components
    - Objects In Kubernetes
        - Kubernetes Object Management
        - Object Names and IDs
        - Labels and Selectors
        - Namespaces
        - Annotations
        - Field Selectors
        - Finalizers
        - Owners and Dependents
        - Recommended Labels
    - The Kubernetes API
- Cluster Architecture
    - Nodes
    - Communication between Nodes and the Control Plane
    - Controllers
    - Leases
    - Cloud Controller Manager
    - About cgroup v2
    - Kubernetes Self-Healing
    - Container Runtime Interface (CRI)
    - Garbage Collection
    - Mixed Version Proxy
- Containers
    - Images
    - Container Environment
    - Runtime Class
    - Container Lifecycle Hooks
- Workloads
    - Pods
        - Pod Lifecycle
        - Init Containers
        - Sidecar Containers
        - Ephemeral Containers
        - Disruptions
        - Pod Quality of Service Classes
        - User Namespaces
        - Downward API
    - Workload Management
        - Deployments
        - ReplicaSet
        - StatefulSets
        - DaemonSet
        - Jobs
        - Automatic Cleanup for Finished Jobs
        - CronJob
        - ReplicationController
    - Autoscaling Workloads
    - Managing Workloads
- Services, Load Balancing, and Networking
    - Service
    - Ingress
    - Ingress Controllers
    - Gateway API
    - EndpointSlices
    - Network Policies
    - DNS for Services and Pods
    - IPv4/IPv6 dual-stack
    - Topology Aware Routing
    - Networking on Windows
    - Service ClusterIP allocation
    - Service Internal Traffic Policy
- Storage
    - Volumes
    - Persistent Volumes
    - Projected Volumes
    - Ephemeral Volumes
    - Storage Classes
    - Volume Attributes Classes
    - Dynamic Volume Provisioning
    - Volume Snapshots
    - Volume Snapshot Classes
    - CSI Volume Cloning
    - Storage Capacity
    - Node-specific Volume Limits
    - Volume Health Monitoring
    - Windows Storage
- Configuration
    - Configuration Best Practices
    - ConfigMaps
    - Secrets
    - Liveness, Readiness, and Startup Probes
    - Resource Management for Pods and Containers
    - Organizing Cluster Access Using kubeconfig Files
    - Resource Management for Windows nodes
- Security
    - Cloud Native Security
    - Pod Security Standards
    - Pod Security Admission
    - Service Accounts
    - Pod Security Policies
    - Security For Windows Nodes
    - Controlling Access to the Kubernetes API
    - Role Based Access Control Good Practices
    - Good practices for Kubernetes Secrets
    - Multi-tenancy
    - Hardening Guide - Authentication Mechanisms
    - Kubernetes API Server Bypass Risks
    - Linux kernel security constraints for Pods and containers
    - Security Checklist
    - Application Security Checklist
- Policies
    - Limit Ranges
    - Resource Quotas
    - Process ID Limits And Reservations
    - Node Resource Managers
- Scheduling, Preemption and Eviction
    - Kubernetes Scheduler
    - Assigning Pods to Nodes
    - Pod Overhead
    - Pod Scheduling Readiness
    - Pod Topology Spread Constraints
    - Taints and Tolerations
    - Scheduling Framework
    - Dynamic Resource Allocation
    - Scheduler Performance Tuning
    - Resource Bin Packing
    - Pod Priority and Preemption
    - Node-pressure Eviction
    - API-initiated Eviction
- Cluster Administration
    - Node Shutdowns
    - Node Autoscaling
    - Certificates
    - Cluster Networking
    - Admission Webhook Good Practices
    - Logging Architecture
    - Compatibility Version For Kubernetes Control Plane Components
    - Metrics For Kubernetes System Components
    - Metrics for Kubernetes Object States
    - System Logs
    - Traces For Kubernetes System Components
    - Proxies in Kubernetes
    - API Priority and Fairness
    - Installing Addons
    - Coordinated Leader Election
- Windows in Kubernetes
    - Windows containers in Kubernetes
    - Guide for Running Windows Containers in Kubernetes
- Extending Kubernetes
    - Compute, Storage, and Networking Extensions
        - Network Plugins
        - Device Plugins
    - Extending the Kubernetes API
        - Custom Resources
        - Kubernetes API Aggregation Layer
    - Operator pattern

---

## Tasks

- Install Tools
    - Install and Set Up kubectl on Linux
    - Install and Set Up kubectl on macOS
    - Install and Set Up kubectl on Windows
- Administer a Cluster
    - Administration with kubeadm
        - Adding Linux worker nodes
        - Adding Windows worker nodes
        - Upgrading kubeadm clusters
        - Upgrading Linux nodes
        - Upgrading Windows nodes
        - Configuring a cgroup driver
        - Certificate Management with kubeadm
        - Reconfiguring a kubeadm cluster
        - Changing The Kubernetes Package Repository
    - Overprovision Node Capacity For A Cluster
    - Migrating from dockershim
        - Changing the Container Runtime on a Node from Docker Engine to containerd
        - Find Out What Container Runtime is Used on a Node
        - Troubleshooting CNI plugin-related errors
        - Check whether dockershim removal affects you
        - Migrating telemetry and security agents from dockershim
    - Generate Certificates Manually
    - Manage Memory, CPU, and API Resources
        - Configure Default Memory Requests and Limits for a Namespace
        - Configure Default CPU Requests and Limits for a Namespace
        - Configure Minimum and Maximum Memory Constraints for a Namespace
        - Configure Minimum and Maximum CPU Constraints for a Namespace
        - Configure Memory and CPU Quotas for a Namespace
        - Configure a Pod Quota for a Namespace
    - Install a Network Policy Provider
        - Use Antrea for NetworkPolicy
        - Use Calico for NetworkPolicy
        - Use Cilium for NetworkPolicy
        - Use Kube-router for NetworkPolicy
        - Romana for NetworkPolicy
        - Weave Net for NetworkPolicy
    - Access Clusters Using the Kubernetes API
    - Advertise Extended Resources for a Node
    - Autoscale the DNS Service in a Cluster
    - Change the Access Mode of a PersistentVolume to ReadWriteOncePod
    - Change the default StorageClass
    - Switching from Polling to CRI Event-based Updates to Container Status
    - Change the Reclaim Policy of a PersistentVolume
    - Cloud Controller Manager Administration
    - Configure a kubelet image credential provider
    - Configure Quotas for API Objects
    - Control CPU Management Policies on the Node
    - Control Topology Management Policies on a node
    - Customizing DNS Service
    - Debugging DNS Resolution
    - Declare Network Policy
    - Developing Cloud Controller Manager
    - Enable Or Disable A Kubernetes API
    - Encrypting Confidential Data at Rest
    - Decrypt Confidential Data that is Already Encrypted at Rest
    - Guaranteed Scheduling For Critical Add-On Pods
    - IP Masquerade Agent User Guide
    - Limit Storage Consumption
    - Migrate Replicated Control Plane To Use Cloud Controller Manager
    - Namespaces Walkthrough
    - Operating etcd clusters for Kubernetes
    - Reserve Compute Resources for System Daemons
    - Running Kubernetes Node Components as a Non-root User
    - Safely Drain a Node
    - Securing a Cluster
    - Set Kubelet Parameters Via A Configuration File
    - Share a Cluster with Namespaces
    - Upgrade A Cluster
    - Use Cascading Deletion in a Cluster
    - Using a KMS provider for data encryption
    - Using CoreDNS for Service Discovery
    - Using NodeLocal DNSCache in Kubernetes Clusters
    - Using sysctls in a Kubernetes Cluster
    - Utilizing the NUMA-aware Memory Manager
    - Verify Signed Kubernetes Artifacts
- Configure Pods and Containers
    - Assign Memory Resources to Containers and Pods
    - Assign CPU Resources to Containers and Pods
    - Assign Pod-level CPU and memory resources
    - Configure GMSA for Windows Pods and containers
    - Resize CPU and Memory Resources assigned to Containers
    - Configure RunAsUserName for Windows pods and containers
    - Create a Windows HostProcess Pod
    - Configure Quality of Service for Pods
    - Assign Extended Resources to a Container
    - Configure a Pod to Use a Volume for Storage
    - Configure a Pod to Use a PersistentVolume for Storage
    - Configure a Pod to Use a Projected Volume for Storage
    - Configure a Security Context for a Pod or Container
    - Configure Service Accounts for Pods
    - Pull an Image from a Private Registry
    - Configure Liveness, Readiness and Startup Probes
    - Assign Pods to Nodes
    - Assign Pods to Nodes using Node Affinity
    - Configure Pod Initialization
    - Attach Handlers to Container Lifecycle Events
    - Configure a Pod to Use a ConfigMap
    - Share Process Namespace between Containers in a Pod
    - Use a User Namespace With a Pod
    - Use an Image Volume With a Pod
    - Create static Pods
    - Translate a Docker Compose File to Kubernetes Resources
    - Enforce Pod Security Standards by Configuring the Built-in Admission Controller
    - Enforce Pod Security Standards with Namespace Labels
    - Migrate from PodSecurityPolicy to the Built-In PodSecurity Admission Controller
- Monitoring, Logging, and Debugging
    - Troubleshooting Applications
        - Debug Pods
        - Debug Services
        - Debug a StatefulSet
        - Determine the Reason for Pod Failure
        - Debug Init Containers
        - Debug Running Pods
        - Get a Shell to a Running Container
    - Troubleshooting Clusters
        - Troubleshooting kubectl
        - Resource metrics pipeline
        - Tools for Monitoring Resources
        - Monitor Node Health
        - Debugging Kubernetes nodes with crictl
        - Auditing
        - Debugging Kubernetes Nodes With Kubectl
        - Developing and debugging services locally using telepresence
        - Windows debugging tips
- Manage Kubernetes Objects
    - Declarative Management of Kubernetes Objects Using Configuration Files
    - Declarative Management of Kubernetes Objects Using Kustomize
    - Managing Kubernetes Objects Using Imperative Commands
    - Imperative Management of Kubernetes Objects Using Configuration Files
    - Update API Objects in Place Using kubectl patch
    - Migrate Kubernetes Objects Using Storage Version Migration
- Managing Secrets
    - Managing Secrets using kubectl
    - Managing Secrets using Configuration File
    - Managing Secrets using Kustomize
- Inject Data Into Applications
    - Define a Command and Arguments for a Container
    - Define Dependent Environment Variables
    - Define Environment Variables for a Container
    - Expose Pod Information to Containers Through Environment Variables
    - Expose Pod Information to Containers Through Files
    - Distribute Credentials Securely Using Secrets
- Run Applications
    Run a Stateless Application Using a Deployment
    Run a Single-Instance Stateful Application
    Run a Replicated Stateful Application
    Scale a StatefulSet
    Delete a StatefulSet
    Force Delete StatefulSet Pods
    Horizontal Pod Autoscaling
    HorizontalPodAutoscaler Walkthrough
    Specifying a Disruption Budget for your Application
    Accessing the Kubernetes API from a Pod
- Run Jobs
    Running Automated Tasks with a CronJob
    Coarse Parallel Processing Using a Work Queue
    Fine Parallel Processing Using a Work Queue
    Indexed Job for Parallel Processing with Static Work Assignment
    Job with Pod-to-Pod Communication
    Parallel Processing using Expansions
    Handling retriable and non-retriable pod failures with Pod failure policy
- Access Applications in a Cluster
    Deploy and Access the Kubernetes Dashboard
    Accessing Clusters
    Configure Access to Multiple Clusters
    Use Port Forwarding to Access Applications in a Cluster
    Use a Service to Access an Application in a Cluster
    Connect a Frontend to a Backend Using Services
    Create an External Load Balancer
    List All Container Images Running in a Cluster
    Set up Ingress on Minikube with the NGINX Ingress Controller
    Communicate Between Containers in the Same Pod Using a Shared Volume
    Configure DNS for a Cluster
    Access Services Running on Clusters
- Extend Kubernetes
    - Configure the Aggregation Layer
    - Use Custom Resources
        - Extend the Kubernetes API with CustomResourceDefinitions
        - Versions in CustomResourceDefinitions
    - Set up an Extension API Server
    - Configure Multiple Schedulers
    - Use an HTTP Proxy to Access the Kubernetes API
    - Use a SOCKS5 Proxy to Access the Kubernetes API
    - Set up Konnectivity service
- TLS
    - Issue a Certificate for a Kubernetes API Client Using A CertificateSigningRequest
    - Configure Certificate Rotation for the Kubelet
    - Manage TLS Certificates in a Cluster
    - Manual Rotation of CA Certificates
- Manage Cluster Daemons
    - Building a Basic DaemonSet
    - Perform a Rolling Update on a DaemonSet
    - Perform a Rollback on a DaemonSet
    - Running Pods on Only Some Nodes
- Networking
    - Adding entries to Pod /etc/hosts with HostAliases
    - Extend Service IP Ranges
    - Validate IPv4/IPv6 dual-stack
- Extend kubectl with plugins
- Manage HugePages
- Schedule GPUs

---

## Tutorials

