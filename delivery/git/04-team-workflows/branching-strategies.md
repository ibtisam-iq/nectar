# Branching Strategies

A branching strategy defines how long branches live, where releases are cut, and how work reaches production. Interviewers ask about this to hear the trade-offs: trunk-based development optimises for continuous delivery, while gitflow optimises for versioned releases, and choosing wrong creates merge pain or slow shipping.

**Track:** Workflow · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Trunk-based | Short-lived branches, merge to `main` daily | `git log --graph` |
| GitHub flow | Branch, PR, review, merge to `main`, deploy | team practice |
| Gitflow | `main`, `develop`, `feature/*`, `release/*`, `hotfix/*` | `git branch -a` |
| Release branch | Stabilise a version while `main`/`develop` moves on | `git log --graph` |
| Hotfix | Branch from `main`, fix, merge back and forward | `git log --graph` |
| Short-lived vs long | Short branches minimise divergence and conflicts | conflict frequency |
| Squash merge | Collapse a branch to one commit on `main` | `git log --oneline` |
| Feature flags | Ship unfinished work behind a toggle, not a branch | code |
| Protected branch | Server-side rule; `main` takes no direct pushes | the host |
| Fits CD | Trunk-based; gitflow suits scheduled releases | team goal |
<!-- --8<-- [end:facts] -->

---

## What a Strategy Decides

A strategy answers three questions: how long a branch lives, where a release is stabilised, and how an urgent fix reaches production. The rest is naming. The core tension is divergence: the longer a branch lives away from `main`, the larger and riskier its eventual merge.

Two families dominate. Trunk-based and GitHub flow keep one long-lived branch (`main`) and everything else short. Gitflow keeps several long-lived branches for staged releases.

---

## Trunk-Based Development

Every change is a short-lived branch off `main`, merged back within a day or two, often squashed to a single commit. `main` is always releasable, and unfinished work hides behind feature flags rather than living on a branch.

```bash
git switch -c feature/login
# ... commits ...
git switch main
git merge --squash feature/login
git commit -m "feat: add login"
git log --oneline --graph
```

Output:

```text
* 1dabe98 feat: add login
* 3575a08 Initial
```

The squash collapses the branch's work-in-progress commits into one clean commit on `main`. Short branch lifetimes keep conflicts small and make continuous integration real, which is why trunk-based fits continuous delivery.

!!! info "GitHub flow is trunk-based with a pull request gate"
    GitHub flow is the same shape (branch off `main`, merge back) with review and CI enforced through a pull request, and deployment straight from `main`. The difference from bare trunk-based is process (the PR), not branch topology.

---

## Gitflow

Gitflow adds long-lived branches: `develop` accumulates features, `release/*` stabilises a version, `main` holds released code, and `hotfix/*` patches production. Features branch off `develop` and merge back; releases merge to both `main` and `develop`.

```bash
git log --oneline --graph --all
```

Output:

```text
*   930b8ec Merge release back to develop
|\
| | *   8d71b4a Release 1.1
| | |\
| | |/
| |/|
| * | 6488840 Bump to 1.1
|/ /
* / 995cbcf Add feature on develop
|/
* af1cdaa Initial
```

The two merge commits are the cost and the point: a release merges into `main` (tagged) and back into `develop` so the version bump is not lost. Gitflow suits software with supported versions and scheduled releases; it is heavy for a service that deploys continuously.

---

## Hotfixes

Every strategy needs an answer for an urgent production fix, and the rule is the same: branch from the released commit, not from whatever unreleased work `main` has since accumulated. Otherwise the hotfix drags in half-finished features.

```bash
git switch -c hotfix/1.0.1 v1.0.0
# ... fix, commit ...
git tag -a v1.0.1 -m "1.0.1"
git log --oneline --graph --all
```

Output:

```text
* b732ebe fix: patch security hole
| * 2b6d0c9 Start 2.0 work
|/
* 4c6f968 Release 1.0
```

The hotfix sits on the release line (`v1.0.0`), separate from the `Start 2.0 work` commit on `main`. After tagging `v1.0.1`, the fix is merged forward into `main` (and `develop` under gitflow) so the next release keeps it.

Skipping the forward merge is a classic mistake: the bug returns in the next major release because `main` never received the fix. In trunk-based development the same idea applies with a short-lived branch off the release tag.

!!! warning "Branch a hotfix from the release, not from HEAD"
    Branching a production fix from the current `main` ships every unreleased commit along with it. Cut the hotfix from the tag of the version actually running in production, then merge it forward.

---

## Choosing a Strategy

The decision follows the release model, not preference.

| | Trunk-based / GitHub flow | Gitflow |
|---|---|---|
| **Branch lifetime** | Hours to days | Features days, releases weeks |
| **Release model** | Continuous deployment from `main` | Scheduled, versioned releases |
| **Merge overhead** | Low; small frequent merges | Higher; several long-lived branches |
| **Unfinished work** | Feature flags | Lives on `develop`/feature branches |
| **Best for** | Web services, SaaS, CD | Libraries, installed software, multiple supported versions |

Most web teams pick trunk-based or GitHub flow and reach for release branches only when they must support an old version. Gitflow's extra branches earn their keep only when several versions ship in parallel.

!!! warning "Long-lived branches are where merge pain comes from"
    A branch that lives for weeks diverges from `main`, so its merge is large, conflict-prone and hard to review. Keep branches short, rebase or merge from `main` often, and use feature flags to ship incomplete work rather than hoarding it on a branch.

---

## Environment Branches Are an Anti-Pattern

A tempting but poor design is long-lived `dev`, `staging` and `prod` branches that changes are merged between to "promote" a release. It looks orderly and causes steady pain.

The problem is drift: the three branches diverge, cherry-picks between them multiply, and the commit that ran in staging is not the commit that reaches production. The better model promotes one built artifact through environments while the code lives on a single `main`, with tags or deployment records marking what shipped where.

!!! warning "Promote artifacts, not branches, between environments"
    Merging between `dev`, `staging` and `prod` branches means each environment runs a different history, so a bug fixed in one can reappear in another. Build once from `main`, tag it, and deploy that same artifact to each environment.

---

## Common Errors

### `Already up to date.` when you expected a merge to bring changes

**Cause:** the branch was already merged (or its commits already reached the target), so there is nothing new to integrate.

**Fix:** confirm with `git log --oneline --graph --all`; you may be on the wrong branch or the work landed via a squash merge under a different SHA.

### `CONFLICT (content): Merge conflict in <file>` on a long-lived branch merge

**Cause:** the branch diverged from `main` for too long, so both sides changed the same lines.

**Fix:** resolve the conflict, then shorten future branches and merge or rebase from `main` regularly to keep divergence small.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is trunk-based development?"
    **Say first:** everyone integrates into one long-lived branch (`main`) through short-lived branches merged within a day or two, keeping `main` always releasable and hiding unfinished work behind feature flags.

    **Proof:** `git log --graph` on `main` shows a mostly linear history of small, frequent merges.

    **Follow-up:** How does GitHub flow differ from bare trunk-based development?

??? question "L1: When would you choose gitflow over trunk-based?"
    **Say first:** when you ship scheduled, versioned releases or must support several versions at once; the `release/*` and `hotfix/*` branches stabilise and patch versions while development continues.

    **Proof:** gitflow's graph shows `main`, `develop` and release branches; trunk-based keeps one main line.

    **Follow-up:** What is the main cost of gitflow's extra branches?
<!-- --8<-- [end:l1] -->

??? question "L2: Merge a finished feature branch into main as a single clean commit."
    **Say first:** `git merge --squash` the branch, then make one commit with a conventional message.

    **Proof:**

    ```bash
    git switch main
    git merge --squash feature/login
    git commit -m "feat: add login"
    ```

    **Follow-up:** What does a squash merge lose compared with a `--no-ff` merge?

??? question "L2: Ship a half-finished feature without keeping it on a long-lived branch."
    **Say first:** merge it to `main` behind a feature flag that is off in production, and enable the flag when it is ready.

    **Proof:** the code is on `main` (small, frequent merges) but inactive; no long-running branch accrues conflicts.

    **Follow-up:** Why is a feature flag safer than a long-lived feature branch here?

??? question "L3: A team's feature branches routinely take a week and merge with huge conflicts. What do you change?"
    **Say first:** shorten branch lifetimes and integrate more often; break the work into smaller mergeable pieces behind flags, and rebase or merge from `main` daily.

    **Proof:** the conflict size tracks divergence; `git log --graph` shows branches lingering far from `main`, and small frequent merges remove the pain.

    **Follow-up:** How would moving to trunk-based development with CI reinforce this?

??? question "L2: A critical bug is live in v1.4 but main is mid-way through 2.0. Ship the fix without the 2.0 work."
    **Say first:** branch the hotfix from the `v1.4.0` release tag (not from `main`), fix, tag `v1.4.1`, then merge the fix forward into `main`.

    **Proof:**

    ```bash
    git switch -c hotfix/1.4.1 v1.4.0
    # fix, commit, then:
    git tag -a v1.4.1 -m "1.4.1"
    ```

    **Follow-up:** What ships along with the fix if you branch it from `main` instead?

??? question "L3: A team promotes releases by merging between long-lived dev, staging and prod branches and keeps hitting bugs that reappear across environments. What is wrong and what do you propose?"
    **Say first:** environment branches drift apart, so each runs a different history and a fix in one does not reach the others; promote one built artifact through environments instead, off a single `main`.

    **Proof:** `git log --graph` shows the three branches diverging with repeated cherry-picks; building once from `main` and deploying that artifact removes the divergence.

    **Follow-up:** How do tags or deployment records replace what the environment branches were tracking?

??? question "L4: Why does gitflow merge a release branch into both main and develop?"
    **Say first:** `main` records the released, tagged code, while `develop` is the ongoing integration branch; merging the release into both ensures the version bump and any release-only fixes are not lost when development continues.

    **Proof:** the graph shows two merge commits from `release/1.1`, one into `main` (tagged) and one back into `develop`.

    **Don't say:** "It only merges into main." That would strand the release fixes off `develop`.

---

## Related

- [Branches](../02-branching-and-merging/branches.md): the branch mechanics every strategy builds on
- [Merging](../02-branching-and-merging/merging.md): `--no-ff` and `--squash`, the merge shapes strategies choose
- [Release and Versioning](release-and-versioning.md): release branches, tags and semantic versioning
- [Commit Conventions](commit-conventions.md): the message discipline that makes a squashed `main` readable

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
