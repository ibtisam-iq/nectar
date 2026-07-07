# Dependabot Configuration

## Purpose

Dependabot is a native GitHub bot that scans a repository for outdated or vulnerable dependencies and automatically opens pull requests to bump their versions. `.github/dependabot.yml` is the configuration file that tells Dependabot what to scan, how often, and how to format the resulting pull requests. Without this file, Dependabot is inactive.

## Content

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    labels:
      - dependencies
      - ci
    commit-message:
      prefix: "ci"
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
    labels:
      - dependencies
      - docs
    commit-message:
      prefix: "docs"
```

## Field-by-Field Reference

### version

Fixed schema identifier. Must be `2` for the current Dependabot configuration format. This is not a free-text field — GitHub only recognizes this exact value.

### package-ecosystem

A fixed keyword from GitHub's supported ecosystem list — not arbitrary text. `github-actions` scans workflow files under `.github/workflows/` for pinned Action versions. `pip` scans Python dependency files (`requirements.txt`, `requirements-dev.txt`, `pyproject.toml`). Other supported values include `npm`, `docker`, `gomod`, `maven`, `cargo`, and `terraform`.

### directory

Anchors the scan at a specific path in the repository. `/` means the repository root. Each ecosystem has its own convention for where it expects to find manifest files once anchored — `github-actions` always resolves to `.github/workflows/` regardless of the directory value, while `pip` looks for its manifest files directly inside the given directory.

### schedule.interval

Controls how often Dependabot checks for new versions. `weekly` runs the check once every seven days. The first check runs immediately upon merging the configuration file, not after the first scheduled interval.

### labels

Arbitrary, user-defined strings — not a fixed GitHub vocabulary. `dependencies`, `ci`, and `docs` were chosen for organizational filtering. If a label does not already exist in the repository, Dependabot creates it automatically on first use. Labels affect only UI filtering; they do not change update behavior.

### commit-message.prefix

Prepends the given string to every commit message Dependabot generates for that ecosystem, aligning with conventional commit style (`ci: bump ...`, `docs: bump ...`).

## Execution Flow

1. On its schedule, Dependabot scans the configured ecosystems for newer available versions.
2. For each outdated dependency found, it creates a dedicated branch.
3. It commits the version bump on that branch, using the configured prefix.
4. It opens a pull request from that branch into the default branch.

No changes are ever committed directly to the default branch — every update arrives as a reviewable pull request.

## Interaction With CI

Existing CI workflows (triggered `on: pull_request`) run automatically against every Dependabot-created branch. A passing check confirms the proposed version bump is safe to merge. A failing check indicates the new dependency version introduced an incompatibility with the current build, lint, or test configuration, and should be investigated before merging.

## Recommended Handling of Generated Pull Requests

| Check Status | Action |
|---|---|
| Passing | Review the diff, confirm it is a version bump only, then merge |
| Failing | Inspect the failed CI step before merging; either adjust the affected configuration for compatibility or close the PR pending further review |

## Known Gap

The current configuration does not include a `docker` ecosystem entry, which would allow Dependabot to track base image version updates (e.g., `FROM alpine:3.20.9`) inside the project's Dockerfiles. Adding this entry is a natural follow-up once the base image build and release automation is finalized.
