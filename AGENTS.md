# AGENTS.md

Instructions for AI coding agents working in this repository.

## Read Before Writing Content

Before creating or editing any tool folder or knowledge-base page, read:

1. `plan/README.md`: index of plans and their status.
2. `plan/standards/`: the writing standard, the tool folder blueprint, and the definition of done. These override the style of older pages in this repository.
3. The plan for the tool being written (for example `plan/linux/`), including `manifest.yml` and `checklist.md`.

## Rules

- Follow `plan/standards/writing-standard.md` for every page.
- Plan changes update `plan.md`, `manifest.yml` and `decisions.md` in the same commit. Regenerate the checklist with `python scripts/gen-checklist.py plan/<tool>`.
- Build and repository commands are documented in `CLAUDE.md`.
