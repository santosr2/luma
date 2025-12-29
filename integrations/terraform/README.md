# Terraform Provider for Luma

Terraform provider for rendering Luma templates in your infrastructure as code workflows.

## Features

- 📝 **Data Source**: Render templates inline and use in other resources
- 📁 **Resource**: Render templates and write to files
- 🎯 **Jinja2 Compatible**: Use existing Jinja2 templates
- 🔧 **Full Luma Features**: Loops, conditionals, filters, macros, etc.
- 🚀 **Fast**: Native Lua runtime, no Python dependencies

## Installation

```hcl
terraform {
  required_providers {
    luma = {
      source  = "registry.terraform.io/santosr2/luma"
      version = "~> 0.1.0"
    }
  }
}

provider "luma" {
  syntax = "auto" # auto, luma, or jinja
}
```

## Usage

### Data Source: `luma_template`

Render a template and use the result in other resources:

```hcl
data "luma_template" "user_data" {
  template = <<-EOT
    #!/bin/bash
    echo "Server: $server_name"
    echo "Environment: $environment"
    
    @for package in packages
    apt-get install -y $package
    @end
  EOT

  vars = {
    server_name = "web-01"
    environment = "production"
    packages    = jsonencode(["nginx", "postgresql", "redis"])
  }
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  user_data     = data.luma_template.user_data.result
}
```

### Resource: `luma_template_file`

Render a template and write it to a file:

```hcl
resource "luma_template_file" "k8s_manifest" {
  template_file = "${path.module}/templates/deployment.yaml.luma"
  destination   = "${path.module}/output/deployment.yaml"
  file_mode     = "0644"

  vars = {
    app_name    = "myapp"
    replicas    = "3"
    image       = "myapp:v1.2.3"
    environment = jsonencode({
      DATABASE_URL = "postgresql://..."
      REDIS_URL    = "redis://..."
    })
  }
}

# Use the generated file in other resources
resource "null_resource" "apply_manifest" {
  triggers = {
    manifest_content = luma_template_file.k8s_manifest.content
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${luma_template_file.k8s_manifest.destination}"
  }
}
```

## Examples

### Kubernetes Manifests

```hcl
data "luma_template" "deployment" {
  template = file("${path.module}/k8s/deployment.yaml.luma")
  vars = {
    name      = "web-app"
    namespace = "production"
    replicas  = "3"
    image     = var.docker_image
    env_vars  = jsonencode(var.environment_variables)
  }
}

resource "local_file" "deployment" {
  content  = data.luma_template.deployment.result
  filename = "${path.module}/manifests/deployment.yaml"
}
```

### Nginx Configuration

```hcl
resource "luma_template_file" "nginx" {
  template = <<-EOT
    server {
        listen $port;
        server_name $server_name;
        
        @for location in locations
        location ${location.path} {
            proxy_pass ${location.backend};
        }
        @end
    }
  EOT

  destination = "/etc/nginx/sites-available/${var.site_name}"
  file_mode   = "0644"

  vars = {
    port        = "80"
    server_name = var.domain
    locations   = jsonencode(var.proxy_locations)
  }
}
```

### Cloud-Init User Data

```hcl
data "luma_template" "cloud_init" {
  template = <<-EOT
    #cloud-config
    hostname: $hostname
    
    packages:
    @for pkg in packages
      - $pkg
    @end
    
    write_files:
    @for file in files
      - path: ${file.path}
        content: |
          ${file.content}
    @end
    
    runcmd:
    @for cmd in commands
      - $cmd
    @end
  EOT

  vars = {
    hostname = "web-server-01"
    packages = jsonencode(["docker", "nginx"])
    files    = jsonencode([
      {
        path    = "/etc/app/config.yml"
        content = "version: 1.0"
      }
    ])
    commands = jsonencode([
      "systemctl enable docker",
      "systemctl start docker"
    ])
  }
}
```

## Template Syntax

### Variables

```hcl
# Simple variable
data "luma_template" "example" {
  template = "Hello, $name!"
  vars = {
    name = "World"
  }
}

# Expression
data "luma_template" "example" {
  template = "Port: ${port + 1000}"
  vars = {
    port = "8080"
  }
}
```

### Conditionals

```hcl
data "luma_template" "example" {
  template = <<-EOT
    @if environment == "production"
    Production mode enabled
    @elif environment == "staging"
    Staging mode enabled
    @else
    Development mode
    @end
  EOT
  vars = {
    environment = "production"
  }
}
```

### Loops

```hcl
data "luma_template" "example" {
  template = <<-EOT
    Servers:
    @for server in servers
      - Name: ${server.name}
        IP: ${server.ip}
    @end
  EOT
  vars = {
    servers = jsonencode([
      { name = "web-01", ip = "10.0.1.10" },
      { name = "web-02", ip = "10.0.1.20" }
    ])
  }
}
```

### Filters

```hcl
data "luma_template" "example" {
  template = <<-EOT
    Name: ${name | upper}
    Count: ${items | length}
    First: ${items | first}
  EOT
  vars = {
    name  = "server"
    items = jsonencode([1, 2, 3])
  }
}
```

## Schema

### Data Source: `luma_template`

| Argument   | Type   | Required | Description                              |
|------------|--------|----------|------------------------------------------|
| `template` | string | Yes      | Luma template string to render           |
| `vars`     | map    | No       | Variables to pass to template (JSON supported) |
| `syntax`   | string | No       | Syntax mode: auto, luma, or jinja        |

**Computed Attributes:**
- `result` (string) - The rendered template output

### Resource: `luma_template_file`

| Argument        | Type   | Required | Description                              |
|-----------------|--------|----------|------------------------------------------|
| `template`      | string | No*      | Template string (*one of template or template_file required) |
| `template_file` | string | No*      | Path to template file (*one of template or template_file required) |
| `vars`          | map    | No       | Variables to pass to template (JSON supported) |
| `destination`   | string | Yes      | Output file path                         |
| `file_mode`     | string | No       | File permissions (default: "0644")       |

**Computed Attributes:**
- `id` (string) - Resource identifier (destination path)
- `content` (string) - The rendered template content

## Development

### Building

```bash
cd integrations/terraform
go mod tidy
go build -o terraform-provider-luma
```

### Testing

```bash
go test ./...
```

### Local Development

```bash
# Build provider
go build -o ~/.terraform.d/plugins/registry.terraform.io/santosr2/luma/0.1.0/darwin_arm64/terraform-provider-luma

# Use in Terraform
cd examples/basic
terraform init
terraform plan
terraform apply
```

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](../../LICENSE) for details.

## Links

- **Luma Documentation**: [https://santosr2.github.io/luma](https://santosr2.github.io/luma)
- **GitHub**: [https://github.com/santosr2/luma](https://github.com/santosr2/luma)
- **Issues**: [https://github.com/santosr2/luma/issues](https://github.com/santosr2/luma/issues)

