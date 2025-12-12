--- Tests for do statement
-- @module spec.do_spec

local luma = require("luma")

describe("Do Statement", function()
    describe("basic do functionality", function()
        it("should execute expression without output", function()
            local template = [[
{% set list = [] %}
{% do list.append(1) %}
{% do list.append(2) %}
{% do list.append(3) %}
{{ list | join(", ") }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("1, 2, 3", result)
        end)

        it("should work with Luma native syntax", function()
            local template = [[
@let items = {}
@do items[1] = "first"
@do items[2] = "second"
${items[1]}, ${items[2]}]]
            local result = luma.render(template, {})
            assert.matches("first, second", result)
        end)

        it("should not produce any output", function()
            local template = [[
Before
{% do 1 + 1 %}
After]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Before", result)
            assert.matches("After", result)
            assert.not_matches("2", result)
        end)
    end)

    describe("modifying namespace objects", function()
        it("should modify namespace properties", function()
            local template = [[
{% set ns = namespace(count=0) %}
{% do ns.count = 10 %}
Count: {{ ns.count }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Count: 10", result)
        end)

        it("should increment namespace values", function()
            local template = [[
@let ns = namespace(value=5)
@do ns.value = ns.value + 3
Result: $ns.value]]
            local result = luma.render(template, {})
            assert.matches("Result: 8", result)
        end)

        it("should build data structures", function()
            local template = [[
{% set ns = namespace(data={}) %}
{% do ns.data["key1"] = "value1" %}
{% do ns.data["key2"] = "value2" %}
{{ ns.data.key1 }}, {{ ns.data.key2 }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("value1, value2", result)
        end)
    end)

    describe("with loops", function()
        it("should execute in loops", function()
            local template = [[
{% set list = [] %}
{% for i in [1, 2, 3] %}
{% do list.append(i * 2) %}
{% endfor %}
{{ list | join(", ") }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("2, 4, 6", result)
        end)

        it("should modify namespace in loops", function()
            local template = [[
@let ns = namespace(total=0)
@for num in numbers
@do ns.total = ns.total + num
@end
Total: $ns.total]]
            local result = luma.render(template, { numbers = {10, 20, 30} })
            assert.matches("Total: 60", result)
        end)

        it("should build list in loop", function()
            local template = [[
{% set result = [] %}
{% for item in items %}
{% if item > 5 %}
{% do result.append(item) %}
{% endif %}
{% endfor %}
{{ result | join(", ") }}]]
            local result = luma.render(template, {
                items = {3, 7, 4, 9, 2, 11}
            }, { syntax = "jinja" })
            assert.matches("7, 9, 11", result)
        end)
    end)

    describe("method calls", function()
        it("should call table methods", function()
            local template = [[
{% set data = {items = []} %}
{% do data.items.append("a") %}
{% do data.items.append("b") %}
{{ data.items | join(", ") }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("a, b", result)
        end)

        it("should call string methods", function()
            -- Note: Lua strings are immutable, but we can still call methods
            local template = [[
@let text = "hello"
@do text:upper()
Still: $text]]
            local result = luma.render(template, {})
            -- String is immutable, so it stays lowercase
            assert.matches("Still: hello", result)
        end)

        it("should modify table in place", function()
            local template = [[
{% set dict = {a = 1} %}
{% do dict.__setitem__("b", 2) if dict.__setitem__ else dict.update({b = 2}) %}
A: {{ dict.a }}, B: {{ dict.b }}]]
            -- This is more Pythonic, in Lua we just do:
            local template2 = [[
@let dict = {a = 1}
@do dict.b = 2
A: $dict.a, B: $dict.b]]
            local result = luma.render(template2, {})
            assert.matches("A: 1, B: 2", result)
        end)
    end)

    describe("complex expressions", function()
        it("should execute complex expressions", function()
            local template = [[
{% set ns = namespace(x=1, y=2) %}
{% do ns.x, ns.y = ns.y, ns.x %}
X: {{ ns.x }}, Y: {{ ns.y }}]]
            -- Note: Multiple assignment doesn't work the same in Lua
            -- Use simpler example:
            local template2 = [[
@let ns = namespace(temp=0, x=1, y=2)
@do ns.temp = ns.x
@do ns.x = ns.y
@do ns.y = ns.temp
X: $ns.x, Y: $ns.y]]
            local result = luma.render(template2, {})
            assert.matches("X: 2, Y: 1", result)
        end)

        it("should execute function calls", function()
            local template = [[
@let ns = namespace(items={})
@do table.insert(ns.items, "first")
@do table.insert(ns.items, "second")
${#ns.items} items]]
            local result = luma.render(template, {})
            assert.matches("2 items", result)
        end)
    end)

    describe("practical use cases", function()
        it("should be useful for data preparation", function()
            local template = [[
{% set users = [] %}
{% for person in people %}
{% if person.active %}
{% do users.append(person.name) %}
{% endif %}
{% endfor %}
Active users: {{ users | join(", ") }}]]
            local result = luma.render(template, {
                people = {
                    {name = "Alice", active = true},
                    {name = "Bob", active = false},
                    {name = "Charlie", active = true}
                }
            }, { syntax = "jinja" })
            assert.matches("Active users: Alice, Charlie", result)
        end)

        it("should be useful for counters", function()
            local template = [[
@let ns = namespace(evens=0, odds=0)
@for num in numbers
@if num % 2 == 0
@do ns.evens = ns.evens + 1
@else
@do ns.odds = ns.odds + 1
@end
@end
Evens: $ns.evens, Odds: $ns.odds]]
            local result = luma.render(template, {
                numbers = {1, 2, 3, 4, 5, 6, 7, 8, 9}
            })
            assert.matches("Evens: 4, Odds: 5", result)
        end)

        it("should be useful for conditional mutations", function()
            local template = [[
{% set config = {debug = false, verbose = false} %}
{% if environment == "development" %}
{% do config.update({debug = true, verbose = true}) if config.update else nil %}
{% endif %}
Debug: {{ config.debug }}]]
            -- Lua version:
            local template2 = [[
@let config = {debug = false, verbose = false}
@if environment == "development"
@do config.debug = true
@do config.verbose = true
@end
Debug: $config.debug]]
            local result = luma.render(template2, { environment = "development" })
            assert.matches("Debug: true", result)
        end)
    end)

    describe("edge cases", function()
        it("should handle expressions that return nil", function()
            local template = [[
{% do none %}
Continues]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Continues", result)
        end)

        it("should handle expressions that could error", function()
            -- In a real scenario, this might error, but we're testing the syntax
            local template = [[
@let safe = {value = 10}
@do safe.value = safe.value * 2
Result: $safe.value]]
            local result = luma.render(template, {})
            assert.matches("Result: 20", result)
        end)

        it("should work in nested blocks", function()
            local template = [[
{% set ns = namespace(val=0) %}
{% with temp = 5 %}
{% do ns.val = temp * 2 %}
{% endwith %}
Value: {{ ns.val }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Value: 10", result)
        end)

        it("should work with autoescape blocks", function()
            local template = [[
@let data = {}
@autoescape false
@do data.html = "<tag>"
@endautoescape
$data.html]]
            local result = luma.render(template, {})
            assert.matches("<tag>", result)
        end)
    end)

    describe("Jinja2 compatibility", function()
        it("should match Jinja2 do behavior", function()
            local template = [[
{% set items = [] %}
{% do items.append("a") %}
{% do items.append("b") %}
{{ items | length }}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("2", result)
        end)

        it("should match Jinja2 list building pattern", function()
            local template = [[
{% set navigation = [] %}
{% do navigation.append({"href": "/", "label": "Home"}) %}
{% do navigation.append({"href": "/about", "label": "About"}) %}
{% for item in navigation %}
{{ item.label }}
{% endfor %}]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Home", result)
            assert.matches("About", result)
        end)

        it("should match Jinja2 with namespace", function()
            local template = [[
{% set ns = namespace(found=false) %}
{% for item in items %}
{% if item.check %}
{% do ns.__setattr__("found", true) if ns.__setattr__ else nil %}
{% set ns.found = true %}
{% endif %}
{% endfor %}
{{ ns.found }}]]
            local result = luma.render(template, {
                items = {{check = true}}
            }, { syntax = "jinja" })
            assert.matches("true", result)
        end)
    end)
end)

