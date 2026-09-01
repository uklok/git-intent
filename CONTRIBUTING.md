# Contributing to Git Intent

Thank you for helping make risky Git work more predictable.

## Begin with the intent

Before proposing code, describe the outcome without prescribing commands. An
operation belongs in Git Intent when its intent is common, its raw Git procedure
is non-trivial or risky, and it can have explicit safety and recovery semantics.

Use the **Propose an operation** issue form. Identify existing tools before
designing a new engine. Building on maintained software is encouraged when it
improves correctness or safety.

## Operation requirements

New mutating operations must follow the
[operation contract](docs/operation-contract.md). A proposal should define:

- its exact mutation boundary;
- preconditions and unsupported cases;
- a read-only preview when technically possible;
- a recovery model;
- verification invariants;
- behavior in non-interactive environments; and
- how local mutation remains separate from remote publication.

Each operation should remain independently useful and have precise Agent Skill
discovery metadata. Avoid broad Git tutorials or catch-all skills.

## Development

Run the repository checks before opening a pull request:

```console
scripts/test
scripts/validate-skills
```

If ShellCheck and shfmt are installed, also run the lint commands documented in
the [README](README.md#develop-and-verify).

Tests for a mutating operation should create isolated disposable repositories
and verify behavior, not implementation wording. At minimum, cover dry-run
purity, rejection paths, promised history invariants, checkpoint reachability,
identity configuration isolation, and non-interactive behavior.

## Pull requests

Keep changes bounded to one intent. Explain the safety contract and evidence
from tests. Call out any engine-dependent limitation or changed recovery
behavior explicitly.

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
