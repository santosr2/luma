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
		it("exits the loop early", function()
			local template = [[
@for i in items
  @if i == 3
    @break
  @end
  $i
@end]]
			local result = luma.render(template, { items = { 1, 2, 3, 4, 5 } })
			assert.matches("1", result)
			assert.matches("2", result)
			assert.not_matches("3", result)
			assert.not_matches("4", result)
			assert.not_matches("5", result)
		end)

		it("works with loop.index condition", function()
			local template = [[
@for item in items
  @if loop.index > 2
    @break
  @end
  ${loop.index}: $item
@end]]
			local result = luma.render(template, { items = { "a", "b", "c", "d" } })
			assert.matches("1: a", result)
			assert.matches("2: b", result)
			assert.not_matches("3:", result)
			assert.not_matches("4:", result)
		end)
	end)

	describe("continue directive", function()
		it("skips to next iteration", function()
			local template = [[
@for i in items
  @if i == 3
    @continue
  @end
  $i
@end]]
			local result = luma.render(template, { items = { 1, 2, 3, 4, 5 } })
			assert.matches("1", result)
			assert.matches("2", result)
			assert.not_matches("3", result)
			assert.matches("4", result)
			assert.matches("5", result)
		end)

		it("works with odd/even filtering", function()
			local template = [[
@for i in items
  @if i % 2 == 0
    @continue
  @end
  $i
@end]]
			local result = luma.render(template, { items = { 1, 2, 3, 4, 5 } })
			assert.matches("1", result)
			assert.not_matches("2", result)
			assert.matches("3", result)
			assert.not_matches("4", result)
			assert.matches("5", result)
		end)
	end)

	describe("nested loops with break/continue", function()
		it("break only affects innermost loop", function()
			local template = [[
@for outer in outers
  Outer: $outer
  @for inner in inners
    @if inner == 2
      @break
    @end
    Inner: $inner
  @end
@end]]
			local result = luma.render(template, { outers = { 1, 2 }, inners = { 1, 2, 3 } })
			-- Both outer iterations should run
			assert.matches("Outer: 1", result)
			assert.matches("Outer: 2", result)
			-- Inner loop should break at 2 (so only 1 is printed, twice - once per outer)
			local inner_1_count = select(2, result:gsub("Inner: 1", ""))
			assert.equals(2, inner_1_count)
			assert.not_matches("Inner: 2", result)
			assert.not_matches("Inner: 3", result)
		end)
	end)
end)
