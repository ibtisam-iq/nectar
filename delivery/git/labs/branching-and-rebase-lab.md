# Branching and Rebase Lab

Practise the branching and merging workflow end to end: create branches, fast-forward and three-way merges, rebase, interactive squash, conflict resolution, and cherry-pick. Run every task in a throwaway repository.

---

## Setup

Create a fresh sandbox and one starting commit.

```bash
mkdir -p /tmp/git-lab && cd /tmp/git-lab
rm -rf sandbox && git init sandbox && cd sandbox
git config user.name "Amina Yusuf"
git config user.email "amina@example.com"
printf 'name: shop\n' > service.yml
git add service.yml
git commit -m "Add service manifest"
```

---

## Branches

### 1. Create and Switch

Create a branch `feature/login` from `main` and switch to it in one command. Confirm you are on it.

??? tip "Solution"
    ```bash
    git switch -c feature/login
    git branch --show-current   # expect: feature/login
    ```

### 2. Commit on the Branch

Add a file `auth.py` with any content and commit it. Then confirm `main` has not moved.

??? tip "Solution"
    ```bash
    printf 'def login(): ...\n' > auth.py
    git add auth.py && git commit -m "Add login function"
    git log --oneline main -1     # still at the first commit
    ```

---

## Merging

### 3. Fast-Forward Merge

Switch to `main` and merge `feature/login`. Because `main` has no new commits, this fast-forwards. Confirm the history is linear.

??? tip "Solution"
    ```bash
    git switch main
    git merge feature/login       # prints: Fast-forward
    git log --oneline --graph -3
    ```

### 4. Force a Merge Commit

Create `feature/cart`, add a commit, switch to `main`, and merge with a merge commit even though a fast-forward is possible.

??? tip "Solution"
    ```bash
    git switch -c feature/cart
    printf 'def add(): ...\n' > cart.py
    git add cart.py && git commit -m "Add cart add"
    git switch main
    git merge --no-ff --no-edit feature/cart
    git log --oneline --graph -3   # a two-parent merge commit at the top
    ```

---

## Rebasing

### 5. Rebase a Feature onto main

Start `feature/search` from `main`, add two commits, then add a commit to `main` so the branches diverge. Rebase the feature onto `main` and confirm the history is linear with new SHAs.

??? tip "Solution"
    ```bash
    git switch -c feature/search
    printf 'def find(): ...\n' > search.py
    git add search.py && git commit -m "Add search"
    printf 'def rank(): ...\n' >> search.py
    git commit -am "Add ranking"
    git switch main
    printf '# Shop\n' > README.md
    git add README.md && git commit -m "Document setup"
    git switch feature/search
    git rebase main               # prints: Successfully rebased ...
    git log --oneline --graph -4  # one straight line, no merge commit
    ```

### 6. Squash Before a Pull Request

On `feature/search`, squash the two feature commits into one with an interactive rebase.

??? tip "Solution"
    ```bash
    git rebase -i HEAD~2
    # in the editor: keep the first as 'pick', change the second to 'fixup', save
    git log --oneline -2          # the two commits are now one
    ```

---

## Conflict Resolution

### 7. Create and Resolve a Conflict

Make `main` and a new branch `feature/tls` each change the same line of a file, then merge and resolve.

??? tip "Solution"
    ```bash
    printf 'port: 80\n' > config.yml
    git add config.yml && git commit -m "Set port 80"
    git switch -c feature/tls
    printf 'port: 443\n' > config.yml
    git commit -am "Serve on 443"
    git switch main
    printf 'port: 8080\n' > config.yml
    git commit -am "Serve on 8080"
    git merge --no-edit feature/tls    # CONFLICT in config.yml
    ```

    Resolve it, then verify and commit:

    ```bash
    git status -s                      # UU config.yml
    printf 'port: 443\n' > config.yml  # decide the final value, remove markers
    git add config.yml
    git diff --check                   # no leftover markers
    git commit --no-edit
    ```

### 8. Abort Instead of Resolving

Trigger the same conflict again on a fresh branch, then abort the merge and confirm the tree is clean.

??? tip "Solution"
    ```bash
    git switch -c feature/tls2 HEAD~1
    printf 'port: 9090\n' > config.yml
    git commit -am "Serve on 9090"
    git switch main
    git merge --no-edit feature/tls2   # CONFLICT
    git merge --abort
    git status                          # clean, back at the pre-merge commit
    ```

---

## Cherry-Pick

### 9. Backport One Commit

On a branch `develop`, make two commits. Cherry-pick only the second onto `main`, recording the source.

??? tip "Solution"
    ```bash
    git switch -c develop
    printf 'f1\n' > feature.py && git add feature.py && git commit -m "Add feature one"
    printf 'patch\n' > hotfix.py && git add hotfix.py && git commit -m "Fix parser"
    git switch main
    git cherry-pick -x develop         # copies only the tip commit
    git log -1 --format=%b             # shows (cherry picked from commit ...)
    ```

---

## Cleanup

```bash
cd /tmp && rm -rf /tmp/git-lab
```
