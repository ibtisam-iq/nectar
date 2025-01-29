# Docker Tagging: Docker Hub vs. AWS ECR vs. Nexus Private Registry

When tagging and pushing images, the repository naming conventions vary depending on the registry. Let's explore how **Docker Hub**, **Amazon Elastic Container Registry (ECR)**, and a **Nexus Private Registry** handle tagging and pushing images.

## 1. Tagging for Docker Hub

Docker Hub follows a simple repository naming pattern:
```
<DockerHub_Username>/<Repository_Name>:<Tag>
```

For example, let's say we have a local image named `my-app:latest`. We can tag it for Docker Hub under the user **mibtisam**:

```bash
docker tag my-app:latest mibtisam/my-app:v1
```

Now, we can push this image to Docker Hub:

```bash
docker push mibtisam/my-app:v1
```

---

## 2. Tagging for AWS Elastic Container Registry (ECR)

AWS ECR requires the repository name to include the AWS account ID, AWS region, and ECR domain:
```
<AWS_Account_ID>.dkr.ecr.<Region>.amazonaws.com/<Repository_Name>:<Tag>
```

### Example:

**Authenticate Docker with AWS ECR:**

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

**Tag the image for AWS ECR:**

```bash
docker tag my-app:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-ecr-repo:v1
```

**Push & Pull the image to AWS ECR:**

```bash
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-ecr-repo:v1
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-ecr-repo:v1
```

---

## 3. Tagging for Nexus Private Registry

A private Nexus repository is often hosted within an organization’s infrastructure. The repository URL follows the format:
```
<Registry_IP>:<Port>/<Repository_Name>:<Tag>
```

For example, if our Nexus Private Registry is hosted at `https://154.65.3.12:5000`, we can tag our image as follows:

```bash
docker tag my-app:latest 154.65.3.12:5000/my-private-repo:v1
```

### Steps to Push the Image to Nexus

**Login to Nexus Private Registry:**

```bash
docker login 154.65.3.12:5000
```

**Push the tagged image to Nexus:**

```bash
docker push 154.65.3.12:5000/my-private-repo:v1
```

---

## Comparison of Docker Image Tagging

| Registry               | Tagging Format                                                   |
|------------------------|------------------------------------------------------------------|
| Docker Hub             | `mibtisam/my-app:v1`                                             |
| AWS ECR                | `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-ecr-repo:v1`     |
| Nexus Private Registry | `154.65.3.12:5000/my-private-repo:v1`                            |

Each registry has its own unique structure, and tagging the image correctly ensures a successful push. Docker Hub is the easiest to use, while AWS ECR and Nexus require additional authentication.

