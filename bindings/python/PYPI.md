# Publishing Luma to PyPI

Complete guide for publishing luma-py to the Python Package Index.

## Prerequisites

1. PyPI account: <https://pypi.org/account/register/>
2. TestPyPI account (optional): <https://test.pypi.org/account/register/>
3. API tokens from both PyPI and TestPyPI
4. Python 3.8+ installed
5. `build` and `twine` packages:

```bash
pip install build twine
```

## Setup

### 1. Configure PyPI Credentials

Create `~/.pypirc`:

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-YOUR_TOKEN_HERE

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-YOUR_TESTPYPI_TOKEN_HERE
```

### 2. Verify Package Metadata

Check `pyproject.toml`:

- [ ] Correct version number
- [ ] Accurate description
- [ ] All dependencies listed
- [ ] Proper classifiers
- [ ] Valid URLs

## Building the Package

### 1. Clean Previous Builds

```bash
cd bindings/python
rm -rf dist/ build/ *.egg-info/
```

### 2. Build Distribution

```bash
python -m build
```

This creates:

- `dist/luma-py-0.1.0.tar.gz` (source distribution)
- `dist/luma_template-0.1.0-py3-none-any.whl` (wheel)

### 3. Verify the Build

```bash
twine check dist/*
```

## Testing

### 1. Upload to TestPyPI

```bash
twine upload --repository testpypi dist/*
```

### 2. Install from TestPyPI

```bash
pip install --index-url https://test.pypi.org/simple/ --no-deps luma-py
```

### 3. Test Installation

```python
python3 -c "from luma import Template; t = Template('Hello, \$name!'); print(t.render(name='Test'))"
```

## Publishing to PyPI

### 1. Final Checks

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in `pyproject.toml`
- [ ] Git tag created: `git tag -a py-v0.1.0`

### 2. Upload to PyPI

```bash
twine upload dist/*
```

### 3. Verify Installation

```bash
pip install luma-py
python3 -c "from luma import Template; print('Success!')"
```

## Automated Publishing with GitHub Actions

### Setup

1. Add PyPI API token to GitHub Secrets:
   - Go to repository Settings > Secrets > Actions
   - Add secret: `PYPI_API_TOKEN`

2. Create `.github/workflows/python-publish.yml`

### Workflow

The workflow automatically:

- Builds on Python 3.8, 3.9, 3.10, 3.11, 3.12
- Runs tests
- Publishes to PyPI on release
- Creates GitHub Release

## Version Management

### Semantic Versioning

Follow SemVer: `MAJOR.MINOR.PATCH`

- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

### Update Version

1. Update `bindings/python/pyproject.toml`
2. Update `bindings/python/luma/__init__.py`
3. Update CHANGELOG.md
4. Create git tag: `git tag -a py-v1.0.1 -m "Python bindings v1.0.1"`
5. Push: `git push origin py-v1.0.1`

## Post-Publication

### 1. Verify Package Page

Visit: <https://pypi.org/project/luma-py/>

Check:

- [ ] Description renders correctly
- [ ] Links work
- [ ] Classifiers are accurate
- [ ] Version is correct

### 2. Test Installation

```bash
# Create fresh venv
python3 -m venv test-env
source test-env/bin/activate
pip install luma-py
python3 -c "from luma import Template; print(Template('$x').render(x=42))"
deactivate
rm -rf test-env
```

### 3. Update Documentation

- [ ] Update README with installation instructions
- [ ] Update documentation website
- [ ] Announce on social media/forums

## Troubleshooting

### Build Failures

```bash
# Install build dependencies
pip install --upgrade pip setuptools wheel build

# Check pyproject.toml syntax
python -c "import tomllib; tomllib.loads(open('pyproject.toml').read())"
```

### Upload Failures

```bash
# Verify credentials
twine check dist/*

# Test with TestPyPI first
twine upload --repository testpypi dist/*
```

### Import Errors

```bash
# Ensure Lua source is bundled
python -m build --verbose

# Check installed files
pip show -f luma-py
```

## Maintenance

### Regular Updates

- Monthly dependency updates
- Security patches promptly
- Bug fixes in patch releases
- Features in minor releases

### Monitoring

- Check PyPI download stats
- Monitor GitHub issues
- Track user feedback
- Update documentation

## Resources

- **PyPI Guide**: <https://packaging.python.org/tutorials/packaging-projects/>
- **Setuptools Docs**: <https://setuptools.pypa.io/>
- **Twine Docs**: <https://twine.readthedocs.io/>
- **PEP 621**: <https://peps.python.org/pep-0621/> (pyproject.toml standard)

## Support

For issues with publishing:

- PyPI Support: <https://pypi.org/help/>
- GitHub Issues: <https://github.com/santosr2/luma/issues>
- Discussions: <https://github.com/santosr2/luma/discussions>
