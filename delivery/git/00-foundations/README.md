# Foundations

What Git is and how it is set up: the distributed snapshot model, installing and configuring an identity, and the three-tree mental model that every later command builds on.

---

## Revision Card

| Fact | Value |
|---|---|
| Distributed | Every clone is a full repository with complete history |
| Storage | Snapshots of the whole tree per commit, not per-file diffs |
| Object id | Content hash; identical content, identical id |
| Config scopes | System, then global, then local, most specific wins |
| Identity | `user.name` and `user.email`, stamped into every commit |
| Working tree | The files on disk |
| Index | The proposed next commit, a full tree of entries |
| `HEAD` | A pointer to the last commit on the current branch |

| Task | Command |
|---|---|
| Start a repository | `git init` |
| Set global identity | `git config --global user.email "you@example.com"` |
| See where a value comes from | `git config --show-origin <key>` |
| See the three states | `git status` |
| Unstaged changes | `git diff` |
| Staged changes | `git diff --cached` |
| Inspect a commit's snapshot | `git cat-file -p HEAD^{tree}` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [What Is Git](what-is-git.md) | Distributed VCS, snapshots not diffs, content addressing | Core | Med |
| [Install and Config](install-and-config.md) | Config scopes, identity, aliases, `includeIf` | Core | Med |
| [The Three Trees](the-three-trees.md) | Working tree, index, `HEAD`, and moving between them | Core | High |

---

## Scenarios and Labs

- [Core Workflow Lab](../labs/core-workflow-lab.md): init, config, stage and commit in a fresh repository
- These foundations feed every scenario; the [three-tree model](the-three-trees.md) underlies [Accidental Commit to Main](../interview/scenarios/accidental-commit-to-main.md)
