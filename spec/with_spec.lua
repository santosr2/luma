--- Tests for with directive
-- @module spec.with_spec

local luma = require("luma")

describe("With Directive", function()
    describe("basic with functionality", function()
        it("should create scoped variable", function()
            local template = [[
{% with foo = 42 %}
{{ foo }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.equals("42", result:match("^%s*(.-)%s*$"))
        end)

        it("should not leak variable outside scope", function()
            local template = [[
{% with temp = "inside" %}
Inside: {{ temp }}
{% endwith %}
Outside: {{ temp }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Inside: inside", result)
            assert.matches("Outside:%s*$", result)
        end)

        it("should work with Luma native syntax", function()
            local template = [[
@with count = 10
Count: $count
@endwith]]
            local result = luma.render(template, {})
            assert.matches("Count: 10", result)
        end)
    end)

    describe("multiple variables", function()
        it("should support multiple variable assignments", function()
            local template = [[
{% with x = 1, y = 2, z = 3 %}
{{ x }}, {{ y }}, {{ z }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("1, 2, 3", result)
        end)

        it("should support expressions in assignments", function()
            local template = [[
{% with total = price * quantity, tax = total * 0.1 %}
Total: {{ total }}, Tax: {{ tax }}
{% endwith %}]]
            local result = luma.render(template, {
                price = 100,
                quantity = 2
            }, { syntax = "jinja" })
            assert.matches("Total: 200", result)
            assert.matches("Tax: 20", result)
        end)

        it("should support complex expressions", function()
            local template = [[
@with fullname = first .. " " .. last, greeting = "Hello, " .. fullname
$greeting
@endwith]]
            local result = luma.render(template, {
                first = "John",
                last = "Doe"
            })
            assert.matches("Hello, John Doe", result)
        end)
    end)

    describe("reading outer context", function()
        it("should allow reading outer variables", function()
            local template = [[
{% set outer = "outer value" %}
{% with inner = "inner value" %}
Outer: {{ outer }}
Inner: {{ inner }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Outer: outer value", result)
            assert.matches("Inner: inner value", result)
        end)

        it("should allow using outer variables in assignments", function()
            local template = [[
{% set x = 10 %}
{% with y = x * 2 %}
Y = {{ y }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Y = 20", result)
        end)

        it("should shadow outer variables", function()
            local template = [[
{% set name = "outer" %}
Outer: {{ name }}
{% with name = "inner" %}
With: {{ name }}
{% endwith %}
After: {{ name }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Outer: outer", result)
            assert.matches("With: inner", result)
            assert.matches("After: outer", result)
        end)
    end)

    describe("empty with block", function()
        it("should support with without assignments", function()
            local template = [[
{% set x = "original" %}
{% with %}
{% set x = "modified" %}
Inside: {{ x }}
{% endwith %}
Outside: {{ x }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Inside: modified", result)
            assert.matches("Outside: original", result)
        end)

        it("should create isolated scope even without assignments", function()
            local template = [[
@with
@let temp = "temporary"
$temp
@endwith
After: $temp]]
            local result = luma.render(template, {})
            assert.matches("temporary", result)
            assert.matches("After:%s*$", result)
        end)
    end)

    describe("nested with blocks", function()
        it("should handle nested with blocks", function()
            local template = [[
{% with x = 1 %}
L1: {{ x }}
{% with x = 2 %}
L2: {{ x }}
{% with x = 3 %}
L3: {{ x }}
{% endwith %}
Back L2: {{ x }}
{% endwith %}
Back L1: {{ x }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("L1: 1", result)
            assert.matches("L2: 2", result)
            assert.matches("L3: 3", result)
            assert.matches("Back L2: 2", result)
            assert.matches("Back L1: 1", result)
        end)

        it("should handle multiple variables in nested blocks", function()
            local template = [[
@with a = 1, b = 2
@with c = a + b, d = c * 2
Result: $d
@endwith
$a, $b
@endwith]]
            local result = luma.render(template, {})
            assert.matches("Result: 6", result)
            assert.matches("1, 2", result)
        end)
    end)

    describe("with control structures", function()
        it("should work with loops inside with", function()
            local template = [[
{% with items = [1, 2, 3] %}
{% for item in items %}
{{ item }}
{% endfor %}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("1", result)
            assert.matches("2", result)
            assert.matches("3", result)
        end)

        it("should work with conditionals inside with", function()
            local template = [[
@with value = 42
@if value > 40
Large: $value
@else
Small: $value
@end
@endwith]]
            local result = luma.render(template, {})
            assert.matches("Large: 42", result)
        end)

        it("should allow modifications inside with", function()
            local template = [[
{% with counter = 0 %}
{% for i in [1, 2, 3] %}
{% set counter = counter + i %}
{% endfor %}
Total: {{ counter }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Total: 6", result)
        end)
    end)

    describe("with filters and expressions", function()
        it("should support filters in assignments", function()
            local template = [[
{% with upper_name = name | upper %}
{{ upper_name }}
{% endwith %}]]
            local result = luma.render(template, { name = "alice" }, { syntax = "jinja" })
            assert.matches("ALICE", result)
        end)

        it("should support complex expressions", function()
            local template = [[
@with result = (a + b) * c, final = result / 2
Final: $final
@endwith]]
            local result = luma.render(template, {
                a = 10,
                b = 5,
                c = 4
            })
            assert.matches("Final: 30", result)
        end)

        it("should support table/array literals", function()
            local template = [[
{% with data = {"key": "value"}, list = [1, 2, 3] %}
Data: {{ data.key }}
First: {{ list[1] }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Data: value", result)
            assert.matches("First: 1", result)
        end)
    end)

    describe("practical use cases", function()
        it("should be useful for temporary calculations", function()
            local template = [[
{% with 
    subtotal = price * quantity,
    tax = subtotal * tax_rate,
    total = subtotal + tax
%}
Subtotal: ${{ subtotal }}
Tax: ${{ tax }}
Total: ${{ total }}
{% endwith %}]]
            local result = luma.render(template, {
                price = 100,
                quantity = 2,
                tax_rate = 0.1
            }, { syntax = "jinja" })
            assert.matches("Subtotal: %$200", result)
            assert.matches("Tax: %$20", result)
            assert.matches("Total: %$220", result)
        end)

        it("should be useful for API response formatting", function()
            local template = [[
@with 
    status = response.success and "Success" or "Failed",
    code = response.code,
    message = response.message
Status: $status ($code)
Message: $message
@endwith]]
            local result = luma.render(template, {
                response = {
                    success = true,
                    code = 200,
                    message = "OK"
                }
            })
            assert.matches("Status: Success %(200%)", result)
            assert.matches("Message: OK", result)
        end)
    end)

    describe("edge cases", function()
        it("should handle empty body", function()
            local template = [[
{% with x = 42 %}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.is_not_nil(result)
        end)

        it("should handle nil values", function()
            local template = [[
{% with x = none %}
Value: {{ x }}
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Value:%s*$", result)
        end)

        it("should work with template inheritance", function()
            local template = [[
{% block content %}
{% with page_var = "test" %}
{{ page_var }}
{% endwith %}
{% endblock %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("test", result)
        end)
    end)

    describe("Jinja2 compatibility", function()
        it("should match Jinja2 with behavior", function()
            local template = [[
{% with greeting = "Hello" %}
{{ greeting }}, World!
{% endwith %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Hello, World!", result)
        end)

        it("should match Jinja2 empty with behavior", function()
            local template = [[
{% set global = "global" %}
{% with %}
{% set local = "local" %}
Global: {{ global }}
Local: {{ local }}
{% endwith %}
After: {{ local }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Global: global", result)
            assert.matches("Local: local", result)
            assert.matches("After:%s*$", result)
        end)
    end)
end)

