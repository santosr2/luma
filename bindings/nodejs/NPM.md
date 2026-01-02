# Publishing to npm

This guide explains how to publish `@santosr2/luma` to npm.

## Prerequisites

1. **npm Account**: Create an account at [npmjs.com](https://www.npmjs.com/)
2. **npm CLI**: Install with Node.js
3. **Access Rights**: Request publish access to `@luma` scope

## Manual Publishing

### 1. Login to npm

```bash
npm login
```

### 2. Build the Package

```bash
cd bindings/nodejs
npm install
npm run build
npm test
```

### 3. Verify Package Contents

```bash
npm pack --dry-run
```

This shows what files will be included in the package.

### 4. Publish

```bash
# First release
npm publish --access public

# Subsequent releases
npm publish
```

### 5. Verify

```bash
npm info @santosr2/luma
```

## Automated Publishing (GitHub Actions)

The repository includes a GitHub Actions workflow that automatically publishes to npm when a release is created.

### Setup

1. **Create npm Token**:
   - Go to [npmjs.com/settings/tokens](https://www.npmjs.com/settings/tokens)
   - Click "Generate New Token" → "Automation"
   - Copy the token

2. **Add to GitHub Secrets**:
   - Go to repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `NPM_TOKEN`
   - Value: Paste your npm token

3. **Create Release**:
   - Go to repository Releases → "Draft a new release"
   - Tag: `v0.1.0`
   - Title: `Node.js Bindings v0.1.0`
   - Description: Release notes
   - Click "Publish release"

4. **Workflow Runs**:
   - GitHub Actions will automatically build, test, and publish
   - Check Actions tab for status

## Version Management

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes (e.g., 1.0.0 → 2.0.0)
- **MINOR**: New features (e.g., 0.1.0 → 0.2.0)
- **PATCH**: Bug fixes (e.g., 0.1.0 → 0.1.1)

### Updating Version

```bash
# Patch release (0.1.0 → 0.1.1)
npm version patch

# Minor release (0.1.0 → 0.2.0)
npm version minor

# Major release (0.1.0 → 1.0.0)
npm version major
```

This updates `package.json` and creates a git tag.

## Pre-release Versions

For beta/alpha releases:

```bash
npm version prerelease --preid=beta
# 0.1.0 → 0.1.1-beta.0

npm publish --tag beta
```

Users can install with:

```bash
npm install @santosr2/luma@beta
```

## Package Name

The package is published as:

- **Package Name**: `@santosr2/luma`
- **Public**: Yes (use `--access public` on first publish)

## Unpublishing

⚠️ **Warning**: Unpublishing is permanent and should be avoided.

```bash
# Unpublish a specific version
npm unpublish @santosr2/luma@0.1.0

# Unpublish entire package (not recommended)
npm unpublish @santosr2/luma --force
```

**npm Policy**: Packages cannot be unpublished after 72 hours if downloaded.

## Deprecating Versions

Instead of unpublishing, deprecate old versions:

```bash
npm deprecate @santosr2/luma@0.1.0 "Please upgrade to 0.2.0"
```

## Post-Publishing Checklist

- [ ] Verify package on [npmjs.com](https://www.npmjs.com/package/@santosr2/luma)
- [ ] Test installation: `npm install @santosr2/luma`
- [ ] Update main README with npm badge
- [ ] Announce release on GitHub
- [ ] Update changelog

## Troubleshooting

### "You do not have permission to publish"

- Verify you're logged in: `npm whoami`
- Use `--access public` for first publish

### "Version already exists"

- Update version in `package.json`
- Or use `npm version patch/minor/major`

### "Package failed tests"

- Run `npm test` locally
- Fix failing tests before publishing
- CI must pass before publishing

## Links

- [npm Documentation](https://docs.npmjs.com/)
- [npm Scopes](https://docs.npmjs.com/about-scopes)
- [Semantic Versioning](https://semver.org/)
