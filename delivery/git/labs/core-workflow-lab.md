# Core Workflow Lab

Practise the everyday loop end to end: initialise a repository, set an identity, stage in whole and in part, commit and amend, inspect history, ignore files, and undo changes at each level. Run every task in a throwaway repository.

---

## Setup

Create a fresh sandbox. This lab starts from an empty directory, so there is no first commit yet.

```bash
mkdir -p /tmp/git-lab && cd /tmp/git-lab
rm -rf core && mkdir core && cd core
```

Use example identities only; never paste a real email, token or private remote URL into a lab.

---

## Foundations

### 1. Initialise and Configure

Turn the directory into a Git repository, then set the identity and default branch for this repository only.

??? tip "Solution"
    ```bash
    git init
    git config user.name "Amina Yusuf"
    git config user.email "amina@example.com"
    git config --show-scope --get user.email   # expect: local  amina@example.com
    ```

### 2. Confirm the Empty State

Show that the repository has no commits and the working tree is clean.

??? tip "Solution"
    ```bash
    git status          # "No commits yet"
    git log 2>&1 || true # fails: no commits to show
    ```

---

## Staging and Committing

### 3. First Commit

Create `service.yml` with any content, stage it, and commit it. Confirm the commit shows as the root commit.

??? tip "Solution"
    ```bash
    printf 'name: shop\n' > service.yml
    git add service.yml
    git commit -m "Add service manifest"   # (root-commit) in the summary
    ```

### 4. Stage Part of a File

Add two unrelated lines far apart in `service.yml`, then stage only the first with an interactive add.

??? tip "Solution"
    ```bash
    printf 'name: shop\nport: 80\nreplicas: 1\nregion: eu\ntier: free\n' > service.yml
    git add -p        # answer y to the first hunk, n to the rest
    git status -s     # expect: MM service.yml
    git diff --cached # shows only the staged hunk
    ```

### 5. Amend a Commit

Commit the staged hunk, then realise you forgot to add a `README.md`. Add it to the same commit without creating a new one.

??? tip "Solution"
    ```bash
    git commit -m "Set service port"
    printf '# Shop\n' > README.md
    git add README.md
    git commit --amend --no-edit
    git show --stat HEAD    # both files under the original message
    ```

---

## Inspecting History

### 6. Read the Log

Make one more commit, then view the history as a compact graph and as a custom one-line format.

??? tip "Solution"
    ```bash
    printf 'name: shop\nport: 443\n' > service.yml
    git commit -am "Serve on 443"
    git log --oneline --graph
    git log --pretty=format:'%h %ad %s' --date=short
    ```

### 7. Blame a Line

Find which commit last changed the `port` line in `service.yml`.

??? tip "Solution"
    ```bash
    git blame service.yml    # the port line points at "Serve on 443"
    git show $(git blame -s -L /port/,+1 service.yml | awk '{print $1}')
    ```

---

## Ignoring Files

### 8. Ignore Generated and Secret Files

Create a `build/` directory, a `.log` file and a `.env`, then ignore all three and confirm they no longer show as untracked.

??? tip "Solution"
    ```bash
    mkdir build && printf 'x\n' > build/out.o
    printf 'log\n' > app.log
    printf 'secret\n' > .env
    printf 'build/\n*.log\n.env\n' > .gitignore
    git status -s              # only .gitignore is untracked
    git check-ignore -v .env   # names the rule that matched
    ```

### 9. Untrack an Already-Committed File

Commit a `config.env`, then decide it should have been ignored. Stop tracking it but keep it on disk.

??? tip "Solution"
    ```bash
    printf 'name=shop\n' > config.env
    git add -f config.env && git commit -m "Add config"
    echo 'config.env' >> .gitignore
    git rm --cached config.env      # D staged, file stays on disk
    git commit -am "Stop tracking config.env"
    ```

---

## Undoing Changes

### 10. Discard an Unstaged Edit

Make a bad edit to `service.yml`, then throw it away and confirm the file is back to the committed version.

??? tip "Solution"
    ```bash
    printf 'name: shop\nport: 0\n' > service.yml
    git restore service.yml
    git status -s     # clean
    ```

### 11. Undo the Last Commit, Keep the Work

Make a commit you decide is premature, then undo the commit while keeping its changes staged.

??? tip "Solution"
    ```bash
    printf 'name: shop\nport: 443\ndraft: true\n' > service.yml
    git commit -am "Draft change"
    git reset --soft HEAD~1
    git status -sb    # change is staged, commit is gone
    ```

### 12. Revert a Commit Safely

Recommit the change from task 11, then back it out with a new commit rather than rewriting history.

??? tip "Solution"
    ```bash
    git commit -m "Draft change"
    git revert --no-edit HEAD
    git log --oneline -2   # original commit plus a Revert commit
    ```

### 13. Clean Untracked Files

Create a couple of untracked scratch files, preview what a clean would remove, then remove them.

??? tip "Solution"
    ```bash
    printf 'x\n' > scratch.txt && mkdir junk && printf 'y\n' > junk/y.txt
    git clean -nd     # dry run: lists what would go
    git clean -fd     # removes them
    git status        # clean
    ```

---

## Cleanup

```bash
cd /tmp && rm -rf /tmp/git-lab
```
