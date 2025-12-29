#!/usr/bin/env bash
# Build script for Luma Docker image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building Luma Docker Image${NC}"
echo "========================================"

# Get version from rockspec or default to 0.1.0
VERSION="${1:-0.1.0-rc.2}"
REGISTRY="${REGISTRY:-ghcr.io/santosr2}"

# Change to repository root
cd "$(dirname "$0")/../.."

# Build the image
echo -e "\n${YELLOW}Building image: ${REGISTRY}/luma:${VERSION}${NC}"
docker build \
    -t "${REGISTRY}/luma:${VERSION}" \
    -t "${REGISTRY}/luma:latest" \
    -f dist/docker/Dockerfile \
    .

echo -e "\n${GREEN}Build complete!${NC}"
echo "========================================"
echo "Images created:"
echo "  - ${REGISTRY}/luma:${VERSION}"
echo "  - ${REGISTRY}/luma:latest"
echo ""
echo "Test the image:"
echo "  docker run ${REGISTRY}/luma:latest --version"
echo "  docker run -v \$(pwd):/templates ${REGISTRY}/luma:latest render examples/hello.luma"
echo ""
echo "Push to GitHub Container Registry:"
echo "  docker push ${REGISTRY}/luma:${VERSION}"
echo "  docker push ${REGISTRY}/luma:latest"
