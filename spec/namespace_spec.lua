--- Tests for namespace() function
-- @module spec.namespace_spec

local luma = require("luma")

describe("Namespace Function", function()
    describe("basic namespace functionality", function()
        it("should create mutable namespace object", function()
            local template = [[
{% set ns = namespace(found=false) %}
{{ ns.found }}
{% set ns.found = true %}
{{ ns.found }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("false", result)
            assert.matches("true", result)
        end)

        it("should work with Luma native syntax", function()
            local template = [[
@let ns = namespace(count=0)
Start: $ns.count
@let ns.count = 5
After: $ns.count]]
            local result = luma.render(template, {})
            assert.matches("Start: 0", result)
            assert.matches("After: 5", result)
        end)

        it("should allow modifications in loops", function()
            local template = [[
{% set ns = namespace(total=0) %}
{% for num in numbers %}
{% set ns.total = ns.total + num %}
{% endfor %}
Total: {{ ns.total }}]]
            local result = luma.render(template, {
                numbers = {1, 2, 3, 4, 5}
            }, { syntax = "jinja" })
            assert.matches("Total: 15", result)
        end)
    end)

    describe("initial values", function()
        it("should support multiple initial values", function()
            local template = [[
{% set ns = namespace(x=1, y=2, z=3) %}
{{ ns.x }}, {{ ns.y }}, {{ ns.z }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("1, 2, 3", result)
        end)

        it("should support empty namespace", function()
            local template = [[
{% set ns = namespace() %}
{% set ns.value = 42 %}
{{ ns.value }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("42", result)
        end)

        it("should support complex values", function()
            local template = [[
@let ns = namespace(list={1,2,3}, text="hello")
List: ${#ns.list}
Text: $ns.text]]
            local result = luma.render(template, {})
            assert.matches("List: 3", result)
            assert.matches("Text: hello", result)
        end)
    end)

    describe("use in loops", function()
        it("should maintain state across loop iterations", function()
            local template = [[
{% set ns = namespace(found=false) %}
{% for item in items %}
{% if item.check %}
{% set ns.found = true %}
{% endif %}
{% endfor %}
Found: {{ ns.found }}]]
            local result = luma.render(template, {
                items = {
                    {check = false},
                    {check = false},
                    {check = true},
                }
            }, { syntax = "jinja" })
            assert.matches("Found: true", result)
        end)

        it("should accumulate values in loops", function()
            local template = [[
@let ns = namespace(sum=0, count=0)
@for item in items
@let ns.sum = ns.sum + item
@let ns.count = ns.count + 1
@end
Sum: $ns.sum, Count: $ns.count]]
            local result = luma.render(template, {
                items = {10, 20, 30}
            })
            assert.matches("Sum: 60", result)
            assert.matches("Count: 3", result)
        end)

        it("should work with nested loops", function()
            local template = [[
{% set ns = namespace(total=0) %}
{% for row in matrix %}
{% for cell in row %}
{% set ns.total = ns.total + cell %}
{% endfor %}
{% endfor %}
Total: {{ ns.total }}]]
            local result = luma.render(template, {
                matrix = {
                    {1, 2, 3},
                    {4, 5, 6},
                    {7, 8, 9}
                }
            }, { syntax = "jinja" })
            assert.matches("Total: 45", result)
        end)
    end)

    describe("string concatenation", function()
        it("should build strings across iterations", function()
            local template = [[
{% set ns = namespace(result="") %}
{% for letter in letters %}
{% set ns.result = ns.result .. letter %}
{% endfor %}
{{ ns.result }}]]
            local result = luma.render(template, {
                letters = {"a", "b", "c", "d"}
            }, { syntax = "jinja" })
            assert.matches("abcd", result)
        end)

        it("should build formatted strings", function()
            local template = [[
@let ns = namespace(output="")
@for name in names
@let ns.output = ns.output .. "Hello, " .. name .. "! "
@end
$ns.output]]
            local result = luma.render(template, {
                names = {"Alice", "Bob"}
            })
            assert.matches("Hello, Alice! Hello, Bob!", result)
        end)
    end)

    describe("boolean flags", function()
        it("should track presence of conditions", function()
            local template = [[
{% set ns = namespace(hasError=false, hasWarning=false) %}
{% for msg in messages %}
{% if msg.type == "error" %}
{% set ns.hasError = true %}
{% elif msg.type == "warning" %}
{% set ns.hasWarning = true %}
{% endif %}
{% endfor %}
Has Errors: {{ ns.hasError }}
Has Warnings: {{ ns.hasWarning }}]]
            local result = luma.render(template, {
                messages = {
                    {type = "info"},
                    {type = "warning"},
                    {type = "info"},
                }
            }, { syntax = "jinja" })
            assert.matches("Has Errors: false", result)
            assert.matches("Has Warnings: true", result)
        end)

        it("should track first/last found items", function()
            local template = [[
@let ns = namespace(first=nil, last=nil)
@for item in items
@if item > 10
@if not ns.first
@let ns.first = item
@end
@let ns.last = item
@end
@end
First: $ns.first, Last: $ns.last]]
            local result = luma.render(template, {
                items = {5, 15, 8, 20, 3, 25}
            })
            assert.matches("First: 15", result)
            assert.matches("Last: 25", result)
        end)
    end)

    describe("practical use cases", function()
        it("should generate unique IDs", function()
            local template = [[
{% set ns = namespace(id=0) %}
{% for item in items %}
{% set ns.id = ns.id + 1 %}
<div id="item-{{ ns.id }}">{{ item }}</div>
{% endfor %}]]
            local result = luma.render(template, {
                items = {"Apple", "Banana", "Cherry"}
            }, { syntax = "jinja" })
            assert.matches('id="item%-1"', result)
            assert.matches('id="item%-2"', result)
            assert.matches('id="item%-3"', result)
        end)

        it("should build complex data structures", function()
            local template = [[
@let ns = namespace(users={}, count=0)
@for user in userlist
@if user.active
@let ns.count = ns.count + 1
@end
@end
Active users: $ns.count]]
            local result = luma.render(template, {
                userlist = {
                    {name = "Alice", active = true},
                    {name = "Bob", active = false},
                    {name = "Charlie", active = true},
                }
            })
            assert.matches("Active users: 2", result)
        end)

        it("should track min/max values", function()
            local template = [[
{% set ns = namespace(min=999, max=0) %}
{% for value in values %}
{% if value < ns.min %}
{% set ns.min = value %}
{% endif %}
{% if value > ns.max %}
{% set ns.max = value %}
{% endif %}
{% endfor %}
Min: {{ ns.min }}, Max: {{ ns.max }}]]
            local result = luma.render(template, {
                values = {5, 12, 3, 18, 7}
            }, { syntax = "jinja" })
            assert.matches("Min: 3", result)
            assert.matches("Max: 18", result)
        end)
    end)

    describe("edge cases", function()
        it("should handle nil values", function()
            local template = [[
{% set ns = namespace(value=none) %}
Value: {{ ns.value }}
{% set ns.value = 42 %}
After: {{ ns.value }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Value:%s*$", result:match("Value:[^\n]*"))
            assert.matches("After: 42", result)
        end)

        it("should work with conditionals", function()
            local template = [[
@let ns = namespace(status="unknown")
@if condition
@let ns.status = "yes"
@else
@let ns.status = "no"
@end
Status: $ns.status]]
            local result = luma.render(template, { condition = true })
            assert.matches("Status: yes", result)
        end)

        it("should not leak outside scope in with blocks", function()
            local template = [[
{% with %}
{% set ns = namespace(temp=42) %}
Inside: {{ ns.temp }}
{% endwith %}
Outside: {{ ns }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Inside: 42", result)
            assert.matches("Outside:%s*$", result)
        end)
    end)

    describe("Jinja2 compatibility", function()
        it("should match Jinja2 namespace behavior", function()
            local template = [[
{% set ns = namespace(found=false) %}
{% for item in items %}
{% if item.check %}
{% set ns.found = true %}
{% endif %}
{% endfor %}
{% if ns.found %}
Found!
{% else %}
Not found
{% endif %}]]
            local result = luma.render(template, {
                items = {{check = false}, {check = true}}
            }, { syntax = "jinja" })
            assert.matches("Found!", result)
        end)

        it("should match Jinja2 counter example", function()
            local template = [[
{% set ns = namespace(counter=0) %}
{% for item in items %}
{% set ns.counter = ns.counter + 1 %}
Item {{ ns.counter }}: {{ item }}
{% endfor %}]]
            local result = luma.render(template, {
                items = {"a", "b", "c"}
            }, { syntax = "jinja" })
            assert.matches("Item 1: a", result)
            assert.matches("Item 2: b", result)
            assert.matches("Item 3: c", result)
        end)
    end)
end)

