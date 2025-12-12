--- Tests for set block syntax
-- @module spec.set_block_spec

local luma = require("luma")

describe("Set Block Syntax", function()
    describe("basic block syntax", function()
        it("should capture simple text content", function()
            local template = [[
{% set greeting %}Hello, World!{% endset %}
$greeting]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.equals("Hello, World!", result:match("^%s*(.-)%s*$"))
        end)

        it("should capture multiline content", function()
            local template = [[
{% set message %}
Line 1
Line 2
Line 3
{% endset %}
$message]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Line 1", result)
            assert.matches("Line 2", result)
            assert.matches("Line 3", result)
        end)

        it("should work with Luma native syntax", function()
            local template = [[
@set greeting
Hello from Luma!
@endset
$greeting]]
            local result = luma.render(template, {})
            assert.matches("Hello from Luma!", result)
        end)
    end)

    describe("with variables", function()
        it("should capture interpolated variables", function()
            local template = [[
{% set fullname %}{{ first }} {{ last }}{% endset %}
Name: $fullname]]
            local result = luma.render(template, { first = "John", last = "Doe" }, { syntax = "jinja" })
            assert.matches("Name: John Doe", result)
        end)

        it("should support expressions in block", function()
            local template = [[
{% set calculation %}2 + 2 = {{ 2 + 2 }}{% endset %}
$calculation]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("2 %+ 2 = 4", result)
        end)

        it("should support filters in block", function()
            local template = [[
{% set upper_text %}{{ name | upper }}{% endset %}
$upper_text]]
            local result = luma.render(template, { name = "alice" }, { syntax = "jinja" })
            assert.matches("ALICE", result)
        end)
    end)

    describe("with control structures", function()
        it("should capture conditional content", function()
            local template = [[
{% set status %}
{%- if active -%}
Active
{%- else -%}
Inactive
{%- endif -%}
{% endset %}
Status: $status]]
            local result = luma.render(template, { active = true }, { syntax = "jinja" })
            assert.matches("Status:%s*Active", result)
        end)

        it("should capture loop output", function()
            local template = [[
{% set list %}
{%- for item in items -%}
{{ item }}
{%- endfor -%}
{% endset %}
$list]]
            local result = luma.render(template, { items = {"A", "B", "C"} }, { syntax = "jinja" })
            assert.matches("A", result)
            assert.matches("B", result)
            assert.matches("C", result)
        end)

        it("should support nested blocks in Luma syntax", function()
            local template = [[
@set items_list
@for item in items
  - $item
@end
@endset
$items_list]]
            local result = luma.render(template, { items = {"apple", "banana"} })
            assert.matches("apple", result)
            assert.matches("banana", result)
        end)
    end)

    describe("complex scenarios", function()
        it("should support nested set blocks", function()
            local template = [[
{% set outer %}
{% set inner %}Inner{% endset %}
Outer: {{ inner }}
{% endset %}
$outer]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Outer: Inner", result)
        end)

        it("should work with HTML/YAML content", function()
            local template = [[
@set config
server:
  host: $host
  port: $port
@endset
$config]]
            local result = luma.render(template, { host = "localhost", port = 8080 })
            assert.matches("server:", result)
            assert.matches("host: localhost", result)
            assert.matches("port: 8080", result)
        end)

        it("should preserve whitespace correctly", function()
            local template = [[
{% set indented %}
  Line 1
  Line 2
{% endset %}
$indented]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            -- Check that indentation is preserved
            assert.matches("  Line 1", result)
            assert.matches("  Line 2", result)
        end)

        it("should work with macro calls in block", function()
            local template = [[
@macro greet(name)
Hello, $name!
@end

@set greeting
@call greet("World")
@endset
$greeting]]
            local result = luma.render(template, {})
            assert.matches("Hello, World!", result)
        end)
    end)

    describe("use in control flow", function()
        it("should be usable in conditionals", function()
            local template = [[
{% set value %}test{% endset %}
{% if value == "test" %}Success{% endif %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Success", result)
        end)

        it("should be usable in loops", function()
            local template = [[
{% set prefix %}Item: {% endset %}
{% for i in items %}{{ prefix }}{{ i }}
{% endfor %}]]
            local result = luma.render(template, { items = {1, 2} }, { syntax = "jinja" })
            assert.matches("Item: 1", result)
            assert.matches("Item: 2", result)
        end)
    end)

    describe("edge cases", function()
        it("should handle empty block", function()
            local template = [[
{% set empty %}{% endset %}
Value: "$empty"]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches('Value: ""', result)
        end)

        it("should handle block with only whitespace", function()
            local template = [[
{% set spaces %}   {% endset %}
Length: ${#spaces}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Length: 3", result)
        end)

        it("should override previous variable", function()
            local template = [[
{% set x = "first" %}
{% set x %}second{% endset %}
$x]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("second", result)
        end)

        it("should work with safe/unsafe content", function()
            local template = [[
{% set html %}<div>Test</div>{% endset %}
$html]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            -- HTML should be escaped by default
            assert.matches("&lt;div&gt;", result)
        end)
    end)

    describe("comparison with assignment syntax", function()
        it("should work alongside assignment syntax", function()
            local template = [[
{% set a = "assigned" %}
{% set b %}captured{% endset %}
A: $a, B: $b]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("A: assigned", result)
            assert.matches("B: captured", result)
        end)

        it("assignment should work with expressions", function()
            local template = [[
{% set x = 10 * 2 %}
{% set y %}{{ 10 * 2 }}{% endset %}
X: $x, Y: $y]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("X: 20", result)
            assert.matches("Y: 20", result)
        end)
    end)
end)

