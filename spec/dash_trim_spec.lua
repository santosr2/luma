--- Tests for dash trimming in Luma native syntax
-- @module spec.dash_trim_spec

local luma = require("luma")

describe("Dash Trimming", function()
	describe("simple interpolation trimming", function()
		it("should trim whitespace before with -$var", function()
			local template = "Hello   -$name!"
			local result = luma.render(template, { name = "World" })
			assert.equals("HelloWorld!", result)
		end)

		it("should trim whitespace after with $var-", function()
			local template = "Hello$name-   !"
			local result = luma.render(template, { name = "World" })
			assert.equals("HelloWorld!", result)
		end)

		it("should trim both sides with -$var-", function()
			local template = "Hello   -$name-   !"
			local result = luma.render(template, { name = "World" })
			assert.equals("HelloWorld!", result)
		end)

		it("should not trim when dash is not adjacent", function()
			local template = "Hello - $name - !"
			local result = luma.render(template, { name = "World" })
			assert.equals("Hello - World - !", result)
		end)
	end)

	describe("expression interpolation trimming", function()
		it("should trim whitespace before with -${expr}", function()
			local template = "Count:   -${num + 1}"
			local result = luma.render(template, { num = 5 })
			assert.equals("Count:6", result)
		end)

		it("should trim whitespace after with ${expr}-", function()
			local template = "Count: ${num + 1}-   items"
			local result = luma.render(template, { num = 5 })
			assert.equals("Count: 6items", result)
		end)

		it("should trim both sides with -${expr}-", function()
			local template = "Count:   -${num + 1}-   items"
			local result = luma.render(template, { num = 5 })
			assert.equals("Count:6items", result)
		end)
	end)

	describe("directive trimming", function()
		it("should trim whitespace before directive with -@if", function()
			local template = [[
Status:   -@if active
Success
@end]]
			local result = luma.render(template, { active = true })
			assert.equals("Status:Success\n", result)
		end)

		it("should work with nested directives", function()
			local template = [[
Tags:   -@for tag in tags
  -$tag-@if not loop.last; , @end
@end]]
			local result = luma.render(template, { tags = { "red", "green", "blue" } })
			assert.equals("Tags:red,green,blue", result:gsub("%s+", ""))
		end)
	end)

	describe("complex scenarios", function()
		it("should handle trimming in loops", function()
			local template = "@for item in items-$item-@end"
			local result = luma.render(template, { items = { "A", "B", "C" } })
			assert.equals("ABC", result)
		end)

		it("should handle trimming with filters", function()
			local template = "Name:   -${name | upper}-   !"
			local result = luma.render(template, { name = "alice" })
			assert.equals("Name:ALICE!", result)
		end)

		it("should trim multiline whitespace", function()
			local template = [[
Line 1
-$value-
Line 2]]
			local result = luma.render(template, { value = "X" })
			-- Trim should remove trailing/leading whitespace around X
			assert.matches("Line 1X", result)
			assert.matches("XLine 2", result)
		end)

		it("should not affect escaped dollars", function()
			local template = "Price: $$100 -$extra"
			local result = luma.render(template, { extra = "50" })
			-- The -$ should trim the space before $extra, so no space between $100 and 50
			assert.equals("Price: $10050", result)
		end)
	end)

	describe("mixed with smart preservation", function()
		it("should work in YAML context", function()
			local template = [[
apiVersion: v1
metadata:
  name:   -$name-
  labels:
    app: myapp]]
			local result = luma.render(template, { name = "my-service" })
			assert.matches("name:my%-service", result)
			assert.not_matches("name:%s+my%-service", result)
		end)

		it("should work inline with text", function()
			local template = "Status: @if active-$status-@else Inactive @end"
			local result = luma.render(template, { active = true, status = "OK" })
			assert.equals("Status: OK", result)
		end)
	end)

	describe("edge cases", function()
		it("should handle empty string values", function()
			local template = "A-$empty-B"
			local result = luma.render(template, { empty = "" })
			assert.equals("AB", result)
		end)

		it("should handle dash at boundaries", function()
			local template = "-$value-"
			local result = luma.render(template, { value = "X" })
			assert.equals("X", result)
		end)

		it("should work with member access", function()
			local template = "User:   -$user.name-   logged in"
			local result = luma.render(template, { user = { name = "Alice" } })
			assert.equals("User:Alicelogged in", result)
		end)

		it("should work with chained filters", function()
			local template = "-${text | upper | truncate(5)}-"
			local result = luma.render(template, { text = "hello world" })
			assert.equals("HE...", result)
		end)
	end)

	describe("comparison with Jinja2 trim syntax", function()
		it("Jinja2 {{- var -}} equivalent to Luma -$var-", function()
			local jinja_template = "Hello  {{- name -}}  !"
			local luma_template = "Hello  -$name-  !"

			local jinja_result = luma.render(jinja_template, { name = "World" }, { syntax = "jinja" })
			local luma_result = luma.render(luma_template, { name = "World" })

			assert.equals(jinja_result, luma_result)
		end)

		it("Jinja2 {%- if %} equivalent to Luma -@if", function()
			local jinja_template = "Status:  {%- if active %}OK{% endif %}"
			local luma_template = "Status:  -@if active; OK @end"

			local jinja_result = luma.render(jinja_template, { active = true }, { syntax = "jinja" })
			local luma_result = luma.render(luma_template, { active = true })

			-- Both should trim leading whitespace before the conditional
			assert.equals("Status:OK", jinja_result)
			-- Luma has space before @end which becomes part of output, normalize it
			assert.equals("Status:OK", luma_result:gsub("%s+", ""))
		end)
	end)
end)
