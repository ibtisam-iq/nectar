# Advanced Tooling

The tools that sit around everyday Git: hooks for automation, submodules and worktrees for structuring work across repositories and branches, the levers for keeping large repositories fast, and the credentials and signing that secure access and authorship. These are the topics that separate a confident Git user from one who has mastered the tool.

---

## Revision Card

| Fact | Value |
|---|---|
| Hooks | Scripts Git runs at workflow points; client hooks are advisory |
| Bypass a hook | `git commit --no-verify` |
| Shared hooks | `core.hooksPath` or the pre-commit framework |
| Submodule | A pinned commit SHA of another repo (gitlink, mode `160000`) |
| Clone with submodules | `git clone --recurse-submodules` |
| Worktree | A second checkout sharing one object store |
| Shallow clone | `--depth N`; extend with `fetch --deepen`/`--unshallow` |
| Partial clone | `--filter=blob:none`; blobs fetched on demand |
| Sparse-checkout | Materialize only chosen paths in the working tree |
| Signing | `gpg.format ssh` reuses an SSH key to sign commits |

| Task | Command |
|---|---|
| Share hooks with the team | `git config core.hooksPath .githooks` |
| Add a submodule | `git submodule add <url> <path>` |
| Populate submodules after clone | `git submodule update --init --recursive` |
| Add a worktree on a new branch | `git worktree add ../hotfix -b hotfix` |
| Shallow clone for CI | `git clone --depth 1 <url>` |
| Monorepo checkout | `git clone --filter=blob:none <url>; git sparse-checkout set <dir>` |
| Sign every commit | `git config commit.gpgsign true` |
| Verify a signature | `git log --show-signature -1` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Hooks](hooks.md) | Client and server hooks, bypass, shared hooks, the framework | Advanced | Med |
| [Submodules](submodules.md) | The gitlink model, cloning, the two-step update | Advanced | Med |
| [Worktrees](worktrees.md) | Multiple checkouts of one repository | Advanced | Low |
| [Large Repos](large-repos.md) | Shallow/partial clone, sparse-checkout, LFS, maintenance | Advanced | Med |
| [Credentials and Signing](credentials-and-signing.md) | SSH vs HTTPS, helpers, commit signing | Core | Med |

---

## Scenarios and Labs

- [Bloated Repo, Large File](../interview/scenarios/bloated-repo-large-file.md): find and purge a big blob committed by accident
