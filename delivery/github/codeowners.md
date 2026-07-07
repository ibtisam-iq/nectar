# CODEOWNERS

## Purpose

`CODEOWNERS` is a GitHub-native file that assigns responsibility over parts of a codebase to specific GitHub usernames or teams. GitHub reads this file automatically and uses it for two purposes:

1. Auto-requesting a review from the listed owner whenever a pull request touches matching files
2. Enforcing "owner approval required" when branch protection rules are enabled

## Content

```
* @ibtisam-iq
```

The wildcard `*` matches every file in the repository. This single line declares `@ibtisam-iq` as the owner of the entire codebase.

## Why It Was Added

For a solo-maintained open-source project, this file makes ownership explicit to GitHub and to any future contributor. It also unlocks automatic reviewer assignment on pull requests once branch protection is configured.

## Clarification: "Owned by [username]" Label

GitHub's web interface displays an "Owned by [username]" annotation next to file paths in the pull request diff view and in the repository file browser. This label is rendered purely because GitHub reads `CODEOWNERS` and displays ownership metadata on screen.

This is a GitHub interface annotation, not a modification to any source file. Nothing is written into Dockerfiles, workflows, or scripts as a result of this file. The label disappears automatically if `CODEOWNERS` is removed.
