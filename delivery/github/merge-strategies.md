# GitHub Merge Strategies: Merge, Squash, Rebase

This doc explains the three merge options that appear on every GitHub pull request:

- **Create a merge commit**
- **Squash and merge**
- **Rebase and merge**

The examples assume a feature branch (for example `feat/add-eksctl`) being merged into `main`.

---

## 1. Create a merge commit

**What it does**

- All commits from the feature branch are added to `main` **as-is**.
- GitHub then creates a **merge commit** on top of `main`, usually named:

  ```text
  Merge pull request #N from feature-branch
  ```

**How history looks**

- `main` shows:
  - each original commit from the feature branch
  - plus one extra "Merge pull request #N" commit that clearly marks where the PR was merged
- You can immediately see **which branch** was merged and **which PR number** it came from.

**Pros**

- Preserves the **full commit history** from the feature branch.
- Shows a clear marker in history: `Merge pull request #N from feat/xyz`.
- Very common in many real-world teams.

**Cons**

- Adds an extra commit for every PR.
- On very busy repos this can make history look a bit "noisy".

**When to use it**

- You want to see **explicit PR merge markers** in history.
- You want to preserve all feature-branch commits exactly as they were.
- The repository is small or medium sized, and a few merge commits are not a problem.

---

## 2. Squash and merge

**What it does**

- Takes all commits from the feature branch and **combines them into a single new commit**.
- That single commit is added to `main`.

**How history looks**

- `main` gets **one new commit** for the entire PR.
- The commit message usually defaults to the PR title, sometimes with the PR number:

  ```text
  feat: add eksctl v0.226.0 binary (#3)
  ```

- The original feature-branch commits are not visible on `main` any more (they only exist in the branch).

**Pros**

- Keeps `main` **very clean**: one commit per PR.
- Great when the branch history has many small or "WIP" commits.

**Cons**

- Loses the granular commit history from the branch on `main`.
- If a bug is introduced by the PR, it is contained in a single big commit.

**When to use it**

- You want **one commit per PR** on `main`.
- Branch history is noisy and you do not need each intermediate step.
- You prefer a very compact history over detailed commit-by-commit tracing.

---

## 3. Rebase and merge

**What it does**

- GitHub replays the feature-branch commits **on top of the current `main`**, one by one.
- No merge commit is created.

**How history looks**

- `main` becomes a **linear history**:
  - existing `main` commits
  - followed by each feature-branch commit (with new SHAs)
- There is **no** "Merge pull request" commit.
- Unless you include `(#N)` in commit messages yourself, the PR number is not obvious from `git log`.

**Pros**

- Clean, **linear history** with no merge bubbles.
- Still preserves **each commit** from the feature branch (unlike squash).

**Cons**

- Rewrites commit SHAs (the rebased commits are not byte-for-byte the originals).
- No explicit merge-commit marker in history.

**When to use it**

- You want a **linear history** without merge commits.
- You still care about each individual commit from the branch.
- The team is comfortable with rebasing semantics.

---

## How commit counts change

Assume:

- `main` currently has 137 commits.
- Feature branch has 3 new commits that are not on `main`.

After merging that branch into `main`:

- **Create a merge commit**
  - `main` gets the 3 commits **plus 1 merge commit**.
  - Total commits on `main` increase by 4.

- **Squash and merge**
  - `main` gets **1 new commit** (the squash).
  - Total commits on `main` increase by 1.

- **Rebase and merge**
  - `main` gets **3 new commits** (rebased versions of the branch commits).
  - Total commits on `main` increase by 3.

In all three cases, the **final code on `main` is the same**; only the shape of the history and the number of commits differ.

---

## Suggested defaults for personal DevOps repos

For a personal or small-team DevOps repository where you:

- use feature branches and PRs,
- write clean, meaningful commits,
- want history to reflect your workflow clearly,

this is a reasonable default:

- Use **Create a merge commit** when you want to see explicit `Merge pull request #N from feature-branch` markers in history.
- Use **Squash and merge** when the branch contains many noisy or experimental commits and you only want a single, clean commit on `main`.
- Use **Rebase and merge** when you prefer a linear history and are comfortable not having a merge-commit marker for the PR.

For showcasing Git skills to recruiters, using feature branches, PRs, and **Create a merge commit** (with clear commit messages) is perfectly acceptable and easy to read in `git log --oneline --graph`.
