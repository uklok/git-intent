# Architecture

Git Intent is a thin intent and safety layer over proven repository engines.

```text
human or agent intent
          |
          v
      Git Intent
recognize -> inspect -> preview -> checkpoint -> execute -> verify
          |
          v
best available engine
Git / git-filter-repo / git-revise / libgit2 / ...
          |
          v
      Git repository
```

## Operations

Each operation is a self-contained Agent Skill under `skills/`. Its `SKILL.md`
provides selection and safety instructions, `scripts/` contains the canonical
executable, and `references/` holds conditional technical context.

```text
skills/<operation>/
|-- SKILL.md
|-- README.md
|-- scripts/
|   `-- git-<operation>
`-- references/
    `-- ...
```

The README is human-facing packaging documentation. The skill entry point stays
compact and routes to references only when their details affect a decision.

The executable is the single implementation source. Human installation exposes
the same `git-<operation>` file on `PATH`, where Git discovers it as
`git <operation>`.

## Stable contracts, replaceable engines

An operation owns its CLI, preconditions, mutation boundary, recovery model,
and verified invariants. It does not promise a permanent internal engine.

The first operation, `git-fix-author`, uses Git plumbing to reconstruct commit
objects without changing file trees, the working tree, or the index. A future
engine change is acceptable only if it preserves or explicitly improves the
documented contract.

## No framework yet

The repository intentionally has no plugin system, shared core, engine adapter,
or meta-command. The second and third real operations should demonstrate a
shared need before common machinery is extracted.

## Distribution

The repository is a collection of independently useful Agent Skills. Existing
skill ecosystems can distribute them; Git Intent does not operate a separate
marketplace.
