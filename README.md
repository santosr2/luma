# Luma

A language-agnostic, Lua-powered templating engine with clean, directive-based syntax.

Luma is designed as a modern alternative to Jinja2-style templating with:
- Less punctuation noise
- Line-based directives
- Familiar `$variable` interpolation (like shell/JS)
- Pure Lua implementation for maximum portability

## Installation

```bash
# Using LuaRocks (coming soon)
luarocks install luma

# Or clone and use directly
git clone https://github.com/yourusername/luma_templates
```

## Quick Start

```lua
local luma = require("luma")

-- Simple rendering
local result = luma.render("Hello, $name!", { name = "World" })
-- Output: "Hello, World!"

-- Compile for reuse
local template = luma.compile("Hello, $name!")
print(template:render({ name = "Alice" }))
print(template:render({ name = "Bob" }))
```

## Syntax

### Interpolation

```
$var                    -- Simple variable
$user.name              -- Member access
${expr}                 -- Expression with full features
${name | upper}         -- With filter
${val | default("N/A")} -- With filter and args
$$                      -- Escaped $ (literal $)
```

### Directives

Directives start with `@` at the beginning of a line (after optional indentation):

```
@if condition
  Content when true
@elif other_condition
  Content for elif
@else
  Content when false
@end

@for item in items
  - $item
@else
  No items found
@end

@let total = price * quantity

@# This is a comment (not rendered)
```

Directives can be indented to match your file structure (great for YAML/configs):

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

### Filters

```lua
-- String filters
${name | upper}           -- Uppercase
${name | lower}           -- Lowercase
${name | capitalize}      -- Capitalize first letter
${name | title}           -- Title Case
${text | trim}            -- Remove whitespace

-- Collection filters
${items | first}          -- First element
${items | last}           -- Last element
${items | length}         -- Count
${items | join(", ")}     -- Join with separator
${items | reverse}        -- Reverse order
${items | sort}           -- Sort

-- Number filters
${num | abs}              -- Absolute value
${num | round(2)}         -- Round to precision
${num | floor}            -- Floor
${num | ceil}             -- Ceiling

-- Default value
${missing | default("fallback")}
```

### Loop Variables

Inside `@for` loops, you have access to `loop` metadata:

```
@for item in items
  ${loop.index}   -- 1-based index
  ${loop.index0}  -- 0-based index
  ${loop.first}   -- true if first iteration
  ${loop.last}    -- true if last iteration
  ${loop.length}  -- total items
@end
```

## API Reference

### Basic Usage

```lua
local luma = require("luma")

-- Render a template string
local result = luma.render(template_string, context)

-- Compile for reuse
local compiled = luma.compile(template_string)
local result = compiled:render(context)
```

### Custom Environment

```lua
local env = luma.create_environment()

-- Add custom filter
env:add_filter("double", function(s)
    return s .. s
end)

-- Add global variable
env:add_global("site_name", "My Site")

-- Render with custom environment
local result = env:render("Welcome to $site_name!", {})
```

### Register Global Filters

```lua
luma.register_filter("exclaim", function(s)
    return s .. "!"
end)

-- Now available in all templates
local result = luma.render("${msg | exclaim}", { msg = "Hello" })
-- Output: "Hello!"
```

## Example: Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app.name
  namespace: ${namespace | default("default")}
spec:
  replicas: ${replicas | default(1)}
  template:
    spec:
      containers:
@for container in containers
        - name: $container.name
          image: ${container.image}:${container.tag | default("latest")}
@if container.ports
          ports:
@for port in container.ports
            - containerPort: $port
@end
@end
@end
```

Compare this to equivalent Helm/Go templates - much cleaner!

## Running Tests

```bash
# Install busted
luarocks install busted

# Run tests
busted spec/
```

## License

MIT

## Comparison with Jinja2

| Feature | Jinja2 | Luma |
|---------|--------|------|
| Variable | `{{ name }}` | `$name` |
| Expression | `{{ expr }}` | `${expr}` |
| If block | `{% if %}...{% endif %}` | `@if...@end` |
| For loop | `{% for %}...{% endfor %}` | `@for...@end` |
| Comment | `{# comment #}` | `@# comment` |
| Filters | `{{ x \| filter }}` | `${x \| filter}` |

Luma aims for less visual noise while maintaining full expressiveness.
