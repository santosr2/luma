--- Tests for membership operators (in / not in)
-- @module spec.membership_spec

describe("Membership Operators", function()
	local luma = require("luma")

	describe("in operator", function()
		it("checks substring in string", function()
			local result = luma.render("${'a' in 'abc'}")
			assert.equals("true", result)
		end)

		it("returns false for substring not in string", function()
			local result = luma.render("${'x' in 'abc'}")
			assert.equals("false", result)
		end)

		it("checks value in array", function()
			local result = luma.render("${item in items}", { item = "b", items = { "a", "b", "c" } })
			assert.equals("true", result)
		end)

		it("returns false for value not in array", function()
			local result = luma.render("${item in items}", { item = "x", items = { "a", "b", "c" } })
			assert.equals("false", result)
		end)

		it("checks key in table", function()
			local result = luma.render("${'name' in user}", { user = { name = "Alice", age = 30 } })
			assert.equals("true", result)
		end)

		it("works with numeric values", function()
			local result = luma.render("${2 in nums}", { nums = { 1, 2, 3 } })
			assert.equals("true", result)
		end)

		it("handles nil container gracefully", function()
			local result = luma.render("${'x' in missing}")
			assert.equals("false", result)
		end)

		it("works in @if conditions", function()
			local template = [[
@if 'admin' in roles
Has admin
@end]]
			local result = luma.render(template, { roles = { "user", "admin" } })
			assert.matches("Has admin", result)
		end)

		it("works with complex expressions", function()
			local result = luma.render("${user.role in allowed}", {
				user = { role = "editor" },
				allowed = { "editor", "admin" },
			})
			assert.equals("true", result)
		end)
	end)

	describe("not in operator", function()
		it("checks substring not in string", function()
			local result = luma.render("${'x' not in 'abc'}")
			assert.equals("true", result)
		end)

		it("returns false for substring in string", function()
			local result = luma.render("${'a' not in 'abc'}")
			assert.equals("false", result)
		end)

		it("checks value not in array", function()
			local result = luma.render("${item not in items}", { item = "x", items = { "a", "b", "c" } })
			assert.equals("true", result)
		end)

		it("returns false for value in array", function()
			local result = luma.render("${item not in items}", { item = "b", items = { "a", "b", "c" } })
			assert.equals("false", result)
		end)

		it("works in @if conditions", function()
			local template = [[
@if 'guest' not in roles
Not a guest
@end]]
			local result = luma.render(template, { roles = { "user", "admin" } })
			assert.matches("Not a guest", result)
		end)

		it("handles nil container gracefully", function()
			local result = luma.render("${'x' not in missing}")
			assert.equals("true", result)
		end)
	end)

	describe("operator precedence", function()
		it("works with and operator", function()
			local result = luma.render("${'a' in 'abc' and 'x' not in 'abc'}")
			assert.equals("true", result)
		end)

		it("works with or operator", function()
			local result = luma.render("${'x' in 'abc' or 'a' in 'abc'}")
			assert.equals("true", result)
		end)

		it("works with not operator", function()
			local result = luma.render("${not ('x' in 'abc')}")
			assert.equals("true", result)
		end)
	end)
end)
