--- Tests for Jinja2 compatibility syntax
-- @module spec.jinja_compat_spec

local luma = require("luma")
local runtime = require("luma.runtime")

describe("Jinja2 Compatibility", function()
	describe("Variable interpolation {{ }}", function()
		it("should render simple variable", function()
			local result = luma.render("Hello {{ name }}!", { name = "World" }, { syntax = "jinja" })
			assert.equals("Hello World!", result)
		end)

		it("should render variable with filter", function()
			local result = luma.render("{{ name | upper }}", { name = "hello" }, { syntax = "jinja" })
			assert.equals("HELLO", result)
		end)

		it("should render variable with multiple filters", function()
			local result = luma.render("{{ name | trim | upper }}", { name = "  hello  " }, { syntax = "jinja" })
			assert.equals("HELLO", result)
		end)

		it("should render nested property access", function()
			local result = luma.render("{{ user.name }}", { user = { name = "Alice" } }, { syntax = "jinja" })
			assert.equals("Alice", result)
		end)

		it("should render array index access", function()
			local result = luma.render("{{ items[1] }}", { items = { "first", "second" } }, { syntax = "jinja" })
			assert.equals("first", result)
		end)

		it("should render arithmetic expressions", function()
			local result = luma.render("{{ a + b }}", { a = 2, b = 3 }, { syntax = "jinja" })
			assert.equals("5", result)
		end)
	end)

	describe("If statements {% if %}", function()
		it("should render if true", function()
			local template = "{% if show %}Yes{% endif %}"
			local result = luma.render(template, { show = true }, { syntax = "jinja" })
			assert.equals("Yes", result)
		end)

		it("should not render if false", function()
			local template = "{% if show %}Yes{% endif %}"
			local result = luma.render(template, { show = false }, { syntax = "jinja" })
			assert.equals("", result)
		end)

		it("should handle if-else", function()
			local template = "{% if show %}Yes{% else %}No{% endif %}"
			local result = luma.render(template, { show = false }, { syntax = "jinja" })
			assert.equals("No", result)
		end)

		it("should handle if-elif-else", function()
			local template = "{% if x == 1 %}One{% elif x == 2 %}Two{% else %}Other{% endif %}"
			local result = luma.render(template, { x = 2 }, { syntax = "jinja" })
			assert.equals("Two", result)
		end)

		it("should support comparisons", function()
			local template = "{% if x > 5 %}Big{% endif %}"
			local result = luma.render(template, { x = 10 }, { syntax = "jinja" })
			assert.equals("Big", result)
		end)
	end)

	describe("For loops {% for %}", function()
		it("should iterate over array", function()
			local template = "{% for item in items %}{{ item }}{% endfor %}"
			local result = luma.render(template, { items = { "a", "b", "c" } }, { syntax = "jinja" })
			assert.equals("abc", result)
		end)

		it("should support loop variable", function()
			local template = "{% for item in items %}{{ loop.index }}{% endfor %}"
			local result = luma.render(template, { items = { "a", "b", "c" } }, { syntax = "jinja" })
			assert.equals("123", result)
		end)

		it("should support tuple unpacking", function()
			local template = "{% for key, value in items %}{{ key }}={{ value }} {% endfor %}"
			local result = luma.render(template, { items = { a = 1, b = 2 } }, { syntax = "jinja" })
			-- Order may vary for dicts
			assert.match("a=1", result)
			assert.match("b=2", result)
		end)

		it("should handle for-else with empty list", function()
			local template = "{% for item in items %}{{ item }}{% else %}Empty{% endfor %}"
			local result = luma.render(template, { items = {} }, { syntax = "jinja" })
			assert.equals("Empty", result)
		end)
	end)

	describe("Let/Set {% set %}", function()
		it("should set variable", function()
			local template = "{% set x = 5 %}{{ x }}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("5", result)
		end)

		it("should set computed variable", function()
			local template = "{% set x = a + b %}{{ x }}"
			local result = luma.render(template, { a = 2, b = 3 }, { syntax = "jinja" })
			assert.equals("5", result)
		end)
	end)

	describe("Macros {% macro %}", function()
		it("should define and call macro", function()
			local template = [[{% macro greet(name) %}Hello {{ name }}!{% endmacro %}{% call greet("World") %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("Hello World!", result)
		end)

		it("should support multiple parameters", function()
			local template = [[{% macro add(a, b) %}{{ a + b }}{% endmacro %}{% call add(2, 3) %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("5", result)
		end)
	end)

	describe("Comments {# #}", function()
		it("should ignore comment content", function()
			local template = "Hello{# this is a comment #} World"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("Hello World", result)
		end)

		it("should handle multiline comments", function()
			local template = "A{# multi\nline\ncomment #}B"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("AB", result)
		end)
	end)

	describe("Whitespace control", function()
		it("should trim whitespace after block with -}}", function()
			local template = "Hello{{ name -}}  World"
			local result = luma.render(template, { name = "X" }, { syntax = "jinja" })
			assert.equals("HelloXWorld", result)
		end)

		it("should trim whitespace after -%}", function()
			local template = "{% if true -%}  Trimmed{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("Trimmed", result)
		end)

		it("should not trim without -", function()
			local template = "{% if true %}  Not trimmed{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("  Not trimmed", result)
		end)
	end)

	describe("Include {% include %}", function()
		local templates = {}

		setup(function()
			runtime.set_loader(function(name)
				return templates[name]
			end)
		end)

		teardown(function()
			runtime.set_loader(nil)
		end)

		it("should include another template", function()
			templates["partial.html"] = "Included content"
			local template = "Before {% include 'partial.html' %} After"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.match("Before", result)
			assert.match("Included content", result)
			assert.match("After", result)
		end)
	end)

	describe("Template inheritance {% extends %}{% block %}", function()
		local templates = {}

		setup(function()
			runtime.set_loader(function(name)
				return templates[name]
			end)
		end)

		teardown(function()
			runtime.set_loader(nil)
		end)

		before_each(function()
			templates = {}
		end)

		it("should extend base template", function()
			templates["base.html"] = "Header {% block content %}Default{% endblock %} Footer"
			local child = "{% extends 'base.html' %}{% block content %}Custom{% endblock %}"
			local result = luma.render(child, {}, { syntax = "jinja" })
			assert.match("Header", result)
			assert.match("Custom", result)
			assert.match("Footer", result)
			assert.is_not.match("Default", result)
		end)

		it("should support nested inheritance", function()
			templates["grandparent.html"] = "GP {% block content %}GP Content{% endblock %} GP"
			templates["parent.html"] = "{% extends 'grandparent.html' %}{% block content %}Parent{% endblock %}"
			local child = "{% extends 'parent.html' %}{% block content %}Child{% endblock %}"
			local result = luma.render(child, {}, { syntax = "jinja" })
			assert.match("GP", result)
			assert.match("Child", result)
			assert.is_not.match("Parent", result)
		end)
	end)

	describe("Tests is/is not", function()
		it("should support is defined", function()
			local template = "{% if x is defined %}Yes{% else %}No{% endif %}"
			local result = luma.render(template, { x = 1 }, { syntax = "jinja" })
			assert.equals("Yes", result)
		end)

		it("should support is not defined", function()
			local template = "{% if x is not defined %}Yes{% else %}No{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("Yes", result)
		end)

		it("should support is none", function()
			local template = "{% if x is none %}Nil{% else %}Not nil{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("Nil", result)
		end)

		it("should support is odd/even", function()
			local template = "{% if x is odd %}Odd{% else %}Even{% endif %}"
			local result = luma.render(template, { x = 3 }, { syntax = "jinja" })
			assert.equals("Odd", result)
		end)
	end)

	describe("Membership operators in/not in", function()
		it("should support in for arrays", function()
			local template = "{% if 2 in items %}Yes{% endif %}"
			local result = luma.render(template, { items = { 1, 2, 3 } }, { syntax = "jinja" })
			assert.equals("Yes", result)
		end)

		it("should support not in for arrays", function()
			local template = "{% if 5 not in items %}Yes{% endif %}"
			local result = luma.render(template, { items = { 1, 2, 3 } }, { syntax = "jinja" })
			assert.equals("Yes", result)
		end)

		it("should support in for strings", function()
			local template = "{% if 'world' in s %}Yes{% endif %}"
			local result = luma.render(template, { s = "hello world" }, { syntax = "jinja" })
			assert.equals("Yes", result)
		end)
	end)

	describe("Break and Continue", function()
		it("should support break", function()
			local template = "{% for i in items %}{% if i == 3 %}{% break %}{% endif %}{{ i }}{% endfor %}"
			local result = luma.render(template, { items = { 1, 2, 3, 4, 5 } }, { syntax = "jinja" })
			assert.equals("12", result)
		end)

		it("should support continue", function()
			local template = "{% for i in items %}{% if i == 3 %}{% continue %}{% endif %}{{ i }}{% endfor %}"
			local result = luma.render(template, { items = { 1, 2, 3, 4, 5 } }, { syntax = "jinja" })
			assert.equals("1245", result)
		end)
	end)

	describe("Auto-detection", function()
		it("should auto-detect Jinja syntax", function()
			local result = luma.render("Hello {{ name }}!", { name = "World" })
			assert.equals("Hello World!", result)
		end)

		it("should auto-detect native syntax", function()
			local result = luma.render("Hello $name!", { name = "World" })
			assert.equals("Hello World!", result)
		end)
	end)
end)
