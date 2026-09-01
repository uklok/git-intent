# Security Policy

Git Intent performs repository mutations, so safety defects can have an impact
beyond ordinary command-line failures.

## Report a vulnerability

Do not open a public issue for a vulnerability that could cause silent history
loss, unintended ref mutation, command injection, credential disclosure, or an
unsafe remote update.

Use the repository host's private vulnerability-reporting feature. If that is
not enabled, contact the maintainers privately through an address listed on the
repository profile. Include:

- the affected operation and version or commit;
- the smallest safe reproduction;
- the expected and observed mutation boundary;
- whether a recovery ref was created; and
- any known workaround.

Do not include real credentials or sensitive repository contents.

## Supported versions

Until the first tagged release, only the current default branch receives
security fixes. This policy will be updated when versioned releases begin.

## Safety is not recovery

Keep independent backups of valuable repositories. Recovery refs reduce risk,
but they are stored inside the same object database and are not a substitute
for an external backup or remote copy.
