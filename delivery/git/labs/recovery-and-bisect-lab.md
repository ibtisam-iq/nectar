# Recovery and Bisect Lab

Practise getting work back and finding a bad commit: recover after a hard reset, rescue a deleted branch, undo a merge with `ORIG_HEAD`, and run an automated bisect. Run every task in a throwaway repository.

---

## Setup

Create a fresh sandbox with a short history.

```bash
mkdir -p /tmp/git-lab && cd /tmp/git-lab
rm -rf recovery && git init recovery && cd recovery
git config user.name "Amina Yusuf"
git config user.email "amina@example.com"
printf 'v1\n' > app.py && git add app.py && git commit -m "Add app"
printf 'v2\n' >> app.py && git commit -am "Add feature"
printf 'v3\n' >> app.py && git commit -am "Add tests"
```

Use example identities only; never paste a real email, token or private remote URL into a lab.

---

## Reflog Recovery

### 1. Recover After a Hard Reset

Hard-reset the branch back two commits, confirm they are gone from `git log`, then restore them with the reflog.

??? tip "Solution"
    ```bash
    git reset --hard HEAD~2
    git log --oneline            # only "Add app"
    git reflog                    # HEAD@{1} is the pre-reset tip
    git reset --hard HEAD@{1}
    git log --oneline            # all three back
    ```

### 2. Recover the Non-Destructive Way

Reset back two commits again, but this time rescue the lost tip onto a new branch instead of moving the current one.

??? tip "Solution"
    ```bash
    lost=$(git rev-parse HEAD)   # note the tip first
    git reset --hard HEAD~2
    git branch recovered "$lost"
    git log --oneline recovered  # the work is safe on 'recovered'
    git reset --hard recovered   # or bring main back to it
    ```

### 3. Rescue a Deleted Branch

Create a branch with a commit, switch away, delete it with `-D`, then recreate it from the SHA the delete printed.

??? tip "Solution"
    ```bash
    git switch -c feature/x
    printf 'x\n' > x.txt && git add x.txt && git commit -m "Add x"
    git switch main
    git branch -D feature/x      # prints: Deleted branch feature/x (was <sha>)
    git branch feature/x <sha>   # or: git branch feature/x $(git reflog | awk '/Add x/{print $1; exit}')
    git log --oneline feature/x -1
    ```

---

## ORIG_HEAD

### 4. Undo a Merge in One Command

Create a branch with a commit, merge it into `main`, then undo the merge with `ORIG_HEAD`.

??? tip "Solution"
    ```bash
    git switch -c feature/y
    printf 'y\n' > y.txt && git add y.txt && git commit -m "Add y"
    git switch main
    git merge --no-ff --no-edit feature/y
    git reset --hard ORIG_HEAD   # main is back to the pre-merge commit
    git log --oneline
    ```

---

## Bisect

### 5. Build a History with a Hidden Bug

Create a `calc.py` that works, add a few commits, break it in the middle, then add more commits so the bug is buried.

??? tip "Solution"
    ```bash
    rm -rf /tmp/git-lab/bisect && git init /tmp/git-lab/bisect && cd /tmp/git-lab/bisect
    git config user.name "Amina Yusuf" && git config user.email "amina@example.com"
    printf 'def add(a,b):\n    return a+b\n' > calc.py
    git add calc.py && git commit -m "Add calc"
    for i in 1 2 3; do echo "# note $i" >> notes.txt; git add notes.txt; git commit -m "Note $i"; done
    printf 'def add(a,b):\n    return a-b  # BUG\n' > calc.py
    git add calc.py && git commit -m "Refactor calc"
    for i in 4 5 6; do echo "# note $i" >> notes.txt; git add notes.txt; git commit -m "Note $i"; done
    ```

### 6. Find the Bad Commit Manually

Start a bisect with the current commit bad and the first commit good, and mark each checkout by testing `add(2,1)`.

??? tip "Solution"
    ```bash
    git bisect start HEAD $(git rev-list --max-parents=0 HEAD)
    # at each checkout:
    python3 -c "import calc; print(calc.add(2,1))"   # 3 = good, else bad
    git bisect good   # or: git bisect bad
    # repeat until: <sha> is the first bad commit
    git bisect reset
    ```

### 7. Automate the Bisect

Write a test script that exits 0 when `add(2,1)==3`, then let `git bisect run` find the culprit unattended.

??? tip "Solution"
    ```bash
    cat > test.sh <<'EOF'
    #!/bin/sh
    python3 -c "import calc,sys; sys.exit(0 if calc.add(2,1)==3 else 1)"
    EOF
    chmod +x test.sh
    git bisect start HEAD $(git rev-list --max-parents=0 HEAD)
    git bisect run ./test.sh     # names the "Refactor calc" commit
    git bisect reset
    ```

### 8. Read and Fix the Culprit

Show the diff of the commit bisect found, then revert only that change.

??? tip "Solution"
    ```bash
    git show <first-bad-sha>     # shows the a+b -> a-b change
    git revert --no-edit <first-bad-sha>
    python3 -c "import calc; print(calc.add(2,1))"   # 3 again
    ```

---

## Cleanup

```bash
cd /tmp && rm -rf /tmp/git-lab
```
