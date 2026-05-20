# EKS — IRSA, OIDC, and Addons

> **What this document covers:**
> How EKS pods get AWS permissions without static credentials — the full OIDC → IRSA flow — and two real-world examples (AWS Load Balancer Controller via Helm, EBS CSI Driver via EKS addon) showing how this pattern is applied in practice, including where they differ and why.

---

## 1. The Problem We Are Solving

In EKS, many pods need to call AWS APIs (EBS, ELB, S3, SQS, etc.).

We want:

- Each workload (or controller) to have its **own AWS permissions**.
- **Without** putting static AWS access keys inside pods.
- **Without** giving the entire EC2 node one big IAM role that every pod on that node shares.

This is solved by:

- An OIDC identity provider for the cluster.
- IAM roles that trust tokens coming from that cluster.
- Kubernetes service accounts annotated with those IAM roles.

This pattern is called **IAM Roles for Service Accounts (IRSA)**.

---

## 2. The Three Actors

Think in terms of 3 main actors:

### 2.1 Pod + Kubernetes Service Account

- The pod runs with `serviceAccountName: X`.
- The Kubernetes service account issues a **token** (like an ID card) for the pod:
  > "I am service account `X` in namespace `Y` of cluster `Z`."
- This token is a signed JWT, projected into the pod at runtime.

### 2.2 EKS OIDC Issuer URL

- Every EKS cluster has an **OIDC issuer URL** like:
  ```
  https://oidc.eks.<region>.amazonaws.com/id/<cluster-id>
  ```
- This URL exposes metadata and public keys so external parties (like IAM) can **verify** the token — confirming it genuinely came from this cluster.

### 2.3 AWS IAM + OIDC Identity Provider + IAM Roles

- In IAM → Identity Providers → OpenID Connect, we create an entry pointing to that OIDC URL.
- This tells IAM: "You can trust tokens issued by this cluster's OIDC URL."
- Then we create **IAM roles** whose trust policies say:
  > "Allow tokens from this OIDC provider, but only when the token claims say `namespace = X` and `serviceAccount = Y`."

This chain of `service account → token → OIDC URL → IAM role` is the heart of IRSA.

---

## 3. What `iam.withOIDC: true` Does in eksctl ClusterConfig

In an `eksctl` ClusterConfig YAML:

```yaml
iam:
  withOIDC: true
```

When the cluster is created, `eksctl` **also creates the IAM OIDC identity provider** in AWS for that cluster's OIDC URL.

After that, AWS IAM knows about the cluster's OIDC URL and can use it when evaluating IAM role trust policies.

**Without this:**
- You cannot create IAM roles that trust "pods from this EKS cluster" using IRSA.
- You fall back to sharing the node's IAM role with all pods on that node (broad, not recommended).

`withOIDC: true` is the **foundation** that enables per-pod AWS IAM permissions.

---

## 4. What `eksctl create iamserviceaccount` Does

```bash
eksctl create iamserviceaccount \
  --cluster <cluster> \
  --namespace <ns> \
  --name <sa-name> \
  --attach-policy-arn <policy-arn> \
  --role-name <role-name> \
  [--role-only] \
  --approve
```

Depending on the `--role-only` flag, this command does:

1. **Creates/ensures IAM role** with a trust policy:
   - Trusts the cluster's OIDC provider.
   - Restricts to tokens for the given namespace + service account name.

2. **Attaches IAM policy** (permissions) to that role — e.g., EBS actions, ELB actions.

3. **If NOT `--role-only`**: Creates/patches the **Kubernetes service account** with annotation:
   ```yaml
   eks.amazonaws.com/role-arn: arn:aws:iam::<account>:role/<role-name>
   ```

This annotation is how the pod tells AWS:
> "Please give me credentials for this IAM role."

---

## 5. End-to-End IRSA Flow (for any pod)

1. Pod starts with `serviceAccountName: <sa>`.
2. Kubernetes service account gives the pod a projected token (ID card).
3. Pod's AWS SDK uses that token + the `role-arn` annotation to ask AWS STS for credentials.
4. IAM validates the token by calling the OIDC provider (cluster's URL).
5. If claims (namespace + serviceAccount name) match the IAM role's trust policy → IAM returns temporary credentials for that role.
6. Pod uses these credentials to call AWS APIs with permissions from the role's attached policy.

**No static keys. Per-pod AWS permissions.**

---

## 6. Example 1 — AWS Load Balancer Controller (Helm-based)

### What It Does

- Runs as pods in `kube-system`.
- Watches Kubernetes `Ingress` and `Service` objects.
- Creates and manages **Application Load Balancers (ALB)** and **Network Load Balancers (NLB)** in AWS.
- Therefore needs AWS permissions for: `elasticloadbalancing:*`, `ec2:Describe*`, `acm:*`, etc.

### Step A — Create IAM Policy

```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

- `iam_policy.json` defines the exact AWS actions the controller is allowed to perform.
- `aws iam create-policy` registers that policy in your AWS account.

### Step B — Create IAM Role + K8s Service Account with Annotation

```bash
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$AWS_ACCOUNT:policy/AWSLoadBalancerControllerIAMPolicy \
  --role-name aws-load-balancer-controller \
  --override-existing-serviceaccounts \
  --region $AWS_REGION \
  --approve
```

This single command:

- Ensures OIDC provider is registered (relies on `iam.withOIDC: true` in cluster config).
- Creates IAM role `aws-load-balancer-controller` with trust policy for service account `kube-system/aws-load-balancer-controller`.
- Attaches `AWSLoadBalancerControllerIAMPolicy` to that role.
- Creates/patches the Kubernetes `ServiceAccount` `aws-load-balancer-controller` in `kube-system` **with the IRSA annotation** pointing to that role.

**Notice:** Here `--role-only` is NOT used. eksctl creates both the IAM role AND the K8s service account with the annotation in one command.

### Step C — Install Controller via Helm, Using That SA

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$AWS_REGION \
  --set vpcID=$VPC_ID \
  --version 1.14.0
```

**Key flags:**

| Flag | Meaning |
|------|---------|
| `serviceAccount.create=false` | Do NOT let Helm create a new service account. We already created one with IRSA annotation via eksctl. |
| `serviceAccount.name=aws-load-balancer-controller` | Use the existing service account that has the IAM role annotation. |

The resulting Deployment will run pods with:
```yaml
spec:
  template:
    spec:
      serviceAccountName: aws-load-balancer-controller
```

Those pods → use the annotated SA → get tokens → IAM validates via OIDC → grants credentials for the role → controller can create ALBs/NLBs.

**If you removed `serviceAccount.create=false`:**
- Helm creates a new, plain service account with no annotation.
- The controller pod starts fine (K8s doesn't care about IAM).
- But when it tries to call AWS ELB APIs, the AWS SDK has no valid credentials → `AccessDenied` errors → no ALBs or NLBs are created.

### Verify

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

---

## 7. Example 2 — EBS CSI Driver (EKS Addon-based)

### What It Does

- EBS CSI driver manages **Elastic Block Store (EBS) volumes** for Kubernetes PersistentVolumeClaims.
- Runs as a controller + a DaemonSet (`ebs-csi-node`) on every node.
- Required for stateful workloads (MySQL, PostgreSQL, etc.) that need durable, dynamic storage.
- Needs AWS EBS permissions: `ec2:CreateVolume`, `ec2:AttachVolume`, `ec2:DeleteVolume`, etc.

### Step A — Create IAM Role Only (no K8s SA yet)

```bash
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $CLUSTER_NAME \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve
```

Because of `--role-only`:

- eksctl creates **only** the IAM role `AmazonEKS_EBS_CSI_DriverRole` with trust policy for the cluster's OIDC provider.
- Attaches the AWS-managed policy `AmazonEBSCSIDriverPolicy` (EBS permissions).
- **Does NOT create a Kubernetes service account.** The EKS addon system will create it.

### Step B — Check Available Addons

```bash
eksctl utils describe-addon-versions --kubernetes-version 1.34 | grep AddonName
```

Confirms `aws-ebs-csi-driver` is supported for your Kubernetes version.

### Step C — Install EBS CSI Addon and Wire IAM Role

```bash
aws eks create-addon \
  --cluster-name $CLUSTER_NAME \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::<account>:role/AmazonEKS_EBS_CSI_DriverRole \
  --configuration-values '{"defaultStorageClass":{"enabled":true}}'
```

What happens here:

- `aws eks create-addon` tells EKS to install and manage the EBS CSI driver addon.
- `--service-account-role-arn` tells EKS: "For the service account that this addon uses, attach this IAM role via IRSA." EKS creates the service account internally and adds the IRSA annotation automatically.
- `--configuration-values '{"defaultStorageClass":{"enabled":true}}'` tells the addon to create a default StorageClass (`ebs-csi-default-sc`) using EBS gp3 volumes.

**Compare to LBC:**
- For LBC: *you* created the service account with annotation → Helm used it.
- For EBS CSI: you only create the IAM role → EKS addon creates the service account + wires the annotation → using `--service-account-role-arn`.

Same IRSA mechanism. Different automation.

### Verify

```bash
# Check DaemonSet (one pod per node)
kubectl get daemonset ebs-csi-node -n kube-system

# Check default StorageClass
kubectl get storageclass
```

Expected output includes `ebs-csi-default-sc (default)` with provisioner `ebs.csi.aws.com`.

---

## 8. Differences Between the Two Examples

Both use **the same IRSA core concept** but differ in who creates the service account and how the IAM role is wired:

| Aspect | AWS Load Balancer Controller (Helm) | EBS CSI Driver (EKS Addon) |
|--------|--------------------------------------|----------------------------|
| Installation mechanism | Helm chart (`helm install`) | EKS addon (`aws eks create-addon`) |
| Service account creation | Created by `eksctl create iamserviceaccount` (no `--role-only`) | Created by EKS as part of addon installation |
| `--role-only` used? | No — SA created by eksctl | Yes — SA created by addon |
| IAM policy source | Custom file `iam_policy.json` → `AWSLoadBalancerControllerIAMPolicy` | AWS-managed `AmazonEBSCSIDriverPolicy` |
| How SA links to IAM role | SA annotation created by eksctl; Helm told to use that SA | EKS addon wires SA ↔ IAM role using `--service-account-role-arn` |
| SA creation control | You control it | EKS controls it |
| Workload type | Controller (manages ALB/NLB) | CSI driver (manages EBS volumes) |

Conceptually both are:
> "Pod that needs AWS permissions → IAM role + policy + OIDC trust → service account annotated with that role → pod assumes role."

---

## 9. General Pattern for Any EKS Addon

When installing any **EKS-managed addon** that needs AWS permissions:

1. Create IAM role with `eksctl create iamserviceaccount --role-only` (creates role + trust policy, no K8s SA).
2. Attach appropriate policy to the role.
3. `aws eks create-addon --service-account-role-arn <role-arn>` — EKS installs the addon, creates its SA, and wires the IRSA annotation internally.

When installing a **Helm/manifest-based controller** that needs AWS permissions:

1. Create IAM role + K8s SA together with `eksctl create iamserviceaccount` (no `--role-only`).
2. Attach policy to the role.
3. Helm install with `serviceAccount.create=false` + `serviceAccount.name=<sa>` to use the pre-created annotated SA.

---

## 10. Console vs. CLI: What Happens Under the Hood

When you install EKS addons from the **AWS Console** (EKS → Cluster → Add-ons → Add), the console:

- Offers an option to auto-create an IAM role for the addon.
- If you accept, AWS automatically creates the IAM role, attaches the required managed policy, adds the OIDC trust, and wires the service account annotation.
- Under the hood it is doing the exact same IRSA steps — just without you running the commands.

So: **console is a UI wrapper around the same mechanism**. Understanding the manual flow means you understand what the console is doing automatically.

For the Load Balancer Controller specifically: it is not a native EKS addon (as of now), so it always requires the manual Helm + eksctl flow.

---

## 11. Why Addons Are Not in the ClusterConfig YAML

The `eksctl` ClusterConfig is for cluster-level properties (nodegroups, VPC, OIDC enablement, etc.).

EKS addons are managed via the **EKS Addons API** (`aws eks create-addon`) and are independent of the cluster config file. They can be installed, updated, or removed after the cluster is created without touching the original config.

This is intentional: cluster creation and addon installation are separate concerns. The cluster config defines **what the cluster is**; addon commands define **what runs on it**.

`iam.withOIDC: true` must be in the cluster config because OIDC enablement is a cluster-level property — it must exist before any IRSA can work.

---

## 12. Quick Reference

### IRSA annotation format

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<account>:role/<role-name>
```

### IAM role trust policy (what eksctl creates)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/<cluster-id>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<region>.amazonaws.com/id/<cluster-id>:sub": "system:serviceaccount:<namespace>:<sa-name>",
          "oidc.eks.<region>.amazonaws.com/id/<cluster-id>:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

This trust policy is what enforces: "Only tokens from *this specific service account in this specific namespace* can assume this role."
