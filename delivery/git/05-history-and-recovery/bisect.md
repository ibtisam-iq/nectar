# Bisect

`git bisect` binary-searches history for the commit that introduced a regression, testing a midpoint each step so a thousand commits take about ten checks. Interviewers ask about it because `git bisect run` automates that search with a test script, which is the fastest way to pin a "it worked last week" bug to one commit.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Purpose | Find the first commit that introduced a regression | `git bisect` |
| Method | Binary search: about `log2(n)` tests for n commits | the step counts |
| Start | `git bisect start <bad> <good>` | Git checks out a midpoint |
| Mark manually | `git bisect good` / `git bisect bad` per checkout | the next midpoint |
| Automate | `git bisect run <cmd>` (exit 0 good, 1-124 bad) | the result |
| Skip untestable | `git bisect skip` (build broken at that commit) | the next midpoint |
| Result | `<sha> is the first bad commit` | the output |
| Finish | `git bisect reset` returns to where you started | `git status` |
| Exit 125 | Reserved: tells `run` the commit is untestable (skip) | the script |
<!-- --8<-- [end:facts] -->

---

## What Bisect Does

Bisect finds the boundary between "working" and "broken" by binary search. You give it one known-bad commit and one known-good ancestor; it checks out the midpoint, you (or a script) judge it, and it halves the range until one commit remains.

The efficiency is the point: each answer discards half the suspects, so the number of tests is logarithmic. A regression somewhere in 1000 commits is found in about 10 checkouts.

---

## A Manual Bisect

`git bisect start <bad> <good>` begins the search and checks out the first midpoint. At each stop you build or run the code and mark it `git bisect good` or `git bisect bad`.

```bash
git bisect start HEAD 5951cc9
```

Output:

```text
Bisecting: 3 revisions left to test after this (roughly 2 steps)
[d97f50dd956dc504435424733f8957cdd10de745] Note 3
```

The "roughly 2 steps" is the remaining binary-search depth. You test the checked-out commit, mark it, and Git jumps to the next midpoint, narrowing until it names the first bad commit.

!!! warning "The good commit really must be good"
    Bisect assumes everything up to the good commit works and the bug appears somewhere before the bad one. If the "good" commit is actually broken, or the bug is intermittent, bisect converges on the wrong commit. Verify the endpoints before starting.

---

## Automating with bisect run

When a single command can decide good from bad, `git bisect run` does the whole search unattended. The command exits `0` for a good commit and `1` to `124` for a bad one; Git checks out each midpoint, runs it, and marks it automatically.

```bash
git bisect start HEAD 5951cc9
git bisect run ./test.sh
```

Output:

```text
running './test.sh'
Bisecting: 1 revision left to test after this (roughly 1 step)
[0df960df5f63e90ef86093e395b534296d035ef6] Note 4
running './test.sh'
Bisecting: 0 revisions left to test after this (roughly 0 steps)
[d6295d70a4e9138fbf47eb741e9024803c221ac5] Refactor calc
running './test.sh'
d6295d70a4e9138fbf47eb741e9024803c221ac5 is the first bad commit
commit d6295d70a4e9138fbf47eb741e9024803c221ac5
    Refactor calc
```

Git found the culprit (`Refactor calc`) in two checkouts. The test script is any command that reproduces the bug: a unit test, a build, or a one-line check. This turns a vague regression into a named commit and diff to read.

!!! tip "Exit 125 tells bisect run a commit is untestable"
    If a commit cannot be built or tested (a broken intermediate state), have the script exit `125`, and `git bisect run` skips it like a manual `git bisect skip`. Reserve `125`; exit codes `1` to `124` all mean "bad".

---

## Finishing Up

Bisect leaves you on the checked-out commit with a temporary state. `git bisect reset` ends the search and returns to the branch you started on.

```bash
git bisect reset
```

Output:

```text
Previous HEAD position was d6295d7 Refactor calc
```

With the first bad commit known, `git show <sha>` reads its diff, and the fix or revert targets exactly that change.

---

## Common Errors

### `You need to start by "git bisect start"`

**Cause:** a `git bisect good`/`bad`/`run` was issued before a bisect session was started.

**Fix:** run `git bisect start <bad> <good>` first; then mark or run.

### `git bisect run` reports every commit bad, even old ones

**Cause:** the test script fails for a reason unrelated to the bug (a missing dependency, a wrong path), so it returns non-zero everywhere.

**Fix:** run the script by hand on a known-good commit first; make it exit `0` there before bisecting.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What problem does git bisect solve, and how?"
    **Say first:** it finds the commit that introduced a regression by binary search: you mark one bad and one good commit, and it tests midpoints, halving the range each step until one commit remains.

    **Proof:** `git bisect start <bad> <good>` then marking each checkout narrows to "the first bad commit" in about `log2(n)` steps.

    **Follow-up:** How do you automate the marking instead of doing it by hand?

??? question "L1: How many tests does bisect need for a thousand commits, and why?"
    **Say first:** about ten, because each test halves the remaining suspect range, so the count is `log2(n)` rather than `n`.

    **Proof:** the "roughly N steps" line drops by one per answer; 1000 is under 2^10.

    **Follow-up:** What makes bisect land on the wrong commit despite the maths?
<!-- --8<-- [end:l1] -->

??? question "L2: Automate a bisect to find which commit broke a test."
    **Say first:** `git bisect run` with a script that exits 0 when good and non-zero when bad.

    **Proof:**

    ```bash
    git bisect start HEAD <good-sha>
    git bisect run ./test.sh
    git bisect reset
    ```

    **Follow-up:** What exit code tells `run` that a commit is untestable?

??? question "L2: A commit in the range does not build, so it cannot be tested. What do you do?"
    **Say first:** `git bisect skip` it (or exit `125` from the run script), and Git chooses a nearby commit instead.

    **Proof:** the search continues around the skipped commit; if too many are skipped, Git may report a range rather than a single commit.

    **Follow-up:** Why is `125` the reserved code rather than `1`?

??? question "L3: A bug appears intermittently and 'it worked last release'. How do you find the commit responsible?"
    **Say first:** write the smallest reliable reproduction as a script, then `git bisect run` it between the last good release tag and the current bad commit.

    **Proof:** `git bisect start HEAD <last-good-tag>` then `git bisect run ./repro.sh` names the first bad commit; flakiness is handled by making the repro deterministic first.

    **Follow-up:** What would a flaky (non-deterministic) test do to the bisect result?

??? question "L4: How does git bisect choose which commit to test, and why is it logarithmic?"
    **Say first:** it picks the commit that most evenly splits the remaining suspect range (roughly the midpoint of the reachable set), so each result eliminates about half; halving repeatedly gives `log2(n)` tests.

    **Proof:** the "roughly N steps" line is the remaining search depth, dropping by one each answer.

    **Don't say:** "It walks commits one by one from the bad end." That would be linear, not logarithmic.

---

## Related

- [Inspecting History](../01-core-workflow/inspecting-history.md): reading the bad commit's diff with `git show`
- [Undoing Changes](../01-core-workflow/undoing-changes.md): reverting the commit bisect identifies
- [Reflog and Recovery](reflog-and-recovery.md): recovering if a bisect session leaves you somewhere unexpected
- [Recovery and Bisect Lab](../labs/recovery-and-bisect-lab.md): practising an automated bisect

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
