# Deploying MkDocs Projects on GitHub Actions

## Method 1: Using `mkdocs gh-deploy` (Simple & Built-in)

**Overview:**

* This is the simplest, built-in method. MkDocs itself handles the deployment directly to a `gh-pages` branch.

**How it works:**

* You run a simple command: `mkdocs gh-deploy --force`.
* It builds the site and pushes the generated files directly to a `gh-pages` branch.
* No separate GitHub Action is needed; MkDocs handles it internally.

**Pros:**

* Very easy to use.
* Good for quick, simple deployments.

**Cons:**

* Less control and customization.
* No advanced CI/CD stages or testing steps.

**YAML Example:**
No YAML needed for this method, just the command in your workflow step:

```yaml
name: Deploy Nectar Docs

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: 3.11

      - name: Install Dependencies
        run: pip install mkdocs-material mkdocs-awesome-pages-plugin mkdocs-glightbox mkdocs-autorefs mkdocs-statistics-plugin

      - name: Deploy to GitHub Pages
        run: mkdocs gh-deploy --force      # both builds and deploys in one step, which is why you don't see a separate build command
```

---

## Method 2: Using GitHub’s `deploy-pages` Action (Modern Artifact-Based)

**Overview:**

* This method uses GitHub’s native artifact-based deployment. It does not use the `gh-pages` branch directly but relies on GitHub’s own Pages infrastructure.

**How it works:**

* You build the site and upload the `/site` directory as an artifact.
* Then you use the `deploy-pages` action to deploy that artifact to GitHub Pages.

**Pros:**

* Clean, modern approach.
* Managed entirely by GitHub’s infrastructure.

**Cons:**

* No `gh-pages` branch history.
* Slightly less transparent than having a dedicated branch.

This is the **modern GitHub Pages native deployment method**, using artifacts + `deploy-pages` action.

### How it works

1. Build docs → generates `/site`
2. Upload `/site` as an artifact (zip-like output)
3. GitHub automatically deploys artifact to Pages hosting

**It does not use `gh-pages` branch.**
Deployment is handled internally by GitHub itself.

This is the architecture GitHub wants people to move toward long-term.

**YAML Example:**

```yaml
- name: Build site
  run: mkdocs build --clean

- name: Upload artifact
  uses: actions/upload-pages-artifact@v3
  with:
    path: ./site

- name: Deploy to GitHub Pages
  uses: actions/deploy-pages@v4
```

---

## Method 3: Using `peaceiris/actions-gh-pages` (Enterprise-Grade with Full CI/CD)

**Overview:**

* This is the most robust and flexible method. It uses a dedicated `gh-pages` branch and can be integrated into a multi-stage CI/CD pipeline.

**How it works:**

* You build the site and then use the `peaceiris` action to push the built files to the `gh-pages` branch.
* This method is ideal for enterprise-level documentation with multiple CI stages (build, test, deploy).

**Pros:**

* Full control and transparency with a dedicated branch.
* Can be part of a more complex pipeline.

**Cons:**

* Slightly more setup, but very powerful.

**YAML Example:**

```yaml
- name: Build site
  run: mkdocs build --strict

- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./site
    publish_branch: gh-pages
```

---

## 🔥 The Method We Are Using Now

```yaml
uses: peaceiris/actions-gh-pages@v3
```

This is **the classic industry standard of the last many years**.
It deploys static files into a **real branch** called:

```
gh-pages
```

### How it works

| Step                                          | Behavior                                         |
| --------------------------------------------- | ------------------------------------------------ |
| Build docs                                    | Generates `/site`                                |
| Action pushes `/site` → into gh-pages branch  | Static site is built as a full repository branch |
| GitHub Pages serves directly from that branch | Public output is visible and version-controlled  |

Advantages:

✔ Branch visible → transparent deployments
✔ Works with anything (Hugo, Docusaurus, MkDocs, React, Static SPA)
✔ Battle-tested in enterprise for years

This is the method we expanded into a multi-stage CI/CD pipeline.

---

### So What’s the Real Difference?

| Feature | Modern GitHub Pages Deploy (`deploy-pages`) | Traditional (`peaceiris/gh-pages`) |
|---|---|
| Uses `gh-pages` branch | ❌ No | ✔ Yes |
| Stores build output visibly | ❌ (artifacts invisible later) | ✔ (branch history preserved) |
| Industry adoption | Increasing recently | VERY mature + widely used |
| Best for Long-term Infra Projects | ⚠ Not always (less transparent) | ✔ Ideal for controlled pipelines |
| Multi-job CI/CD integration | Possible but indirect | Natural (branch as deployment unit) |

---

### In simple terms:

**deploy-pages**
→ *GitHub-managed hosting with artifacts only*
→ clean, simple, newer approach

**peaceiris / gh-pages**
→ *Engineer-managed deployment with a real branch*
→ transparent, versionable, production-friendly
→ easier for scaling into multi-stage pipelines (what we're doing)

---
