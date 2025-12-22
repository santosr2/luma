---
layout: default
title: Home
render_with_liquid: false
---

# Luma Template Engine

A **fast, clean templating language** with full Jinja2 compatibility.
Perfect for DevOps, configuration management, and modern web applications.

## Why Luma?

### 🚀 **Fast**

- LuaJIT-powered performance
- Compiled template caching
- 377K operations/second

### ✨ **Clean Syntax**

- Readable native syntax: `@if`, `@for`, `$var`
- Full Jinja2 compatibility for seamless migration
- Smart whitespace handling - works everywhere

### 🔧 **DevOps-Ready**

- Built for Kubernetes, Terraform, Ansible
- YAML-friendly syntax
- Production examples included

### ✅ **Production-Proven**

- 100% Jinja2 feature parity
- 589/589 tests passing
- Comprehensive documentation

---

## Quick Start

### Installation

```bash
# Using LuaRocks
luarocks install luma

# Using Homebrew (macOS/Linux)
brew install luma

# Using Docker
docker pull luma/luma
```

### Hello World

**Native Luma Syntax:**

```luma
@let name = "World"
Hello, $name!

@if name == "World"
  Welcome to Luma!
@end
```

**Jinja2 Syntax (also supported):**

{% raw %}
{% raw %}
```jinja
{% set name = "World" %}
Hello, {{ name }}!

{% if name == "World" %}
  Welcome to Luma!
{% endif %}
```
{% endraw %}
{% endraw %}

### Using in Code

**Lua:**

```lua
local luma = require("luma")
local result = luma.render("Hello, $name!", { name = "World" })
print(result)  -- "Hello, World!"
```

**Python:**

```python
from luma import Luma

luma = Luma()
result = luma.render("Hello, $name!", {"name": "World"})
print(result)  # "Hello, World!"
```

---

## Features

### Core Features

- ✅ **Variables**: `$var`, `$&#123;expression&#125;`
- ✅ **Control Flow**: `@if`/`@elif`/`@else`, `@for`, `@while`
- ✅ **Filters**: `$value | upper | truncate(20)`
- ✅ **Tests**: `@if value is defined`, `@if x is even`
- ✅ **Macros**: Reusable template components
- ✅ **Template Inheritance**: `@extends`, `@block`, `super()`
- ✅ **Imports**: Selective imports with `@from "file" import macro`

### Advanced Features

- ✅ **Call with Caller**: Advanced macro patterns
- ✅ **Scoped Blocks**: Isolated variable scopes
- ✅ **Autoescape**: XSS protection for web apps
- ✅ **Whitespace Control**: Smart preservation + dash trimming
- ✅ **Named Filter Arguments**: `truncate(length=50, killwords=true)`
- ✅ **Loop Enhancements**: `loop.cycle()`, `@break`, `@continue`

---

## Documentation

<div class="docs-grid" markdown="1">

### [Getting Started](/getting-started)

Installation, first template, basic concepts

### [Documentation](/documentation)

Complete language reference and guides

### [Examples](/examples)

Real-world templates for K8s, Terraform, Ansible

### [API Reference](/API)

Complete API documentation for all languages

### [Jinja2 Migration](/JINJA2_MIGRATION)

Seamless migration from Jinja2 to Luma

### [Integration Guides](/INTEGRATION_GUIDES)

Helm, Terraform, Ansible, Flask, and more

</div>

---

## Use Cases

### DevOps & Infrastructure

```yaml
# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app.name
spec:
  replicas: ${replicas | default(3)}
  template:
    spec:
      containers:
@for container in containers
        - name: $container.name
          image: ${container.image}:${container.tag}
@end
```

### Web Applications

```html
<!DOCTYPE html>
<html>
<head>
  <title>${title | escape}</title>
</head>
<body>
  @extends "base.html"
  
  @block content
    <h1>Welcome, $user.name!</h1>
    
    @if user.is_admin
      <a href="/admin">Admin Panel</a>
    @end
  @end
</body>
</html>
```

### Configuration Files

```nginx
# Nginx Configuration
server {
    listen ${port | default(80)};
    server_name $server_name;
    
@for location in locations
    location $location.path {
        proxy_pass $location.backend;
@if location.cache
        proxy_cache_valid 200 ${location.cache}m;
@end
    }
@end
}
```

---

## Comparison

| Feature | Luma | Jinja2 | Go Templates | Mustache |
|---------|------|--------|--------------|----------|
| Syntax Clarity | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| Performance | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Template Inheritance | ✅ | ✅ | ❌ | ❌ |
| Filters | ✅ 80+ | ✅ 50+ | ✅ Limited | ❌ |
| YAML-Friendly | ✅ | ❌ | ❌ | ✅ |
| Whitespace Control | ✅ Smart | ⚠️ Manual | ⚠️ Manual | ✅ |
| Multi-Language | ✅ | ✅ | Go only | ✅ |

---

## Community & Support

- **GitHub**: [santosr2/luma](https://github.com/santosr2/luma)
- **Issues**: [Report bugs or request features](https://github.com/santosr2/luma/issues)
- **Discussions**: [Community forum](https://github.com/santosr2/luma/discussions)
- **Security**: See [SECURITY.md](https://github.com/santosr2/luma/security/policy)

---

## License

Luma is open source software licensed under the [MIT License](https://github.com/santosr2/luma/blob/main/LICENSE).

---

<style>
.docs-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin: 2rem 0;
}

.docs-grid h3 {
  background: #f5f5f5;
  padding: 1rem;
  border-left: 4px solid #0366d6;
  margin-top: 0;
}

.docs-grid h3 a {
  text-decoration: none;
  color: #0366d6;
}

.docs-grid h3 + p {
  padding: 0 1rem;
  color: #666;
  font-size: 0.9em;
}
</style>
