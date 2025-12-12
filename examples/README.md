# Luma Examples

This directory contains real-world examples demonstrating Luma's capabilities.

## Examples

### 1. Kubernetes Manifest (`kubernetes_manifest.luma`)

Generate Kubernetes deployment manifests with proper indentation and structure.

**Run:**
```bash
luajit examples/run_k8s_example.lua
```

**Features demonstrated:**
- Clean YAML generation
- Smart indentation preservation
- Loop rendering for ports and environment variables
- Complex nested data structures

### 2. HTML Email Template (`html_email.luma`)

Professional HTML email template with conditional content and tables.

**Features demonstrated:**
- HTML generation
- Conditional blocks
- Table rendering with loops
- Filters (default, etc.)
- Safe variable interpolation

### 3. Terraform AWS ECS Module (`terraform_module.luma`)

Generate Terraform configuration for AWS ECS deployments.

**Run:**
```bash
luajit examples/run_terraform_example.lua
```

**Features demonstrated:**
- Infrastructure as Code generation
- Complex nested resources
- Dynamic tag generation
- Conditional load balancer configuration

### 4. Helm Chart.yaml (`helm_chart.luma`)

Generate Helm chart metadata with dependencies and maintainers.

**Features demonstrated:**
- Helm chart structure
- Conditional dependencies
- List iteration for maintainers and keywords

### 5. Ansible Playbook (`ansible_playbook.luma`)

Generate Ansible playbooks with tasks and handlers.

**Features demonstrated:**
- YAML playbook generation
- Task iteration with conditional logic
- Handler definitions
- Complex nested structures

- Web application templates
- Configuration file generation
- Report generation
- API documentation
- Data transformation

## Usage Patterns

### Basic Rendering

```lua
local luma = require("luma")

local template = "Hello, $name!"
local result = luma.render(template, {name = "World"})
print(result)  -- "Hello, World!"
```

### Compiled Template Reuse

For better performance when rendering the same template multiple times:

```lua
local luma = require("luma")
local filters = require("luma.filters")
local runtime = require("luma.runtime")

-- Compile once
local template = luma.compile("Hello, $name!")

-- Render many times
for _, user in ipairs(users) do
    local result = template:render(
        {name = user.name},
        filters.get_all(),
        runtime
    )
    print(result)
end
```

### Performance Tips

1. **Compile templates once, reuse many times** - 50x faster than re-parsing
2. **Use native Luma syntax** - cleaner and more readable than Jinja2
3. **Pre-structure your data** - avoid complex transformations in templates
4. **Cache compiled templates** - for web applications serving many requests

## Performance Numbers

Based on benchmarks (`benchmarks/run.lua`):

- **Simple interpolation**: ~60,000 ops/sec
- **Complex templates**: ~13,000 ops/sec
- **Compiled reuse**: ~377,000 ops/sec (fastest)
- **Large loops (100 items)**: ~7,400 ops/sec

## Memory Efficiency

Based on profiling (`benchmarks/memory_profile.lua`):

- **Simple render**: ~1.3 KB per operation
- **Compiled reuse**: ~0.025 KB per operation
- **Efficiency gain**: 51.8x more efficient with compiled reuse

## Contributing Examples

Have a great use case? Submit a PR with:
1. Template file (`.luma` extension)
2. Example runner script (`.lua`)
3. Brief description in this README

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

