--- Tests for additional test expressions (sameas, escaped, in)
-- @module spec.additional_tests_spec

local luma = require("luma")

describe("Additional Test Expressions", function()
    describe("sameas test", function()
        it("should return true for identical references", function()
            local template = [[
@let obj = items
@if obj is sameas(items)
Same
@else
Different
@end]]
            local items = {1, 2, 3}
            local result = luma.render(template, { items = items })
            assert.matches("Same", result)
        end)

        it("should return false for equal but different objects", function()
            local template = [[
{% if list1 is sameas(list2) %}Same{% else %}Different{% endif %}]]
            local result = luma.render(template, {
                list1 = {1, 2, 3},
                list2 = {1, 2, 3}
            }, { syntax = "jinja" })
            assert.matches("Different", result)
        end)

        it("should work with primitive values", function()
            local template = [[
{% if x is sameas(y) %}Same{% else %}Different{% endif %}]]
            local result = luma.render(template, { x = 5, y = 5 }, { syntax = "jinja" })
            assert.matches("Same", result)
        end)

        it("should work with strings", function()
            local template = [[
@if name is sameas(other)
Same
@else
Different
@end]]
            local result = luma.render(template, { name = "test", other = "test" })
            assert.matches("Same", result)
        end)
    end)

    describe("escaped test", function()
        it("should return false for normal values", function()
            local template = [[
{% if text is escaped %}Escaped{% else %}Not Escaped{% endif %}]]
            local result = luma.render(template, { text = "<div>" }, { syntax = "jinja" })
            assert.matches("Not Escaped", result)
        end)

        it("should return true for safe values", function()
            -- Register a filter that returns safe values
            luma.register_filter("make_safe", function(v)
                local runtime = require("luma.runtime")
                return runtime.safe(v)
            end)
            
            local template = [[
@let safe_text = text | make_safe
@if safe_text is escaped
Escaped
@else
Not Escaped
@end]]
            local result = luma.render(template, { text = "<div>" })
            assert.matches("Escaped", result)
        end)

        it("should work with safe filter output", function()
            local template = [[
{% set safe_html = html | safe %}
{% if safe_html is escaped %}Safe{% else %}Unsafe{% endif %}]]
            local result = luma.render(template, { html = "<b>test</b>" }, { syntax = "jinja" })
            assert.matches("Safe", result)
        end)

        it("should return false for regular strings", function()
            local template = [[
@if name is escaped
Yes
@else
No
@end]]
            local result = luma.render(template, { name = "Alice" })
            assert.matches("No", result)
        end)
    end)

    describe("in test", function()
        it("should check if value is in array", function()
            local template = [[
{% if 2 is in(numbers) %}Found{% else %}Not Found{% endif %}]]
            local result = luma.render(template, { numbers = {1, 2, 3} }, { syntax = "jinja" })
            assert.matches("Found", result)
        end)

        it("should check if value is not in array", function()
            local template = [[
{% if 5 is in(numbers) %}Found{% else %}Not Found{% endif %}]]
            local result = luma.render(template, { numbers = {1, 2, 3} }, { syntax = "jinja" })
            assert.matches("Not Found", result)
        end)

        it("should check if key is in table", function()
            local template = [[
@if "name" is in(user)
Found
@else
Not Found
@end]]
            local result = luma.render(template, { user = { name = "Alice", age = 30 } })
            assert.matches("Found", result)
        end)

        it("should check if substring is in string", function()
            local template = [[
{% if "world" is in(text) %}Found{% else %}Not Found{% endif %}]]
            local result = luma.render(template, { text = "hello world" }, { syntax = "jinja" })
            assert.matches("Found", result)
        end)

        it("should work with is not in", function()
            local template = [[
{% if 5 is not in(numbers) %}Not Found{% else %}Found{% endif %}]]
            local result = luma.render(template, { numbers = {1, 2, 3} }, { syntax = "jinja" })
            assert.matches("Not Found", result)
        end)

        it("should distinguish from in operator", function()
            -- The 'in' operator is: value in container
            -- The 'in' test is: value is in(container)
            local template = [[
@if 2 in numbers
Operator: Yes
@else
Operator: No
@end
@if 2 is in(numbers)
Test: Yes
@else
Test: No
@end]]
            local result = luma.render(template, { numbers = {1, 2, 3} })
            assert.matches("Operator: Yes", result)
            assert.matches("Test: Yes", result)
        end)
    end)

    describe("combined with other tests", function()
        it("should work with negation", function()
            local template = [[
{% if x is not sameas(y) %}Different{% endif %}]]
            local result = luma.render(template, {
                x = {1},
                y = {1}
            }, { syntax = "jinja" })
            assert.matches("Different", result)
        end)

        it("should work in complex conditions", function()
            local template = [[
{% if (value is in(list)) and (value is number) %}Valid{% endif %}]]
            local result = luma.render(template, {
                value = 42,
                list = {40, 41, 42, 43}
            }, { syntax = "jinja" })
            assert.matches("Valid", result)
        end)

        it("should work with filters", function()
            local template = [[
{% if text | upper is in(items) %}Found{% endif %}]]
            local result = luma.render(template, {
                text = "hello",
                items = {"HELLO", "WORLD"}
            }, { syntax = "jinja" })
            assert.matches("Found", result)
        end)
    end)

    describe("edge cases", function()
        it("sameas with nil values", function()
            local template = [[
@if x is sameas(y)
Same
@else
Different
@end]]
            local result = luma.render(template, { x = nil, y = nil })
            assert.matches("Same", result)
        end)

        it("in test with empty container", function()
            local template = [[
{% if 1 is in(empty) %}Found{% else %}Not Found{% endif %}]]
            local result = luma.render(template, { empty = {} }, { syntax = "jinja" })
            assert.matches("Not Found", result)
        end)

        it("in test with nil container", function()
            local template = [[
{% if 1 is in(nothing) %}Found{% else %}Not Found{% endif %}]]
            local result = luma.render(template, { nothing = nil }, { syntax = "jinja" })
            assert.matches("Not Found", result)
        end)

        it("escaped test with numbers", function()
            local template = [[
{% if 42 is escaped %}Escaped{% else %}Not Escaped{% endif %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Not Escaped", result)
        end)
    end)

    describe("Jinja2 compatibility examples", function()
        it("should match Jinja2 sameas behavior", function()
            local template = [[
{% set x = [1, 2] %}
{% set y = x %}
{% set z = [1, 2] %}
x sameas y: {% if x is sameas(y) %}yes{% else %}no{% endif %}
x sameas z: {% if x is sameas(z) %}yes{% else %}no{% endif %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("x sameas y: yes", result)
            assert.matches("x sameas z: no", result)
        end)

        it("should match Jinja2 in test behavior", function()
            local template = [[
{% if 'o' is in('foo') %}yes{% endif %}
{% if 'x' is in('foo') %}yes{% else %}no{% endif %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("yes", result)
            assert.matches("no", result)
        end)
    end)
end)

