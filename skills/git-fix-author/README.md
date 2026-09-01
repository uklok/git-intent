# `git fix-author`

Safely repair author and committer attribution across an inclusive commit range.

## Install

Copy the canonical executable to a directory on `PATH`:

```console
install -m 0755 \
  skills/git-fix-author/scripts/git-fix-author \
  "$HOME/.local/bin/git-fix-author"
```

Git exposes `git-fix-author` as `git fix-author`.

## Preview, then execute

```console
git fix-author \
  --start fix/author \
  --finish feature/foo \
  --name "AIPAL" \
  --email "aipal@uklok.ai" \
  --dry-run

git fix-author \
  --start fix/author \
  --finish feature/foo \
  --name "AIPAL" \
  --email "aipal@uklok.ai"
```

The finish value must be a local branch and defaults to the current branch.
Missing values are prompted for only when both stdin and stdout are terminals,
or when `--interactive` is explicit.

For reviewed automation:

```console
git fix-author \
  --start fix/author \
  --finish feature/foo \
  --name "AIPAL" \
  --email "aipal@uklok.ai" \
  --non-interactive \
  --yes
```

All primary values also have `GFA_*` environment equivalents documented by
`--help`.

## Identity semantics

By default, both the author and committer become the requested author. This
prevents `user.name` or `user.email` from the executing environment from
appearing in rewritten history.

Set a separate committer only as an explicit pair:

```console
git fix-author \
  --start fix/author \
  --name "Tony Stark" \
  --email "tony@stak.com" \
  --committer-name "Jarvis" \
  --committer-email "jarvis@stark.ai"
```

Neither repository-local nor global Git identity configuration is modified.
Commit-message `Co-authored-by:` trailers are unrelated and remain unchanged.

## Preserved and changed data

The operation reconstructs the resolved commit graph and verifies:

- identical file-tree IDs;
- identical commit messages;
- identical author and committer timestamps;
- identical parent topology after mapping rewritten parents; and
- the requested author and committer identities.

Empty and merge commits are preserved. Commit IDs necessarily change. Any
cryptographic commit signatures in the rewritten range are removed because
their signed objects no longer exist.

The start commit itself must not be a merge, because its first-parent boundary
would otherwise be ambiguous. Merge commits later in the range are supported.

## Local refs

By default, local branch tips that point to rewritten commits move with the
rewritten graph. The preview lists every affected ref. Use `--no-update-refs` to
move only the finish branch.

Tags and remote-tracking refs are never changed.

## Recovery

Before any reachable ref moves, the operation creates a ref like:

```text
refs/backup/author-rewrite-20260901-014500
```

Inspect recovery refs with:

```console
git for-each-ref \
  --format='%(refname) -> %(objectname:short)' \
  refs/backup/
```

`--no-backup` is available for callers that explicitly accept losing this
checkpoint. Dry runs never create one.

The operation changes local refs only. Review the result before publishing. A
published branch normally requires:

```console
git push --force-with-lease origin feature/foo
```

Backup listing, verification, restoration, and pruning are intentionally a
follow-up operation rather than hidden behavior in this rewrite path.
