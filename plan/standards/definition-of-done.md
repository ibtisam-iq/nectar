# Definition of Done

A tool folder is complete only when every check below passes. Automated checks run through `scripts/audit-tool.py`; the rest are recorded by the independent review and the owner's sign-off in `plan/<tool>/audit-report.md`.

---

## Automated Checks (`scripts/audit-tool.py`)

| # | Area | Check |
|---|---|---|
| 1 | Completeness | Every manifest entry exists on disk. Every `.md` file in the tool folder (except `_sources/`) is listed in the manifest. |
| 2 | Navigation | Every folder has a `.pages` file. Every file appears in its `.pages`, every `.pages` entry resolves, and no `.pages` uses the `...` catch-all. |
| 3 | Topic structure | H1 with at most two opening sentences, a Track and Weight line matching the manifest, `## Must-Know Facts` inside snippet markers, `## Interview Checkpoints`, `## Related`, and a capture footer, in template order. |
| 4 | Interview coverage | 6 to 12 checkpoints per topic; L1 questions inside `l1` snippet markers; at least one L3 in every High-weight topic; at least one L4 in every `(I)` topic, and each `(I)` topic linked from `round-4-internals.md`. |
| 5 | Scenario structure | Every scenario has Symptom, Clarifying Questions, Diagnostic Path, Root Causes, Fix, Prevention, Related, and is linked from `round-3-troubleshooting.md` and from at least one module README. |
| 6 | Module READMEs | Revision Card present; Topic Map lists exactly the topic files in the folder. |
| 7 | Aggregators | `reference/must-know-facts.md` includes every topic's `facts` section; `interview/round-1-screening.md` includes every topic's `l1` section. |
| 8 | Line budgets | Every file is within the budget for its type and weight. |
| 9 | Coverage | Every row of `reference/coverage-map.md` points to an existing file. Every item in `_sources/INVENTORY.md` is resolved (file, fact, deferred with a target, or dropped with a reason). |
| 10 | Output honesty | Every `text` block is preceded by `Output:`; every page with output has a capture footer. |
| 11 | Tabs | Only the approved tab labels are used. |
| 12 | Links | All relative links resolve; no relative links inside snippet sections. |
| 13 | Housekeeping | Files scheduled for removal are gone; inbound links to them are fixed; `_sources/` is git-ignored and listed in `exclude_docs`. |
| 14 | LLM pointers | `CLAUDE.md`, `GEMINI.md` and `AGENTS.md` point to `plan/`; `CLAUDE.md` contains the Notes Conventions section. |
| 15 | Checklist | Every box in `plan/<tool>/checklist.md` is ticked. |
| 16 | Delegated checks | `scripts/lint-prose.py` exits 0 and `mkdocs build` reports no warnings for the tool folder. |

---

## Manual Checks

- **Independent review:** a fresh agent with no prior session context receives only `plan/<tool>/plan.md`, `plan/standards/` and the repository. It reports anything planned but missing, anything present but unplanned, trivia posing as interview questions, student-style or AI-sounding prose, and factual errors it can detect.
- **Rendering:** `mkdocs serve` shows correct module order and titles, Revision Cards, synchronised tabs, collapsing checkpoints, rendered snippet pages, and a usable layout at phone width and in dark mode.
- **Links:** `lychee ./site/**/*.html` on the final build.
- **Owner sign-off:** the owner reads the folder and signs off in `audit-report.md`.

Findings are fixed and the audit is re-run until clean. Only then is the tool marked complete in `plan/README.md`.
