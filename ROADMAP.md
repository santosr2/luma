# Luma Roadmap

## Completed Features

### Phase 1: Membership Operators (`in`/`not in`)
- [x] `NOT_IN` token type
- [x] Lexer recognition of "not in" compound keyword
- [x] `runtime.contains()` helper function
- [x] Support for strings, arrays, and table keys

### Phase 2: Test Expressions (`is`/`is not`)
- [x] `TEST` AST node type
- [x] `parse_test()` in expression parser
- [x] Built-in tests: `defined`, `undefined`, `none`, `string`, `number`, `boolean`, `table`, `callable`, `odd`, `even`, `divisibleby`, `iterable`, `mapping`, `sequence`, `lower`, `upper`

### Phase 3: Loop Enhancements
- [x] Enhanced loop variables: `revindex`, `revindex0`, `depth`, `depth0`, `previtem`, `nextitem`
- [x] `cycle()` function in loops
- [x] Tuple unpacking: `@for key, value in dict`
- [x] `@break` directive
- [x] `@continue` directive

### Phase 4: Template Inheritance (`@extends`/`@block`)
- [x] `@extends "base.html"` directive
- [x] `@block name` / `@end` blocks
- [x] `@endblock` alias
- [x] Compile-time AST inheritance resolution
- [x] Nested/multi-level inheritance

### Phase 5: Additional Filters
- [x] String: `replace`, `split`, `wordwrap`, `center`, `indent`, `truncate`, `striptags`, `urlencode`
- [x] Collection: `unique`, `sum`, `min`, `max`, `groupby`, `selectattr`, `rejectattr`, `map`, `keys`, `values`, `items`, `attr`, `select`, `reject`
- [x] Utility: `tojson`, `batch`, `slice`, `dictsort`
- [x] Fixed `safe` filter HTML escaping bypass

### Phase 6: Jinja2 Compatibility Lexer
- [x] `{{ expression }}` variable interpolation
- [x] `{% statement %}` control structures
- [x] `{# comment #}` comments
- [x] Auto-detection between native and Jinja syntax
- [x] Whitespace control: `-%}` and `-}}` (trim after)

---

## Jinja2 Compatibility & Migration

### Goal
Luma provides **full Jinja2 feature parity** to enable seamless migration, but **strongly recommends** using native Luma syntax for new projects due to its cleaner, more readable syntax.

### Jinja2 Feature Status

#### ✅ Fully Supported (38 features tested)
- Variable interpolation: `{{ expr }}`
- Control structures: `{% if %}`, `{% for %}`, `{% while %}`
- Filters with chaining: `{{ x | filter1 | filter2 }}`
- Template inheritance: `{% extends %}`, `{% block %}`
- Macros: `{% macro %}` and `{% call %}`
- Tests: `is defined`, `is none`, `is odd`, etc.
- Membership: `in`, `not in`
- Loop control: `{% break %}`, `{% continue %}`
- Comments: `{# comment #}`
- Whitespace control (trim after): `-%}`, `-}}`
- Auto-detection between Jinja2 and Luma syntax

#### ✅ **COMPLETE - Full Jinja2 Feature Parity Achieved!**

All Jinja2 features are now fully implemented:

**Core Features:**
- ✅ Template inheritance (`@extends`, `@block`, `super()`)
- ✅ Macros and macro calls
- ✅ Include and import (with selective imports)
- ✅ Control flow (if/elif/else, for loops, break/continue)
- ✅ Variables, filters, and tests
- ✅ Comments and raw blocks

**Advanced Features:**
- ✅ Filter named arguments: `{{ x | filter(name=value) }}`
- ✅ Selective imports: `{% from "file" import macro1, macro2 %}`
- ✅ Set block syntax: `{% set x %}...{% endset %}`
- ✅ Call with caller: `{% call(item) macro() %}...{% endcall %}`
- ✅ Scoped blocks: `{% block name scoped %}`
- ✅ Autoescape blocks: `{% autoescape true/false %}`
- ✅ All test expressions: `defined`, `undefined`, `sameas`, `escaped`, `in`, etc.

**Whitespace Control:**
- ✅ Jinja2 trim syntax: `{%-`, `{{-`, `-%}`, `-}}`
- ✅ Luma dash trimming: `-$var`, `$var-`, `-@if`
- ✅ Context-aware inline mode (auto-detection)
- ✅ Smart indentation preservation (universal)

---

### Deprecation & Migration Strategy

#### Deprecation Warning (Phase 1)
When Jinja2 syntax is detected, display a **non-blocking warning** recommending Luma syntax:

```
⚠️  Jinja2 Syntax Detected
────────────────────────────────────────────────────────
This template uses Jinja2 syntax ({{ }}, {% %}).
While fully supported, we recommend migrating to Luma's
cleaner native syntax for better readability.

Run:  luma migrate template.jinja > template.luma

To suppress this warning, use:
  - luma.render(template, context, { no_jinja_warning = true })
  - Or set environment variable: LUMA_NO_JINJA_WARNING=1
────────────────────────────────────────────────────────
```

**Implementation:**
- [ ] Add `detect_jinja_usage()` to lexer
- [ ] Add warning system to `luma/init.lua`
- [ ] Respect `no_jinja_warning` option and `LUMA_NO_JINJA_WARNING` env var
- [ ] Only show warning once per process (use global flag)

**Files to modify:**
- `luma/lexer/init.lua` - Add detection and warning
- `luma/init.lua` - Check option and env var

---

#### Migration Tool (Phase 2)
CLI command to automatically convert Jinja2 syntax to Luma syntax.

**Command Interface:**
```bash
# Convert single file
luma migrate template.jinja > template.luma

# Convert and overwrite
luma migrate template.jinja --in-place

# Convert entire directory
luma migrate templates/ --output luma-templates/

# Dry run (show diff without writing)
luma migrate template.jinja --dry-run

# Specify input syntax explicitly
luma migrate template.txt --from jinja --to luma
```

**Conversion Rules:**

| Jinja2 | Luma |
|--------|------|
| `{{ expr }}` | `${expr}` |
| `{{ var }}` | `$var` (if simple) |
| `{% if x %}` | `@if x` |
| `{% elif x %}` | `@elif x` |
| `{% else %}` | `@else` |
| `{% endif %}` | `@end` |
| `{% for x in y %}` | `@for x in y` |
| `{% endfor %}` | `@end` |
| `{% set x = y %}` | `@let x = y` |
| `{% macro name() %}` | `@macro name()` |
| `{% endmacro %}` | `@end` |
| `{% call name() %}` | `@call name()` |
| `{% endcall %}` | `@end` |
| `{% include "x" %}` | `@include "x"` |
| `{% extends "x" %}` | `@extends "x"` |
| `{% block name %}` | `@block name` |
| `{% endblock %}` | `@end` |
| `{% break %}` | `@break` |
| `{% continue %}` | `@continue` |
| `{# comment #}` | `@# comment` |

**Edge Cases:**
- Preserve indentation levels
- Handle whitespace control (`-%}` → remove, as Luma handles this intelligently)
- Preserve filter arguments and chaining
- Handle complex expressions correctly
- Preserve string quotes
- Keep comments and documentation

**Implementation:**
- [ ] Create `cli/commands/migrate.lua`
- [ ] Implement AST-based conversion (not regex!)
- [ ] Parse with Jinja2 lexer, regenerate with Luma syntax
- [ ] Add tests for conversion accuracy
- [ ] Handle edge cases (nested blocks, complex expressions)

**File Structure:**
```
cli/
├── commands/
│   └── migrate.lua      # Migration command implementation
└── migrate/
    ├── converter.lua    # AST → Luma code generator
    ├── formatter.lua    # Pretty-print Luma syntax
    └── validator.lua    # Verify conversion correctness
```

---

## Pending Features

### High Priority

#### `super()` Function for Template Inheritance
Support for calling parent block content from child blocks.

```jinja
{% block content %}
{{ super() }}
Additional content
{% endblock %}
```

**Status:** ✅ Implemented

**Implementation:**
- [x] Store parent block in child block during inheritance resolution
- [x] Generate `__super` function containing parent block content
- [x] Handle `super` as special identifier resolving to `__super`
- [x] Initialize `__super = nil` in generated code
- [x] Support multiple `super()` calls in same block
- [x] Work with nested inheritance (3+ levels)
- [x] Test suite in `spec/super_spec.lua`

**Files modified:**
- `luma/compiler/init.lua` - Store parent blocks during inheritance
- `luma/compiler/codegen.lua` - Generate super() function and handle identifier
- `spec/super_spec.lua` - Comprehensive test coverage

#### Jinja2 Deprecation Warning System
Display helpful warnings when Jinja2 syntax is detected.

**Features:**
- Non-blocking warning message
- Suggestion to migrate to Luma syntax
- One-time warning per process
- Suppressible via option or environment variable

**Files to modify:**
- `luma/lexer/init.lua` - Detection and warning emission
- `luma/init.lua` - Handle suppression options
- `luma/utils/warnings.lua` - New warning system (create)

---

#### Jinja2 → Luma Migration Tool
CLI command to convert Jinja2 templates to Luma syntax.

**Features:**
- AST-based conversion (accurate, not regex)
- Preserve indentation and formatting
- Handle all Jinja2 constructs
- Dry-run mode with diff output
- Batch directory conversion
- Validation of conversion correctness

**Files to create:**
- `cli/commands/migrate.lua` - CLI command
- `cli/migrate/converter.lua` - AST → Luma generator
- `cli/migrate/formatter.lua` - Code formatting
- `spec/migrate_spec.lua` - Migration tests

---

#### Context-Aware Inline Mode & Whitespace Trimming
Luma has **smart indentation preservation by default** for all file types. For rare cases needing precise control, use context-aware inline mode and dash trimming.

**Native Luma Syntax:**
```
# Inline mode (use semicolon to end expression)
Status: @if active; Success @else Failed @end

# Space required before @ for inline directives
email@example.com           # Literal @
Result: @if x; yes @end     # Directive @ (space before)

# Dash trimming for edge cases
text-$value-more
@-for item in items
```

**Philosophy:**
- **Block mode** (default): Directive on own line → preserves structure
- **Inline mode** (semicolon `;`): Marks end of expression for compact output
- **Space requirement**: `@` requires space before it for inline directives
- **Dash trimming** (`-`): Explicit whitespace control for edge cases
- Smart preservation works universally (YAML, HTML, JSON, code, etc.)
- Explicit control rarely needed (99% of cases use defaults)

**Jinja2 Compatibility:**
- Need trim-before (`{%-`, `{{-`) for Jinja2 feature parity
- Jinja2 users should migrate to Luma's cleaner context-aware + dash syntax

**Files to modify:**
- `luma/lexer/native.lua` - Detect inline context, recognize dash (`-`) trim syntax
- `luma/lexer/tokens.lua` - Add trim modifier tokens
- `luma/parser/init.lua` - Detect inline mode from context, parse trim modifiers
- `luma/compiler/codegen.lua` - Generate inline code (no newlines) + apply trimming
- `luma/lexer/jinja.lua` - Add trim-before for Jinja2 compat
- `docs/WHITESPACE.md` - Complete documentation (already updated ✅)
- `WHITESPACE_DESIGN.md` - Design rationale (already updated ✅)

---

### Medium Priority (Jinja2 Feature Parity)

#### ✅ Filter Named Arguments (COMPLETED)
Support Jinja2-style named arguments in filters for full compatibility.

```jinja
{{ text | truncate(length=50, killwords=true) }}
{{ text | wordwrap(width=80, wrapstring='<br>') }}
{{ text | indent(width=4, first=false) }}
```

**Status:** ✅ Implemented with full backward compatibility
- Works in both Jinja2 and Luma syntax
- Supports positional and named arguments
- Parser detects `name=value` syntax
- Codegen passes named args as table
- Core filters (truncate, wordwrap, indent) updated
- Custom filters can use `runtime._extract_filter_args` helper

**Files to modify:**
- `luma/parser/expressions.lua` - Parse `name=value` in filter arguments
- `luma/compiler/codegen.lua` - Generate table argument for named params
- `luma/filters/init.lua` - Update filters to accept named args

---

#### Import Selective Names (`{% from ... import %}`)
Support selective imports from templates.

```jinja
{% from "macros.html" import button, card %}
{% from "utils.html" import helper as h %}
```

**Jinja2 Parity:** Required for macro libraries and component systems.

**Files to modify:**
- `luma/lexer/tokens.lua` - Add `FROM` token
- `luma/parser/init.lua` - Update `parse_import` for selective syntax
- `luma/compiler/codegen.lua` - Generate selective macro binding
- `luma/runtime/init.lua` - Add selective import logic

---

#### Scoped Blocks
Blocks with access to the current context scope.

```jinja
{% for item in items %}
  {% block item scoped %}{{ item }}{% endblock %}
{% endfor %}
```

**Jinja2 Parity:** Used in advanced templating patterns.

**Files to modify:**
- `luma/parser/init.lua` - Parse `scoped` modifier
- `luma/compiler/codegen.lua` - Pass context to scoped blocks

---

#### Set Block Syntax
Multi-line variable assignment.

```jinja
{% set navigation %}
  <nav>
    <a href="/">Home</a>
    <a href="/about">About</a>
  </nav>
{% endset %}
{{ navigation }}
```

**Jinja2 Parity:** Used for complex HTML/text composition.

**Files to modify:**
- `luma/parser/init.lua` - Detect and parse block form of `set`
- `luma/compiler/codegen.lua` - Capture block output into variable

---

#### Call Block with Caller
Advanced macro invocation with content blocks.

```jinja
{% macro render_list(items) %}
  <ul>
  {% for item in items %}
    <li>{{ caller(item) }}</li>
  {% endfor %}
  </ul>
{% endmacro %}

{% call(item) render_list([1, 2, 3]) %}
  Item: {{ item }}
{% endcall %}
```

**Jinja2 Parity:** Used in advanced macro patterns (like HOCs in React).

**Files to modify:**
- `luma/parser/init.lua` - Parse `call` with arguments
- `luma/compiler/codegen.lua` - Generate caller function
- `luma/runtime/init.lua` - Support caller context

---

### Low Priority (Jinja2 Nice-to-Have)

#### Additional Tests
Additional test expressions for full Jinja2 compatibility:
- `sameas` - Identity comparison (`x is sameas y`)
- `escaped` - Check if value is already escaped
- `in` as test - `x is in [1, 2, 3]` (alternative to membership operator)

**Jinja2 Parity:** Rarely used in practice.

**Files to modify:**
- `luma/runtime/init.lua` - Add test functions

---

#### Autoescape Control
Automatic HTML escaping for security.

```jinja
{% autoescape true %}
  {{ user_content }}  {# automatically escaped #}
{% endautoescape %}

{% autoescape false %}
  {{ trusted_html }}  {# not escaped #}
{% endautoescape %}
```

**Jinja2 Parity:** Important for web frameworks, but can be handled at framework level.

**Files to modify:**
- `luma/parser/init.lua` - Parse `autoescape` directive
- `luma/compiler/codegen.lua` - Toggle escaping mode
- `luma/runtime/init.lua` - Track autoescape state

---

#### Raw Blocks Enhancement
Verify and document `{% raw %}...{% endraw %}` behavior in Jinja mode.

```jinja
{% raw %}
  This {{ will }} not {% be %} parsed
{% endraw %}
```

**Status:** Partially implemented, needs testing and documentation.

**Files to modify:**
- `spec/jinja_compat_spec.lua` - Add comprehensive raw block tests

---

### Jinja2 Compatibility Priority Matrix

| Feature | Jinja2 Usage | Implementation Effort | Priority |
|---------|--------------|----------------------|----------|
| Deprecation warning | N/A | Low | **P0** |
| Migration tool | N/A | Medium | **P0** |
| `super()` function | High | Medium | **P1** |
| Trim before (`{%-`) | Medium | Low | **P1** |
| Filter named args | Medium | Medium | **P1** |
| Selective imports | Medium | Medium | **P2** |
| Set block syntax | Low | Low | **P2** |
| Scoped blocks | Low | Medium | **P3** |
| Call with caller | Low | High | **P3** |
| Autoescape | Medium* | Medium | **P3** |
| Additional tests | Very Low | Low | **P4** |

\* Typically handled at framework level (Flask, Django, etc.)

---

## Test Coverage

| Feature | Tests |
|---------|-------|
| Membership operators | 18 |
| Test expressions | 31 |
| Loop enhancements | 14 |
| Template inheritance | 12 |
| Extended filters | 45 |
| Jinja2 compatibility | 38 |
| **Total** | **226** |

---

## Tooling

### VSCode/Cursor Extension
A language extension for VSCode and Cursor editors providing Luma template support.

#### Features
- [ ] Syntax highlighting for `.luma` files
- [ ] Syntax highlighting for embedded Luma in `.html` files
- [ ] Bracket matching for `@if`/`@end`, `{% %}`/`{% end %}`, `${ }`
- [ ] Auto-closing pairs for `${}`, `{{ }}`, `{% %}`
- [ ] Snippets for common patterns (`@for`, `@if`, `@macro`, `@block`)
- [ ] IntelliSense/autocomplete for:
  - Built-in filters (`upper`, `lower`, `join`, etc.)
  - Built-in tests (`defined`, `none`, `odd`, etc.)
  - Directives (`@if`, `@for`, `@let`, `@macro`, etc.)
- [ ] Hover documentation for filters and directives
- [ ] Go to definition for macros and blocks
- [ ] Find all references for variables
- [ ] Outline view for blocks and macros
- [ ] Error diagnostics (integration with linter)
- [ ] Format document support

#### File Structure
```
luma-vscode/
├── package.json           # Extension manifest
├── syntaxes/
│   └── luma.tmLanguage.json  # TextMate grammar
├── snippets/
│   └── luma.json          # Code snippets
├── language-configuration.json
└── src/
    ├── extension.ts       # Extension entry point
    ├── completionProvider.ts
    ├── hoverProvider.ts
    ├── diagnosticsProvider.ts
    └── formattingProvider.ts
```

#### Grammar Scopes
- `source.luma` - Luma template file
- `meta.interpolation.luma` - `${}` and `{{ }}`
- `keyword.control.luma` - `@if`, `@for`, `{% if %}`, etc.
- `entity.name.function.filter.luma` - Filter names
- `entity.name.function.macro.luma` - Macro definitions
- `variable.other.luma` - Variable references

---

### Luma Linter (`lumalint`)
A command-line linter for validating Luma templates.

#### Features
- [ ] Syntax validation (parsing errors)
- [ ] Undefined variable warnings
- [ ] Undefined filter errors
- [ ] Undefined macro errors
- [ ] Unused variable warnings
- [ ] Unused macro warnings
- [ ] Block name mismatch detection
- [ ] Unclosed directive detection (`@if` without `@end`)
- [ ] Template inheritance validation (missing parent, circular extends)
- [ ] Configurable rules via `.lumalintrc`
- [ ] Multiple output formats (text, JSON, SARIF)
- [ ] Watch mode for continuous linting
- [ ] Integration with CI/CD pipelines

#### CLI Interface
```bash
# Lint a single file
lumalint template.luma

# Lint multiple files
lumalint templates/*.luma

# Lint with specific config
lumalint --config .lumalintrc templates/

# Output as JSON
lumalint --format json template.luma

# Watch mode
lumalint --watch templates/

# Fix auto-fixable issues
lumalint --fix template.luma
```

#### Configuration (`.lumalintrc`)
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
  "customFilters": ["my_filter", "format_date"],
  "templatePaths": ["templates/"],
  "ignore": ["**/vendor/**", "**/*.min.luma"]
}
```

#### Error Output Example
```
templates/page.luma
  3:12  error    Undefined filter 'formatt' - did you mean 'format'?  undefined-filter
  7:5   warning  Variable 'user' is defined but never used            unused-variable
  15:1  error    Unclosed @if directive started at line 10            unclosed-directive

✖ 3 problems (2 errors, 1 warning)
```

#### File Structure
```
lumalint/
├── bin/
│   └── lumalint          # CLI entry point
├── lib/
│   ├── linter.lua        # Main linter logic
│   ├── rules/            # Individual lint rules
│   │   ├── undefined-variable.lua
│   │   ├── undefined-filter.lua
│   │   ├── unclosed-directive.lua
│   │   └── ...
│   ├── config.lua        # Config file parser
│   ├── formatter.lua     # Output formatters
│   └── fixer.lua         # Auto-fix logic
├── .lumalintrc.default   # Default configuration
└── rockspec/             # LuaRocks package spec
```

#### Integration Points
- **VSCode Extension**: Real-time diagnostics via LSP or direct integration
- **Pre-commit hooks**: Validate templates before commit
- **CI/CD**: Exit with non-zero code on errors
- **Editor plugins**: Vim, Neovim, Sublime Text, etc.

---

## Ecosystem & Multi-Language Support

Goal: Make Luma as ubiquitous as Jinja2 across different languages and tools.

### Phase 1: Enhanced CLI Tool

Universal interface for any language via subprocess.

#### Features
- [ ] `luma render <template> --data <json>` - Render with inline JSON
- [ ] `luma render <template> --data-file <file>` - Render with JSON/YAML file
- [ ] `luma render --stdin` - Read template from stdin
- [ ] `luma render --data-stdin` - Read context data from stdin
- [ ] `luma compile <template> --output <file>` - Pre-compile templates
- [ ] `luma validate <template>` - Syntax validation without rendering
- [ ] `luma version` - Version information
- [ ] Exit codes for CI/CD integration (0 = success, 1 = error)
- [ ] Multiple output formats (raw, JSON-wrapped)

#### CLI Interface
```bash
# Render with inline JSON data
luma render template.luma --data '{"name": "World"}'

# Render with data file (auto-detects JSON/YAML)
luma render template.luma --data-file context.yaml

# Pipe data via stdin
echo '{"name": "World"}' | luma render template.luma --data-stdin

# Pipe template via stdin
cat template.luma | luma render --stdin --data '{"name": "World"}'

# Pre-compile for performance
luma compile templates/*.luma --output compiled/

# Validate without rendering
luma validate template.luma
```

---

### Phase 2: Package Distribution

Make Luma easily installable across ecosystems.

#### Distribution Channels
- [ ] **LuaRocks**: `luarocks install luma`
- [ ] **Homebrew**: `brew install luma`
- [ ] **APT/Debian**: `.deb` packages
- [ ] **RPM/Fedora**: `.rpm` packages
- [ ] **Docker**: `docker run luma/luma render ...`
- [ ] **GitHub Releases**: Pre-built binaries (Linux, macOS, Windows)
- [ ] **Nix**: Nixpkgs recipe

#### File Structure
```
dist/
├── homebrew/
│   └── luma.rb              # Homebrew formula
├── docker/
│   └── Dockerfile           # Docker image
├── deb/
│   └── debian/              # Debian packaging
├── rpm/
│   └── luma.spec            # RPM spec file
└── nix/
    └── default.nix          # Nix expression
```

---

### Phase 3: Language Bindings

Native integrations using Lua's embeddability.

#### Python (`luma-py`)
- [ ] PyPI package: `pip install luma-templates`
- [ ] Uses `lupa` (LuaJIT) or `lunatic` for Lua integration
- [ ] Pythonic API matching Jinja2 patterns
- [ ] Type hints for IDE support
- [ ] Django/Flask extensions

```python
from luma import Luma, Environment

# Simple usage
luma = Luma()
result = luma.render("Hello, $name!", {"name": "World"})

# With environment
env = Environment()
env.add_filter("exclaim", lambda s: s + "!")
result = env.render("${msg | exclaim}", {"msg": "Hello"})

# Flask integration
from luma.contrib.flask import Luma
app.jinja_env = Luma()  # Drop-in replacement
```

**File Structure:**
```
luma-py/
├── pyproject.toml
├── src/luma/
│   ├── __init__.py          # Main API
│   ├── environment.py       # Environment class
│   ├── lua_bridge.py        # Lua integration via lupa
│   └── contrib/
│       ├── flask.py         # Flask integration
│       └── django.py        # Django integration
├── tests/
└── lua/                     # Bundled Lua source
    └── luma/
```

---

#### Go (`luma-go`)
- [ ] Go module: `go get github.com/luma-templates/luma-go`
- [ ] Uses `gopher-lua` (pure Go Lua VM)
- [ ] Idiomatic Go API with `template.Template`-like interface
- [ ] Helm plugin support
- [ ] Kubernetes controller integration

```go
package main

import "github.com/luma-templates/luma-go"

func main() {
    // Simple usage
    result, _ := luma.Render("Hello, $name!", map[string]any{
        "name": "World",
    })

    // Compiled template
    tmpl, _ := luma.Compile("Hello, $name!")
    result, _ = tmpl.Execute(map[string]any{"name": "Alice"})

    // With environment
    env := luma.NewEnvironment()
    env.AddFilter("exclaim", func(s string) string {
        return s + "!"
    })
    result, _ = env.Render("${msg | exclaim}", map[string]any{"msg": "Hello"})
}
```

**File Structure:**
```
luma-go/
├── go.mod
├── luma.go                  # Main API
├── environment.go           # Environment management
├── template.go              # Compiled template
├── lua_bridge.go            # gopher-lua integration
├── lua/                     # Embedded Lua source
│   └── luma/
├── cmd/
│   └── helm-luma/           # Helm plugin
└── examples/
```

---

#### Rust (`luma-rs`)
- [ ] Crates.io: `cargo add luma-templates`
- [ ] Uses `mlua` or `rlua` for Lua integration
- [ ] Compile to WASM for universal runtime
- [ ] Serde integration for data serialization
- [ ] Async support

```rust
use luma::Luma;
use serde_json::json;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let luma = Luma::new()?;

    // Render with serde_json
    let result = luma.render(
        "Hello, $name!",
        json!({"name": "World"})
    )?;

    // Compiled template
    let template = luma.compile("Hello, $name!")?;
    let result = template.render(json!({"name": "Alice"}))?;

    Ok(())
}
```

**File Structure:**
```
luma-rs/
├── Cargo.toml
├── src/
│   ├── lib.rs               # Main API
│   ├── environment.rs       # Environment management
│   ├── template.rs          # Compiled template
│   └── lua_bridge.rs        # mlua integration
├── lua/                     # Embedded Lua source
│   └── luma/
└── examples/
```

---

#### Node.js (`@luma/templates`)
- [ ] npm package: `npm install @luma/templates`
- [ ] Uses `fengari` (Lua in JavaScript) for browser + Node.js
- [ ] TypeScript definitions included
- [ ] Express/Koa middleware
- [ ] Browser bundle for client-side rendering

```typescript
import { Luma, Environment } from '@luma/templates';

// Simple usage
const luma = new Luma();
const result = luma.render('Hello, $name!', { name: 'World' });

// Async file rendering
const result = await luma.renderFile('template.luma', { name: 'World' });

// Express integration
import express from 'express';
import { lumaEngine } from '@luma/templates/express';

const app = express();
app.engine('luma', lumaEngine());
app.set('view engine', 'luma');
```

**File Structure:**
```
luma-js/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts             # Main API
│   ├── environment.ts       # Environment class
│   ├── lua-bridge.ts        # fengari integration
│   └── integrations/
│       ├── express.ts       # Express middleware
│       └── koa.ts           # Koa middleware
├── lua/                     # Bundled Lua source
│   └── luma/
├── dist/                    # Compiled output
│   ├── index.js
│   ├── index.d.ts
│   └── browser.js           # Browser bundle
└── test/
```

---

#### Elixir (`luma_ex`)
- [ ] Hex package: `{:luma, "~> 1.0"}`
- [ ] Uses `luerl` (pure Erlang Lua implementation)
- [ ] Phoenix integration
- [ ] LiveView compatible

```elixir
# Simple usage
Luma.render("Hello, $name!", %{name: "World"})

# Compiled template
{:ok, template} = Luma.compile("Hello, $name!")
Luma.Template.render(template, %{name: "Alice"})

# Phoenix integration
# config/config.exs
config :phoenix, :template_engines,
  luma: Luma.Phoenix.Engine
```

**File Structure:**
```
luma_ex/
├── mix.exs
├── lib/
│   ├── luma.ex              # Main API
│   ├── luma/
│   │   ├── environment.ex   # Environment management
│   │   ├── template.ex      # Compiled template
│   │   ├── lua_bridge.ex    # luerl integration
│   │   └── phoenix/
│   │       └── engine.ex    # Phoenix engine
├── priv/
│   └── lua/                 # Bundled Lua source
│       └── luma/
└── test/
```

---

#### Ruby (`luma-ruby`)
- [ ] RubyGems: `gem install luma-templates`
- [ ] Uses `rufus-lua` for Lua integration
- [ ] Rails integration (ActionView template handler)
- [ ] Tilt adapter for Sinatra/Rack

```ruby
require 'luma'

# Simple usage
result = Luma.render("Hello, $name!", { name: "World" })

# Compiled template
template = Luma.compile("Hello, $name!")
result = template.render({ name: "Alice" })

# Rails integration
# config/initializers/luma.rb
ActionView::Template.register_template_handler(:luma, Luma::Rails::Handler)
```

**File Structure:**
```
luma-ruby/
├── luma.gemspec
├── lib/
│   ├── luma.rb              # Main API
│   ├── luma/
│   │   ├── environment.rb   # Environment class
│   │   ├── template.rb      # Compiled template
│   │   ├── lua_bridge.rb    # rufus-lua integration
│   │   └── rails/
│   │       └── handler.rb   # ActionView handler
├── lua/                     # Bundled Lua source
│   └── luma/
└── spec/
```

---

### Phase 4: WebAssembly (WASM) Support

Universal runtime for browser and edge computing.

#### Features
- [ ] Compile Luma to WASM using `wasmoon` (Lua 5.4 in WASM)
- [ ] Browser bundle (`<script src="luma.wasm.js">`)
- [ ] Edge runtime support (Cloudflare Workers, Deno Deploy, Vercel Edge)
- [ ] Standalone WASM module for any WASM runtime

#### Usage
```html
<!-- Browser -->
<script src="https://cdn.jsdelivr.net/npm/@luma/wasm/luma.min.js"></script>
<script>
  const luma = await Luma.init();
  const result = luma.render('Hello, $name!', { name: 'World' });
</script>
```

```typescript
// Cloudflare Worker
import { Luma } from '@luma/wasm';

export default {
  async fetch(request: Request): Promise<Response> {
    const luma = await Luma.init();
    const html = luma.render(template, { request });
    return new Response(html, { headers: { 'content-type': 'text/html' } });
  }
};
```

**File Structure:**
```
luma-wasm/
├── package.json
├── src/
│   ├── index.ts             # JavaScript wrapper
│   └── init.ts              # WASM initialization
├── lua/                     # Lua source to bundle
│   └── luma/
├── build/
│   ├── build.js             # Build script using wasmoon
│   └── wasm/                # Compiled WASM output
└── dist/
    ├── luma.wasm.js         # Browser bundle
    ├── luma.wasm.mjs        # ESM bundle
    └── luma.wasm            # Raw WASM module
```

---

### Phase 5: Framework Integrations

First-class support for popular DevOps and web frameworks.

#### Helm Plugin (`helm-luma`)
Alternative to Go templates for Kubernetes manifests.

- [ ] Helm plugin: `helm plugin install https://github.com/luma-templates/helm-luma`
- [ ] `helm luma template` command
- [ ] Values file support
- [ ] Chart.yaml integration

```bash
# Install plugin
helm plugin install https://github.com/luma-templates/helm-luma

# Use in chart (templates/*.luma)
helm luma template mychart -f values.yaml

# Convert existing Go templates to Luma
helm luma convert templates/deployment.yaml
```

**Example Chart:**
```yaml
# templates/deployment.luma
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Values.name
  labels:
    app: $Values.name
spec:
  replicas: ${Values.replicas | default(1)}
  template:
    spec:
      containers:
@for container in Values.containers
        - name: $container.name
          image: ${container.image}:${container.tag | default("latest")}
@if container.env
          env:
@for key, value in container.env
            - name: $key
              value: "$value"
@end
@end
@end
```

---

#### Ansible Plugin (`ansible-luma`)
Alternative to Jinja2 for Ansible templates.

- [ ] Ansible collection: `ansible-galaxy collection install luma.templates`
- [ ] Template lookup plugin
- [ ] Filter plugin bridge
- [ ] Template module

```yaml
# playbook.yml
- name: Deploy config
  template:
    src: config.luma
    dest: /etc/app/config.yaml
    engine: luma

# Or using lookup
- name: Render inline
  debug:
    msg: "{{ lookup('luma', 'Hello, $name!', name=inventory_hostname) }}"
```

**File Structure:**
```
ansible-luma/
├── galaxy.yml
├── plugins/
│   ├── lookup/
│   │   └── luma.py          # Lookup plugin
│   ├── filter/
│   │   └── luma_filters.py  # Bridge Luma filters
│   └── module_utils/
│       └── luma_engine.py   # Shared engine
├── roles/
└── lua/                     # Bundled Lua source
    └── luma/
```

---

#### Terraform Provider (`terraform-provider-luma`)
Template rendering for Terraform configurations.

- [ ] Terraform Registry provider
- [ ] `luma_template` data source
- [ ] `luma_file` data source

```hcl
terraform {
  required_providers {
    luma = {
      source = "luma-templates/luma"
    }
  }
}

data "luma_template" "config" {
  template = <<-EOT
    server:
      host: $host
      port: ${port | default(8080)}
    @for db in databases
      - name: $db.name
        url: $db.url
    @end
  EOT

  vars = {
    host      = var.server_host
    port      = var.server_port
    databases = var.databases
  }
}

resource "local_file" "config" {
  content  = data.luma_template.config.rendered
  filename = "${path.module}/config.yaml"
}
```

---

#### dbt Adapter (`dbt-luma`)
Alternative to Jinja2 for dbt SQL templating.

- [ ] dbt package
- [ ] SQL file rendering with Luma syntax
- [ ] Macro support bridge

```sql
-- models/users.sql (using Luma syntax)
@let columns = ["id", "name", "email", "created_at"]

SELECT
@for col in columns
  ${col}${loop.last ? "" : ","}
@end
FROM {{ ref('raw_users') }}
@if is_incremental()
WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
@end
```

---

#### GitHub Action (`luma-action`)
CI/CD integration for template rendering.

- [ ] GitHub Marketplace action
- [ ] Render templates in workflows
- [ ] Validation step

```yaml
# .github/workflows/deploy.yml
- name: Render Kubernetes manifests
  uses: luma-templates/luma-action@v1
  with:
    templates: k8s/*.luma
    data-file: env/${{ github.ref_name }}.yaml
    output: rendered/

- name: Validate templates
  uses: luma-templates/luma-action@v1
  with:
    templates: templates/**/*.luma
    command: validate
```

---

### Integration Priority Matrix

| Integration | Effort | Impact | Priority |
|------------|--------|--------|----------|
| Enhanced CLI | Low | High | P0 |
| LuaRocks + Homebrew | Low | Medium | P0 |
| Python binding | Medium | High | P1 |
| Go binding | Medium | High | P1 |
| Helm plugin | Medium | High | P1 |
| Node.js binding | Medium | Medium | P2 |
| WASM build | Medium | Medium | P2 |
| Ansible plugin | Medium | Medium | P2 |
| Rust binding | High | Medium | P2 |
| Elixir binding | High | Low | P3 |
| Ruby binding | High | Low | P3 |
| Terraform provider | High | Low | P3 |
| dbt adapter | High | Low | P3 |

---

## Contributing

When implementing new features:

1. Add token types to `luma/lexer/tokens.lua` if needed
2. Update the appropriate lexer (`native.lua` or `jinja.lua`)
3. Add AST node types to `luma/parser/ast.lua`
4. Update parser in `luma/parser/init.lua` or `luma/parser/expressions.lua`
5. Add code generation in `luma/compiler/codegen.lua`
6. Add runtime helpers in `luma/runtime/init.lua` if needed
7. Write tests in `spec/` directory
8. Run `busted spec/` to verify all tests pass

================================================================================
NEXT STEPS (RECOMMENDED)
================================================================================

IMMEDIATE:
1. Run full test suite: make test
2. Run linter: make lint
3. Install pre-commit hooks: pre-commit install
4. Test CI locally: make ci

SHORT-TERM:
1. Set up repository secrets (LUAROCKS_API_KEY, COVERALLS_REPO_TOKEN)
2. Enable GitHub branch protection rules
3. Create first release: git tag -a v1.0.0
4. Public announcement

MEDIUM-TERM:
1. Documentation website (GitHub Pages)
2. Tutorial series
3. Example gallery
4. Performance benchmarks

LONG-TERM:
1. Multi-language bindings (Python, Node.js, Go)
2. Framework integrations (Flask, Django, etc.)
3. Plugin ecosystem
4. Community growth

================================================================================
UNTRACKED FILES (INTENTIONAL)
================================================================================

These files remain untracked per .cursorrules:
- .cursorrules (project-specific rules)
- CLAUDE.md (AI assistant notes)
- ROADMAP.md (internal roadmap)
- OSS_SETUP_COMPLETE.md (internal summary)
- FEATURE_COMPLETE.md (internal docs)

These are for internal reference and documentation only.