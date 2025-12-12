# Luma Integration Guides

Complete guides for integrating Luma into popular tools and frameworks.

## Table of Contents

1. [Helm Integration](#helm-integration)
2. [Terraform Integration](#terraform-integration)
3. [Ansible Integration](#ansible-integration)
4. [GitHub Actions](#github-actions)
5. [Python Applications](#python-applications)
6. [Web Frameworks](#web-frameworks)

---

## Helm Integration

### Using Luma for Helm Chart Generation

Helm charts benefit from Luma's clean syntax and smart indentation.

**Directory Structure:**
```
my-app/
├── generate-chart.lua
├── templates/
│   ├── Chart.yaml.luma
│   ├── values.yaml.luma
│   └── deployment.yaml.luma
└── generated/
    └── (output goes here)
```

**Example: `generate-chart.lua`**
```lua
local luma = require("luma")
local yaml = require("yaml")  -- optional, for validation

-- Load template
local file = io.open("templates/Chart.yaml.luma", "r")
local template = file:read("*a")
file:close()

-- Context
local context = {
    chart_name = "my-app",
    version = "1.0.0",
    app_version = "2.3.4",
    description = "My application",
    -- ... more context
}

-- Render
local result = luma.render(template, context)

-- Write output
local out = io.open("generated/Chart.yaml", "w")
out:write(result)
out:close()
```

**Benefits:**
- Type-safe chart generation
- Dynamic versioning
- Environment-specific values
- Consistent formatting

---

## Terraform Integration

### Using Luma for Terraform Module Generation

Generate Terraform configurations programmatically with Luma.

**Use Cases:**
- Multi-environment deployments
- Repetitive resource definitions
- Dynamic module generation
- Configuration from YAML/JSON

**Example Workflow:**

1. **Define Template** (`main.tf.luma`):
```hcl
resource "aws_instance" "$name" {
  ami           = "$ami"
  instance_type = "$instance_type"

  tags = {
@for key, val in tags
    $key = "$val"
@end
  }
}
```

2. **Generate Script:**
```lua
local luma = require("luma")
local json = require("json")  -- or cjson

-- Load config
local config_file = io.open("config.json", "r")
local config = json.decode(config_file:read("*a"))
config_file:close()

-- Load template
local template_file = io.open("main.tf.luma", "r")
local template = template_file:read("*a")
template_file:close()

-- Render each environment
for env_name, env_config in pairs(config.environments) do
    local result = luma.render(template, env_config)
    
    local out = io.open("terraform/" .. env_name .. "/main.tf", "w")
    out:write(result)
    out:close()
    
    print("Generated: terraform/" .. env_name .. "/main.tf")
end
```

3. **Usage:**
```bash
lua generate-terraform.lua
cd terraform/production && terraform plan
```

**Best Practices:**
- Keep templates in version control
- Validate generated HCL with `terraform fmt`
- Use consistent naming conventions
- Document template variables

---

## Ansible Integration

### Using Luma for Ansible Playbook Generation

Generate Ansible playbooks from structured data.

**Example: Inventory-Driven Playbook Generation**

```lua
local luma = require("luma")

-- Load inventory
local inventory = {
    web_servers = {"web1", "web2", "web3"},
    db_servers = {"db1", "db2"},
    packages = {"nginx", "nodejs", "pm2"},
}

-- Template
local playbook_template = [[
---
- name: Configure Web Servers
  hosts: web
  tasks:
@for pkg in packages
    - name: Install $pkg
      apt:
        name: $pkg
        state: present
@end
]]

-- Generate
local result = luma.render(playbook_template, inventory)

-- Save
local file = io.open("generated-playbook.yml", "w")
file:write(result)
file:close()
```

**Integration Points:**
- **Pre-deployment**: Generate playbooks from configs
- **Dynamic inventories**: Create inventory files
- **Role generation**: Template out role structures
- **Variable files**: Generate group_vars/host_vars

---

## GitHub Actions

### Using Luma in CI/CD Pipelines

Generate workflow files or use Luma within workflows.

**Example 1: Generate Workflow Files**

```yaml
# .github/workflows/generate.yml
name: Generate Configs

on:
  push:
    paths:
      - 'templates/**'
      - 'config/**'

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install LuaJIT
        run: |
          sudo apt-get update
          sudo apt-get install -y luajit lua-filesystem
      
      - name: Install Luma
        run: |
          git clone https://github.com/yourorg/luma.git
          cd luma && sudo make install
      
      - name: Generate Configurations
        run: |
          luajit scripts/generate-all.lua
      
      - name: Commit Changes
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add generated/
          git commit -m "chore: regenerate configs" || true
          git push
```

**Example 2: Template Rendering in Workflow**

```yaml
- name: Render Kubernetes Manifests
  run: |
    luajit << 'EOLUA'
      local luma = require("luma")
      local template = io.open("k8s/deployment.luma"):read("*a")
      local result = luma.render(template, {
        image = "${{ github.sha }}",
        environment = "${{ github.ref_name }}",
      })
      io.open("k8s/deployment.yaml", "w"):write(result)
    EOLUA

- name: Deploy
  run: kubectl apply -f k8s/deployment.yaml
```

---

## Python Applications

### Using Luma Python Bindings

Full Python integration for web apps and scripts.

**Installation:**
```bash
cd luma/bindings/python
pip install .
```

**Basic Usage:**
```python
from luma import Template

# Simple rendering
template = Template("Hello, {{ name }}!")
result = template.render(name="World")
print(result)  # "Hello, World!"
```

**Flask Integration:**
```python
from flask import Flask, render_template_string
from luma import Template

app = Flask(__name__)

@app.route("/user/<username>")
def user_profile(username):
    template_str = """
    <h1>Profile: {{ user.name }}</h1>
    <p>Email: {{ user.email }}</p>
    """
    
    template = Template(template_str, syntax="jinja")
    return template.render(
        user={"name": username, "email": f"{username}@example.com"}
    )
```

**Django Integration:**
```python
from django.http import HttpResponse
from luma import Template

def my_view(request):
    template = Template("""
    <h1>{{ title }}</h1>
    {% for item in items %}
        <p>{{ item }}</p>
    {% endfor %}
    """, syntax="jinja")
    
    html = template.render(
        title="My Page",
        items=["Item 1", "Item 2", "Item 3"]
    )
    
    return HttpResponse(html)
```

---

## Web Frameworks

### Nginx Configuration Generation

```lua
local luma = require("luma")

local template = [[
server {
    listen 80;
    server_name $domain;

@for location in locations
    location $location.path {
        proxy_pass http://$location.upstream;
@if location.headers
@for header in location.headers
        proxy_set_header $header.name $header.value;
@end
@end
    }
@end
}
]]

local config = {
    domain = "example.com",
    locations = {
        {path = "/api", upstream = "localhost:3000"},
        {path = "/static", upstream = "localhost:8080"},
    }
}

local nginx_conf = luma.render(template, config)
-- Write to /etc/nginx/sites-available/
```

---

## Best Practices

### General Integration Tips

1. **Version Control Templates**
   - Keep `.luma` templates in git
   - Document template variables
   - Use semantic versioning

2. **Validation**
   - Validate generated output
   - Run linters (yamllint, terraform fmt, etc.)
   - Test generated configs before deployment

3. **Error Handling**
   ```lua
   local ok, result = pcall(function()
       return luma.render(template, context)
   end)
   
   if not ok then
       print("Error:", result)
       os.exit(1)
   end
   ```

4. **Performance**
   - Compile templates once
   - Reuse compiled templates
   - Cache rendered output when appropriate

5. **Security**
   - Validate input data
   - Use autoescape for HTML
   - Sanitize user input before rendering

---

## Troubleshooting

### Common Issues

**Issue: "Template not found"**
```lua
-- Solution: Use absolute paths or set loader paths
local runtime = require("luma.runtime")
runtime.set_paths({"/path/to/templates", "."})
```

**Issue: "Syntax error in template"**
```lua
-- Solution: Enable better error messages
local luma = require("luma")
local ok, err = pcall(function()
    return luma.compile(template_source)
end)
if not ok then
    print("Compilation error:", err)
end
```

**Issue: Performance degradation**
```lua
-- Solution: Pre-compile and reuse
local compiled = luma.compile(template_source)
local filters = require("luma.filters")
local runtime = require("luma.runtime")

for _, item in ipairs(many_items) do
    local result = compiled:render(item, filters.get_all(), runtime)
    -- Process result
end
```

---

## Additional Resources

- [Luma Documentation](../README.md)
- [Examples Directory](../examples/)
- [Performance Benchmarks](../benchmarks/)
- [Python Bindings](../bindings/python/)

## Contributing

Have an integration guide to share? Submit a PR!

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

