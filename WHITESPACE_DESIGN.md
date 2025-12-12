# Luma Whitespace Control Design

## Innovation: Smart Preservation + Inline Directives

Unlike Jinja2's manual trim controls (`{%-`, `-%}`), Luma uses an intelligent two-mode system:

### Core Philosophy

**99% of templates need ZERO whitespace control.**

Luma automatically preserves indentation context for ALL file types - not just YAML, but HTML, JSON, Python, configs, markdown, everything.

---

## The Two Modes (Context-Aware)

| Mode | Detection | Behavior | Use Case |
|------|-----------|----------|----------|
| **Block** (default) | Directive on its own line | Preserves structure, natural newlines | 99% of templates |
| **Inline** | Directive with text on same line | Compact, flows with text | Inline conditionals/loops |

### Key Insight

Luma **automatically detects** whether a directive should be inline or block based on context. No special syntax needed - if it looks inline, it behaves inline.

**Plus:** Explicit trim control with dash (`-`) for edge cases.

---

## Why This is Better Than Jinja2

### Jinja2 Approach (Manual Control)

```jinja
{# YAML template - must manually control whitespace #}
spec:
  containers:
  {%- for container in containers %}
    - name: {{ container.name }}
      {%- if container.ports %}
      ports:
        {%- for port in container.ports %}
        - containerPort: {{ port }}
        {%- endfor %}
      {%- endif %}
  {%- endfor %}
```

**Problems:**
- `{%-` and `-%}` everywhere
- Hard to read
- Easy to forget and get extra blank lines
- Different rules for different contexts
- Mental overhead on every directive

### Luma Approach (Smart Default)

```yaml
spec:
  containers:
  @for container in containers
    - name: $container.name
      @if container.ports
      ports:
        @for port in container.ports
        - containerPort: $port
        @end
      @end
  @end
```

**Benefits:**
- Clean, readable
- No whitespace control needed
- Works correctly automatically
- Same behavior across all file types
- Zero mental overhead

---

## Context-Aware Inline Mode

No special syntax - directives automatically become inline when used with text on the same line:

### Inline Conditional (Auto-detected)

```
Status: @if active Success @else Failed @end
```

**Output:** `Status: Success` (no newlines)

### Compact List (Auto-detected)

```
Tags: @for tag in tags $tag@if not loop.last, @end @end
```

**Output:** `Tags: red, green, blue`

### JSON with Precise Formatting

```json
{
  "users": [
@for user in users
    {"id": $user.id, "name": "$user.name"}@if not loop.last,@end
@end
  ]
}
```

## Explicit Whitespace Trimming (Edge Cases)

For rare cases needing precise whitespace control, use dash (`-`):

### Trim Syntax

```
-$var      # Trim whitespace before variable
$var-      # Trim whitespace after variable
@-if x     # Trim before directive output
@if x-     # Trim after directive output
```

### Examples

```yaml
# Remove blank line before loop
@-for item in items
  - $item
@end

# Remove trailing space
text-$value-more

# Inline with trimming
Status: @-if ok- ✓ @-else- ✗ @-end
```

---

## Universal Smart Preservation

This isn't just for YAML - it works **everywhere**:

### HTML

```html
<ul>
@for item in items
  <li>$item</li>
@end
</ul>
```

Indentation preserved perfectly ✅

### Python

```python
class Config:
@for attr in attributes
    $attr.name = $attr.value
@end
```

Indentation preserved perfectly ✅

### Markdown

```markdown
## Features

@for feature in features
### $feature.name

$feature.description

@end
```

Structure preserved perfectly ✅

---

## Design Decisions

### Why Context-Aware Instead of Special Syntax?

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| `@@directive` | Explicit | Visual noise, ambiguous with text | ❌ |
| `@{directive}` | Clear boundaries | Verbose, potential conflicts | ❌ |
| `:@directive` | Short | Unintuitive position | ❌ |
| **Context-aware** | Zero syntax, intuitive, looks inline = is inline | None | ✅ |

### Why Dash (`-`) for Trimming?

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `~` (tilde) | Unique | Unfamiliar, less intuitive | ❌ |
| `\` (backslash) | Escape metaphor | Conflicts with escapes | ❌ |
| `_` (underscore) | Visual | Ambiguous with identifiers | ❌ |
| **`-` (dash)** | Directional, familiar to Jinja2, unambiguous | None | ✅ |

### Why Smart Preservation by Default?

**Problem:** Jinja2 requires manual control because it doesn't understand document structure.

**Solution:** Luma analyzes indentation context and preserves it intelligently.

**Result:** Templates that "just work" without thinking about whitespace.

---

## Implementation Status

- [x] **Smart preservation**: Already implemented and working
- [x] **Documentation**: Complete (docs/WHITESPACE.md, WHITESPACE_DESIGN.md)
- [ ] **Context-aware inline mode**: To be implemented (P2 priority)
- [ ] **Dash trim control** (`-$var`, `@-if`): To be implemented (P2 priority)
- [ ] **Jinja2 trim-before** (`{%-`): For Jinja2 compat only (P1 for parity)

---

## Migration from Jinja2

### Before (Jinja2)

```jinja
{%- for item in items %}
  {{- item -}}
{%- endfor %}
```

### After (Luma)

```
@for item in items -$item- @end
```

Or even simpler (inline mode auto-detected):

```
@for item in items $item @end
```

**90% of Jinja2 whitespace control can be removed entirely** when migrating to Luma!

---

## Summary

**Luma's whitespace philosophy:**

1. **Smart by default** - preserves indentation universally
2. **Context-aware** - inline mode detected automatically (zero syntax)
3. **Minimal trimming** - dash (`-`) for edge cases only
4. **Zero mental overhead** - it just works
5. **All file types** - not just YAML
6. **Clean templates** - no visual clutter

**This is true innovation** - not copying Jinja2's manual approach, but solving the problem properly with intelligent defaults and context awareness.

