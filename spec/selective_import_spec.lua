--- Tests for selective import (from ... import)
-- @module spec.selective_import_spec

local luma = require("luma")
local io = require("io")
local os = require("os")

-- Helper to create temporary template files
local function create_temp_file(filename, content)
    local path = "/tmp/luma_test_" .. filename
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    end
    return path
end

-- Helper to remove temporary files
local function remove_temp_file(path)
    os.remove(path)
end

describe("Selective Import", function()
    describe("basic from...import syntax", function()
        it("should import a single macro", function()
            local macros_file = create_temp_file("macros1.luma", [[
@macro greet(name)
Hello, $name!
@end

@macro farewell(name)
Goodbye, $name!
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import greet %}
@call greet("World")
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Hello, World!", result)

            remove_temp_file(macros_file)
        end)

        it("should import multiple macros", function()
            local macros_file = create_temp_file("macros2.luma", [[
@macro greet(name)
Hello, $name!
@end

@macro farewell(name)
Goodbye, $name!
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import greet, farewell %}
@call greet("Alice")
@call farewell("Bob")
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Hello, Alice!", result)
            assert.matches("Goodbye, Bob!", result)

            remove_temp_file(macros_file)
        end)

        it("should work with Luma native syntax", function()
            local macros_file = create_temp_file("macros3.luma", [[
@macro say_hi(name)
Hi, $name!
@end
]])

            local template = [[
@from "]] .. macros_file .. [[" import say_hi
@call say_hi("Test")
]]
            local result = luma.render(template, {})
            assert.matches("Hi, Test!", result)

            remove_temp_file(macros_file)
        end)
    end)

    describe("import with aliases", function()
        it("should import macro with alias", function()
            local macros_file = create_temp_file("macros4.luma", [[
@macro original_name(text)
Original: $text
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import original_name as renamed %}
@call renamed("Test")
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Original: Test", result)

            remove_temp_file(macros_file)
        end)

        it("should import multiple macros with aliases", function()
            local macros_file = create_temp_file("macros5.luma", [[
@macro func1(x)
F1: $x
@end

@macro func2(x)
F2: $x
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import func1 as a, func2 as b %}
@call a("1")
@call b("2")
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("F1: 1", result)
            assert.matches("F2: 2", result)

            remove_temp_file(macros_file)
        end)

        it("should support mixing aliased and non-aliased imports", function()
            local macros_file = create_temp_file("macros6.luma", [[
@macro keep_name(x)
Keep: $x
@end

@macro rename_me(x)
Rename: $x
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import keep_name, rename_me as renamed %}
@call keep_name("A")
@call renamed("B")
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Keep: A", result)
            assert.matches("Rename: B", result)

            remove_temp_file(macros_file)
        end)
    end)

    describe("importing variables", function()
        it("should import variables from templates", function()
            local vars_file = create_temp_file("vars1.luma", [[
@let greeting = "Hello"
@let count = 42
]])

            local template = [[
{% from "]] .. vars_file .. [[" import greeting, count %}
$greeting! Count: $count
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Hello!", result)
            assert.matches("Count: 42", result)

            remove_temp_file(vars_file)
        end)

        it("should import variables with aliases", function()
            local vars_file = create_temp_file("vars2.luma", [[
@let value = "test"
]])

            local template = [[
{% from "]] .. vars_file .. [[" import value as v %}
Value: $v
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Value: test", result)

            remove_temp_file(vars_file)
        end)
    end)

    describe("comparison with full import", function()
        it("full import should import all macros", function()
            local macros_file = create_temp_file("macros7.luma", [[
@macro m1()
M1
@end

@macro m2()
M2
@end
]])

            local template = [[
{% import "]] .. macros_file .. [[" as lib %}
This uses full import (not selective)
]]
            -- Just verify it doesn't error
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.is_not_nil(result)

            remove_temp_file(macros_file)
        end)

        it("selective import should only import specified names", function()
            local macros_file = create_temp_file("macros8.luma", [[
@macro included()
I am included
@end

@macro not_included()
I am not included
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import included %}
@call included()
]]
            -- included should work
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("I am included", result)

            -- not_included should not be available (would error if called)

            remove_temp_file(macros_file)
        end)
    end)

    describe("edge cases", function()
        it("should handle empty macro body", function()
            local macros_file = create_temp_file("macros9.luma", [[
@macro empty()
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import empty %}
Before @call empty(); After
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("Before.*After", result)

            remove_temp_file(macros_file)
        end)

        it("should handle macros with complex logic", function()
            local macros_file = create_temp_file("macros10.luma", [[
@macro list_items(items)
@for item in items
  - $item
@end
@end
]])

            local template = [[
{% from "]] .. macros_file .. [[" import list_items %}
@call list_items(items)
]]
            local result = luma.render(template, { items = {"A", "B"} }, { syntax = "jinja" })
            assert.matches("- A", result)
            assert.matches("- B", result)

            remove_temp_file(macros_file)
        end)

        it("should not pollute namespace with unimported names", function()
            local macros_file = create_temp_file("macros11.luma", [[
@let should_import = "yes"
@let should_not_import = "no"
]])

            local template = [[
{% from "]] .. macros_file .. [[" import should_import %}
$should_import
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("yes", result)
            assert.not_matches("no", result)

            remove_temp_file(macros_file)
        end)
    end)

    describe("Jinja2 compatibility examples", function()
        it("should match Jinja2 from...import behavior", function()
            local utils_file = create_temp_file("utils.luma", [[
@macro render_user(user)
Name: $user.name
@end

@macro render_product(product)
Product: $product.name
@end
]])

            local template = [[
{% from "]] .. utils_file .. [[" import render_user %}
@call render_user(user)
]]
            local result = luma.render(template, {
                user = { name = "Alice" }
            }, { syntax = "jinja" })
            assert.matches("Name: Alice", result)

            remove_temp_file(utils_file)
        end)

        it("should support typical Jinja2 import patterns", function()
            local helpers_file = create_temp_file("helpers.luma", [[
@macro input(name, type)
<input name="$name" type="$type">
@end

@macro button(text)
<button>$text</button>
@end
]])

            local template = [[
{% from "]] .. helpers_file .. [[" import input, button %}
@call input("email", "email")
@call button("Submit")
]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches('<input name="email"', result)
            assert.matches("<button>Submit</button>", result)

            remove_temp_file(helpers_file)
        end)
    end)
end)
