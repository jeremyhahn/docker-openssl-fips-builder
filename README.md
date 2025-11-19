# OpenSSL FIPS Provider Builder

This Docker container builds the OpenSSL FIPS provider module (`fips.so`) that is required for FIPS 140-3 compliance.


## Build Configuration

The FIPS provider is built with:

- OpenSSL 3.4.1 (configurable via `OPENSSL_VERSION`)
- `--prefix=/usr` (NOT `/usr/local`)
- `--libdir=lib` (NOT `lib64`)
- `--openssldir=/etc/ssl`
- `enable-fips`
- Security hardening: `no-ssl3`, `no-weak-ssl-ciphers`, `OPENSSL_TLS_SECURITY_LEVEL=2`

## Usage

Build the FIPS provider module:

```bash
make build
```

This will:
1. Build the Docker image
2. Run the container to build the FIPS provider
3. Extract `fips.so` to `output/`
4. Create SHA256 checksum

Clean build artifacts:

```bash
make clean
```

Test the built module:

```bash
make test
```

## Output

After building, you'll find in `output/`:

- `fips.so` - The FIPS provider module
- `fips.so.sha256` - SHA256 checksum
- `openssl-version.txt` - OpenSSL version used
