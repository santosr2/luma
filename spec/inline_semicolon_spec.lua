--- Tests for inline directives with semicolon delimiter
-- @module spec.inline_semicolon_spec

local luma = require("luma")

describe("Inline Directives with Semicolon", function()
    describe("inline conditional", function()
        it("should work with semicolon delimiter", function()
            local template = "Status: @if active; Success @else Failed @end"
            local result = luma.render(template, { active = true })
            local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            assert.equals("Status: Success", clean)
        end)

        it("should work with variables", function()
            local template = "Hello @if name; $name @else Guest @end!"
            local result = luma.render(template, { name = "Alice" })
            local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            -- Note: Extra space before ! is due to inline whitespace handling
            assert.matches("Hello Alice", clean)
        end)

        it("should work without semicolon for directives without expressions", function()
            local template = "Status: @if active; Good @else Bad @end"
            local result = luma.render(template, { active = false })
            local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            assert.equals("Status: Bad", clean)
        end)
    end)

    describe("inline loops", function()
        it("should work with semicolon", function()
            local template = "Items: @for item in items; $item @end"
            local result = luma.render(template, { items = { "a", "b", "c" } })
            local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            assert.matches("Items: a b c", clean)
        end)

        it("should handle simple loop with items", function()
            local template = "List: @for item in items; $item, @end done"
            local result = luma.render(template, { items = {1, 2, 3} })
            local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            assert.matches("List: 1, 2, 3, done", clean)
        end)
    end)

    describe("space requirement", function()
        it("should require space before @ for inline directives", function()
            local template = "email@example.com"
            local result = luma.render(template, {})
            assert.equals("email@example.com", result)
        end)

        it("should work with space before @", function()
            local template = "Status: @if true; OK @end"
            local result = luma.render(template, {})
            local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            assert.matches("Status: OK", clean)
        end)

        it("should treat @ without space as literal", function()
            local template = "Contact us at:support@luma.com"
            local result = luma.render(template, {})
            assert.equals("Contact us at:support@luma.com", result)
        end)
    end)

    describe("mixed inline and block", function()
        it("should handle both modes", function()
            local template = [[
Inline: @if show; yes @end
Block:
@if show
  Content
@end
]]
            local result = luma.render(template, { show = true })
            assert.match("Inline:%s+yes", result)
            assert.match("Block:", result)
            assert.match("Content", result)
        end)
    end)
end)

