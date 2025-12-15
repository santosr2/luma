--- Expression parser for Luma
-- Parses expressions using recursive descent with operator precedence
-- @module luma.parser.expressions

local ast = require("luma.parser.ast")
local tokens = require("luma.lexer.tokens")
local errors = require("luma.utils.errors")

local T = tokens.types
local expressions = {}

--- Operator precedence levels (lower = binds tighter)
local PRECEDENCE = {
    OR = 1,
    AND = 2,
    COMPARISON = 3,  -- ==, !=, <, >, <=, >=
    CONCAT = 4,      -- ..
    ADDITIVE = 5,    -- +, -
    MULTIPLICATIVE = 6,  -- *, /, %
    POWER = 7,       -- ^
    UNARY = 8,       -- not, -
    CALL = 9,        -- (), [], .
    FILTER = 10,     -- |, |>
}

--- Binary operator mapping to AST operators
local BINARY_OPS = {
    [T.PLUS] = "+",
    [T.MINUS] = "-",
    [T.STAR] = "*",
    [T.SLASH] = "/",
    [T.PERCENT] = "%",
    [T.CARET] = "^",
    [T.CONCAT] = "..",
    [T.EQ] = "==",
    [T.NE] = "!=",
    [T.LT] = "<",
    [T.LE] = "<=",
    [T.GT] = ">",
    [T.GE] = ">=",
    [T.AND] = "and",
    [T.OR] = "or",
    [T.IN] = "in",
    [T.NOT_IN] = "not_in",
}

--- Get precedence for a token type
local function get_precedence(token_type)
    if token_type == T.OR then
        return PRECEDENCE.OR
    elseif token_type == T.AND then
        return PRECEDENCE.AND
    elseif token_type == T.EQ or token_type == T.NE or
           token_type == T.LT or token_type == T.LE or
           token_type == T.GT or token_type == T.GE or
           token_type == T.IN or token_type == T.NOT_IN then
        return PRECEDENCE.COMPARISON
    elseif token_type == T.CONCAT then
        return PRECEDENCE.CONCAT
    elseif token_type == T.PLUS or token_type == T.MINUS then
        return PRECEDENCE.ADDITIVE
    elseif token_type == T.STAR or token_type == T.SLASH or token_type == T.PERCENT then
        return PRECEDENCE.MULTIPLICATIVE
    elseif token_type == T.CARET then
        return PRECEDENCE.POWER
    elseif token_type == T.PIPE or token_type == T.PIPE_ARROW then
        return PRECEDENCE.FILTER
    end
    return 0
end

--- Parse a primary expression (literals, identifiers, parenthesized)
-- @param stream table Token stream
-- @return table AST node
function expressions.parse_primary(stream)
    local token = stream:peek()

    if not token then
        errors.raise(errors.parse("Unexpected end of input", nil, nil))
    end

    -- Literals
    if token.type == T.NUMBER then
        stream:advance()
        return ast.literal(token.value, "number", token.line, token.column)
    end

    if token.type == T.STRING then
        stream:advance()
        return ast.literal(token.value, "string", token.line, token.column)
    end

    if token.type == T.BOOLEAN then
        stream:advance()
        return ast.literal(token.value, "boolean", token.line, token.column)
    end

    if token.type == T.NIL then
        stream:advance()
        return ast.literal(nil, "nil", token.line, token.column)
    end

    -- Identifiers
    if token.type == T.IDENT then
        stream:advance()
        return ast.identifier(token.value, token.line, token.column)
    end

    -- Parenthesized expression
    if token.type == T.LPAREN then
        stream:advance()  -- skip (
        local expr = expressions.parse(stream)
        stream:expect(T.RPAREN, "Expected ')' after expression")
        return expr
    end

    -- Array literal [a, b, c]
    if token.type == T.LBRACKET then
        return expressions.parse_array(stream)
    end

    -- Table literal {key: value}
    if token.type == T.LBRACE then
        return expressions.parse_table(stream)
    end

    errors.raise(errors.parse(
        "Unexpected token: " .. tokens.type_name(token.type),
        token.line, token.column
    ))
end

--- Parse an array literal [a, b, c]
-- @param stream table Token stream
-- @return table AST node
function expressions.parse_array(stream)
    local start = stream:advance()  -- skip [
    local entries = {}

    while not stream:check(T.RBRACKET) and not stream:is_eof() do
        local value = expressions.parse(stream)
        table.insert(entries, { key = nil, value = value })

        if not stream:match(T.COMMA) then
            break
        end
    end

    stream:expect(T.RBRACKET, "Expected ']' after array")
    return ast.table_literal(entries, true, start.line, start.column)
end

--- Parse a table literal {key: value}
-- @param stream table Token stream
-- @return table AST node
function expressions.parse_table(stream)
    local start = stream:advance()  -- skip {
    local entries = {}

    while not stream:check(T.RBRACE) and not stream:is_eof() do
        local key
        local value

        -- Check for key: value or just value
        if stream:check(T.IDENT) or stream:check(T.STRING) then
            local maybe_key = stream:advance()

            if stream:check(T.COLON) then
                -- key: value
                stream:advance()  -- skip :
                if maybe_key.type == T.IDENT then
                    key = ast.literal(maybe_key.value, "string", maybe_key.line, maybe_key.column)
                else
                    key = ast.literal(maybe_key.value, "string", maybe_key.line, maybe_key.column)
                end
                value = expressions.parse(stream)
            else
                -- Just a value, restore and parse as expression
                -- We need to handle this case - the token was consumed
                -- Create an identifier or literal from it
                if maybe_key.type == T.IDENT then
                    value = ast.identifier(maybe_key.value, maybe_key.line, maybe_key.column)
                else
                    value = ast.literal(maybe_key.value, "string", maybe_key.line, maybe_key.column)
                end
                -- Parse rest of expression if any
                value = expressions.parse_postfix(stream, value)
            end
        else
            value = expressions.parse(stream)
        end

        table.insert(entries, { key = key, value = value })

        if not stream:match(T.COMMA) then
            break
        end
    end

    stream:expect(T.RBRACE, "Expected '}' after table")
    return ast.table_literal(entries, false, start.line, start.column)
end

--- Parse postfix operators (calls, member access, index access)
-- @param stream table Token stream
-- @param expr table Current expression
-- @return table AST node
function expressions.parse_postfix(stream, expr)
    while true do
        local token = stream:peek()

        if not token then
            break
        end

        -- Member access: expr.member
        if token.type == T.DOT then
            stream:advance()
            local member = stream:expect(T.IDENT, "Expected identifier after '.'")
            expr = ast.member_access(expr, member.value, token.line, token.column)

        -- Index access: expr[index]
        elseif token.type == T.LBRACKET then
            stream:advance()
            local index = expressions.parse(stream)
            stream:expect(T.RBRACKET, "Expected ']' after index")
            expr = ast.index_access(expr, index, token.line, token.column)

        -- Function call: expr(args)
        elseif token.type == T.LPAREN then
            stream:advance()
            local positional_args, named_args = expressions.parse_args(stream)
            stream:expect(T.RPAREN, "Expected ')' after arguments")
            expr = ast.function_call(expr, positional_args, named_args, token.line, token.column)

        else
            break
        end
    end

    return expr
end

--- Parse function arguments
-- Supports both positional and named arguments (Jinja2 style)
-- @param stream table Token stream
-- @return table Array of positional argument expressions
-- @return table|nil Table of named arguments (name -> expression) or nil
function expressions.parse_args(stream)
    local positional_args = {}
    local named_args = nil

    if stream:check(T.RPAREN) then
        return positional_args, named_args
    end

    local seen_named = false

    while true do
        -- Check if this is a named argument (name=value)
        local is_named = false
        local arg_name = nil
        
        if stream:check(T.IDENT) then
            -- Look ahead to see if next token is '='
            local saved_pos = stream.pos
            local ident = stream:advance()
            if stream:check(T.ASSIGN) then
                -- This is a named argument
                is_named = true
                arg_name = ident.value
                stream:advance()  -- skip '='
                seen_named = true
            else
                -- Not a named arg, restore position
                stream.pos = saved_pos
            end
        end

        if is_named then
            -- Parse named argument value
            local value = expressions.parse(stream)
            if not named_args then
                named_args = {}
            end
            named_args[arg_name] = value
        else
            -- Parse positional argument
            if seen_named then
                errors.raise(errors.parse("Positional arguments must come before named arguments", 
                    stream:peek().line, stream:peek().column))
            end
            local arg = expressions.parse(stream)
            table.insert(positional_args, arg)
        end

        if not stream:match(T.COMMA) then
            break
        end
    end

    return positional_args, named_args
end

--- Parse unary operators (not, -, #)
-- @param stream table Token stream
-- @return table AST node
function expressions.parse_unary(stream)
    local token = stream:peek()

    if token and token.type == T.NOT then
        stream:advance()
        local operand = expressions.parse_unary(stream)
        return ast.unary_op("not", operand, token.line, token.column)
    end

    if token and token.type == T.MINUS then
        stream:advance()
        local operand = expressions.parse_unary(stream)
        return ast.unary_op("-", operand, token.line, token.column)
    end

    if token and token.type == T.HASH then
        stream:advance()
        local operand = expressions.parse_unary(stream)
        return ast.unary_op("#", operand, token.line, token.column)
    end

    local expr = expressions.parse_primary(stream)
    return expressions.parse_postfix(stream, expr)
end

--- Parse filters (expr | filter or expr |> filter())
-- @param stream table Token stream
-- @param expr table Current expression
-- @return table AST node
function expressions.parse_filters(stream, expr)
    while true do
        local token = stream:peek()

        if not token then
            break
        end

        -- Simple filter: expr | filter or expr | filter(args)
        if token.type == T.PIPE then
            stream:advance()
            local filter_name = stream:expect(T.IDENT, "Expected filter name after '|'")
            local positional_args = {}
            local named_args = nil

            -- Optional arguments
            if stream:check(T.LPAREN) then
                stream:advance()
                positional_args, named_args = expressions.parse_args(stream)
                stream:expect(T.RPAREN, "Expected ')' after filter arguments")
            end

            expr = ast.filter(expr, filter_name.value, positional_args, named_args, token.line, token.column)

        -- Pipeline: expr |> filter()
        elseif token.type == T.PIPE_ARROW then
            stream:advance()
            local filter_expr = expressions.parse_unary(stream)
            expr = ast.pipeline(expr, filter_expr, token.line, token.column)

        else
            break
        end
    end

    return expr
end

--- Parse a binary expression with precedence climbing
-- @param stream table Token stream
-- @param min_prec number Minimum precedence to parse
-- @return table AST node
function expressions.parse_binary(stream, min_prec)
    local left = expressions.parse_unary(stream)
    left = expressions.parse_filters(stream, left)

    while true do
        local token = stream:peek()
        if not token then
            break
        end

        -- Check for 'is' test expression
        if token.type == T.IS then
            left = expressions.parse_test(stream, left)
            token = stream:peek()
            if not token then
                break
            end
        end

        local prec = get_precedence(token.type)
        if prec == 0 or prec < min_prec then
            break
        end

        local op = BINARY_OPS[token.type]
        if not op then
            break
        end

        stream:advance()

        -- Right associative for power operator
        local next_prec = prec
        if token.type == T.CARET then
            next_prec = prec  -- Right associative
        else
            next_prec = prec + 1  -- Left associative
        end

        local right = expressions.parse_binary(stream, next_prec)
        left = ast.binary_op(op, left, right, token.line, token.column)
    end

    return left
end

--- Parse a test expression (is / is not)
-- @param stream table Token stream
-- @param expr table Expression being tested
-- @return table AST test node
function expressions.parse_test(stream, expr)
    local is_token = stream:advance()  -- consume 'is'
    local negated = false

    -- Check for 'not' (is not)
    if stream:check(T.NOT) then
        stream:advance()
        negated = true
    end

    -- Parse test name - can be IDENT, BOOLEAN (true/false), NIL, or IN (for 'is in' test)
    local test_name_token = stream:peek()
    local test_name
    if test_name_token.type == T.IDENT then
        stream:advance()
        test_name = test_name_token.value
    elseif test_name_token.type == T.BOOLEAN then
        stream:advance()
        test_name = test_name_token.value and "true" or "false"
    elseif test_name_token.type == T.NIL then
        stream:advance()
        test_name = "nil"
    elseif test_name_token.type == T.IN then
        -- Special case: "is in" test (Jinja2 compatibility)
        stream:advance()
        test_name = "in"
    else
        errors.raise(errors.parse("Expected test name after 'is'", test_name_token.line, test_name_token.column))
    end

    local positional_args = {}
    local named_args = nil

    -- Optional arguments in parentheses
    if stream:check(T.LPAREN) then
        stream:advance()
        positional_args, named_args = expressions.parse_args(stream)
        stream:expect(T.RPAREN, "Expected ')' after test arguments")
    end

    -- Tests typically don't use named arguments, but we pass them anyway for consistency
    return ast.test(expr, test_name, positional_args, negated, is_token.line, is_token.column)
end

--- Parse a full expression
-- @param stream table Token stream
-- @return table AST node
function expressions.parse(stream)
    return expressions.parse_binary(stream, 1)
end

--- Parse a simple path expression from a token value (e.g., "foo.bar.baz")
-- Used for $var.path interpolation
-- @param path string Path string like "foo.bar.baz"
-- @param line number Line number
-- @param column number Column number
-- @return table AST node
function expressions.parse_path(path, line, column)
    local parts = {}
    for part in path:gmatch("[^.]+") do
        table.insert(parts, part)
    end

    if #parts == 0 then
        errors.raise(errors.parse("Empty path", line, column))
    end

    local result = ast.identifier(parts[1], line, column)

    for i = 2, #parts do
        result = ast.member_access(result, parts[i], line, column)
    end

    return result
end

return expressions
