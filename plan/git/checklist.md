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
- [x] Pilot: owner review done; first-hand line spots listed <!-- id:check:P:owner -->
- [x] Owner sign-off on the pilot <!-- id:p2:signoff -->
- [x] `CLAUDE.md` has the Notes Conventions section <!-- id:p2:conventions -->

---

## Phase 3: Batch A (modules 00, 01)

- [x] `00-foundations/.pages` <!-- id:delivery/git/00-foundations/.pages -->
- [x] `00-foundations/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/00-foundations/README.md -->
- [x] `00-foundations/what-is-git.md` (Core, Med) <!-- id:delivery/git/00-foundations/what-is-git.md -->
- [x] `00-foundations/install-and-config.md` (Core, Med) <!-- id:delivery/git/00-foundations/install-and-config.md -->
- [x] `00-foundations/the-three-trees.md` (Core, High) <!-- id:delivery/git/00-foundations/the-three-trees.md -->
- [x] `01-core-workflow/.pages` <!-- id:delivery/git/01-core-workflow/.pages -->
- [x] `01-core-workflow/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/01-core-workflow/README.md -->
- [x] `01-core-workflow/staging-and-committing.md` (Core, High) <!-- id:delivery/git/01-core-workflow/staging-and-committing.md -->
- [x] `01-core-workflow/inspecting-history.md` (Core, High) <!-- id:delivery/git/01-core-workflow/inspecting-history.md -->
- [x] `01-core-workflow/ignoring-and-attributes.md` (Core, Med) <!-- id:delivery/git/01-core-workflow/ignoring-and-attributes.md -->
- [x] `01-core-workflow/undoing-changes.md` (Core, High) <!-- id:delivery/git/01-core-workflow/undoing-changes.md -->
- [x] `reference/error-messages.md` <!-- id:delivery/git/reference/error-messages.md -->
- [x] `labs/core-workflow-lab.md` <!-- id:delivery/git/labs/core-workflow-lab.md -->
- [x] `interview/scenarios/accidental-commit-to-main.md` (modules 01, 02) <!-- id:delivery/git/interview/scenarios/accidental-commit-to-main.md -->
- [x] `interview/scenarios/wrong-branch-commits.md` (modules 01, 02) <!-- id:delivery/git/interview/scenarios/wrong-branch-commits.md -->
- [x] Batch A: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:A:grows -->
- [x] Batch A: `scripts/lint-prose.py` exits 0 <!-- id:check:A:lint -->
- [x] Batch A: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:A:audit -->
- [x] Batch A: `mkdocs build` has no warnings for the tool folder <!-- id:check:A:build -->
- [ ] Batch A: owner review done; first-hand line spots listed <!-- id:check:A:owner -->

---

## Phase 3: Batch B (modules 03)

- [x] `03-remotes-and-collaboration/.pages` <!-- id:delivery/git/03-remotes-and-collaboration/.pages -->
- [x] `03-remotes-and-collaboration/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/03-remotes-and-collaboration/README.md -->
- [x] `03-remotes-and-collaboration/remotes.md` (Core, High) <!-- id:delivery/git/03-remotes-and-collaboration/remotes.md -->
- [x] `03-remotes-and-collaboration/pushing-and-pulling.md` (Core, High) <!-- id:delivery/git/03-remotes-and-collaboration/pushing-and-pulling.md -->
- [x] `03-remotes-and-collaboration/tags-and-releases.md` (Core, Med) <!-- id:delivery/git/03-remotes-and-collaboration/tags-and-releases.md -->
- [x] `03-remotes-and-collaboration/stashing.md` (Core, Med) <!-- id:delivery/git/03-remotes-and-collaboration/stashing.md -->
- [x] `03-remotes-and-collaboration/forks-and-pull-requests.md` (Workflow, Med) <!-- id:delivery/git/03-remotes-and-collaboration/forks-and-pull-requests.md -->
- [x] `interview/scenarios/diverged-branches-push-rejected.md` (modules 03) <!-- id:delivery/git/interview/scenarios/diverged-branches-push-rejected.md -->
- [x] `interview/scenarios/detached-head.md` (modules 02) <!-- id:delivery/git/interview/scenarios/detached-head.md -->
- [x] Batch B: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:B:grows -->
- [x] Batch B: `scripts/lint-prose.py` exits 0 <!-- id:check:B:lint -->
- [x] Batch B: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:B:audit -->
- [x] Batch B: `mkdocs build` has no warnings for the tool folder <!-- id:check:B:build -->
- [ ] Batch B: owner review done; first-hand line spots listed <!-- id:check:B:owner -->

---

## Phase 3: Batch C (modules 04)

- [x] `04-team-workflows/.pages` <!-- id:delivery/git/04-team-workflows/.pages -->
- [x] `04-team-workflows/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/04-team-workflows/README.md -->
- [x] `04-team-workflows/branching-strategies.md` (Workflow, High) <!-- id:delivery/git/04-team-workflows/branching-strategies.md -->
- [x] `04-team-workflows/commit-conventions.md` (Workflow, High) <!-- id:delivery/git/04-team-workflows/commit-conventions.md -->
- [x] `04-team-workflows/code-review-with-git.md` (Workflow, Med) <!-- id:delivery/git/04-team-workflows/code-review-with-git.md -->
- [x] `04-team-workflows/release-and-versioning.md` (Workflow, Med) <!-- id:delivery/git/04-team-workflows/release-and-versioning.md -->
- [x] Complete `labs/branching-and-rebase-lab.md` <!-- id:delivery/git/labs/branching-and-rebase-lab.md:complete -->
- [x] `interview/scenarios/messy-history-before-pr.md` (modules 02, 04) <!-- id:delivery/git/interview/scenarios/messy-history-before-pr.md -->
- [x] Batch C: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:C:grows -->
- [x] Batch C: `scripts/lint-prose.py` exits 0 <!-- id:check:C:lint -->
- [x] Batch C: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:C:audit -->
- [x] Batch C: `mkdocs build` has no warnings for the tool folder <!-- id:check:C:build -->
- [ ] Batch C: owner review done; first-hand line spots listed <!-- id:check:C:owner -->

---

## Phase 3: Batch D (modules 05, 06)

- [x] `05-history-and-recovery/.pages` <!-- id:delivery/git/05-history-and-recovery/.pages -->
- [x] `05-history-and-recovery/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/05-history-and-recovery/README.md -->
- [x] `05-history-and-recovery/reflog-and-recovery.md` (Core, High) <!-- id:delivery/git/05-history-and-recovery/reflog-and-recovery.md -->
- [x] `05-history-and-recovery/bisect.md` (Advanced, Med) <!-- id:delivery/git/05-history-and-recovery/bisect.md -->
- [x] `05-history-and-recovery/rewriting-history.md` (Advanced, High) <!-- id:delivery/git/05-history-and-recovery/rewriting-history.md -->
- [x] `05-history-and-recovery/filter-repo-and-secrets.md` (Advanced, Med) <!-- id:delivery/git/05-history-and-recovery/filter-repo-and-secrets.md -->
- [x] `06-internals/.pages` <!-- id:delivery/git/06-internals/.pages -->
- [x] `06-internals/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/06-internals/README.md -->
- [x] `06-internals/object-model.md` (Advanced, High, internals) <!-- id:delivery/git/06-internals/object-model.md -->
- [x] `06-internals/refs-and-head.md` (Advanced, High, internals) <!-- id:delivery/git/06-internals/refs-and-head.md -->
- [x] `06-internals/how-merge-and-rebase-work.md` (Advanced, High, internals) <!-- id:delivery/git/06-internals/how-merge-and-rebase-work.md -->
- [x] `06-internals/packfiles-and-gc.md` (Advanced, Low, internals) <!-- id:delivery/git/06-internals/packfiles-and-gc.md -->
- [x] `labs/recovery-and-bisect-lab.md` <!-- id:delivery/git/labs/recovery-and-bisect-lab.md -->
- [x] `interview/scenarios/lost-commits-after-reset.md` (modules 05) <!-- id:delivery/git/interview/scenarios/lost-commits-after-reset.md -->
- [x] `interview/scenarios/committed-a-secret.md` (modules 05) <!-- id:delivery/git/interview/scenarios/committed-a-secret.md -->
- [x] `interview/scenarios/force-push-clobbered-teammate.md` (modules 03, 05) <!-- id:delivery/git/interview/scenarios/force-push-clobbered-teammate.md -->
- [x] Batch D: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:D:grows -->
- [x] Batch D: `scripts/lint-prose.py` exits 0 <!-- id:check:D:lint -->
- [x] Batch D: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:D:audit -->
- [x] Batch D: `mkdocs build` has no warnings for the tool folder <!-- id:check:D:build -->
- [ ] Batch D: owner review done; first-hand line spots listed <!-- id:check:D:owner -->

---

## Phase 3: Batch E (modules 07)

- [x] `07-advanced-tooling/.pages` <!-- id:delivery/git/07-advanced-tooling/.pages -->
- [x] `07-advanced-tooling/README.md` (Revision Card, Topic Map) <!-- id:delivery/git/07-advanced-tooling/README.md -->
- [x] `07-advanced-tooling/hooks.md` (Advanced, Med) <!-- id:delivery/git/07-advanced-tooling/hooks.md -->
- [x] `07-advanced-tooling/submodules.md` (Advanced, Med) <!-- id:delivery/git/07-advanced-tooling/submodules.md -->
- [x] `07-advanced-tooling/worktrees.md` (Advanced, Low) <!-- id:delivery/git/07-advanced-tooling/worktrees.md -->
- [x] `07-advanced-tooling/large-repos.md` (Advanced, Med) <!-- id:delivery/git/07-advanced-tooling/large-repos.md -->
- [x] `07-advanced-tooling/credentials-and-signing.md` (Core, Med) <!-- id:delivery/git/07-advanced-tooling/credentials-and-signing.md -->
- [x] `interview/scenarios/bloated-repo-large-file.md` (modules 07) <!-- id:delivery/git/interview/scenarios/bloated-repo-large-file.md -->
- [x] Batch E: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:E:grows -->
- [x] Batch E: `scripts/lint-prose.py` exits 0 <!-- id:check:E:lint -->
- [x] Batch E: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:E:audit -->
- [x] Batch E: `mkdocs build` has no warnings for the tool folder <!-- id:check:E:build -->
- [ ] Batch E: owner review done; first-hand line spots listed <!-- id:check:E:owner -->

---

## Phase 4: Interview Layer

- [x] `interview/round-2-hands-on.md` <!-- id:delivery/git/interview/round-2-hands-on.md -->
- [x] `interview/mock-interviews.md` <!-- id:delivery/git/interview/mock-interviews.md -->
- [x] Output-reading drills in `round-2-hands-on.md` <!-- id:p4:output-drills -->
- [x] Phase 4: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:4:grows -->
- [x] Phase 4: `scripts/lint-prose.py` exits 0 <!-- id:check:4:lint -->
- [x] Phase 4: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:4:audit -->
- [x] Phase 4: `mkdocs build` has no warnings for the tool folder <!-- id:check:4:build -->
- [ ] Phase 4: owner review done; first-hand line spots listed <!-- id:check:4:owner -->

---

## Phase 5: Reference and Labs

- [x] `reference/cheatsheet.md` <!-- id:delivery/git/reference/cheatsheet.md -->
- [x] `reference/command-index.md` <!-- id:delivery/git/reference/command-index.md -->
- [x] `reference/config-reference.md` <!-- id:delivery/git/reference/config-reference.md -->
- [x] `reference/dotfiles-reference.md` <!-- id:delivery/git/reference/dotfiles-reference.md -->
- [x] `reference/glossary.md` <!-- id:delivery/git/reference/glossary.md -->
- [x] `labs/internals-by-hand-lab.md` <!-- id:delivery/git/labs/internals-by-hand-lab.md -->
- [x] `labs/history-surgery-lab.md` <!-- id:delivery/git/labs/history-surgery-lab.md -->
- [x] Every `INVENTORY.md` item resolved <!-- id:p5:inventory-resolved -->
- [x] Phase 5: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:5:grows -->
- [x] Phase 5: `scripts/lint-prose.py` exits 0 <!-- id:check:5:lint -->
- [x] Phase 5: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:5:audit -->
- [x] Phase 5: `mkdocs build` has no warnings for the tool folder <!-- id:check:5:build -->
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
