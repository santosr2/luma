---
render_with_liquid: false
---

# Luma API Documentation

Complete API reference for the Luma template engine.

## Table of Contents

1. [Core API](#core-api)
2. [Compiler API](#compiler-api)
3. [Runtime API](#runtime-api)
4. [Filters API](#filters-api)
5. [Python Bindings](#python-bindings)

---

## Core API

### `luma.render(template, context, options)`

Render a template string with context data.

**Parameters:**

- `template` (string): Template source code
- `context` (table): Variables to pass to template
- `options` (table, optional): Rendering options
  - `syntax` (string): "auto", "jinja", or "luma" (default: "auto")
  - `no_jinja_warning` (boolean): Suppress Jinja2 syntax warning
  - `name` (string): Template name for error messages

**Returns:** (string) Rendered output

**Example:**

```lua
local luma = require("luma")

local result = luma.render("Hello, $name!", {name = "World"})
print(result)  -- "Hello, World!"
```

**Error Handling:**

```lua
local ok, result = pcall(function()
    return luma.render(template, context)
end)

if not ok then
    print("Error:", result)
end
```

### `luma.compile(template, options)`

Compile a template for reuse.

**Parameters:**

- `template` (string): Template source code
- `options` (table, optional): Compilation options
  - `syntax` (string): Template syntax mode
  - `name` (string): Template name

**Returns:** (table) Compiled template object

**Example:**

```lua
local luma = require("luma")

-- Compile once
local compiled = luma.compile("Hello, $name!")

-- Render many times
local filters = require("luma.filters")
local runtime = require("luma.runtime")

for _, user in ipairs(users) do
    local result = compiled:render(
        {name = user.name},
        filters.get_all(),
        runtime
    )
    print(result)
end
```

**Performance:** Compiling and reusing templates is 50-100x faster than rendering from source each time.

### `luma.new_environment(options)`

Create a template environment with shared state.

**Parameters:**

- `options` (table, optional): Environment options
  - `paths` (table): Template search paths
  - `filters` (table): Custom filters
  - `globals` (table): Global variables

**Returns:** (table) Environment object

**Methods:**

- `env:render(template, context)` - Render template string
- `env:render_file(name, context)` - Render template file
- `env:compile(template)` - Compile template

**Example:**

```lua
local luma = require("luma")

local env = luma.new_environment({
    paths = {"/templates", "."},
    globals = {site_name = "My Site"},
})

local result = env:render_file("page.luma", {title = "Home"})
```

---

## Compiler API

### `compiler.compile(source, options)`

Low-level template compilation.

**Parameters:**

- `source` (string): Template source code
- `options` (table): Compilation options

**Returns:** (table) Compiled template with metadata

**Example:**

```lua
local compiler = require("luma.compiler")

local compiled = compiler.compile(source, {name = "mytemplate"})

-- Access metadata
print("Template name:", compiled.name)
print("Source:", compiled.source)  -- Generated Lua code
print("Dependencies:", #compiled.dependencies)
```

### `compiled:render(context, filters, runtime, macros, tests)`

Render a compiled template.

**Parameters:**

- `context` (table): Template variables
- `filters` (table): Available filters
- `runtime` (table): Runtime utilities
- `macros` (table, optional): Pre-defined macros
- `tests` (table, optional): Test functions

**Returns:** (string) Rendered output

---

## Runtime API

### `runtime.escape(value, column)`

HTML-escape a value.

**Parameters:**

- `value` (any): Value to escape
- `column` (number, optional): Column for error reporting

**Returns:** (string) HTML-escaped string

**Example:**

```lua
local runtime = require("luma.runtime")

local escaped = runtime.escape("<script>alert('xss')</script>")
-- Returns: "&lt;script&gt;alert('xss')&lt;/script&gt;"
```

### `runtime.set_paths(paths)`

Set template search paths.

**Parameters:**

- `paths` (table): Array of directory paths

**Example:**

```lua
local runtime = require("luma.runtime")

runtime.set_paths({"/usr/share/templates", "./templates", "."})
```

### `runtime.load_source(name)`

Load template source by name.

**Parameters:**

- `name` (string): Template name or path

**Returns:**

- `source` (string|nil): Template source
- `error` (string|nil): Error message if not found

**Example:**

```lua
local runtime = require("luma.runtime")

local source, err = runtime.load_source("layout.luma")
if not source then
    error("Template not found: " .. err)
end
```

### `runtime.namespace(initial)`

Create a mutable namespace object for templates.

**Parameters:**

- `initial` (table, optional): Initial values

**Returns:** (table) Namespace object

**Example (in template):**

{% raw %}
```lua
{% set ns = namespace(count=0) %}
{% for item in items %}
  {% do ns.count = ns.count + 1 %}
{% endfor %}
Total: {{ ns.count }}
```
{% endraw %}

---

## Filters API

### Built-in Filters

#### String Filters

**`upper`** - Convert to uppercase

{% raw %}
```lua
{{ "hello" | upper }}  -- "HELLO"
```
{% endraw %}

**`lower`** - Convert to lowercase

{% raw %}
```lua
{{ "HELLO" | lower }}  -- "hello"
```
{% endraw %}

**`title`** - Title case

{% raw %}
```lua
{{ "hello world" | title }}  -- "Hello World"
```
{% endraw %}

**`capitalize`** - Capitalize first letter

{% raw %}
```lua
{{ "hello" | capitalize }}  -- "Hello"
```
{% endraw %}

**`trim`** - Remove whitespace

{% raw %}
```lua
{{ "  hello  " | trim }}  -- "hello"
```
{% endraw %}

**`truncate(length, end)`** - Truncate string

{% raw %}
```lua
{{ "Long text" | truncate(5) }}  -- "Long..."
{{ "Long text" | truncate(5, "…") }}  -- "Long…"
```
{% endraw %}

**`replace(old, new)`** - Replace substring

{% raw %}
```lua
{{ "hello world" | replace("world", "Lua") }}  -- "hello Lua"
```
{% endraw %}

#### List Filters

**`length`** - Get length

{% raw %}
```lua
{{ items | length }}  -- number of items
```
{% endraw %}

**`join(sep)`** - Join list elements

{% raw %}
```lua
{{ ["a", "b", "c"] | join(", ") }}  -- "a, b, c"
```
{% endraw %}

**`first`** - First element

{% raw %}
```lua
{{ items | first }}
```
{% endraw %}

**`last`** - Last element

{% raw %}
```lua
{{ items | last }}
```
{% endraw %}

**`sort`** - Sort list

{% raw %}
```lua
{{ [3, 1, 2] | sort }}  -- [1, 2, 3]
```
{% endraw %}

**`reverse`** - Reverse list

{% raw %}
```lua
{{ [1, 2, 3] | reverse }}  -- [3, 2, 1]
```
{% endraw %}

#### Numeric Filters

**`abs`** - Absolute value

{% raw %}
```lua
{{ -5 | abs }}  -- 5
```
{% endraw %}

**`round(precision)`** - Round number

{% raw %}
```lua
{{ 3.14159 | round(2) }}  -- 3.14
```
{% endraw %}

**`format(fmt)`** - Format number

{% raw %}
```lua
{{ 1234.5 | format("%.2f") }}  -- "1234.50"
```
{% endraw %}

#### Date/Time Filters

**`date(format)`** - Format timestamp

{% raw %}
```lua
{{ timestamp | date("%Y-%m-%d") }}
```
{% endraw %}

#### Misc Filters

**`default(value)`** - Default if nil/empty

{% raw %}
```lua
{{ var | default("N/A") }}
```
{% endraw %}

**`escape`** - HTML escape (alias: `e`)

{% raw %}
```lua
{{ "<script>" | escape }}  -- "&lt;script&gt;"
```
{% endraw %}

### Custom Filters

**Define custom filter:**

```lua
local filters = require("luma.filters")

filters.add("double", function(value)
    return value * 2
end)

filters.add("greet", function(name, greeting)
    greeting = greeting or "Hello"
    return greeting .. ", " .. name .. "!"
end)
```

**Use in template:**

{% raw %}
```lua
{{ 5 | double }}  -- 10
{{ "Alice" | greet }}  -- "Hello, Alice!"
{{ "Bob" | greet("Hi") }}  -- "Hi, Bob!"
```
{% endraw %}

---

## Python Bindings

### Template Class

{% raw %}
```python
from luma import Template

# Create template
template = Template("Hello, {{ name }}!", syntax="jinja")

# Render with kwargs
result = template.render(name="World")

# Render with dict
result = template.render_dict({"name": "World"})

# String representation
print(repr(template))  # <Template source="...">
```
{% endraw %}

### Environment Class

```python
from luma import Environment
from luma.loaders import FileSystemLoader

# Create environment
env = Environment(
    loader=FileSystemLoader("/path/to/templates"),
    autoescape=True
)

# Set globals
env.globals["site_name"] = "My Site"

# Add filter
env.filters["double"] = lambda x: x * 2

# Render template
template = env.get_template("page.html")
result = template.render(title="Home", items=[1, 2, 3])
```

### Loaders

**FileSystemLoader:**

```python
from luma.loaders import FileSystemLoader

loader = FileSystemLoader("/templates", encoding="utf-8")
```

**DictLoader:**

{% raw %}
```python
from luma.loaders import DictLoader

loader = DictLoader({
    "index.html": "Hello, {{ name }}!",
    "about.html": "About page",
})
```
{% endraw %}

**PackageLoader:**

```python
from luma.loaders import PackageLoader

loader = PackageLoader("myapp", "templates")
```

### Exceptions

```python
from luma.exceptions import (
    TemplateError,
    TemplateSyntaxError,
    TemplateNotFoundError,
)

try:
    result = template.render(**data)
except TemplateSyntaxError as e:
    print(f"Syntax error: {e}")
except TemplateError as e:
    print(f"Template error: {e}")
```

---

## Error Handling

### Compilation Errors

```lua
local luma = require("luma")

local ok, compiled = pcall(function()
    return luma.compile(template_source)
end)

if not ok then
    -- compiled contains error message
    print("Compilation failed:", compiled)
end
```

### Runtime Errors

```lua
local ok, result = pcall(function()
    return compiled:render(context, filters, runtime)
end)

if not ok then
    print("Runtime error:", result)
end
```

### Error Messages

Luma provides detailed error messages with:

- Line and column numbers
- Context snippet
- Error description
- Stack trace

Example error:

{% raw %}
```text
ParseError: Expected 'end' after 'for' block
  at template.luma:15:1
  
  13 | @for item in items
  14 |   - {{ item }}
> 15 | @if condition
```
{% endraw %}

---

## Performance Tips

1. **Compile Once, Reuse Many Times**

   ```lua
   local compiled = luma.compile(template)
   for i = 1, 1000 do
       compiled:render(data, filters, runtime)
   end
   ```

   *50-100x faster than re-compiling each time*

2. **Use Native Syntax**
   - Luma native syntax is cleaner and slightly faster
   - Jinja2 syntax has minimal overhead

3. **Pre-structure Data**
   - Prepare data before rendering
   - Avoid complex transformations in templates

4. **Cache Compiled Templates**

   ```lua
   local cache = {}
   
   function get_template(name)
       if not cache[name] then
           local source = load_template_source(name)
           cache[name] = luma.compile(source)
       end
       return cache[name]
   end
   ```

---

## Thread Safety

- Compiled templates are **read-only** and **thread-safe**
- Context data should be **unique per render**
- Filters and runtime are **stateless** and safe to share

**Multi-threaded example (conceptual):**

```lua
local compiled = luma.compile(template)  -- Shared
local filters = require("luma.filters").get_all()  -- Shared
local runtime = require("luma.runtime")  -- Shared

-- In each thread:
local result = compiled:render(
    {user = thread_specific_user},  -- Thread-local context
    filters,
    runtime
)
```

---

## See Also

- [Integration Guides](INTEGRATION_GUIDES.md)
- [Examples](../examples/)
- [Benchmarks](../benchmarks/)
- [Contributing](../CONTRIBUTING.md)
