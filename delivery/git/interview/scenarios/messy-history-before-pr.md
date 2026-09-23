# Messy History Before a PR

A feature branch has a string of "wip", "more", "fix typo", "fix again" commits, and it needs to be a clean, reviewable history before the pull request. Interviewers use this because the fix is an interactive rebase, and the candidate must first check the commits are unshared so rewriting them is safe.

---

## Symptom

> "My branch works, but the history is a mess: wip, more cart, fix typo, fix again. I want to open a PR with clean commits. Nothing is pushed yet."

---

## Clarifying Questions

- **Is any of this pushed or shared?** Rewriting is only safe for commits nobody else has; `git log @{u}..HEAD` (or `main..HEAD` with no upstream) shows what is local.
- **Should this be one commit or several?** A single logical change squashes to one; two distinct changes should become two atomic commits.
- **Does each intended commit build and pass on its own?** Atomic commits should, so `git bisect` and `git revert` stay useful.
- **Will the PR be squash-merged anyway?** If the platform squashes on merge, local tidy still helps review, but the final `main` commit is one regardless.

---

## Diagnostic Path

### 1. See the Mess and Confirm It Is Local

```bash
git log --oneline main..feature/cart
```

Output:

```text
1dfb975 fix again
f9d9e8e fix typo
7bfd4ca more cart
2583978 wip cart
```

Four noisy commits, none of which is a meaningful unit. Before rewriting, confirm they are unshared so the golden rule is not broken.

```bash
git log --oneline main..HEAD | wc -l
```

Output:

```text
4
```

With no upstream set, `main..HEAD` is the local-only range. If an upstream existed, `git log @{u}..HEAD` would show only the unpushed commits, and only those may be rewritten.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Work-in-progress commits never tidied | `wip`, `fix typo`, `fix again` in the log | Interactive rebase: squash and reword |
| One logical change split across commits | Commits that do not stand alone | Squash into one atomic commit |
| Two changes tangled together | Unrelated files in each commit | Rebase and re-split with `edit` plus `add -p` |
| Some commits already pushed | `git log @{u}..HEAD` is shorter than the mess | Rewrite only the unpushed range |

---

## Fix

An interactive rebase over the local range folds the noise into one commit and rewords it to a conventional message.

```bash
git rebase -i main
# in the todo: keep the first as 'pick', mark the rest 'fixup'
git commit --amend -m "feat(cart): add cart with tests"
git log --oneline main..feature/cart
```

Output:

```text
053dc06 feat(cart): add cart with tests
```

The four commits are now one clean, conventionally-typed commit. Critically, the branch's net change is identical; only the history was reshaped.

```bash
git diff --stat main...feature/cart
```

Output:

```text
 cart.py      | 3 +++
 cart_test.py | 1 +
 2 files changed, 4 insertions(+)
```

If the work were genuinely two changes (say the feature and its tests), mark one commit `edit` in the todo and use `git add -p` to re-split it into two atomic commits instead of one. After rewriting, a push of an already-pushed branch needs `--force-with-lease`.

!!! danger "Only rewrite commits that are still yours alone"
    Interactive rebase gives every replayed commit a new SHA. Run it only on the unpushed range (`git log @{u}..HEAD`); rewriting commits teammates have pulled forces a divergent history and a painful reconcile for everyone.

!!! tip "Autosquash tidies as you go"
    If you commit review or self-review fixes as `git commit --fixup=<sha>` while working, `git rebase -i --autosquash main` places and folds them automatically, so the final tidy is one command with no manual todo editing.

---

## Prevention

- Commit fixes as `git commit --fixup=<target>` during work, then `rebase -i --autosquash` before the PR.
- Keep branches short so there is little history to clean up.
- Write conventional messages from the start, so only squashing (not rewording) is needed at the end.
- If the platform squash-merges, still tidy locally for a readable review, but do not over-invest since `main` gets one commit anyway.

---

## Related

- [Interactive Rebase](../../02-branching-and-merging/interactive-rebase.md): squash, fixup, reword and autosquash in detail
- [Commit Conventions](../../04-team-workflows/commit-conventions.md): the atomic, typed commits this produces
- [Code Review with Git](../../04-team-workflows/code-review-with-git.md): the fixup flow and `range-diff` during review
- [Rebasing](../../02-branching-and-merging/rebasing.md): the golden rule that gates this rewrite

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
