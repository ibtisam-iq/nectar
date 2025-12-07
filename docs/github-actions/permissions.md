# 🔐 GitHub Actions Permissions

GitHub Actions uses a **permission-based security model**.  
Workflows and individual jobs can be granted specific access levels to follow the **principle of least privilege**.

This guide focuses on the **three most important permissions** when deploying documentation (especially MkDocs + GitHub Pages) and modern cloud deployments.

---

## Overview of Key Permissions

| Permission         | Scope                          | Typical Use Case                              | Risk Level | Recommended When |
|--------------------|--------------------------------|-----------------------------------------------|------------|------------------|
| `contents: write`  | Repository code & branches     | Push to `gh-pages`, commit generated files    | 🟡 Medium  | Writing back to repo |
| `pages: write`     | GitHub Pages publishing        | Official `actions/deploy-pages`               | 🟢 Low     | Using GitHub-native Pages deploy |
| `id-token: write`  | OIDC token issuance            | Secret-less auth to AWS/GCP/Azure             | 🔥 High    | Deploying to external clouds |

---

## Detailed Permission Reference

### 1. `contents: write`

```yaml
permissions:
  contents: write
```

#### What it allows
| Action                          | Allowed |
|---------------------------------|---------|
| Push commits / create branches  | ✔      |
| Modify repository files         | ✔      |
| Publish to `gh-pages` branch    | ✔      |
| Read repository contents        | ✔      |

#### Common use cases
- Deploying MkDocs site via `peaceiris/actions-gh-pages`
- Auto-updating README, release notes, or generated docs
- Any CI that commits artifacts back to the repo

#### Risk
Compromised workflow could rewrite repository code → **use only when necessary**

---

### 2. `pages: write`

```yaml
permissions:
  pages: write
```

#### What it allows
| Action                            | Allowed |
|-----------------------------------|---------|
| Deploy to GitHub Pages            | ✔      |
| Trigger Pages rebuild             | ✔      |
| Configure Pages settings          | ✔      |
| Modify repository source code     | ❌      |

#### When required
Only with GitHub’s official deployment action:

```yaml
- uses: actions/deploy-pages@v4
```

**Not needed** when using `peaceiris/actions-gh-pages` (that one uses `contents: write` instead).

#### Risk
Very low — only affects the published static site.

---

### 3. `id-token: write`

```yaml
permissions:
  id-token: write
```

#### What it allows
| Action                              | Allowed |
|-------------------------------------|---------|
| Mint short-lived OIDC tokens        | ✔      |
| Assume roles in AWS/GCP/Azure       | ✔      |
| Push to repository                  | ❌      |
| Deploy to GitHub Pages              | ❌      |

#### Supported cloud providers (OIDC)
| Provider                     | Supported |
|------------------------------|-----------|
| AWS IAM Roles Anywhere / AssumeRole | ✔       |
| Google Cloud Workload Identity Federation | ✔ |
| Azure Federated Credentials  | ✔        |

#### Use cases
- Deploy static sites to S3 + CloudFront
- Firebase Hosting, Cloudflare R2, GCP Cloud Storage, Azure Storage

#### Risk
Gives real cloud credentials → treat as **high-risk**. Only grant when actually deploying to external clouds.

---

## Choosing the Right Permissions for Your Deployment

| Deployment Method                        | Required Permissions                  | Notes |
|------------------------------------------|---------------------------------------|-------|
| `mkdocs gh-deploy` (built-in)            | None                                  | Uses your personal GH token |
| `actions/deploy-pages@v4`                | `pages: write`                        | Official GitHub method |
| `peaceiris/actions-gh-pages@v3/v4`       | `contents: write`                     | Most popular community action |
| Deploy to AWS/GCP/Azure via OIDC         | `id-token: write` (+ sometimes `contents`) | Secret-less auth |

---

## Where to Declare Permissions (Scope)

GitHub supports **two scopes**:

### 1. Workflow-level (root)

```yaml
permissions:
  contents: write
  pages: write
  id-token: write
```

→ Applies to **all jobs** in the workflow (unless overridden)  
→ Convenient for simple, single-purpose workflows

### 2. Job-level (recommended for security)

```yaml
jobs:
  build:
    permissions: {}
    # or explicitly read-only
    # permissions: read-all

  deploy:
    permissions:
      pages: write
      # or contents: write / id-token: write as needed
```

→ Only the deploy job gets write access  
→ Follows **least privilege** principle

### Decision Table

| Scenario                                  | Recommended Placement       |
|-------------------------------------------|-----------------------------|
| Single-job workflow                       | Root or job-level (both OK) |
| Multi-stage pipeline (build → test → deploy) | **Job-level only on deploy** |
| Security-focused / enterprise             | Always job-level, minimal scope |

#### Secure Enterprise Pattern (Best Practice)

```yaml
name: Deploy Docs
on: [push, workflow_dispatch]

permissions: {}  # deny all by default

jobs:
  build:
    runs-on: ubuntu-latest
    steps: [...]
  
  test:
    needs: build
    runs-on: ubuntu-latest
    steps: [...]

  deploy:
    needs: test
    permissions:
      contents: write   # or pages: write / id-token: write
    runs-on: ubuntu-latest
    steps:
      - uses: actions/deploy-pages@v4   # if using official action
      # or peaceiris/actions-gh-pages@v4
```

---

## One-Glance Summary Table

| Permission         | Main Purpose                     | Typical Deployment Scenario           | Frequency in Real Projects |
|--------------------|----------------------------------|---------------------------------------|----------------------------|
| `contents: write`  | Push to repo / gh-pages branch   | MkDocs + peaceiris action             | 🔥 Very common            |
| `pages: write`     | Official GitHub Pages deploy     | `actions/deploy-pages`               | 🟡 Common                  |
| `id-token: write`  | OIDC auth to cloud providers     | AWS, GCP, Azure hosting               | 🟠 Professional / Enterprise |

---

## Key Takeaways (Senior Engineer Mindset)

- **Never grant more permissions than needed**
- **Prefer job-level permissions** in multi-job workflows
- **Root-level permissions = convenience**, job-level = security
- Use `pages: write` only with official deploy action
- Use `id-token: write` only for real cloud OIDC deployments

