FROM ubuntu:24.04

ARG SWIFT_VERSION=6.0.3
ARG SWIFTLINT_VERSION=0.59.1

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        libncurses6 \
        libcurl4 \
        libatomic1 \
        python3 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
      "https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2404/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04.tar.gz" \
    | tar xz -C /opt \
    && mv "/opt/swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04" /opt/swift \
    && ln -sf /opt/swift/usr/bin/swift /usr/local/bin/swift \
    && ln -sf /opt/swift/usr/bin/swiftc /usr/local/bin/swiftc

RUN curl -fsSL \
      "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/swiftlint_linux.zip" \
      -o /tmp/swiftlint.zip \
    && unzip -q /tmp/swiftlint.zip -d /usr/local/bin \
    && rm /tmp/swiftlint.zip

USER ubuntu
