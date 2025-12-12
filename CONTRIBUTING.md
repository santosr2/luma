# Contributing to Luma

Thank you for your interest in contributing to Luma! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- Lua 5.1+ or LuaJIT
- LuaRocks
- Git
- Busted (for testing)
- Luacheck (for linting)

### Development Setup

1. **Fork and clone the repository:**

```bash
git clone https://github.com/YOUR_USERNAME/luma.git
cd luma
```

2. **Install dependencies:**

```bash
luarocks install busted
luarocks install luacheck
luarocks install luacov
```

3. **Install pre-commit hooks:**

```bash
pip install pre-commit
pre-commit install
```

4. **Run tests to verify setup:**

```bash
busted spec/
```

## Making Changes

### Branch Naming

Use descriptive branch names with prefixes:

- `feat/feature-name` - New features
- `fix/bug-description` - Bug fixes
- `docs/what-changed` - Documentation updates
- `refactor/what-changed` - Code refactoring
- `test/what-added` - Test additions/modifications
- `chore/what-changed` - Maintenance tasks

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Test additions or modifications
- `chore`: Build process or auxiliary tool changes

**Examples:**

```
feat(lexer): add support for custom delimiters

Implement configurable delimiter syntax to allow users
to customize {{ }}, {% %}, and {# #} delimiters.

Closes #123
```

```
fix(parser): handle empty block statements correctly

Empty blocks were causing parser errors. This fix allows
empty blocks and generates appropriate AST nodes.

Fixes #456
```

### Code Style

1. **Indentation:** Use 4 spaces (not tabs)
2. **Line length:** Maximum 120 characters
3. **Naming:**
   - `snake_case` for functions and variables
   - `PascalCase` for classes/modules
   - `UPPER_CASE` for constants
4. **Comments:**
   - Use LDoc format for function documentation
   - Add inline comments for complex logic
   - Keep comments up-to-date

**Example:**

```lua
--- Parse a template expression
-- @param stream table Token stream
-- @param context table|nil Parser context
-- @return table AST node
-- @raise error if syntax is invalid
function parser.parse_expression(stream, context)
    local start_token = stream:peek()
    
    -- Handle special cases for empty expressions
    if not start_token or start_token.type == tokens.EOF then
        return ast.literal(nil, "nil", start_token.line, start_token.column)
    end
    
    -- Continue parsing...
end
```

### Documentation

- Update `README.md` for user-facing changes
- Add/update LDoc comments for API changes
- Update `CHANGELOG.md` (see [Keep a Changelog](https://keepachangelog.com/))
- Add examples in `examples/` for new features

## Testing

### Running Tests

```bash
# Run all tests
busted spec/

# Run specific test file
busted spec/lexer_spec.lua

# Run with coverage
busted --coverage spec/

# Verbose output
busted --verbose spec/
```

### Writing Tests

1. **File naming:** `spec/feature_name_spec.lua`
2. **Use descriptive test names:**

```lua
describe("Feature Name", function()
    describe("specific behavior", function()
        it("should do something specific", function()
            -- Test implementation
        end)
        
        it("should handle edge case X", function()
            -- Edge case test
        end)
    end)
end)
```

3. **Test organization:**
   - Basic functionality first
   - Edge cases
   - Error handling
   - Integration scenarios

4. **Coverage requirements:**
   - New features: 90%+ coverage
   - Bug fixes: Add test that would have caught the bug
   - All critical paths must be tested

### Test Categories

- **Unit tests:** Individual functions/modules
- **Integration tests:** Component interactions
- **Jinja2 compatibility tests:** Verify Jinja2 parity
- **Regression tests:** Prevent known bugs from returning

## Code Quality

### Luacheck

Run the linter before committing:

```bash
luacheck luma/ cli/ spec/
```

Fix all warnings and errors. Configuration is in `.luacheckrc`.

### Complexity

Keep cyclomatic complexity low:
- Functions: Maximum complexity of 15
- Files: Maximum 500 lines (consider splitting larger files)

### Performance

- Profile performance-critical code
- Avoid unnecessary table allocations
- Cache repeated lookups
- Use local variables for performance

## Submitting Changes

### Pull Request Process

1. **Update documentation** (README, CHANGELOG, etc.)
2. **Add tests** for new functionality
3. **Run the full test suite:**
   ```bash
   busted spec/
   luacheck luma/ cli/ spec/
   ```
4. **Commit with signoff:**
   ```bash
   git commit -s -m "feat: add new feature"
   ```
5. **Push to your fork:**
   ```bash
   git push origin feat/my-feature
   ```
6. **Create Pull Request** with description including:
   - What changes were made
   - Why the changes are needed
   - Any breaking changes
   - Issue numbers (Fixes #123, Closes #456)

### PR Requirements

- ✅ All tests pass
- ✅ Code coverage maintained or improved
- ✅ Luacheck passes with no errors
- ✅ Documentation updated
- ✅ CHANGELOG.md updated
- ✅ Signed commits (DCO)
- ✅ No merge conflicts
- ✅ Approved by maintainer

### Review Process

1. Automated checks run (CI/CD)
2. Maintainer reviews code
3. Feedback and requested changes
4. Approval and merge

## Release Process

### Version Numbering

Luma follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality additions
- **PATCH**: Backward-compatible bug fixes

### Release Checklist

1. Update `luma/version.lua`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Create git tag: `git tag -a v1.2.3 -m "Release 1.2.3"`
5. Push tag: `git push origin v1.2.3`
6. GitHub Actions creates release automatically
7. LuaRocks package published automatically

## Development Workflow

### Daily Development

```bash
# 1. Pull latest changes
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feat/my-feature

# 3. Make changes and test
# ... edit files ...
busted spec/
luacheck luma/

# 4. Commit (triggers pre-commit hooks)
git add .
git commit -s -m "feat: add my feature"

# 5. Push and create PR
git push origin feat/my-feature
```

### Pre-commit Hooks

Hooks automatically run on commit:
- ✅ Luacheck (linting)
- ✅ Trailing whitespace removal
- ✅ End-of-file fixer
- ✅ YAML/JSON validation
- ✅ Large file detection
- ✅ Secret detection

Skip hooks (not recommended):
```bash
git commit --no-verify
```

## Areas for Contribution

### High Priority

- 🐛 **Bug Fixes:** See [Issues](https://github.com/USERNAME/luma/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
- 📚 **Documentation:** Improve guides, add examples
- ✨ **Performance:** Optimize hot paths
- 🧪 **Tests:** Increase coverage

### Medium Priority

- 🔧 **Tooling:** IDE plugins, syntax highlighters
- 🌍 **Bindings:** Python, Node.js, Go, Rust
- 📦 **Integrations:** Framework plugins
- 🎨 **Examples:** Real-world use cases

### Low Priority

- 🎁 **Nice-to-haves:** Quality of life improvements
- 🧹 **Refactoring:** Code cleanup
- 📊 **Analytics:** Usage metrics, benchmarks

## Getting Help

- 📖 **Documentation:** [README.md](README.md)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/USERNAME/luma/discussions)
- 🐛 **Issues:** [GitHub Issues](https://github.com/USERNAME/luma/issues)
- 💡 **Ideas:** [Feature Requests](https://github.com/USERNAME/luma/issues/new?template=feature_request.md)

## Recognition

Contributors are recognized in:
- `CONTRIBUTORS.md`
- Release notes
- GitHub contributors page

Thank you for contributing to Luma! 🎉

