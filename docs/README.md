**Status: CURRENT** | Last verified: 2026-10-09

# Documentation index

This repository produces a Docker image that builds the OpenSSL FIPS provider
module (`fips.so`) required for FIPS 140-3 compliance. The provider is built
from a pinned, validated OpenSSL release (see the root README for the pin and
its rationale) by `build-fips-provider.sh`, driven from the `Dockerfile` and
`Makefile`.

## Documents

- [README.md](../README.md) — what the image builds, the build configuration and
  the configure flags.
- [ROADMAP.md](../ROADMAP.md) — planned work.
- [CLAUDE.md](../CLAUDE.md) — agent and engineering rules for this repository.

## Standards

Company standards live in the handbook repository, checked out beside this one.
Start with the constitution,
`../handbook/software/docs/00-ownership-and-sdk-boundary.md`.
