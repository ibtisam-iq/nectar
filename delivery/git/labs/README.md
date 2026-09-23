# Labs

Hands-on exercises with collapsed solutions. Work through a lab in a throwaway repository, check the result with the verification commands, then open the solution. This folder grows as each module is added.

---

## Environment

Git labs need no server or VM. A scratch directory is enough, and disposable repositories can be thrown away and recreated freely.

```bash
mkdir -p /tmp/git-lab && cd /tmp/git-lab
git init sandbox && cd sandbox
git config user.name "Amina Yusuf"
git config user.email "amina@example.com"
```

The iximiuz Labs playground shell also has Git preinstalled if a browser environment is preferred. Use example identities and generic remotes; never paste a real email, token or private remote URL into a lab.

---

## How the Labs Work

- Each task states a goal, not the commands. Try it first, then open the `Solution` block.
- Verification commands (`git log --oneline --graph`, `git status`) confirm the result before you check the answer.
- Commit messages and file contents are arbitrary; the Git operations are the point.

---

## Lab Index

| Lab | Modules |
|---|---|
| [Core Workflow Lab](core-workflow-lab.md) | 00 Foundations, 01 Core Workflow |
| [Branching and Rebase Lab](branching-and-rebase-lab.md) | 02 Branching and Merging |
| [Recovery and Bisect Lab](recovery-and-bisect-lab.md) | 05 History and Recovery |
