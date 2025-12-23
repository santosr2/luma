# Release Process for Luma

This document describes the standardized release process for Luma using `bump-my-version`.

## Prerequisites

```bash
# Install bump-my-version (if not already installed via mise)
pip install bump-my-version

# Ensure you're on main branch with clean working directory
git checkout main
git pull origin main
git status  # Should show clean
```

## Version Types

Luma follows [Semantic Versioning](https://semver.org/):
- **major**: Breaking changes (1.0.0 → 2.0.0)
- **minor**: New features, backwards compatible (0.1.0 → 0.2.0)
- **patch**: Bug fixes, backwards compatible (0.1.0 → 0.1.1)
- **prerelease**: Alpha, beta, rc releases (0.1.0 → 0.1.1-rc.1)

## Release Commands

### Pre-release (RC, Alpha, Beta)

For release candidates before final release:

```bash
# Create release candidate 1
bump-my-version bump prerelease --new-version 0.1.0-rc.1

# Create release candidate 2 (increment)
bump-my-version bump prerelease

# Create alpha release
bump-my-version bump prerelease --new-version 0.2.0-alpha.1

# Create beta release
bump-my-version bump prerelease --new-version 0.2.0-beta.1
```

### Stable Releases

```bash
# Patch release (0.1.0 → 0.1.1)
bump-my-version bump patch

# Minor release (0.1.1 → 0.2.0)
bump-my-version bump minor

# Major release (0.2.0 → 1.0.0)
bump-my-version bump major
```

## What Happens Automatically

When you run `bump-my-version bump <part>`:

1. **Version updates** in all files:
   - `luma/version.lua`
   - `bindings/python/pyproject.toml`
   - `bindings/python/luma/__init__.py`
   - `bindings/nodejs/package.json`
   - `bindings/go/lua/luma/version.lua`
   - `bindings/nodejs/lua/luma/version.lua`
   - `integrations/helm/plugin.yaml`
   - `tools/vscode-luma/package.json`
   - `dist/wasm/package.json`
   - `dist/docker/Dockerfile`
   - `dist/docker/build.sh`

2. **Git commit** created with message:
   ```
   chore: bump version {old} → {new}
   
   Signed-off-by: Your Name <your.email@example.com>
   ```

3. **Git tag** created:
   ```
   v{new_version}
   ```
   with message: `Bump version: {old} → {new}`

4. **Push to trigger release**:
   ```bash
   git push origin main --follow-tags
   ```

## GitHub Release Workflow

Once the tag is pushed, GitHub Actions automatically:

1. ✅ **Runs all tests** (Core, Python, Go, Node.js, Helm)
2. 📦 **Generates rockspec** dynamically (not version-controlled)
3. 📦 **Creates source tarball**
4. 📝 **Generates changelog** using git-cliff (from conventional commits)
5. 🚀 **Creates GitHub Release** with changelog and assets
6. 📦 **Publishes to LuaRocks** (stable releases only, skips rc/alpha/beta)
7. 📢 **Posts announcement**

## Pre-release vs Stable

**Pre-releases** (`-rc.X`, `-alpha.X`, `-beta.X`):
- ✅ GitHub Release created
- ✅ Source tarball available
- ❌ NOT published to LuaRocks
- Marked as "pre-release" on GitHub

**Stable releases** (e.g., `0.1.0`, `1.0.0`):
- ✅ GitHub Release created
- ✅ Source tarball available
- ✅ Published to LuaRocks
- Marked as "latest release" on GitHub

## Example: Full Release Flow

### Creating v0.1.0-rc.1

```bash
# Ensure clean state
git checkout main
git pull origin main
git status

# Create RC1
bump-my-version bump prerelease --new-version 0.1.0-rc.1
# Creates commit + tag v0.1.0-rc.1

# Push
git push origin main --follow-tags

# Monitor release at: https://github.com/santosr2/luma/actions
```

### After testing RC1, create v0.1.0 stable

```bash
# Remove pre-release suffix and create stable 0.1.0
bump-my-version bump patch --new-version 0.1.0
# Creates commit + tag v0.1.0

# Push
git push origin main --follow-tags

# This will:
# - Create GitHub Release
# - Publish to LuaRocks
# - Make available for: pip, npm, go get, helm plugin install
```

## Troubleshooting

### Bump Failed: "Working directory is not clean"

```bash
# Commit or stash changes first
git status
git add .
git commit -m "fix: your changes"
```

### Bump Failed: "Current version X does not match"

The version in `.bumpversion.toml` is out of sync:

```bash
# Check current version
grep "current_version" .bumpversion.toml

# Manually update if needed, then commit
```

### Tag Already Exists

```bash
# Delete local tag
git tag -d v0.1.0-rc.1

# Delete remote tag (if pushed)
git push origin :refs/tags/v0.1.0-rc.1

# Then retry bump command
```

### Release Workflow Failed

Check the GitHub Actions logs:
```bash
# View recent runs
gh run list --limit 5

# View specific run logs
gh run view <run-id> --log
```

## Best Practices

1. **Always test RC releases** before stable
2. **Update CHANGELOG.md** manually for major features (git-cliff supplements this)
3. **Use conventional commits** for automatic changelog generation:
   - `feat: add new feature`
   - `fix: resolve bug`
   - `docs: update documentation`
   - `chore: maintenance task`
4. **Never force-push tags** - delete and recreate instead
5. **Keep main branch stable** - all tests should pass before releasing

## Changelog Generation

The release workflow uses [git-cliff](https://git-cliff.org/) to automatically generate release notes from commit messages.

**Conventional Commit Format**:
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Examples**:
- `feat(nodejs): add TypeScript support`
- `fix(lexer): resolve hyphen concatenation bug`
- `docs: update installation guide`
- `perf(parser): optimize expression evaluation`

These are automatically grouped in the release notes:
- ✨ Features
- 🐛 Bug Fixes  
- 📚 Documentation
- ⚡ Performance
- etc.

## Version-Controlled vs Generated Files

**Version-Controlled**:
- All source code
- `CHANGELOG.md` (manually maintained for major releases)
- Version files (updated by bump-my-version)

**Generated (NOT version-controlled)**:
- `luma-*.rockspec` (created during release)
- `release_notes.md` (temporary, from git-cliff)
- Source tarballs

## Questions?

See also:
- `.bumpversion.toml` - bump-my-version configuration
- `.github/workflows/release.yml` - Release automation
- `cliff.toml` - Changelog generation config

