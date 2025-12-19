# Whitespace Handling in Luma

## Smart Indentation Preservation (Default Behavior)

Luma automatically preserves indentation and whitespace structure in **all** file types, not just YAML or
Kubernetes configs. This intelligent behavior works for:

- **Configuration files**: YAML, TOML, INI, JSON
- **Markup**: HTML, XML, Markdown
- **Code**: Any programming language
- **Data**: CSV, TSV
- **Plain text**: Documentation, logs, reports

**You rarely need to think about whitespace control** - Luma does the right thing by default.

---

## How Smart Preservation Works

### Principle

**Luma preserves the indentation context where placeholders and directives appear.**

This means:

1. Content inside directives maintains its indentation level
2. Multiline interpolations indent subsequent lines to match the placeholder position
3. Directive lines themselves are consumed (not output)
4. Output content aligns naturally with the document structure

---

## Examples Across File Types

### YAML/Kubernetes

```yaml
apiVersion: v1
kind: Service
metadata:
  name: $service.name
  labels:
    app: $app.name
spec:
  ports:
  @for port in ports
    - port: $port.number
      name: $port.name
      protocol: $port.protocol
  @end
```

**Output:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  labels:
    app: web
spec:
  ports:
    - port: 80
      name: http
      protocol: TCP
    - port: 443
      name: https
      protocol: TCP
```

### HTML

```html
<!DOCTYPE html>
<html>
  <head>
    <title>$page.title</title>
  </head>
  <body>
    <h1>$page.heading</h1>
    <ul>
    @for item in items
      <li>$item.name</li>
    @end
    </ul>
  </body>
</html>
```

**Output:**

```html
<!DOCTYPE html>
<html>
  <head>
    <title>My Page</title>
  </head>
  <body>
    <h1>Welcome</h1>
    <ul>
      <li>First</li>
      <li>Second</li>
      <li>Third</li>
    </ul>
  </body>
</html>
```

### Python Code

```python
# config.py.luma
DATABASES = {
@for db in databases
    "$db.name": {
        "ENGINE": "$db.engine",
        "NAME": "$db.name",
        "HOST": "$db.host",
    },
@end
}
```

**Output:**

```python
# config.py
DATABASES = {
    "default": {
        "ENGINE": "postgresql",
        "NAME": "mydb",
        "HOST": "localhost",
    },
    "cache": {
        "ENGINE": "redis",
        "NAME": "cache",
        "HOST": "redis-server",
    },
}
```

### JSON

```json
{
  "name": "$project.name",
  "version": "$project.version",
  "dependencies": {
  @for dep in dependencies
    "$dep.name": "$dep.version"@if not loop.last,@end
  @end
  }
}
```

**Output:**

```json
{
  "name": "my-app",
  "version": "0.1.0",
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "^4.17.21"
  }
}
```

### Markdown

```markdown
# $title

## Features

@for feature in features
### $feature.name

$feature.description

@end

## Installation

\`\`\`bash
$installation_command
\`\`\`
```

---

## Multiline Interpolation

When a placeholder contains newlines, subsequent lines are automatically indented to match the placeholder's position:

```yaml
config:
  description: ${long_text}
  # If long_text = "Line 1\nLine 2\nLine 3"
  # Output:
  # description: Line 1
  #              Line 2
  #              Line 3
```

---

## Explicit Whitespace Control (Advanced)

**In 99% of cases, you don't need this.** Luma's smart defaults handle everything.

For the rare cases where you need precise control:

### Context-Aware Inline Mode (Automatic!)

Luma **automatically detects** when directives should be inline based on context:

| Context | Mode | Behavior |
|---------|------|----------|
| Directive on its own line | Block | Preserves structure, natural newlines |
| Directive with text on same line | Inline | Compact, flows with text |

**No special syntax needed** - if it looks inline, it behaves inline!

#### Inline Examples (Auto-detected)

**Inline Conditional:**

```text
Result: @if success ✓ Passed @else ✗ Failed @end
```

**Output:** `Result: ✓ Passed`

**Compact List:**

```text
Colors: @for color in colors $color@if not loop.last, @end @end
```

**Output:** `Colors: red, green, blue`

**Mixed Block + Inline:**

```yaml
metadata:
  name: $name
  # Block mode (directive on own line)
  labels:
  @for label in labels
    $label.key: $label.value
  @end
  # Inline mode (directive with text on same line)
  status: @if active enabled @else disabled @end
```

### Dash Trimming (Edge Cases Only)

For micro-adjustments, use dash (`-`) to explicitly trim whitespace:

| Syntax | Effect |
|--------|--------|
| `-$var` | Trim whitespace before variable |
| `$var-` | Trim whitespace after variable |
| `@-if x` | Trim before directive output |
| `@if x-` | Trim after directive output |

#### Trim Examples

**Remove extra whitespace:**

```text
text-$value-more
```

**Remove blank line before loop:**

```yaml
items:
@-for item in items
  - $item
@end
```

**Inline with trimming:**

```text
Status: @-if ok- ✓ @-else- ✗ @-end
```

**Note:** Trimming is rarely needed thanks to smart preservation!

---

## Configuration Options

You can override smart preservation behavior globally if needed:

```lua
local luma = require("luma")

-- Disable smart indentation (not recommended)
local result = luma.render(template, context, {
  preserve_indentation = false
})

-- Custom indentation unit
local result = luma.render(template, context, {
  indent_width = 4,  -- Default: 2
  indent_char = "\t" -- Default: " " (space)
})
```

**Note:** These options are rarely needed. Trust the smart defaults!

---

## Best Practices

### ✅ DO

- Let Luma handle indentation automatically (default behavior)
- Indent directives to match your document structure for readability
- Use inline mode naturally (directives on same line as text)
- Use dash trimming (`-`) only when truly needed

### ❌ DON'T

- Add manual indentation inside directive blocks (Luma handles it)
- Over-use trim control (smart defaults work well)
- Override `preserve_indentation` unless absolutely necessary
- Fight against smart defaults - they're designed to work

---

## Comparison with Jinja2

| Feature | Jinja2 | Luma |
|---------|--------|------|
| **Default behavior** | Can add unwanted newlines | Smart preservation everywhere |
| **Inline mode** | Same syntax, needs trim control | Context-aware (automatic) |
| **Whitespace control** | Required frequently (`{%-`, `-%}`) | Rarely needed (dash `-` for edge cases) |
| **Learning curve** | Must understand trim rules | Works intuitively |
| **Maintenance** | Explicit control everywhere | Clean, minimal templates |

---

## Summary

**Luma's whitespace handling is designed to "just work":**

1. **Smart by default** - preserves indentation in all file types
2. **Context-aware inline mode** - automatically detected (zero syntax)
3. **Dash trimming** (`-`) - for rare edge cases only
4. **Configuration options** - for special needs

**Trust the defaults.** Luma is designed to make templates clean and maintainable without thinking about whitespace.
