#!/usr/bin/env luajit
--- Example: Rendering Kubernetes manifest
package.path = package.path .. ";./?.lua;./?/init.lua"

local luma = require("luma")

-- Read template
local file = io.open("examples/kubernetes_manifest.luma", "r")
local template = file:read("*a")
file:close()

-- Context data
local context = {
	name = "web-api",
	ns = "production",
	version = "v1.2.3",
	replicas = 3,
	registry = "ghcr.io/myorg",
	ports = {
		{ number = 8080, name = "http" },
		{ number = 9090, name = "metrics" },
	},
	env = {
		{ name = "DATABASE_URL", value = "postgres://db:5432/mydb" },
		{ name = "REDIS_URL", value = "redis://cache:6379" },
		{ name = "LOG_LEVEL", value = "info" },
	},
	resources = {
		requests = { memory = "256Mi", cpu = "100m" },
		limits = { memory = "512Mi", cpu = "500m" },
	},
}

-- Render
local result = luma.render(template, context)
print(result)
