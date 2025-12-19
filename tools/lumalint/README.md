# Lumalint - Luma Template Linter

Command-line linter for validating Luma templates - catch errors and enforce best practices.

## Status

✅ **Production Ready** - v0.1.0 - Fully implemented, tested, and documented.

## Features

- ✅ Syntax error detection
- ✅ Undefined variable warnings
- ✅ Unused variable detection
- ✅ Empty block warnings
- ✅ Line length checks
- ✅ Debug statement detection
- ✅ Configurable rules
- ✅ Multiple output formats (text, JSON)
- ✅ Pre-defined ignore lists for Helm/Kubernetes/Ansible/Terraform
- ✅ Fix suggestions
- ✅ Comprehensive test suite

## Installation

```bash
# Add lumalint to your PATH
cd tools/lumalint
chmod +x bin/lumalint
export PATH="$PWD/bin:$PATH"

# Or create a symlink
ln -s $PWD/bin/lumalint /usr/local/bin/lumalint
```

## Quick Start

```bash
# Lint a single file
lumalint template.luma

# Lint multiple files
lumalint templates/**/*.luma

# Lint a directory
lumalint templates/

# Strict mode (warnings as errors)
lumalint --strict template.luma

# JSON output
lumalint --format json template.luma
```

## Usage

```bash
lumalint [OPTIONS] FILES...

Options:
  -h, --help              Show help message
  -v, --version           Show version information
  --strict                Treat warnings as errors
  --max-line-length N     Set maximum line length (default: 120)
  --format FORMAT         Output format: text|json (default: text)
  --no-color              Disable colored output
```

## Linting Rules

### Syntax Errors (severity: error)

Detects invalid template syntax:

```luma
@if condition    # Missing @end
```

### Undefined Variables (severity: warning)

Detects variables used without definition:

```luma
Hello, $undefined_name!
```

**Fix:** Define the variable with `@let` or pass it in context.

### Unused Variables (severity: info)

Detects variables defined but never used:

```luma
@let unused = "value"
# Never used
```

**Fix:** Remove unused variable or use it in the template.

### Empty Blocks (severity: warning)

Detects empty control structures:

```luma
@if condition
@end
```

**Fix:** Add content or remove the empty block.

### Line Length (severity: info)

Detects lines exceeding maximum length:

```luma
This is a very long line that exceeds 120 characters...
```

**Fix:** Break into multiple lines.

### Debug Statements (severity: warning)

Detects debug code:

```luma
@do print("debug") @end
```

**Fix:** Remove before production.

## Configuration

Create a `.lumalintrc.yaml` file:

```yaml
# Enable/disable rules
rules:
  undefined-variable: true
  unused-variable: true
  empty-block: true
  max-line-length:
    enabled: true
    max: 100
  no-debug: true

# Variables to ignore
ignore_vars:
  Values: true     # Helm
  Chart: true      # Helm
  Release: true    # Helm
  
# Options
max_line_length: 100
strict: false
```

### Pre-defined Ignore Lists

Lumalint comes with ignore lists for common tools:

**Helm/Kubernetes:**

- `Values`
- `Chart`
- `Release`
- `Capabilities`
- `Template`
- `Files`

**Ansible:**

- `ansible_facts`
- `inventory_hostname`
- `hostvars`

**Terraform:**

- `var`
- `local`
- `module`

## Examples

### Linting a Helm Chart

```bash
lumalint templates/**/*.luma
```

Output:

```text
templates/deployment.luma: ✓ No issues found

templates/service.luma:
  ⚠ 15:5 Undefined variable 'port' [undefined-variable]
    Suggestion: Define 'port' with @let or pass in context

Summary: 2 file(s) checked, 1 issue(s) found (0 error(s))
```

### JSON Output for CI/CD

```bash
lumalint --format json templates/**/*.luma
```

Output:

```json
[
  {
    "file": "templates/service.luma",
    "messages": [
      {
        "rule": "undefined-variable",
        "message": "Undefined variable 'port'",
        "line": 15,
        "column": 5,
        "severity": "warning"
      }
    ]
  }
]
```

### Pre-commit Hook

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: lumalint
      name: Lint Luma templates
      entry: lumalint
      language: system
      files: \.(luma|j2)$
      pass_filenames: true
```

### CI/CD Integration

```yaml
# GitHub Actions
- name: Lint Luma Templates
  run: |
    lumalint --strict templates/**/*.luma
    
# GitLab CI
lint:
  script:
    - lumalint --format json templates/**/*.luma > lint-report.json
  artifacts:
    reports:
      json: lint-report.json
```

## Exit Codes

- `0`: No issues found
- `1`: Issues found (or errors with `--strict`)
- `2`: Fatal error (file not found, invalid arguments, etc.)

## Development

### Running Tests

```bash
cd tools/lumalint
busted spec/
```

### Adding New Rules

1. Add rule function to `lumalint/rules.lua`
2. Add tests to `spec/lumalint_spec.lua`
3. Update `default_options` in `lumalint/init.lua`
4. Document the rule in this README

Example rule:

```lua
rules["my-rule"] = function(ast, source, options)
    local messages = {}
    
    walk_ast(ast, function(node)
        if node.type == N.SOMETHING then
            table.insert(messages, {
                message = "Issue description",
                line = node.line,
                column = node.column,
                severity = "warning",
                fix_suggestion = "How to fix",
            })
        end
    end)
    
    return messages
end
```

## Testing

```bash
# Run all tests
busted spec/

# Test specific file
busted spec/lumalint_spec.lua

# Test with coverage
busted --coverage spec/
```

Comprehensive test suite with 15+ test cases covering:

- Syntax error detection
- Variable analysis (undefined, unused)
- Empty block detection
- Line length checks
- Debug statement detection
- File linting
- Message formatting
- Configuration options

## Performance

- Fast AST-based linting
- Efficient file scanning
- Suitable for large codebases
- Typical speed: 1000+ lines/second

## Comparison

| Feature | Lumalint | yamllint | jinjalint |
|---------|----------|----------|-----------|
| Luma Syntax | ✅ | ❌ | ❌ |
| Jinja2 Syntax | ✅ | ❌ | ✅ |
| Undefined Vars | ✅ | ❌ | ⚠️ |
| AST Analysis | ✅ | ✅ | ⚠️ |
| Custom Rules | ✅ | ✅ | ❌ |
| JSON Output | ✅ | ❌ | ❌ |

## License

MIT

## Links

- [Luma Project](https://github.com/santosr2/luma)
- [Examples](./examples/)
- [Rule Documentation](./RULES.md)
