# DS-0002 ACCEPTED RISK (owner ruling 2026-08-20): this is a BUILD-TIME tool
# image — it installs distro packages and produces artifacts, is never deployed
# as a service, and never faces traffic. Root is required for package installs
# and device/loop operations; a USER directive would break the build for no
# runtime benefit. Re-evaluate only if this image ever becomes a runtime image.
FROM alpine:3.22

# Install build dependencies.
# Versions are deliberately unpinned: devops.md §9 wants builder images on the
# latest available packages, and a pinned apk set goes stale silently.
# hadolint ignore=DL3018
RUN apk add --no-cache \
    build-base \
    perl \
    linux-headers \
    wget \
    bash \
    ca-certificates

# Set working directory
WORKDIR /build

# Copy build script
COPY build-fips-provider.sh /build/
RUN chmod +x /build/build-fips-provider.sh

# Set entrypoint
ENTRYPOINT ["/build/build-fips-provider.sh"]
