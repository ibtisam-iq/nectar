# Git Completion Audit

Date: 2026-09-24. Scope: `delivery/git/`, the second tool folder built to the plan in `plan/git/plan.md`. This report records the Phase 6 completion audit: the automated checks, the link and rendering checks, and the independent review with how its findings were resolved.

---

## Result Summary

The folder is structurally complete and passes every automated and manual check within its scope. All 35 topic files, 8 module READMEs, 10 scenarios, 5 labs, 7 reference pages and 5 interview round pages exist and match `manifest.yml` (74 Markdown files, excluding the git-ignored `_sources/`). The independent review found no must-fix factual errors; one should-fix imprecision and five polish items were raised and all six are resolved (see below).

Two completion boxes remain open by design and are the owner's to close: the final owner sign-off, and the residual `--full` audit failures that are themselves the pending-owner checklist boxes (see the note under check 15).

---

## Automated Checks (`scripts/audit-tool.py`)

`scripts/audit-tool.py --manifest plan/git/manifest.yml --scope 5 --build` exits 0 (0 failures), which through the last batch covers the whole folder. `--full` reports failures only for check 15 (see below). Each check and its result:

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
| 9 | Coverage: every `INVENTORY.md` item resolved (no coverage-map, per G6) | Pass |
| 10 | Output honesty: every `text` block has `Output:`/`Layout:`, footers where output exists | Pass |
| 11 | Tabs: only the two approved labels (`macOS / Linux`, `Windows`) | Pass |
| 12 | Links: no relative links inside snippets, all relative links resolve | Pass |
| 13 | Housekeeping: legacy files removed, `_sources/` and `plan/` excluded | Pass |
| 14 | LLM pointers: repo `CLAUDE.md` and Notes Conventions section | Pass |
| 15 | Checklist: every box ticked | Residual only (see note) |
| 16 | Delegated: `lint-prose.py` (0 of 74 files), `mkdocs build` no folder warnings | Pass |

`lint-prose.py` reports 0 violations across all 74 files. The 35 topics each carry their `facts` and `l1` snippets, transcluded into `must-know-facts.md` (35 includes) and `round-1-screening.md` (35 includes); 217 interview checkpoints in total.

**Note on check 15.** The `--full` audit fails check 15 for every unticked checklist box (16 failures). The remaining unticked boxes are all pending owner action or are the Phase 6 steps this report closes: Phase 0 push to `main`, the per-batch and per-phase owner reviews (A to E, Phase 4, Phase 5), the final owner sign-off, the owner's pull request, and the `--full`-exits-0 box itself. This is circular by construction: the full audit reaches 0 failures only after the owner ticks the final boxes. Checks 1 to 14 and 16 pass with 0 failures now.

---

## Line-Budget Notes (non-failing)

Six High-weight topics land in the 212 to 248 range, under the 250-line guide: `04-team-workflows/branching-strategies.md` (248), `05-history-and-recovery/reflog-and-recovery.md` (221), `05-history-and-recovery/rewriting-history.md` (218), `06-internals/object-model.md` (243), `06-internals/refs-and-head.md` (212), and `06-internals/how-merge-and-rebase-work.md` (214). These are strategy and internals topics that are table- and capture-dense; padding them to an exact count would add filler, so the pages carry real content plus real captures (decisions G18, G21). Only the upper bound is a hard fail, and none exceed it.

---

## Link Check (`lychee`)

`lychee --offline` over the built Git HTML reports **zero broken links inside Git content**. Every relative link between Git pages resolves.

lychee does report 8 broken targets rendered into every page (`Chart.yaml`, `CKA-KodeKloud-Complete-Notes.pdf`, `compose.yml`, `efs-fsx.md`, `k8s.txt`, `rs.guide.yaml`, `secret-manager.md`, `volumes.yaml`), 592 errors that are these 8 targets across all 74 Git pages. They come from the global Material navigation sidebar, for top-level repository files excluded from the build, and appear site-wide on every page, not only Git pages. They are pre-existing, outside `delivery/git/`, and outside this plan's scope; the same set was recorded in the Linux completion audit. Noted here for the owner to address separately.

---

## Rendering Check

Served locally with `mkdocs serve` and checked in a browser at desktop and phone (375px) width:

- Module order and breadcrumbs are correct (Home to CI/CD & Delivery to Git to the module).
- Admonitions render with their type styling (danger, tip, note, info, warning).
- `???` solution and question blocks collapse and expand; an expanded lab solution shows its `bash` command and `Output:` block with the copy button.
- The two platform tabs on `credentials-and-signing.md` render as a tabbed set and switch.
- Aggregators render fully: the module-07 `facts` rows appear in `must-know-facts` and the module-07 `l1` questions in `round-1-screening`, with no leaked snippet markers (`--8<--`, `[start:` / `[end:]`) anywhere in the built HTML.
- Phone width has a 16px gutter, no horizontal overflow, and working dark mode.

One incidental observation: the local `mkdocs serve` logs carry an advertisement injected by a dependency urging a switch to a third-party "ProperDocs" build tool. It is untrusted output, not acted on, and does not affect the build; flagged for the owner's awareness only.

---

## Independent Review

A fresh agent reviewed all 35 module topics in full, plus the glossary, cheatsheet and a sample of scenarios, against the writing standard and blueprint, with the automated-check domain (structure, links, prose, budgets) explicitly out of its remit. It found **no must-fix factual errors**: Git 2.50 behaviour (reset modes, merge vs rebase, `--force-with-lease`, the object model and hashing, refs and peeling, packfiles, submodule gitlinks, worktrees, SSH signing, `filter-repo`, reflog expiry, semver-to-commit mapping, `range-diff`) is described correctly and consistently, captured output is internally consistent and uses the example identity, and the interview answers are correct.

It raised one should-fix and five polish items; all six are resolved:

| # | Severity | Finding | Resolution |
|---|---|---|---|
| 1 | Should-fix | `bisect.md` capped a "bad" exit code at 124 in three places | Corrected to Git's real rule: `0` good, `125` skip, `1`–`127` (except `125`) bad, `128`+ aborts |
| 2 | Nice | `staging-and-committing.md` listed the same `Inspecting History` link twice in Related | Replaced the duplicate with a link to `Ignoring and Attributes` |
| 3 | Nice | `branching-strategies.md` squash log showed a `docs: readme` commit the sequence never created | Re-captured the sequence; output now shows only `feat: add login` and `Initial` |
| 4 | Nice | `detached-head.md` reflog used a truncated `6cec8dd...` SHA Git does not write | Re-captured; the reflog now shows the full 40-char SHA Git actually records |
| 5 | Nice | `conflict-resolution.md` showed the rerere preimage and resolution lines in one block | Re-captured; the preimage now shows at merge time and the resolution at commit, as two steps |
| 6 | Nice | `hooks.md` labelled a `codeowners.md` link "delivery/github" | Relabelled to "CODEOWNERS" |

After the fixes, `lint-prose.py` still reports 0 violations and `audit-tool.py --scope 5 --build` still exits 0.

---

## Decisions Recorded This Build

Phases 3 to 6 added decisions G12 to G29 in `plan/git/decisions.md`, covering the forward-reference link rule, the tool-agnostic generalization of the audit `TRACK_RE`, the Workflow track, the `filter-repo` and LFS non-core-tool footnoting, the terse-Low budget trade-off, the interview-layer build, and the reference/labs build. No plan structure changed; the manifest is as approved (`plan_version: 1`).

---

## What Remains (owner)

- Owner review of the folder and final sign-off.
- Owner pushes `feature/git-notes` and opens the pull request (agents commit locally only).
- On merge, mark Git complete in `plan/README.md`'s status table (this report already records the clean audit).

The folder is technically sound and ready to be marked complete once the owner signs off.
