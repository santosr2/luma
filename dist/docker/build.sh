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

# Get version from rockspec or default to 1.0.0
VERSION="${1:-1.0.0}"

# Change to repository root
cd "$(dirname "$0")/../.."

# Build the image
echo -e "\n${YELLOW}Building image: luma/luma:${VERSION}${NC}"
docker build \
    -t "luma/luma:${VERSION}" \
    -t "luma/luma:latest" \
    -f dist/docker/Dockerfile \
    .

echo -e "\n${GREEN}Build complete!${NC}"
echo "========================================"
echo "Images created:"
echo "  - luma/luma:${VERSION}"
echo "  - luma/luma:latest"
echo ""
echo "Test the image:"
echo "  docker run luma/luma:latest --version"
echo "  docker run -v \$(pwd):/templates luma/luma:latest render examples/hello.luma"
echo ""
echo "Push to Docker Hub:"
echo "  docker push luma/luma:${VERSION}"
echo "  docker push luma/luma:latest"
