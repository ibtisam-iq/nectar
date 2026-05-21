# EKS — IRSA, OIDC, and Addons

> **What this document covers:**
> How EKS pods get AWS permissions without static credentials — the full OIDC → IRSA flow — two real-world cluster-level examples (AWS Load Balancer Controller via Helm, EBS CSI Driver via EKS addon) — and two real-world application-level examples (Catalog via Helm + MySQL, Cart via Helm + DynamoDB) that illustrate when IRSA is needed by the application itself versus when it is handled by a controller.

---

## 1. The Problem We Are Solving

In EKS, many pods need to call AWS APIs (EBS, ELB, S3, SQS, DynamoDB, etc.).

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

## 12. The Core Decision: Controller vs. Application

Before wiring any IRSA for a microservice or a new component, answer one question:

> **Who is the AWS API client — the controller/driver, or the application pod itself?**

This single question determines everything:

| Scenario | AWS client | Who gets IRSA |
|----------|-----------|---------------|
| Pod needs EBS-backed PVC | EBS CSI driver (controller) | CSI driver's SA — not the app |
| Pod needs an ALB/NLB via Ingress | ALB controller (controller) | LBC's SA — not the app |
| Pod code calls DynamoDB SDK | Application pod directly | The app's own SA |
| Pod code uploads files to S3 | Application pod directly | The app's own SA |
| Pod code reads messages from SQS | Application pod directly | The app's own SA |
| Pod code writes logs to CloudWatch | Fluent Bit (agent/controller) | Fluent Bit's SA — not the app |
| ExternalDNS updates Route 53 | ExternalDNS controller | ExternalDNS SA — not the app |

**Rule:**
- Application calls AWS → the application's service account needs IRSA.
- A controller/agent/driver calls AWS on behalf of the application → the controller's service account gets IRSA; the application needs nothing extra.

---

## 13. Example 3 — Catalog Service (Helm + MySQL, No App IRSA)

### What It Does

- Language: Go.
- Persistence: MySQL (internal to the cluster, deployed by the Helm chart as a StatefulSet).
- The Go app talks to MySQL over TCP inside the cluster — it never calls AWS APIs directly.

### Why No IRSA for Catalog

The Catalog app only uses Kubernetes resources:

- A `Service` to reach MySQL.
- MySQL uses a `PersistentVolumeClaim` backed by the `ebs-csi-default-sc` StorageClass.

The **EBS CSI driver** (already installed and wired with its own IRSA) handles EBS volume creation when the PVC is provisioned. The Catalog app has no knowledge of EBS or AWS.

So: **EBS CSI driver owns the IAM role. Catalog app needs no IRSA.**

### Helm Values (`helm-values/catalog-values.yaml`)

```bash
helm show values oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart \
  --version 1.3.0 > helm-values/catalog-values.yaml
```

Edit to enable MySQL with EBS-backed persistent storage:

```yaml
app:
  persistence:
    provider: mysql
    endpoint: ""
    database: "catalog"

  mysql:
    create: true
    persistentVolume:
      enabled: true
      annotations: {}
      labels: {}
      accessModes:
        - ReadWriteOnce
      size: 10Gi
      storageClass: "ebs-csi-default-sc"
```

### Deploy

```bash
helm upgrade -i catalog \
  oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart \
  -n catalog \
  -f helm-values/catalog-values.yaml \
  --version 1.3.0
```

### Verify

```bash
kubectl get po -n catalog

# Confirm EBS volumes were dynamically provisioned
kubectl get pv
```

### PVC/PV Behavior in StatefulSets

> **Important:** When a StatefulSet pod is deleted, its PVC and PV are **not** deleted automatically.

- StatefulSets use PVCs. PVCs survive pod deletion by design.
- The StorageClass has `reclaimPolicy: Delete`, but that policy applies when the **PVC itself** is deleted — not when the pod is deleted.
- Deleting a pod → PVC and PV remain.
- Deleting the PVC → EBS volume is deleted (due to Delete reclaim policy).

This is expected and correct behavior for stateful workloads.

---

## 14. Example 4 — Cart Service (Helm + DynamoDB, App IRSA Required)

### What It Does

- Language: Java.
- Persistence: Amazon DynamoDB (external AWS managed service).
- The Java app calls DynamoDB HTTP APIs directly using the AWS SDK.

### Why IRSA Is Required for Cart

Unlike Catalog, the Cart app is itself an AWS API client. There is no intermediate controller that calls DynamoDB on its behalf. The pod's Java code signs and sends requests to the DynamoDB endpoint. For those requests to succeed, the pod must have valid AWS credentials with DynamoDB permissions.

This is why Cart needs its own IRSA service account.

### Step A — Create DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name carts \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=customerId,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes '[
    {
      "IndexName": "idx_global_customerId",
      "KeySchema": [
        { "AttributeName": "customerId", "KeyType": "HASH" }
      ],
      "Projection": { "ProjectionType": "ALL" }
    }
  ]'
```

### Step B — Create IAM Policy for DynamoDB Access

```bash
cat > carts-dynamo-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllAPIActionsOnCart",
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": [
        "arn:aws:dynamodb:us-east-1:${AWS_ACCOUNT}:table/carts",
        "arn:aws:dynamodb:us-east-1:${AWS_ACCOUNT}:table/carts/index/*"
      ]
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name carts-dynamo \
  --policy-document file://carts-dynamo-policy.json
```

The policy grants DynamoDB actions only on the `carts` table and its indexes — principle of least privilege.

### Step C — Bind IRSA to Cart Namespace

```bash
eksctl create iamserviceaccount \
  --cluster microservice-ecom-eks \
  --namespace cart \
  --name cart \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT}:policy/carts-dynamo \
  --role-name dynamo-table-access-for-carts \
  --approve \
  --override-existing-serviceaccounts
```

This creates:
- IAM role `dynamo-table-access-for-carts` with OIDC trust for `system:serviceaccount:cart:cart`.
- Kubernetes SA `cart` in namespace `cart` with the IRSA annotation.

Verify the annotation:

```bash
kubectl get sa -n cart cart -o yaml
# Expected annotation:
# eks.amazonaws.com/role-arn: arn:aws:iam::<account>:role/dynamo-table-access-for-carts
```

### Step D — Retrieve and Edit Helm Values

```bash
helm show values oci://public.ecr.aws/aws-containers/retail-store-sample-cart-chart \
  --version 1.3.0 > helm-values/cart-values.yaml
```

Edit `helm-values/cart-values.yaml`:

```yaml
serviceAccount:
  # Do not create a new SA — reuse the one created by eksctl with IRSA annotation
  create: false
  annotations: {}
  name: "cart"

app:
  persistence:
    provider: dynamodb
    dynamodb:
      tableName: carts
      createTable: false
```

**Key choices:**

| Setting | Reason |
|---------|--------|
| `serviceAccount.create: false` | The SA already exists with the IRSA annotation. Letting Helm create a new one would produce an unannotated SA with no AWS permissions. |
| `serviceAccount.name: "cart"` | Explicitly reference the pre-created IRSA-annotated SA. |
| `persistence.provider: dynamodb` | Tell the app to use DynamoDB instead of any in-cluster DB. |
| `createTable: false` | Table was already created in Step A. |

### Step E — Deploy

```bash
helm upgrade -i cart \
  oci://public.ecr.aws/aws-containers/retail-store-sample-cart-chart \
  -n cart \
  -f helm-values/cart-values.yaml \
  --version 1.3.0
```

### Verify

```bash
# Check pods
kubectl get po -n cart

# Confirm which service account the deployment uses
kubectl get deploy cart-carts -n cart -o yaml | grep serviceAccount
```

The deployment must reference `serviceAccountName: cart` — the annotated SA. If it references any other SA, the pods will receive `AccessDenied` from DynamoDB.

---

## 15. Catalog vs. Cart — Side-by-Side Comparison

| Aspect | Catalog (Go + MySQL) | Cart (Java + DynamoDB) |
|--------|----------------------|------------------------|
| Database | In-cluster MySQL (StatefulSet) | External AWS DynamoDB |
| Who calls AWS APIs | EBS CSI driver (to provision MySQL's PVC) | Cart app pod itself (SDK calls to DynamoDB) |
| App IRSA needed? | No | Yes |
| `eksctl create iamserviceaccount` for app? | No | Yes |
| `serviceAccount.create` in Helm values | Default (Helm creates SA, or irrelevant) | `false` — reuse the IRSA-annotated SA |
| IAM policy scope | None for app; EBS CSI driver has its own | `dynamodb:*` on the `carts` table |
| AWS resource created before deploy | None (EBS volumes created dynamically by CSI) | DynamoDB table created manually before deploy |

---

## 16. General Reasoning Framework for Any Microservice

When encountering any new microservice or component in an EKS-based architecture:

1. **Identify what each service talks to.**
   - In-cluster database (MySQL, PostgreSQL, Redis) via K8s `Service`? → No IRSA for the app.
   - AWS managed service directly (DynamoDB, S3, SQS, SNS, Secrets Manager)? → App needs IRSA.

2. **Check if a controller already handles the AWS interaction.**
   - EBS/EFS CSI driver → handles storage provisioning → app just uses PVC.
   - ALB controller → handles load balancer provisioning → app just uses Ingress.
   - ExternalDNS → handles DNS → app just uses hostnames.
   - FluentBit/CloudWatch agent → handles log shipping → app just writes to stdout.

3. **Apply the pattern accordingly:**

   | Situation | Action |
   |-----------|--------|
   | Controller calls AWS | Give the controller's SA an IRSA role. App needs nothing. |
   | App code calls AWS SDK | Give the app's SA an IRSA role. Set `serviceAccount.create: false` in Helm, reference the pre-created annotated SA. |

4. **For any IRSA setup, the same three sub-steps always apply:**
   - Create IAM policy (permissions).
   - Create IAM role + wire OIDC trust (`eksctl create iamserviceaccount`).
   - Use the annotated SA in the workload (either Helm `serviceAccount.create=false` or `--service-account-role-arn` for EKS addons).

This framework applies to any AWS integration: SQS consumers, S3 upload services, Secrets Manager readers, SNS publishers — the pattern is identical. Only the IAM policy and AWS resource differ.

---

## 17. Quick Reference

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

This trust policy enforces: "Only tokens from *this specific service account in this specific namespace* can assume this role."

### Decision checklist for any new component

```
Is this pod going to call AWS APIs?
├── Yes → Does a controller/agent already make those calls?
│         ├── Yes (CSI, LBC, FluentBit, ExternalDNS...) → IRSA the controller, not the app
│         └── No (app code uses AWS SDK directly) → IRSA the app's service account
└── No  → No IRSA needed for this workload
```
