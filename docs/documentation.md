---
layout: default
title: Documentation
render_with_liquid: false
---

# Luma Documentation

Complete reference for the Luma template engine.

## Quick Links

- [API Reference](API.html) - Complete API documentation
- [Jinja2 Migration Guide](JINJA2_MIGRATION.html) - Migrate from Jinja2
- [Integration Guides](INTEGRATION_GUIDES.html) - Framework integrations
- [Whitespace Control](WHITESPACE.html) - Smart whitespace handling

---

## Language Reference

### Variables

#### Simple Variables

```luma
$name
$user.email
$config.server.host
```

#### Complex Expressions

```luma
${1 + 2}
${price * quantity}
${users[0].name}
${dict["key"]}
```

#### Variable Assignment

```luma
@let name = "Alice"
@let age = 30
@let items = ["apple", "banana", "cherry"]
```

---

### Control Flow

#### If Statements

```luma
@if condition
  True branch
@end

@if x > 10
  Large
@elif x > 5
  Medium
@else
  Small
@end
```

#### For Loops

```luma
@# List iteration
@for item in items
  - $item
@end

@# Dictionary iteration
@for key, value in pairs(dict)
  ${key}: $value
@end

@# Array iteration with index
@for i, value in ipairs(array)
  ${i}. $value
@end

@# Tuple unpacking
@for name, age in users
  $name is $age years old
@end
```

#### Loop Variables

```luma
@for item in items
  Index: $loop.index (1-based)
  Index0: $loop.index0 (0-based)
  First: $loop.first (boolean)
  Last: $loop.last (boolean)
  Length: $loop.length
  Previous: $loop.previtem
  Next: $loop.nextitem
  
  @# Cycle through values
  $loop.cycle("odd", "even")
@end
```

#### Loop Control

```luma
@for item in items
  @if item.skip
    @continue
  @end
  
  @if item.stop
    @break
  @end
  
  Process: $item
@end
```

#### While Loops

```luma
@let count = 0
@while count < 10
  Count: $count
  @let count = count + 1
@end
```

---

### Filters

Filters transform values using the pipe operator:

```luma
$value | filter
$value | filter(arg1, arg2)
$value | filter1 | filter2 | filter3
```

#### String Filters

```luma
$text | upper
$text | lower
$text | capitalize
$text | title
$text | trim
$text | replace("old", "new")
$text | truncate(50)
$text | center(80)
$text | wordwrap(60)
$text | indent(4)
$text | striptags
$text | urlencode
$text | escape
```

#### List Filters

```luma
$items | length
$items | first
$items | last
$items | join(", ")
$items | sort
$items | reverse
$items | unique
$items | sum
$items | min
$items | max
$items | map("name")
$items | select("active")
$items | reject("deleted")
$items | selectattr("status", "active")
$items | rejectattr("hidden", true)
$items | groupby("category")
$items | batch(3)
$items | slice(2)
```

#### Dictionary Filters

```luma
$dict | keys
$dict | values
$dict | items
$dict | dictsort
```

#### Type Filters

```luma
$value | default("fallback")
$value | default(0)
$obj | attr("property")
$data | tojson
```

#### Numeric Filters

```luma
$number | round
$number | round(2)
$number | abs
```

#### Named Arguments

```luma
$text | truncate(length=50, killwords=true, end="...")
$text | wordwrap(width=80, break_long_words=false)
$text | indent(width=4, first=false)
```

See [API Reference - Filters](API.html#filters) for complete list.

---

### Tests

Tests check conditions using `is`:

```luma
@if value is defined
@if value is undefined
@if value is none
@if value is string
@if value is number
@if value is boolean
@if value is table
@if value is callable
@if value is iterable
@if value is mapping
@if value is sequence
@if value is odd
@if value is even
@if value is divisibleby(3)
@if value is lower
@if value is upper
```

#### Negation

```luma
@if value is not defined
@if value is not none
@if x is not even
```

See [API Reference - Tests](API.html#tests) for complete list.

---

### Membership Operators

```luma
@if "key" in dict
@if item in list
@if "sub" in string
@if x not in collection
```

---

### Template Inheritance

#### Extends

**Base Template (`base.luma`):**

```luma
<!DOCTYPE html>
<html>
<head>
  @block head
    <title>Default Title</title>
  @end
</head>
<body>
  @block content
    Default content
  @end
</body>
</html>
```

**Child Template:**

```luma
@extends "base.luma"

@block head
  <title>My Page</title>
@end

@block content
  <h1>Hello, World!</h1>
@end
```

#### Super Function

Call parent block content:

```luma
@extends "base.luma"

@block content
  $super()
  Additional content
@end
```

#### Scoped Blocks

```luma
@for user in users
  @block user_card scoped
    <div>$user.name</div>
  @end
@end
```

---

### Includes

```luma
@# Simple include
@include "header.luma"

@# Include with context
@include "card.luma" with title="Hello", content="World"

@# Include with namespace
@include "config.luma" ignore missing
```

---

### Macros

#### Define Macros

```luma
@macro button(text, type="default")
  <button class="btn btn-$type">$text</button>
@end

@macro card(title, content)
  <div class="card">
    <h3>$title</h3>
    <p>$content</p>
  </div>
@end
```

#### Call Macros

```luma
@call button("Click Me")
@call button("Submit", type="primary")
@call card("Title", "Content goes here")
```

#### Import Macros

```luma
@# Import all macros
@import "macros.luma"

@# Import specific macros
@from "macros.luma" import button, card

@# Import with alias
@from "macros.luma" import button as btn
```

#### Call with Caller

```luma
@# Define macro that accepts caller
@macro list(items)
  <ul>
  @for item in items
    <li>$caller(item)</li>
  @end
  </ul>
@end

@# Use with caller block
@call(item) list(["a", "b", "c"])
  Item: $item
@end
```

---

### Do Blocks

Execute code without output:

```luma
@do
  @let result = expensive_calculation()
  @let formatted = result | format
@end

Result: $formatted
```

---

### Set Blocks

Multi-line variable assignment:

```luma
@let html_content
  <div>
    <h1>Title</h1>
    <p>Content</p>
  </div>
@end

$html_content
```

---

### Namespaces

Mutable objects for variable management:

```luma
@do
  @let ns = namespace(count=0, found=false)
@end

@for item in items
  @if item.match
    @do
      ns.found = true
      ns.count = ns.count + 1
    @end
  @end
@end

Found: $ns.found, Count: $ns.count
```

---

### Comments

```luma
@# Single-line comment

@comment
Multi-line comment
Can span multiple lines
@end
```

---

### Raw Blocks

Disable template processing:

```luma
@raw
This $variable will not be processed
@if statements are ignored too
@end
```

**Jinja2 syntax:**

```jinja
&#123;% raw %&#125;
&#123;&#123; this &#125;&#125; will not be processed
&#123;% endraw %&#125;
```

---

### Autoescape

Control HTML escaping:

```luma
@autoescape true
  $user_input  @# Will be escaped
@end

@autoescape false
  $trusted_html  @# Will not be escaped
@end
```

**Mark content as safe:**

```luma
@let safe_html = html | safe
$safe_html  @# Won't be escaped even in autoescape blocks
```

---

## Whitespace Control

### Smart Preservation (Default)

Luma automatically preserves indentation for all file types:

```yaml
# YAML example - indentation preserved automatically
containers:
@for container in containers
  - name: $container.name
    image: $container.image
@end
```

### Dash Trimming

For precise control, use dash (`-`) syntax:

```luma
@# Trim before
text-$value

@# Trim after
$value-text

@# Trim both
text-$value-more

@# Trim with directives
-@if condition
  content
@end
```

### Inline Mode

Use semicolons for inline directives:

```luma
Status: @if active; Online @else Offline @end

Result: @for i in {1,2,3}; $i @end
```

### Jinja2 Trim Syntax

```jinja
&#123;%- if condition -%&#125;
  &#123;&#123;- value -&#125;&#125;
&#123;%- endif -%&#125;
```

See [Whitespace Control Guide](WHITESPACE.html) for details.

---

## Jinja2 Syntax

Luma supports full Jinja2 syntax for compatibility:

```jinja
&#123;% set name = "World" %&#125;
Hello, &#123;&#123; name &#125;&#125;!

&#123;% if condition %&#125;
  True
&#123;% elif other %&#125;
  Maybe
&#123;% else %&#125;
  False
&#123;% endif %&#125;

&#123;% for item in items %&#125;
  - &#123;&#123; item &#125;&#125;
&#123;% endfor %&#125;

&#123;% macro button(text) %&#125;
  <button>&#123;&#123; text &#125;&#125;</button>
&#123;% endmacro %&#125;

&#123;&#123; button("Click") &#125;&#125;
```

**Migration:**

```bash
luma migrate template.j2 > template.luma
```

See [Jinja2 Migration Guide](JINJA2_MIGRATION.html).

---

## Best Practices

### 1. Use Native Syntax for Readability

```luma
@# Preferred - clean and readable
@if condition
  $value
@end

@# Also works but less clean
&#123;% if condition %&#125;
  &#123;&#123; value &#125;&#125;
&#123;% endif %&#125;
```

### 2. Leverage Smart Whitespace

```yaml
# No manual trimming needed
apiVersion: v1
kind: Service
metadata:
  name: $service_name
spec:
@if ports
  ports:
@for port in ports
    - port: $port.port
      targetPort: $port.targetPort
@end
@end
```

### 3. Use Macros for Reusability

```luma
@# Define once
@macro alert(message, type="info")
  <div class="alert alert-$type">$message</div>
@end

@# Use many times
@call alert("Success!", type="success")
@call alert("Warning!", type="warning")
```

### 4. Filter Data Appropriately

```luma
@# Always escape user input for HTML
<div>${user_input | escape}</div>

@# Use appropriate filters
$email | lower
$name | title
$date | date_format
```

### 5. Organize Templates

```text
templates/
├── base.luma           # Base layouts
├── components/         # Reusable components
│   ├── header.luma
│   └── footer.luma
├── macros/            # Macro libraries
│   ├── forms.luma
│   └── cards.luma
└── pages/             # Page templates
    ├── home.luma
    └── about.luma
```

---

## Performance Tips

### 1. Compile Once, Render Many

```lua
local luma = require("luma")

-- Compile once
local compiled = luma.compile(template_string)

-- Render many times (fast!)
for i = 1, 1000 do
    local result = compiled(context)
end
```

### 2. Enable Template Caching

```lua
local luma = require("luma")
luma.enable_cache()

-- Templates are cached automatically
for i = 1, 1000 do
    luma.render(template_string, context)
end
```

### 3. Use LuaJIT

```bash
# Use LuaJIT for 3-5x performance improvement
luajit your_script.lua
```

### 4. Minimize Filter Chains

```luma
@# Less efficient
$value | filter1 | filter2 | filter3 | filter4

@# More efficient - combine when possible
$value | combined_filter
```

---

## Error Handling

### Syntax Errors

```text
Error: Syntax error in template at line 5, column 12
  Expected 'end' but found 'elif'
  
  @if condition
    something
  @elif other  <-- Error here
```

### Undefined Variables

```lua
-- Handle missing variables
local luma = require("luma")
luma.strict_undefined = false  -- Don't error on undefined
```

```luma
@# Use defaults for safety
${maybe_undefined | default("fallback")}

@# Check if defined
@if value is defined
  $value
@else
  Not available
@end
```

### Validation

```bash
# Validate template syntax
luma validate template.luma

# Validate all templates
luma validate templates/**/*.luma
```

---

## Next Steps

- [API Reference](API.html) - Detailed API documentation
- [Examples](examples.html) - Real-world examples
- [Integration Guides](INTEGRATION_GUIDES.html) - Framework integrations
- [Contributing](https://github.com/santosr2/luma/blob/main/CONTRIBUTING.md) - Contribute to Luma
