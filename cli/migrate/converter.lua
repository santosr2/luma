--- Converter for Jinja2 → Luma syntax transformation
-- Uses AST-based conversion for accuracy
-- @module cli.migrate.converter

local luma = require("luma")
local formatter = require("cli.migrate.formatter")

local converter = {}

--- Convert template from one syntax to another
-- @param source string Template source code
-- @param options table Conversion options
-- @return string|nil Converted template or nil on error
-- @return string|nil Error message if conversion failed
function converter.convert(source, options)
    options = options or {}
    local from = options.from or "auto"
    local to = options.to or "luma"

    -- Auto-detect source syntax if needed
    if from == "auto" then
        if source:match("{{") or source:match("{%%") or source:match("{#") then
            from = "jinja"
        else
            from = "luma"
        end
    end

    -- Nothing to do if already in target syntax
    if from == to then
        return source
    end

    -- Currently only support jinja → luma
    if from ~= "jinja" or to ~= "luma" then
        return nil, "Only Jinja2 → Luma conversion is currently supported"
    end

    -- Parse with Jinja lexer
    local ok, result = pcall(function()
        local tokens = luma.tokenize(source, { syntax = "jinja" })
        return formatter.tokens_to_luma(tokens, source)
    end)

    if not ok then
        return nil, result
    end

    return result
end

return converter
