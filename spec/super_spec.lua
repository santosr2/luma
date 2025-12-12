--- Tests for super() function in template inheritance
-- @module spec.super_spec

local luma = require("luma")
local runtime = require("luma.runtime")

describe("super() Function", function()
    local templates = {}

    setup(function()
        runtime.set_loader(function(name)
            return templates[name]
        end)
    end)

    teardown(function()
        runtime.set_loader(nil)
    end)

    before_each(function()
        templates = {}
    end)

    describe("basic super() usage", function()
        it("should call parent block content", function()
            templates["base.html"] = [[
@block content
Parent content
@end]]
            local child = [[@extends "base.html"
@block content
Before
${super()}
After
@end]]
            local result = luma.render(child, {})
            assert.match("Before", result)
            assert.match("Parent content", result)
            assert.match("After", result)
        end)

        it("should return empty string when no parent block", function()
            local template = [[
@block content
${super()}
Child only
@end]]
            local result = luma.render(template, {})
            assert.equals("\n\nChild only\n", result)
        end)

        it("should work with interpolation in parent block", function()
            templates["base.html"] = [[
@block greeting
Hello $name
@end]]
            local child = [[@extends "base.html"
@block greeting
${super()} from child!
@end]]
            local result = luma.render(child, { name = "World" })
            assert.match("Hello World", result)
            assert.match("from child!", result)
        end)

        it("should work multiple times in same block", function()
            templates["base.html"] = [[
@block content
[Parent]
@end]]
            local child = [[@extends "base.html"
@block content
Start ${super()} Middle ${super()} End
@end]]
            local result = luma.render(child, {})
            assert.match("Start %[Parent%] Middle %[Parent%] End", result)
        end)
    end)

    describe("super() with nested blocks", function()
        it("should work in nested inheritance (3 levels)", function()
            templates["grandparent.html"] = [[
@block content
Grandparent
@end]]
            templates["parent.html"] = [[@extends "grandparent.html"
@block content
Parent (${super()})
@end]]
            local child = [[@extends "parent.html"
@block content
Child (${super()})
@end]]
            local result = luma.render(child, {})
            assert.match("Child", result)
            assert.match("Parent", result)
            assert.match("Grandparent", result)
        end)

        it("should only access immediate parent block", function()
            templates["grandparent.html"] = [[
@block content
GP
@end]]
            templates["parent.html"] = [[@extends "grandparent.html"
@block content
P
@end]]
            local child = [[@extends "parent.html"
@block content
${super()}
@end]]
            local result = luma.render(child, {})
            assert.match("P", result)
            assert.is_not.match("GP", result)
        end)
    end)

    describe("super() with directives in parent block", function()
        it("should execute parent block directives", function()
            templates["base.html"] = [[
@block items
@for item in items
- $item
@end
@end]]
            local child = [[@extends "base.html"
@block items
=== Items ===
${super()}
=== End ===
@end]]
            local result = luma.render(child, { items = { "a", "b", "c" } })
            assert.match("=== Items ===", result)
            assert.match("- a", result)
            assert.match("- b", result)
            assert.match("- c", result)
            assert.match("=== End ===", result)
        end)

        it("should apply filters in parent block", function()
            templates["base.html"] = [[
@block title
${title | upper}
@end]]
            local child = [[@extends "base.html"
@block title
Prefix: ${super()}
@end]]
            local result = luma.render(child, { title = "hello" })
            assert.match("Prefix:", result)
            assert.match("HELLO", result)
        end)
    end)

    describe("super() in Jinja2 syntax", function()
        it("should work with Jinja2 block syntax", function()
            templates["base.html"] = [[
{% block content %}
Parent content
{% endblock %}]]
            local child = [[{% extends "base.html" %}
{% block content %}
{{ super() }}
Child content
{% endblock %}]]
            local result = luma.render(child, {}, { syntax = "jinja" })
            assert.match("Parent content", result)
            assert.match("Child content", result)
        end)
    end)

    describe("edge cases", function()
        it("should handle empty parent block", function()
            templates["base.html"] = [[
@block content
@end]]
            local child = [[@extends "base.html"
@block content
${super()}Child
@end]]
            local result = luma.render(child, {})
            assert.match("Child", result)
        end)

        it("should work when parent block has only whitespace", function()
            templates["base.html"] = [[
@block content
  
@end]]
            local child = [[@extends "base.html"
@block content
[${super()}]
@end]]
            local result = luma.render(child, {})
            assert.match("%[.*%]", result)
        end)

        it("should not interfere with variables named super", function()
            local template = [[
@let super = "not a function"
$super
]]
            local result = luma.render(template, {})
            assert.match("not a function", result)
        end)
    end)
end)

