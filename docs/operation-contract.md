# Operation Contract

Every mutating Git Intent operation should implement these stages:

1. preflight;
2. resolution;
3. preview;
4. checkpoint;
5. execution;
6. verification; and
7. recovery and publishing guidance.

An operation's documentation must state which guarantees are unconditional,
which depend on the selected engine, and which cases are unsupported.

## Safety principles

A mutating operation must not silently:

- discard working-tree or index changes;
- delete user branches;
- modify repository, worktree, or global Git identity configuration;
- force-push;
- remove recovery data;
- broaden its requested history range; or
- mutate unrelated refs.

The operation must fail before mutation when it cannot establish its documented
preconditions. Error messages should identify the violated precondition and a
safe next action.

## Dry runs

When technically possible, a mutating operation must provide a read-only
preview.

A dry run must not create backup refs, modify refs, rewrite reachable commits,
alter configuration, or change the working tree or index. It should resolve the
same intent and report the same mutation scope as execution.

## Checkpoints

History-rewriting operations should establish a native Git recovery point
before mutating a reachable ref. Native Git refs are preferred over external
bookkeeping where practical.

The checkpoint name and target must be reported to the caller. Omitting a
checkpoint requires an explicit option; it must never be inferred from
non-interactive execution.

## Verification

Success is defined by the operation's promised invariants, not only by the exit
status of its underlying engine.

Verification should compare the resolved pre-operation objects with the final
objects. If an invariant fails after mutation, the operation must report the
failure, retain the recovery point, and avoid publishing changes.

## Recovery and publishing

Local mutation and remote publication are separate actions.

An operation must not publish or force-update remote history unless that is the
operation's explicit, separately authorized purpose. A history rewrite should
provide recovery and `--force-with-lease` guidance without performing either
action automatically.

## Engines

Git Intent does not require operations to reproduce capabilities already
provided reliably elsewhere. An operation may use:

- Git;
- `git-filter-repo`;
- `git-revise`;
- libgit2; or
- another established tool.

Interfaces should remain stable while engines remain replaceable. The selected
engine is an implementation detail unless it materially changes safety,
semantics, portability, or recovery.
