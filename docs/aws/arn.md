# AWS IAM - Identity and Access Management

## **Amazon Resource Name (ARN)**

### **What is an ARN?**
Amazon Resource Name (ARN) is a unique identifier assigned to AWS resources. It follows a standardized format:

```
arn:partition:service:region:account-id:resource
```

- `partition` → Usually `aws`, but can be `aws-us-gov` for government clouds.
- `service` → The AWS service (e.g., `s3`, `ec2`, `lambda`).
- `region` → AWS region where the resource is hosted.
- `account-id` → The AWS account number.
- `resource` → The specific resource identifier.

### **Examples of ARNs**
| AWS Service | ARN Example |
|------------|------------|
| IAM User | `arn:aws:iam::123456789012:user/JohnDoe` |
| S3 Bucket | `arn:aws:s3:::my-bucket` |
| S3 Object | `arn:aws:s3:::my-bucket/myfile.txt` |
| EC2 Instance | `arn:aws:ec2:us-east-1:123456789012:instance/i-abcdef123456` |
| Lambda Function | `arn:aws:lambda:us-west-2:123456789012:function:MyFunction` |
| RDS Database | `arn:aws:rds:us-west-2:123456789012:db:mydatabase` |

---
