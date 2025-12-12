--- Formatter to convert tokens to Luma syntax
-- @module cli.migrate.formatter

local T = require("luma.lexer.tokens").types

local formatter = {}

--- Convert token stream to Luma syntax
-- @param tokens table Array of tokens
-- @param source string Original source (for reference)
-- @return string Luma syntax output
function formatter.tokens_to_luma(tokens, source)
    local parts = {}
    local i = 1

    while i <= #tokens do
        local token = tokens[i]

        if token.type == T.TEXT then
            table.insert(parts, token.value)

        elseif token.type == T.INTERP_START then
            -- {{ expr }} → ${expr} or $var
            i = i + 1
            local expr_tokens = {}
            
            -- Collect expression tokens until INTERP_END
            while i <= #tokens and tokens[i].type ~= T.INTERP_END do
                table.insert(expr_tokens, tokens[i])
                i = i + 1
            end

            -- Try to simplify to $var if possible
            if #expr_tokens == 1 and expr_tokens[1].type == T.IDENT then
                table.insert(parts, "$" .. expr_tokens[1].value)
            elseif #expr_tokens >= 1 then
                -- Check if it's a simple path: var.foo.bar
                local is_simple_path = true
                for j, t in ipairs(expr_tokens) do
                    if j % 2 == 1 then
                        -- Odd positions should be IDENT
                        if t.type ~= T.IDENT then
                            is_simple_path = false
                            break
                        end
                    else
                        -- Even positions should be DOT
                        if t.type ~= T.DOT then
                            is_simple_path = false
                            break
                        end
                    end
                end

                if is_simple_path and #expr_tokens % 2 == 1 then
                    -- Simple path: $var.foo.bar
                    local path = {}
                    for j = 1, #expr_tokens, 2 do
                        table.insert(path, expr_tokens[j].value)
                    end
                    table.insert(parts, "$" .. table.concat(path, "."))
                else
                    -- Complex expression: ${...}
                    table.insert(parts, "${")
                    table.insert(parts, formatter.format_expression(expr_tokens))
                    table.insert(parts, "}")
                end
            end

        elseif token.type == T.DIR_IF then
            -- {% if x %} → @if x
            table.insert(parts, "@if ")
            i = i + 1
            
            -- Collect condition tokens until NEWLINE
            local cond_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(cond_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(cond_tokens))

        elseif token.type == T.DIR_ELIF then
            table.insert(parts, "@elif ")
            i = i + 1
            
            local cond_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(cond_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(cond_tokens))

        elseif token.type == T.DIR_ELSE then
            table.insert(parts, "@else")

        elseif token.type == T.DIR_END or token.type == T.DIR_ENDBLOCK then
            table.insert(parts, "@end")

        elseif token.type == T.DIR_FOR then
            -- {% for x in y %} → @for x in y
            table.insert(parts, "@for ")
            i = i + 1
            
            local for_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(for_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(for_tokens))

        elseif token.type == T.DIR_LET then
            -- {% set x = y %} → @let x = y
            table.insert(parts, "@let ")
            i = i + 1
            
            local let_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(let_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(let_tokens))

        elseif token.type == T.DIR_MACRO then
            -- {% macro name() %} → @macro name()
            table.insert(parts, "@macro ")
            i = i + 1
            
            local macro_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(macro_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(macro_tokens))

        elseif token.type == T.DIR_CALL then
            table.insert(parts, "@call ")
            i = i + 1
            
            local call_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(call_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(call_tokens))

        elseif token.type == T.DIR_INCLUDE then
            table.insert(parts, "@include ")
            i = i + 1
            
            local inc_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(inc_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(inc_tokens))

        elseif token.type == T.DIR_EXTENDS then
            table.insert(parts, "@extends ")
            i = i + 1
            
            local ext_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(ext_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(ext_tokens))

        elseif token.type == T.DIR_BLOCK then
            table.insert(parts, "@block ")
            i = i + 1
            
            local block_tokens = {}
            while i <= #tokens and tokens[i].type ~= T.NEWLINE do
                table.insert(block_tokens, tokens[i])
                i = i + 1
            end
            table.insert(parts, formatter.format_expression(block_tokens))

        elseif token.type == T.DIR_BREAK then
            table.insert(parts, "@break")

        elseif token.type == T.DIR_CONTINUE then
            table.insert(parts, "@continue")

        elseif token.type == T.DIR_COMMENT then
            table.insert(parts, "@# " .. (token.value or ""))

        elseif token.type == T.NEWLINE then
            -- Directive completed, add newline if needed
            table.insert(parts, "\n")

        elseif token.type == T.EOF then
            -- End of file
            break
        end

        i = i + 1
    end

    return table.concat(parts)
end

--- Format an expression from tokens
-- @param tokens table Array of expression tokens
-- @return string Formatted expression
function formatter.format_expression(tokens)
    local parts = {}

    for _, token in ipairs(tokens) do
        if token.type == T.IDENT then
            table.insert(parts, token.value)
        elseif token.type == T.NUMBER then
            table.insert(parts, tostring(token.value))
        elseif token.type == T.STRING then
            -- Preserve original quotes if possible, default to double
            table.insert(parts, '"' .. token.value:gsub('"', '\\"') .. '"')
        elseif token.type == T.BOOLEAN then
            table.insert(parts, token.value and "true" or "false")
        elseif token.type == T.NIL then
            table.insert(parts, "nil")
        elseif token.type == T.PIPE then
            table.insert(parts, " | ")
        elseif token.type == T.DOT then
            table.insert(parts, ".")
        elseif token.type == T.COMMA then
            table.insert(parts, ", ")
        elseif token.type == T.COLON then
            table.insert(parts, ": ")
        elseif token.type == T.LPAREN then
            table.insert(parts, "(")
        elseif token.type == T.RPAREN then
            table.insert(parts, ")")
        elseif token.type == T.LBRACKET then
            table.insert(parts, "[")
        elseif token.type == T.RBRACKET then
            table.insert(parts, "]")
        elseif token.type == T.LBRACE then
            table.insert(parts, "{")
        elseif token.type == T.RBRACE then
            table.insert(parts, "}")
        elseif token.type == T.PLUS then
            table.insert(parts, " + ")
        elseif token.type == T.MINUS then
            table.insert(parts, " - ")
        elseif token.type == T.STAR then
            table.insert(parts, " * ")
        elseif token.type == T.SLASH then
            table.insert(parts, " / ")
        elseif token.type == T.PERCENT then
            table.insert(parts, " % ")
        elseif token.type == T.CARET then
            table.insert(parts, " ^ ")
        elseif token.type == T.EQ then
            table.insert(parts, " == ")
        elseif token.type == T.NE then
            table.insert(parts, " != ")
        elseif token.type == T.LT then
            table.insert(parts, " < ")
        elseif token.type == T.LE then
            table.insert(parts, " <= ")
        elseif token.type == T.GT then
            table.insert(parts, " > ")
        elseif token.type == T.GE then
            table.insert(parts, " >= ")
        elseif token.type == T.AND then
            table.insert(parts, " and ")
        elseif token.type == T.OR then
            table.insert(parts, " or ")
        elseif token.type == T.NOT then
            table.insert(parts, "not ")
        elseif token.type == T.IN then
            table.insert(parts, " in ")
        elseif token.type == T.NOT_IN then
            table.insert(parts, " not in ")
        elseif token.type == T.IS then
            table.insert(parts, " is ")
        elseif token.type == T.ASSIGN then
            table.insert(parts, " = ")
        end
    end

    return table.concat(parts)
end

return formatter

