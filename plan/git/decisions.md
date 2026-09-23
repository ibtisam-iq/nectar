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
