--- Tests for loop enhancements
-- @module spec.loop_enhanced_spec

describe("Loop Enhancements", function()
	local luma = require("luma")

	describe("enhanced loop variables", function()
		it("provides revindex", function()
			local template = [[
@for item in items
${loop.revindex}
@end]]
			local result = luma.render(template, { items = { "a", "b", "c" } })
			assert.matches("3", result)
			assert.matches("2", result)
			assert.matches("1", result)
		end)

		it("provides revindex0", function()
			local template = [[
@for item in items
${loop.revindex0}
@end]]
			local result = luma.render(template, { items = { "a", "b", "c" } })
			assert.matches("2", result)
			assert.matches("1", result)
			assert.matches("0", result)
		end)

		it("provides depth for nested loops", function()
			local template = [[
@for outer in outers
@for inner in inners
Depth: ${loop.depth}
@end
@end]]
			local result = luma.render(template, {
				outers = { 1 },
				inners = { 1 },
			})
			assert.matches("Depth: 2", result)
		end)

		it("provides depth0 for nested loops", function()
			local template = [[
@for outer in outers
@for inner in inners
Depth0: ${loop.depth0}
@end
@end]]
			local result = luma.render(template, {
				outers = { 1 },
				inners = { 1 },
			})
			assert.matches("Depth0: 1", result)
		end)

		it("provides previtem", function()
			local template = [[
@for item in items
@if loop.previtem is defined
Prev: ${loop.previtem}
@end
@end]]
			local result = luma.render(template, { items = { "a", "b", "c" } })
			assert.matches("Prev: a", result)
			assert.matches("Prev: b", result)
		end)

		it("provides nextitem", function()
			local template = [[
@for item in items
@if loop.nextitem is defined
Next: ${loop.nextitem}
@end
@end]]
			local result = luma.render(template, { items = { "a", "b", "c" } })
			assert.matches("Next: b", result)
			assert.matches("Next: c", result)
		end)

		it("provides cycle function", function()
			local template = [[
@for item in items
${loop.cycle("odd", "even")}
@end]]
			local result = luma.render(template, { items = { 1, 2, 3, 4 } })
			assert.matches("odd", result)
			assert.matches("even", result)
		end)
	end)

	describe("tuple unpacking", function()
		it("unpacks key-value pairs from dict", function()
			local template = [[
@for key, value in dict
${key}: ${value}
@end]]
			local result = luma.render(template, { dict = { name = "Alice", age = "30" } })
			-- Note: pairs() order is not guaranteed, so just check both exist
			assert.matches("name: Alice", result)
			assert.matches("age: 30", result)
		end)

		it("works with loop variables in tuple unpacking", function()
			local template = [[
@for key, value in dict
${loop.index}: ${key}
@end]]
			local result = luma.render(template, { dict = { a = 1, b = 2 } })
			assert.matches("1:", result)
			assert.matches("2:", result)
		end)
	end)

	describe("break directive", function()
		pending("exits the loop early", function()
			local template = [[
@for item in items
@if item == "stop"
@break
@end
${item}
@end]]
			local result = luma.render(template, { items = { "a", "b", "stop", "c", "d" } })
			assert.matches("a", result)
			assert.matches("b", result)
			assert.is_nil(result:match("c"))
			assert.is_nil(result:match("d"))
		end)

		pending("works with loop.index condition", function()
			local template = [[
@for item in items
@if loop.index > 2
@break
@end
${item}
@end]]
			local result = luma.render(template, { items = { "a", "b", "c", "d", "e" } })
			assert.matches("a", result)
			assert.matches("b", result)
			assert.is_nil(result:match("c"))
		end)
	end)

	describe("continue directive", function()
		pending("skips to next iteration", function()
			local template = [[
@for item in items
@if item == "skip"
@continue
@end
${item}
@end]]
			local result = luma.render(template, { items = { "a", "skip", "b", "skip", "c" } })
			assert.matches("a", result)
			assert.matches("b", result)
			assert.matches("c", result)
			-- "skip" should not appear in output
			local count = 0
			for _ in result:gmatch("skip") do
				count = count + 1
			end
			assert.equals(0, count)
		end)

		pending("works with odd/even filtering", function()
			local template = [[
@for num in nums
@if num is even
@continue
@end
${num}
@end]]
			local result = luma.render(template, { nums = { 1, 2, 3, 4, 5 } })
			assert.matches("1", result)
			assert.matches("3", result)
			assert.matches("5", result)
			-- Check that 2 and 4 are not there (tricky since they might be in other numbers)
		end)
	end)

	describe("nested loops with break/continue", function()
		pending("break only affects innermost loop", function()
			local template = [[
@for outer in outers
Outer: ${outer}
@for inner in inners
@if inner == "stop"
@break
@end
Inner: ${inner}
@end
@end]]
			local result = luma.render(template, {
				outers = { "A", "B" },
				inners = { "1", "stop", "2" },
			})
			-- Both outer iterations should complete
			assert.matches("Outer: A", result)
			assert.matches("Outer: B", result)
			-- But inner loop should stop at "stop"
			assert.matches("Inner: 1", result)
			assert.is_nil(result:match("Inner: 2"))
		end)
	end)
end)
