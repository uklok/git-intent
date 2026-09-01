# Git semantics for attribution repair

Read this reference when evaluating or explaining edge cases in
`git-fix-author`.

## Why IDs change

A commit ID hashes the commit's tree, parents, author, committer, timestamps,
message, and other headers. Changing an identity creates a different object.
Descendants then change because they name the replaced parent ID.

This is object replacement, not evidence that file content changed.

## Inclusive range

For a non-root start, the boundary is the start commit's sole parent. Every
commit reachable from the finish branch but not from that parent is rebuilt.
This includes the start, finish, and merge-side commits within that graph.

For a root start, every commit reachable from the finish branch is rebuilt.

A merge commit cannot be the start because selecting one parent as the excluded
boundary would silently choose semantics the caller did not express. Merges
inside the resolved graph remain supported.

## Metadata

The operation changes author and committer names/emails. It preserves author and
committer timestamps, file-tree IDs, messages, empty commits, and mapped parent
topology.

Commit signatures authenticate the exact original object. They cannot survive
an identity change and are intentionally not copied. Message trailers such as
`Co-authored-by:` are message content and remain untouched.

## Ref scope

The finish local branch always moves. With the default `--update-refs`, other
local branches whose tips are reconstructed move atomically in the same ref
transaction. Tags, custom refs, and remote-tracking refs do not move.

Before that transaction, the original finish tip is stored under
`refs/backup/author-rewrite-*` unless `--no-backup` was explicit. A dry run does
not write any object or ref reachable from the repository.

## Publication

Local rewriting and remote publication are separate. A remote branch update may
require `--force-with-lease`; the operation prints guidance but never pushes.
