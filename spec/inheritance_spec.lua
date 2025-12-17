--- Tests for template inheritance (@extends/@block)
-- @module spec.inheritance_spec

local luma = require("luma")
local runtime = require("luma.runtime")

describe("Template Inheritance", function()
	-- Store the original loader to restore after tests
	local original_loader
	local templates = {}

	setup(function()
		-- Set up a custom loader that serves from our templates table
		runtime.set_loader(function(name)
			return templates[name]
		end)
	end)

	teardown(function()
		-- Reset loader
		runtime.set_loader(nil)
	end)

	before_each(function()
		-- Clear templates before each test
		templates = {}
	end)

	describe("@extends directive", function()
		it("should render parent template when child has no blocks", function()
			templates["base.html"] = "Hello from base"
			local child = '@extends "base.html"\n'
			local result = luma.render(child, {})
			assert.equals("Hello from base", result)
		end)

		it("should allow child to override parent block", function()
			templates["base.html"] = [[Header
@block content
Default content
@end
Footer]]
			local child = [[@extends "base.html"
@block content
Custom content from child
@end]]
			local result = luma.render(child, {})
			assert.match("Header", result)
			assert.match("Custom content from child", result)
			assert.match("Footer", result)
			assert.is_not.match("Default content", result)
		end)

		it("should keep parent block content when child doesn't override", function()
			templates["base.html"] = [[Start
@block header
Parent Header
@end
Middle
@block footer
Parent Footer
@end
End]]
			local child = [[@extends "base.html"
@block header
Child Header
@end]]
			local result = luma.render(child, {})
			assert.match("Child Header", result)
			assert.match("Parent Footer", result)
		end)

		it("should support multiple block overrides", function()
			templates["base.html"] = [[@block a
A
@end
@block b
B
@end
@block c
C
@end]]
			local child = [[@extends "base.html"
@block a
X
@end
@block c
Z
@end]]
			local result = luma.render(child, {})
			assert.match("X", result)
			assert.match("B", result)
			assert.match("Z", result)
		end)
	end)

	describe("nested inheritance", function()
		it("should support three-level inheritance", function()
			templates["grandparent.html"] = [[<!DOCTYPE html>
@block body
Grandparent body
@end]]
			templates["parent.html"] = [[@extends "grandparent.html"
@block body
Parent body
@end]]
			local child = [[@extends "parent.html"
@block body
Child body
@end]]
			local result = luma.render(child, {})
			assert.match("<!DOCTYPE html>", result)
			assert.match("Child body", result)
			assert.is_not.match("Parent body", result)
			assert.is_not.match("Grandparent body", result)
		end)

		it("should allow middle template to not override a block", function()
			templates["grandparent.html"] = [[@block content
Grandparent
@end]]
			templates["parent.html"] = [[@extends "grandparent.html"]]
			local child = [[@extends "parent.html"
@block content
Child
@end]]
			local result = luma.render(child, {})
			assert.match("Child", result)
		end)
	end)

	describe("blocks with dynamic content", function()
		it("should interpolate variables in blocks", function()
			templates["base.html"] = [[Hello,
@block greeting
Guest
@end]]
			local child = [[@extends "base.html"
@block greeting
$name
@end]]
			local result = luma.render(child, { name = "Alice" })
			assert.match("Hello,", result)
			assert.match("Alice", result)
		end)

		it("should support directives in blocks", function()
			templates["base.html"] = [[List:
@block items
No items
@end]]
			local child = [[@extends "base.html"
@block items
@for item in items
- $item
@end
@end]]
			local result = luma.render(child, { items = { "one", "two", "three" } })
			assert.match("- one", result)
			assert.match("- two", result)
			assert.match("- three", result)
		end)

		it("should support filters in blocks", function()
			templates["base.html"] = [[@block title
Default Title
@end]]
			local child = [[@extends "base.html"
@block title
${title | upper}
@end]]
			local result = luma.render(child, { title = "hello" })
			assert.match("HELLO", result)
		end)
	end)

	describe("@endblock alias", function()
		it("should accept @endblock as block terminator", function()
			templates["base.html"] = [[@block content
Default
@endblock]]
			local child = [[@extends "base.html"
@block content
Override
@endblock]]
			local result = luma.render(child, {})
			assert.match("Override", result)
		end)
	end)

	describe("error handling", function()
		it("should error on missing parent template", function()
			local child = '@extends "nonexistent.html"\n'
			assert.has_error(function()
				luma.render(child, {})
			end)
		end)
	end)

	describe("context inheritance", function()
		it("should pass context through to parent blocks", function()
			templates["base.html"] = [[User: $user
@block content
Content here
@end]]
			local child = [[@extends "base.html"
@block content
Hello $user
@end]]
			local result = luma.render(child, { user = "Bob" })
			assert.match("User: Bob", result)
			assert.match("Hello Bob", result)
		end)
	end)
end)
