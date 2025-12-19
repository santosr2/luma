# Publishing Luma VSCode Extension

Guide for publishing the Luma extension to the VSCode Marketplace.

## Prerequisites

1. **Microsoft Account**: Create at [account.microsoft.com](https://account.microsoft.com/)
2. **Azure DevOps**: Set up at [dev.azure.com](https://dev.azure.com/)
3. **Personal Access Token (PAT)**: Create in Azure DevOps
4. **vsce**: VSCode Extension Manager CLI

```bash
npm install -g vsce
```

## Setup

### 1. Create Personal Access Token

1. Go to [dev.azure.com](https://dev.azure.com/)
2. Click User Settings → Personal Access Tokens
3. Click "New Token"
4. Configure:
   - Name: `vsce-publish`
   - Organization: All accessible organizations
   - Expiration: 1 year
   - Scopes: **Marketplace** → **Manage**
5. Copy the token (you won't see it again!)

### 2. Create Publisher

```bash
vsce create-publisher luma
```

Follow the prompts and provide your PAT.

Or create manually at: [marketplace.visualstudio.com/manage](https://marketplace.visualstudio.com/manage)

### 3. Login

```bash
vsce login luma
```

Enter your PAT when prompted.

## Publishing Process

### 1. Update Version

Update version in `package.json`:

```bash
# Patch release (0.1.0 → 0.1.1)
npm version patch

# Minor release (0.1.0 → 0.2.0)
npm version minor

# Major release (0.1.0 → 1.0.0)
npm version major
```

### 2. Build Extension

```bash
npm install
npm run compile
npm run lint
```

### 3. Test Locally

```bash
# Package the extension
npm run package

# This creates luma-X.Y.Z.vsix

# Install and test
code --install-extension luma-0.1.0.vsix
```

### 4. Publish

```bash
# Publish to marketplace
npm run publish

# Or manually
vsce publish
```

### 5. Verify

1. Go to [marketplace.visualstudio.com](https://marketplace.visualstudio.com/)
2. Search for "Luma Templates"
3. Verify extension appears correctly
4. Test installation from marketplace

## Version Management

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes (1.0.0 → 2.0.0)
- **MINOR**: New features (0.1.0 → 0.2.0)
- **PATCH**: Bug fixes (0.1.0 → 0.1.1)

## Pre-release Versions

For beta testing:

```bash
vsce publish --pre-release
```

Users can opt-in to pre-release versions in VSCode.

## Unpublishing

⚠️ **Warning**: Unpublishing affects all users. Use with caution.

```bash
# Unpublish specific version
vsce unpublish luma@0.1.0

# Unpublish entire extension (requires confirmation)
vsce unpublish luma
```

## Marketplace Guidelines

Ensure compliance with [VSCode Marketplace requirements](https://code.visualstudio.com/api/working-with-extensions/publishing-extension):

1. **Icon**: Provide a high-quality icon (128x128 PNG)
2. **README**: Include clear documentation
3. **License**: Specify license in `package.json`
4. **Repository**: Link to source code
5. **Categories**: Choose appropriate categories
6. **Keywords**: Add relevant keywords for discoverability

## Automated Publishing (GitHub Actions)

Create `.github/workflows/publish-vscode.yml`:

```yaml
name: Publish VSCode Extension

on:
  release:
    types: [created]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'

      - name: Install dependencies
        working-directory: tools/vscode-luma
        run: npm ci

      - name: Compile
        working-directory: tools/vscode-luma
        run: npm run compile

      - name: Lint
        working-directory: tools/vscode-luma
        run: npm run lint

      - name: Publish
        working-directory: tools/vscode-luma
        run: npx vsce publish -p ${{ secrets.VSCE_PAT }}
```

Add `VSCE_PAT` to GitHub Secrets.

## Updating the Extension

1. Make changes to code
2. Update `CHANGELOG.md` in README
3. Bump version
4. Build and test
5. Publish

## Troubleshooting

### "You don't have permission to publish"

- Verify you're logged in: `vsce login luma`
- Check your PAT has "Marketplace (Manage)" scope
- Ensure publisher name matches

### "Extension already exists"

- Update version in `package.json`
- Version must be higher than previous release

### "Invalid manifest"

- Run `vsce package` to validate
- Check `package.json` for errors
- Ensure all required fields are present

### "Icon not found"

- Verify icon path in `package.json`
- Ensure icon file exists
- Icon must be PNG, 128x128 pixels

## Post-Publishing Checklist

- [ ] Verify extension on marketplace
- [ ] Test installation from marketplace
- [ ] Update main repository README with marketplace link
- [ ] Announce release (GitHub, social media, etc.)
- [ ] Monitor for user feedback and issues

## Metrics and Analytics

View extension metrics at:
[marketplace.visualstudio.com/manage](https://marketplace.visualstudio.com/manage)

Metrics include:

- Total installs
- Daily installs
- Ratings and reviews
- Version distribution

## Support

- [VSCode Extension API](https://code.visualstudio.com/api)
- [Publishing Guide](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)
- [Marketplace FAQ](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#marketplace-faq)

## Links

- [VSCode Marketplace](https://marketplace.visualstudio.com/)
- [Azure DevOps](https://dev.azure.com/)
- [vsce Documentation](https://github.com/microsoft/vscode-vsce)
