# DS-0002 ACCEPTED RISK (owner ruling 2026-08-20): this is a BUILD-TIME tool
# image — it installs distro packages and produces artifacts, is never deployed
# as a service, and never faces traffic. Root is required for package installs
# and device/loop operations; a USER directive would break the build for no
# runtime benefit. Re-evaluate only if this image ever becomes a runtime image.
FROM alpine:3.22

# Install build dependencies.
# Versions are deliberately unpinned: devops.md §9 wants builder images on the
# latest available packages, and a pinned apk set goes stale silently.
#
# `apk upgrade` is load-bearing, not tidiness. libcrypto3 and libssl3 ship IN
# the alpine base layer, and `apk add` does not upgrade a package that is
# already present -- so without this the image inherits whatever OpenSSL the
# base was built with. As of 2026-09-06 that is 3.5.7-r0 with CVE-2026-14456
# (HIGH) outstanding, while v3.22/main already serves the fixed 3.5.8-r0. No
# published Alpine tag carries the fix (3.22, 3.23, latest and edge all ship
# 3.5.7-r0), so `docker build --pull` does not help either: upgrading at build
# time is the only route. Owner ruling 2026-09-06, issue #8, measurements on #7.
# hadolint ignore=DL3018
RUN apk upgrade --no-cache && \
    apk add --no-cache \
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
