# Git Checklist

Generated from `manifest.yml` by `scripts/gen-checklist.py`. Tick items in the same commit as the work. Regenerate after any manifest change; ticked items are preserved by id.

---

## Phase 0: Plan Logged in Repository

- [x] `plan/README.md` <!-- id:p0:plan-readme -->
- [x] `plan/standards/` (writing standard, blueprint, definition of done) <!-- id:p0:standards -->
- [x] `plan/git/` (plan, manifest, decisions, research, checklist) <!-- id:p0:plan-files -->
- [x] `scripts/gen-checklist.py` <!-- id:p0:gen-checklist -->
- [x] `plan/` listed in `exclude_docs` <!-- id:p0:exclude-plan -->
- [x] `CLAUDE.md` points to `plan/` <!-- id:p0:pointer:CLAUDE.md -->
- [x] `GEMINI.md` points to `plan/` <!-- id:p0:pointer:GEMINI.md -->
- [x] `AGENTS.md` points to `plan/` <!-- id:p0:pointer:AGENTS.md -->
- [ ] Phase 0 on `main` (owner pushes and merges) <!-- id:p0:merged -->

---

## Phase 1: Housekeeping

- [x] Raw course material moved to `delivery/git/_sources/` <!-- id:p1:sources-moved -->
- [x] `_sources/` in `.gitignore` <!-- id:p1:gitignore:_sources/ -->
- [x] `_sources/` in `exclude_docs` <!-- id:p1:exclude:_sources/ -->
- [x] Remove `delivery/git/Git.md` <!-- id:remove:Git.md -->
- [x] Remove `delivery/git/gitCheatSheet.md` <!-- id:remove:gitCheatSheet.md -->
- [x] Remove `delivery/git/git-submodules.md` <!-- id:remove:git-submodules.md -->
- [x] Remove `delivery/git/troubleshooting.md` <!-- id:remove:troubleshooting.md -->
- [x] Inbound links fixed in `delivery/index.md` <!-- id:p1:links:delivery/index.md -->
- [x] Local virtual environment synced with `requirements.txt` <!-- id:p1:venv -->
- [x] `_sources/INVENTORY.md` written <!-- id:p1:inventory -->

---

## Phase 2: Pilot

- [x] `templates/topic.md` <!-- id:repo:templates/topic.md -->
- [x] `templates/module-readme.md` <!-- id:repo:templates/module-readme.md -->
- [x] `templates/scenario.md` <!-- id:repo:templates/scenario.md -->
- [x] `scripts/lint-prose.py` <!-- id:repo:scripts/lint-prose.py -->
- [x] `scripts/audit-tool.py` <!-- id:repo:scripts/audit-tool.py -->
- [x] Tool folder `.pages` <!-- id:delivery/git/.pages -->
- [x] `reference/.pages` <!-- id:delivery/git/reference/.pages -->
- [x] `interview/.pages` <!-- id:delivery/git/interview/.pages -->
- [x] `interview/scenarios/.pages` <!-- id:delivery/git/interview/scenarios/.pages -->
- [x] `labs/.pages` <!-- id:delivery/git/labs/.pages -->
- [x] `02-branching-and-merging/.pages` <!-- id:delivery/git/02-branching-and-merging/.pages -->
- [x] `02-branching-and-merging/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/02-branching-and-merging/README.md -->
- [x] `02-branching-and-merging/branches.md` (Core, High) <!-- id:delivery/git/02-branching-and-merging/branches.md -->
- [x] `02-branching-and-merging/merging.md` (Core, High) <!-- id:delivery/git/02-branching-and-merging/merging.md -->
- [x] `02-branching-and-merging/rebasing.md` (Core, High) <!-- id:delivery/git/02-branching-and-merging/rebasing.md -->
- [x] `02-branching-and-merging/interactive-rebase.md` (Advanced, High) <!-- id:delivery/git/02-branching-and-merging/interactive-rebase.md -->
- [x] `02-branching-and-merging/conflict-resolution.md` (Core, High) <!-- id:delivery/git/02-branching-and-merging/conflict-resolution.md -->
- [x] `02-branching-and-merging/cherry-pick.md` (Core, Med) <!-- id:delivery/git/02-branching-and-merging/cherry-pick.md -->
- [x] `reference/must-know-facts.md` <!-- id:delivery/git/reference/must-know-facts.md -->
- [x] `labs/README.md` <!-- id:delivery/git/labs/README.md -->
- [x] `labs/branching-and-rebase-lab.md` <!-- id:delivery/git/labs/branching-and-rebase-lab.md -->
- [x] `interview/README.md` <!-- id:delivery/git/interview/README.md -->
- [x] `interview/round-1-screening.md` <!-- id:delivery/git/interview/round-1-screening.md -->
- [x] `interview/round-3-troubleshooting.md` <!-- id:delivery/git/interview/round-3-troubleshooting.md -->
- [x] `interview/round-4-internals.md` <!-- id:delivery/git/interview/round-4-internals.md -->
- [x] `interview/scenarios/merge-conflict-resolution.md` (modules 02) <!-- id:delivery/git/interview/scenarios/merge-conflict-resolution.md -->
- [x] `README.md` <!-- id:delivery/git/README.md -->
- [x] `roadmap.md` <!-- id:delivery/git/roadmap.md -->
- [x] Pilot: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:P:grows -->
- [x] Pilot: `scripts/lint-prose.py` exits 0 <!-- id:check:P:lint -->
- [x] Pilot: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:P:audit -->
- [x] Pilot: `mkdocs build` has no warnings for the tool folder <!-- id:check:P:build -->
- [ ] Pilot: owner review done; first-hand line spots listed <!-- id:check:P:owner -->
- [ ] Owner sign-off on the pilot <!-- id:p2:signoff -->
- [x] `CLAUDE.md` has the Notes Conventions section <!-- id:p2:conventions -->

---

## Phase 3: Batch A (modules 00, 01)

- [ ] `00-foundations/.pages` <!-- id:delivery/git/00-foundations/.pages -->
- [ ] `00-foundations/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/00-foundations/README.md -->
- [ ] `00-foundations/what-is-git.md` (Core, Med) <!-- id:delivery/git/00-foundations/what-is-git.md -->
- [ ] `00-foundations/install-and-config.md` (Core, Med) <!-- id:delivery/git/00-foundations/install-and-config.md -->
- [ ] `00-foundations/the-three-trees.md` (Core, High) <!-- id:delivery/git/00-foundations/the-three-trees.md -->
- [ ] `01-core-workflow/.pages` <!-- id:delivery/git/01-core-workflow/.pages -->
- [ ] `01-core-workflow/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/01-core-workflow/README.md -->
- [ ] `01-core-workflow/staging-and-committing.md` (Core, High) <!-- id:delivery/git/01-core-workflow/staging-and-committing.md -->
- [ ] `01-core-workflow/inspecting-history.md` (Core, High) <!-- id:delivery/git/01-core-workflow/inspecting-history.md -->
- [ ] `01-core-workflow/ignoring-and-attributes.md` (Core, Med) <!-- id:delivery/git/01-core-workflow/ignoring-and-attributes.md -->
- [ ] `01-core-workflow/undoing-changes.md` (Core, High) <!-- id:delivery/git/01-core-workflow/undoing-changes.md -->
- [ ] `reference/error-messages.md` <!-- id:delivery/git/reference/error-messages.md -->
- [ ] `labs/core-workflow-lab.md` <!-- id:delivery/git/labs/core-workflow-lab.md -->
- [ ] `interview/scenarios/accidental-commit-to-main.md` (modules 01, 02) <!-- id:delivery/git/interview/scenarios/accidental-commit-to-main.md -->
- [ ] `interview/scenarios/wrong-branch-commits.md` (modules 01, 02) <!-- id:delivery/git/interview/scenarios/wrong-branch-commits.md -->
- [ ] Batch A: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:A:grows -->
- [ ] Batch A: `scripts/lint-prose.py` exits 0 <!-- id:check:A:lint -->
- [ ] Batch A: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:A:audit -->
- [ ] Batch A: `mkdocs build` has no warnings for the tool folder <!-- id:check:A:build -->
- [ ] Batch A: owner review done; first-hand line spots listed <!-- id:check:A:owner -->

---

## Phase 3: Batch B (modules 03)

- [ ] `03-remotes-and-collaboration/.pages` <!-- id:delivery/git/03-remotes-and-collaboration/.pages -->
- [ ] `03-remotes-and-collaboration/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/03-remotes-and-collaboration/README.md -->
- [ ] `03-remotes-and-collaboration/remotes.md` (Core, High) <!-- id:delivery/git/03-remotes-and-collaboration/remotes.md -->
- [ ] `03-remotes-and-collaboration/pushing-and-pulling.md` (Core, High) <!-- id:delivery/git/03-remotes-and-collaboration/pushing-and-pulling.md -->
- [ ] `03-remotes-and-collaboration/tags-and-releases.md` (Core, Med) <!-- id:delivery/git/03-remotes-and-collaboration/tags-and-releases.md -->
- [ ] `03-remotes-and-collaboration/stashing.md` (Core, Med) <!-- id:delivery/git/03-remotes-and-collaboration/stashing.md -->
- [ ] `03-remotes-and-collaboration/forks-and-pull-requests.md` (Workflow, Med) <!-- id:delivery/git/03-remotes-and-collaboration/forks-and-pull-requests.md -->
- [ ] `interview/scenarios/diverged-branches-push-rejected.md` (modules 03) <!-- id:delivery/git/interview/scenarios/diverged-branches-push-rejected.md -->
- [ ] `interview/scenarios/detached-head.md` (modules 02) <!-- id:delivery/git/interview/scenarios/detached-head.md -->
- [ ] Batch B: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:B:grows -->
- [ ] Batch B: `scripts/lint-prose.py` exits 0 <!-- id:check:B:lint -->
- [ ] Batch B: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:B:audit -->
- [ ] Batch B: `mkdocs build` has no warnings for the tool folder <!-- id:check:B:build -->
- [ ] Batch B: owner review done; first-hand line spots listed <!-- id:check:B:owner -->

---

## Phase 3: Batch C (modules 04)

- [ ] `04-team-workflows/.pages` <!-- id:delivery/git/04-team-workflows/.pages -->
- [ ] `04-team-workflows/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/04-team-workflows/README.md -->
- [ ] `04-team-workflows/branching-strategies.md` (Workflow, High) <!-- id:delivery/git/04-team-workflows/branching-strategies.md -->
- [ ] `04-team-workflows/commit-conventions.md` (Workflow, High) <!-- id:delivery/git/04-team-workflows/commit-conventions.md -->
- [ ] `04-team-workflows/code-review-with-git.md` (Workflow, Med) <!-- id:delivery/git/04-team-workflows/code-review-with-git.md -->
- [ ] `04-team-workflows/release-and-versioning.md` (Workflow, Med) <!-- id:delivery/git/04-team-workflows/release-and-versioning.md -->
- [ ] Complete `labs/branching-and-rebase-lab.md` <!-- id:delivery/git/labs/branching-and-rebase-lab.md:complete -->
- [ ] `interview/scenarios/messy-history-before-pr.md` (modules 02, 04) <!-- id:delivery/git/interview/scenarios/messy-history-before-pr.md -->
- [ ] Batch C: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:C:grows -->
- [ ] Batch C: `scripts/lint-prose.py` exits 0 <!-- id:check:C:lint -->
- [ ] Batch C: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:C:audit -->
- [ ] Batch C: `mkdocs build` has no warnings for the tool folder <!-- id:check:C:build -->
- [ ] Batch C: owner review done; first-hand line spots listed <!-- id:check:C:owner -->

---

## Phase 3: Batch D (modules 05, 06)

- [ ] `05-history-and-recovery/.pages` <!-- id:delivery/git/05-history-and-recovery/.pages -->
- [ ] `05-history-and-recovery/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/05-history-and-recovery/README.md -->
- [ ] `05-history-and-recovery/reflog-and-recovery.md` (Core, High) <!-- id:delivery/git/05-history-and-recovery/reflog-and-recovery.md -->
- [ ] `05-history-and-recovery/bisect.md` (Advanced, Med) <!-- id:delivery/git/05-history-and-recovery/bisect.md -->
- [ ] `05-history-and-recovery/rewriting-history.md` (Advanced, High) <!-- id:delivery/git/05-history-and-recovery/rewriting-history.md -->
- [ ] `05-history-and-recovery/filter-repo-and-secrets.md` (Advanced, Med) <!-- id:delivery/git/05-history-and-recovery/filter-repo-and-secrets.md -->
- [ ] `06-internals/.pages` <!-- id:delivery/git/06-internals/.pages -->
- [ ] `06-internals/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/06-internals/README.md -->
- [ ] `06-internals/object-model.md` (Advanced, High, internals) <!-- id:delivery/git/06-internals/object-model.md -->
- [ ] `06-internals/refs-and-head.md` (Advanced, High, internals) <!-- id:delivery/git/06-internals/refs-and-head.md -->
- [ ] `06-internals/how-merge-and-rebase-work.md` (Advanced, High, internals) <!-- id:delivery/git/06-internals/how-merge-and-rebase-work.md -->
- [ ] `06-internals/packfiles-and-gc.md` (Advanced, Low, internals) <!-- id:delivery/git/06-internals/packfiles-and-gc.md -->
- [ ] `labs/recovery-and-bisect-lab.md` <!-- id:delivery/git/labs/recovery-and-bisect-lab.md -->
- [ ] `interview/scenarios/lost-commits-after-reset.md` (modules 05) <!-- id:delivery/git/interview/scenarios/lost-commits-after-reset.md -->
- [ ] `interview/scenarios/committed-a-secret.md` (modules 05) <!-- id:delivery/git/interview/scenarios/committed-a-secret.md -->
- [ ] `interview/scenarios/force-push-clobbered-teammate.md` (modules 03, 05) <!-- id:delivery/git/interview/scenarios/force-push-clobbered-teammate.md -->
- [ ] Batch D: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:D:grows -->
- [ ] Batch D: `scripts/lint-prose.py` exits 0 <!-- id:check:D:lint -->
- [ ] Batch D: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:D:audit -->
- [ ] Batch D: `mkdocs build` has no warnings for the tool folder <!-- id:check:D:build -->
- [ ] Batch D: owner review done; first-hand line spots listed <!-- id:check:D:owner -->

---

## Phase 3: Batch E (modules 07)

- [ ] `07-advanced-tooling/.pages` <!-- id:delivery/git/07-advanced-tooling/.pages -->
- [ ] `07-advanced-tooling/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/07-advanced-tooling/README.md -->
- [ ] `07-advanced-tooling/hooks.md` (Advanced, Med) <!-- id:delivery/git/07-advanced-tooling/hooks.md -->
- [ ] `07-advanced-tooling/submodules.md` (Advanced, Med) <!-- id:delivery/git/07-advanced-tooling/submodules.md -->
- [ ] `07-advanced-tooling/worktrees.md` (Advanced, Low) <!-- id:delivery/git/07-advanced-tooling/worktrees.md -->
- [ ] `07-advanced-tooling/large-repos.md` (Advanced, Med) <!-- id:delivery/git/07-advanced-tooling/large-repos.md -->
- [ ] `07-advanced-tooling/credentials-and-signing.md` (Core, Med) <!-- id:delivery/git/07-advanced-tooling/credentials-and-signing.md -->
- [ ] `interview/scenarios/bloated-repo-large-file.md` (modules 07) <!-- id:delivery/git/interview/scenarios/bloated-repo-large-file.md -->
- [ ] Batch E: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:E:grows -->
- [ ] Batch E: `scripts/lint-prose.py` exits 0 <!-- id:check:E:lint -->
- [ ] Batch E: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:E:audit -->
- [ ] Batch E: `mkdocs build` has no warnings for the tool folder <!-- id:check:E:build -->
- [ ] Batch E: owner review done; first-hand line spots listed <!-- id:check:E:owner -->

---

## Phase 4: Interview Layer

- [ ] `interview/round-2-hands-on.md` <!-- id:delivery/git/interview/round-2-hands-on.md -->
- [ ] `interview/mock-interviews.md` <!-- id:delivery/git/interview/mock-interviews.md -->
- [ ] Output-reading drills in `round-2-hands-on.md` <!-- id:p4:output-drills -->
- [ ] Phase 4: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:4:grows -->
- [ ] Phase 4: `scripts/lint-prose.py` exits 0 <!-- id:check:4:lint -->
- [ ] Phase 4: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:4:audit -->
- [ ] Phase 4: `mkdocs build` has no warnings for the tool folder <!-- id:check:4:build -->
- [ ] Phase 4: owner review done; first-hand line spots listed <!-- id:check:4:owner -->

---

## Phase 5: Reference and Labs

- [ ] `reference/cheatsheet.md` <!-- id:delivery/git/reference/cheatsheet.md -->
- [ ] `reference/command-index.md` <!-- id:delivery/git/reference/command-index.md -->
- [ ] `reference/config-reference.md` <!-- id:delivery/git/reference/config-reference.md -->
- [ ] `reference/dotfiles-reference.md` <!-- id:delivery/git/reference/dotfiles-reference.md -->
- [ ] `reference/glossary.md` <!-- id:delivery/git/reference/glossary.md -->
- [ ] `labs/internals-by-hand-lab.md` <!-- id:delivery/git/labs/internals-by-hand-lab.md -->
- [ ] `labs/history-surgery-lab.md` <!-- id:delivery/git/labs/history-surgery-lab.md -->
- [ ] Every `INVENTORY.md` item resolved <!-- id:p5:inventory-resolved -->
- [ ] Phase 5: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:5:grows -->
- [ ] Phase 5: `scripts/lint-prose.py` exits 0 <!-- id:check:5:lint -->
- [ ] Phase 5: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:5:audit -->
- [ ] Phase 5: `mkdocs build` has no warnings for the tool folder <!-- id:check:5:build -->
- [ ] Phase 5: owner review done; first-hand line spots listed <!-- id:check:5:owner -->

---

## Phase 6: Completion Audit

- [ ] `scripts/audit-tool.py --manifest plan/git/manifest.yml --full` exits 0 <!-- id:p6:audit-full -->
- [ ] `lychee` on the final build <!-- id:p6:lychee -->
- [ ] Rendering checked (order, cards, tabs, checkpoints, snippets, phone width, dark mode) <!-- id:p6:render -->
- [ ] Independent review by a fresh agent; findings fixed <!-- id:p6:independent-review -->
- [ ] `plan/git/audit-report.md` written <!-- id:p6:audit-report -->
- [ ] `plan/README.md` marks the tool complete <!-- id:p6:status -->
- [ ] Work committed locally and handed to the owner (owner pushes and opens the pull request) <!-- id:p6:pr -->
- [ ] Owner final sign-off <!-- id:p6:owner-signoff -->
