# Remotes and Collaboration

Working with other copies of the repository: remotes and tracking refs, pushing and pulling safely, tagging releases, shelving work with stashes, and the fork plus pull request model. This is where Git stops being a local tool and becomes a team one.

---

## Revision Card

| Fact | Value |
|---|---|
| Remote | A named URL for another repository |
| `origin/main` | Local cache of the remote's `main`, moves only on fetch |
| Fetch vs pull | Fetch updates tracking refs; pull fetches then integrates |
| Rejected push | Remote moved; integrate with pull, never `--force` |
| Force safely | `--force-with-lease` refuses if the remote moved |
| Annotated tag | A real object (tagger, date, message); can be signed |
| Tags and push | Tags need an explicit push |
| Stash | Shelved changes stored as commits off `refs/stash` |
| Fork remotes | `origin` = your fork, `upstream` = the original |

| Task | Command |
|---|---|
| See remotes | `git remote -v` |
| Update tracking refs | `git fetch` (add `--prune`) |
| Reconcile linearly | `git pull --rebase` |
| Overwrite your branch safely | `git push --force-with-lease` |
| Publish a release tag | `git tag -a v1.0.0 -m "..."; git push origin v1.0.0` |
| Shelve dirty work | `git stash push -u -m "..."` |
| Sync a fork | `git fetch upstream; git merge --ff-only upstream/main` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Remotes](remotes.md) | Remote URLs, tracking refs, fetch vs pull, prune | Core | High |
| [Pushing and Pulling](pushing-and-pulling.md) | Upstreams, `pull --rebase`, `--force-with-lease` | Core | High |
| [Tags and Releases](tags-and-releases.md) | Lightweight vs annotated, `describe`, pushing tags | Core | Med |
| [Stashing](stashing.md) | Shelving work, pop vs apply, stash to a branch | Core | Med |
| [Forks and Pull Requests](forks-and-pull-requests.md) | Fork model, syncing, the PR flow | Workflow | Med |

---

## Scenarios and Labs

- [Diverged Branches, Push Rejected](../interview/scenarios/diverged-branches-push-rejected.md): local and remote both moved, push refused
- [Detached HEAD](../interview/scenarios/detached-head.md): commits made off a branch, and saving them
- The [Branching and Rebase Lab](../labs/branching-and-rebase-lab.md) covers the rebase that a `pull --rebase` performs
