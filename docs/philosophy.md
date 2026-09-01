# Philosophy

Git Intent exists for Git jobs whose desired outcome fits in a sentence while
their safe implementation takes a page.

## Express the intent, not the surgery

Git exposes excellent low-level primitives. Those primitives do not always form
a single safe command for higher-level maintenance tasks. Git Intent names that
outcome, resolves it to concrete objects, previews the scope, creates a recovery
point, performs the bounded mutation, and verifies its promises.

The caller should need to understand the consequence of an operation, not
reconstruct its internal command sequence.

## Scope is a safety feature

An operation belongs in Git Intent when:

1. its intent is common;
2. its raw Git procedure is non-trivial or risky; and
3. its behavior can be given a clear safety and recovery contract.

That makes author repair, lost-commit recovery, or bounded history movement
plausible operations. It does not justify wrappers for `git status`, `git add`,
`git log`, or other ordinary Git commands.

## Recovery is product surface

Mistakes and changed minds are normal operational conditions. Recovery should
be visible, inspectable, and built into mutating workflows rather than hidden in
a warning or left to reflog expertise.

## Agent-native, not agent-dependent

Every capability should be useful from a human terminal. A narrow Agent Skill
helps an agent recognize the intent, gather the required inputs, preview the
operation, and invoke the reviewed executable. It should not teach the agent to
improvise equivalent history surgery.

The agent chooses the operation. The operation owns the surgery.

## Stand on mature abstractions

We prefer climbing on mature abstractions to boiling the same water again.

Dependencies are judged by correctness, maintenance, portability, and
safety—not by whether we could reproduce their behavior ourselves. When native
Git is the right engine, use it. When another maintained tool provides stronger
semantics, integrate it transparently.

## Let real operations shape the project

Git Intent is deliberately not beginning with a framework or an invented
catalogue of commands. The first operation establishes the contract. Later
operations should reveal which abstractions are genuinely shared.
