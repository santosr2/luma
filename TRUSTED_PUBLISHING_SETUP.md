# 🔐 Trusted Publishing Setup Guide

This project uses **Trusted Publishing (OIDC)** for secure, token-free publishing to PyPI and npm. This eliminates the need for long-lived API tokens.

---

## 📦 PyPI Trusted Publishing Setup

### **1. Configure on PyPI**

#### **For Existing Package (luma-py exists):**

1. Go to: https://pypi.org/manage/project/luma-py/settings/publishing/
2. Scroll to **"Publishing"** section
3. Click **"Add a new pending publisher"**
4. Fill in:
   - **PyPI Project Name**: `luma-py`
   - **Owner**: `santosr2`
   - **Repository name**: `luma`
   - **Workflow name**: `release.yml`
   - **Environment name**: `release`
5. Click **"Add"**

#### **For First Time Publishing:**

If the package doesn't exist yet, use PyPI's **pending publisher** feature:

1. Go to: https://pypi.org/manage/account/publishing/
2. Click **"Add a new pending publisher"**
3. Fill in:
   - **PyPI Project Name**: `luma-py`
   - **Owner**: `santosr2`
   - **Repository name**: `luma`
   - **Workflow name**: `release.yml`
   - **Environment name**: `release`
4. The first workflow run will create the package

### **2. How It Works**

- No `PYPI_API_TOKEN` secret needed! 🎉
- GitHub Actions gets a short-lived OIDC token
- PyPI validates the token matches your configuration
- Package is published securely

### **3. Verify Setup**

```bash
# Check workflow permissions
# Look for: permissions: id-token: write
cat .github/workflows/release.yml | grep -A2 "permissions:"
```

---

## 📦 npm Provenance Setup

### **1. Configure on npm**

#### **Enable Provenance for Your Account:**

1. Go to: https://www.npmjs.com/settings/YOUR_USERNAME/packages
2. Find the `luma` package (or pre-create it)
3. Go to **Settings** → **Publishing Access**
4. Enable **"Require 2FA or Automation token"** (optional but recommended)

#### **Package Name:**

The npm package is published as `luma-js` (not `luma`, which is already taken).

#### **Configure Package Access:**

```bash
# You still need an npm token for authentication
# But provenance provides cryptographic attestation
```

1. Create an **Automation** token:
   - Go to: https://www.npmjs.com/settings/YOUR_USERNAME/tokens
   - Click **"Generate New Token"** → **"Automation"**
   - Copy the token

2. Add to GitHub Secrets:
   - Go to: https://github.com/santosr2/luma/settings/secrets/actions
   - Update `NPM_TOKEN` with the automation token

### **2. How It Works**

- `--provenance` flag signs packages with GitHub's OIDC token
- Creates a cryptographic link between package and source code
- Provides transparency and build reproducibility
- Users can verify package authenticity via:
  ```bash
  npm view luma --json | jq .dist.attestations
  ```

### **3. Benefits**

- **Transparency**: Anyone can verify the package was built in GitHub Actions
- **Security**: Cryptographic proof of origin
- **Compliance**: Meets supply chain security requirements (SLSA)
- **Trust**: npm displays a verified badge for provenance packages

> **Note**: The npm package is named `luma-js` because `luma` was already taken on npm.

---

## 🛡️ GitHub Environment Setup

### **Create the `release` Environment**

1. Go to: https://github.com/santosr2/luma/settings/environments
2. Click **"New environment"**
3. Name it: `release`
4. Click **"Configure environment"**

### **Configure Environment Protection (Recommended)**

Add protection rules to prevent accidental releases:

#### **Option 1: Required Reviewers**
- Under **"Environment protection rules"**
- Enable **"Required reviewers"**
- Add yourself or team members
- All releases will require manual approval

#### **Option 2: Deployment Branches**
- Under **"Deployment branches and tags"**
- Select **"Protected branches only"** or **"Selected branches and tags"**
- Add pattern: `refs/tags/v*`
- Only tagged releases can deploy

#### **Option 3: Wait Timer**
- Under **"Environment protection rules"**
- Enable **"Wait timer"**
- Set minutes to wait before deployment (e.g., 5 minutes)
- Provides a window to cancel accidental releases

### **Add Environment Secrets**

If you want environment-specific secrets:

1. In the `release` environment settings
2. Scroll to **"Environment secrets"**
3. Add secrets here instead of repository secrets
4. These override repository-level secrets

**Current setup uses repository secrets** (LUAROCKS_API_KEY, NPM_TOKEN) which work fine.

---

## 🔍 Verification

### **After Publishing with Trusted Publishing:**

#### **PyPI:**

```bash
# View package sigstore attestations
pip download luma-py --no-deps
pip install sigstore
sigstore verify identity luma_py-*.whl \
  --cert-identity 'https://github.com/santosr2/luma/.github/workflows/release.yml@refs/tags/v*' \
  --cert-oidc-issuer 'https://token.actions.githubusercontent.com'
```

#### **npm:**

```bash
# View provenance information
npm view luma-js --json | jq .dist.attestations

# Download and verify attestations
npm audit signatures
```

---

## 🚀 Publishing Workflow

### **Current Setup:**

```yaml
# PyPI Job
python:
  environment: release  # ← GitHub environment for protection
  permissions:
    id-token: write  # ← Required for OIDC
    contents: read
  steps:
    - name: Publish to PyPI (Trusted Publishing)
      uses: pypa/gh-action-pypi-publish@release/v1
      # No secrets needed!

# npm Job  
npm:
  environment: release  # ← GitHub environment for protection
  permissions:
    id-token: write  # ← Required for provenance
    contents: read
  steps:
    - name: Publish to npm with Provenance
      env:
        NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
      run: npm publish --provenance  # ← Signs with OIDC
```

---

## ✅ Checklist

### **GitHub Environment:**
- [ ] Create `release` environment on GitHub
- [ ] (Optional) Configure required reviewers for extra protection
- [ ] (Optional) Set deployment branch rules (e.g., `refs/tags/v*`)

### **PyPI:**
- [ ] Add pending publisher on PyPI with environment name: `release`
- [ ] Verify workflow has `id-token: write` permission
- [ ] Remove `PYPI_API_TOKEN` secret (no longer needed!)
- [ ] Test with a release

### **npm:**
- [ ] Create automation token on npm
- [ ] Add `NPM_TOKEN` to GitHub secrets
- [ ] Verify workflow has `id-token: write` permission
- [ ] Test with a release
- [ ] Verify provenance: `npm view luma-js --json | jq .dist.attestations`

---

## 🆘 Troubleshooting

### **PyPI: "Trusted publisher configuration does not match"**

- Double-check repository name: `santosr2/luma` (not `luma` alone)
- Verify workflow name exactly: `release.yml`
- Ensure environment name is exactly: `release` (must match workflow configuration)

### **npm: "Provenance failed"**

- Ensure `id-token: write` permission is set
- Check `NODE_AUTH_TOKEN` is valid
- Verify `--provenance` flag is present

### **First-time Publishing**

- For PyPI: Use **pending publisher** feature
- For npm: Package must exist or use automation token for first publish

---

## 📚 References

- **PyPI Trusted Publishing**: https://docs.pypi.org/trusted-publishers/
- **npm Provenance**: https://docs.npmjs.com/generating-provenance-statements
- **GitHub OIDC**: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- **Sigstore**: https://www.sigstore.dev/

---

## 🎉 Benefits Summary

| Feature | Before | With Trusted Publishing |
|---------|--------|------------------------|
| **Secrets** | Long-lived API tokens | No PyPI token, short-lived OIDC |
| **Security** | Token rotation needed | Automatic rotation |
| **Audit** | Manual tracking | Cryptographic proof |
| **Trust** | Token-based | Identity-based |
| **Supply Chain** | Basic | SLSA Level 3 compliance |

**Result**: More secure, less maintenance, better transparency! 🚀

