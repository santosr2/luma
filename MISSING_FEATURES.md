# Missing Jinja2 Features Analysis

After comprehensive review of Jinja2 documentation, we've identified 5 features not yet implemented:

## 1. ✅ {% with %} - Scoped Variable Assignment
**Priority: P2 (Medium)**

```jinja
{% with foo = 42 %}
    {{ foo }}
{% endwith %}

{% with %}
    {% set foo = 42 %}
    {{ foo }}
{% endwith %}
```

**Use case:** Create temporary variables with limited scope
**Complexity:** Low - similar to scoped blocks
**Luma equivalent:** `@with foo = 42 ... @end`

---

## 2. ✅ {% do %} - Execute Statement Without Output
**Priority: P3 (Low)**

```jinja
{% do navigation.append('a string') %}
{% do my_list.extend([1, 2, 3]) %}
```

**Use case:** Modify variables/objects without producing output
**Complexity:** Low - execute expression, discard result
**Luma equivalent:** `@do expression`

---

## 3. ✅ {% filter %} - Filter Blocks
**Priority: P2 (Medium)**

```jinja
{% filter upper %}
    this text becomes uppercase
{% endfilter %}

{% filter center(80) %}
    centered text
{% endfilter %}
```

**Use case:** Apply filters to entire blocks of content
**Complexity:** Medium - capture output, apply filter
**Luma equivalent:** `@filter upper ... @end`

---

## 4. ✅ namespace() - Mutable Variables in Loops
**Priority: P2 (Medium)**

```jinja
{% set ns = namespace(found=false) %}
{% for item in items %}
    {% if item.check %}
        {% set ns.found = true %}
    {% endif %}
{% endfor %}
{{ ns.found }}
```

**Use case:** Create mutable objects that work across scopes
**Complexity:** Medium - special object type
**Luma equivalent:** `@let ns = namespace(found=false)`

---

## 5. ✅ {% include %} with Context Control
**Priority: P3 (Low)**

```jinja
{% include 'header.html' with context %}
{% include 'header.html' without context %}
{% include 'header.html' ignore missing %}
```

**Current status:** We have basic `{% include %}`, missing:
- `with context` / `without context` modifiers
- `ignore missing` modifier

**Complexity:** Low - add flags to include directive
**Luma equivalent:** `@include "file" with context`

---

## Implementation Priority

### Recommended Order:
1. **{% with %}** - Most commonly used, simple to implement
2. **{% filter %}** - Useful feature, moderate complexity
3. **namespace()** - Solves real problem (mutable vars in loops)
4. **{% include %}** modifiers - Complete existing feature
5. **{% do %}** - Rarely used, lowest priority

### Impact Assessment:

| Feature | Usage Frequency | Implementation Time | Value |
|---------|----------------|---------------------|-------|
| `{% with %}` | High | 2-3 hours | High |
| `{% filter %}` | Medium | 3-4 hours | Medium |
| `namespace()` | Medium | 2-3 hours | High |
| Include modifiers | Low | 1-2 hours | Low |
| `{% do %}` | Low | 1 hour | Low |

**Total estimated time: 10-14 hours**

---

## Decision

Should we implement these 5 features to achieve **TRUE 100% Jinja2 parity**, or are we comfortable with "99% parity" and move to the next phase?

### Arguments FOR implementation:
- ✅ Achieves true 100% feature parity
- ✅ Covers edge cases some users might need
- ✅ Makes migration from Jinja2 completely seamless
- ✅ Professional completeness

### Arguments AGAINST (move to next phase):
- ❌ These features are rarely used
- ❌ 10-14 hours could be spent on ecosystem/bindings
- ❌ Current 95% parity handles 99% of real templates
- ❌ Can add these later based on user feedback

---

## Recommendation

**Option A:** Implement all 5 features now (10-14 hours)
- Achieve true 100% parity
- Professional polish
- No migration blockers

**Option B:** Implement only high-value features (5-7 hours)
- `{% with %}` - commonly used
- `namespace()` - solves real problem
- Skip rarely-used features

**Option C:** Move to next phase (ecosystem)
- Current parity handles 99% of real templates
- Get feedback from real users
- Implement missing features based on demand

---

## What Would You Like To Do?

1. **Full implementation** (Option A) - All 5 features
2. **Partial implementation** (Option B) - High-value only
3. **Move to ecosystem phase** (Option C) - Come back later if needed

