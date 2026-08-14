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
