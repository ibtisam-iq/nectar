# Static Site Deployment via GitHub Actions

This document covers every method available to deploy a static site (MkDocs, Hugo, Docusaurus, plain HTML, etc.) to GitHub Pages using GitHub Actions. These are not MkDocs-specific — they work for **any static site generator**.

Three deployment methods exist. The right choice depends on whether you need PR previews, multi-job pipelines, or simplicity.

---

## Method Comparison at a Glance

| Feature | Method 1: `mkdocs gh-deploy` | Method 2: OIDC (`deploy-pages`) | Method 3: Branch (`peaceiris`) |
|---|---|---|---|
| **Complexity** | Minimal | Moderate | Moderate |
| **`gh-pages` branch created** | Yes | No | Yes |
| **Separate build + deploy jobs** | No (single step) | Yes | Yes |
| **PR preview support** | No | No | Yes (via `rossjrw`) |
| **Multi-job artifact sharing** | No | No (internal pipe) | Yes (standard artifact) |
| **Deployment history visible** | Yes (branch commits) | No (internal) | Yes (branch commits) |
| **GitHub Pages source setting** | Deploy from branch | GitHub Actions | Deploy from branch |
| **Best for** | Quick personal projects | Clean modern pipelines | Production + PR previews |

---

## Method 1 — `mkdocs gh-deploy` (Built-in, Simplest)

### How it works

MkDocs has a built-in command that **builds and deploys in one step**. It pushes the generated `/site` directory directly to a `gh-pages` branch. No separate deploy action is needed.

```
push to main → single job → mkdocs gh-deploy --force → gh-pages branch updated
```

### When to use

- Personal or hobby projects
- No QA steps needed (no HTML validation, no link checking)
- You want the simplest possible workflow (under 20 lines of YAML)
- MkDocs-only projects (this command is not available for Hugo/Docusaurus)

### When NOT to use

- You need to run tests before deploying
- You want PR previews
- You need to share the build artifact between jobs
- Non-MkDocs static site generators

### GitHub Pages setting

**Settings → Pages → Source:** `Deploy from a branch` → `gh-pages` / `/ (root)`

### Full workflow example

```yaml
name: Deploy Docs

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0   # required for git-revision-date plugin

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Build and deploy
        run: mkdocs gh-deploy --force
        # This single command: builds the site → pushes to gh-pages branch
```

---

## Method 2 — OIDC / `actions/deploy-pages` (Modern GitHub-Native)

### How it works

This is GitHub's **official modern approach**. The build job uploads the `/site` directory as a special internal artifact using `upload-pages-artifact`. A separate deploy job then uses `actions/deploy-pages` to push it to GitHub Pages through GitHub's internal OIDC pipeline — **no `gh-pages` branch is created**.

```
build job → upload-pages-artifact → [GitHub internal pipeline]
deploy job → actions/deploy-pages → site goes live
```

The artifact handoff between jobs is **internal to GitHub Pages infrastructure** — only `actions/deploy-pages` can consume an artifact uploaded by `upload-pages-artifact`. No other job can read it.

### When to use

- You want a clean repo with no extra branches
- You do not need PR previews
- You prefer GitHub's managed infrastructure
- Works with any static site generator (not MkDocs-only)

### When NOT to use

- You need PR preview deployments (the `gh-pages` branch is required for that)
- You need multiple jobs to consume the same build artifact
- You want deployment history visible as branch commits

### GitHub Pages setting

**Settings → Pages → Source:** `GitHub Actions`

### Required permissions

```yaml
permissions:
  pages: write
  id-token: write
```

### Full workflow example

```yaml
name: Deploy Docs

on:
  push:
    branches:
      - main
  workflow_dispatch:

concurrency:
  group: pages
  cancel-in-progress: true

permissions:
  contents: read

jobs:

  build:
    name: Build Site
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Build site
        run: mkdocs build

      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./site
          # Note: this is a SPECIAL artifact — only actions/deploy-pages can consume it

  deploy:
    name: Deploy to GitHub Pages
    runs-on: ubuntu-latest
    needs: build

    permissions:
      pages: write
      id-token: write

    environment:
      name: github-pages
      url: ${{ steps.deploy.outputs.page_url }}

    steps:
      - name: Deploy to GitHub Pages
        id: deploy
        uses: actions/deploy-pages@v4
```

---

## Method 3 — `peaceiris/actions-gh-pages` + PR Previews (Production-Grade)

### How it works

The build job uploads `/site` as a **standard workflow artifact** (not the special Pages artifact). Two downstream jobs can both consume it:

1. **Preview job** — runs only on PRs, deploys a live temporary URL at `/previews/pr-<number>/` using `rossjrw/pr-preview-action`, and posts a comment on the PR with the preview link. Automatically cleaned up when the PR is merged or closed.
2. **Deploy job** — runs only on pushes to `main`, deploys the production site by pushing to the `gh-pages` branch via `peaceiris/actions-gh-pages`.

```
build job  ──(artifact)──┬──► preview job  (PR only)  → /previews/pr-5/
                         └──► deploy job   (main only) → production site
```

Because both jobs share the same general-purpose artifact, the site is **built exactly once** regardless of which downstream job runs.

### Why `peaceiris` is required for PR previews

`rossjrw/pr-preview-action` works by writing preview folders **into the `gh-pages` branch** alongside the main site. It needs a real, writable branch to do this. The OIDC method has no such branch — GitHub manages it internally and it cannot be written to by other actions. Therefore, **PR previews require the `peaceiris` branch-based method**.

### When to use

- Production documentation sites with external contributors
- You want reviewers (including yourself) to see a live preview before merging a PR
- Multi-stage CI/CD with build, QA, preview, and deploy as separate jobs
- Works with any static site generator

### When NOT to use

- Tiny personal projects with no contributors (Method 1 is simpler)
- You specifically want no extra branches in your repo

### GitHub Pages setting

**Settings → Pages → Source:** `Deploy from a branch` → `gh-pages` / `/ (root)`

### Required permissions

```yaml
# deploy job
permissions:
  contents: write   # push to gh-pages branch

# preview job
permissions:
  contents: write       # push preview folder to gh-pages branch
  pull-requests: write  # post preview URL comment on the PR
```

### PR preview flow (from a contributor's perspective)

```
1. Contributor forks your repo
2. Makes changes to a .md file
3. Opens a Pull Request to your repo
4. GitHub Actions triggers automatically:
   - Build job runs (mkdocs build, HTML validation, link check)
   - Preview job deploys to: https://your-site.com/previews/pr-5/
   - A bot comments on the PR with the live preview URL
5. You click the link, review the rendered docs
6. If happy → merge the PR
7. Deploy job runs → production site updated
8. Preview URL at /previews/pr-5/ is automatically deleted
```

### Full workflow example

```yaml
name: Docs — Build & Deploy

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:

concurrency:
  group: pages-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:

  # ──────────────────────────────────────────────
  # JOB 1 — Build + QA (runs on push AND PR)
  # ──────────────────────────────────────────────
  build:
    name: Build Site
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: pip

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Build site
        run: mkdocs build

      - name: Upload site artifact
        uses: actions/upload-artifact@v4
        with:
          name: site
          path: ./site
          retention-days: 1
          # Standard artifact — can be consumed by ANY downstream job

  # ──────────────────────────────────────────────
  # JOB 2 — PR Preview (runs ONLY on pull_request)
  # Live URL: https://your-site.com/previews/pr-<number>/
  # Bot posts the URL as a comment on the PR.
  # Deleted automatically when PR is closed.
  # ──────────────────────────────────────────────
  preview:
    name: Deploy PR Preview
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'pull_request'

    permissions:
      contents: write
      pull-requests: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download built site
        uses: actions/download-artifact@v4
        with:
          name: site
          path: ./site

      - name: Deploy PR preview
        uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: ./site
          umbrella-dir: previews
          action: auto
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  # ──────────────────────────────────────────────
  # JOB 3 — Production Deploy (runs ONLY on push to main)
  # ──────────────────────────────────────────────
  deploy:
    name: Deploy to GitHub Pages
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name != 'pull_request'

    permissions:
      contents: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download built site
        uses: actions/download-artifact@v4
        with:
          name: site
          path: ./site

      - name: Write CNAME (if using a custom domain)
        run: echo "your-site.com" > ./site/CNAME

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./site
          publish_branch: gh-pages
          force_orphan: true
          # force_orphan: keeps gh-pages branch as a single flat commit
          # (no history bloat from thousands of doc build commits)
```

---

## Key Concept — `upload-pages-artifact` vs `upload-artifact`

This is the most common point of confusion when switching between methods.

| | `upload-pages-artifact` (Method 2) | `upload-artifact` (Method 3) |
|---|---|---|
| **Consumer** | Only `actions/deploy-pages` | Any job via `download-artifact` |
| **Visibility** | Internal GitHub pipeline | Visible in workflow run artifacts |
| **Multiple consumers** | No — single deploy job only | Yes — preview job AND deploy job can both use it |
| **Use case** | OIDC single-deploy pipelines | Multi-job pipelines, PR previews |

In Method 3, the build job uploads once, and both the preview job and deploy job download the same artifact. This ensures the **exact same build** is previewed and then deployed — no risk of drift between what you reviewed and what went live.

---

## Are These Methods MkDocs-Only?

**No.** The deployment methods (Methods 2 and 3) are completely generic and work with any static site generator:

| Generator | Build command | Output dir |
|---|---|---|
| MkDocs | `mkdocs build` | `./site` |
| Hugo | `hugo` | `./public` |
| Docusaurus | `npm run build` | `./build` |
| Jekyll | `bundle exec jekyll build` | `./_site` |
| Plain HTML | *(no build step)* | `./` |

The only thing that changes between generators is the **build command** and the **output directory** you pass to the upload/deploy action. Everything else in the workflow is identical.

Method 1 (`mkdocs gh-deploy`) is MkDocs-only because it is a built-in MkDocs CLI command.

---

## Decision Guide

```
Do you need PR previews?
├── Yes → Method 3 (peaceiris + rossjrw)
└── No
    ├── Do you need QA steps (HTML validation, link checks)?
    │   ├── Yes → Method 2 (OIDC) or Method 3 (peaceiris)
    │   └── No
    │       └── Is it a MkDocs project?
    │           ├── Yes → Method 1 (mkdocs gh-deploy) — simplest
    │           └── No  → Method 2 (OIDC) — clean and modern
    └── Do you want a gh-pages branch for transparency?
        ├── Yes → Method 3 (peaceiris)
        └── No  → Method 2 (OIDC)
```
