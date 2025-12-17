--- Compile command
-- @module cli.commands.compile

local luma = require("luma")

local compile_cmd = {}

function compile_cmd.execute(args)
	local template_file = args[2]
	local output_file = nil
	local syntax = "auto"
	local show_ast = false

	-- Parse arguments
	local i = 3
	while i <= #args do
		local arg = args[i]
		if arg == "--output" or arg == "-o" then
			output_file = args[i + 1]
			i = i + 2
		elseif arg == "--syntax" or arg == "-s" then
			syntax = args[i + 1]
			i = i + 2
		elseif arg == "--ast" then
			show_ast = true
			i = i + 1
		else
			i = i + 1
		end
	end

	if not template_file then
		print("Error: No template file specified")
		print("Usage: luma compile <template> [options]")
		os.exit(1)
	end

	-- Read template
	local file = io.open(template_file, "r")
	if not file then
		print("Error: Cannot open template file: " .. template_file)
		os.exit(1)
	end
	local template_source = file:read("*all")
	file:close()

	-- Compile template
	local compiled = luma.compile(template_source, { syntax = syntax })

	if show_ast then
		-- Show AST (would need parser access)
		print("AST output not yet implemented")
		return
	end

	-- Output compiled code
	local code = compiled.source

	if output_file then
		local out = io.open(output_file, "w")
		if not out then
			print("Error: Cannot write to output file: " .. output_file)
			os.exit(1)
		end
		out:write(code)
		out:close()
		print("Compiled code written to: " .. output_file)
	else
		print(code)
	end
end

return compile_cmd
