# Nectar Plans

This folder holds the plans and standards that govern how Nectar tool folders are written. It is tracked in git and excluded from the published site (`exclude_docs` in `mkdocs.yml`).

!!! danger "Read this before creating or editing any tool folder"
    Any person or LLM that writes Nectar content must read `plan/standards/` first, then the plan for the tool being written. Content that does not follow these standards is not accepted.

---

## Standards (apply to every tool folder)

| File | Purpose |
|---|---|
| [`standards/writing-standard.md`](standards/writing-standard.md) | Voice, sentence rules, banned vocabulary, formatting, accuracy rules |
| [`standards/tool-folder-blueprint.md`](standards/tool-folder-blueprint.md) | The four-layer folder layout, templates, Track and Weight system, interview question rules, output capture rules |
| [`standards/definition-of-done.md`](standards/definition-of-done.md) | The checks a tool folder must pass before it counts as complete |

---

## Tool Plans

| Tool | Folder | Plan | Status |
|---|---|---|---|
| Linux | `technical-grounding/linux/` | [`linux/plan.md`](linux/plan.md) | Complete: merged to `main` (#19), full audit clean ([`linux/audit-report.md`](linux/audit-report.md)), owner signed off |
| Git | `delivery/git/` | [`git/plan.md`](git/plan.md) | Phases 3 to 5 complete (all modules, interview layer, reference and labs), lint and `--scope 5 --build` clean; awaiting owner review; Phase 6 (completion audit) next |

Each tool plan folder contains:

- `plan.md`: context, verified structure, phases
- `manifest.yml`: machine-readable list of every planned file, read by `scripts/audit-tool.py`
- `decisions.md`: dated decision log
- `research.md`: coverage research and sources
- `checklist.md`: A-to-Z progress tracker, generated from `manifest.yml` by `scripts/gen-checklist.py`
- `audit-report.md`: written by the final completion audit

---

## Git Rules for Agents

- Commit locally only. Never push, never open or edit pull requests.
- Never add AI attribution lines (`Co-Authored-By: ...`, "Generated with ...") to commit messages or pull requests.
- The owner decides when work is pushed, reviewed and merged.

---

## Rules for Changing a Plan

- A change made during execution updates `plan.md` and `manifest.yml` and adds an entry to `decisions.md` in the same commit.
- `checklist.md` is regenerated after every `manifest.yml` change (`python scripts/gen-checklist.py plan/<tool>`). Ticked boxes are preserved.
- A tool folder is marked complete in the table above only after its `audit-report.md` records a clean audit.
