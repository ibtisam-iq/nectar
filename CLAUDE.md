# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 1️⃣ Repository Overview

**Nectar** is a personal engineering knowledge base stored as Markdown and configuration files in a single GitHub repository. It is not a compiled application – rather, it is a collection of documentation, configuration snippets, and reference material that together generate a static documentation site at https://nectar.ibtisam-iq.com.

The source files are organized by domain, including:

| Area | Description |
|------|-------------|
| **Documentation** | MkDocs‑Material site built directly from the repo root (`.`) | `mkdocs.yml`, `index.md`, `*.md` |
| **Infrastructure notes** | Cloud‑/AWS‑, Kubernetes‑, Docker‑related concepts | `cloud-infrastructure/`, `containers-orchestration/` |
| **CI/CD** | GitHub Actions that build, validate, preview, and deploy the site | `.github/workflows/` |
| **Operational runbooks** | Wireguard, CI stack, server configurations | `operations/` |
| **Reference material** | Miscellaneous notes, images, and binary assets | `*.md`, `*.png`, `*.pdf`, `*.txt` under many sub‑folders |
---

## 2️⃣ Common Development Commands

> **Tip** – All commands should be run from the repository root (`/Users/ibtisam-iq/gitHub/nectar`).

| Goal | Command | Description |
|------|---------|-------------|
| **Set up a Python virtual environment** | `python -m venv .venv && source .venv/bin/activate` | Isolates MkDocs and its plugins. |
| **Install documentation dependencies** | `pip install -r requirements.txt` | Installs MkDocs, Material theme, and required plugins. |
| **Run the docs locally (live reload)** | `mkdocs serve -a 0.0.0.0:8000` | Serves the site on <http://localhost:8000> and watches for changes. |
| **Build the static site** | `mkdocs build` | Generates HTML output in the `site/` directory. |
| **Check for broken links** | `lychee ./site/**/*.html` (run after a build) | Scans generated HTML for dead internal links. |
| **Validate documentation assets** | `trivy fs .` (requires Trivy) | Scans bundled binaries for known CVEs. |

### Running Bash Commands in Claude Code

If you want to execute any of the commands inside this chat, prefix the command with an exclamation mark:

```
! mkdocs serve -a 0.0.0.0:8000
```

Claude Code will run it in its sandbox and return the output.

---

## 3️⃣ High‑Level Architecture & Structure

### 3.1 Core Files

* **`mkdocs.yml`** – Central configuration for the MkDocs site (theme, plugins, extensions, navigation, and build options).  
* **`.github/workflows/pages.yml`** – CI pipeline that builds, validates, previews, and deploys the documentation site.  
* **`requirements.txt`** – Pin‑versions of MkDocs and its plugins.  
* **`README.md`** – High‑level introduction, including a Mermaid diagram that shows how Nectar fits into the author’s broader engineering system.  
* **`index.md`** – Root landing page of the generated documentation site.

### 3.2 Documentation Domains

| Domain | Key Sub‑folders | Typical Content |
|--------|----------------|-----------------|
| `cloud-infrastructure` | `aws/`, `cloudflare/`, `github-pages/` | AWS services, Cloudflare tunnels, GitHub Pages setup, IAM policies, networking, security, cost management. |
| `containers-orchestration` | `docker/`, `docker-compose/`, `helm/`, `kubernetes/`, `kustomize/` | Dockerfile patterns, Helm chart authoring, Kubernetes core concepts, networking, storage, security, debugging, workloads, reference cheatsheets. |
| `delivery` | `argocd/`, `git/`, `github/`, `github-actions/`, `jenkins/`, `nexus/`, `sonarqube/` | GitOps (ArgoCD), CI/CD pipelines, Jenkins shared libraries, Nexus repository layout, SonarQube quality gates. |
| `operations` | `cicd-stack/`, `wireguard/` | Self‑hosted CI components and WireGuard VPN setup. |
| `technical-grounding` | Various cheat‑sheets, language‑specific notes, and foundational tutorials | Bash basics, Linux concepts, networking, Python snippets, SSH usage, Vim tips, YAML examples. |
| `scratchpad` | Ad‑hoc notes and personal experiments | Miscellaneous Markdown files used for quick reference. |

### 3.3 CI/CD Pipeline

The repository contains a single GitHub Actions workflow (`.github/workflows/pages.yml`) that defines three jobs:

| Job | Trigger | Purpose |
|-----|---------|---------|
| **build** | `push` to `main` and on every PR | Checks out the repo, installs dependencies, runs `mkdocs build`, and validates generated HTML with Lychee link checking. |
| **preview** | `pull_request` events | Deploys a preview of the modified documentation to a temporary GitHub Pages branch, providing a live URL for review. |
| **deploy** | Non‑PR pushes to `main` | Publishes the final documentation site to the `gh-pages` branch for public consumption. |

The workflow uses minimal permissions (`contents: read` for the build job, `contents: write` for preview/deploy) and includes concurrency protection to avoid overlapping deployments.

---

## 4️⃣ Important Files & Directories (quick reference)

- **`README.md`** – Introductory overview and system diagram.  
- **`mkdocs.yml`** – Full MkDocs configuration.  
- **`.github/workflows/pages.yml`** – CI/CD pipeline definition.  
- **`requirements.txt`** – Dependency versions.  
- **`index.md`** – Home page of the generated site.  
- **`cloud-infrastructure/`** – Cloud‑specific guides (AWS, Cloudflare, etc.).  
- **`containers-orchestration/kubernetes/`** – Comprehensive Kubernetes documentation set.  
- **`delivery/`** – CI/CD tooling notes (ArgoCD, Jenkins, Nexus, SonarQube).  
- **`operations/`** – Operational runbooks (Wireguard, CI stack).  
  

---

## 5️⃣ Development Workflow

1. **Create a feature branch**  
   ```bash
   git checkout -b feature/<short‑slug>
   ```
2. **Edit Markdown files** – Keep line length consistent with existing files. Add new documentation or update existing content.  
3. **Preview locally**  
   ```bash
   mkdocs serve -a 0.0.0.0:8000
   ```  
   The site reloads automatically on each save.  
4. **Build the static site**  
   ```bash
   mkdocs build
   ```  
5. **Validate changes**  
   - Run `lychee ./site/**/*.html` to catch broken internal links.  
   - Optionally run `trivy fs .` if new binaries were added.  
6. **Commit and push**  
   ```bash
   git add .
   git commit -m "feat: add <brief description>"
   git push origin feature/<short‑slug>
   ```
7. **Open a Pull Request** – CI will automatically build the docs, run link checking, and create a preview deployment. The PR comment will contain the preview URL.  
8. **Merge** – After approval, merging to `main` triggers the final **deploy** job that publishes the updated site to GitHub Pages.

---

## 6️⃣ Special Configuration Notes

| Setting | Location | Purpose |
|--------|----------|---------|
| **`docs_dir: .`** | `mkdocs.yml` | Allows the repo root to serve as the documentation source, enabling mixed code‑and‑doc layouts. |
| **`same-dir` plugin** | `mkdocs.yml` → plugins | Supports using the repository root as the docs directory without moving files. |
| **`awesome-pages`** | `mkdocs.yml` → plugins | Controls navigation ordering via `.pages` files. |
| **`section-index`** | `mkdocs.yml` → plugins | Turns each folder’s landing page (`README.md` or `index.md`) into a navigable section. |
| **`exclude_docs`** | `mkdocs.yml` → `exclude_docs:` block | Prevents scripts, config files, and binary assets from being bundled into the final site. |
| **GitHub Action permissions** | `.github/workflows/pages.yml` | Grants only the permissions required for each job (minimal‑privilege principle). |
| **Link‑checking tolerance** | `lychee-action` step | Accepts 200, 429, and 403 responses to ignore expected false‑positive failures (e.g., LinkedIn URLs). |
| **Analytics placeholder** | `mkdocs.yml` → `extra.analytics` (commented) | Ready for Google Analytics integration; uncomment and add a property ID when needed. |

---

## 7️⃣ Quick Reference Cheat‑Sheet (Copy‑Paste)

```bash
# 1️⃣ Bootstrap a dev environment
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2️⃣ Serve locally with live reload
mkdocs serve -a 0.0.0.0:8000

# 3️⃣ Build static site (used by CI)
mkdocs build

# 4️⃣ Check for broken links locally (after a build)
lychee ./site/**/*.html

# 5️⃣ Run security scan on bundled assets
trivy fs .

# 6️⃣ Simulate GitHub Action locally (requires `act`)
act -j build   # runs the “build” job from .github/workflows/pages.yml
```

---

## 8️⃣ Goal for Future Claude Code Sessions

When Claude Code is invoked in this repository, it should:

1. **Emphasize MkDocs‑centric commands** (`mkdocs serve`, `mkdocs build`).  
2. **Reference the navigation hierarchy** defined by `.pages` when suggesting where to place new documentation.  
3. **Leverage the CI pipeline** – e.g., remind users that PRs get automatic preview URLs and that link checking runs on every push.  
4. **Avoid touching autogenerated files** (`site/`, `*.pages` that already exist) unless explicitly asked to restructure navigation.  
5. **Use `README.md` and `mkdocs.yml`** as the single source of truth for site‑wide metadata (site name, URL, theme, analytics).  

--- 

*End of CLAUDE.md*