--- Parser module for Luma
-- Converts token stream into Abstract Syntax Tree
-- @module luma.parser

local ast = require("luma.parser.ast")
local expressions = require("luma.parser.expressions")
local lexer = require("luma.lexer")
local tokens = require("luma.lexer.tokens")
local errors = require("luma.utils.errors")

local T = tokens.types
local parser = {}

-- Re-export AST module
parser.ast = ast
parser.expressions = expressions

--- Parse a template from source string
-- @param source string Template source code
-- @param options table|nil Parser options
-- @return table AST root node
function parser.parse(source, options)
    options = options or {}
    local token_list = lexer.tokenize(source, options)
    local stream = lexer.stream(token_list)
    return parser.parse_template(stream)
end

--- Parse a template from token stream
-- @param stream table Token stream
-- @return table Template AST node
function parser.parse_template(stream)
    local body = parser.parse_body(stream, nil)
    return ast.template(body, 1)
end

--- Parse template body until end condition
-- @param stream table Token stream
-- @param end_tokens table|nil Token types that end this body
-- @return table Array of AST nodes
function parser.parse_body(stream, end_tokens)
    local body = {}

    while not stream:is_eof() do
        -- Check for end condition
        if end_tokens then
            local current = stream:peek()
            for _, end_type in ipairs(end_tokens) do
                if current and current.type == end_type then
                    return body
                end
            end
        end

        local node = parser.parse_node(stream)
        if node then
            table.insert(body, node)
        end
    end

    return body
end

--- Parse a single node
-- @param stream table Token stream
-- @return table|nil AST node or nil
function parser.parse_node(stream)
    local token = stream:peek()

    if not token or token.type == T.EOF then
        return nil
    end

    -- Text content
    if token.type == T.TEXT then
        stream:advance()
        return ast.text(token.value, token.line, token.column)
    end

    -- Simple interpolation $var.path
    if token.type == T.INTERP_SIMPLE then
        stream:advance()
        local expr = expressions.parse_path(token.value, token.line, token.column)
        return ast.interpolation(expr, token.line, token.column)
    end

    -- Expression interpolation ${expr}
    if token.type == T.INTERP_START then
        return parser.parse_interpolation(stream)
    end

    -- Directives
    if token.type == T.DIR_IF then
        return parser.parse_if(stream)
    end

    if token.type == T.DIR_FOR then
        return parser.parse_for(stream)
    end

    if token.type == T.DIR_LET then
        return parser.parse_let(stream)
    end

    if token.type == T.DIR_MACRO then
        return parser.parse_macro(stream)
    end

    if token.type == T.DIR_CALL then
        return parser.parse_call(stream)
    end

    if token.type == T.DIR_INCLUDE then
        return parser.parse_include(stream)
    end

    if token.type == T.DIR_IMPORT then
        return parser.parse_import(stream)
    end

    if token.type == T.DIR_FROM then
        return parser.parse_from(stream)
    end

    if token.type == T.DIR_EXTENDS then
        return parser.parse_extends(stream)
    end

    if token.type == T.DIR_BLOCK then
        return parser.parse_block(stream)
    end

    if token.type == T.DIR_RAW then
        return parser.parse_raw(stream)
    end

    if token.type == T.DIR_AUTOESCAPE then
        return parser.parse_autoescape(stream)
    end

    if token.type == T.DIR_COMMENT then
        stream:advance()
        return ast.comment(token.value, token.line, token.column)
    end

    if token.type == T.DIR_BREAK then
        stream:advance()
        return ast.break_node(token.line, token.column)
    end

    if token.type == T.DIR_CONTINUE then
        stream:advance()
        return ast.continue_node(token.line, token.column)
    end

    -- Newlines in directive mode
    if token.type == T.NEWLINE then
        stream:advance()
        return nil
    end

    -- Unexpected token - skip it
    stream:advance()
    return nil
end

--- Parse expression interpolation ${...}
-- @param stream table Token stream
-- @return table Interpolation AST node
function parser.parse_interpolation(stream)
    local start = stream:advance()  -- skip INTERP_START
    local expr = expressions.parse(stream)
    stream:expect(T.INTERP_END, "Expected '}' to close interpolation")
    return ast.interpolation(expr, start.line, start.column)
end

--- Parse @if directive
-- @param stream table Token stream
-- @return table If AST node
function parser.parse_if(stream)
    local start = stream:advance()  -- skip DIR_IF
    local is_inline = start.inline

    -- Parse condition
    local condition = expressions.parse(stream)

    -- Skip newline after condition (unless inline mode)
    if not is_inline then
        stream:match(T.NEWLINE)
    end

    -- Parse then body until @elif, @else, or @end
    local then_body = parser.parse_body(stream, { T.DIR_ELIF, T.DIR_ELSE, T.DIR_END })

    local else_body = nil
    local current = stream:peek()

    -- Handle @elif
    if current and current.type == T.DIR_ELIF then
        -- Parse as nested if
        else_body = parser.parse_if(stream)
    elseif current and current.type == T.DIR_ELSE then
        local else_token = stream:advance()  -- skip @else
        if not else_token.inline then
            stream:match(T.NEWLINE)
        end
        else_body = parser.parse_body(stream, { T.DIR_END })
    end

    -- Expect @end
    if stream:check(T.DIR_END) then
        local end_token = stream:advance()
        if not end_token.inline then
            stream:match(T.NEWLINE)
        end
    end

    local node = ast.if_node(condition, then_body, else_body, start.line, start.column)
    node.inline = is_inline
    return node
end

--- Parse @for directive
-- @param stream table Token stream
-- @return table For AST node
function parser.parse_for(stream)
    local start = stream:advance()  -- skip DIR_FOR
    local is_inline = start.inline

    -- Parse variable name(s) - support tuple unpacking: @for key, value in dict
    local var_names = {}
    local var_token = stream:expect(T.IDENT, "Expected variable name after @for")
    table.insert(var_names, var_token.value)

    -- Check for additional comma-separated variable names
    while stream:match(T.COMMA) do
        var_token = stream:expect(T.IDENT, "Expected variable name after ','")
        table.insert(var_names, var_token.value)
    end

    -- Expect 'in'
    stream:expect(T.IN, "Expected 'in' after variable name(s) in @for")

    -- Parse iterable expression
    local iterable = expressions.parse(stream)

    -- Skip newline after expression (unless inline mode)
    if not is_inline then
        stream:match(T.NEWLINE)
    end

    -- Parse body until @else or @end
    local body = parser.parse_body(stream, { T.DIR_ELSE, T.DIR_END })

    local else_body = nil
    local current = stream:peek()

    -- Handle @else (for empty iteration)
    if current and current.type == T.DIR_ELSE then
        local else_token = stream:advance()
        if not else_token.inline then
            stream:match(T.NEWLINE)
        end
        else_body = parser.parse_body(stream, { T.DIR_END })
    end

    -- Expect @end
    if stream:check(T.DIR_END) then
        local end_token = stream:advance()
        if not end_token.inline then
            stream:match(T.NEWLINE)
        end
    end

    local node = ast.for_node(var_names, iterable, body, else_body, start.line, start.column)
    node.inline = is_inline
    return node
end

--- Parse @let/@set directive
-- Supports both assignment and block syntax:
--   @let x = value
--   @set x %}...{% endset   (Jinja2 compat)
-- @param stream table Token stream
-- @return table Let AST node
function parser.parse_let(stream)
    local start = stream:advance()  -- skip DIR_LET

    -- Parse variable name
    local name_token = stream:expect(T.IDENT, "Expected variable name after @let/@set")

    -- Check if this is block syntax (no '=' token) or assignment syntax
    if stream:check(T.ASSIGN) then
        -- Assignment syntax: @let x = value
        stream:advance()  -- skip '='
        
        -- Parse value expression
        local value = expressions.parse(stream)
        
        -- Skip newline
        stream:match(T.NEWLINE)
        
        return ast.let(name_token.value, value, start.line, start.column)
    else
        -- Block syntax: @set x %}...{% endset
        -- Skip newline after variable name
        stream:match(T.NEWLINE)
        
        -- Parse body until @endset
        local body = parser.parse_body(stream, { T.DIR_ENDSET })
        
        -- Expect @endset
        if stream:check(T.DIR_ENDSET) then
            stream:advance()
            stream:match(T.NEWLINE)
        end
        
        -- Create a special let node that captures rendered content
        -- We'll mark it with a flag to indicate it's a block
        local let_node = ast.let(name_token.value, body, start.line, start.column)
        let_node.is_block = true
        return let_node
    end
end

--- Parse @macro directive
-- @param stream table Token stream
-- @return table Macro definition AST node
function parser.parse_macro(stream)
    local start = stream:advance()  -- skip DIR_MACRO

    -- Parse macro name
    local name_token = stream:expect(T.IDENT, "Expected macro name after @macro")

    -- Parse parameters
    local params = {}
    if stream:check(T.LPAREN) then
        stream:advance()
        while not stream:check(T.RPAREN) and not stream:is_eof() do
            local param = stream:expect(T.IDENT, "Expected parameter name")
            table.insert(params, param.value)
            if not stream:match(T.COMMA) then
                break
            end
        end
        stream:expect(T.RPAREN, "Expected ')' after macro parameters")
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    -- Parse body until @end
    local body = parser.parse_body(stream, { T.DIR_END })

    -- Expect @end
    if stream:check(T.DIR_END) then
        stream:advance()
        stream:match(T.NEWLINE)
    end

    return ast.macro_def(name_token.value, params, body, start.line, start.column)
end

--- Parse @call directive
-- @param stream table Token stream
-- @return table Macro call AST node
function parser.parse_call(stream)
    local start = stream:advance()  -- skip DIR_CALL

    -- Parse macro name
    local name_token = stream:expect(T.IDENT, "Expected macro name after @call")

    -- Parse arguments
    local args = {}
    if stream:check(T.LPAREN) then
        stream:advance()
        args = expressions.parse_args(stream)
        stream:expect(T.RPAREN, "Expected ')' after macro arguments")
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    return ast.macro_call(name_token.value, args, start.line, start.column)
end

--- Parse @include directive
-- @param stream table Token stream
-- @return table Include AST node
function parser.parse_include(stream)
    local start = stream:advance()  -- skip DIR_INCLUDE

    -- Parse path (string or expression)
    local path
    if stream:check(T.STRING) then
        local str = stream:advance()
        path = str.value
    else
        path = expressions.parse(stream)
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    return ast.include(path, true, start.line, start.column)
end

--- Parse @import directive
-- @param stream table Token stream
-- @return table Import AST node
function parser.parse_import(stream)
    local start = stream:advance()  -- skip DIR_IMPORT

    -- Parse path
    local path
    if stream:check(T.STRING) then
        local str = stream:advance()
        path = str.value
    else
        path = expressions.parse(stream)
    end

    local names = nil
    local alias = nil

    -- Check for 'as' alias
    if stream:check(T.AS) then
        stream:advance()
        local alias_token = stream:expect(T.IDENT, "Expected alias name after 'as'")
        alias = alias_token.value
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    return ast.import(path, names, alias, start.line, start.column)
end

--- Parse @from directive (selective import)
-- Syntax: {% from "file" import macro1, macro2 %}
-- @param stream table Token stream
-- @return table Import AST node
function parser.parse_from(stream)
    local start = stream:advance()  -- skip DIR_FROM

    -- Parse path
    local path
    if stream:check(T.STRING) then
        local str = stream:advance()
        path = str.value
    else
        path = expressions.parse(stream)
    end

    -- Expect 'import' keyword
    local import_token = stream:peek()
    if not import_token or import_token.type ~= T.DIR_IMPORT then
        errors.raise(errors.parse("Expected 'import' after file path in 'from' directive", 
            import_token.line, import_token.column))
    end
    stream:advance()  -- skip 'import'

    -- Parse list of names to import
    local names = {}
    while true do
        local name_token = stream:expect(T.IDENT, "Expected macro/variable name after 'import'")
        
        -- Check for optional 'as' alias
        local import_name = name_token.value
        local import_alias = nil
        
        if stream:check(T.AS) then
            stream:advance()
            local alias_token = stream:expect(T.IDENT, "Expected alias name after 'as'")
            import_alias = alias_token.value
        end
        
        table.insert(names, {
            name = import_name,
            alias = import_alias
        })
        
        -- Check for comma (more names) or end
        if not stream:match(T.COMMA) then
            break
        end
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    -- For selective imports, we use alias=nil and pass names array
    return ast.import(path, names, nil, start.line, start.column)
end

--- Parse @raw block
-- @param stream table Token stream
-- @return table Raw AST node
function parser.parse_raw(stream)
    local start = stream:advance()  -- skip DIR_RAW
    stream:match(T.NEWLINE)

    -- Collect all text until @endraw
    local content_parts = {}

    while not stream:is_eof() do
        local token = stream:peek()

        if token.type == T.DIR_ENDRAW then
            stream:advance()
            stream:match(T.NEWLINE)
            break
        end

        if token.type == T.TEXT then
            table.insert(content_parts, token.value)
        elseif token.type == T.NEWLINE then
            table.insert(content_parts, "\n")
        else
            -- In raw mode, treat everything as text
            if token.value then
                table.insert(content_parts, tostring(token.value))
            end
        end

        stream:advance()
    end

    return ast.raw(table.concat(content_parts), start.line, start.column)
end

--- Parse @autoescape block
-- Syntax: {% autoescape true|false|"html" %}...{% endautoescape %}
-- @param stream table Token stream
-- @return table Autoescape AST node
function parser.parse_autoescape(stream)
    local start = stream:advance()  -- skip DIR_AUTOESCAPE

    -- Parse the autoescape mode (optional, defaults to true)
    local enabled = true
    local token = stream:peek()
    
    if token and token.type == T.BOOLEAN then
        enabled = token.value
        stream:advance()
    elseif token and token.type == T.STRING then
        -- Format like "html", "xml" - we treat as enabled
        enabled = token.value
        stream:advance()
    elseif token and token.type == T.IDENT then
        -- Could be "true", "false", or format name
        local val = token.value:lower()
        if val == "false" then
            enabled = false
        elseif val == "true" then
            enabled = true
        else
            -- Format name like "html"
            enabled = token.value
        end
        stream:advance()
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    -- Parse body until @endautoescape
    local body = parser.parse_body(stream, { T.DIR_ENDAUTOESCAPE })

    -- Expect @endautoescape
    if stream:check(T.DIR_ENDAUTOESCAPE) then
        stream:advance()
        stream:match(T.NEWLINE)
    end

    return ast.autoescape(enabled, body, start.line, start.column)
end

--- Parse @extends directive
-- @param stream table Token stream
-- @return table Extends AST node
function parser.parse_extends(stream)
    local start = stream:advance()  -- skip DIR_EXTENDS

    -- Parse path (string or expression)
    local path
    if stream:check(T.STRING) then
        local str = stream:advance()
        path = str.value
    else
        path = expressions.parse(stream)
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    return ast.extends(path, start.line, start.column)
end

--- Parse @block directive
-- Supports scoped blocks: {% block name scoped %}
-- @param stream table Token stream
-- @return table Block AST node
function parser.parse_block(stream)
    local start = stream:advance()  -- skip DIR_BLOCK

    -- Parse block name
    local name_token = stream:expect(T.IDENT, "Expected block name after @block")

    -- Check for 'scoped' modifier
    local scoped = false
    if stream:check(T.SCOPED) then
        stream:advance()
        scoped = true
    end

    -- Skip newline
    stream:match(T.NEWLINE)

    -- Parse body until @end or @endblock
    local body = parser.parse_body(stream, { T.DIR_END, T.DIR_ENDBLOCK })

    -- Expect @end or @endblock
    if stream:check(T.DIR_END) or stream:check(T.DIR_ENDBLOCK) then
        stream:advance()
        stream:match(T.NEWLINE)
    end

    local block_node = ast.block(name_token.value, body, start.line, start.column)
    block_node.scoped = scoped
    return block_node
end

return parser
