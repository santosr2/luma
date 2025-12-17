--- Tests for include context modifiers
-- @module spec.include_modifiers_spec

local luma = require("luma")
local io = require("io")
local os = require("os")

-- Helper to create temporary template files
local function create_temp_file(filename, content)
	local path = "/tmp/luma_test_" .. filename
	local file = io.open(path, "w")
	if file then
		file:write(content)
		file:close()
	end
	return path
end

-- Helper to remove temporary files
local function remove_temp_file(path)
	os.remove(path)
end

describe("Include Context Modifiers", function()
	describe("with context (default)", function()
		it("should include with context by default", function()
			local partial = create_temp_file("partial1.luma", "Hello, $name!")

			local template = [[
{% include "]] .. partial .. [[" %}]]
			local result = luma.render(template, { name = "World" }, { syntax = "jinja" })
			assert.matches("Hello, World!", result)

			remove_temp_file(partial)
		end)

		it("should include with context explicitly", function()
			local partial = create_temp_file("partial2.luma", "Value: $value")

			local template = [[
@include "]] .. partial .. [[" with context
]]
			local result = luma.render(template, { value = 42 })
			assert.matches("Value: 42", result)

			remove_temp_file(partial)
		end)

		it("should pass all context variables", function()
			local partial = create_temp_file("partial3.luma", "$x, $y, $z")

			local template = [[
{% include "]] .. partial .. [[" with context %}]]
			local result = luma.render(template, {
				x = "A",
				y = "B",
				z = "C",
			}, { syntax = "jinja" })
			assert.matches("A, B, C", result)

			remove_temp_file(partial)
		end)
	end)

	describe("without context", function()
		it("should not pass context variables", function()
			local partial = create_temp_file("partial4.luma", "Value: $value")

			local template = [[
{% include "]] .. partial .. [[" without context %}]]
			local result = luma.render(template, { value = 42 }, { syntax = "jinja" })
			-- Variable should be empty/undefined without context
			assert.matches("Value:%s*$", result)

			remove_temp_file(partial)
		end)

		it("should work with Luma syntax", function()
			local partial = create_temp_file("partial5.luma", "Name: $name")

			local template = [[
@include "]] .. partial .. [[" without context
]]
			local result = luma.render(template, { name = "Alice" })
			assert.matches("Name:%s*$", result)

			remove_temp_file(partial)
		end)

		it("should create isolated include", function()
			local partial = create_temp_file(
				"partial6.luma",
				[[
X: $x
Y: $y
Z: $z]]
			)

			local template = [[
{% include "]] .. partial .. [[" without context %}]]
			local result = luma.render(template, {
				x = 1,
				y = 2,
				z = 3,
			}, { syntax = "jinja" })
			-- None of the variables should be available
			assert.not_matches("X: 1", result)
			assert.not_matches("Y: 2", result)
			assert.not_matches("Z: 3", result)

			remove_temp_file(partial)
		end)
	end)

	describe("ignore missing", function()
		it("should not error on missing file", function()
			local template = [[
Before
{% include "nonexistent.html" ignore missing %}
After]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Before", result)
			assert.matches("After", result)
		end)

		it("should work with Luma syntax", function()
			local template = [[
@include "missing_file.luma" ignore missing
Content continues
]]
			local result = luma.render(template, {})
			assert.matches("Content continues", result)
		end)

		it("should work combined with context modifiers", function()
			local template = [[
{% include "missing.html" without context ignore missing %}
Text after
]]
			local result = luma.render(template, { var = "test" }, { syntax = "jinja" })
			assert.matches("Text after", result)
		end)

		it("should include existing file normally", function()
			local partial = create_temp_file("partial7.luma", "Found: $value")

			local template = [[
{% include "]] .. partial .. [[" ignore missing %}]]
			local result = luma.render(template, { value = "yes" }, { syntax = "jinja" })
			assert.matches("Found: yes", result)

			remove_temp_file(partial)
		end)
	end)

	describe("combined modifiers", function()
		it("should combine with context and ignore missing", function()
			local template = [[
{% include "missing.html" with context ignore missing %}
Continues]]
			local result = luma.render(template, { data = "test" }, { syntax = "jinja" })
			assert.matches("Continues", result)
		end)

		it("should combine without context and ignore missing", function()
			local partial = create_temp_file("partial8.luma", "Value: $val")

			local template = [[
{% include "]] .. partial .. [[" without context ignore missing %}]]
			local result = luma.render(template, { val = "should not appear" }, { syntax = "jinja" })
			assert.matches("Value:%s*$", result)

			remove_temp_file(partial)
		end)
	end)

	describe("practical use cases", function()
		it("should be useful for optional partials", function()
			local template = [[
<div class="header">
{% include "custom_header.html" ignore missing %}
<h1>{{ title }}</h1>
</div>]]
			local result = luma.render(template, { title = "My Page" }, { syntax = "jinja" })
			assert.matches("<h1>My Page</h1>", result)
		end)

		it("should be useful for isolated components", function()
			local widget = create_temp_file(
				"widget.luma",
				[[
<div class="widget">
Widget content (no access to page vars)
</div>]]
			)

			local template = [[
{% set page_data = "sensitive" %}
{% include "]] .. widget .. [[" without context %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Widget content", result)

			remove_temp_file(widget)
		end)

		it("should be useful for plugin systems", function()
			local template = [[
<!-- Try to load user customization -->
@include "user_custom.luma" ignore missing

<!-- Default content -->
<p>Default content</p>
]]
			local result = luma.render(template, {})
			assert.matches("Default content", result)
		end)
	end)

	describe("edge cases", function()
		it("should handle empty file with context", function()
			local empty = create_temp_file("empty.luma", "")

			local template = [[
Before
{% include "]] .. empty .. [[" with context %}
After]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Before", result)
			assert.matches("After", result)

			remove_temp_file(empty)
		end)

		it("should handle dynamic paths with modifiers", function()
			local partial = create_temp_file("dynamic.luma", "Dynamic: $data")

			local template = [[
{% include template_path without context %}]]
			local result = luma.render(template, {
				template_path = partial,
				data = "should not appear",
			}, { syntax = "jinja" })
			assert.matches("Dynamic:%s*$", result)

			remove_temp_file(partial)
		end)

		it("should work inside loops", function()
			local item_template = create_temp_file("item.luma", "- $item.name")

			local template = [[
{% for item in items %}
{% include "]] .. item_template .. [[" with context %}
{% endfor %}]]
			local result = luma.render(template, {
				items = {
					{ name = "Apple" },
					{ name = "Banana" },
				},
			}, { syntax = "jinja" })
			assert.matches("- Apple", result)
			assert.matches("- Banana", result)

			remove_temp_file(item_template)
		end)
	end)

	describe("Jinja2 compatibility", function()
		it("should match Jinja2 with context behavior", function()
			local partial = create_temp_file("jinja1.luma", "User: {{ username }}")

			local template = [[
{% include "]] .. partial .. [[" with context %}]]
			local result = luma.render(template, { username = "admin" }, { syntax = "jinja" })
			assert.matches("User: admin", result)

			remove_temp_file(partial)
		end)

		it("should match Jinja2 without context behavior", function()
			local partial = create_temp_file("jinja2.luma", "Secret: {{ secret }}")

			local template = [[
{% include "]] .. partial .. [[" without context %}]]
			local result = luma.render(template, { secret = "hidden" }, { syntax = "jinja" })
			assert.matches("Secret:%s*$", result)

			remove_temp_file(partial)
		end)

		it("should match Jinja2 ignore missing behavior", function()
			local template = [[
{% include "this_file_does_not_exist.html" ignore missing %}
Continued]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Continued", result)
		end)
	end)
end)
