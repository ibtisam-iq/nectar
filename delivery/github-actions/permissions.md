# GitHub Actions — Permissions

---

## Start Here — What Is a Permission?

When GitHub Actions runs a workflow, it needs to **do things** — push code, publish a website, talk to a cloud provider, read your repo. But doing things requires **access**. GitHub does not give your workflow unlimited access by default. Instead, it gives a **token** with specific permissions you define.

Think of it like a hotel key card:
- The hotel (GitHub) creates a key card (token) for your stay (workflow run)
- The key card only opens the doors you need — not the kitchen, not the server room
- When you check out (workflow ends), the key card is destroyed

This key card is called `secrets.GITHUB_TOKEN`.

---

## What Is `secrets.GITHUB_TOKEN`?

When a workflow run starts, GitHub **automatically creates** a temporary token. You never create it yourself — GitHub generates it, injects it into the workflow as `secrets.GITHUB_TOKEN`, uses it during the run, then destroys it when the run ends.

This token is what your workflow uses to:
- Log in to GitHub Container Registry (GHCR)
- Push commits back to the repository
- Publish to GitHub Pages
- Comment on pull requests
- And more

### How it appears in a workflow

For example, to log in to GHCR before pushing a Docker image:

```yaml
- name: Log in to GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}   # ← the auto-generated token
```

A registry login needs three things: a registry URL, a username, and a password. GitHub uses the auto-generated token as the password. You do not need to create or store this password — GitHub handles it.

---

## The Two Access Levels

For every permission, there are two possible values:

| Value | What it means |
|---|---|
| `read` | The workflow can **see** this thing but cannot change it |
| `write` | The workflow can **see AND modify** this thing |

`write` always includes `read` — if you can write, you can also read.

---

## GitHub's Permission Sections

GitHub divides its services into sections. Each section can be granted `read` or `write` independently. Here are the most important ones:

| Section | What it controls |
|---|---|
| `contents` | Repository code, files, branches, commits, releases |
| `packages` | GitHub Container Registry (GHCR) — pushing/pulling images |
| `pages` | GitHub Pages — publishing static websites |
| `id-token` | OIDC token — passwordless login to AWS, GCP, Azure |
| `pull-requests` | Opening, commenting on, and merging pull requests |
| `actions` | Triggering and managing other workflows |

You declare these in a `permissions:` block in your workflow file.

---

## How to Write Permissions

### Basic syntax

```yaml
permissions:
  contents: read
  packages: write
```

This means:
- `contents: read` — the workflow can read your repo code but cannot push or commit
- `packages: write` — the workflow can push images to GHCR

### Two shorthand values

```yaml
permissions: read-all    # every section gets read access
permissions: write-all   # every section gets write access (dangerous)
```

`write-all` is almost always wrong — it gives the workflow more power than it needs.

### Deny everything (most secure starting point)

```yaml
permissions: {}
```

This gives the workflow no access at all. Then you add back only what is needed.

---

## Where to Put the Permissions Block

You can put `permissions:` at two levels:

### 1. Workflow level (applies to every job)

```yaml
name: My Workflow
on: [push]

permissions:          # ← applies to ALL jobs
  contents: read
  packages: write

jobs:
  build:
    ...
  deploy:
    ...
```

### 2. Job level (applies only to that specific job)

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read    # ← only this job gets this
    steps:
      ...

  deploy:
    runs-on: ubuntu-latest
    permissions:
      packages: write   # ← only this job gets this
    steps:
      ...
```

### Which should you use?

| Situation | Recommendation |
|---|---|
| Single-job workflow | Workflow level is fine |
| Multi-job workflow (build → test → deploy) | Job level — only the deploy job gets write access |
| Security-sensitive / production | Always job level, minimal scope |

---

## The Five Most Common Permission Setups

### 1. Pushing a Docker image to GHCR

```yaml
permissions:
  contents: read
  packages: write
```

- `contents: read` — workflow needs to read your repo code to build the image
- `packages: write` — workflow needs to push the image to GHCR

**Wrong version:**
```yaml
permissions:
  contents: write   # ❌ unnecessary — you are not committing anything back
  packages: write
```
Granting `contents: write` when you only need to read is giving away more access than needed.

---

### 2. Deploying a static site to GitHub Pages (community action)

```yaml
permissions:
  contents: write
```

Used with `peaceiris/actions-gh-pages`. This action pushes your built site as a commit to the `gh-pages` branch — which is why it needs `contents: write`.

**Wrong version:**
```yaml
permissions:
  pages: write      # ❌ this does NOT work with peaceiris action
  contents: write
```
`pages: write` is only for GitHub's own official deploy action, not the community one.

---

### 3. Deploying to GitHub Pages (official GitHub action)

```yaml
permissions:
  pages: write
  id-token: write
  contents: read
```

Used with `actions/deploy-pages@v4`. GitHub's official Pages action uses OIDC (`id-token`) to authenticate with the Pages service directly — it does not push to `gh-pages` branch at all.

**Wrong version:**
```yaml
permissions:
  contents: write   # ❌ not needed — this action does not commit to the repo
  pages: write
```

---

### 4. Deploying to AWS / GCP / Azure without passwords (OIDC)

```yaml
permissions:
  id-token: write
  contents: read
```

`id-token: write` lets the workflow mint a short-lived OIDC token that cloud providers (AWS, GCP, Azure) accept as proof of identity — no stored secrets needed.

**Wrong version:**
```yaml
permissions: write-all   # ❌ massively over-permissioned
```

---

### 5. Read-only workflow (just running tests)

```yaml
permissions:
  contents: read
```

Or simply:
```yaml
permissions: read-all
```

A test-only workflow does not need to write anything.

---

## How the Token Behaves Differently Based on Who Triggers the Workflow

This is critical to understand when working with pull requests.

| Who triggers the workflow | Token power |
|---|---|
| You, pushing to your own branch | Full — reads and writes work |
| You, opening a PR from your own branch | Full — reads and writes work |
| A stranger opening a PR from a **fork** | **Read only** — write is blocked by GitHub automatically |

The third row is GitHub's **automatic security behavior**. You do not write this anywhere — GitHub enforces it regardless of your `permissions:` block. This prevents a malicious contributor from pushing code that steals your secrets or publishes rogue images to your registry.

### Practical example — your Docker image workflow

```yaml
- name: Build and push
  uses: docker/build-push-action@v6
  with:
    push: ${{ github.event_name != 'pull_request' }}
```

This line means:

```
PR opened       → github.event_name = "pull_request"
                → 'pull_request' != 'pull_request' = FALSE
                → push: false
                → image is built but NOT pushed to GHCR ✅

PR merged       → github.event_name = "push"
                → 'push' != 'pull_request' = TRUE
                → push: true
                → image is built AND pushed to GHCR ✅
```

**Wrong version:**
```yaml
push: true   # ❌ image pushed on every PR, every commit, every trigger
```

This would publish an unreviewed image every time anyone opens a PR.

---

## Correct vs Wrong — Side-by-Side Reference

| Goal | Correct | Wrong | Why wrong |
|---|---|---|---|
| Push Docker image to GHCR | `packages: write` + `contents: read` | `write-all` | Over-permissioned |
| Deploy with peaceiris Pages action | `contents: write` | `pages: write` | Wrong permission for this action |
| Deploy with official Pages action | `pages: write` + `id-token: write` | `contents: write` | Not how official action works |
| Only push on merge, not on PR | `push: ${{ github.event_name != 'pull_request' }}` | `push: true` | Publishes on unreviewed PRs |
| Multi-job pipeline | Job-level permissions only on deploy job | Workflow-level `write-all` | Every job gets write access it doesn't need |
| Protect against fork PRs | GitHub handles this automatically | Enabling fork write access in repo settings | Fork PR could push to your registry |

---

## The Secure Pattern (Best Practice Template)

```yaml
name: Build and Deploy
on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

permissions: {}   # deny everything at workflow level

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read   # only read — nothing to write here
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make build

  deploy:
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write   # only this job can push to GHCR
    steps:
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          push: ${{ github.event_name != 'pull_request' }}
```

---

## Key Rules to Remember

- `secrets.GITHUB_TOKEN` is auto-generated — you never create or store it
- The `permissions:` block controls what that token is allowed to do
- `write` always includes `read`
- Fork PRs automatically get read-only tokens — this is not configurable in the workflow, it is a GitHub platform rule
- `push: ${{ github.event_name != 'pull_request' }}` ensures images are only published after merge, never during PR review
- Always start with the minimum permission needed, then add more only if the workflow fails
- Job-level permissions are safer than workflow-level in multi-job pipelines
