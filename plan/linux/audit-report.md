# Linux Completion Audit

Date: 2026-09-18. Scope: `technical-grounding/linux/`, the pilot tool folder for the plan in `plan/linux/plan.md`. This report records the Phase 6 completion audit: the automated checks, the link and rendering checks, and the independent review with how its findings were resolved.

---

## Result Summary

The folder is structurally complete and passes every automated and manual check that is within its scope. All 140 topic files, 21 module READMEs, 19 scenarios, 8 labs, 9 reference pages and 5 interview round pages exist and match `manifest.yml` (206 Markdown files, excluding git-ignored `_sources/`). The independent review found one should-fix accuracy error and a handful of minor items, all resolved or accepted with reason below.

Two completion boxes remain open by design and are the owner's to close: the final owner sign-off, and the residual `--full` audit failures that are themselves the pending-owner checklist boxes (see the note under check 15).

---

## Automated Checks (`scripts/audit-tool.py`)

`scripts/audit-tool.py --manifest plan/linux/manifest.yml --scope 5 --build` exits 0 (0 failures). `--full` reports failures only for check 15 (see below). Each check and its result:

| # | Area | Result |
|---|---|---|
| 1 | Completeness: every manifest entry exists, no unplanned `.md` | Pass |
| 2 | Navigation: every folder has `.pages`, every file listed, no `...` | Pass |
| 3 | Topic structure: H1, opening, Track line, section order, footers | Pass |
| 4 | Interview coverage: 6 to 12 checkpoints, L1 markers, High has L3, internals has L4 | Pass |
| 5 | Scenario structure: template sections, listed in round 3 and a README | Pass |
| 6 | Module READMEs: Revision Card and a topic map matching the folder | Pass |
| 7 | Aggregators: `must-know-facts` has every `facts` snippet, `round-1` every `l1` | Pass |
| 8 | Line budgets: every file within its weight's budget | Pass (below-lower notes only) |
| 9 | Coverage: `coverage-map` rows resolve, every `INVENTORY.md` item resolved | Pass |
| 10 | Output honesty: every `text` block has `Output:`/`Layout:`, footers where output exists | Pass |
| 11 | Tabs: only the two approved labels | Pass |
| 12 | Links: no relative links inside snippets, all relative links resolve | Pass |
| 13 | Housekeeping: legacy files removed, `_sources/` and `plan/` excluded | Pass |
| 14 | LLM pointers: `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, Notes Conventions section | Pass |
| 15 | Checklist: every box ticked | Residual only (see note) |
| 16 | Delegated: `lint-prose.py` (0 of 206 files), `mkdocs build` no folder warnings | Pass |

`lint-prose.py` reports 0 violations across all 206 files.

**Note on check 15.** The `--full` audit fails check 15 for every unticked checklist box. The remaining unticked boxes are all pending owner action or are the Phase 6 steps this report closes: Phase 0 merge to `main`, the `_sources/` resume-and-zip cleanup (owner-held, git-ignored files), the batch I / Phase 4 / Phase 5 owner reviews, the final owner sign-off, and the `--full`-exits-0 box itself. This is circular by construction: the full audit reaches 0 failures only after the owner ticks the final boxes. Checks 1 to 14 and 16 pass with 0 failures now.

---

## Link Check (`lychee`)

`lychee --offline` over the built Linux HTML reports **zero broken links inside Linux content**. Every relative link between Linux pages resolves.

lychee does report 8 broken targets rendered into every page: `compose.yml`, `Chart.yaml`, `k8s.txt`, `efs-fsx.md`, `secret-manager.md`, `rs.guide.yaml`, `volumes.yaml` and a CKA PDF. These come from the global Material navigation sidebar (`md-nav__link`), for top-level repository files excluded from the build, and appear site-wide on every page, not only Linux pages. They are pre-existing, outside `technical-grounding/linux/`, and outside this plan's scope; fixing them means changing the global navigation, which the plan does not cover. Recorded here for the owner to address separately.

---

## Rendering Check

Served locally with `mkdocs serve` and checked in a browser:

- Module order and breadcrumbs are correct (Home to Grounding to Linux to the module).
- Admonitions render with their type styling (danger, tip, note, warning).
- `???` solution and question blocks collapse and expand.
- Distro tabs render and switch, with `Output:` labels and `# ... (trimmed)` markers intact.
- Aggregators render fully: 262 L1 checkpoints as detail blocks in `round-1-screening`, 4512 fact cells in `must-know-facts`, with no leaked snippet markers.
- Comparison tables scroll within their container at phone width with no page overflow.
- Dark mode renders correctly.

---

## Independent Review

A fresh agent with no session context reviewed the folder against `plan.md` and the three standards, focused on what the scripts cannot judge: trivia questions, student-style prose, AI tells, accuracy and consistency. Findings and resolutions:

| Finding | Severity | Resolution |
|---|---|---|
| `rhel-vs-ubuntu.md` `useradd` row said RHEL creates no home by default; RHEL does (`CREATE_HOME yes`), Ubuntu does not without `-m` | Should-fix | Fixed: the row now states RHEL creates the home and Ubuntu needs `-m`, matching `04-users-and-access/users.md` |
| `no-tools-fallbacks.md` labelled a recursive `**/*` glob as `find (shallow)` | Minor | Fixed: relabelled `find (recursive)` |
| `break-fix-lab.md` exercise 2 was muddled between inode and space exhaustion on `tmpfs` | Minor | Fixed: now demonstrates the space case cleanly, with inode exhaustion named as the real-disk variant |
| `archiving-and-compression.md` L1 "What does `-f` mean?" was pure recall | Should-fix (borderline) | Fixed: reworded to "why does it fail without `-f`" (stdin reasoning) |
| L1 recall questions in `pam.md`, `awk.md`, `login-sessions.md` | Minor | Fixed: reworded to reasoning prompts (an `account`-type denial, `$NF` with varying width, `btmp` for brute-force) that keep the fact |
| `round-1-screening.md` missing `---` before the last seven module headings | Minor | Fixed: separators added |
| `round-4-internals.md` three near-identical "typing `ls`" entries | Minor | Fixed: the Architecture and Process Lifecycle entries reworded to their distinct angle (user-to-kernel crossing; process created/replaced/reaped) |

**Accepted without change, with reason:**

- L1 in `exit-codes-and-chaining.md` (meaning of 0, 1, 126, 127, 137): kept, because 137 as 128 plus signal 9 is reasoning about the encoding, not a flat list, and the follow-ups escalate it.
- L1 in `text-editors.md` (save and exit vim): kept, as this is a hands-on essential every candidate is expected to do live, not list trivia.
- Curly quote in `flatpak-and-snap.md`: kept, because it is inside a reproduced literal error string, where accuracy outranks the ASCII rule.

The reviewer rated student-style prose and AI tells clean across the sampled pages (foundations, High-weight internals, Low-weight, all reference and lab pages, aggregators).

---

## Post-Fix Verification

After the fixes, `lint-prose.py` reports 0 violations and `audit-tool.py --scope 5 --build` reports 0 failures. The changes touched question wording, one reference row, two lab passages and separators; none changed file counts, snippet markers or budgets.

---

## Closeout

All owner items are done: batch I, Phase 4 and Phase 5 were reviewed and signed off, the `_sources/` third-party resume and duplicate zip were removed (git-ignored, owner-held), and the work merged to `main` in pull request #19. With the final checklist boxes ticked, `audit-tool.py --manifest plan/linux/manifest.yml --full` exits 0 (all 16 checks pass, notes only). The Linux tool folder is complete.

One item remains open by choice, outside this folder: the global-navigation broken links noted under the link check, left for a separate focused change if the owner wants them fixed.
