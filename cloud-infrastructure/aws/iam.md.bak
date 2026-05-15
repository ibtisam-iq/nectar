# AWS IAM (Identity and Access Management)

## 1. Introduction to IAM

### What is IAM and Why Do We Need It?

Imagine you own a company where different employees need access to different areas. Some should access only the main office, while managers should access financial records. You wouldn’t want everyone to have unrestricted access.

AWS faces the same challenge. IAM (Identity and Access Management) is AWS’s security service that controls **who can access what and how**.

### Problems Before IAM:
- ❌ **No way to create multiple users:** AWS initially had only one root user.
- ❌ **No fine-grained access control:** Everyone had the same access.
- ❌ **Risk of leaked credentials:** If an access key leaked, the entire AWS account was at risk.

### How IAM Solves These Problems:
✅ **Multiple users:** Create separate users for `employees` or `applications`.  
✅ **Granular access:** Assign permissions using policies.  
✅ **Temporary access:** Use roles and STS to provide short-lived credentials.

---

## 2. Fundamental Concepts

Before diving into IAM components, let's cover some core AWS security concepts:

### **Authentication vs Authorization**
- **Authentication:** Confirms **who you are** (e.g., logging in with a username and password).
- **Authorization:** Determines **what you can do** after authentication (e.g., accessing an S3 bucket).

IAM helps manage **both authentication and authorization**.

### **Entities & Objects**
- **Entity:** Anything that interacts with AWS (Users, Groups, Roles).
- **Object:** AWS resources like S3 buckets, EC2 instances, etc.

### **Amazon Resource Name (ARN)**
Every AWS resource has a unique ARN. Example:
```
arn:aws:iam::123456789012:user/Ibtisam
arn:aws:s3:::my-secure-bucket
```
IAM policies use ARNs to define permissions.

---

## 3. IAM Core Components

### **A. IAM Users**
👤 Represents individuals or applications needing AWS access. Each IAM user has unique credentials.

#### **Authentication Methods for IAM Users**
1. **Console Login (Username & Password):**
   - Best for users managing AWS via the Web UI.
   - Enable MFA for extra security.
2. **Access Keys (Key & Secret):**
   - Used for AWS CLI & API access.
   - Should be rotated regularly.
   - **Never** hardcode access keys into applications.

✅ **Use passwords for human users; use access keys for programmatic access.**

---

### **B. IAM Groups**
👥 Allows managing permissions for multiple users at once.

📌 Example:
- "Admin Group" has full access.
- "Developer Group" has limited permissions.
- Adding a user to a group automatically grants the group's permissions.

---

### **C. IAM Roles**
IAM Roles provide **temporary** permissions to AWS services or external users. Instead of long-term credentials, IAM roles generate **short-lived** credentials using STS (Security Token Service).

📌 **When to use IAM Roles?**
- Allowing an EC2 instance to access an S3 bucket.
- Granting temporary access to AWS resources for an external user.

🚀 **Example:**
Instead of storing an access key inside an EC2 instance, attach an IAM Role. The role automatically grants the necessary permissions.

---

### **D. AWS Security Token Service (STS)**
STS allows users and services to obtain **temporary security credentials** with specific permissions. These credentials **expire automatically**, reducing security risks.

✅ **How STS Works:**
1. A user/application requests temporary credentials via STS.
2. STS generates a time-limited access key and secret (token).
3. The user/application uses the temporary credentials to access AWS services.

📌 **Use Case:**
- A mobile app needs access to an S3 bucket for 1 hour → STS provides temporary credentials instead of long-term IAM user credentials.

---

## 4. IAM Policies

### **What Are IAM Policies?**
Policies define **who can do what** in AWS. They are written in JSON format.

📌 **Types of IAM Policies:**
1. **AWS-Managed Policies:** Predefined by AWS.
2. **Customer-Managed Policies:** Custom policies created by users.
3. **Inline Policies:** Attached directly to a user, role, or group (not recommended).

Example IAM Policy (Allows listing an S3 bucket):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::my-secure-bucket"
    }
  ]
}
```

---

## 5. IAM User vs. IAM Role

| Feature            | IAM User              | IAM Role               |
|--------------------|----------------------|------------------------|
| Authentication    | Username & Password  | Temporary STS Tokens  |
| Access Keys      | Permanent (Risky)    | Short-lived (Safer)   |
| Best for         | Long-term users      | AWS services, temporary users |
| Example Use Case | A developer logging into AWS | An EC2 instance accessing S3 |

✅ **Roles are safer than users because they don’t use permanent credentials.**

---

## 6. How IAM Components Work Together

Example Scenario:
1. A **developer** joins the company.
2. They are added to the **Developer Group** (with predefined policies).
3. They need temporary access to an **S3 bucket** → They assume a **role**.

This combination of **Users, Groups, Roles, and Policies** ensures **secure and efficient access control**.

---

## 7. Advanced IAM Concepts

### **A. IAM Identity Center (Formerly AWS SSO)**
Manages access across multiple AWS accounts from **one place**.

📌 **Use Case:**
- A company with **10 AWS accounts** uses IAM Identity Center to manage access centrally.

---

### **B. AWS Organizations & IAM**
Allows managing multiple AWS accounts under **one organization** with **Service Control Policies (SCPs).**

📌 **Use Case:**
- Prevent **junior developers** from **deleting resources** by enforcing an SCP policy.

---

## 8. AWS Certification Key Points

✅ IAM is **global** (not region-specific).  
✅ Users **cannot assume roles** unless explicitly granted.  
✅ **Root user should never be used** for daily operations.  
✅ Enable **MFA (Multi-Factor Authentication)** for security.  
✅ Follow **least privilege principle**—grant only necessary permissions.

---

## Summary
AWS IAM is a **critical security service** for managing authentication and authorization. By using **Users, Groups, Roles, Policies, and STS**, AWS ensures **secure and efficient access control** across services.