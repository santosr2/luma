--- Tests for context-aware inline mode
-- @module spec.inline_mode_spec

local luma = require("luma")

describe("Context-Aware Inline Mode", function()
	describe("inline conditional detection", function()
		it("should auto-detect inline @if when text is on same line with semicolon", function()
			local template = "Status: @if active; Success @else Failed @end"
			local result = luma.render(template, { active = true })
			-- Should not add extra newlines
			assert.equals("Status: Success", result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
		end)

		it("should auto-detect inline @if with variables", function()
			local template = "Hello @if name; $name @else Guest @end!"
			local result = luma.render(template, { name = "Alice" })
			assert.match("Hello%s+Alice", result)
			assert.is_not.match("\n", result)
		end)

		it("should use block mode when directive is on own line", function()
			local template = [[
Status:
@if active
  Success
@else
  Failed
@end
]]
			local result = luma.render(template, { active = true })
			assert.match("Status:", result)
			assert.match("Success", result)
			assert.match("\n", result) -- Should have newlines
		end)
	end)

	describe("inline loops", function()
		it("should auto-detect inline @for", function()
			local template = "Tags: @for tag in tags $tag @end"
			local result = luma.render(template, { tags = { "a", "b", "c" } })
			-- Should be compact
			local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
			assert.matches("Tags:.*a.*b.*c", clean)
		end)

		it("should handle inline @for with separator", function()
			local template = "List: @for item in items $item@if not loop.last, @end @end"
			local result = luma.render(template, { items = { 1, 2, 3 } })
			local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
			assert.matches("List:.*1.*,.*2.*,.*3", clean)
		end)

		it("should use block mode for multi-line loops", function()
			local template = [[
Items:
@for item in items
  - $item
@end
]]
			local result = luma.render(template, { items = { "a", "b" } })
			assert.match("%-%s+a", result)
			assert.match("%-%s+b", result)
		end)
	end)

	describe("mixed inline and block mode", function()
		it("should handle both modes in same template", function()
			local template = [[
# Title
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

		it("should handle nested inline directives", function()
			local template = "Result: @if a; @if b; both @else A only @end @else none @end"
			local result = luma.render(template, { a = true, b = true })
			local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
			assert.matches("Result:.*both", clean)
		end)
	end)

	describe("inline detection edge cases", function()
		it("should handle directive at start of line", function()
			local template = "@if true; Start @end of line"
			local result = luma.render(template, {})
			local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
			assert.equals("Start of line", clean)
		end)

		it("should handle directive at end of line", function()
			local template = "Text before @if true; end @end"
			local result = luma.render(template, {})
			local clean = result:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
			assert.equals("Text before end", clean)
		end)

		it("should handle empty inline conditional", function()
			local template = "Before @if false; content @end After"
			local result = luma.render(template, {})
			assert.equals("Before After", result:gsub("%s+", " "))
		end)

		it("should not confuse indented block with inline", function()
			local template = [[
  @if true
    indented content
  @end
]]
			local result = luma.render(template, {})
			assert.match("\n", result) -- Should preserve structure
			assert.match("indented content", result)
		end)
	end)

	describe("whitespace handling in inline mode", function()
		it("should preserve spaces around inline directives", function()
			local template = "A @if true; B @end C"
			local result = luma.render(template, {})
			local clean = result:gsub("%s+", " ")
			assert.matches("A%s+B%s+C", clean)
		end)

		it("should not add extra newlines in inline mode", function()
			local template = "One @if true Two @end Three"
			local result = luma.render(template, {})
			-- Count newlines - should be minimal
			local _, newline_count = result:gsub("\n", "\n")
			assert.is_true(newline_count <= 1)
		end)
	end)
end)
