# Git Intent

> **Express the Git intent, not the surgery.**

Git Intent is a community-maintained collection of safe, deterministic, and
recovery-aware Git operations for humans and AI agents.

Git already gives us excellent primitives. The difficult part is that many
simple intentions still require surprisingly fragile combinations of those
primitives:

- correct attribution across existing commits;
- recover lost work;
- move a history range safely;
- repair refs;
- rewrite sensitive history; and
- unwind an incorrect operation.

Humans repeatedly reconstruct these procedures from memory and documentation.
Coding agents repeatedly spend context and tokens reasoning through the same
operations—and can still improvise the wrong sequence.

Git Intent captures proven solutions once.

Instead of expressing the surgery:

```console
git rebase ...
git commit --amend ...
git update-ref ...
```

express the intent:

```console
git fix-author \
  --start fix/author \
  --finish feature/foo \
  --name "AIPAL" \
  --email "aipal@uklok.ai"
```

Every mutating operation follows the same model:

```text
preflight
  -> resolve
  -> preview
  -> checkpoint
  -> execute
  -> verify
  -> recover
```

## Built on what already works

Git Intent is not another version-control system, branch-management philosophy,
or generalized Git wrapper. It does not replace Git's plumbing.

When Git, `git-filter-repo`, `git-revise`, libgit2, or another established
project already solves the underlying problem reliably, Git Intent can build on
that work. Engines are implementation details unless they materially change an
operation's safety or semantics.

The value of Git Intent lives at the boundary between **intent and safe
execution**.

## Humans and agents share the same tools

Operations are ordinary command-line tools first. Agent Skills package those
same reviewed executables with enough context for an agent to recognize when to
use them.

> **The agent chooses the operation. The operation owns the surgery.**

This reduces improvisation without creating an agent-only Git abstraction.

## Install `git fix-author`

Install the reference operation somewhere on `PATH`:

```console
install -m 0755 \
  skills/git-fix-author/scripts/git-fix-author \
  "$HOME/.local/bin/git-fix-author"
```

Git discovers executables named `git-<command>`, so the installed program is
available as either `git-fix-author` or `git fix-author`.

Preview an inclusive rewrite range:

```console
git fix-author \
  --start fix/author \
  --finish feature/foo \
  --name "AIPAL" \
  --email "aipal@uklok.ai" \
  --dry-run
```

Read [the operation guide](skills/git-fix-author/README.md) for behavior,
limitations, recovery, and automation examples.

## Project documents

- [Philosophy](docs/philosophy.md)
- [Architecture](docs/architecture.md)
- [Operation contract](docs/operation-contract.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Develop and verify

The test suite creates disposable repositories and proves the promised history
invariants:

```console
scripts/test
scripts/validate-skills
```

ShellCheck and shfmt are used in CI when available locally:

```console
shellcheck scripts/test scripts/validate-skills \
  skills/git-fix-author/scripts/git-fix-author \
  tests/git-fix-author/test.sh

shfmt -d -i 2 -ci \
  scripts/test scripts/validate-skills \
  skills/git-fix-author/scripts/git-fix-author \
  tests/git-fix-author/test.sh
```

## Status

`git-fix-author` is the first reference implementation of the Git Intent
operation contract. New operations should start from a real, repeatable Git
problem whose intent is simple but whose safe execution requires careful work.

Git Intent is licensed under the [MIT License](LICENSE).
