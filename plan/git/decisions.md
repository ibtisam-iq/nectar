# Git Plan Decisions

Dated decision log for the `delivery/git/` rebuild. A change made during execution updates `plan.md` and `manifest.yml` and adds an entry here in the same commit.

---

## 2026-09-19: Phase 0 (plan logged)

| # | Decision | Reason |
|---|---|---|
| G1 | Scope is Git the tool only. Pull requests, CODEOWNERS and branch protection stay in `delivery/github/`; CI in `delivery/github-actions/`; GitOps in `delivery/argocd/`. Git pages link out rather than duplicate | Those folders already own the platform features; the current `Git.md` mixed Git and GitHub, which this rebuild separates |
| G2 | Track taxonomy is `Core / Workflow / Advanced`, git's instance of the shared three-track system. `Workflow` is the middle track for team collaboration conventions (branching strategy, commit conventions, code review, releases), replacing Linux's `RHCSA` | Git has no certification, so the cert-flavoured middle track does not apply; recorded here so the shared blueprint is not edited |
| G3 | Pilot module is `02-branching-and-merging` (README plus 6 topics), with `merge-conflict-resolution.md` as its scenario and the module-02 part of `branching-and-rebase-lab.md` | Merge vs rebase, interactive rebase and conflict resolution are the highest interview-weight git topics and the best stress test of the format |
| G4 | Rebuild from scratch. `Git.md`, `gitCheatSheet.md`, `git-submodules.md` and `troubleshooting.md` become source input in a git-ignored `_sources/`, are rebuilt to the standard, and the originals are removed in Phase 1 | The existing files carry emoji, chatbot residue, a student tone and a mixed scope; they are input, not a style reference |
| G5 | Platform tabs are minimal: `=== "macOS / Linux"` and `=== "Windows"`, used only where behaviour differs (line endings and `core.autocrlf`, credential helpers, SSH vs HTTPS). Most pages use no tabs | Git commands are cross-platform, so tabs would be noise everywhere except a few genuine differences |
| G6 | No `reference/coverage-map.md`. Git has no certification objectives to map. `_sources/INVENTORY.md` and `research.md` carry the completeness proof, mapped against the Pro Git chapters | The coverage-map exists to prove certification coverage, which does not apply to git |
| G7 | `scripts/gen-checklist.py` was generalized in four tool-agnostic ways: the Phase 1 remove rows now cover any legacy file not absorbed by a module; the resume-cleanup row is gated on `housekeeping.resume_cleanup` (default true); empty Phase 3 batches are skipped; the coverage-map row is emitted only when a `coverage-map.md` reference page exists. Each defaults to Linux's existing behaviour, and the Linux checklist regenerates byte-identical | Git uses batches P and A to E only, has no resume or coverage-map, and needed the removal rows for its own legacy files; the changes make the generator reusable for every future tool without touching Linux |
| G8 | Capture environment is throwaway local git repositories (a scratch directory, or the iximiuz playground shell). Real emails, remote URLs and tokens are scrubbed; example identities are used | Git output is fully reproducible from disposable repos and needs no VM; scrubbing keeps real credentials and addresses out of the notes |

---

## 2026-09-20: Phase 1 and Phase 2 (pilot)

| # | Decision | Reason |
|---|---|---|
| G9 | The stray `delivery/git/.gitattributes` (a corporate sample with LFS filters) was moved to `_sources/gitattributes-sample` and removed from the folder | No other tool folder carries a bespoke `.gitattributes`, and the LFS filters could misfire on files committed under `delivery/git/`; the sample is recorded in the inventory and feeds `reference/dotfiles-reference.md` |
| G10 | Capture identity is `Amina Yusuf <amina@example.com>` with a fixed commit clock, run under an isolated `GIT_CONFIG_GLOBAL` so the owner's real config never leaks; commit SHAs and dates in the notes are therefore stable and reproducible | Deterministic captures keep the pages honest (real git output) while avoiding real credentials and churn on re-capture |
| G11 | Pilot signed off by the owner on 2026-09-20. Module 02 passed `lint-prose` and `audit-tool --scope P --build` with zero failures; the format (Say first, Proof, Follow-up), real captured output and the four-layer structure are confirmed for the remaining batches | The pilot is the format stress test; sign-off unblocks Phase 3 (batches A to E) |

---

## 2026-09-23: Phase 3 Batch A (modules 00, 01)

| # | Decision | Reason |
|---|---|---|
| G12 | Batch-A pages link only to files that already exist (modules 00, 01, 02, the built reference and interview pages). Forward references to unbuilt modules (03 to 07, `config-reference`, `dotfiles-reference`, `reflog-and-recovery`, `object-model` and so on) are written as plain prose naming the target module, not as `.md` links | Same rule the pilot followed: the audit (checks 12 and 16) fails on any link to a missing file, so cross-links are added back when the target batch lands, keeping every intermediate state build-clean |
| G13 | `reference/error-messages.md` was created in batch A and grows per batch (it absorbs the empty legacy `troubleshooting.md`). It is a how-to page: exact error string heading, then Cause and Fix, grouped by area | The manifest marks it `batch: A, grows: true`; starting it now gives every topic a real place to point its Common Errors readers, and it is populated only with errors actually captured or reproduced |
| G14 | Line-ending guidance in `ignoring-and-attributes.md` and the install step use the two platform tabs `=== "macOS / Linux"` and `=== "Windows"` (per G5), the only batch-A places where behaviour genuinely differs | Everywhere else git commands are cross-platform, so tabs would be noise; `core.autocrlf` and the install command are the real differences |

---

## 2026-09-24: Phase 3 Batch B (module 03)

| # | Decision | Reason |
|---|---|---|
| G15 | `scripts/audit-tool.py` `TRACK_RE` was generalized from the hardcoded `(Core\|RHCSA\|Advanced)` to `([A-Z][A-Za-z]+)` for the track name; the weight stays `(High\|Med\|Low)` and the value is still validated against the manifest (the existing check at the match site). This is the audit counterpart of the G7 checklist generalization | `forks-and-pull-requests.md` is the first `Workflow`-track topic (per G2), which the Linux-flavoured regex rejected. Reading the track from the manifest keeps the script tool-agnostic; Linux's full audit still passes with zero failures, so no page changed |
| G16 | Batch B adds two scenarios: `diverged-branches-push-rejected` (feeds 03) and `detached-head` (feeds 02). Each is linked from the README of a module it draws on (03 and 02 respectively), which the audit (check 5) requires | The manifest schedules both in batch B; `detached-head` feeds module 02, so 02's README, already merged, gains the link now that the scenario exists |

---

## 2026-09-24: Phase 3 Batch C (module 04)

| # | Decision | Reason |
|---|---|---|
| G17 | `labs/branching-and-rebase-lab.md` (started in the pilot, marked `completed_in: C`) is finished in batch C with a "Preparing for Review" section (squash a messy branch, autosquash a fixup), tying the lab to module 04's team-workflow topics | The manifest schedules the lab's completion for batch C once module 04 exists to justify the review-prep framing; the module-02 mechanics were the pilot part |
| G18 | The `messy-history-before-pr` scenario feeds modules 02 and 04 and is linked from module 04's README (check 5). Module 04's Workflow topics are more conceptual than the Core modules, so their captures are smaller and some High topics land just under the 250-line guide (a non-failing note) | The topics are genuinely shorter (strategy and versioning are decision-and-table heavy); padding to the guide would add filler, so the pages carry real content plus real captures and accept the note |

---

## 2026-09-24: Phase 3 Batch D (modules 05, 06)

| # | Decision | Reason |
|---|---|---|
| G19 | `filter-repo-and-secrets.md`, `object-model.md`'s plumbing section, and the `committed-a-secret` scenario use real `git filter-repo` output. `git-filter-repo` is a separate tool (present on the capture machine); the capture footer names it, and the topic states it is not built into Git | The plan lists filter-repo as the recommended purge tool over the deprecated `filter-branch`; captures must be real, so the tool was used and its non-core status is called out for the reader |
| G20 | Module 06 is the internals module: every topic sets `internals: true`, carries at least one L4 checkpoint, and is linked from `round-4-internals.md` (audit check 4/5). `packfiles-and-gc.md` (Low) was written tersely to stay within the 150-line Low budget while still meeting the 6-checkpoint and 2-admonition minimums | The manifest marks these internals and the audit enforces the L4-from-round-4 link; the Low budget is a hard upper bound, so the packfiles page trades prose for the required checkpoints |
| G21 | Several High internals and history topics land in the 210 to 245 range, under the 250-line guide (non-failing notes), same trade-off as G18 | Internals topics are dense and reference-heavy; the pages carry real plumbing captures and full checkpoint sets rather than filler to reach an exact line count |

---

## 2026-09-24: Phase 3 Batch E (module 07)

| # | Decision | Reason |
|---|---|---|
| G22 | Module 07 completes the module set. `submodules.md` absorbs the legacy `git-submodules.md` (INVENTORY already targeted it there), rebuilt to the standard with scrubbed example remotes (`../lib.git`, `vendor/lib`) and real captured `submodule add`/`update --remote` output. `credentials-and-signing.md` uses the two platform tabs (per G5) for credential helpers only, and shows real SSH commit signing plus the `allowedSignersFile` verification step | The manifest schedules 07 for batch E and marks submodules as the absorber of the legacy file; SSH signing needs no GPG key and captures cleanly, so it is the worked example, with GPG/x509 named as alternatives |
| G23 | Git LFS is described in prose in `large-repos.md` and `bloated-repo-large-file.md` without an `Output:` capture, because `git-lfs` is not installed on the capture machine. Shallow and partial clones are captured against a local `file://` remote with `uploadpack.allowFilter` enabled, so `--depth` and `--filter` behave as they do over a network (a plain local clone ignores both) | The standard forbids fabricated output; LFS is a separate extension and is presented conceptually, consistent with how `git-filter-repo` is footnoted (G19). The `file://` and `allowFilter` setup makes the shallow/partial captures real rather than warning-and-fallback |
| G24 | `worktrees.md` (Low) was tightened to the 150-line budget by inlining single-command checkpoint proofs and dropping the redundant Common Errors section (its one error is shown in the body). It keeps 6 checkpoints (2 L1, 4 L2) and 2 admonitions | Same terse-Low trade-off as `packfiles-and-gc.md` (G20): the Low upper bound is a hard fail, so prose is trimmed while the required checkpoint and admonition minimums are met |

---

## 2026-09-24: Phase 4 (interview layer)

| # | Decision | Reason |
|---|---|---|
| G25 | Phase 4 built `round-2-hands-on.md` (timed tasks as worked `??? tip` solutions grouped by area, plus seven output-reading drills from real captures: conflicted `status`, conflict markers, diverged `status -sb`, a rejected push, `log --graph --all`, `reflog` after a hard reset, detached-HEAD `status`) and `mock-interviews.md` (three 45-minute mocks: junior screen, recovery-and-collaboration, senior internals), each question linking to a built topic or scenario | The plan schedules both for phase 4; all ten scenarios and rounds 1/3/4 were already complete through batch E, so no scenarios remained and round-3/round-4 needed no growth. Round 2's drills mirror the merged Linux round-2 output-reading format with git states instead of host telemetry |
| G26 | No `coverage-map.md` was updated for the `check:4:grows` item (it references one generically); git has no coverage-map per G6, and the interview nav (`interview/.pages`, `interview/README.md`) and `roadmap.md` were updated instead | The checklist row is generic across tools; git satisfies it through the interview nav and roadmap, consistent with G6 dropping the coverage-map for a tool with no certification objectives |
