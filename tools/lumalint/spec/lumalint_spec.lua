local lumalint = require("lumalint.init")

describe("Lumalint", function()
    describe("lint()", function()
        it("should return no messages for valid template", function()
            local source = [[
@let name = "Alice"
Hello, $name!
]]
            local messages = lumalint.lint(source)
            assert.equals(0, #messages)
        end)

        it("should detect syntax errors", function()
            local source = "@if missing_end"
            local messages = lumalint.lint(source)

            assert.is_true(#messages > 0)
            assert.equals("syntax-error", messages[1].rule)
            assert.equals("error", messages[1].severity)
        end)

        it("should detect undefined variables", function()
            local source = "Hello, $undefined_var!"
            local messages = lumalint.lint(source)

            local found = false
            for _, msg in ipairs(messages) do
                if msg.rule == "undefined-variable" then
                    found = true
                    assert.equals("warning", msg.severity)
                    assert.matches("undefined_var", msg.message)
                end
            end
            assert.is_true(found)
        end)

        it("should not flag ignored variables", function()
            local source = "Chart: $Chart.Name"
            local options = {
                rules = { ["undefined-variable"] = true },
                ignore_vars = { Chart = true },
            }
            local messages = lumalint.lint(source, nil, options)

            -- Should not flag Chart as undefined
            for _, msg in ipairs(messages) do
                assert.is_not.equals("undefined-variable", msg.rule)
            end
        end)

        it("should detect unused variables", function()
            local source = [[
@let unused = "value"
Hello, World!
]]
            local messages = lumalint.lint(source)

            local found = false
            for _, msg in ipairs(messages) do
                if msg.rule == "unused-variable" then
                    found = true
                    assert.equals("info", msg.severity)
                    assert.matches("unused", msg.message)
                end
            end
            assert.is_true(found)
        end)

        it("should detect empty blocks", function()
            local source = [[
@if condition
@end
]]
            local messages = lumalint.lint(source)

            local found = false
            for _, msg in ipairs(messages) do
                if msg.rule == "empty-block" then
                    found = true
                    assert.equals("warning", msg.severity)
                end
            end
            assert.is_true(found)
        end)

        it("should detect lines that are too long", function()
            local source = string.rep("a", 150)
            local messages = lumalint.lint(source)

            local found = false
            for _, msg in ipairs(messages) do
                if msg.rule == "max-line-length" then
                    found = true
                    assert.equals("info", msg.severity)
                end
            end
            assert.is_true(found)
        end)

        it("should detect debug statements", function()
            local source = [[
@do print("debug") @end
]]
            local messages = lumalint.lint(source)

            local found = false
            for _, msg in ipairs(messages) do
                if msg.rule == "no-debug" then
                    found = true
                    assert.equals("warning", msg.severity)
                end
            end
            assert.is_true(found)
        end)

        it("should sort messages by line and column", function()
            local source = [[
$var1
$var2
$var3
]]
            local messages = lumalint.lint(source)

            -- Verify messages are sorted
            for i = 2, #messages do
                local prev = messages[i - 1]
                local curr = messages[i]
                assert.is_true(prev.line <= curr.line)
                if prev.line == curr.line then
                    assert.is_true(prev.column <= curr.column)
                end
            end
        end)
    end)

    describe("lint_file()", function()
        it("should lint a file", function()
            -- Create temporary file
            local tmpfile = os.tmpname()
            local f = io.open(tmpfile, "w")
            f:write("Hello, $name!")
            f:close()

            local messages = lumalint.lint_file(tmpfile)

            -- Clean up
            os.remove(tmpfile)

            -- Should have undefined variable warning
            local found = false
            for _, msg in ipairs(messages) do
                if msg.rule == "undefined-variable" then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it("should return error for missing file", function()
            local messages = lumalint.lint_file("/nonexistent/file.luma")
            assert.equals(1, #messages)
            assert.equals("file-not-found", messages[1].rule)
            assert.equals("error", messages[1].severity)
        end)
    end)

    describe("format_messages()", function()
        it("should format messages for display", function()
            local messages = {
                {
                    rule = "undefined-variable",
                    message = "Undefined variable 'foo'",
                    line = 5,
                    column = 10,
                    severity = "warning",
                },
            }

            local formatted = lumalint.format_messages(messages, "test.luma")
            assert.matches("test%.luma", formatted)
            assert.matches("5:10", formatted)
            assert.matches("Undefined variable 'foo'", formatted)
            assert.matches("%[undefined%-variable%]", formatted)
        end)

        it("should show success message for no issues", function()
            local formatted = lumalint.format_messages({}, "test.luma")
            assert.matches("No issues found", formatted)
        end)

        it("should include fix suggestions", function()
            local messages = {
                {
                    rule = "test",
                    message = "Test message",
                    line = 1,
                    column = 1,
                    severity = "warning",
                    fix_suggestion = "Do this instead",
                },
            }

            local formatted = lumalint.format_messages(messages, "test.luma")
            assert.matches("Suggestion: Do this instead", formatted)
        end)
    end)
end)
