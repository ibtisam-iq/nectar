# AWS IAM - Identity and Access Management

## **IAM Identity Center (AWS Single Sign-On - SSO)**

### **What is IAM Identity Center?**
AWS Identity Center (formerly AWS SSO) is a **centralized user authentication and authorization service** that allows organizations to manage access to multiple AWS accounts and applications.

### **Why Was IAM Identity Center Introduced?**
Before IAM Identity Center, managing access for multiple AWS accounts was complex because:
1. Companies had **multiple IAM users across different AWS accounts**, creating duplication.
2. Organizations using **Microsoft Active Directory (AD)** had to manually sync users with AWS IAM.
3. There was **no single sign-on (SSO) capability** for AWS Management Console and third-party apps.

### **How Does IAM Identity Center Work?**
- Allows **centralized user management** across multiple AWS accounts.
- Supports **single sign-on (SSO)** so users log in once and access multiple accounts.
- Integrates with **Microsoft Active Directory (AD)** and **third-party identity providers (IdPs)** (e.g., Okta, Google Workspace, Azure AD).

### **IAM Identity Center vs. Traditional IAM**
| Feature | IAM | IAM Identity Center |
|---------|----|-------------------|
| User Management | AWS-only IAM Users | External Identity Providers (AD, Okta) |
| Access Scope | Per AWS Account | Across Multiple AWS Accounts |
| Login Method | IAM Credentials (Username/Password) | SSO (Single Login for All) |
| Best for | Small Teams | Large Organizations with Multiple AWS Accounts |

### **Use Cases of IAM Identity Center**
1. **Multi-Account Access** → Companies with multiple AWS accounts can assign access from one place.
2. **Active Directory Integration** → Companies using AD can extend access to AWS services.
3. **SSO for Third-Party Applications** → Easily log in to third-party SaaS applications (e.g., Salesforce, Jira).
4. **Federated Access for Employees** → Employees can log in using their corporate credentials.

### **How IAM Identity Center Integrates with Active Directory (AD)?**
- AWS Identity Center can **sync users and groups** from an **on-premise Microsoft Active Directory**.
- Users can log in with their **corporate credentials** without needing IAM users.
- This is done via **AWS Directory Service**.

### **Conclusion**
AWS IAM Identity Center is **not a replacement for IAM** but an **addition** that simplifies user access management, especially for companies using multiple AWS accounts or third-party identity providers.

---
