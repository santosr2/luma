--- Tests for call with caller pattern
-- @module spec.call_with_caller_spec

local luma = require("luma")

describe("Call with Caller Pattern", function()
	describe("basic caller functionality", function()
		it("should pass caller to macro", function()
			local template = [[
@macro dialog(title)
<div class="dialog">
  <h1>$title</h1>
  <div class="body">
    @call caller()
  </div>
</div>
@end

@call(item) dialog("My Dialog")
This is the content from the caller!
@endcall]]
			local result = luma.render(template, {})
			assert.matches("<h1>My Dialog</h1>", result)
			assert.matches("This is the content from the caller!", result)
		end)

		it("should work with Jinja2 syntax", function()
			local template = [[
{% macro dialog(title) %}
<div class="dialog">
  <h1>{{ title }}</h1>
  <div class="body">
    {{ caller() }}
  </div>
</div>
{% endmacro %}

{% call dialog("Test Dialog") %}
Hello from caller!
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("<h1>Test Dialog</h1>", result)
			assert.matches("Hello from caller!", result)
		end)
	end)

	describe("caller with parameters", function()
		it("should pass parameters to caller", function()
			local template = [[
{% macro list_items(items) %}
<ul>
{% for item in items %}
  <li>{{ caller(item) }}</li>
{% endfor %}
</ul>
{% endmacro %}

{% call(item) list_items([1, 2, 3]) %}
  Item: {{ item }}
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("<li>%s*Item: 1%s*</li>", result)
			assert.matches("<li>%s*Item: 2%s*</li>", result)
			assert.matches("<li>%s*Item: 3%s*</li>", result)
		end)

		it("should support multiple parameters", function()
			local template = [[
@macro table_row()
<table>
@call caller("Header", "center")
</table>
@end

@call(text, align) table_row()
<th style="text-align: $align">$text</th>
@endcall]]
			local result = luma.render(template, {})
			assert.matches("<th", result)
			assert.matches("Header", result)
			assert.matches("center", result)
		end)

		it("should work with complex parameters", function()
			local template = [[
{% macro render_users(users) %}
{% for user in users %}
  {{ caller(user.name, user.age) }}
{% endfor %}
{% endmacro %}

{% call(name, age) render_users(users) %}
Name: {{ name }}, Age: {{ age }}
{% endcall %}]]
			local result = luma.render(template, {
				users = {
					{ name = "Alice", age = 30 },
					{ name = "Bob", age = 25 },
				},
			}, { syntax = "jinja" })
			assert.matches("Name: Alice, Age: 30", result)
			assert.matches("Name: Bob, Age: 25", result)
		end)
	end)

	describe("nested calls", function()
		it("should handle nested call-with-caller", function()
			local template = [[
{% macro outer() %}
<div class="outer">
{{ caller() }}
</div>
{% endmacro %}

{% macro inner() %}
<div class="inner">
{{ caller() }}
</div>
{% endmacro %}

{% call outer() %}
  {% call inner() %}
    Nested content
  {% endcall %}
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches('<div class="outer">', result)
			assert.matches('<div class="inner">', result)
			assert.matches("Nested content", result)
		end)

		it("should preserve caller context in nested calls", function()
			local template = [[
@macro outer_macro()
Outer: @call caller()
@end

@macro inner_macro()
Inner: @call caller()
@end

@call outer_macro()
  @call inner_macro()
    Deep content
  @endcall
@endcall]]
			local result = luma.render(template, {})
			assert.matches("Outer:", result)
			assert.matches("Inner:", result)
			assert.matches("Deep content", result)
		end)
	end)

	describe("caller with variables", function()
		it("should allow accessing outer context in caller", function()
			local template = [[
{% set greeting = "Hello" %}

{% macro wrapper() %}
<div>
{{ caller() }}
</div>
{% endmacro %}

{% call wrapper() %}
{{ greeting }}, World!
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Hello, World!", result)
		end)

		it("should allow setting variables in caller", function()
			local template = [[
@macro repeat_caller(times)
@for i in times
  @call caller(i)
@end
@end

@call(index) repeat_caller({1, 2, 3})
  @let message = "Item " .. tostring(index)
  $message
@endcall]]
			local result = luma.render(template, {})
			assert.matches("Item 1", result)
			assert.matches("Item 2", result)
			assert.matches("Item 3", result)
		end)
	end)

	describe("practical use cases", function()
		it("should be useful for HTML components", function()
			local template = [[
{% macro panel(title, type) %}
<div class="panel panel-{{ type }}">
  <div class="panel-heading">{{ title }}</div>
  <div class="panel-body">
    {{ caller() }}
  </div>
</div>
{% endmacro %}

{% call panel("Success", "success") %}
Operation completed successfully!
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches('class="panel panel%-success"', result)
			assert.matches("Success", result)
			assert.matches("Operation completed successfully!", result)
		end)

		it("should be useful for iteration patterns", function()
			local template = [[
@macro each_with_index(items)
@for i, item in ipairs(items)
  @call caller(item, i)
@end
@end

@call(item, index) each_with_index(fruits)
$index. $item
@endcall]]
			local result = luma.render(template, {
				fruits = { "Apple", "Banana", "Cherry" },
			})
			assert.matches("1%. Apple", result)
			assert.matches("2%. Banana", result)
			assert.matches("3%. Cherry", result)
		end)

		it("should be useful for layout wrappers", function()
			local template = [[
{% macro page(title) %}
<!DOCTYPE html>
<html>
<head><title>{{ title }}</title></head>
<body>
{{ caller() }}
</body>
</html>
{% endmacro %}

{% call page("My Page") %}
<h1>Welcome</h1>
<p>Page content here</p>
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("<title>My Page</title>", result)
			assert.matches("<h1>Welcome</h1>", result)
		end)
	end)

	describe("edge cases", function()
		it("should handle empty caller body", function()
			local template = [[
{% macro wrapper() %}
Before {{ caller() }} After
{% endmacro %}

{% call wrapper() %}
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			assert.matches("Before%s+After", result)
		end)

		it("should handle caller not being called", function()
			local template = [[
@macro no_call()
This macro doesn't call the caller
@end

@call no_call()
This won't be rendered
@endcall]]
			local result = luma.render(template, {})
			assert.matches("This macro doesn't call the caller", result)
			assert.not_matches("This won't be rendered", result)
		end)

		it("should handle multiple caller invocations", function()
			local template = [[
{% macro repeat() %}
{{ caller() }}
{{ caller() }}
{{ caller() }}
{% endmacro %}

{% call repeat() %}
Hello!
{% endcall %}]]
			local result = luma.render(template, {}, { syntax = "jinja" })
			-- Should see Hello! three times
			local _, count = result:gsub("Hello!", "")
			assert.equals(3, count)
		end)

	it("should work with filters in caller", function()
		local template = [[
@macro wrap()
[
@call caller()
]
@end

@call wrap()
${"hello" | upper}
@endcall]]
		local result = luma.render(template, {})
		assert.matches("%[%s*HELLO%s*%]", result)
	end)
	end)

	describe("Jinja2 compatibility", function()
		it("should match Jinja2 call pattern", function()
			local template = [[
{% macro render_dialog(title, class="") %}
<div class="dialog {{ class }}">
  <h2>{{ title }}</h2>
  <div class="contents">
    {{ caller() }}
  </div>
</div>
{% endmacro %}

{% call render_dialog("Welcome") %}
  <p>This is a dialog box</p>
{% endcall %}]]
		local result = luma.render(template, {}, { syntax = "jinja" })
		-- Allow optional whitespace when default parameter is empty string
		assert.matches('<div class="dialog%s*">', result)
		assert.matches("<h2>Welcome</h2>", result)
		assert.matches("<p>This is a dialog box</p>", result)
		end)

		it("should match Jinja2 caller with arguments", function()
			local template = [[
{% macro dump_users(users) %}
<ul>
{% for user in users %}
  <li>{{ caller(user) }}</li>
{% endfor %}
</ul>
{% endmacro %}

{% call(user) dump_users(users) %}
  {{ user.username|e }} ({{ user.email }})
{% endcall %}]]
			local result = luma.render(template, {
				users = {
					{ username = "alice", email = "alice@example.com" },
					{ username = "bob", email = "bob@example.com" },
				},
			}, { syntax = "jinja" })
			assert.matches("alice.*alice@example%.com", result)
			assert.matches("bob.*bob@example%.com", result)
		end)
	end)
end)
