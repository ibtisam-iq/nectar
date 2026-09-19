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
