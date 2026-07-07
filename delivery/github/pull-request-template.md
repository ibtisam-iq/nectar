# Pull Request Template

## Purpose

`.github/PULL_REQUEST_TEMPLATE.md` defines a template that automatically pre-fills the description box whenever a new pull request is opened against the repository.

## Content

```
## What
## Why
## Testing
- [ ] `make check` passes locally
- [ ] Tested affected variant(s) with `make run-<variant>`
## Notes
```

## Why It Exists

The template forces every contributor to explicitly state what changed, why it changed, and confirm that local validation was performed before requesting a merge. The testing checklist ties directly into the project's own Makefile-based local development workflow (`make check`, `make run-<variant>`).

## Origin

This template was authored specifically for this repository. It references commands that only exist in this project's own Makefile — it was not copied from an external template registry or generic boilerplate.
