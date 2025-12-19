--- Render command
-- @module cli.commands.render

local luma = require("luma")
local json = require("luma.utils.compat").json or require("cjson")

local render = {}

--- Parse YAML (simple implementation for basic data files)
local function parse_yaml(content)
	-- For production, use lyaml or similar
	-- This is a minimal parser for demo purposes
	-- For now, try JSON first, then fall back to simple key-value parsing
	local ok, result = pcall(json.decode, content)
	if ok then
		return result
	end

	-- Simple YAML parser (handles basic cases)
	local data = {}
	for line in content:gmatch("[^\r\n]+") do
		-- Skip comments and empty lines
		if not line:match("^%s*#") and not line:match("^%s*$") then
			local key, value = line:match("^([%w_]+):%s*(.+)")
			if key and value then
				-- Remove quotes
				value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
				-- Try to parse as number
				local num = tonumber(value)
				if num then
					data[key] = num
				elseif value == "true" then
					data[key] = true
				elseif value == "false" then
					data[key] = false
				else
					data[key] = value
				end
			end
		end
	end
	return data
end

function render.execute(args)
	local template_file = args[2]
	local data_str = nil
	local data_file = nil
	local data_stdin = false
	local template_stdin = false
	local output_file = nil
	local syntax = "auto"

	-- Parse arguments
	local i = 3
	while i <= #args do
		local arg = args[i]
		if arg == "--data" or arg == "-d" then
			data_str = args[i + 1]
			i = i + 2
		elseif arg == "--data-file" or arg == "-f" then
			data_file = args[i + 1]
			i = i + 2
		elseif arg == "--data-stdin" then
			data_stdin = true
			i = i + 1
		elseif arg == "--stdin" then
			template_stdin = true
			i = i + 1
		elseif arg == "--output" or arg == "-o" then
			output_file = args[i + 1]
			i = i + 2
		elseif arg == "--syntax" or arg == "-s" then
			syntax = args[i + 1]
			i = i + 2
		else
			i = i + 1
		end
	end

	-- Handle template source
	local template_source
	if template_stdin or template_file == "-" then
		-- Read from stdin
		template_source = io.read("*all")
		if not template_source or template_source == "" then
			io.stderr:write("Error: No template data provided on stdin\n")
			os.exit(1)
		end
	elseif template_file then
		-- Read from file
		local file = io.open(template_file, "r")
		if not file then
			io.stderr:write("Error: Cannot open template file: " .. template_file .. "\n")
			os.exit(1)
		end
		template_source = file:read("*all")
		file:close()
	else
		io.stderr:write("Error: No template file specified\n")
		io.stderr:write("Usage: luma render <template> [options]\n")
		io.stderr:write("       luma render --stdin [options]\n")
		os.exit(1)
	end

	-- Parse context data
	local context = {}
	if data_stdin then
		-- Read data from stdin
		local stdin_data = io.read("*all")
		if stdin_data and stdin_data ~= "" then
			-- Try JSON first, then YAML
			local ok, result = pcall(json.decode, stdin_data)
			if ok then
				context = result
			else
				context = parse_yaml(stdin_data)
			end
		end
	elseif data_str then
		-- Parse inline JSON
		local ok, result = pcall(json.decode, data_str)
		if not ok then
			io.stderr:write("Error: Invalid JSON data: " .. tostring(result) .. "\n")
			os.exit(1)
		end
		context = result
	elseif data_file then
		-- Read from file (JSON or YAML)
		local f = io.open(data_file, "r")
		if not f then
			io.stderr:write("Error: Cannot open data file: " .. data_file .. "\n")
			os.exit(1)
		end
		local content = f:read("*all")
		f:close()

		-- Detect format by extension or try both
		if data_file:match("%.ya?ml$") then
			context = parse_yaml(content)
		else
			-- Try JSON first
			local ok, result = pcall(json.decode, content)
			if ok then
				context = result
			else
				-- Fall back to YAML
				context = parse_yaml(content)
			end
		end
	end

	-- Render template
	local ok, result = pcall(luma.render, template_source, context, { syntax = syntax })
	if not ok then
		io.stderr:write("Error rendering template: " .. tostring(result) .. "\n")
		os.exit(1)
	end

	-- Output
	if output_file then
		local out = io.open(output_file, "w")
		if not out then
			io.stderr:write("Error: Cannot write to output file: " .. output_file .. "\n")
			os.exit(1)
		end
		out:write(result)
		out:close()
		io.stderr:write("Output written to: " .. output_file .. "\n")
	else
		io.write(result)
	end
end

return render
