--- Tests for filter named arguments
-- @module spec.filter_named_args_spec

local luma = require("luma")
local runtime = require("luma.runtime")

describe("Filter Named Arguments", function()
    describe("truncate filter", function()
        it("should work with positional arguments (backward compat)", function()
            local template = '{{ text | truncate(10) }}'
            local result = luma.render(template, { text = "Hello World!" }, { syntax = "jinja" })
            assert.equals("Hello...", result)
        end)

        it("should work with named length argument", function()
            local template = '{{ text | truncate(length=10) }}'
            local result = luma.render(template, { text = "Hello World!" }, { syntax = "jinja" })
            assert.equals("Hello...", result)
        end)

        it("should work with named killwords argument", function()
            local template = '{{ text | truncate(length=10, killwords=true) }}'
            local result = luma.render(template, { text = "Hello World!" }, { syntax = "jinja" })
            assert.equals("Hello W...", result)
        end)

        it("should work with named end argument", function()
            local template = '{{ text | truncate(length=10, end=">>") }}'
            local result = luma.render(template, { text = "Hello World!" }, { syntax = "jinja" })
            assert.equals("Hello >>", result)
        end)

        it("should work with all named arguments", function()
            local template = '{{ text | truncate(length=8, killwords=true, end="!") }}'
            local result = luma.render(template, { text = "Hello World" }, { syntax = "jinja" })
            assert.equals("Hello W!", result)
        end)

        it("should work with mixed positional and named arguments", function()
            local template = '{{ text | truncate(10, killwords=true) }}'
            local result = luma.render(template, { text = "Hello World!" }, { syntax = "jinja" })
            assert.equals("Hello W...", result)
        end)
    end)

    describe("wordwrap filter", function()
        it("should work with positional arguments", function()
            local template = '{{ text | wordwrap(10) }}'
            local result = luma.render(template, { text = "Hello World From Luma" }, { syntax = "jinja" })
            assert.match("Hello", result)
            assert.match("\n", result)
        end)

        it("should work with named width argument", function()
            local template = '{{ text | wordwrap(width=10) }}'
            local result = luma.render(template, { text = "Hello World From Luma" }, { syntax = "jinja" })
            assert.match("Hello", result)
            assert.match("\n", result)
        end)

        it("should work with named wrapstring argument", function()
            local template = '{{ text | wordwrap(width=10, wrapstring=" | ") }}'
            local result = luma.render(template, { text = "Hello World From Luma" }, { syntax = "jinja" })
            assert.match(" | ", result)
        end)
    end)

    describe("indent filter", function()
        it("should work with positional arguments", function()
            local template = '{{ text | indent(2) }}'
            local result = luma.render(template, { text = "Hello\nWorld" }, { syntax = "jinja" })
            assert.match("^  Hello", result)
            assert.match("\n  World", result)
        end)

        it("should work with named width argument", function()
            local template = '{{ text | indent(width=4) }}'
            local result = luma.render(template, { text = "Hello\nWorld" }, { syntax = "jinja" })
            assert.match("^    Hello", result)
        end)

        it("should work with named first argument", function()
            local template = '{{ text | indent(width=2, first=false) }}'
            local result = luma.render(template, { text = "Hello\nWorld" }, { syntax = "jinja" })
            assert.match("^Hello", result) -- First line not indented
            assert.match("\n  World", result) -- Second line indented
        end)

        it("should work with all named arguments", function()
            local template = '{{ text | indent(width=2, first=true, blank=true) }}'
            local result = luma.render(template, { text = "A\n\nB" }, { syntax = "jinja" })
            assert.match("^  A", result)
            assert.match("\n  \n", result) -- Blank line also indented
        end)
    end)

    describe("in Luma native syntax", function()
        it("should work with named arguments in ${} interpolation", function()
            local template = '${text | truncate(length=10, killwords=true)}'
            local result = luma.render(template, { text = "Hello World!" })
            assert.equals("Hello W...", result)
        end)

        it("should work with mixed named and positional", function()
            local template = '${text | wordwrap(10, wrapstring=" // ")}'
            local result = luma.render(template, { text = "Hello World From Luma" })
            assert.match(" // ", result)
        end)
    end)

    describe("error handling", function()
        it("should error when positional args come after named args", function()
            local template = '{{ text | truncate(length=10, "end") }}'
            assert.has_error(function()
                luma.render(template, { text = "test" }, { syntax = "jinja" })
            end)
        end)
    end)

    describe("custom filters with named arguments", function()
        it("should support named arguments in custom filters", function()
            luma.register_filter("custom", function(value, ...)
                local pos, named = runtime._extract_filter_args({value, ...}, 2)
                local prefix = named.prefix or pos[2] or ""
                local suffix = named.suffix or pos[3] or ""
                return prefix .. tostring(value) .. suffix
            end)

            local template = '{{ text | custom(prefix="[", suffix="]") }}'
            local result = luma.render(template, { text = "test" }, { syntax = "jinja" })
            assert.equals("[test]", result)
        end)

        it("should work with mixed positional and named in custom filters", function()
            luma.register_filter("wrap", function(value, ...)
                local pos, named = runtime._extract_filter_args({value, ...}, 2)
                local left = pos[2] or named.left or "("
                local right = named.right or pos[3] or ")"
                return left .. tostring(value) .. right
            end)

            local template = '{{ text | wrap("[", right="]") }}'
            local result = luma.render(template, { text = "test" }, { syntax = "jinja" })
            assert.equals("[test]", result)
        end)
    end)

    describe("chained filters with named arguments", function()
        it("should support named args in filter chains", function()
            local template = '{{ text | truncate(length=20, end="...") | upper }}'
            local result = luma.render(template, { text = "Hello World!" }, { syntax = "jinja" })
            assert.equals("HELLO WORLD!", result) -- Under length, so not truncated, then uppercased
        end)

        it("should support multiple filters with named args", function()
            local template = '{{ text | indent(width=2, first=false) | truncate(length=15) }}'
            local result = luma.render(template, { text = "A\nB" }, { syntax = "jinja" })
            assert.match("^A", result) -- First line not indented
        end)
    end)
end)

