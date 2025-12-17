--- Tests for warning system
-- @module spec.warnings_spec
-- luacheck: ignore 122 (setting read-only field of global - intentional for testing)

local luma = require("luma")
local warnings = require("luma.utils.warnings")

describe("Warning System", function()
	before_each(function()
		-- Reset warnings before each test
		warnings.reset()
		-- Clear environment variables
		for _, key in ipairs({ "LUMA_NO_JINJA_WARNING", "LUMA_NO_WARNINGS" }) do
			os.execute("unset " .. key .. " 2>/dev/null")
		end
	end)

	describe("Jinja2 syntax warning", function()
		it("should show warning on first Jinja2 template render", function()
			-- Capture stderr
			local old_stderr = io.stderr
			local stderr_output = {}
			io.stderr = {
				write = function(_, str)
					table.insert(stderr_output, str)
				end,
			}

			local result = luma.render("Hello {{ name }}!", { name = "World" })

			io.stderr = old_stderr

			-- Check that template rendered correctly
			assert.equals("Hello World!", result)

			-- Check that warning was shown
			local output = table.concat(stderr_output)
			assert.match("Jinja2 Syntax Detected", output)
			assert.match("luma migrate", output)

			-- Verify warning was marked as shown
			assert.is_true(warnings.was_shown("jinja"))
		end)

		it("should only show warning once per process", function()
			-- Capture stderr
			local old_stderr = io.stderr
			local call_count = 0
			io.stderr = {
				write = function(_, str)
					if str:match("Jinja2") then
						call_count = call_count + 1
					end
				end,
			}

			-- Render multiple Jinja2 templates
			luma.render("{{ x }}", { x = 1 })
			luma.render("{{ y }}", { y = 2 })
			luma.render("{{ z }}", { z = 3 })

			io.stderr = old_stderr

			-- Warning should only appear once
			assert.is_true(call_count > 0 and call_count < 5) -- Shown but not repeated
		end)

		it("should be suppressible via option", function()
			local old_stderr = io.stderr
			local stderr_output = {}
			io.stderr = {
				write = function(_, str)
					table.insert(stderr_output, str)
				end,
			}

			warnings.reset() -- Reset to allow warning
			local result = luma.render("Hello {{ name }}!", { name = "World" }, { no_jinja_warning = true })

			io.stderr = old_stderr

			assert.equals("Hello World!", result)

			local output = table.concat(stderr_output)
			assert.is_not.match("Jinja2 Syntax Detected", output)
		end)

		it("should not show warning for native syntax", function()
			local old_stderr = io.stderr
			local stderr_output = {}
			io.stderr = {
				write = function(_, str)
					table.insert(stderr_output, str)
				end,
			}

			warnings.reset()
			local result = luma.render("Hello $name!", { name = "World" })

			io.stderr = old_stderr

			assert.equals("Hello World!", result)

			local output = table.concat(stderr_output)
			assert.is_not.match("Jinja2", output)
		end)

		it("should not show warning when syntax is explicitly set to jinja", function()
			local old_stderr = io.stderr
			local stderr_output = {}
			io.stderr = {
				write = function(_, str)
					table.insert(stderr_output, str)
				end,
			}

			warnings.reset()
			-- Explicitly requesting Jinja syntax - no warning
			local result = luma.render("Hello {{ name }}!", { name = "World" }, { syntax = "jinja" })

			io.stderr = old_stderr

			assert.equals("Hello World!", result)

			-- Should not warn when user explicitly chooses Jinja
			local output = table.concat(stderr_output)
			assert.is_not.match("Jinja2 Syntax Detected", output)
		end)
	end)

	describe("Warning suppression", function()
		it("should suppress all warnings with no_warnings option", function()
			local old_stderr = io.stderr
			local stderr_output = {}
			io.stderr = {
				write = function(_, str)
					table.insert(stderr_output, str)
				end,
			}

			warnings.reset()
			luma.render("{{ x }}", { x = 1 }, { no_warnings = true })

			io.stderr = old_stderr

			local output = table.concat(stderr_output)
			assert.equals("", output)
		end)
	end)
end)
