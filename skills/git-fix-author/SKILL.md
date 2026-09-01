---
name: git-fix-author
description: Safely repair Git commit author or committer attribution across an existing history range. Use when commits have the wrong author name or email, a bot or operator identity was recorded incorrectly, or multiple existing commits need attribution corrected. Do not use for message edits, squashing, splitting, secret removal, or new commits.
---

# Git Fix Author

Use the bundled `scripts/git-fix-author` executable for a bounded attribution
repair. Do not improvise an equivalent rebase while this operation satisfies the
request.

## Workflow

1. Confirm that rewriting published history is acceptable and identify the
   inclusive start commit and local finish branch.
2. Preserve unrelated user work. The executable rejects a dirty repository; do
   not silently stash, reset, or discard changes to bypass that precondition.
3. Inspect `scripts/git-fix-author --help` and run `--dry-run` with the intended
   author and, only when explicitly requested, separate committer values.
4. Review the resolved objects, commit count, identities, and local refs that
   will move.
5. Obtain authorization immediately before mutation. For deterministic
   automation, add `--non-interactive --yes` only after reviewing the preview.
6. Report the new tip and recovery ref. Keep remote publication separate; if
   needed, recommend `git push --force-with-lease`, never silently push.

By default the committer identity matches the requested author so the executing
machine's configured identity cannot leak into rewritten commits. Use
`--committer-name` and `--committer-email` only when a distinct committer was
requested.

Changing commit metadata necessarily changes commit IDs and therefore the IDs
of descendants. Signed commits in the range lose their invalidated signatures.

Read [references/git-semantics.md](references/git-semantics.md) when explaining
object identity, range/topology behavior, local ref updates, signatures, or
recovery. Human installation and complete CLI examples are in
[README.md](README.md).

Do not use this operation to change commit messages or contents, rewrite
trailers, reorder/squash/split commits, remove secrets, or repair ordinary new
commits.
