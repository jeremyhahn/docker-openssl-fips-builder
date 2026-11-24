# Build-time tool image, never deployed: root is required for package installs and loop devices.
FROM alpine:3.22

# Unpinned by design; apk upgrade picks up OpenSSL fixes the base layer lacks.
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
