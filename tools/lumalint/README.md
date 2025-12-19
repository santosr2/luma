# Lumalint - Luma Template Linter

Command-line linter for validating Luma templates.

## Status

🚧 **Planned** - Specification complete, ready for implementation.

## Installation

```bash
luarocks install lumalint
# or
npm install -g lumalint
```

## Usage

```bash
# Lint a single file
lumalint template.luma

# Lint multiple files
lumalint templates/**/*.luma

# With config
lumalint --config .lumalintrc templates/

# Auto-fix issues
lumalint --fix template.luma

# Watch mode
lumalint --watch templates/
```

## Configuration

`.lumalintrc`:

```json
{
  "rules": {
    "undefined-variable": "warn",
    "undefined-filter": "error",
    "unused-variable": "warn",
    "unused-macro": "warn",
    "unclosed-directive": "error",
    "max-nesting-depth": ["warn", 4],
    "no-raw-html": "off"
  },
  "globals": ["config", "request", "session"],
  "customFilters": ["my_filter"],
  "ignore": ["**/vendor/**"]
}
```

## Rules

### Errors (Blocking)

- `undefined-filter` - Unknown filter used
- `undefined-test` - Unknown test used
- `unclosed-directive` - Missing @end
- `syntax-error` - Invalid syntax

### Warnings

- `undefined-variable` - Variable might not exist
- `unused-variable` - Defined but never used
- `unused-macro` - Defined but never called
- `max-nesting-depth` - Too deeply nested
- `deprecated-syntax` - Old syntax used

### Style

- `prefer-native-syntax` - Suggest Luma over Jinja2
- `consistent-quotes` - String quote style
- `trailing-whitespace` - Unnecessary whitespace

## Output Formats

- `text` - Human-readable (default)
- `json` - Machine-readable
- `checkstyle` - XML format
- `sarif` - Static Analysis Results

## CI/CD Integration

```yaml
# .github/workflows/lint.yml
- name: Lint templates
  run: lumalint --format json templates/ > lint-results.json
```

## Implementation Structure

```text
tools/lumalint/
├── bin/
│   └── lumalint           # CLI entry
├── lib/
│   ├── linter.lua         # Main linter
│   ├── rules/             # Lint rules
│   ├── config.lua         # Configuration
│   └── formatter.lua      # Output formats
└── tests/
    └── rules/             # Rule tests
```

## License

MIT
