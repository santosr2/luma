---
render_with_liquid: false
---

# Jinja2 to Luma Migration Guide

## Overview

Luma provides **full Jinja2 compatibility** to enable seamless migration from existing Jinja2 templates. While
Jinja2 syntax is fully supported, we **strongly recommend** using Luma's cleaner native syntax for better
readability and maintainability.

## Why Migrate?

| Aspect | Jinja2 | Luma |
|--------|--------|------|
| **Syntax Noise** | Heavy: `{{{#123; }}}#125;`, `{% %%}#125;` | Light: `$var`, `@if` |
| **Readability** | More cluttered | Cleaner, shell-like |
| **Whitespace** | Often needs `{%-` / `-%%}#125;` control | Smart preservation by default |
| **All File Types** | YAML struggles without trim | Works perfectly everywhere |
| **Escaping** | Complex rules | Simple `$$` for literal `$` |

### Comparison Examples

**Variable Interpolation:**

```jinja
{# Jinja2 #}
Hello {{{#123; user.name }}}#125;!
```

```luma
@# Luma
Hello $user.name!
```

**Control Flow:**

```jinja
{# Jinja2 #}
{% if user.is_admin %%}#125;
  <p>Welcome, admin {{{#123; user.name }}}#125;!</p>
{% else %%}#125;
  <p>Welcome, {{{#123; user.name }}}#125;!</p>
{% endif %%}#125;
```

```luma
@# Luma
@if user.is_admin
  <p>Welcome, admin $user.name!</p>
@else
  <p>Welcome, $user.name!</p>
@end
```

**Loops:**

```jinja
{# Jinja2 #}
{% for item in items %%}#125;
  <li>{{{#123; loop.index }}}#125;: {{{#123; item.name }}}#125;</li>
{% endfor %%}#125;
```

```luma
@# Luma
@for item in items
  <li>${loop.index}: $item.name</li>
@end
```

---

## Automatic Migration Tool

Luma includes a built-in migration tool that converts Jinja2 templates to native Luma syntax automatically.

### Installation

```bash
# After installing Luma
luarocks install luma
# or use directly from source
```

### Usage

```bash
# Convert and print to stdout
luma migrate template.jinja

# Convert and save
luma migrate template.jinja > template.luma

# Convert in-place
luma migrate template.jinja --in-place

# Convert entire directory
luma migrate templates/ --output luma-templates/

# Preview changes with diff
luma migrate template.jinja --dry-run --diff
```

---

## Conversion Table

| Jinja2 Syntax | Luma Syntax |
|---------------|-------------|
| `{{{#123; expr }}}#125;` | `${expr}` |
| `{{{#123; var }}}#125;` | `$var` (simplified) |
| `{{{#123; user.name }}}#125;` | `$user.name` |
| `{% if x %%}#125;` | `@if x` |
| `{% elif x %%}#125;` | `@elif x` |
| `{% else %%}#125;` | `@else` |
| `{% endif %%}#125;` | `@end` |
| `{% for x in y %%}#125;` | `@for x in y` |
| `{% endfor %%}#125;` | `@end` |
| `{% set x = y %%}#125;` | `@let x = y` |
| `{% macro name() %%}#125;` | `@macro name()` |
| `{% endmacro %%}#125;` | `@end` |
| `{% call name() %%}#125;` | `@call name()` |
| `{% endcall %%}#125;` | `@end` |
| `{% include "x" %%}#125;` | `@include "x"` |
| `{% extends "x" %%}#125;` | `@extends "x"` |
| `{% block name %%}#125;` | `@block name` |
| `{% endblock %%}#125;` | `@end` |
| `{% break %%}#125;` | `@break` |
| `{% continue %%}#125;` | `@continue` |
| `{# comment #}` | `@# comment` |

---

## Feature Compatibility Matrix

### ✅ Fully Supported

These Jinja2 features work identically in both syntaxes:

- Variable interpolation and member access
- All filters (including chaining)
- Control structures: `if`/`elif`/`else`
- Loops: `for`/`while` with `else` clause
- Loop variables: `loop.index`, `loop.first`, etc.
- Membership operators: `in`, `not in`
- Test expressions: `is defined`, `is none`, etc.
- Template inheritance: `extends`, `block`
- Macros and macro calls
- Includes
- Break and continue statements
- Comments

### 🚧 Pending (On Roadmap)

These features will be added for full Jinja2 parity:

- `super()` function (P1 priority)
- Whitespace control (trim before: `{%-`) (P1)
- Filter named arguments (P1)
- Selective imports: `{% from "file" import macro %%}#125;` (P2)
- Set block syntax (P2)
- Call with caller pattern (P3)
- Autoescape blocks (P3)

---

## Migration Workflow

### 1. **Automatic Conversion**

Start with the automated migration tool:

```bash
# Backup your templates first!
cp -r templates templates.backup

# Migrate entire directory
luma migrate templates/ --output luma-templates/
```

### 2. **Review & Test**

The converter is AST-based and accurate, but always review:

- Complex nested structures
- Whitespace-sensitive YAML/configs
- Custom filters or macros

### 3. **Gradual Migration**

You can migrate incrementally:

- Luma auto-detects syntax per template
- Mix `.jinja` and `.luma` templates in same project
- Migrate one module/feature at a time

### 4. **Suppress Warnings**

During migration, suppress deprecation warnings:

```lua
-- In code
luma.render(template, context, { no_jinja_warning = true })
```

```bash
# Via environment variable
export LUMA_NO_JINJA_WARNING=1
```

---

## Framework Integration

### Flask

```python
# Before (Jinja2)
from flask import Flask, render_template
app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html.jinja', name='World')
```

```python
# After (Luma)
from flask import Flask
from luma.contrib.flask import Luma

app = Flask(__name__)
app.jinja_env = Luma()  # Drop-in replacement

@app.route('/')
def index():
    return render_template('index.html.luma', name='World')
```

### Django

```python
# settings.py
TEMPLATES = [{
    'BACKEND': 'luma.contrib.django.LumaTemplates',
    'DIRS': ['templates'],
    'OPTIONS': {
        'no_jinja_warning': True,  # Suppress during migration
    }
}]
```

### Ansible

```yaml
# playbook.yml
- name: Deploy config
  template:
    src: config.luma  # Use .luma extension
    dest: /etc/app/config.yaml
    engine: luma
```

---

## Common Patterns

### Pattern 1: Kubernetes Manifests

**Before (Jinja2):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{{#123; app_name }}}#125;
spec:
  replicas: {{{#123; replicas | default(3) }}}#125;
  template:
    spec:
      containers:
      {% for container in containers %%}#125;
        - name: {{{#123; container.name }}}#125;
          image: {{{#123; container.image }}}#125;:{{{#123; container.tag | default('latest') }}}#125;
          {% if container.env %%}#125;
          env:
            {% for key, value in container.env.items() %%}#125;
            - name: {{{#123; key }}}#125;
              value: "{{{#123; value }}}#125;"
            {% endfor %%}#125;
          {% endif %%}#125;
      {% endfor %%}#125;
```

**After (Luma):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app_name
spec:
  replicas: ${replicas | default(3)}
  template:
    spec:
      containers:
      @for container in containers
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

### Pattern 2: HTML Components

**Before (Jinja2):**

```html
{% macro button(text, type='primary') %%}#125;
  <button class="btn btn-{{{#123; type }}}#125;">
    {{{#123; text | capitalize }}}#125;
  </button>
{% endmacro %%}#125;

{{{#123; button('submit', type='success') }}}#125;
```

**After (Luma):**

```html
@macro button(text, type='primary')
  <button class="btn btn-$type">
    ${text | capitalize}
  </button>
@end

@call button('submit', type='success')
```

---

## Troubleshooting

### Issue: Templates not rendering

**Solution:** Check syntax detection:

```lua
-- Explicitly set syntax during transition
luma.render(template, context, { syntax = "jinja" })
-- or
luma.render(template, context, { syntax = "luma" })
```

### Issue: Filter not found

**Solution:** Ensure all custom filters are registered:

```lua
luma.register_filter("custom_filter", function(value)
    return transform(value)
end)
```

### Issue: Whitespace issues in YAML

**Solution:** Use proper indentation with directives:

```yaml
# Good - directives aligned with content
spec:
  containers:
  @for container in containers
    - name: $container.name
  @end

# Avoid - directives at column 0
spec:
  containers:
@for container in containers
    - name: $container.name
@end
```

---

## Getting Help

- **Documentation:** <https://github.com/santosr2/luma>
- **Roadmap:** See `ROADMAP.md` for upcoming features
- **Issues:** Report migration problems on GitHub

## Next Steps

1. ✅ Review the conversion table above
2. ✅ Run `luma migrate` on a test template
3. ✅ Compare output and verify correctness
4. ✅ Gradually migrate your project
5. ✅ Enjoy cleaner, more maintainable templates!
