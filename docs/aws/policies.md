# AWS IAM - Identity and Access Management

## **IAM Policies - Effect, Action, Resource**

### **Understanding IAM Policy Components**
IAM policies are written in JSON format and contain **three key components**:

- **Effect** → Defines whether the statement `Allow` or `Deny` actions.
- **Action** → Specifies the AWS service and operations that are allowed or denied.
- **Resource** → Identifies the AWS resource to which the policy applies.

### **Example Use Case: Read-Only Access to S3**
Imagine an IAM user needs read-only access to a specific S3 bucket (`my-secure-bucket`). The policy would be:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-secure-bucket/*"
    }
  ]
}
```

### **Breakdown:**
- **Effect**: `Allow` → The action is permitted.
- **Action**: `s3:GetObject` → Allows reading objects in an S3 bucket.
- **Resource**: `arn:aws:s3:::my-secure-bucket/*` → Applies only to objects inside `my-secure-bucket`.

### **Example Use Case: Denying Access to Everything Except S3 Read**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-secure-bucket/*"
    }
  ]
}
```

### **Breakdown:**
- The first statement explicitly **denies all actions on all resources**.
- The second statement allows **only reading objects from S3**.
- This ensures **principle of least privilege**.

---

