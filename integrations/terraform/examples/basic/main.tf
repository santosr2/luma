terraform {
  required_providers {
    luma = {
      source = "registry.terraform.io/santosr2/luma"
    }
  }
}

provider "luma" {
  syntax = "auto" # auto, luma, or jinja
}

# Data source: Render template inline
data "luma_template" "greeting" {
  template = "Hello, $name!"
  vars = {
    name = "Terraform"
  }
}

output "greeting" {
  value = data.luma_template.greeting.result
}

# Data source: Complex template with loops
data "luma_template" "config" {
  template = <<-EOT
    # Configuration
    @for key, value in pairs(config)
    ${key} = $value
    @end
  EOT
  vars = {
    config = jsonencode({
      server_name = "prod-server"
      port        = "8080"
      debug       = "false"
    })
  }
}

output "config" {
  value = data.luma_template.config.result
}

# Resource: Write rendered template to file
resource "luma_template_file" "nginx_config" {
  template_file = "${path.module}/templates/nginx.conf.luma"
  destination   = "${path.module}/output/nginx.conf"
  file_mode     = "0644"

  vars = {
    server_name = "example.com"
    port        = "80"
    workers     = "4"
    locations   = jsonencode([
      { path = "/", proxy_pass = "http://backend:8080" },
      { path = "/api", proxy_pass = "http://api:8081" }
    ])
  }
}

output "nginx_config_path" {
  value = luma_template_file.nginx_config.destination
}

