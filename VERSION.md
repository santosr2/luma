# Version Management with bump-my-version

Luma uses [`bump-my-version`](https://github.com/callowayproject/bump-my-version) to manage
versions across all packages and bindings.

## Installation

```bash
pip install bump-my-version
```

## Current Version

The current version is **0.1.0**.

## Version Format

Luma follows [Semantic Versioning](https://semver.org/):

```text
MAJOR.MINOR.PATCH[-PRERELEASE]
  0  .  1  .  0   [-alpha]
```

## Bumping Versions

### Stable Releases

```bash
# Patch release (0.1.0 → 0.1.1)
bump-my-version bump patch

# Minor release (0.1.0 → 0.2.0)
bump-my-version bump minor

# Major release (0.1.0 → 1.0.0)
bump-my-version bump major
```

### Pre-releases

```bash
# Create alpha pre-release (0.1.0 → 0.2.0-alpha)
bump-my-version bump minor --new-version 0.2.0-alpha

# Bump alpha to beta (0.2.0-alpha → 0.2.0-beta)
bump-my-version bump pre_l

# Bump to release candidate (0.2.0-beta → 0.2.0-rc)
bump-my-version bump pre_l

# Finalize release (0.2.0-rc → 0.2.0)
bump-my-version bump pre_l
```

### Pre-release with numbers

```bash
# Create numbered pre-release (0.1.0 → 0.2.0-alpha.1)
bump-my-version bump minor --new-version 0.2.0-alpha.1

# Increment pre-release number (0.2.0-alpha.1 → 0.2.0-alpha.2)
bump-my-version bump pre_n
```

## What Gets Updated

The tool automatically updates versions in:

✅ **Core Lua**:

- `luma/version.lua`

✅ **Python Bindings**:

- `bindings/python/pyproject.toml`
- `bindings/python/luma/__init__.py`

✅ **Node.js Bindings**:

- `bindings/nodejs/package.json`
- `bindings/nodejs/lua/luma/version.lua` (embedded)

✅ **Go Bindings**:

- `bindings/go/lua/luma/version.lua` (embedded)
- Git tag: `v{version}`

✅ **Integrations**:

- `integrations/helm/plugin.yaml`

✅ **Tools**:

- `tools/vscode-luma/package.json`

✅ **Distribution**:

- `dist/wasm/package.json`
- `dist/docker/Dockerfile`
- `dist/docker/build.sh`

## LuaRocks Rockspec

The rockspec file requires manual handling due to its `-1` suffix:

```bash
# After bumping version
OLD_VERSION="0.1.0"
NEW_VERSION="0.2.0"

# Rename rockspec
mv luma-$OLD_VERSION-1.rockspec luma-$NEW_VERSION-1.rockspec

# Update version and tag in the new rockspec
sed -i '' "s/version = \"$OLD_VERSION-1\"/version = \"$NEW_VERSION-1\"/" luma-$NEW_VERSION-1.rockspec
sed -i '' "s/tag = \"v$OLD_VERSION\"/tag = \"v$NEW_VERSION\"/" luma-$NEW_VERSION-1.rockspec

# Stage the changes
git add luma-$NEW_VERSION-1.rockspec
git rm luma-$OLD_VERSION-1.rockspec
git commit --amend --no-edit --no-gpg-sign
```

Or use the provided script:

```bash
./scripts/update-rockspec.sh 0.2.0
```

## Workflow

### Standard Release

```bash
# 1. Bump version (also commits and tags)
bump-my-version bump minor  # or patch, major

# 2. Update rockspec
./scripts/update-rockspec.sh $(grep current_version .bumpversion.toml | cut -d'"' -f2)

# 3. Push changes and tag
git push origin main
git push origin --tags
```

### Pre-release

```bash
# 1. Create pre-release
bump-my-version bump minor --new-version 0.2.0-alpha

# 2. Update rockspec
./scripts/update-rockspec.sh 0.2.0-alpha

# 3. Push
git push origin main
git push origin --tags
```

## Configuration

All version configuration is in `.bumpversion.toml`.

Key settings:

- `current_version`: Current version (auto-updated)
- `parse`: Regex to parse version strings
- `serialize`: How to format version strings
- `tag_name`: Git tag format (`v{new_version}`)
- `message`: Commit message format
- `commit_args`: Git commit flags (`--signoff --no-gpg-sign`)

## Checking Current Version

```bash
# From bumpversion config
grep current_version .bumpversion.toml

# From Lua code
lua -e "print(require('luma.version').string)"

# From Python
python -c "import luma; print(luma.__version__)"

# From Node.js
node -e "console.log(require('./bindings/nodejs/package.json').version)"

# From CLI
luma --version
```

## Dry Run

Test version bump without making changes:

```bash
bump-my-version bump minor --dry-run --verbose
```

## Troubleshooting

### "Working directory is not clean"

Commit or stash changes before bumping:

```bash
git status
git add -A
git commit --signoff --no-gpg-sign -m "your changes"
```

Or allow dirty working directory:

```bash
bump-my-version bump minor --allow-dirty
```

### Version mismatch errors

Run the version consistency check:

```bash
pre-commit run check-version-consistency --all-files
```

### Undo a bump

If you haven't pushed yet:

```bash
# Undo commit and tag
git reset --hard HEAD~1
git tag -d v0.2.0

# Update .bumpversion.toml manually to restore old version
```

## Pre-commit Hook

The `check-version-consistency` hook ensures all version files stay in sync.

If you manually edit versions, make sure to update:

- `.bumpversion.toml` (`current_version`)
- All files listed above

## More Info

- [bump-my-version docs](https://callowayproject.github.io/bump-my-version/)
- [Semantic Versioning](https://semver.org/)
- [CHANGELOG.md](./CHANGELOG.md) - Version history
