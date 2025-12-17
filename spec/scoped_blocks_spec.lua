--- Tests for scoped blocks
-- @module spec.scoped_blocks_spec

local luma = require("luma")

describe("Scoped Blocks", function()
	describe("basic scoped block functionality", function()
		it("should isolate variables in scoped block", function()
			local template = [[
{% set x = "outer" %}
Outer: {{ x }}
{% block content scoped %}
{% set x = "inner" %}
Block: {{ x }}
{% endblock %}
After: {{ x }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Outer: outer", result)
			assert.matches("Block: inner", result)
			assert.matches("After: outer", result) -- x unchanged outside block
		end)

		it("should allow reading outer variables in scoped block", function()
			local template = [[
{% set greeting = "Hello" %}
{% block content scoped %}
{{ greeting }}, World!
{% endblock %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Hello, World!", result)
		end)

		it("should prevent assignments from leaking out", function()
			local template = [[
{% block test scoped %}
{% set leaked = "should not leak" %}
{% endblock %}
Value: {{ leaked }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			-- leaked should be empty/undefined outside the scoped block
			assert.matches("Value:%s*$", result)
		end)

		it("should work with Luma native syntax", function()
			local template = [[
@let name = "Original"
@block content scoped
@let name = "Modified"
Inside: $name
@end
Outside: $name]]
			local result = luma.render(template, {})
			assert.matches("Inside: Modified", result)
			assert.matches("Outside: Original", result)
		end)
	end)

	describe("comparison with regular blocks", function()
		it("regular block should allow variable leaking", function()
			local template = [[
{% set x = "outer" %}
{% block content %}
{% set x = "modified" %}
{% endblock %}
After: {{ x }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("After: modified", result) -- x was modified
		end)

		it("scoped block should prevent variable leaking", function()
			local template = [[
{% set x = "outer" %}
{% block content scoped %}
{% set x = "modified" %}
{% endblock %}
After: {{ x }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("After: outer", result) -- x unchanged
		end)
	end)

	describe("with template inheritance", function()
		it("should work with extends and scoped blocks", function()
			-- Note: This test demonstrates the concept
			-- Full implementation requires file system support
			local child = [[
{% set page_title = "Child" %}
{% block content scoped %}
{% set local_var = "local" %}
Title: {{ page_title }}
Local: {{ local_var }}
{% endblock %}]]

			local result = luma.render(child, {}, { syntax = "jinja" })
			assert.matches("Title: Child", result)
			assert.matches("Local: local", result)
		end)

		it("should isolate context in overridden scoped blocks", function()
			local template = [[
{% set global = "global value" %}
{% block content scoped %}
{% set block_var = "block value" %}
Global: {{ global }}
Block: {{ block_var }}
{% endblock %}
Outside: {{ block_var }}]]

			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Global: global value", result)
			assert.matches("Block: block value", result)
			assert.matches("Outside:%s*$", result) -- block_var not available
		end)
	end)

	describe("nested scoped blocks", function()
		it("should handle nested scoped blocks", function()
			local template = [[
{% set x = "L0" %}
{% block outer scoped %}
{% set x = "L1" %}
L1: {{ x }}
{% block inner scoped %}
{% set x = "L2" %}
L2: {{ x }}
{% endblock %}
Back L1: {{ x }}
{% endblock %}
Back L0: {{ x }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("L1: L1", result)
			assert.matches("L2: L2", result)
			assert.matches("Back L1: L1", result)
			assert.matches("Back L0: L0", result)
		end)

		it("should mix scoped and non-scoped blocks", function()
			local template = [[
{% set x = "outer" %}
{% block scoped_block scoped %}
{% set x = "scoped" %}
Scoped: {{ x }}
{% endblock %}
After scoped: {{ x }}
{% block normal_block %}
{% set x = "normal" %}
Normal: {{ x }}
{% endblock %}
After normal: {{ x }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Scoped: scoped", result)
			assert.matches("After scoped: outer", result)
			assert.matches("Normal: normal", result)
			assert.matches("After normal: normal", result) -- normal block modified x
		end)
	end)

	describe("with loops and conditionals", function()
		it("should work with loops inside scoped blocks", function()
			local template = [[
{% set counter = 0 %}
{% block content scoped %}
{% for i in items %}
{% set counter = i %}
Item: {{ i }}
{% endfor %}
Last: {{ counter }}
{% endblock %}
Outside: {{ counter }}]]
			local result = luma.render(template, {
				items = { 1, 2, 3 },
			}, { syntax = "jinja" })
			assert.matches("Last: 3", result)
			assert.matches("Outside: 0", result) -- counter unchanged outside
		end)

		it("should work with conditionals inside scoped blocks", function()
			local template = [[
{% set flag = false %}
{% block content scoped %}
{% if true %}
{% set flag = true %}
{% endif %}
Inside: {{ flag }}
{% endblock %}
Outside: {{ flag }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Inside: true", result)
			assert.matches("Outside: false", result)
		end)
	end)

	describe("edge cases", function()
		it("should handle empty scoped block", function()
			local template = [[
{% set x = "test" %}
{% block content scoped %}
{% endblock %}
After: {{ x }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("After: test", result)
		end)

		it("should handle multiple variables", function()
			local template = [[
{% set a = 1 %}
{% set b = 2 %}
{% block scoped scoped %}
{% set a = 10 %}
{% set b = 20 %}
{% set c = 30 %}
Scoped: {{ a }}, {{ b }}, {{ c }}
{% endblock %}
Outside: {{ a }}, {{ b }}, {{ c }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Scoped: 10, 20, 30", result)
			assert.matches("Outside: 1, 2,%s*$", result) -- c is undefined
		end)

		it("should allow reading from outer scope", function()
			local template = [[
{% set user = {"name": "Alice", "age": 30} %}
{% block info scoped %}
{% set user = {"name": "Bob", "age": 25} %}
Inner user: {{ user.name }}
{% endblock %}
Outer user: {{ user.name }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Inner user: Bob", result)
			assert.matches("Outer user: Alice", result)
		end)
	end)

	describe("practical use cases", function()
		it("should be useful for isolated component rendering", function()
			local template = [[
{% set theme = "dark" %}
{% block widget scoped %}
{% set theme = "light" %}
{% set title = "Widget Title" %}
<div class="{{ theme }}">
  <h1>{{ title }}</h1>
</div>
{% endblock %}
<body class="{{ theme }}">
  Main content
</body>]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches('div class="light"', result)
			assert.matches('body class="dark"', result)
		end)

		it("should prevent naming conflicts in macros", function()
			local template = [[
{% set temp = "global" %}
{% block process scoped %}
{% for item in items %}
{% set temp = item | upper %}
{{ temp }}
{% endfor %}
{% endblock %}
Global temp: {{ temp }}]]
			local result = luma.render(template, {
				items = { "a", "b", "c" },
			}, { syntax = "jinja" })
			assert.matches("A", result)
			assert.matches("B", result)
			assert.matches("C", result)
			assert.matches("Global temp: global", result)
		end)
	end)

	describe("Jinja2 compatibility", function()
		it("should match Jinja2 scoped block behavior", function()
			local template = [[
{% set x = 42 %}
{% block content scoped %}
{% set x = 99 %}
In block: {{ x }}
{% endblock %}
Outside block: {{ x }}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("In block: 99", result)
			assert.matches("Outside block: 42", result)
		end)

		it("should allow reading parent context", function()
			local template = [[
{% set config = {"debug": true} %}
{% block component scoped %}
Debug mode: {{ config.debug }}
{% endblock %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Debug mode: true", result)
		end)
	end)
end)
