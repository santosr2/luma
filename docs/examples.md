---
layout: default
title: Examples
---

# Luma Examples

Real-world examples demonstrating Luma's capabilities across different domains.

## DevOps & Infrastructure

### Kubernetes Deployment

Generate production-ready Kubernetes manifests with proper YAML structure:

```luma
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app.name
  labels:
    app: $app.name
    version: $app.version
spec:
  replicas: ${replicas | default(3)}
  selector:
    matchLabels:
      app: $app.name
  template:
    metadata:
      labels:
        app: $app.name
        version: $app.version
    spec:
      containers:
@for container in containers
        - name: $container.name
          image: ${container.image}:${container.tag | default("latest")}
@if container.ports
          ports:
@for port in container.ports
            - containerPort: $port.port
              name: $port.name
              protocol: ${port.protocol | default("TCP")}
@end
@end
@if container.env
          env:
@for key, value in pairs(container.env)
            - name: $key
              value: "$value"
@end
@end
          resources:
            requests:
              memory: ${container.resources.memory | default("256Mi")}
              cpu: ${container.resources.cpu | default("100m")}
@end
```

**Run the full example:**

```bash
luajit examples/run_k8s_example.lua
```

---

### Terraform AWS ECS Module

Infrastructure as Code with Terraform:

```luma
resource "aws_ecs_cluster" "main" {
  name = "$cluster_name"

  setting {
    name  = "containerInsights"
    value = "${container_insights | default("enabled")}"
  }

@for key, value in pairs(tags)
  tags = {
    "${key}" = "$value"
  }
@end
}

resource "aws_ecs_task_definition" "app" {
  family                   = "$app_name"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "$cpu"
  memory                   = "$memory"

  container_definitions = jsonencode([
    {
      name      = "$app_name"
      image     = "$image"
      essential = true

@if environment
      environment = [
@for env in environment
        {
          name  = "$env.name"
          value = "$env.value"
        }${loop.last ? "" : ","}
@end
      ]
@end

@if ports
      portMappings = [
@for port in ports
        {
          containerPort = $port
          protocol      = "tcp"
        }${loop.last ? "" : ","}
@end
      ]
@end
    }
  ])
}
```

**Run:**

```bash
luajit examples/run_terraform_example.lua
```

---

### Ansible Playbook

Generate Ansible playbooks dynamically:

```luma
---
- name: $playbook.name
  hosts: $playbook.hosts
  become: ${playbook.become | default(true)}

  vars:
@for key, value in pairs(vars)
    ${key}: $value
@end

  tasks:
@for task in tasks
    - name: $task.name
@if task.command
      command: $task.command
@end
@if task.shell
      shell: $task.shell
@end
@if task.apt
      apt:
        name: $task.apt.name
        state: ${task.apt.state | default("present")}
@end
@if task.when
      when: $task.when
@end
@if task.notify
      notify:
@for handler in task.notify
        - $handler
@end
@end
@if not loop.last

@end
@end

@if handlers
  handlers:
@for handler in handlers
    - name: $handler.name
      service:
        name: $handler.service
        state: $handler.state
@if not loop.last

@end
@end
@end
```

---

### Helm Chart.yaml

Generate Helm chart metadata:

```luma
apiVersion: v2
name: $chart.name
description: $chart.description
type: ${chart.type | default("application")}
version: $chart.version
appVersion: "$chart.app_version"

@if chart.keywords
keywords:
@for keyword in chart.keywords
  - $keyword
@end
@end

@if chart.maintainers
maintainers:
@for maintainer in chart.maintainers
  - name: $maintainer.name
    email: $maintainer.email
@if maintainer.url
    url: $maintainer.url
@end
@end
@end

@if chart.dependencies
dependencies:
@for dep in chart.dependencies
  - name: $dep.name
    version: "$dep.version"
    repository: $dep.repository
@if dep.condition
    condition: $dep.condition
@end
@end
@end
```

---

## Web Applications

### HTML Email Template

Professional HTML email with responsive design:

```luma
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$email.subject</title>
  <style>
    body { font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; }
    .header { background: #0366d6; color: white; padding: 20px; }
    .content { padding: 20px; }
    .footer { background: #f6f8fa; padding: 10px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>$email.title</h1>
    </div>
    
    <div class="content">
      <p>Hello ${recipient.name | default("there")},</p>
      
      $email.body
      
@if items
      <h3>Your Items:</h3>
      <table>
        <tr>
          <th>Item</th>
          <th>Quantity</th>
          <th>Price</th>
        </tr>
@for item in items
        <tr>
          <td>$item.name</td>
          <td>$item.quantity</td>
          <td>${item.price}</td>
        </tr>
@end
      </table>
      
      <p><strong>Total: ${total | default(0)}</strong></p>
@end
      
@if cta
      <p style="text-align: center;">
        <a href="$cta.url" style="background: #0366d6; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
          $cta.text
        </a>
      </p>
@end
    </div>
    
    <div class="footer">
      <p>$email.footer</p>
@if unsubscribe_url
      <p><a href="$unsubscribe_url">Unsubscribe</a></p>
@end
    </div>
  </div>
</body>
</html>
```

---

### Web Page with Template Inheritance

**Base Template (`base.luma`):**

```luma
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>@block title; My Site @end</title>
  @block head_extra
  @end
</head>
<body>
  <nav>
    <ul>
@for item in navigation
      <li><a href="$item.url">$item.title</a></li>
@end
    </ul>
  </nav>
  
  <main>
    @block content
      <p>Default content</p>
    @end
  </main>
  
  <footer>
    <p>&copy; ${year} ${site_name}</p>
  </footer>
  
  @block scripts
  @end
</body>
</html>
```

**Page Template:**

```luma
@extends "base.luma"

@block title
  ${page.title} - My Site
@end

@block head_extra
  <link rel="stylesheet" href="/css/page.css">
@end

@block content
  <h1>$page.title</h1>
  
  <article>
@for section in page.sections
    <section>
      <h2>$section.title</h2>
      <p>$section.content</p>
    </section>
@end
  </article>
  
@if page.comments
  <div class="comments">
    <h3>Comments</h3>
@for comment in page.comments
    <div class="comment">
      <strong>$comment.author</strong>
      <p>$comment.text</p>
    </div>
@end
  </div>
@end
@end

@block scripts
  <script src="/js/page.js"></script>
@end
```

---

## Configuration Files

### Nginx Configuration

```luma
server {
    listen ${port | default(80)};
    server_name $server_name;
    
    root $document_root;
    index index.html index.htm;
    
@if ssl_enabled
    # SSL Configuration
    listen 443 ssl http2;
    ssl_certificate $ssl_cert;
    ssl_certificate_key $ssl_key;
    ssl_protocols TLSv1.2 TLSv1.3;
@end
    
@if access_log
    access_log $access_log;
@end
    error_log ${error_log | default("/var/log/nginx/error.log")} warn;
    
@for location in locations
    location $location.path {
@if location.proxy_pass
        proxy_pass $location.proxy_pass;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
@end
        
@if location.cache
        proxy_cache_valid 200 ${location.cache}m;
        proxy_cache_key "$scheme$request_method$host$request_uri";
@end
        
@if location.try_files
        try_files $location.try_files;
@end
    }
    
@end
@if redirects
@for redirect in redirects
    location $redirect.from {
        return ${redirect.code | default(301)} $redirect.to;
    }
@end
@end
}
```

---

### Docker Compose

```luma
version: "$compose_version"

services:
@for service in services
  ${service.name}:
    image: $service.image
@if service.build
    build:
      context: $service.build.context
      dockerfile: ${service.build.dockerfile | default("Dockerfile")}
@end
@if service.ports
    ports:
@for port in service.ports
      - "${port.host}:${port.container}"
@end
@end
@if service.environment
    environment:
@for key, value in pairs(service.environment)
      ${key}: $value
@end
@end
@if service.volumes
    volumes:
@for volume in service.volumes
      - $volume
@end
@end
@if service.depends_on
    depends_on:
@for dep in service.depends_on
      - $dep
@end
@end
@if service.networks
    networks:
@for network in service.networks
      - $network
@end
@end
@if not loop.last

@end
@end

@if networks
networks:
@for network in networks
  ${network.name}:
    driver: ${network.driver | default("bridge")}
@end
@end

@if volumes
volumes:
@for volume in volumes
  ${volume.name}:
@if volume.driver
    driver: $volume.driver
@end
@end
@end
```

---

## Reusable Components with Macros

### UI Component Library

```luma
@# Button macro
@macro button(text, type="default", size="medium", disabled=false)
<button class="btn btn-$type btn-$size"@if disabled disabled@end>
  $text
</button>
@end

@# Card macro
@macro card(title, content, footer=null)
<div class="card">
  <div class="card-header">
    <h3>$title</h3>
  </div>
  <div class="card-body">
    $content
  </div>
@if footer
  <div class="card-footer">
    $footer
  </div>
@end
</div>
@end

@# Alert macro
@macro alert(message, type="info", dismissible=true)
<div class="alert alert-$type@if dismissible alert-dismissible@end">
  $message
@if dismissible
  <button type="button" class="close" data-dismiss="alert">&times;</button>
@end
</div>
@end

@# Usage
@call button("Click Me", type="primary")
@call card("Welcome", "This is a card component")
@call alert("Success!", type="success")
```

---

## Running Examples

### Clone the Repository

```bash
git clone https://github.com/santosr2/luma.git
cd luma/examples
```

### Run Kubernetes Example

```bash
luajit run_k8s_example.lua
```

### Run Terraform Example

```bash
luajit run_terraform_example.lua
```

### Custom Example

```bash
# Create your template
cat > my_template.luma << 'EOF'
Hello, $name!
@if items
Items:
@for item in items
  - $item
@end
@end
EOF

# Render with luma CLI
luma render my_template.luma --data '{"name": "World", "items": ["a", "b", "c"]}'
```

---

## Performance Benchmarks

### Simple Template

- **Parse + Render**: ~60,000 ops/sec
- **Compiled Reuse**: ~377,000 ops/sec (6.3x faster)

### Complex Template (100 items)

- **Parse + Render**: ~7,400 ops/sec
- **Compiled Reuse**: ~45,000 ops/sec (6x faster)

### Memory Usage

- **Simple Render**: 1.3 KB per operation
- **Compiled Reuse**: 0.025 KB per operation (51.8x more efficient)

**Run benchmarks:**

```bash
luajit benchmarks/run.lua
luajit benchmarks/memory_profile.lua
luajit benchmarks/stress_test.lua
```

---

## More Examples

Explore more examples in the repository:

- [Kubernetes Manifests](https://github.com/santosr2/luma/blob/main/examples/kubernetes_manifest.luma)
- [Terraform Modules](https://github.com/santosr2/luma/blob/main/examples/terraform_module.luma)
- [Ansible Playbooks](https://github.com/santosr2/luma/blob/main/examples/ansible_playbook.luma)
- [HTML Email Templates](https://github.com/santosr2/luma/blob/main/examples/html_email.luma)
- [Helm Charts](https://github.com/santosr2/luma/blob/main/examples/helm_chart.luma)

---

## Contributing Examples

Have a great use case? We'd love to see it!

1. Create your template file
2. Add a runner script if needed
3. Document the use case
4. Submit a PR

See [Contributing Guide](https://github.com/santosr2/luma/blob/main/CONTRIBUTING.md) for details.
