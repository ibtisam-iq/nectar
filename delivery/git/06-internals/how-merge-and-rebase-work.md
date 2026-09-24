# How Merge and Rebase Work

A merge finds the common ancestor of two branches and builds one commit with two parents; a rebase replays a branch's commits as new commits on a new base. Interviewers ask about the mechanism because it explains why merge preserves the graph, why rebase changes SHAs, and what the merge base has to do with either.

**Track:** Advanced · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Merge base | The common ancestor of two commits | `git merge-base A B` |
| Three-way merge | Combines base, ours and theirs into one tree | `git merge` |
| Merge commit | Has two (or more) parents | `git cat-file -p <merge>` |
| ort strategy | The default merge algorithm since Git 2.34 | `git merge -s ort` |
| Fast-forward | No merge commit; the ref moves up | `git log --graph` |
| Rebase | Replays each commit as a patch onto a new base | `git rebase <base>` |
| Rebase result | New SHAs, one parent each, linear history | `git log --oneline` |
| Rebase conflict | Per-commit, resolved then `--continue` | `git status` |
| Why SHAs change | New parent (and time) means a new commit hash | `git log` |
| Merge preserves DAG | Rebase rewrites it into a line | `git log --graph` |
<!-- --8<-- [end:facts] -->

---

## The Merge Base

Merging or rebasing two lines of work starts from their merge base: the most recent commit reachable from both tips. `git merge-base` finds it.

```bash
git merge-base main topic
git log --oneline -1 $(git merge-base main topic)
```

Output:

```text
db149aebfbae58b9d33f7aeafdb0c26e994cd5da
db149ae Base
```

`Base` is where the two branches diverged. Everything after it on each side is that side's own work, and the merge base is the reference point both merge and rebase measure changes against.

---

## Three-Way Merge

A three-way merge takes three inputs: the merge base, the current branch's tip (ours) and the other tip (theirs). It combines the changes each side made relative to the base into one tree, then records a commit with both tips as parents.

```bash
git merge --no-edit topic
git cat-file -p HEAD | head -3
```

Output:

```text
tree f50a88db0fc051142e6148c0ba4e57087b5eaf94
parent f0cde7889111204b49e99bd312e647c573ef148c
parent d39913819fcc86d1f69207382acecc9301a6d727
```

The two `parent` lines are what make it a merge commit: it ties both histories together, so the graph records that the branches met here.

```bash
git log --oneline -1 --pretty='%h parents: %p'
```

Output:

```text
0a7a60b parents: f0cde78 d399138
```

Because a merge adds a commit rather than rewriting any, existing commits keep their SHAs. This is why merging is safe on shared branches: nothing already pushed changes.

!!! info "The ort strategy is the three-way merge engine"
    Git's default strategy since 2.34 is `ort` (Ostensibly Recursive's Twin). It computes each side's diff against the merge base and applies both, handling renames and, for criss-cross histories, building a virtual merge base from multiple common ancestors. A clean merge is where the two diffs do not overlap; an overlap is a conflict.

---

## How Rebase Works

Rebase does not merge. It takes each commit unique to your branch, computes it as a patch (its diff against its own parent), and reapplies those patches one by one onto the new base, creating a new commit for each.

```bash
git log --oneline -2   # before
git rebase main
git log --oneline -4   # after
```

Output:

```text
8b3578f Topic 2
03fd7c8 Topic 1
37e09dd Topic 2
0a3ce7e Topic 1
ed13670 Main 1
db149ae Base
```

`Topic 1` and `Topic 2` have new SHAs (`03fd7c8` became `0a3ce7e`, and so on), because each was recreated on top of `Main 1` with a new parent. The history is now linear.

```bash
git log --pretty='%h parents: %p' -3
```

Output:

```text
37e09dd parents: 0a3ce7e
0a3ce7e parents: ed13670
ed13670 parents: db149ae
```

Each replayed commit has exactly one parent, and there is no merge commit. A conflict during a rebase is per-commit: Git stops on the patch that does not apply, you resolve it, and `git rebase --continue` resumes with the next patch.

!!! info "A fast-forward is neither a merge nor a rebase"
    When your branch has no commits the other lacks, `git merge` only moves the ref forward to the other tip: no merge commit, no new objects, because there is nothing to combine. `--no-ff` forces a merge commit anyway to record that a branch existed.

---

## Merge Versus Rebase at the Object Level

Both integrate `topic` with `main`, but they build different objects. A merge adds one new commit (two parents) and leaves every other commit untouched, preserving the branching shape in the DAG. A rebase creates new commits for each replayed change (one parent each) and abandons the originals, producing a straight line.

That single structural difference explains the trade-offs: merge keeps true history and shared-branch safety at the cost of a busier graph; rebase gives a clean linear history at the cost of new SHAs, which is why it must not touch shared commits.

---

## Common Errors

### `fatal: refusing to merge unrelated histories`

**Cause:** the two branches share no merge base (for example, two repositories initialised separately), so a three-way merge has no common ancestor.

**Fix:** if the merge is intended, pass `--allow-unrelated-histories`; otherwise you are on the wrong branch or remote.

### `CONFLICT (content)` reappears commit after commit during a rebase

**Cause:** rebase replays each commit in turn, so a change that conflicts with the new base can conflict again in several of the replayed commits.

**Fix:** resolve and `git rebase --continue` each time; enable `rerere` so a repeated resolution is replayed automatically.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a merge base, and why does merging need it?"
    **Say first:** the merge base is the most recent common ancestor of the two branches; a three-way merge compares each side's changes against it to combine them.

    **Proof:** `git merge-base A B` prints it; the merge applies both sides' diffs relative to that commit.

    **Follow-up:** How many parents does the resulting merge commit have?

??? question "L1: Why does rebasing change commit SHAs when merging does not?"
    **Say first:** rebase recreates each commit on a new parent, and a commit's SHA hashes its parent, so every replayed commit gets a new id; merge only adds a commit and rewrites none.

    **Proof:** after a rebase `git log` shows new SHAs; after a merge the original commits keep theirs and a two-parent merge commit appears.

    **Follow-up:** What does that difference mean for shared branches?
<!-- --8<-- [end:l1] -->

??? question "L2: Show that a merge commit has two parents and a rebased commit has one."
    **Say first:** print the parent lists with a pretty format.

    **Proof:**

    ```bash
    git log --pretty='%h parents: %p' -1   # merge: two parents
    git log --pretty='%h parents: %p' -1   # rebased tip: one parent
    ```

    **Follow-up:** Which of the two preserves the original branching shape in the graph?

??? question "L2: Find the common ancestor two branches will merge from."
    **Say first:** `git merge-base A B` prints the most recent commit reachable from both, the base a three-way merge diffs against.

    **Proof:**

    ```bash
    git merge-base main topic
    ```

    **Follow-up:** What does `git merge-base --all` return that the plain form does not?

??? question "L3: A rebase keeps stopping with the same conflict on several commits in a row. Why, and what helps?"
    **Say first:** rebase replays commits one at a time, so a change that clashes with the new base clashes again in each commit that touches those lines; resolving repeatedly is expected.

    **Proof:** `git status` shows the paused rebase per commit; enabling `rerere` records the first resolution and replays it on the recurring conflict.

    **Follow-up:** Would a merge have hit the conflict once instead of many times?

??? question "L4: What does the ort strategy actually compute during a three-way merge?"
    **Say first:** it diffs each side against the merge base and applies both diffs to the base tree; non-overlapping changes combine cleanly, overlapping ones become conflicts, and for criss-cross histories it builds a virtual merge base by merging multiple common ancestors first.

    **Proof:** `git merge-base --all A B` can show several ancestors that ort recursively merges into one virtual base before the final three-way merge.

    **Don't say:** "It compares the two tips directly." It compares each tip to the base, not to each other.

---

## Related

- [Merging](../02-branching-and-merging/merging.md): merge from the user's side, `--no-ff` and conflicts
- [Rebasing](../02-branching-and-merging/rebasing.md): rebase from the user's side and the golden rule
- [Object Model](object-model.md): the commit objects and parents these operations create
- [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md): resolving the overlaps this describes

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
