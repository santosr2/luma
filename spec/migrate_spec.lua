--- Tests for Jinja2 → Luma migration
-- @module spec.migrate_spec

local converter = require("cli.migrate.converter")

describe("Jinja2 to Luma Migration", function()
    describe("Variable interpolation", function()
        it("should convert simple variable {{ var }} to $var", function()
            local jinja = "Hello {{ name }}!"
            local luma = converter.convert(jinja)
            assert.equals("Hello $name!", luma)
        end)

        it("should convert property access {{ user.name }} to $user.name", function()
            local jinja = "Hello {{ user.name }}!"
            local luma = converter.convert(jinja)
            assert.equals("Hello $user.name!", luma)
        end)

        it("should convert complex expressions {{ x + y }} to ${x + y}", function()
            local jinja = "Result: {{ x + y }}"
            local luma = converter.convert(jinja)
            assert.equals("Result: ${x + y}", luma)
        end)

        it("should convert filter {{ name | upper }} to ${name | upper}", function()
            local jinja = "Hello {{ name | upper }}!"
            local luma = converter.convert(jinja)
            assert.equals("Hello ${name | upper}!", luma)
        end)

        it("should convert multiple filters", function()
            local jinja = "{{ text | trim | upper }}"
            local luma = converter.convert(jinja)
            assert.equals("${text | trim | upper}", luma)
        end)
    end)

    describe("Control structures", function()
        it("should convert {% if %} to @if", function()
            local jinja = "{% if show %}Yes{% endif %}"
            local luma = converter.convert(jinja)
            assert.equals("@if show\nYes\n@end\n", luma)
        end)

        it("should convert {% if %} {% else %} to @if @else", function()
            local jinja = "{% if show %}Yes{% else %}No{% endif %}"
            local luma = converter.convert(jinja)
            assert.equals("@if show\nYes\n@else\nNo\n@end\n", luma)
        end)

        it("should convert {% if %} {% elif %} {% else %}", function()
            local jinja = "{% if x == 1 %}One{% elif x == 2 %}Two{% else %}Other{% endif %}"
            local luma = converter.convert(jinja)
            assert.equals("@if x == 1\nOne\n@elif x == 2\nTwo\n@else\nOther\n@end\n", luma)
        end)

        it("should convert {% for %} to @for", function()
            local jinja = "{% for item in items %}{{ item }}{% endfor %}"
            local luma = converter.convert(jinja)
            assert.equals("@for item in items\n$item\n@end\n", luma)
        end)

        it("should convert {% for %} with else", function()
            local jinja = "{% for item in items %}{{ item }}{% else %}Empty{% endfor %}"
            local luma = converter.convert(jinja)
            assert.equals("@for item in items\n$item\n@else\nEmpty\n@end\n", luma)
        end)

        it("should convert {% set %} to @let", function()
            local jinja = "{% set x = 5 %}"
            local luma = converter.convert(jinja)
            assert.equals("@let x = 5\n", luma)
        end)
    end)

    describe("Template features", function()
        it("should convert {% macro %} to @macro", function()
            local jinja = "{% macro button() %}Click{% endmacro %}"
            local luma = converter.convert(jinja)
            assert.equals("@macro button()\nClick\n@end\n", luma)
        end)

        it("should convert {% extends %} to @extends", function()
            local jinja = '{% extends "base.html" %}'
            local luma = converter.convert(jinja)
            assert.equals('@extends "base.html"\n', luma)
        end)

        it("should convert {% block %} to @block", function()
            local jinja = "{% block content %}Text{% endblock %}"
            local luma = converter.convert(jinja)
            assert.equals("@block content\nText\n@end\n", luma)
        end)

        it("should convert {% include %} to @include", function()
            local jinja = '{% include "partial.html" %}'
            local luma = converter.convert(jinja)
            assert.equals('@include "partial.html"\n', luma)
        end)

        it("should convert {% break %} to @break", function()
            local jinja = "{% for i in items %}{% if i == 5 %}{% break %}{% endif %}{% endfor %}"
            local luma = converter.convert(jinja)
            assert.match("@break", luma)
        end)

        it("should convert {% continue %} to @continue", function()
            local jinja = "{% for i in items %}{% if i == 5 %}{% continue %}{% endif %}{% endfor %}"
            local luma = converter.convert(jinja)
            assert.match("@continue", luma)
        end)
    end)

    describe("Comments", function()
        it("should convert {# comment #} to @#", function()
            local jinja = "{# This is a comment #}"
            local luma = converter.convert(jinja)
            assert.equals("@#  This is a comment ", luma)
        end)
    end)

    describe("Complex templates", function()
        it("should handle nested structures", function()
            local jinja = [[
{% for user in users %}
  {% if user.active %}
    Hello {{ user.name | upper }}!
  {% endif %}
{% endfor %}
]]
            local luma = converter.convert(jinja)

            assert.match("@for user in users", luma)
            assert.match("@if user.active", luma)
            assert.match("$%{user%.name | upper%}", luma)
            assert.match("@end", luma)
        end)

        it("should handle template inheritance", function()
            local jinja = [[
{% extends "base.html" %}

{% block title %}My Page{% endblock %}

{% block content %}
  <h1>{{ page.title }}</h1>
  <p>{{ page.content }}</p>
{% endblock %}
]]
            local luma = converter.convert(jinja)

            assert.match('@extends "base.html"', luma)
            assert.match("@block title", luma)
            assert.match("@block content", luma)
            assert.match("$page.title", luma)
            assert.match("$page.content", luma)
        end)
    end)

    describe("Error handling", function()
        it("should return error for unsupported conversions", function()
            local result, err = converter.convert("test", { from = "luma", to = "jinja" })
            assert.is_nil(result)
            assert.matches("Only Jinja2 .* Luma", err)
        end)
    end)
end)
