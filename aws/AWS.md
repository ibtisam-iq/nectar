This is test.

what was earlier in the companies, then virtualization, then cloud

private vs public vs hybrid cloud

why public cloud becomes popular

major cloud providers

---

IAM
what is IAM?
why IAM is important
types of IAM
components of IAM
what problem it solves: authentication and authorization

Network interface is associated with Security Group, to delete a Security Group, you need to delete all the Network Interfaces associated with it.
If there is a VPC association, you first need to delete the VPC association before you can delete the Security Group.
Whenever an VPC is created, a default Security Group is created. You can't delete the default Security Group.

Deleting the auto scaling group will delete the instances, but the launch configuration will still exist.
There is no need to delete the launch configuration, it will be automatically deleted when the auto scaling group is deleted.
There is no need to delete the network interface, it will be automatically deleted when the resources associated to it are deleted.

# AWS Default Resources on VPC Creation

When you create a **VPC**, AWS automatically creates the following resources:

## ✅ Created by Default
### 1️⃣ Default Security Group (SG)
- **1 SG per VPC** (cannot be deleted).
- **By default:** Allows traffic **only within the same SG** (instances can talk to each other).

### 2️⃣ Default Route Table
- **1 main route table per VPC** (named **"Main"** in AWS).
- **By default:** No internet access (only internal VPC traffic).

### 3️⃣ Default Network ACL (NACL)
- **1 default NACL per VPC.**
- **By default:** **Allows all inbound & outbound traffic** (stateless firewall).
- Can be modified but **cannot be deleted**.

### 4️⃣ Default DHCP Option Set
- Used for **automatic IP assignment & DNS resolution**.
- **By default:** Uses AWS-provided DNS servers.
- **Cannot be deleted**, but you can create a custom one.

---

## ❌ Not Created by Default (Must Be Created Manually)
| Resource            | Created by Default? | Can You Delete? | Default Behavior |
|---------------------|----------------|---------------|----------------|
| **Subnets**         | ❌ No  | N/A | Must be created manually |
| **Internet Gateway (IGW)** | ❌ No  | N/A | Must be created for internet access |
| **NAT Gateway**     | ❌ No  | N/A | Must be created for private subnet internet access |

---

## 🔹 Summary
- Every new VPC **automatically gets** a Security Group, Route Table, NACL, and DHCP options.
- **Subnets, IGW, and NAT Gateway** must be created manually depending on your architecture.


