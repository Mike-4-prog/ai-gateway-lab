# ARG for the Envoy base image
ARG ENVOY_IMAGE
ARG CARGO_ZBUILD_IMAGE=ghcr.io/rust-cross/cargo-zigbuild:0.19.8

# Stage 1: pull in all Rust build dependencies and cache them
FROM --platform=$TARGETPLATFORM ${CARGO_ZBUILD_IMAGE} AS rust_build_deps
WORKDIR /build
RUN apt update && apt install -y clang

# Corrected path to Rust source code (Option 1 layout)
ARG RUSTFORMATIONS_DIR=rustformations

# Copy top-level Cargo.toml files for caching dependencies
COPY ${RUSTFORMATIONS_DIR}/Cargo.toml ${RUSTFORMATIONS_DIR}/Cargo.lock ./

# Create dummy libraries to cache layer
RUN mkdir -p rustformations/src transformations/src \
    && echo "pub fn dummy() {}" > rustformations/src/lib.rs \
    && echo "pub fn dummy() {}" > transformations/src/lib.rs

# Copy local crates Cargo.toml files
COPY ${RUSTFORMATIONS_DIR}/transformations/Cargo.toml ./transformations

# Copy empty patched-envoy-sdk folder (needed by Dockerfile)
COPY ${RUSTFORMATIONS_DIR}/patched-envoy-sdk patched-envoy-sdk

# Build dummy fetch to populate cargo layer cache
ARG RUST_BUILD_ARCH=x86_64
RUN cargo fetch \
    && cargo zigbuild --target ${RUST_BUILD_ARCH}-unknown-linux-gnu \
    && find /build/target \( -name librust_module.so -o -name 'libtransformations*.rlib' \) -type f -delete

# Stage 2: build the envoy dynamic module
FROM --platform=$TARGETPLATFORM ${CARGO_ZBUILD_IMAGE} AS rust_builder
WORKDIR /build
RUN apt update && apt install -y clang

# Copy cached cargo and target directories from stage 1
COPY --from=rust_build_deps /usr/local/cargo /usr/local/cargo
COPY --from=rust_build_deps /build/target /build/target

# Copy Rust source code (Option 1 layout)
COPY rustformations .

# Build the real library
ARG RUST_BUILD_ARCH=x86_64
RUN cargo zigbuild --target ${RUST_BUILD_ARCH}-unknown-linux-gnu

# Copy compiled library to a common location
RUN cp /build/target/${RUST_BUILD_ARCH}-unknown-linux-gnu/debug/librust_module.so /build/librust_module.so

# Stage 3: build the final envoy wrapper image
FROM --platform=$TARGETPLATFORM ${ENVOY_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive

# Install OS dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y wget ca-certificates \
    && rm -rf /var/log/*log /var/lib/apt/lists/* /var/log/apt/* /var/lib/dpkg/*-old /var/cache/debconf/*-old

# Copy envoyinit binary
ARG GOARCH=amd64
COPY envoyinit-linux-$GOARCH /usr/local/bin/envoyinit

# Copy compiled Rust module
ENV ENVOY_DYNAMIC_MODULES_SEARCH_PATH=/usr/local/lib
COPY --from=rust_builder /build/librust_module.so /usr/local/lib/librust_module.so

# SDS-specific entrypoint
ARG ENTRYPOINT_SCRIPT=/docker-entrypoint.sh
COPY $ENTRYPOINT_SCRIPT /

# Use non-root user
USER 10101

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD []
