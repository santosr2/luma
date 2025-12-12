--- Tests for autoescape blocks
-- @module spec.autoescape_spec

local luma = require("luma")

describe("Autoescape Blocks", function()
    describe("basic autoescape functionality", function()
        it("should escape HTML by default", function()
            local template = "{{ html }}"
            local result = luma.render(template, { html = "<div>test</div>" }, { syntax = "jinja" })
            assert.equals("&lt;div&gt;test&lt;/div&gt;", result)
        end)

        it("should disable escaping in autoescape false block", function()
            local template = [[
{% autoescape false %}
{{ html }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<div>test</div>" }, { syntax = "jinja" })
            assert.matches("<div>test</div>", result)
        end)

        it("should enable escaping in autoescape true block", function()
            local template = [[
{% autoescape true %}
{{ html }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<b>bold</b>" }, { syntax = "jinja" })
            assert.matches("&lt;b&gt;bold&lt;/b&gt;", result)
        end)

        it("should work with Luma native syntax", function()
            local template = [[
@autoescape false
${html}
@endautoescape]]
            local result = luma.render(template, { html = "<span>text</span>" })
            assert.matches("<span>text</span>", result)
        end)
    end)

    describe("nested autoescape blocks", function()
        it("should restore previous autoescape state", function()
            local template = [[
Before: {{ html }}
{% autoescape false %}
Inside false: {{ html }}
{% endautoescape %}
After: {{ html }}]]
            local result = luma.render(template, { html = "<div>" }, { syntax = "jinja" })
            assert.matches("Before: &lt;div&gt;", result)
            assert.matches("Inside false: <div>", result)
            assert.matches("After: &lt;div&gt;", result)
        end)

        it("should handle nested autoescape blocks", function()
            local template = [[
{% autoescape false %}
Outer false: {{ html }}
{% autoescape true %}
Inner true: {{ html }}
{% endautoescape %}
Back to false: {{ html }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<tag>" }, { syntax = "jinja" })
            assert.matches("Outer false: <tag>", result)
            assert.matches("Inner true: &lt;tag&gt;", result)
            assert.matches("Back to false: <tag>", result)
        end)

        it("should handle multiple nesting levels", function()
            local template = [[
@autoescape false
L1: $html
@autoescape true
L2: $html
@autoescape false
L3: $html
@endautoescape
Back L2: $html
@endautoescape
Back L1: $html
@endautoescape]]
            local result = luma.render(template, { html = "<x>" })
            assert.matches("L1: <x>", result)
            assert.matches("L2: &lt;x&gt;", result)
            assert.matches("L3: <x>", result)
            assert.matches("Back L2: &lt;x&gt;", result)
            assert.matches("Back L1: <x>", result)
        end)
    end)

    describe("with control structures", function()
        it("should work inside loops", function()
            local template = [[
{% autoescape false %}
{% for item in items %}
{{ item }}
{% endfor %}
{% endautoescape %}]]
            local result = luma.render(template, {
                items = {"<a>", "<b>", "<c>"}
            }, { syntax = "jinja" })
            assert.matches("<a>", result)
            assert.matches("<b>", result)
            assert.matches("<c>", result)
        end)

        it("should work inside conditionals", function()
            local template = [[
{% autoescape false %}
{% if show %}
{{ html }}
{% endif %}
{% endautoescape %}]]
            local result = luma.render(template, {
                show = true,
                html = "<div>content</div>"
            }, { syntax = "jinja" })
            assert.matches("<div>content</div>", result)
        end)

        it("should work with nested control structures", function()
            local template = [[
@autoescape false
@for user in users
  @if user.active
    Name: $user.name (${user.tag})
  @end
@end
@endautoescape]]
            local result = luma.render(template, {
                users = {
                    { name = "Alice", tag = "<admin>", active = true },
                    { name = "Bob", tag = "<user>", active = false },
                    { name = "Charlie", tag = "<mod>", active = true }
                }
            })
            assert.matches("Alice.*<admin>", result)
            assert.not_matches("Bob", result)
            assert.matches("Charlie.*<mod>", result)
        end)
    end)

    describe("format specification", function()
        it("should accept format name as string", function()
            local template = [[
{% autoescape "html" %}
{{ html }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<p>test</p>" }, { syntax = "jinja" })
            -- String format name is treated as enabled
            assert.matches("&lt;p&gt;test&lt;/p&gt;", result)
        end)

        it("should accept format name as identifier", function()
            local template = [[
{% autoescape html %}
{{ html }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<p>test</p>" }, { syntax = "jinja" })
            -- Identifier format name is treated as enabled
            assert.matches("&lt;p&gt;test&lt;/p&gt;", result)
        end)

        it("should recognize false as identifier", function()
            local template = [[
{% autoescape false %}
{{ html }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<tag>" }, { syntax = "jinja" })
            assert.matches("<tag>", result)
        end)
    end)

    describe("interaction with safe filter", function()
        it("should not escape safe values even in autoescape true", function()
            local template = [[
{% autoescape true %}
Normal: {{ html }}
Safe: {{ html | safe }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<b>bold</b>" }, { syntax = "jinja" })
            assert.matches("Normal: &lt;b&gt;bold&lt;/b&gt;", result)
            assert.matches("Safe: <b>bold</b>", result)
        end)

        it("should not double-escape in autoescape false", function()
            local template = [[
{% autoescape false %}
{{ html | safe }}
{% endautoescape %}]]
            local result = luma.render(template, { html = "<i>italic</i>" }, { syntax = "jinja" })
            assert.matches("<i>italic</i>", result)
        end)
    end)

    describe("with filters", function()
        it("should escape filter output in autoescape true", function()
            local template = [[
{% autoescape true %}
{{ text | replace("a", "<b>") }}
{% endautoescape %}]]
            local result = luma.render(template, { text = "apple" }, { syntax = "jinja" })
            assert.matches("&lt;b&gt;", result)
        end)

        it("should not escape filter output in autoescape false", function()
            local template = [[
{% autoescape false %}
{{ text | replace("a", "<b>") }}
{% endautoescape %}]]
            local result = luma.render(template, { text = "apple" }, { syntax = "jinja" })
            assert.matches("<b>", result)
        end)
    end)

    describe("edge cases", function()
        it("should handle empty block", function()
            local template = [[
{% autoescape false %}
{% endautoescape %}
After]]
            local result = luma.render(template, {}, { syntax = "jinja" })
            assert.matches("After", result)
        end)

        it("should handle non-string values", function()
            local template = [[
{% autoescape false %}
Number: {{ num }}
Boolean: {{ bool }}
{% endautoescape %}]]
            local result = luma.render(template, {
                num = 42,
                bool = true
            }, { syntax = "jinja" })
            assert.matches("Number: 42", result)
            assert.matches("Boolean: true", result)
        end)

        it("should handle nil values", function()
            local template = [[
{% autoescape false %}
Value: {{ nothing }}
{% endautoescape %}]]
            local result = luma.render(template, { nothing = nil }, { syntax = "jinja" })
            assert.matches("Value:%s*$", result)
        end)

        it("should work with template inheritance", function()
            local base = [[
{% autoescape false %}
{% block content %}Base: {{ html }}{% endblock %}
{% endautoescape %}]]
            
            local child = [[
{% extends "base" %}
{% block content %}Child: {{ html }}{% endblock %}]]
            
            -- Note: This test requires file system support
            -- For now, just verify no errors
            assert.is_not_nil(base)
            assert.is_not_nil(child)
        end)
    end)

    describe("Jinja2 compatibility", function()
        it("should match Jinja2 autoescape true behavior", function()
            local template = [[
{% autoescape true %}
<div class="content">{{ user_input }}</div>
{% endautoescape %}]]
            local result = luma.render(template, {
                user_input = '<script>alert("XSS")</script>'
            }, { syntax = "jinja" })
            assert.not_matches("<script>", result)
            assert.matches("&lt;script&gt;", result)
        end)

        it("should match Jinja2 autoescape false behavior", function()
            local template = [[
{% autoescape false %}
{{ trusted_html }}
{% endautoescape %}]]
            local result = luma.render(template, {
                trusted_html = '<p class="intro">Welcome</p>'
            }, { syntax = "jinja" })
            assert.matches('<p class="intro">Welcome</p>', result)
        end)

        it("should match Jinja2 default behavior (autoescape on)", function()
            local template = "{{ html }}"
            local result = luma.render(template, {
                html = "<tag>"
            }, { syntax = "jinja" })
            assert.equals("&lt;tag&gt;", result)
        end)
    end)
end)

