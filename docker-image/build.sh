#!/bin/bash
# Build script for the Liquescent Development devcontainer base image

# Configuration
IMAGE_NAME="${IMAGE_NAME:-liquescent-development/devcontainer}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-ghcr.io}"

# Full image name
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building devcontainer base image..."
echo "Image: ${FULL_IMAGE_NAME}"

# Build the image
docker build \
  --build-arg TZ="${TZ:-UTC}" \
  --build-arg CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}" \
  --build-arg GIT_DELTA_VERSION="${GIT_DELTA_VERSION:-0.18.2}" \
  -t "${FULL_IMAGE_NAME}" \
  -f Dockerfile \
  .

if [ $? -eq 0 ]; then
  echo "✅ Build successful!"
  echo ""
  echo "To push to registry:"
  echo "  docker push ${FULL_IMAGE_NAME}"
  echo ""
  echo "To use in devcontainer.json:"
  echo "  \"image\": \"${FULL_IMAGE_NAME}\""
else
  echo "❌ Build failed!"
  exit 1
fi