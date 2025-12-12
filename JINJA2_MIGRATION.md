# Jinja2 to Luma Migration Guide

## Overview

Luma provides **full Jinja2 compatibility** to enable seamless migration from existing Jinja2 templates. While Jinja2 syntax is fully supported, we **strongly recommend** using Luma's cleaner native syntax for better readability and maintainability.

## Why Migrate?

| Aspect | Jinja2 | Luma |
|--------|--------|------|
| **Syntax Noise** | Heavy: `{{ }}`, `{% %}` | Light: `$var`, `@if` |
| **Readability** | More cluttered | Cleaner, shell-like |
| **Whitespace** | Often needs `{%-` / `-%}` control | Smart preservation by default |
| **All File Types** | YAML struggles without trim | Works perfectly everywhere |
| **Escaping** | Complex rules | Simple `$$` for literal `$` |

### Comparison Examples

**Variable Interpolation:**
```jinja
{# Jinja2 #}
Hello {{ user.name }}!
```
```luma
@# Luma
Hello $user.name!
```

**Control Flow:**
```jinja
{# Jinja2 #}
{% if user.is_admin %}
  <p>Welcome, admin {{ user.name }}!</p>
{% else %}
  <p>Welcome, {{ user.name }}!</p>
{% endif %}
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
{% for item in items %}
  <li>{{ loop.index }}: {{ item.name }}</li>
{% endfor %}
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
| `{{ expr }}` | `${expr}` |
| `{{ var }}` | `$var` (simplified) |
| `{{ user.name }}` | `$user.name` |
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
- Selective imports: `{% from "file" import macro %}` (P2)
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
  name: {{ app_name }}
spec:
  replicas: {{ replicas | default(3) }}
  template:
    spec:
      containers:
      {% for container in containers %}
        - name: {{ container.name }}
          image: {{ container.image }}:{{ container.tag | default('latest') }}
          {% if container.env %}
          env:
            {% for key, value in container.env.items() %}
            - name: {{ key }}
              value: "{{ value }}"
            {% endfor %}
          {% endif %}
      {% endfor %}
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
{% macro button(text, type='primary') %}
  <button class="btn btn-{{ type }}">
    {{ text | capitalize }}
  </button>
{% endmacro %}

{{ button('submit', type='success') }}
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

- **Documentation:** https://github.com/yourusername/luma
- **Roadmap:** See `ROADMAP.md` for upcoming features
- **Issues:** Report migration problems on GitHub

## Next Steps

1. ✅ Review the conversion table above
2. ✅ Run `luma migrate` on a test template
3. ✅ Compare output and verify correctness
4. ✅ Gradually migrate your project
5. ✅ Enjoy cleaner, more maintainable templates!

