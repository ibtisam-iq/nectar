# Plan: rebuild `delivery/git/` as a complete Git notebook and interview kit

## Context
`technical-grounding/linux/` was rebuilt into a complete notebook and interview kit and merged to `main` (pull requests #19 and #20), passing a full automated audit and an independent review. The same four-layer system now applies to the next tool folder, `delivery/git/`.

The current `delivery/git/` is in the pre-standard state Linux started in: four files (`Git.md`, `gitCheatSheet.md`, `git-submodules.md`, `troubleshooting.md`) with emoji, chatbot residue, a student tone, a mixed Git and GitHub scope, and a cheatsheet carrying a table of contents against the standard. Git is one of the most heavily tested interview topics (merge vs rebase, conflict resolution, undoing changes, reflog recovery, internals), so it earns the same depth Linux got. The goal is one folder that serves four uses: learning Git in depth, revising before an interview, practising interview rounds, and day-to-day lookup.

## Confirmed decisions
- **Scope: Git the tool only.** Cover Git in depth and link out to `delivery/github/` for pull requests, CODEOWNERS and branch protection, and to `delivery/github-actions/` for CI. No duplication of platform features that already live in those folders.
- **Track taxonomy: Core / Workflow / Advanced.** Replaces Linux's `Core / RHCSA / Advanced`. `Workflow` is the middle track for team collaboration conventions. Weights stay `High / Med / Low`.
- **Pilot: `02-branching-and-merging`.** The highest interview-weight module and the best test of the format.
- **Rebuild from scratch.** The four existing files become source input only: moved to a git-ignored `_sources/`, rebuilt to the standard, originals removed.

## Research and sources
Full detail in `research.md`. The tree was mapped against the official reference and real interview banks:
- **Coverage vs Pro Git.** Every in-scope chapter of the Pro Git book (git-scm.com) maps to a module. Chapters 4 (servers), 6 (GitHub) and 9 (other VCS) are the deliberate out-of-scope set. The mapping surfaced one gap now fixed: revision selection folded into `inspecting-history.md`.
- **Interview coverage.** Cross-checked against the KodeKloud 2026 set, the NotHarshhaa DevOps interview repository, InterviewBit and senior-edition compilations.
- **Answer format is grounded.** `Say first` is BLUF (Bottom Line Up Front). `Proof` is the evidence step. `Follow-up` (kept, with a short parenthetical pointer answer, consistent with Linux) anticipates the next probe and chains L1 to L4.

## Reuse (no new infrastructure)
- **Standards** in `plan/standards/` apply unchanged. The blueprint is tool-agnostic; git's Track values (`Core / Workflow / Advanced`) are recorded in `decisions.md` without editing the shared standard.
- **Scripts** are manifest-driven and reused: `lint-prose.py`, `audit-tool.py`, `gen-checklist.py`. `gen-checklist.py` gained three tool-agnostic generalizations (Phase 1 remove filter, optional resume-cleanup row, skip empty batches, optional coverage-map row), each defaulting to Linux's existing behaviour so the Linux checklist stays byte-identical.
- **Lesson already applied:** `_sources/INVENTORY.md` is force-tracked (`git add -f`) from Phase 1 so the completion audit (check 9) is reproducible on a fresh checkout.

## Tabs and capture
- **Platform tabs: minimal.** Most pages use no tabs. Where behaviour differs (line endings and `core.autocrlf`, credential helpers, SSH vs HTTPS), use exactly `=== "macOS / Linux"` and `=== "Windows"`.
- **Capture: throwaway local git repos.** Real output from disposable sandbox repos, fully reproducible. Scrub real emails, remote URLs and tokens; use example identities. Every `text` block follows the `Output:` rule with a capture footer.
- **No `coverage-map.md`.** Git has no certification to map objectives against. `_sources/INVENTORY.md` and `research.md` carry the completeness proof.

## Target structure
`(I)` marks internals topics that feed `round-4-internals.md`. Arrows mean "links to an existing folder rather than duplicating it".

```
delivery/git/
├── README.md          # four layers, module map, study paths, out-of-scope list
├── roadmap.md         # checkbox tracker for every topic, scenario and lab
│
├── 00-foundations/                         (batch A)
│   ├── what-is-git.md            : Core, Med  : DVCS vs centralized, snapshots not diffs, why Git
│   ├── install-and-config.md     : Core, Med  : config levels, identity, editor, aliases, includeIf
│   └── the-three-trees.md        : Core, High : working tree / index / HEAD, the core mental model
│
├── 01-core-workflow/                       (batch A)
│   ├── staging-and-committing.md : Core, High : add / add -p, status, commit, amend
│   ├── inspecting-history.md     : Core, High : log, show, diff, blame, revision selection (HEAD~/^, A..B vs A...B)
│   ├── ignoring-and-attributes.md: Core, Med  : .gitignore rules, .gitattributes, line endings (tabs)
│   └── undoing-changes.md        : Core, High : restore, reset --soft/mixed/hard, revert, clean (decision table)
│
├── 02-branching-and-merging/               (PILOT)
│   ├── branches.md               : Core, High : create/switch, HEAD, tracking, detached HEAD
│   ├── merging.md                : Core, High : fast-forward vs 3-way, --no-ff, merge commits
│   ├── rebasing.md               : Core, High : rebase vs merge, the golden rule, --onto
│   ├── interactive-rebase.md     : Advanced, High : squash/fixup/reword/reorder, autosquash
│   ├── conflict-resolution.md    : Core, High : conflict anatomy, tools, rerere, abort
│   └── cherry-pick.md            : Core, Med  : ranges, -x, backporting
│
├── 03-remotes-and-collaboration/           (batch B)
│   ├── remotes.md                : Core, High : remote add, fetch vs pull, tracking, prune
│   ├── pushing-and-pulling.md    : Core, High : upstream, pull --rebase, force vs force-with-lease
│   ├── tags-and-releases.md      : Core, Med  : lightweight vs annotated, signing, describe
│   ├── stashing.md               : Core, Med  : push/pop/apply, untracked, stash to branch
│   └── forks-and-pull-requests.md: Workflow, Med : fork model, sync a fork, PR flow -> ../../github/
│
├── 04-team-workflows/                      (batch C)
│   ├── branching-strategies.md   : Workflow, High : trunk-based vs GitHub flow vs gitflow, trade-offs
│   ├── commit-conventions.md     : Workflow, High : conventional/atomic commits, messages, sign-off
│   ├── code-review-with-git.md   : Workflow, Med  : range-diff, review locally, fixup flow
│   └── release-and-versioning.md : Workflow, Med  : semver, release branches, changelogs, tagging
│
├── 05-history-and-recovery/                (batch D)
│   ├── reflog-and-recovery.md    : Core, High : reflog, recover lost commits/branches, ORIG_HEAD
│   ├── bisect.md                 : Advanced, Med : bisect run, automated regression hunting
│   ├── rewriting-history.md      : Advanced, High : amend/reset/rebase -i, golden rule, force-with-lease
│   └── filter-repo-and-secrets.md: Advanced, Med : filter-repo, remove a secret, rotate, BFG note
│
├── 06-internals/                           (batch D)
│   ├── object-model.md       (I) : Advanced, High : blob/tree/commit/tag, SHA addressing, cat-file/hash-object
│   ├── refs-and-head.md      (I) : Advanced, High : refs, HEAD, packed-refs, symbolic refs, the DAG
│   ├── how-merge-and-rebase-work.md (I) : Advanced, High : merge base, 3-way, patch replay
│   └── packfiles-and-gc.md   (I) : Advanced, Low : loose vs packed, gc, delta compression, fsck
│
├── 07-advanced-tooling/                    (batch E)
│   ├── hooks.md                  : Advanced, Med : client/server hooks, pre-commit framework, CI link
│   ├── submodules.md             : Advanced, Med : absorbs git-submodules.md; add/update/deinit, pitfalls
│   ├── worktrees.md              : Advanced, Low : linked worktrees, parallel branches
│   ├── large-repos.md            : Advanced, Med : shallow/partial clone, sparse-checkout, LFS, maintenance
│   └── credentials-and-signing.md: Core, Med : credential helpers (tabs), SSH vs HTTPS, GPG/SSH signing
│
├── reference/                              # REVISE layer
│   ├── cheatsheet.md             # absorbs gitCheatSheet.md; by task, no collapsibles
│   ├── command-index.md          # A-Z porcelain plus key plumbing to topic file
│   ├── config-reference.md       # important git config keys: purpose, level, default
│   ├── dotfiles-reference.md     # .gitignore / .gitattributes / .gitconfig / .gitmodules formats
│   ├── glossary.md               # ref, HEAD, index, upstream, fast-forward, detached HEAD
│   ├── must-know-facts.md        # aggregator of every topic's facts snippet (grows per batch)
│   └── error-messages.md         # absorbs troubleshooting.md; real git error to cause to fix (grows)
│
├── interview/                             # INTERVIEW layer
│   ├── README.md
│   ├── round-1-screening.md      # L1 aggregator (grows per batch)
│   ├── round-2-hands-on.md       # L2 tasks plus output-reading drills
│   ├── round-3-troubleshooting.md# L3 scenario index (grows per batch)
│   ├── round-4-internals.md      # L4 bank (grows per batch)
│   ├── scenarios/                # 10 scenarios (symptom to fix to prevention)
│   └── mock-interviews.md        # 3 timed mocks mixing L1-L4
│
└── labs/                                 # PRACTICE layer
    ├── README.md                 # environment: a throwaway local repo; sandbox setup
    ├── core-workflow-lab.md
    ├── branching-and-rebase-lab.md
    ├── recovery-and-bisect-lab.md
    ├── internals-by-hand-lab.md  # plumbing: hash-object, write-tree, commit-tree
    └── history-surgery-lab.md    # filter-repo remove a secret; rewrite a branch safely

    (plus _sources/  : git-ignored raw material; INVENTORY.md force-tracked)
```

**Size:** 8 module folders, about 40 topic files, 10 scenarios, 5 labs, 7 reference pages, 5 interview pages (about 75 files).

**Out of scope** (mapped to Pro Git chapters): running Git servers and protocols (ch4); GitHub platform features such as PRs, CODEOWNERS and branch protection (ch6, owned by `delivery/github/`); Git as a client to other VCS and migrations (ch9); CI/CD (`delivery/github-actions/`); GitOps (`delivery/argocd/`). Niche plumbing (`git bundle`, `git replace`) gets at most a one-line mention.

## Phases (each waits for owner review before the next)
- **Phase 0 (plan logged):** create `plan/git/` (`plan.md`, `manifest.yml`, `decisions.md`, `research.md`, generated `checklist.md`), add a Git row to `plan/README.md`, generate the checklist. Commit locally.
- **Phase 1 (housekeeping):** move the four legacy files into `delivery/git/_sources/`, force-track `_sources/INVENTORY.md`, write the inventory, `git rm` the originals, repoint the `delivery/index.md` Git card (currently `git/Git.md`) to `git/README.md`, fix `delivery/git/.pages`. Confirm `_sources/` is git-ignored and excluded from the site (already global).
- **Phase 2 (pilot, then stop for sign-off):** build `02-branching-and-merging/` (README plus 6 topics), seed `reference/must-know-facts.md` and `interview/round-1-screening.md`, one scenario (`merge-conflict-resolution.md`), and the module-02 part of `labs/branching-and-rebase-lab.md`. Pass lint and `audit-tool.py --scope P --build`. Owner reviews and signs off.
- **Phase 3 (module batches, one commit each):** A (00, 01), B (03), C (04), D (05, 06), E (07). Each batch adds its scenarios and lab sections, updates the aggregators and `roadmap.md`, passes lint and `audit-tool.py --scope <batch>`, and ticks its boxes.
- **Phase 4 (interview layer):** `round-2-hands-on.md` with output drills, complete rounds 3 and 4, the remaining scenarios, and `mock-interviews.md`.
- **Phase 5 (reference and labs):** the five remaining reference pages, `internals-by-hand-lab.md` and `history-surgery-lab.md`; resolve every `_sources/INVENTORY.md` item.
- **Phase 6 (completion audit):** `audit-tool.py --full` (0 failures), `lychee`, a served rendering pass, an independent fresh-agent review with findings fixed, `plan/git/audit-report.md`, mark Git complete in `plan/README.md`, hand off for the owner's pull request and sign-off.

## Interview and quality rules (from the standard)
- Every topic: H1 plus at most two opening sentences plus the `**Track:** ... · **Interview weight:** ...` line, a `## Must-Know Facts` table in snippet markers, `## Interview Checkpoints` (6 to 12, L1 inside markers, High has at least one L3, each `(I)` file has at least one L4 linked from round 4), `## Related`, and a capture footer where output exists.
- Trivia becomes a facts row, not a question. Interview pages span topics and link back, never copying topic questions.
- Real captured output only, `Output:` before each `text` block, trims marked `# ... (trimmed)`.
- No em or en dashes, no banned vocabulary, paragraphs of three sentences at most, declarative third person in topics, imperative only in labs.

## Critical files
- New: `plan/git/{plan.md, manifest.yml, decisions.md, research.md, checklist.md}`, later `audit-report.md`.
- Edited: `plan/README.md` (Git row), `delivery/index.md` (Git card link), `delivery/git/.pages`, `scripts/gen-checklist.py` (tool-agnostic generalizations).
- Removed in Phase 1: `delivery/git/{Git.md, gitCheatSheet.md, git-submodules.md, troubleshooting.md}`.
- Built: `delivery/git/**`.
- Reused unchanged: `scripts/{lint-prose,audit-tool}.py`, `plan/standards/*`.

## Verification (each phase)
- `python scripts/lint-prose.py delivery/git` exits 0.
- `python scripts/audit-tool.py --manifest plan/git/manifest.yml --scope <batch> --build` exits 0.
- `mkdocs build` prints no warnings for `delivery/git`; `site/.../git/_sources` is absent.
- Rendering checked in the browser: module order, revision cards, `???` collapsing, snippet pages, tabs where present, phone width, dark mode.
- Final: `audit-tool.py --full` exits 0, `lychee` on the build, the independent review, `audit-report.md`, then the owner's pull request and sign-off.
