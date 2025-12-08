--- Tests for extended Jinja2-compatible filters
-- @module spec.filters_extended_spec

local luma = require("luma")

describe("Extended Filters", function()
    describe("String filters", function()
        describe("replace", function()
            it("should replace substrings", function()
                local result = luma.render("${s | replace('world', 'Lua')}", { s = "Hello world" })
                assert.equals("Hello Lua", result)
            end)

            it("should replace all occurrences", function()
                local result = luma.render("${s | replace('a', 'X')}", { s = "banana" })
                assert.equals("bXnXnX", result)
            end)

            it("should handle special regex characters", function()
                local result = luma.render("${s | replace('.', '-')}", { s = "1.2.3" })
                assert.equals("1-2-3", result)
            end)
        end)

        describe("split", function()
            it("should split by space by default", function()
                local result = luma.render("${(s | split) | join(',')}", { s = "one two three" })
                assert.equals("one,two,three", result)
            end)

            it("should split by custom separator", function()
                local result = luma.render("${(s | split(',')) | join('-')}", { s = "a,b,c" })
                assert.equals("a-b-c", result)
            end)

            it("should split into characters with empty separator", function()
                local result = luma.render("${(s | split('')) | join('-')}", { s = "abc" })
                assert.equals("a-b-c", result)
            end)
        end)

        describe("wordwrap", function()
            it("should wrap text at specified width", function()
                local result = luma.render("${s | wordwrap(10)}", { s = "Hello World Test" })
                assert.match("Hello", result)
                assert.match("World Test", result)
            end)
        end)

        describe("center", function()
            it("should center text in given width", function()
                local result = luma.render("${s | center(10)}", { s = "ab" })
                assert.equals("    ab    ", result)
            end)

            it("should return unchanged if text is longer than width", function()
                local result = luma.render("${s | center(3)}", { s = "hello" })
                assert.equals("hello", result)
            end)
        end)

        describe("indent", function()
            it("should indent all lines", function()
                local result = luma.render("${s | indent(2)}", { s = "a\nb" })
                assert.equals("  a\n  b", result)
            end)

            it("should skip first line when first is false", function()
                local result = luma.render("${s | indent(2, false)}", { s = "a\nb" })
                assert.equals("a\n  b", result)
            end)
        end)

        describe("truncate", function()
            it("should truncate long strings", function()
                local result = luma.render("${s | truncate(10)}", { s = "Hello World Test" })
                assert.equals("Hello...", result)
            end)

            it("should not truncate short strings", function()
                local result = luma.render("${s | truncate(20)}", { s = "Hello" })
                assert.equals("Hello", result)
            end)

            it("should kill words when specified", function()
                local result = luma.render("${s | truncate(8, true)}", { s = "Hello World" })
                assert.equals("Hello...", result)
            end)
        end)

        describe("striptags", function()
            it("should remove HTML tags", function()
                local result = luma.render("${s | striptags}", { s = "<p>Hello <b>World</b></p>" })
                assert.equals("Hello World", result)
            end)
        end)

        describe("urlencode", function()
            it("should encode special characters", function()
                local result = luma.render("${s | urlencode}", { s = "hello world" })
                assert.equals("hello%20world", result)
            end)

            it("should encode special URL characters", function()
                local result = luma.render("${s | urlencode}", { s = "a=b&c=d" })
                assert.equals("a%3Db%26c%3Dd", result)
            end)
        end)
    end)

    describe("Collection filters", function()
        describe("unique", function()
            it("should remove duplicates", function()
                local result = luma.render("${(items | unique) | join(',')}", { items = { 1, 2, 1, 3, 2 } })
                assert.equals("1,2,3", result)
            end)
        end)

        describe("sum", function()
            it("should sum numbers", function()
                local result = luma.render("${items | sum}", { items = { 1, 2, 3, 4 } })
                assert.equals("10", result)
            end)

            it("should sum with start value", function()
                local result = luma.render("${items | sum(nil, 10)}", { items = { 1, 2, 3 } })
                assert.equals("16", result)
            end)

            it("should sum attribute values", function()
                local items = { { price = 10 }, { price = 20 }, { price = 30 } }
                local result = luma.render("${items | sum('price')}", { items = items })
                assert.equals("60", result)
            end)
        end)

        describe("min", function()
            it("should return minimum value", function()
                local result = luma.render("${items | min}", { items = { 5, 2, 8, 1, 9 } })
                assert.equals("1", result)
            end)
        end)

        describe("max", function()
            it("should return maximum value", function()
                local result = luma.render("${items | max}", { items = { 5, 2, 8, 1, 9 } })
                assert.equals("9", result)
            end)
        end)

        describe("groupby", function()
            it("should group items by attribute", function()
                local items = {
                    { name = "Alice", type = "admin" },
                    { name = "Bob", type = "user" },
                    { name = "Carol", type = "admin" },
                }
                local template = [[
@for group in items | groupby('type')
$group.grouper: ${group.list | map('name') | join(', ')}
@end]]
                local result = luma.render(template, { items = items })
                assert.match("admin: Alice, Carol", result)
                assert.match("user: Bob", result)
            end)
        end)

        describe("selectattr", function()
            it("should select items with defined attribute", function()
                local items = {
                    { name = "Alice", email = "alice@example.com" },
                    { name = "Bob" },
                    { name = "Carol", email = "carol@example.com" },
                }
                local result = luma.render("${(items | selectattr('email')) | map('name') | join(',')}", { items = items })
                assert.equals("Alice,Carol", result)
            end)

            it("should select items matching equality test", function()
                local items = {
                    { name = "Alice", active = true },
                    { name = "Bob", active = false },
                    { name = "Carol", active = true },
                }
                local result = luma.render("${(items | selectattr('active', 'eq', true)) | map('name') | join(',')}", { items = items })
                assert.equals("Alice,Carol", result)
            end)
        end)

        describe("rejectattr", function()
            it("should reject items with defined attribute", function()
                local items = {
                    { name = "Alice", email = "alice@example.com" },
                    { name = "Bob" },
                    { name = "Carol", email = "carol@example.com" },
                }
                local result = luma.render("${(items | rejectattr('email')) | map('name') | join(',')}", { items = items })
                assert.equals("Bob", result)
            end)
        end)

        describe("map", function()
            it("should extract attribute values", function()
                local items = {
                    { name = "Alice" },
                    { name = "Bob" },
                    { name = "Carol" },
                }
                local result = luma.render("${(items | map('name')) | join(',')}", { items = items })
                assert.equals("Alice,Bob,Carol", result)
            end)
        end)

        describe("keys", function()
            it("should return table keys", function()
                local result = luma.render("${(d | keys) | sort | join(',')}", { d = { a = 1, b = 2, c = 3 } })
                assert.equals("a,b,c", result)
            end)
        end)

        describe("values", function()
            it("should return table values", function()
                local result = luma.render("${(d | values) | sort | join(',')}", { d = { a = 1, b = 2, c = 3 } })
                assert.equals("1,2,3", result)
            end)
        end)
    end)

    describe("Utility filters", function()
        describe("tojson", function()
            it("should convert string to JSON", function()
                local result = luma.render("${s | tojson | safe}", { s = "hello" })
                assert.equals('"hello"', result)
            end)

            it("should convert number to JSON", function()
                local result = luma.render("${n | tojson | safe}", { n = 42 })
                assert.equals("42", result)
            end)

            it("should convert boolean to JSON", function()
                local result = luma.render("${b | tojson | safe}", { b = true })
                assert.equals("true", result)
            end)

            it("should convert nil to JSON null", function()
                local result = luma.render("${n | tojson | safe}", { n = nil })
                assert.equals("null", result)
            end)

            it("should convert array to JSON", function()
                local result = luma.render("${a | tojson | safe}", { a = { 1, 2, 3 } })
                assert.equals("[1, 2, 3]", result)
            end)

            it("should escape special characters in strings", function()
                local result = luma.render("${s | tojson | safe}", { s = 'hello\n"world"' })
                assert.equals('"hello\\n\\"world\\""', result)
            end)
        end)

        describe("batch", function()
            it("should batch items into groups", function()
                local template = [[
@for row in items | batch(3)
${row | join(',')}
@end]]
                local result = luma.render(template, { items = { 1, 2, 3, 4, 5 } })
                assert.match("1,2,3", result)
                assert.match("4,5", result)
            end)

            it("should fill last batch if fill value provided", function()
                local template = "${(items | batch(3, 'x')) | last | join(',')}"
                local result = luma.render(template, { items = { 1, 2, 3, 4, 5 } })
                assert.equals("4,5,x", result)
            end)
        end)

        describe("slice", function()
            it("should slice items into n parts", function()
                local template = [[
@for part in items | slice(2)
${part | join(',')}
@end]]
                local result = luma.render(template, { items = { 1, 2, 3, 4 } })
                assert.match("1,2", result)
                assert.match("3,4", result)
            end)
        end)

        describe("dictsort", function()
            it("should sort dictionary by key", function()
                local template = [[
@for item in d | dictsort
$item.key: $item.value
@end]]
                local result = luma.render(template, { d = { c = 3, a = 1, b = 2 } })
                -- Check order
                local a_pos = result:find("a:")
                local b_pos = result:find("b:")
                local c_pos = result:find("c:")
                assert.is_true(a_pos < b_pos)
                assert.is_true(b_pos < c_pos)
            end)

            it("should sort case insensitively when specified", function()
                local template = [[
@for item in d | dictsort(false)
$item.key
@end]]
                local result = luma.render(template, { d = { B = 1, a = 2, C = 3 } })
                local a_pos = result:find("a")
                local b_pos = result:find("B")
                local c_pos = result:find("C")
                assert.is_true(a_pos < b_pos)
                assert.is_true(b_pos < c_pos)
            end)
        end)

        describe("attr", function()
            it("should get attribute from object", function()
                local result = luma.render("${obj | attr('name')}", { obj = { name = "test" } })
                assert.equals("test", result)
            end)
        end)

        describe("select", function()
            it("should select truthy values (non-zero, non-false, non-empty)", function()
                -- Note: nil values are skipped by ipairs, so we test with defined values
                local result = luma.render("${(items | select) | join(',')}", { items = { 1, 2, 3, 4 } })
                assert.equals("1,2,3,4", result)
            end)

            it("should filter out 0 and false", function()
                local result = luma.render("${(items | select) | join(',')}", { items = { 1, 0, 2, false, 3 } })
                assert.equals("1,2,3", result)
            end)
        end)

        describe("reject", function()
            it("should keep falsy values (0, false, empty string)", function()
                local result = luma.render("${(items | reject) | join(',')}", { items = { 1, 0, false, 2 } })
                assert.equals("0,false", result)
            end)
        end)
    end)
end)
