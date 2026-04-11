# Git Submodules

## The Problem It Solves

Imagine you have two repositories:

- `java-monolith-app` — holds the Spring Boot application source code
- `platform-engineering-systems` — holds Dockerfiles, Terraform, Kubernetes manifests

You need the application code to be available inside `platform-engineering-systems` (so Docker can build from it, Terraform can reference it, etc.).

**The naive approach:** Copy-paste the code from one repo into the other.

**Why that is wrong:**

- The code now exists in two places. Any change in the source repo must be manually re-copied.
- You lose the single source of truth.
- Over time, the copies diverge. You will ship the wrong version.
- This is exactly the kind of manual, error-prone process that DevOps practices are designed to eliminate.

**The correct approach:** Git Submodules.

A submodule is a **pointer** — not a copy. The parent repo stores only a reference (a commit SHA) to another repo. The actual files live in the original repo and are fetched on demand. No duplication.

---

## When to Use Submodules

Use a submodule when:

- A separate repository produces artifacts (code, configs, schemas) that another repo needs to consume
- You want the consumer repo to be pinned to a **specific, reviewed version** of the source repo (not always the latest tip)
- Multiple repos need to reference the same source without duplicating it
- You are separating concerns: one repo owns application code, another owns infrastructure

Do **not** use submodules when:

- The code is tightly coupled and always changes together — keep it in one repo
- Your team is unfamiliar with Git internals and you have no time to document the workflow

---

## How It Works Internally

Two things get created in the parent repo when you add a submodule:

### 1. `.gitmodules` (tracked file, committed to the repo)

This maps the local path to the remote URL:

```ini
[submodule "systems/java-monolith/app"]
    path = systems/java-monolith/app
    url = https://github.com/ibtisam-iq/java-monolith-app.git
```

> **Never add `.gitmodules` to `.gitignore`.** This file is what connects the folder path to the source repo. If it is ignored, Git forgets the mapping and the submodule breaks for everyone who clones the repo.

### 2. `.git/config` (local only, not committed)

Git also writes an entry in the local config with the resolved URL and `active = true`. This is per-machine and not shared.

```ini
[submodule "systems/java-monolith/app"]
    url = https://github.com/ibtisam-iq/java-monolith-app.git
    active = true
```

### 3. The folder itself (`systems/java-monolith/app/`)

The parent repo does **not** store the files inside this folder. It stores only a single commit SHA. That SHA is what gets committed to the parent repo each time you update the submodule pointer.

You can verify this:

```bash
git ls-files --stage systems/java-monolith/app
# Output: 160000 <commit-sha> 0  systems/java-monolith/app
# Mode 160000 = this is a submodule, not a regular file
```

---

## First-Time Setup

### Adding a submodule (done once, by the repo maintainer)

```bash
# From the root of the parent repo
git submodule add https://github.com/ibtisam-iq/java-monolith-app.git systems/java-monolith/app
```

This creates:
- The `.gitmodules` file (or appends to it)
- The `systems/java-monolith/app/` folder with the source code fetched at HEAD

Then commit and push:

```bash
git add .gitmodules systems/java-monolith/app
git commit -m "chore: add java-monolith-app as submodule"
git push
```

### Cloning a repo that already has submodules

A plain `git clone` will leave submodule folders **empty**. Always clone with:

```bash
git clone --recurse-submodules https://github.com/ibtisam-iq/platform-engineering-systems.git
```

If you already cloned without the flag:

```bash
git submodule update --init --recursive
```

- `--init` registers the submodule URL from `.gitmodules` into `.git/config`
- `--recursive` handles nested submodules (submodules inside submodules)

---

## Updating the Submodule (When Source Repo Changes)

This is the most common day-to-day operation. The source repo (`java-monolith-app`) received new commits and you want to pull them into the parent repo.

### Method 1 — Manual (explicit control)

```bash
# Step 1: Go inside the submodule folder
cd systems/java-monolith/app

# Step 2: Pull the latest commits from the source repo
git pull origin main

# Step 3: Go back to the parent repo root
cd ../../../

# Step 4: Stage the updated commit pointer
git add systems/java-monolith/app
git commit -m "chore: update java-monolith submodule to latest"
git push
```

> **Why is Step 4 required?**
> After `git pull` inside the submodule, the pointer (commit SHA) stored in the parent repo is now outdated. The parent repo still points to the old commit. You need to commit and push the updated pointer so that CI/CD and other contributors get the correct version when they run `git submodule update`.

### Method 2 — Single command (all submodules at once)

```bash
git submodule update --remote --merge
```

Then stage and push:

```bash
git add .
git commit -m "chore: update all submodules to latest"
git push
```

`--remote` fetches the latest commit from the tracked branch instead of the pinned SHA. `--merge` merges it into the local submodule working tree.

---

## The `already up to date` Trap

If you run `git pull origin main` from the **parent repo root** instead of **inside the submodule folder**, Git will say:

```
Already up to date.
```

This is misleading. The parent repo is up to date, but the submodule folder still has the old code. You must `cd` into the submodule folder before pulling, or use `git submodule update --remote`.

---

## Submodule States and What They Mean

```bash
git status
# modified:  systems/java-monolith/app (new commits)
```

| Status | Meaning |
|---|---|
| `new commits` | The submodule has new commits locally that the parent hasn’t committed yet |
| `modified content` | There are uncommitted changes inside the submodule |
| `untracked content` | New untracked files inside the submodule |

---

## Quick Reference

| Task | Command |
|---|---|
| Add a submodule | `git submodule add <url> <path>` |
| Clone with submodules | `git clone --recurse-submodules <url>` |
| Init after plain clone | `git submodule update --init --recursive` |
| Update one submodule | `cd <path> && git pull origin main && cd -` |
| Update all submodules | `git submodule update --remote --merge` |
| Check submodule status | `git submodule status` |
| List all submodules | `cat .gitmodules` |

---

## README Warning (Add This to Any Repo Using Submodules)

If your repo uses submodules, add this note to its README so contributors do not get confused by empty folders:

```markdown
> **This repository uses Git submodules.**
> Clone with: `git clone --recurse-submodules <url>`
> If already cloned: `git submodule update --init --recursive`
```
