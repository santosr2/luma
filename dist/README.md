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
curl -L https://github.com/santosr2/luma/archive/v0.1.0.tar.gz | shasum -a 256
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
./build.sh 0.1.0
```

Or manually:

```bash
docker build -t ghcr.io/santosr2/luma:0.1.0 -f dist/docker/Dockerfile .
docker tag ghcr.io/santosr2/luma:0.1.0 ghcr.io/santosr2/luma:latest
```

### Testing the Image

```bash
# Test version
docker run ghcr.io/santosr2/luma:latest --version

# Test rendering
echo "Hello, \$name!" > /tmp/test.luma
docker run -v /tmp:/templates ghcr.io/santosr2/luma:latest render test.luma --data '{"name":"World"}'

# Test with examples
docker run -v $(pwd)/examples:/templates ghcr.io/santosr2/luma:latest render hello.luma
```

### Publishing to GitHub Container Registry (GHCR)

Luma images are published to GitHub Container Registry and are publicly available.

**Pull the image:**

```bash
docker pull ghcr.io/santosr2/luma:latest
docker pull ghcr.io/santosr2/luma:0.1.0
```

**Manual publishing** (automated via GitHub Actions):

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u santosr2 --password-stdin

# Build and tag
docker build -t ghcr.io/santosr2/luma:0.1.0 -f dist/docker/Dockerfile .
docker tag ghcr.io/santosr2/luma:0.1.0 ghcr.io/santosr2/luma:latest

# Push
docker push ghcr.io/santosr2/luma:0.1.0
docker push ghcr.io/santosr2/luma:latest
```

### Docker Compose

Use the provided `docker-compose.yml` for local development:

```bash
cd dist/docker
docker-compose run luma render /examples/hello.luma
```

The compose file automatically uses the GitHub Container Registry image.

---

## GitHub Actions for Automated Publishing

### Docker Image Publishing

The repository includes `.github/workflows/docker-publish.yml` for automated publishing to
GitHub Container Registry.

**Key features:**

- Automatically publishes on releases
- Multi-architecture support (amd64, arm64)
- Semantic versioning tags (0.1.0, 0.1, latest)
- Build caching for faster builds
- Automated testing of published images

**No secrets required** - uses `GITHUB_TOKEN` which is automatically provided by GitHub Actions.

The workflow can also be triggered manually from the Actions tab for testing.

---

## LuaRocks Distribution

Luma is published to LuaRocks: <https://luarocks.org/modules/santosr2/luma>

### Publishing to LuaRocks

1. Create an account at <https://luarocks.org>
2. Get your API key from account settings
3. Upload the rockspec:

```bash
luarocks upload luma-0.1.0.rockspec --api-key=YOUR_API_KEY
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
docker build -t ghcr.io/santosr2/luma:test -f dist/docker/Dockerfile .

# Test
docker run ghcr.io/santosr2/luma:test --version
docker run -v $(pwd)/examples:/templates ghcr.io/santosr2/luma:test render hello.luma

# Cleanup
docker rmi ghcr.io/santosr2/luma:test
```

### Test LuaRocks Installation

```bash
# Install locally
luarocks make luma-0.1.0.rockspec

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
- [ ] Create Git tag: `git tag -a v0.1.0 -m "Release v0.1.0"`
- [ ] Push tag: `git push origin v0.1.0`
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
