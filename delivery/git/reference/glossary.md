# Glossary

One-line definitions of the Git terms used across this folder. Each entry links to the topic that explains it in full.

---

## A to D

| Term | Definition |
|---|---|
| Annotated tag | A full tag object with a tagger, date and message, and can be signed. See [Tags and Releases](../03-remotes-and-collaboration/tags-and-releases.md). |
| Bare repository | A repo with no working tree, holding only the object store, used as a remote. See [Remotes](../03-remotes-and-collaboration/remotes.md). |
| Bisect | A binary search over history for the first commit that broke something. See [Bisect](../05-history-and-recovery/bisect.md). |
| Blob | The object type holding file content, with no name or metadata. See [Object Model](../06-internals/object-model.md). |
| Cherry-pick | Applying one commit's change onto the current branch as a new commit. See [Cherry-Pick](../02-branching-and-merging/cherry-pick.md). |
| Commit | An object tying a tree snapshot to its parents, author and message. See [Object Model](../06-internals/object-model.md). |
| Conflict marker | The `<<<<<<<`, `=======`, `>>>>>>>` lines Git writes where two changes overlap. See [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md). |
| Content-addressed | Objects are named by the hash of their content, giving dedup and integrity. See [Object Model](../06-internals/object-model.md). |
| DAG | Directed acyclic graph: the shape of commit history, each commit pointing at parents. See [Refs and HEAD](../06-internals/refs-and-head.md). |
| Detached HEAD | `HEAD` pointing straight at a commit rather than a branch. See [Branches](../02-branching-and-merging/branches.md). |

---

## E to L

| Term | Definition |
|---|---|
| Fast-forward | Moving a branch ref forward with no merge commit, when it has no divergent work. See [Merging](../02-branching-and-merging/merging.md). |
| Fetch | Downloading refs and objects from a remote without changing any branch. See [Remotes](../03-remotes-and-collaboration/remotes.md). |
| Force-with-lease | A force push that refuses if the remote moved since your last fetch. See [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md). |
| Gitlink | A tree entry (mode `160000`) storing a submodule's pinned commit SHA. See [Submodules](../07-advanced-tooling/submodules.md). |
| HEAD | The ref naming the current commit, usually via the current branch. See [Refs and HEAD](../06-internals/refs-and-head.md). |
| Hunk | A contiguous block of changed lines in a diff, the unit `add -p` stages. See [Staging and Committing](../01-core-workflow/staging-and-committing.md). |
| Index | The staging area between the working tree and the next commit. See [The Three Trees](../00-foundations/the-three-trees.md). |
| Loose object | An object stored as its own zlib-compressed file before packing. See [Packfiles and GC](../06-internals/packfiles-and-gc.md). |

---

## M to R

| Term | Definition |
|---|---|
| Merge base | The most recent common ancestor of two commits. See [How Merge and Rebase Work](../06-internals/how-merge-and-rebase-work.md). |
| ORIG_HEAD | The tip before the last reset, merge or rebase, for quick undo. See [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md). |
| Packfile | A compressed file holding many objects as deltas, for storage and transfer. See [Packfiles and GC](../06-internals/packfiles-and-gc.md). |
| Partial clone | A clone that skips blob content, fetching it on demand. See [Large Repos](../07-advanced-tooling/large-repos.md). |
| Rebase | Replaying commits onto a new base, creating new commits with new SHAs. See [Rebasing](../02-branching-and-merging/rebasing.md). |
| Ref | A name (branch, tag, `HEAD`) pointing at a commit. See [Refs and HEAD](../06-internals/refs-and-head.md). |
| Reflog | A local log of every move of `HEAD` and branch tips, for recovery. See [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md). |
| Remote-tracking branch | A local ref (`origin/main`) mirroring a branch's last-fetched state. See [Remotes](../03-remotes-and-collaboration/remotes.md). |
| rerere | Reuse recorded resolution: Git replays a past conflict fix automatically. See [Conflict Resolution](../02-branching-and-merging/conflict-resolution.md). |

---

## S to Z

| Term | Definition |
|---|---|
| Shallow clone | A clone limited to the last N commits with `--depth`. See [Large Repos](../07-advanced-tooling/large-repos.md). |
| Snapshot | Git's model: each commit records a full tree, not a diff. See [What Is Git](../00-foundations/what-is-git.md). |
| Sparse-checkout | Materializing only chosen paths in the working tree. See [Large Repos](../07-advanced-tooling/large-repos.md). |
| Stash | A shelf holding working-tree changes as commits, off any branch. See [Stashing](../03-remotes-and-collaboration/stashing.md). |
| Submodule | Another repository embedded at a path as a pinned commit. See [Submodules](../07-advanced-tooling/submodules.md). |
| Three-way merge | Combining two branches using their changes against the merge base. See [How Merge and Rebase Work](../06-internals/how-merge-and-rebase-work.md). |
| Tree | The object type holding a directory listing of blobs and subtrees. See [Object Model](../06-internals/object-model.md). |
| Upstream | The remote branch a local branch tracks, shown as `[ahead/behind]`. See [Pushing and Pulling](../03-remotes-and-collaboration/pushing-and-pulling.md). |
| Working tree | The checked-out files you edit, one of the three trees. See [The Three Trees](../00-foundations/the-three-trees.md). |
| Worktree (linked) | An additional checkout attached to one repository's object store. See [Worktrees](../07-advanced-tooling/worktrees.md). |

---

## Related

- [Must-Know Facts](must-know-facts.md): the facts tables these terms come from
- [Command Index](command-index.md): the commands that create and manage these objects
- [Config Reference](config-reference.md): the settings behind many of these terms
- [Object Model](../06-internals/object-model.md): the blob, tree, commit and tag these definitions build on
