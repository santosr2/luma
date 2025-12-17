--- Tests for Jinja2 whitespace trimming ({%- -%} {{- -}})
-- @module spec.jinja_trim_spec

local luma = require("luma")

describe("Jinja2 Whitespace Trimming", function()
	describe("trim after (-}}  -%})", function()
		it("should trim whitespace after variable with -}}", function()
			local template = "Hello {{ name -}}  \n  World"
			local result = luma.render(template, { name = "Alice" }, { syntax = "jinja" })
			assert.equals("Hello AliceWorld", result)
		end)

		it("should trim whitespace after statement with -%}", function()
			local template = "Hello {% if true -%}\n  \nWorld{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("Hello World", result)
		end)

		it("should trim whitespace after endif with -%}", function()
			local template = "A{% if true %}B{% endif -%}  \n  C"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("ABC", result)
		end)
	end)

	describe("trim before ({{-  {%-)", function()
		it("should trim whitespace before variable with {{-", function()
			local template = "Hello  \n  {{- name }}"
			local result = luma.render(template, { name = "Alice" }, { syntax = "jinja" })
			assert.equals("HelloAlice", result)
		end)

		it("should trim whitespace before statement with {%-", function()
			local template = "Hello  \n  {%- if true %}World{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("HelloWorld", result)
		end)

		it("should trim whitespace before endif with {%-", function()
			local template = "A{% if true %}B  \n  {%- endif %}C"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("ABC", result)
		end)

		it("should trim whitespace before comment with {#-", function()
			local template = "Hello  \n  {#- comment #}World"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("HelloWorld", result)
		end)
	end)

	describe("combined trim ({{- -}}  {%- -%})", function()
		it("should trim both sides with {{- -}}", function()
			local template = "A  \n  {{- name -}}  \n  B"
			local result = luma.render(template, { name = "X" }, { syntax = "jinja" })
			assert.equals("AXB", result)
		end)

		it("should trim both sides with {%- -%}", function()
			local template = "A  \n  {%- if true -%}  \n  B  \n  {%- endif -%}  \n  C"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("ABC", result)
		end)

		it("should handle complex nested trimming", function()
			local template = [[
A
  {%- if true %}
    {{- "B" -}}
  {%- endif -%}
C]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("ABC", result)
		end)
	end)

	describe("selective trimming", function()
		it("should only trim after when only -%} is used", function()
			local template = "A  \n  {% if true -%}  \n  B{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			-- Jinja2 behavior: preserves whitespace before directive AND inside body
			-- The -%} only trims whitespace immediately after the %}, not the body content
			assert.equals("A  \n  B", result)
		end)

		it("should only trim before when only {%- is used", function()
			local template = "A  \n  {%- if true %}  \n  B{% endif %}"
			local result = luma.render(template, {}, { syntax = "jinja" })
			-- Jinja2 behavior: {%- trims whitespace before the directive
			-- But in this case, directive is on its own line, so behaves same as test above
			assert.equals("A  \n  B", result)
		end)

		it("should not trim when no markers are present", function()
			local template = "A  \n  {% if true %}  \n  B  \n  {% endif %}  \n  C"
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.match("A%s+", result)
			assert.match("%s+B%s+", result)
			assert.match("%s+C", result)
		end)
	end)

	describe("trim with loops", function()
		it("should trim around for loops", function()
			local template = "Items:  \n  {%- for i in items %}  \n  - {{ i }}  \n  {%- endfor -%}  \n  Done"
			local result = luma.render(template, { items = { 1, 2, 3 } }, { syntax = "jinja" })
			assert.matches("Items:%s*%-%s*1%s*%-%s*2%s*%-%s*3%s*Done", result)
		end)

		it("should handle trim in loop body", function()
			local template = "{%- for i in items -%}{{- i -}}{%- endfor -%}"
			local result = luma.render(template, { items = { "a", "b", "c" } }, { syntax = "jinja" })
			assert.equals("abc", result)
		end)
	end)

	describe("edge cases", function()
		it("should handle trim when there's no preceding whitespace", function()
			local template = "A{{- name }}"
			local result = luma.render(template, { name = "B" }, { syntax = "jinja" })
			assert.equals("AB", result)
		end)

		it("should handle trim when there's no following whitespace", function()
			local template = "{{ name -}}B"
			local result = luma.render(template, { name = "A" }, { syntax = "jinja" })
			assert.equals("AB", result)
		end)

		it("should handle multiple consecutive trims", function()
			local template = "{{- a -}}{{- b -}}{{- c -}}"
			local result = luma.render(template, { a = "1", b = "2", c = "3" }, { syntax = "jinja" })
			assert.equals("123", result)
		end)

		it("should not affect newlines within expressions", function()
			local template = [[ {{- "hello\nworld" -}} ]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("hello\nworld", result)
		end)
	end)

	describe("auto-detection with trimming", function()
		it("should auto-detect Jinja syntax with trim markers", function()
			local template = "A  \n  {{- name -}}  \n  B"
			local result = luma.render(template, { name = "X" })
			assert.equals("AXB", result)
		end)
	end)
end)
