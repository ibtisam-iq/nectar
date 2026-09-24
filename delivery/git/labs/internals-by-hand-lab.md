# Internals by Hand

Build a commit from its parts using only plumbing commands, with no `git add` or `git commit`. The goal is to prove that a commit is a tree plus parents, that a tree is a list of blobs, and that every object is named by the hash of its content. By the end you will have a two-commit history that `git log` reads normally, all created by hand.

---

## Setup

Use a throwaway repository. Set a fixed identity so your object SHAs match the ones shown here.

```bash
mkdir -p /tmp/git-internals && cd /tmp/git-internals
git init
git config user.name "Amina Yusuf"
git config user.email "amina@example.com"
```

The SHAs below assume that identity and a fixed commit date; with your own clock the tree SHAs match but commit SHAs differ. Delete the directory when done.

---

## Blobs and Trees

### 1. Write a Blob into the Object Store

Store a piece of content directly as a blob, with no file staged, and read it back by its SHA.

??? tip "Solution"
    ```bash
    echo 'hello internals' | git hash-object -w --stdin
    ```

    Output:

    ```text
    7fb30904241a9ffd036dc6695c5de5b1d977c7fc
    ```

    `-w` writes the object; the SHA is the hash of `blob <size>\0hello internals`. `git cat-file -p 7fb3090` prints the content back. The object exists with nothing referencing it, a dangling blob.

### 2. Build a Tree from the Index

Stage a file into the index, then snapshot the index as a tree object.

??? tip "Solution"
    ```bash
    echo 'hello internals' > greeting.txt
    git update-index --add greeting.txt
    git write-tree
    ```

    Output:

    ```text
    f9c4d7fb83fbb0e4fd4588ebb70ae25d577d4522
    ```

    `update-index --add` is the plumbing under `git add`; `write-tree` turns the current index into a tree. Reading it shows the blob from task 1, proving the tree only references content it does not store.

    ```bash
    git cat-file -p f9c4d7f
    ```

    Output:

    ```text
    100644 blob 7fb30904241a9ffd036dc6695c5de5b1d977c7fc	greeting.txt
    ```

---

## Commits

### 3. Create a Commit Object

Wrap the tree in a commit with `commit-tree`, which prints the new commit's SHA.

??? tip "Solution"
    ```bash
    COMMIT=$(echo "First commit, by hand" | git commit-tree f9c4d7f)
    echo $COMMIT
    git cat-file -p $COMMIT
    ```

    Output:

    ```text
    tree f9c4d7fb83fbb0e4fd4588ebb70ae25d577d4522
    author Amina Yusuf <amina@example.com> 1772337600 +0500
    committer Amina Yusuf <amina@example.com> 1772337600 +0500

    First commit, by hand
    ```

    The commit references the tree and holds the author, committer and message. It has no `parent` line, because it is the first commit.

### 4. Point a Branch at the Commit

The commit exists but no branch names it. Create `main` pointing at it with `update-ref`, and `git log` starts working.

??? tip "Solution"
    ```bash
    git update-ref refs/heads/main $COMMIT
    git log --oneline
    ```

    Output:

    ```text
    74257b5 First commit, by hand
    ```

    `update-ref` writes the branch ref directly. Now `HEAD` resolves through `main` to the commit, so ordinary porcelain (`git log`, `git show`) reads the hand-built history.

### 5. Add a Second Commit with a Parent

Change the file, snapshot a new tree, and commit it with `-p` naming the first commit as its parent.

??? tip "Solution"
    ```bash
    echo 'second line' >> greeting.txt
    git update-index greeting.txt
    TREE2=$(git write-tree)
    COMMIT2=$(echo "Second commit, by hand" | git commit-tree $TREE2 -p HEAD)
    git update-ref refs/heads/main $COMMIT2
    git log --oneline
    ```

    Output:

    ```text
    1519d9d Second commit, by hand
    74257b5 First commit, by hand
    ```

    The `-p HEAD` gives the new commit a parent, which is what links it into history. Reading it shows the `parent` line pointing at the first commit.

    ```bash
    git cat-file -p HEAD | head -3
    ```

    Output:

    ```text
    tree bbedfc38119cd298e637722b588e0c3c15097a69
    parent 74257b57ef5c981cbe67696323052827215a6c1a
    author Amina Yusuf <amina@example.com> 1772341200 +0500
    ```

---

## Proving the Constants

### 6. The Empty Tree Has a Universal SHA

The empty tree's content is fixed, so its SHA is the same in every SHA-1 repository.

??? tip "Solution"
    ```bash
    git hash-object -t tree /dev/null
    ```

    Output:

    ```text
    4b825dc642cb6eb9a060e54bf8d69288fbee4904
    ```

    This constant appears in every repository, and tools use it as a stable base, for example diffing a first commit against the empty tree. It is a direct consequence of content addressing: identical content, identical id.

---

## Cleanup

```bash
cd /tmp && rm -rf git-internals
```

You built two commits, two trees and two blobs with no `add` or `commit`, and `git log` read them as normal history. That is the whole model: refs point at commits, commits at trees, trees at blobs, every edge a content hash.

---

## Related

- [Object Model](../06-internals/object-model.md): the four object types this lab builds
- [Refs and HEAD](../06-internals/refs-and-head.md): what `update-ref` and `HEAD` do
- [The Three Trees](../00-foundations/the-three-trees.md): the index this lab writes with `update-index`
- [Packfiles and GC](../06-internals/packfiles-and-gc.md): how these loose objects get packed

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
