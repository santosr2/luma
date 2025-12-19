# Luma Distribution Files

This directory contains files for distributing Luma across different package managers and platforms.

## Contents

```text
dist/
├── homebrew/          # Homebrew formula
│   └── luma.rb
├── docker/            # Docker image
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── build.sh
└── README.md          # This file
```

---

## Homebrew Distribution

### Creating a Homebrew Tap

1. Create a GitHub repository named `homebrew-luma`
2. Copy the formula:

```bash
mkdir -p Formula
cp dist/homebrew/luma.rb Formula/
git add Formula/luma.rb
git commit -m "Add Luma formula"
git push origin main
```

1. Users can then install with:

```bash
brew tap santosr2/luma
brew install luma
```

### Updating the Formula

When releasing a new version:

1. Create a GitHub release and tarball
2. Calculate SHA256:

```bash
curl -L https://github.com/santosr2/luma/archive/v1.0.0.tar.gz | shasum -a 256
```

1. Update `luma.rb`:
   - Update `version`
   - Update `url`
   - Update `sha256`

1. Test the formula:

```bash
brew install --build-from-source dist/homebrew/luma.rb
brew test luma
brew audit --strict luma
```

### Publishing to Homebrew Core

To submit Luma to the main Homebrew repository:

1. Ensure the formula passes all audits
2. Fork `homebrew/homebrew-core`
3. Add the formula to `Formula/`
4. Submit a pull request

Requirements:

- Must be stable and well-maintained
- Must have a significant user base
- Must pass `brew audit --strict --online`

---

## Docker Distribution

### Building the Image

```bash
cd dist/docker
./build.sh 1.0.0
```

Or manually:

```bash
docker build -t luma/luma:1.0.0 -f dist/docker/Dockerfile .
docker tag luma/luma:1.0.0 luma/luma:latest
```

### Testing the Image

```bash
# Test version
docker run luma/luma:latest --version

# Test rendering
echo "Hello, \$name!" > /tmp/test.luma
docker run -v /tmp:/templates luma/luma:latest render test.luma --data '{"name":"World"}'

# Test with examples
docker run -v $(pwd)/examples:/templates luma/luma:latest render hello.luma
```

### Publishing to Docker Hub

1. Create an account at <https://hub.docker.com>
2. Create a repository: `luma/luma`
3. Login and push:

```bash
docker login
docker push luma/luma:1.0.0
docker push luma/luma:latest
```

### Publishing to GitHub Container Registry (GHCR)

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u santosr2 --password-stdin

# Tag for GHCR
docker tag luma/luma:1.0.0 ghcr.io/santosr2/luma:1.0.0
docker tag luma/luma:latest ghcr.io/santosr2/luma:latest

# Push
docker push ghcr.io/santosr2/luma:1.0.0
docker push ghcr.io/santosr2/luma:latest
```

### Docker Compose

Use the provided `docker-compose.yml` for local development:

```bash
cd dist/docker
docker-compose run luma render /examples/hello.luma
```

---

## GitHub Actions for Automated Publishing

### Docker Image Publishing

Create `.github/workflows/docker-publish.yml`:

```yaml
name: Publish Docker Image

on:
  release:
    types: [published]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Extract version
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: |
            luma/luma
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: dist/docker/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## LuaRocks Distribution

Luma is published to LuaRocks: <https://luarocks.org/modules/santosr2/luma>

### Publishing to LuaRocks

1. Create an account at <https://luarocks.org>
2. Get your API key from account settings
3. Upload the rockspec:

```bash
luarocks upload luma-1.0.0-1.rockspec --api-key=YOUR_API_KEY
```

### Automated Publishing via GitHub Actions

Add to `.github/workflows/release.yml`:

```yaml
- name: Publish to LuaRocks
  env:
    LUAROCKS_API_KEY: ${{ secrets.LUAROCKS_API_KEY }}
  run: |
    luarocks upload luma-${{ github.ref_name }}-1.rockspec --api-key=$LUAROCKS_API_KEY
```

---

## Testing Distributions

### Test Homebrew Formula

```bash
# Install from local formula
brew install --build-from-source dist/homebrew/luma.rb

# Test
luma --version
luma render examples/hello.luma

# Uninstall
brew uninstall luma
```

### Test Docker Image

```bash
# Build
docker build -t luma:test -f dist/docker/Dockerfile .

# Test
docker run luma:test --version
docker run -v $(pwd)/examples:/templates luma:test render hello.luma

# Cleanup
docker rmi luma:test
```

### Test LuaRocks Installation

```bash
# Install locally
luarocks make luma-1.0.0-1.rockspec

# Test
luma --version
lua -e "local luma = require('luma'); print(luma.render('Hello, \$name!', {name='Test'}))"

# Uninstall
luarocks remove luma
```

---

## Release Checklist

When preparing a new release:

- [ ] Update version in:
  - [ ] `luma/version.lua`
  - [ ] `luma-VERSION-1.rockspec`
  - [ ] `dist/homebrew/luma.rb`
  - [ ] `dist/docker/Dockerfile`
  - [ ] `CHANGELOG.md`
- [ ] Run all tests: `make test`
- [ ] Run all pre-commit checks: `pre-commit run -a`
- [ ] Create Git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
- [ ] Push tag: `git push origin v1.0.0`
- [ ] Create GitHub Release with release notes
- [ ] Build and push Docker image
- [ ] Upload to LuaRocks
- [ ] Update Homebrew formula with new SHA256
- [ ] Announce release on:
  - [ ] GitHub Discussions
  - [ ] Reddit (r/lua, r/devops)
  - [ ] Hacker News
  - [ ] Twitter/X

---

## Support

For issues with distributions:

- **GitHub Issues**: <https://github.com/santosr2/luma/issues>
- **Discussions**: <https://github.com/santosr2/luma/discussions>
