# docker-openssl-fips-builder roadmap

> **Status: REFERENCE** · Owner: Software Department · Last verified: 2026-10-08
> Changes are proposed by docs-only PR.

## Mission

Build the FIPS OpenSSL provider image: the validated OpenSSL 3.1.2 `fips.so`.
Ship only the provider module, checksummed, for any OpenSSL 3.x host to install.
A build project owned by `agent-docker-openssl-fips-builder` in dept-software.

## Current milestone

None. No Gitea milestone is open; target kind RC, projected date not set.

## Now

- [#7](../../issues/7) deterministic trivy-image gate on a vulnerable image — blocked: labelled task:blocked
- [#13](../../issues/13) signed release artifacts (IS-14) — open
- [#14](../../issues/14) docs conformance: index and serena — open
- readiness: release artifacts signed before the first RC (#13) — open

## Next

- [#10](../../issues/10) decommissioned task-worker.yml removed from CI — open

## Later

Nothing accepted. New work arrives as issues.

## Dependencies

- Up: none; no go.mod, no in-house module pins.
- Down: hosts and images that install the released `fips.so` provider module.

## Non-goals

- A complete OpenSSL build or replacement of system OpenSSL libraries; see [ownership and SDK boundary](../handbook/software/docs/00-ownership-and-sdk-boundary.md).
- Any OpenSSL release other than a FIPS 140-3 validated one.
