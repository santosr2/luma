#!/usr/bin/env luajit
--- Example: Generating Terraform AWS ECS configuration
package.path = package.path .. ";./?.lua;./?/init.lua" -- luacheck: ignore

local luma = require("luma")

-- Read template
local file = io.open("examples/terraform_module.luma", "r")
local template = file:read("*a")
file:close()

-- Context data
local context = {
	terraform_version = "1.0",
	aws_provider_version = "5.0",
	cluster_name = "production-cluster",
	service_name = "web-api",
	container_name = "api",
	container_image = "ghcr.io/myorg/api:v1.2.3",
	cpu = "256",
	memory = "512",
	desired_count = 3,
	region = "us-east-1",
	enable_container_insights = "enabled",
	assign_public_ip = "false",

	ports = {
		{ container = 8080, host = 8080, protocol = "tcp" },
		{ container = 9090, host = 9090, protocol = "tcp" },
	},

	environment = {
		{ name = "ENV", value = "production" },
		{ name = "LOG_LEVEL", value = "info" },
		{ name = "PORT", value = "8080" },
	},

	subnet_ids = '"subnet-abc123", "subnet-def456"',
	security_group_ids = '"sg-xyz789"',

	load_balancer = {
		target_group_arn = "arn:aws:elasticloadbalancing:...",
		container_port = 8080,
	},

	tags = {
		Environment = "production",
		ManagedBy = "terraform",
		Service = "web-api",
	},
}

-- Render
local result = luma.render(template, context)
print(result)
