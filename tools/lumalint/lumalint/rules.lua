---@module lumalint.rules
--- Linting rules for Lumalint

local N = require("luma.parser.ast")

local rules = {}

--- Helper to walk AST nodes
local function walk_ast(node, callback)
    if not node then
        return
    end

    callback(node)

    -- Recursively walk children based on node type
    if node.type == N.BLOCK or node.type == N.ROOT then
        for _, child in ipairs(node.body or {}) do
            walk_ast(child, callback)
        end
    elseif node.type == N.IF then
        walk_ast(node.consequent, callback)
        if node.alternative then
            walk_ast(node.alternative, callback)
        end
    elseif node.type == N.FOR then
        walk_ast(node.body, callback)
    elseif node.type == N.MACRO then
        walk_ast(node.body, callback)
    elseif node.type == N.CALL then
        if node.body then
            walk_ast(node.body, callback)
        end
    end
end

--- Check for undefined variables
rules["undefined-variable"] = function(ast, source, options)
    local messages = {}
    local defined_vars = {}

    -- Add ignored variables
    for var in pairs(options.ignore_vars or {}) do
        defined_vars[var] = true
    end

    -- First pass: collect defined variables
    walk_ast(ast, function(node)
        if node.type == N.LET then
            defined_vars[node.name] = true
        elseif node.type == N.FOR then
            if type(node.var) == "string" then
                defined_vars[node.var] = true
            elseif type(node.var) == "table" then
                for _, v in ipairs(node.var) do
                    defined_vars[v] = true
                end
            end
        elseif node.type == N.MACRO then
            defined_vars[node.name] = true
            -- Parameters are also defined
            for _, param in ipairs(node.params or {}) do
                defined_vars[param.name or param] = true
            end
        end
    end)

    -- Second pass: check usage
    walk_ast(ast, function(node)
        if node.type == N.VARIABLE then
            local var_name = node.name
            -- Extract root variable name (before dots)
            local root_var = var_name:match("^([^.%[]+)")

            if not defined_vars[root_var] then
                table.insert(messages, {
                    message = string.format("Undefined variable '%s'", var_name),
                    line = node.line or 1,
                    column = node.column or 1,
                    severity = "warning",
                    fix_suggestion = string.format("Define '%s' with @let or pass in context", root_var),
                })
            end
        end
    end)

    return messages
end

--- Check for unused variables
rules["unused-variable"] = function(ast, source, options)
    local messages = {}
    local defined_vars = {}
    local used_vars = {}

    -- Collect defined variables
    walk_ast(ast, function(node)
        if node.type == N.LET then
            table.insert(defined_vars, {
                name = node.name,
                line = node.line or 1,
                column = node.column or 1,
            })
        end
    end)

    -- Collect used variables
    walk_ast(ast, function(node)
        if node.type == N.VARIABLE then
            local root_var = node.name:match("^([^.%[]+)")
            used_vars[root_var] = true
        end
    end)

    -- Check for unused
    for _, var in ipairs(defined_vars) do
        if not used_vars[var.name] then
            table.insert(messages, {
                message = string.format("Variable '%s' is defined but never used", var.name),
                line = var.line,
                column = var.column,
                severity = "info",
                fix_suggestion = "Remove unused variable or use it in template",
            })
        end
    end

    return messages
end

--- Check for empty blocks
rules["empty-block"] = function(ast, source, options)
    local messages = {}

    walk_ast(ast, function(node)
        local is_empty = false
        local node_name = ""

        if node.type == N.IF then
            if node.consequent and #(node.consequent.body or {}) == 0 then
                is_empty = true
                node_name = "if"
            end
        elseif node.type == N.FOR then
            if node.body and #(node.body.body or {}) == 0 then
                is_empty = true
                node_name = "for"
            end
        elseif node.type == N.MACRO then
            if node.body and #(node.body.body or {}) == 0 then
                is_empty = true
                node_name = "macro"
            end
        end

        if is_empty then
            table.insert(messages, {
                message = string.format("Empty %s block", node_name),
                line = node.line or 1,
                column = node.column or 1,
                severity = "warning",
                fix_suggestion = "Add content or remove empty block",
            })
        end
    end)

    return messages
end

--- Check for maximum line length
rules["max-line-length"] = function(ast, source, options)
    local messages = {}
    local max_length = options.max_line_length or 120

    if type(options.rules["max-line-length"]) == "table" then
        max_length = options.rules["max-line-length"].max or max_length
    end

    local line_num = 1
    for line in source:gmatch("([^\n]*)\n?") do
        if #line > max_length then
            table.insert(messages, {
                message = string.format("Line too long (%d > %d)", #line, max_length),
                line = line_num,
                column = max_length + 1,
                severity = "info",
                fix_suggestion = "Break line into multiple lines",
            })
        end
        line_num = line_num + 1
    end

    return messages
end

--- Check for debug statements
rules["no-debug"] = function(ast, source, options)
    local messages = {}

    -- Check for common debug patterns in source
    local debug_patterns = {
        "print%s*%(",
        "console%.log%s*%(",
        "debug%s*%(",
        "@do%s+print",
    }

    local line_num = 1
    for line in source:gmatch("([^\n]*)\n?") do
        for _, pattern in ipairs(debug_patterns) do
            if line:match(pattern) then
                table.insert(messages, {
                    message = "Debug statement found",
                    line = line_num,
                    column = 1,
                    severity = "warning",
                    fix_suggestion = "Remove debug statement before production",
                })
                break
            end
        end
        line_num = line_num + 1
    end

    return messages
end

--- Check for deprecated syntax
rules["deprecated-syntax"] = function(ast, source, options)
    local messages = {}

    -- Check for old-style syntax patterns
    local line_num = 1
    for line in source:gmatch("([^\n]*)\n?") do
        -- Example: check for old variable syntax if any
        -- This is a placeholder for future deprecations

        line_num = line_num + 1
    end

    return messages
end

return rules
