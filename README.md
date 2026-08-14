# OpenSSL FIPS Provider Builder

This Docker container builds the OpenSSL FIPS provider module (`fips.so`) that
is required for FIPS 140-3 compliance.

## Build Configuration

The FIPS provider is built from **OpenSSL 3.1.2**, configurable via
`OPENSSL_FIPS_VERSION`.

That version is a deliberate, documented pin, not staleness. The provider must
come from a FIPS 140-3 **validated** OpenSSL release — 3.1.2 holds certificate
#4985 — and a newer OpenSSL is not validated, so a `fips.so` built from it
would not be FIPS compliant. The resulting module is compatible with any
OpenSSL 3.x (3.0 through 3.5+), which is why the pin costs nothing: the system
keeps its own current OpenSSL libraries and only the validated provider module
is installed.

Configure flags:

- `--prefix=/usr` (NOT `/usr/local`)
- `--libdir=lib` (NOT `lib64`)
- `--openssldir=/etc/ssl`
- `enable-fips`
- Security hardening: `no-ssl3`, `no-weak-ssl-ciphers`,
  `OPENSSL_TLS_SECURITY_LEVEL=2`

## Why only the provider module

This build produces **only** `fips.so`, never a complete OpenSSL. That is a
deliberate compliance decision, and it is what makes the version pin above
cost-free. Per the official OpenSSL FIPS documentation:

- The FIPS provider module built from OpenSSL 3.1.2 is the FIPS 140-3
  validated one.
- That module is compatible with **any** OpenSSL 3.x version (3.0 through
  3.5+).
- The system's own OpenSSL libraries must **not** be replaced. Only the
  validated `fips.so` is copied onto the system.

Doing it this way keeps both properties that matter at once: FIPS compliance,
because the provider is the validated 3.1.2 build; and symbol compatibility,
because the system keeps its own current OpenSSL libraries. Replacing the
system libraries with 3.1.2 would buy nothing and break the second property.

This is the approach upstream officially supports:

- <https://github.com/openssl/openssl/blob/master/README-FIPS.md>
- <https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4985>
- <https://openssl-library.org/post/2025-03-11-fips-140-3/>

> "You can build openssl-3.5.0, then build openssl-3.1.2, and simply copy the
> fips.so module from your openssl-3.1.2 tree into the openssl-3.5.0 tree"

## Usage

Build the FIPS provider module:

```bash
make build
```

This will:

1. Build the Docker image
2. Run the container to build the FIPS provider
3. Copy the artifacts out of the container into `output/`
4. Create a SHA256 checksum

Verify the built module — checks the module exists, is a plausible size, and
matches its recorded checksum:

```bash
make test
```

Run the security suite (Dockerfile and shell linting, plus both Trivy scans —
`conventions/devops.md` §8):

```bash
make security
```

Clean build artifacts:

```bash
make clean
```

## Output

After building, `output/` contains:

- `usr/lib/ossl-modules/fips.so` — the FIPS provider module, laid out at its
  install path
- `fips.so.sha256` — SHA256 checksum, verified by `make test`
- `openssl-fips-version.txt` — the validated OpenSSL version it was built from
- `README.txt` — installation instructions generated at build time

## Installing the module

1. Install the system OpenSSL package
2. Copy `fips.so` to `/usr/lib/ossl-modules/fips.so`
3. Run
   `openssl fipsinstall -out /etc/ssl/fipsmodule.cnf -module /usr/lib/ossl-modules/fips.so`
4. Configure OpenSSL to use the FIPS provider in `/etc/ssl/openssl.cnf`

## Notes for CI

Artifacts are copied out of a stopped container with `docker cp` rather than
bind-mounted. Bind mount sources are resolved by the docker *daemon*, so in CI
— where the job itself runs in a container sharing the host's docker socket —
a workspace path does not exist for the daemon and `docker run` fails with
exit 125. `docker cp` works on every host, and as a bonus leaves the artifacts
owned by the invoking user instead of root.
