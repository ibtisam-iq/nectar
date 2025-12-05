# Introduction to Cloud Computing

## 1. The Evolution of IT Infrastructure

### **Before Cloud: The Era of Physical Servers**
In the early days of IT infrastructure, companies relied on **physical servers** to host applications and store data. This approach came with several challenges:

| Challenges | Description |
|------------|------------|
| **High Upfront Costs** | Organizations had to purchase expensive hardware. |
| **Maintenance Overhead** | Physical space, cooling, and power were required to keep servers operational. |
| **Scalability Issues** | Expanding capacity required purchasing and installing new servers, which was time-consuming and costly. |
| **Underutilization of Resources** | Many servers ran at low capacity, leading to wasted computing power and inefficiencies. |

### **The Rise of Virtualization**
To address the inefficiencies of physical servers, **virtualization** technology was introduced. Virtualization allows multiple **Virtual Machines (VMs)** to run on a single physical server using a **hypervisor** (e.g., VMware, Hyper-V, KVM). 

#### **How Virtualization Works**
- A **hypervisor** (software layer) sits on top of the physical server.
- It allows multiple **virtual machines (VMs)** to run independently on the same physical hardware.
- Each VM has its own **operating system and applications**.

| Benefits of Virtualization | Description |
|----------------------------|------------|
| **Better Resource Utilization** | Multiple VMs on one server reduced hardware waste. |
| **Improved Scalability** | Organizations could create or remove VMs as needed. |
| **Increased Fault Tolerance** | VMs could be migrated between physical servers, reducing downtime. |
| **Reduced Costs** | Fewer physical machines meant lower operational expenses. |

#### **Types of Virtualization**
Virtualization is classified into different types based on what is being virtualized:

| Type | Description | Example Software |
|------|------------|------------------|
| **Server Virtualization** | Multiple virtual servers run on a single physical machine. | VMware vSphere, Microsoft Hyper-V, KVM |
| **Desktop Virtualization** | Users can run multiple OS environments on one physical computer. | Citrix Virtual Apps, VMware Horizon |
| **Storage Virtualization** | Abstracts physical storage from servers to improve management. | NetApp ONTAP, IBM Spectrum Virtualize |
| **Network Virtualization** | Virtual networks are created within a physical network for better flexibility. | Cisco ACI, VMware NSX |
| **Application Virtualization** | Applications run in isolated environments without full installation. | Microsoft App-V, Citrix XenApp |

#### **Types of Hypervisors**
Hypervisors are categorized into two types:

| Hypervisor Type | Description | Examples |
|---------------|------------|------------|
| **Type 1 (Bare Metal Hypervisor)** | Runs directly on the physical hardware, providing better performance and security. Used in enterprise data centers. | VMware ESXi, Microsoft Hyper-V, Xen |
| **Type 2 (Hosted Hypervisor)** | Runs on top of an existing operating system, making it more suitable for personal use and testing. | VMware Workstation, Oracle VirtualBox, Parallels |

### **Emergence of Cloud Computing**
While virtualization improved efficiency, organizations still had to manage their own **data centers, networking, and security**. This led to the birth of **Cloud Computing**, where IT resources were provided as **on-demand services** over the internet.

**Key Innovations That Led to Cloud Computing:**
1. **Advancements in Virtualization** – Enabled better resource allocation.
2. **Increased Internet Speeds** – Allowed seamless access to remote resources.
3. **Pay-As-You-Go Pricing** – Eliminated upfront investments in hardware.
4. **Need for Global Scalability** – Companies needed infrastructure that could scale instantly.

## 2. What is IT Infrastructure?
IT Infrastructure refers to the combination of hardware, software, networks, and facilities that organizations use to develop, test, deliver, and manage IT services.

### **Components of IT Infrastructure**

| Component | Description | Example |
|-----------|------------|------------|
| **Hardware** | Physical devices like servers, storage, and networking equipment. | Dell Servers, Cisco Routers |
| **Software** | Operating systems, applications, and management tools. | Windows Server, Linux, VMware |
| **Networking** | Connectivity between devices, including switches, routers, and firewalls. | Cisco Switches, Juniper Firewalls |
| **Data Storage** | Solutions to store and manage enterprise data. | SAN, NAS, Cloud Storage |
| **Security** | Tools to protect IT assets from threats and unauthorized access. | Firewalls, Antivirus, IAM |
| **Cloud Services** | Infrastructure provided over the internet to reduce physical dependency. | AWS, Azure, GCP |

## 3. What is Cloud Computing?
Cloud Computing is the **delivery of computing services** (servers, storage, databases, networking, software) over the internet, allowing users to access resources **on demand** without physical infrastructure management.

### **Key Characteristics of Cloud Computing**
1. **On-Demand Self-Service** – Users can provision resources as needed without human intervention.
2. **Broad Network Access** – Services are accessible via the internet from any device.
3. **Resource Pooling** – Cloud providers use shared resources to serve multiple customers.
4. **Rapid Elasticity** – Resources can scale up/down automatically based on demand.
5. **Measured Service** – Users only pay for what they consume, reducing costs.

## 4. Cloud Service Models (IaaS, PaaS, SaaS)
Cloud computing is categorized into three major service models:

### **Infrastructure as a Service (IaaS)**
- Provides **virtualized computing resources** over the internet.
- Users manage OS, applications, and data; provider manages hardware.
- **Examples:** AWS EC2, Google Compute Engine.

### **Platform as a Service (PaaS)**
- Offers a **development platform** to build and deploy applications.
- Developers focus on coding; providers handle infrastructure and runtime.
- **Examples:** AWS Elastic Beanstalk, Google App Engine.

### **Software as a Service (SaaS)**
- Delivers **fully managed software applications** over the internet.
- Users don’t manage infrastructure or platform—only use the software.
- **Examples:** Gmail, Microsoft Office 365, Dropbox.

| Cloud Service Model | Responsibility | Examples |
|----------------------|----------------|------------|
| **IaaS** | Users manage OS, applications, networking. | AWS EC2, Google Compute Engine |
| **PaaS** | Users manage applications; provider manages infrastructure. | AWS Elastic Beanstalk, Heroku |
| **SaaS** | Everything managed by the provider. | Gmail, Dropbox |

### **Graph: Cloud Service Model Responsibilities**
```
+-----------------------------------+
| SaaS (Software as a Service)      |
| (Managed: Infrastructure + App)  |
+-----------------------------------+
         ↑
+-----------------------------------+
| PaaS (Platform as a Service)      |
| (Managed: Infrastructure)         |
+-----------------------------------+
         ↑
+-----------------------------------+
| IaaS (Infrastructure as a Service)|
| (Managed: Compute, Storage, Network)|
+-----------------------------------+
```

