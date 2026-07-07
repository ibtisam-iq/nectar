# Issue Templates

## Purpose

The `.github/ISSUE_TEMPLATE/` directory defines structured intake forms rendered by GitHub whenever a new issue is opened against the repository. Instead of a blank text box, GitHub converts the YAML definitions in this folder into an actual form with required fields.

## Files

### bug_report.yml

Renders a structured bug report form collecting:
- Affected variant (lite / balanced / power / base)
- Image tag or version
- Platform (amd64 / arm64 / both)
- Description of the observed behavior
- Expected behavior
- Additional context

### feature_request.yml

Renders a structured feature request form collecting:
- Target variant
- Requested addition or change
- The debugging use case the request solves

## Why This Matters

Without these templates, every issue reporter starts from an empty box. Reports arrive with vague titles and no reproduction context, forcing back-and-forth clarification before triage can even begin.

Required fields (`required: true`) block submission until filled, guaranteeing that every bug report already contains the variant, version, and platform needed to reproduce the problem.

## Before vs. After

| State | Behavior |
|---|---|
| Before | No issue guidance existed; reports had arbitrary structure or none |
| After | Every bug report and feature request is guaranteed a minimum structured baseline before submission |

## Where It Lives

```
.github/ISSUE_TEMPLATE/
├── bug_report.yml
└── feature_request.yml
```
