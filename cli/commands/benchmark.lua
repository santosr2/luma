--- Benchmark command
-- @module cli.commands.benchmark

local luma = require("luma")

local benchmark = {}

function benchmark.execute(args)
	local template_file = args[2]
	local iterations = 1000
	local syntax = "auto"

	-- Parse arguments
	local i = 3
	while i <= #args do
		local arg = args[i]
		if arg == "--iterations" or arg == "-n" then
			iterations = tonumber(args[i + 1]) or 1000
			i = i + 2
		elseif arg == "--syntax" or arg == "-s" then
			syntax = args[i + 1]
			i = i + 2
		else
			i = i + 1
		end
	end

	if not template_file then
		print("Error: No template file specified")
		print("Usage: luma benchmark <template> [options]")
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

	print("Benchmarking: " .. template_file)
	print("Iterations: " .. iterations)
	print("")

	-- Benchmark compilation
	local compile_start = os.clock()
	local compiled = luma.compile(template_source, { syntax = syntax })
	local compile_time = os.clock() - compile_start

	print("Compilation: " .. string.format("%.3f", compile_time * 1000) .. "ms")

	-- Benchmark rendering
	local context = { name = "World", items = { 1, 2, 3, 4, 5 } }

	local render_start = os.clock()
	for i = 1, iterations do
		local _ = compiled:render(context)
	end
	local render_time = os.clock() - render_start

	print("Rendering (" .. iterations .. "x): " .. string.format("%.3f", render_time * 1000) .. "ms")
	print("Average per render: " .. string.format("%.3f", (render_time / iterations) * 1000) .. "ms")
	print("Renders per second: " .. string.format("%.0f", iterations / render_time))
end

return benchmark
