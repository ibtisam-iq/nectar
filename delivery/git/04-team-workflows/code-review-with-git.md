# Code Review with Git

Git has the tools to review a branch without leaving the terminal: read its commits, diff it against the base, run it, and see exactly what changed between two rounds of review. Interviewers ask about `git range-diff` and the fixup flow because they are what make iterating on a pull request fast and honest.

**Track:** Workflow · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Branch commits | `git log <base>..<branch>` | `git log` |
| Net change | `git diff <base>...<branch>` (three-dot, merge base) | `git diff` |
| Per-commit review | `git log -p <base>..<branch>` | `git log -p` |
| Run it | `git switch <branch>`, test, `git switch -` back | `git branch` |
| Between review rounds | `git range-diff <base> <old-tip> <new-tip>` | `git range-diff` |
| range-diff markers | `=` identical, `!` changed, `<`/`>` only one side | the output |
| Respond to a note | `git commit --fixup=<sha>` targeting the reviewed commit | `git log --oneline` |
| Fold fixups | `git rebase -i --autosquash <base>` | `git log` |
| Review a PR branch | `git fetch origin <branch>` then diff and run | `git branch -r` |
<!-- --8<-- [end:facts] -->

---

## Reviewing a Branch Locally

Start by reading what the branch adds: its own commits, then its net change against the base. Use `<base>..<branch>` for the commit list and the three-dot `<base>...<branch>` for the diff, which compares against the merge base so unrelated `main` changes are excluded.

```bash
git log --oneline main..feature/pay
git diff --stat main...feature/pay
```

Output:

```text
36786bc Add refund
a92f3ac Add pay module
 pay.py    | 3 +++
 refund.py | 1 +
 2 files changed, 4 insertions(+)
```

To run the code, switch to the branch and switch back with `git switch -`. A reviewer's local checkout catches what a diff cannot: does it build, do the tests pass, does it behave.

---

## Reading Commit by Commit

A branch is best reviewed one commit at a time when the author kept commits atomic, because each commit is a self-contained change with its own rationale. `git log -p main..feature/pay` shows each commit's message and diff in order.

Reviewing per commit reveals intent that a squashed diff hides: which change is the fix, which is the refactor, which is the test. It is also how you spot a commit that mixes two concerns and should have been split.

!!! tip "Three-dot diff is what the pull request shows"
    `git diff main...feature` matches the "Files changed" tab: the branch's own work against the merge base. `git diff main..feature` (two dots) would also show `main`'s later commits as deletions, which is rarely what a reviewer wants.

---

## What Changed Between Review Rounds

When an author force-pushes a reworked branch, the diff is gone and re-reviewing from scratch is wasteful. `git range-diff` compares two versions of the same branch and shows a diff of the diffs.

```bash
git range-diff --creation-factor=100 main feature/pay-v1 feature/pay
```

Output:

```text
1:  8d6cc11 ! 1:  a92f3ac Add pay module
    @@ Commit message

      ## pay.py (new) ##
     @@
    ++# payments
     +line1
     +line2
2:  76de559 = 2:  36786bc Add refund
```

The markers tell the story: `=` means the commit is unchanged, `!` means it was reworked (here the first commit gained a `# payments` line), and `<`/`>` mark a commit present on only one side. The reviewer re-reads only the `!` commit. `--creation-factor` tunes how aggressively range-diff pairs commits that were heavily rewritten.

---

## Responding to Review with Fixups

When a reviewer flags something in an earlier commit, `git commit --fixup=<sha>` records the change as a `fixup!` commit aimed at that commit, keeping the branch reviewable in the meantime.

```bash
git commit --fixup=a92f3ac
git log --oneline -3
```

Output:

```text
8402842 fixup! Add pay module
36786bc Add refund
a92f3ac Add pay module
```

The reviewer can see each fixup maps to a specific commit. Before merge, `git rebase -i --autosquash main` folds every fixup into its target automatically, leaving clean atomic commits. This is the terminal equivalent of "push review fixes, then tidy before merge".

!!! note "Fixups keep review honest, autosquash keeps history clean"
    Amending the reviewed commit directly would hide the change from the reviewer. A `fixup!` commit is visible during review and disappears into its target at merge time via `--autosquash`, so both the reviewer and the final history get what they need.

---

## Common Errors

### `fatal: bad revision 'main..feature/pay'`

**Cause:** one side of the range is not a valid ref, often an unfetched PR branch or a typo.

**Fix:** `git fetch origin <branch>` first, then use the fetched ref (for example `origin/feature/pay`); confirm names with `git branch -a`.

### `git range-diff` shows two commits as `<` and `>` instead of pairing them

**Cause:** the commit was rewritten enough that range-diff scored it as unrelated, so it lists the old and new separately.

**Fix:** raise the pairing threshold with `--creation-factor=<n>` (up to 100) to force a diff-of-diffs.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do you review a branch's changes from the command line?"
    **Say first:** list its commits with `git log main..branch`, see its net change with the three-dot `git diff main...branch`, and check it out to build and run it.

    **Proof:** `git diff main...branch` matches the pull request's "Files changed" view.

    **Follow-up:** Why the three-dot diff rather than two dots?

??? question "L1: An author force-pushed after your review. How do you see only what they changed?"
    **Say first:** `git range-diff` compares the old and new versions of the branch and shows a diff of the diffs, so you re-read only the commits that changed.

    **Proof:** its output marks each commit `=` (unchanged), `!` (reworked) or `<`/`>` (one side only).

    **Follow-up:** What does the `!` marker mean in range-diff output?
<!-- --8<-- [end:l1] -->

??? question "L2: Review a colleague's pull request branch locally before approving."
    **Say first:** fetch the branch, diff it against the base with three dots, then check it out to run it.

    **Proof:**

    ```bash
    git fetch origin feature/pay
    git diff main...origin/feature/pay
    git switch feature/pay   # run tests, then git switch -
    ```

    **Follow-up:** How would you review the branch one commit at a time instead of as one diff?

??? question "L2: Address a review comment on an earlier commit without hiding the change from the reviewer."
    **Say first:** `git commit --fixup=<sha>` so the fix is a visible `fixup!` commit aimed at the reviewed commit; fold it in with `--autosquash` before merge.

    **Proof:** `git log --oneline` shows `fixup! <subject>`; `git rebase -i --autosquash main` squashes it into its target.

    **Follow-up:** Why not amend the original commit directly instead?

??? question "L3: A reviewer says your rebased branch 'looks completely different' and refuses to re-review it all. How do you help?"
    **Say first:** give them a `git range-diff` between the pre-rebase and post-rebase tips so they see only what actually changed, not the whole branch again.

    **Proof:** `git range-diff main <old-tip> <new-tip>` marks unchanged commits `=` and reworked ones `!`, so re-review is scoped.

    **Follow-up:** Where would the old tip come from if you already force-pushed over it?

??? question "L4: How does git range-diff decide that two commits are the same one, reworked, versus two unrelated commits?"
    **Say first:** it computes a cost of turning one commit's patch into the other's and pairs commits below a threshold (the creation factor), marking a pair `!`; commits too dissimilar are left unpaired as `<` and `>`.

    **Proof:** raising `--creation-factor` pairs commits it otherwise splits, turning a `<`/`>` pair into a single `!` with a diff-of-diffs.

    **Don't say:** "It matches commits by SHA." The SHAs differ after a rebase; it matches by patch similarity.

---

## Related

- [Inspecting History](../01-core-workflow/inspecting-history.md): `git log`, ranges and the three-dot diff
- [Interactive Rebase](../02-branching-and-merging/interactive-rebase.md): autosquash that folds review fixups before merge
- [Commit Conventions](commit-conventions.md): the atomic commits that make per-commit review possible
- [Forks and Pull Requests](../03-remotes-and-collaboration/forks-and-pull-requests.md): fetching a contributor's branch to review

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
