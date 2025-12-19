---@module lumalint
--- Lumalint - Linter for Luma templates
---
--- Checks templates for:
--- - Syntax errors
--- - Undefined variables
--- - Unused variables
--- - Missing filters
--- - Best practices violations
--- - Performance issues

local luma = require("luma")
local lexer = require("luma.lexer")
local parser = require("luma.parser")
local rules = require("lumalint.rules")

local lumalint = {}

---@class LintOptions
---@field rules table<string, boolean|table> Rule configuration
---@field ignore_vars table<string, boolean> Variables to ignore
---@field max_line_length number Maximum line length
---@field strict boolean Strict mode (treat warnings as errors)

--- Default linting options
lumalint.default_options = {
    rules = {
        ["undefined-variable"] = true,
        ["unused-variable"] = true,
        ["missing-filter"] = true,
        ["empty-block"] = true,
        ["duplicate-key"] = true,
        ["deprecated-syntax"] = true,
        ["max-line-length"] = { enabled = true, max = 120 },
        ["no-debug"] = true,
        ["prefer-explicit-autoescape"] = false,
    },
    ignore_vars = {
        -- Common Helm/Kubernetes variables
        Values = true,
        Chart = true,
        Release = true,
        Capabilities = true,
        Template = true,
        Files = true,
    },
    max_line_length = 120,
    strict = false,
}

---@class LintMessage
---@field rule string Rule name
---@field message string Error message
---@field line number Line number
---@field column number Column number
---@field severity string "error" | "warning" | "info"
---@field fix_suggestion string|nil Optional fix suggestion

--- Lint a template string
---@param source string Template source code
---@param filename string|nil Filename for error messages
---@param options LintOptions|nil Linting options
---@return LintMessage[] messages Lint messages
function lumalint.lint(source, filename, options)
    filename = filename or "<input>"
    options = options or lumalint.default_options

    local messages = {}

    -- Merge options with defaults
    local opts = {}
    for k, v in pairs(lumalint.default_options) do
        opts[k] = v
    end
    if options then
        for k, v in pairs(options) do
            opts[k] = v
        end
    end

    -- Try to parse the template
    local success, ast_or_error = pcall(function()
        local tokens = lexer.tokenize(source)
        return parser.parse(tokens, filename)
    end)

    if not success then
        -- Syntax error
        table.insert(messages, {
            rule = "syntax-error",
            message = tostring(ast_or_error),
            line = 1,
            column = 1,
            severity = "error",
        })
        return messages
    end

    local ast = ast_or_error

    -- Run all enabled rules
    for rule_name, rule_config in pairs(opts.rules) do
        local enabled = rule_config
        if type(rule_config) == "table" then
            enabled = rule_config.enabled ~= false
        end

        if enabled then
            local rule = rules[rule_name]
            if rule then
                local rule_messages = rule(ast, source, opts)
                for _, msg in ipairs(rule_messages) do
                    msg.rule = rule_name
                    table.insert(messages, msg)
                end
            end
        end
    end

    -- Sort messages by line, then column
    table.sort(messages, function(a, b)
        if a.line ~= b.line then
            return a.line < b.line
        end
        return a.column < b.column
    end)

    return messages
end

--- Lint a file
---@param filename string Path to template file
---@param options LintOptions|nil Linting options
---@return LintMessage[] messages Lint messages
function lumalint.lint_file(filename, options)
    local file = io.open(filename, "r")
    if not file then
        return {{
            rule = "file-not-found",
            message = "Failed to open file: " .. filename,
            line = 0,
            column = 0,
            severity = "error",
        }}
    end

    local source = file:read("*all")
    file:close()

    return lumalint.lint(source, filename, options)
end

--- Format lint messages for display
---@param messages LintMessage[] Lint messages
---@param filename string Filename for display
---@return string formatted Formatted messages
function lumalint.format_messages(messages, filename)
    if #messages == 0 then
        return filename .. ": ✓ No issues found"
    end

    local lines = {}
    table.insert(lines, filename .. ":")

    for _, msg in ipairs(messages) do
        local severity_icon = ({
            error = "✗",
            warning = "⚠",
            info = "ℹ",
        })[msg.severity] or "•"

        local line = string.format(
            "  %s %d:%d %s [%s]",
            severity_icon,
            msg.line,
            msg.column,
            msg.message,
            msg.rule
        )
        table.insert(lines, line)

        if msg.fix_suggestion then
            table.insert(lines, string.format("    Suggestion: %s", msg.fix_suggestion))
        end
    end

    return table.concat(lines, "\n")
end

return lumalint
