# Cloud Computing — Introduction & Fundamentals

## 1. IT Infrastructure

**Definition:** The combination of hardware, software, networks, and facilities used to develop, test, deliver, and manage IT services.

| Component | Description | Example |
|-----------|-------------|---------|
| **Hardware** | Physical devices: servers, storage, networking | Dell Servers, Cisco Routers |
| **Software** | OS, apps, management tools | Windows Server, Linux, VMware |
| **Networking** | Switches, routers, firewalls | Cisco Switches, Juniper Firewalls |
| **Data Storage** | Enterprise data management solutions | SAN, NAS, Cloud Storage |
| **Security** | Protection against threats and unauthorized access | Firewalls, Antivirus, IAM |
| **Cloud Services** | Internet-based infra to reduce physical dependency | AWS, Azure, GCP |

---

## 2. Evolution Timeline

| Era | What Existed | Core Problem |
|-----|-------------|--------------|
| 80s–2000s | Physical Data Centers | Owned, built, and managed everything yourself |
| 2000s | Virtualization | Fixed hardware waste and isolation issues |
| Post-Virtualization | Remote-managed VDCs | Still needed physical access for control |
| Today | Cloud Computing | Internet-based, on-demand, pay-as-you-go |

---

## 3. Problems with Physical Data Centers

| # | Problem | Why It Hurts |
|---|---------|-------------|
| 1 | High upfront cost | Buy all servers before knowing actual need |
| 2 | Unequal resource needs | Cart (low CPU) and Payment (high CPU) given same machine |
| 3 | No resource sharing | Idle RAM/CPU on Server A cannot help Server B |
| 4 | Uncertain demand | Over-provision = waste; Under-provision = crash |
| 5 | One OS per server | Dependency conflicts (Python 3.12 vs 3.8 on same machine) |

---

## 4. Virtualization

**Definition:** Creating multiple Virtual Machines (VMs) on a single physical machine using a hypervisor.

### Benefits

| Benefit | What It Solves |
|---------|---------------|
| Better resource utilization | Multiple VMs on one server reduce hardware waste |
| Improved scalability | Create/remove VMs as needed |
| Increased fault tolerance | VMs can be migrated between servers, reducing downtime |
| Reduced costs | Fewer physical machines = lower operational expenses |

### Types of Virtualization

| Type | What Gets Virtualized | Example Software |
|------|-----------------------|-----------------|
| **Server** | Multiple virtual servers on one physical machine | VMware vSphere, Hyper-V, KVM |
| **Desktop** | Multiple OS environments on one computer | Citrix Virtual Apps, VMware Horizon |
| **Storage** | Abstracts physical storage from servers | NetApp ONTAP, IBM Spectrum Virtualize |
| **Network** | Virtual networks within a physical network | Cisco ACI, VMware NSX |
| **Application** | Apps run in isolated environments without full install | Microsoft App-V, Citrix XenApp |

### Hypervisor (The Engine Behind Virtualization)

**Definition:** Software/firmware layer that creates and manages VMs.

| | Type 1 (Bare Metal) | Type 2 (Hosted) |
|--|--------------------|--------------------|
| Sits on | Directly on hardware | On top of an OS |
| Stack | `Hardware → Hypervisor → VMs` | `Hardware → OS → Hypervisor → VMs` |
| Performance | ✅ High | ❌ Lower |
| Used in | Production / Cloud | Local dev / Testing |
| Examples | AWS Nitro, Xen, VMware ESXi, Hyper-V | VirtualBox, VMware Workstation, Parallels |

> **Bare Metal** = Hardware with no OS installed. Type 1 hypervisors run directly on bare metal.

---

## 5. Birth of Cloud

**Key innovations that pushed from virtualization → cloud:**

1. **Advancements in Virtualization** — Enabled better resource allocation
2. **Increased Internet Speeds** — Allowed seamless access to remote resources
3. **Pay-As-You-Go Pricing** — Eliminated upfront hardware investments
4. **Need for Global Scalability** — Companies needed instantly scalable infrastructure

A **management layer** (internet-accessible console) was added on top of virtualized data centers → you can now create, delete, and manage resources **from anywhere over the internet**.

---

## 6. Cloud Computing — Official Definition (NIST SP 800-145)

> *"A model for enabling ubiquitous, convenient, on-demand network access to a shared pool of configurable computing resources that can be rapidly provisioned and released with minimal management effort or service provider interaction."*

**Simple version:** Delivery of computing resources (servers, storage, networking, software) over the internet — on-demand, pay-as-you-go.

---

## 7. NIST 5 Essential Characteristics ⭐

| # | Characteristic | What It Means | Example |
|---|---------------|---------------|---------|
| 1 | On-Demand Self-Service | Provision resources anytime, no human approval needed | Launch EC2 at 2 AM instantly |
| 2 | Broad Network Access | Accessible from any device over the internet | Laptop, mobile, anywhere |
| 3 | Resource Pooling (Multi-tenancy) | Provider serves multiple customers from shared hardware dynamically | You don't know which physical server you're on |
| 4 | Rapid Elasticity | Scale up/down instantly and automatically | 2 servers → 100 → back to 2 |
| 5 | Measured Service | Usage tracked and billed (CPU hours, storage, bandwidth) | Pay for exactly what you use |

---

## 8. CapEx vs OpEx ⭐

| | CapEx (Capital Expenditure) | OpEx (Operational Expenditure) |
|--|-----------------------------|---------------------------------|
| What | Upfront investment in physical assets | Ongoing usage-based spending |
| Example | Buy servers for your data center | Pay AWS monthly bill |
| Risk | High — pay before you know demand | Low — pay as you grow |
| Traditional DC | ✅ CapEx-heavy | — |
| Cloud | — | ✅ OpEx model |

> Cloud converts CapEx → OpEx. This is one of the core business reasons companies migrate to cloud.

---

## 9. Cloud Deployment Models

| Model | Who Uses It | Infra Owned By | Key Point |
|-------|------------|----------------|-----------|
| **Public** | Anyone | Provider (AWS, Azure, GCP) | No upfront cost, less control |
| **Private** | Single org only | Organization itself | Full control, high cost |
| **Hybrid** | One org | Both (private + public) | Sensitive data private, scale on public |
| **Community** | Group of orgs with shared needs | Shared / Provider | Hospitals, universities |
| **Multi-Cloud** | One org | Multiple public providers | AWS + Azure together |

> **Important:** Data Center ≠ Private Cloud.
> Data Center + Cloud Software (e.g., OpenStack, VMware vSphere) = Private Cloud

### Hybrid vs Multi-Cloud (Trap Question)

| Hybrid | Multi-Cloud |
|--------|-------------|
| Private + Public combined | Multiple public clouds |
| Mixed model | Same type (all public) |
| Example: On-prem + AWS | Example: AWS + Azure |

---

## 10. Cloud Service Models ⭐

| Model | Provider Manages | You Manage | AWS Example |
|-------|-----------------|------------|-------------|
| **IaaS** | Hardware, networking, virtualization | OS, runtime, apps, data | EC2 |
| **PaaS** | Infra + OS + runtime | Only your app/code | Elastic Beanstalk, EKS (managed) |
| **SaaS** | Everything | Just usage | Gmail, Dropbox, Zoom |
| **FaaS** | Infra + OS + runtime + scaling | Only function code | AWS Lambda |

```
IaaS → PaaS → SaaS → FaaS
Less you manage, but also less control.
```

---

## 11. Common Confusions Resolved ✅

| ❌ Wrong Belief | ✅ Correct Answer |
|----------------|-----------------|
| Virtualization = Cloud | Virtualization is a **building block** of cloud, not cloud itself |
| Data Center = Cloud | DC + cloud software stack = Private Cloud |
| Docker = PaaS | Docker is a **containerization tool**, not a service model |
| Raw Kubernetes = PaaS | Raw K8s = IaaS-like; Managed K8s (EKS, GKE) ≈ PaaS |
| Netlify/Vercel = SaaS | They are **PaaS** — you deploy code, they manage infra |
| Custom software for a client = SaaS | That is software development; SaaS = one product, many users |
| Type 2 hypervisor used in cloud | Type 1 (bare metal) is used in production cloud |

---

## 12. Interview Questions Checklist ✅

- [ ] What is IT Infrastructure and its components?
- [ ] What problems did physical data centers have?
- [ ] What is virtualization and what problem did it solve?
- [ ] What are the 5 types of virtualization?
- [ ] Difference between Type 1 and Type 2 hypervisor?
- [ ] What is bare metal?
- [ ] Why was cloud needed even after virtualization?
- [ ] State the NIST official definition of cloud computing
- [ ] Explain the 5 NIST characteristics of cloud
- [ ] CapEx vs OpEx — how does cloud change this?
- [ ] Public vs Private vs Hybrid vs Multi-Cloud
- [ ] IaaS vs PaaS vs SaaS vs FaaS — with examples
- [ ] Is Docker PaaS? (trap)
- [ ] Is Kubernetes PaaS?
- [ ] Data Center vs Private Cloud?
