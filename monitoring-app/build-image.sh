#!/bin/bash

set -Eeuo pipefail

# Image to build. Update this once the target Quay namespace is settled; the demo is
# currently running quay.io/mregan/*-arm64 images.
IMAGE="${IMAGE:-quay.io/mregan/train-monitoring-app-arm64}"
TAG="${TAG:-latest}"
PLATFORM="${PLATFORM:-linux/arm64/v8}"

# Maven runs in a container so that no JDK or Maven install is needed on the host.
# A JDK image is enough because this repository ships a working .mvn/wrapper.
JDK_IMAGE="${JDK_IMAGE:-docker.io/library/eclipse-temurin:17-jdk}"
M2_DIR="${M2_DIR:-$HOME/.m2}"

cd "$(dirname "$0")"

# Cache dependencies between runs, otherwise every build re-downloads the world.
mkdir -p "$M2_DIR"

echo "Packaging with $JDK_IMAGE ..."
podman run --rm \
    -v "$PWD":/project:z \
    -v "$M2_DIR":/root/.m2:z \
    -w /project \
    "$JDK_IMAGE" ./mvnw -B clean package

podman build -f src/main/docker/Dockerfile.jvm -t "quarkus/train-monitoring-app-jvm" --platform "$PLATFORM" .
podman tag "quarkus/train-monitoring-app-jvm:latest" "${IMAGE}:${TAG}"

echo "Built ${IMAGE}:${TAG}"

# Pushing is opt-in so that running this script cannot publish by accident.
if [ "${PUSH:-0}" = "1" ]; then
    podman push "${IMAGE}:${TAG}"
    echo "Pushed ${IMAGE}:${TAG}"
else
    echo "Not pushed. Re-run with PUSH=1 to publish."
fi
