--- Integration tests for Luma
describe("Luma Integration", function()
	local luma = require("luma")

	describe("render", function()
		it("renders plain text", function()
			local result = luma.render("Hello, World!")
			assert.equals("Hello, World!", result)
		end)

		it("renders simple interpolation", function()
			local result = luma.render("Hello, $name!", { name = "Alice" })
			assert.equals("Hello, Alice!", result)
		end)

		it("renders nested access", function()
			local result = luma.render("$user.name", { user = { name = "Bob" } })
			assert.equals("Bob", result)
		end)

		it("renders expression interpolation", function()
			local result = luma.render("${name}", { name = "Charlie" })
			assert.equals("Charlie", result)
		end)

		it("handles nil values gracefully", function()
			local result = luma.render("Hello, $name!", {})
			assert.equals("Hello, !", result)
		end)

	it("escapes HTML by default", function()
		local result = luma.render("$content", { content = "<script>alert('xss')</script>" })
		-- Forward slashes don't need escaping in HTML content (only in JS contexts)
		assert.equals("&lt;script&gt;alert(&#x27;xss&#x27;)&lt;/script&gt;", result)
	end)

		it("handles escaped dollar signs", function()
			local result = luma.render("Price: $$100")
			assert.equals("Price: $100", result)
		end)
	end)

	describe("expressions", function()
		it("renders arithmetic", function()
			local result = luma.render("${1 + 2}")
			assert.equals("3", result)
		end)

		it("renders comparisons", function()
			local result = luma.render("${5 > 3}")
			assert.equals("true", result)
		end)

		it("renders logical operators", function()
			local result = luma.render("${true and false}")
			assert.equals("false", result)
		end)

		it("renders string values from context", function()
			-- String concatenation is done via filters or in context
			local result = luma.render("${greeting}", { greeting = "Hello, World!" })
			assert.equals("Hello, World!", result)
		end)
	end)

	describe("filters", function()
		it("applies upper filter", function()
			local result = luma.render("${name | upper}", { name = "alice" })
			assert.equals("ALICE", result)
		end)

		it("applies lower filter", function()
			local result = luma.render("${name | lower}", { name = "ALICE" })
			assert.equals("alice", result)
		end)

		it("applies default filter", function()
			local result = luma.render("${name | default('Anonymous')}", {})
			assert.equals("Anonymous", result)
		end)

		it("applies multiple filters", function()
			local result = luma.render("${name | default('unknown') | upper}", {})
			assert.equals("UNKNOWN", result)
		end)

		it("applies length filter", function()
			local result = luma.render("${items | length}", { items = { 1, 2, 3, 4, 5 } })
			assert.equals("5", result)
		end)

		it("applies first filter", function()
			local result = luma.render("${items | first}", { items = { "a", "b", "c" } })
			assert.equals("a", result)
		end)

		it("applies last filter", function()
			local result = luma.render("${items | last}", { items = { "a", "b", "c" } })
			assert.equals("c", result)
		end)

		it("applies join filter", function()
			local result = luma.render("${items | join(', ')}", { items = { "a", "b", "c" } })
			assert.equals("a, b, c", result)
		end)

		it("applies trim filter", function()
			local result = luma.render("${text | trim}", { text = "  hello  " })
			assert.equals("hello", result)
		end)

		it("applies capitalize filter", function()
			local result = luma.render("${name | capitalize}", { name = "alice" })
			assert.equals("Alice", result)
		end)

		it("applies title filter", function()
			local result = luma.render("${text | title}", { text = "hello world" })
			assert.equals("Hello World", result)
		end)

		it("applies round filter", function()
			local result = luma.render("${num | round(2)}", { num = 3.14159 })
			assert.equals("3.14", result)
		end)

		it("applies abs filter", function()
			local result = luma.render("${num | abs}", { num = -42 })
			assert.equals("42", result)
		end)
	end)

	describe("conditionals", function()
		it("renders @if when true", function()
			local template = [[
@if show
visible
@end]]
			local result = luma.render(template, { show = true })
			assert.matches("visible", result)
		end)

		it("skips @if when false", function()
			local template = [[
@if show
visible
@end]]
			local result = luma.render(template, { show = false })
			assert.not_matches("visible", result)
		end)

		it("renders @else branch", function()
			local template = [[
@if show
visible
@else
hidden
@end]]
			local result = luma.render(template, { show = false })
			assert.matches("hidden", result)
			assert.not_matches("visible", result)
		end)

		it("renders @elif branch", function()
			local template = [[
@if x == 1
one
@elif x == 2
two
@else
other
@end]]
			local result = luma.render(template, { x = 2 })
			assert.matches("two", result)
			assert.not_matches("one", result)
			assert.not_matches("other", result)
		end)
	end)

	describe("loops", function()
		it("renders @for loop", function()
			local template = [[
@for item in items
- $item
@end]]
			local result = luma.render(template, { items = { "a", "b", "c" } })
			assert.matches("- a", result)
			assert.matches("- b", result)
			assert.matches("- c", result)
		end)

		it("provides loop.index", function()
			local template = [[
@for item in items
${loop.index}: $item
@end]]
			local result = luma.render(template, { items = { "a", "b" } })
			assert.matches("1: a", result)
			assert.matches("2: b", result)
		end)

		it("provides loop.first and loop.last", function()
			local template = [[
@for item in items
@if loop.first
first: $item
@elif loop.last
last: $item
@else
middle: $item
@end
@end]]
			local result = luma.render(template, { items = { "a", "b", "c" } })
			assert.matches("first: a", result)
			assert.matches("middle: b", result)
			assert.matches("last: c", result)
		end)

		it("handles empty arrays with @else", function()
			local template = [[
@for item in items
- $item
@else
No items
@end]]
			local result = luma.render(template, { items = {} })
			assert.matches("No items", result)
			assert.not_matches("^-", result)
		end)
	end)

	describe("indented directives", function()
		it("handles indented @if", function()
			local template = [[
items:
    @if show
    - visible item
    @end]]
			local result = luma.render(template, { show = true })
			assert.matches("items:", result)
			assert.matches("visible item", result)
		end)

		it("handles nested indented directives", function()
			local template = [[
root:
    @for item in items
        @if item.active
        - $item.name (active)
        @else
        - $item.name (inactive)
        @end
    @end]]
			local ctx = {
				items = {
					{ name = "A", active = true },
					{ name = "B", active = false },
				},
			}
			local result = luma.render(template, ctx)
			assert.matches("A %(active%)", result)
			assert.matches("B %(inactive%)", result)
		end)

		it("preserves indentation in output content", function()
			local template = [[
spec:
    containers:
    @for c in containers
        - name: $c.name
          image: $c.image
    @end]]
			local ctx = {
				containers = {
					{ name = "web", image = "nginx" },
					{ name = "api", image = "node" },
				},
			}
			local result = luma.render(template, ctx)
			assert.matches("name: web", result)
			assert.matches("image: nginx", result)
			assert.matches("name: api", result)
		end)

		it("indents multiline content to match placeholder column", function()
			local template = [[
config:
    data: ${content}
done]]
			local result = luma.render(template, { content = "line1\nline2\nline3" })
			-- Each subsequent line should be indented to column 11 (where ${content} starts)
			assert.matches("data: line1", result)
			assert.matches("\n          line2", result) -- 10 spaces
			assert.matches("\n          line3", result) -- 10 spaces
		end)

		it("does not indent single-line content", function()
			local template = [[
    value: ${content}]]
			local result = luma.render(template, { content = "simple" })
			assert.equals("    value: simple", result)
		end)
	end)

	describe("variables", function()
		it("renders @let assignment", function()
			local template = [[
@let greeting = "Hello"
$greeting, World!]]
			local result = luma.render(template, {})
			assert.matches("Hello, World!", result)
		end)

		it("allows @let with expression", function()
			local template = [[
@let total = price * quantity
Total: $total]]
			local result = luma.render(template, { price = 10, quantity = 3 })
			assert.matches("Total: 30", result)
		end)
	end)

	describe("compile", function()
		it("compiles template for reuse", function()
			local compiled = luma.compile("Hello, $name!")

			local result1 = compiled:render({ name = "Alice" })
			local result2 = compiled:render({ name = "Bob" })

			assert.equals("Hello, Alice!", result1)
			assert.equals("Hello, Bob!", result2)
		end)

		it("exposes source code for debugging", function()
			local compiled = luma.compile("Hello, $name!")
			assert.is_string(compiled.source)
			assert.matches("function", compiled.source)
		end)
	end)

	describe("environment", function()
		it("creates custom environment", function()
			local env = luma.create_environment()
			local result = env:render("Hello, $name!", { name = "World" })
			assert.equals("Hello, World!", result)
		end)

		it("supports custom filters", function()
			local env = luma.create_environment()
			env:add_filter("double", function(s)
				return s .. s
			end)
			local result = env:render("${name | double}", { name = "hi" })
			assert.equals("hihi", result)
		end)

		it("supports global variables", function()
			local env = luma.create_environment()
			env:add_global("site_name", "My Site")
			local result = env:render("Welcome to $site_name!", {})
			assert.equals("Welcome to My Site!", result)
		end)
	end)

	describe("custom filters", function()
		it("registers global filter", function()
			luma.register_filter("exclaim", function(s)
				return s .. "!"
			end)
			local result = luma.render("${msg | exclaim}", { msg = "Hello" })
			assert.equals("Hello!", result)
		end)
	end)
end)
