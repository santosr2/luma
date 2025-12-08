--- Tests for test expressions (is / is not)
-- @module spec.tests_spec

describe("Test Expressions", function()
    local luma = require("luma")

    describe("existence tests", function()
        it("checks if variable is defined", function()
            local result = luma.render("${name is defined}", { name = "Alice" })
            assert.equals("true", result)
        end)

        it("checks if variable is undefined", function()
            local result = luma.render("${missing is undefined}")
            assert.equals("true", result)
        end)

        it("checks if value is none", function()
            local result = luma.render("${value is none}", { value = nil })
            assert.equals("true", result)
        end)

        it("checks if value is not none", function()
            local result = luma.render("${value is not none}", { value = "something" })
            assert.equals("true", result)
        end)
    end)

    describe("type tests", function()
        it("checks if value is string", function()
            local result = luma.render("${value is string}", { value = "hello" })
            assert.equals("true", result)
        end)

        it("checks if value is not string", function()
            local result = luma.render("${value is not string}", { value = 42 })
            assert.equals("true", result)
        end)

        it("checks if value is number", function()
            local result = luma.render("${value is number}", { value = 42 })
            assert.equals("true", result)
        end)

        it("checks if value is boolean", function()
            local result = luma.render("${value is boolean}", { value = true })
            assert.equals("true", result)
        end)

        it("checks if value is table", function()
            local result = luma.render("${value is table}", { value = { 1, 2, 3 } })
            assert.equals("true", result)
        end)

        it("checks if value is callable", function()
            local result = luma.render("${value is callable}", { value = function() end })
            assert.equals("true", result)
        end)
    end)

    describe("numeric tests", function()
        it("checks if number is odd", function()
            local result = luma.render("${value is odd}", { value = 3 })
            assert.equals("true", result)
        end)

        it("checks if number is even", function()
            local result = luma.render("${value is even}", { value = 4 })
            assert.equals("true", result)
        end)

        it("checks if number is divisibleby", function()
            local result = luma.render("${value is divisibleby(3)}", { value = 9 })
            assert.equals("true", result)
        end)

        it("returns false for non-divisible number", function()
            local result = luma.render("${value is divisibleby(3)}", { value = 10 })
            assert.equals("false", result)
        end)

        it("handles zero divisor gracefully", function()
            local result = luma.render("${value is divisibleby(0)}", { value = 10 })
            assert.equals("false", result)
        end)
    end)

    describe("collection tests", function()
        it("checks if value is iterable (array)", function()
            local result = luma.render("${value is iterable}", { value = { 1, 2, 3 } })
            assert.equals("true", result)
        end)

        it("checks if value is iterable (string)", function()
            local result = luma.render("${value is iterable}", { value = "hello" })
            assert.equals("true", result)
        end)

        it("checks if value is sequence", function()
            local result = luma.render("${value is sequence}", { value = { 1, 2, 3 } })
            assert.equals("true", result)
        end)

        it("checks if value is mapping", function()
            local result = luma.render("${value is mapping}", { value = { name = "Alice" } })
            assert.equals("true", result)
        end)

        it("checks if value is empty (empty table)", function()
            local result = luma.render("${value is empty}", { value = {} })
            assert.equals("true", result)
        end)

        it("checks if value is empty (empty string)", function()
            local result = luma.render("${value is empty}", { value = "" })
            assert.equals("true", result)
        end)

        it("checks if value is not empty", function()
            local result = luma.render("${value is not empty}", { value = { 1 } })
            assert.equals("true", result)
        end)
    end)

    describe("value tests", function()
        it("checks if value is true", function()
            local result = luma.render("${value is true}", { value = true })
            assert.equals("true", result)
        end)

        it("checks if value is false", function()
            local result = luma.render("${value is false}", { value = false })
            assert.equals("true", result)
        end)
    end)

    describe("string tests", function()
        it("checks if string is lower", function()
            local result = luma.render("${value is lower}", { value = "hello" })
            assert.equals("true", result)
        end)

        it("checks if string is upper", function()
            local result = luma.render("${value is upper}", { value = "HELLO" })
            assert.equals("true", result)
        end)
    end)

    describe("in conditions", function()
        it("works in @if conditions", function()
            local template = [[
@if value is defined
Has value
@end]]
            local result = luma.render(template, { value = "test" })
            assert.matches("Has value", result)
        end)

        it("works with is not in @if conditions", function()
            local template = [[
@if missing is not defined
Missing
@end]]
            local result = luma.render(template, {})
            assert.matches("Missing", result)
        end)

        it("combines with other conditions", function()
            local template = [[
@if value is defined and value is number
Is a number
@end]]
            local result = luma.render(template, { value = 42 })
            assert.matches("Is a number", result)
        end)
    end)

    describe("complex expressions", function()
        it("works with member access", function()
            local result = luma.render("${user.name is defined}", { user = { name = "Alice" } })
            assert.equals("true", result)
        end)

        it("works with nested tests", function()
            local template = [[
@if items is iterable and items is not empty
Has items
@end]]
            local result = luma.render(template, { items = { 1, 2, 3 } })
            assert.matches("Has items", result)
        end)
    end)
end)
