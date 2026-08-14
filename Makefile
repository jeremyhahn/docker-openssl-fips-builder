# OpenSSL FIPS Provider Builder
#
# Builds the OpenSSL FIPS 140-3 provider module inside a container.

# DOCUMENTED PIN (devops.md §9): the FIPS provider must be built from a
# FIPS 140-3 *validated* OpenSSL release. 3.1.2 is the validated one
# (certificate #4985). Do NOT raise this to track the latest OpenSSL — a newer
# release is not validated, and the fips.so it produces would not be FIPS
# compliant. §9's "latest everything" does not apply here: the validation IS
# the artifact. The base image and its packages do track latest.
OPENSSL_FIPS_VERSION ?= 3.1.2
OUTPUT_DIR ?= $(PWD)/output
DOCKER_IMAGE ?= openssl-fips-provider-builder
BUILD_CONTAINER ?= openssl-fips-provider-build
FIPS_MODULE := $(OUTPUT_DIR)/usr/lib/ossl-modules/fips.so

# Minimum plausible size for the module; a truncated build is caught here.
FIPS_MODULE_MIN_BYTES := 1000000

.PHONY: all build test lint image-scan fs-scan security clean

all: build

image:
	docker build -t $(DOCKER_IMAGE) .

# Artifacts are copied out of a stopped container rather than bind-mounted.
# A bind mount source is resolved by the docker DAEMON, not the client, so in
# CI — where the job itself runs inside a container sharing the host's docker
# socket — the workspace path does not exist for the daemon and `docker run`
# dies with exit 125. `docker cp` streams through the API and extracts on the
# client side, so it lands in the workspace on every host.
build: image
	@echo "Building OpenSSL FIPS provider module..."
	@docker rm -f $(BUILD_CONTAINER) >/dev/null 2>&1 || true
	docker run --name $(BUILD_CONTAINER) \
		-e OPENSSL_FIPS_VERSION=$(OPENSSL_FIPS_VERSION) \
		$(DOCKER_IMAGE)
	@rm -rf $(OUTPUT_DIR)
	@mkdir -p $(OUTPUT_DIR)
	docker cp $(BUILD_CONTAINER):/output/. $(OUTPUT_DIR)/
	@docker rm $(BUILD_CONTAINER) >/dev/null
	@echo ""
	@echo "Build complete. Artifacts in: $(OUTPUT_DIR)"
	@ls -lh $(FIPS_MODULE)

test:
	@echo "Testing FIPS provider module..."
	@if [ ! -f "$(FIPS_MODULE)" ]; then \
		echo "ERROR: FIPS module not found at $(FIPS_MODULE). Run 'make build' first."; \
		exit 1; \
	fi
	@echo "✓ FIPS module exists: $(FIPS_MODULE)"
	@SIZE=$$(stat -c %s "$(FIPS_MODULE)"); \
	echo "Size: $$SIZE bytes"; \
	if [ "$$SIZE" -lt $(FIPS_MODULE_MIN_BYTES) ]; then \
		echo "ERROR: FIPS module is implausibly small ($$SIZE bytes)"; \
		exit 1; \
	fi
	@echo "✓ FIPS module size is plausible"
	@cd $(OUTPUT_DIR) && sha256sum -c fips.so.sha256
	@echo "✓ SHA256 checksum verified"
	@echo "Built from OpenSSL $$(cat $(OUTPUT_DIR)/openssl-fips-version.txt)"

# Linters are piped their input on stdin: a `-v $(PWD):/mnt` bind mount fails
# in CI for the same daemon-path reason documented on the build target.
lint:
	@echo "Linting Dockerfile (hadolint)..."
	docker run --rm -i hadolint/hadolint:latest \
		hadolint --failure-threshold warning - < Dockerfile
	@echo "Linting shell scripts (shellcheck)..."
	docker run --rm -i koalaman/shellcheck:stable \
		--severity=warning - < build-fips-provider.sh

# devops.md §8. The Go suite (gosec, govulncheck, go mod verify, golangci-lint)
# has no analogue here — this repo contains no Go code — so the gate is the
# Dockerfile/shell linters plus both trivy scans.
fs-scan:
	@echo "Scanning source tree (trivy fs)..."
	trivy fs --scanners vuln,secret \
		--severity CRITICAL,HIGH --exit-code 1 .

# --ignore-unfixed is ratified for IMAGE scans only (devops.md §8): base images
# carry unfixable distro advisories at any moment, so a raw gate is permanently
# red. The fs scan above deliberately does NOT use it.
image-scan: image
	@echo "Scanning image (trivy image)..."
	trivy image --scanners vuln,secret \
		--severity CRITICAL,HIGH --ignore-unfixed --exit-code 1 $(DOCKER_IMAGE)

security: lint fs-scan image-scan
	@echo "✓ Security suite passed"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)
	@docker rm -f $(BUILD_CONTAINER) >/dev/null 2>&1 || true
	@docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
