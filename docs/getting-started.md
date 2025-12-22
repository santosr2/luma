---
layout: default
title: Getting Started
---

# Getting Started with Luma

This guide will help you install Luma and create your first templates.

## Installation

### Using LuaRocks (Recommended)

```bash
luarocks install luma
```

### Using Homebrew (macOS/Linux)

```bash
brew install luma
```

### Using Docker

```bash
# Pull the image
docker pull luma/luma

# Run a template
docker run -v $(pwd):/templates luma/luma render template.luma --data-file context.yaml
```

### From Source

```bash
git clone https://github.com/santosr2/luma.git
cd luma
make install
```

---

## Your First Template

### 1. Create a Template File

Create a file named `hello.luma`:

```luma
@# This is a comment
@let name = "World"

Hello, $name!

@if name == "World"
  Welcome to Luma templating!
@end
```

### 2. Render the Template

**Using the CLI:**

```bash
luma render hello.luma
```

**Using Lua:**

```lua
local luma = require("luma")

-- Render from string
local template = [[
Hello, $name!
@if excited
  This is amazing!
@end
]]

local result = luma.render(template, {
    name = "Developer",
    excited = true
})

print(result)
```

**Using Python:**

```python
from luma import Luma

luma = Luma()
result = luma.render("""
Hello, $name!
@if excited
  This is amazing!
@end
""", {
    "name": "Developer",
    "excited": True
})

print(result)
```

---

## Basic Concepts

### Variables

**Simple Variables:**

```luma
$name
$user.email
$config.database.host
```

**Complex Expressions:**

```luma
${1 + 2}
${users[0].name}
${price * quantity}
```

### Control Flow

**If Statements:**

```luma
@if condition
  Do something
@elif other_condition
  Do something else
@else
  Default action
@end
```

**For Loops:**

```luma
@# Iterate over a list
@for item in items
  - $item
@end

@# Iterate with index
@for i, value in ipairs(data)
  ${i}. $value
@end

@# Iterate over dictionary
@for key, value in pairs(config)
  ${key}: $value
@end
```

**While Loops:**

```luma
@let count = 0
@while count < 5
  Count: $count
  @let count = count + 1
@end
```

### Filters

Filters transform values using the pipe (`|`) operator:

```luma
@# String filters
$name | upper
$title | lower | capitalize
$text | truncate(50)

@# Number filters
$price | round(2)
$items | length

@# List filters
$tags | join(", ")
$numbers | sort | first
```

See [API Reference](/API#filters) for all available filters.

### Comments

```luma
@# Single-line comment

@comment
Multi-line comment
Can span multiple lines
@end
```

---

## Jinja2 Compatibility

If you're coming from Jinja2, you can use the familiar syntax:

```jinja
&#123;% set name = "World" %&#125;
Hello, &#123;&#123; name &#125;&#125;!

&#123;% if condition %&#125;
  Do something
&#123;% endif %&#125;

&#123;% for item in items %&#125;
  - &#123;&#123; item &#125;&#125;
&#123;% endfor %&#125;
```

**Migration Tool:**

Convert Jinja2 templates to native Luma syntax:

```bash
luma migrate template.j2 > template.luma
```

See [Jinja2 Migration Guide](/JINJA2_MIGRATION) for details.

---

## Template Files

### File Structure

```text
templates/
├── base.luma           # Base template
├── components/
│   ├── header.luma     # Reusable components
│   └── footer.luma
├── pages/
│   ├── home.luma       # Page templates
│   └── about.luma
└── macros.luma         # Macro library
```

### Template Inheritance

**Base Template (`base.luma`):**

```luma
<!DOCTYPE html>
<html>
<head>
  <title>@block title; Default Title @end</title>
</head>
<body>
  <header>
    @include "components/header.luma"
  </header>
  
  <main>
    @block content
      Default content
    @end
  </main>
  
  <footer>
    @include "components/footer.luma"
  </footer>
</body>
</html>
```

**Child Template (`pages/home.luma`):**

```luma
@extends "base.luma"

@block title
  Home - My Site
@end

@block content
  <h1>Welcome Home!</h1>
  <p>This is the home page.</p>
@end
```

### Includes and Imports

**Include a Template:**

```luma
@# Include entire template
@include "components/header.luma"

@# Include with context variables
@include "components/card.luma" with title="Hello", content="World"
```

**Import Macros:**

```luma
@# Import specific macros
@from "macros.luma" import button, card

@call button("Click Me", type="primary")
```

---

## Working with Data

### Passing Context Data

**CLI with JSON:**

```bash
luma render template.luma --data '{"name": "Alice", "age": 30}'
```

**CLI with YAML file:**

```bash
# context.yaml
name: Alice
age: 30
items:
  - apple
  - banana
  - cherry

# Render
luma render template.luma --data-file context.yaml
```

**In Lua:**

```lua
local luma = require("luma")
local result = luma.render("Hello, $name!", {
    name = "Alice",
    items = {"apple", "banana", "cherry"}
})
```

**In Python:**

```python
from luma import Luma

luma = Luma()
result = luma.render("Hello, $name!", {
    "name": "Alice",
    "items": ["apple", "banana", "cherry"]
})
```

### Accessing Data

```luma
@# Simple variables
$name
$age

@# Nested data
$user.profile.email
$config.database.host

@# Lists/arrays
$items[0]
$users[2].name

@# With defaults
${name | default("Guest")}
${config.port | default(8080)}
```

---

## Common Patterns

### Configuration Files

**YAML Configuration:**

```luma
# config.yaml
server:
  host: $config.host
  port: ${config.port | default(8080)}
  debug: ${config.debug | default(false)}

database:
  host: $db.host
  port: ${db.port | default(5432)}
@if db.replicas
  replicas:
@for replica in db.replicas
    - host: $replica.host
      port: $replica.port
@end
@end
```

### Lists and Tables

```luma
@# Generate markdown table
| Name | Age | Email |
|------|-----|-------|
@for user in users
| $user.name | $user.age | $user.email |
@end

@# Generate HTML list
<ul>
@for item in items
  <li>${item | escape}</li>
@end
</ul>
```

### Conditional Content

```luma
@# Feature flags
@if features.new_ui
  <script src="/js/new-ui.js"></script>
@end

@# Environment-specific config
@if env == "production"
  log_level: error
@elif env == "staging"
  log_level: warning
@else
  log_level: debug
@end
```

---

## Next Steps

### Learn More

- **[Complete Documentation](/documentation)** - Full language reference
- **[Examples](/examples)** - Real-world use cases
- **[API Reference](/API)** - Detailed API documentation
- **[Integration Guides](/INTEGRATION_GUIDES)** - Framework-specific guides

### Try Examples

```bash
# Clone the repository
git clone https://github.com/santosr2/luma.git
cd luma/examples

# Run Kubernetes example
luajit run_k8s_example.lua

# Run Terraform example
luajit run_terraform_example.lua
```

### Get Help

- **[GitHub Issues](https://github.com/santosr2/luma/issues)** - Report bugs or request features
- **[Discussions](https://github.com/santosr2/luma/discussions)** - Ask questions
- **[Contributing](https://github.com/santosr2/luma/blob/main/CONTRIBUTING.md)** - Contribute to Luma

---

## Tips & Best Practices

### 1. Use Native Syntax for New Projects

Native Luma syntax is cleaner and more readable:

```luma
@# Preferred
@if condition
  $value
@end

@# Instead of
&#123;% if condition %&#125;
  &#123;&#123; value &#125;&#125;
&#123;% endif %&#125;
```

### 2. Leverage Smart Whitespace

Luma preserves indentation automatically - no manual trimming needed:

```yaml
# Works perfectly in YAML
containers:
@for container in containers
  - name: $container.name
    image: $container.image
@end
```

### 3. Use Filters for Data Transformation

```luma
@# Transform data in the template
$email | lower
$name | title
$description | truncate(100)
$json_data | tojson
```

### 4. Create Reusable Macros

```luma
@# macros.luma
@macro card(title, content, style="default")
  <div class="card card-$style">
    <h3>$title</h3>
    <p>$content</p>
  </div>
@end

@# Use in templates
@from "macros.luma" import card
@call card("Hello", "Welcome!", style="primary")
```

### 5. Test Templates with Different Data

```bash
# Test with different contexts
luma render template.luma --data-file dev.yaml
luma render template.luma --data-file staging.yaml
luma render template.luma --data-file prod.yaml
```

---

Happy templating! 🚀
