--- Tests for filter blocks
-- @module spec.filter_block_spec

local luma = require("luma")

describe("Filter Blocks", function()
	describe("basic filter block functionality", function()
		it("should apply filter to block content", function()
			local template = [[
{% filter upper %}
hello world
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("HELLO WORLD", result)
		end)

		it("should work with Luma native syntax", function()
			local template = [[
@filter lower
HELLO WORLD
@endfilter]]
			local result = luma.render(template, {})
			assert.matches("hello world", result)
		end)

		it("should preserve multiline content", function()
			local template = [[
{% filter upper %}
line 1
line 2
line 3
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("LINE 1", result)
			assert.matches("LINE 2", result)
			assert.matches("LINE 3", result)
		end)
	end)

	describe("filters with arguments", function()
		it("should apply filter with positional arguments", function()
			local template = [[
{% filter truncate(20) %}
This is a very long text that should be truncated
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.is_true(#result < 25)
			assert.matches("%.%.%.", result)
		end)

		it("should apply filter with named arguments", function()
			local template = [[
@filter truncate(length=15, end=">>")
This is some long text here
@endfilter]]
			local result = luma.render(template, {})
			assert.is_true(#result:match("^%s*(.-)%s*$") <= 20)
			assert.matches(">>", result)
		end)

		it("should work with wordwrap", function()
			local template = [[
{% filter wordwrap(10) %}
This is a long sentence that should be wrapped
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			-- Should have newlines from wrapping
			assert.matches("\n", result)
		end)

		it("should work with indent", function()
			local template = [[
{% filter indent(4) %}
Line 1
Line 2
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("    Line 1", result)
			assert.matches("    Line 2", result)
		end)
	end)

	describe("with dynamic content", function()
		it("should apply filter to interpolated content", function()
			local template = [[
{% filter upper %}
Hello {{ name }}!
{% endfilter %}]]
			local result = luma.render(template, { name = "Alice" }, { syntax = "jinja" })
			assert.matches("HELLO ALICE!", result)
		end)

		it("should work with loops inside filter", function()
			local template = [[
@filter upper
@for item in items
$item
@end
@endfilter]]
			local result = luma.render(template, { items = { "apple", "banana", "cherry" } })
			assert.matches("APPLE", result)
			assert.matches("BANANA", result)
			assert.matches("CHERRY", result)
		end)

		it("should work with conditionals inside filter", function()
			local template = [[
{% filter lower %}
{% if show %}
VISIBLE TEXT
{% else %}
HIDDEN TEXT
{% endif %}
{% endfilter %}]]
			local result = luma.render(template, { show = true }, { syntax = "jinja" })
			assert.matches("visible text", result)
			assert.not_matches("hidden", result:lower())
		end)
	end)

	describe("nested filter blocks", function()
		it("should handle nested filter blocks", function()
			local template = [[
{% filter upper %}
outer
{% filter trim %}
  inner with spaces
{% endfilter %}
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("OUTER", result)
			assert.matches("INNER WITH SPACES", result)
		end)

		it("should apply filters in correct order", function()
			local template = [[
@filter upper
@filter trim
  text
@endfilter
@endfilter]]
			local result = luma.render(template, {})
			-- trim first (removes spaces), then upper
			assert.equals("TEXT", result:match("^%s*(.-)%s*$"))
		end)
	end)

	describe("with HTML/escaping", function()
		it("should apply filter after escaping", function()
			local template = [[
{% filter upper %}
{{ html }}
{% endfilter %}]]
			local result = luma.render(template, { html = "<tag>" }, { syntax = "jinja" })
			-- Content is escaped first, then filtered
			assert.matches("&LT;TAG&GT;", result)
		end)

		it("should work with safe content", function()
			local template = [[
{% filter upper %}
{{ html | safe }}
{% endfilter %}]]
			local result = luma.render(template, { html = "<tag>" }, { syntax = "jinja" })
			assert.matches("<TAG>", result)
		end)
	end)

	describe("with other filters", function()
		it("should work with replace filter", function()
			local template = [[
{% filter replace("a", "X") %}
banana
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("bXnXnX", result)
		end)

		it("should work with center filter", function()
			local template = [[
{% filter center(20) %}
text
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			-- Text should be centered
			local trimmed = result:match("^%s*(.-)%s*$")
			assert.is_true(#result:gsub("\n", "") >= 20)
		end)

		it("should work with reverse filter", function()
			local template = [[
@filter reverse
abc
@endfilter]]
			local result = luma.render(template, {})
			assert.matches("cba", result)
		end)
	end)

	describe("practical use cases", function()
		it("should be useful for code formatting", function()
			local template = [[
{% filter indent(2) %}
function hello() {
  console.log("hi");
}
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("  function", result)
			assert.matches("    console", result)
		end)

		it("should be useful for text processing", function()
			local template = [[
@filter trim | upper

  Important Message

@endfilter]]
			-- Note: Can't chain filters in filter directive itself in Jinja2
			-- This test shows single filter application
			local template2 = [[
@filter upper
@filter trim
  Important Message
@endfilter
@endfilter]]
			local result = luma.render(template2, {})
			assert.equals("IMPORTANT MESSAGE", result:match("^%s*(.-)%s*$"))
		end)

		it("should be useful for documentation generation", function()
			local template = [[
{% filter wordwrap(60) %}
This is a very long line of documentation text that should be wrapped at 60 characters for better readability in terminals and code editors.
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			-- Should have line breaks
			assert.matches("\n", result)
		end)
	end)

	describe("edge cases", function()
		it("should handle empty block", function()
			local template = [[
{% filter upper %}
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("", result:match("^%s*(.-)%s*$"))
		end)

		it("should handle whitespace-only block", function()
			local template = [[
{% filter trim %}

{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.equals("", result:match("^%s*(.-)%s*$"))
		end)

		it("should work with macros inside", function()
			local template = [[
@macro greet(name)
Hello, $name!
@end

@filter upper
@call greet("world")
@endfilter]]
			local result = luma.render(template, {})
			assert.matches("HELLO, WORLD!", result)
		end)

		it("should work inside loops", function()
			local template = [[
{% for name in names %}
{% filter upper %}
{{ name }}
{% endfilter %}
{% endfor %}]]
			local result = luma.render(template, {
				names = { "alice", "bob" },
			}, { syntax = "jinja" })
			assert.matches("ALICE", result)
			assert.matches("BOB", result)
		end)
	end)

	describe("Jinja2 compatibility", function()
		it("should match Jinja2 filter block behavior", function()
			local template = [[
{% filter upper %}
hello, world!
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("HELLO, WORLD!", result)
		end)

		it("should match Jinja2 with variables", function()
			local template = [[
{% filter replace("foo", "bar") %}
foo is everywhere foo
{% endfilter %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("bar is everywhere bar", result)
		end)
	end)
end)
