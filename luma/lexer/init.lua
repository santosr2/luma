--- Lexer module for Luma
-- Orchestrates tokenization of template source code
-- @module luma.lexer

local tokens = require("luma.lexer.tokens")
local native = require("luma.lexer.native")

local lexer = {}

-- Re-export tokens module
lexer.tokens = tokens
lexer.types = tokens.types

--- Syntax modes
lexer.SYNTAX_NATIVE = "native"
lexer.SYNTAX_JINJA = "jinja"
lexer.SYNTAX_AUTO = "auto"

--- Detect syntax mode from source content
-- @param source string Template source
-- @return string Detected syntax mode ("native" or "jinja")
local function detect_syntax(source)
    -- Look for Jinja patterns first
    if source:match("{{") or source:match("{%%") then
        return lexer.SYNTAX_JINJA
    end
    -- Default to native
    return lexer.SYNTAX_NATIVE
end

--- Create a new lexer
-- @param source string The template source code
-- @param options table|nil Options table
-- @return table Lexer instance
function lexer.new(source, options)
    options = options or {}

    local syntax = options.syntax or lexer.SYNTAX_AUTO
    local source_name = options.source_name or options.name or "template"

    -- Auto-detect syntax if needed
    if syntax == lexer.SYNTAX_AUTO then
        syntax = detect_syntax(source)
    end

    -- Create appropriate lexer
    if syntax == lexer.SYNTAX_JINJA then
        -- TODO: Implement Jinja compat lexer
        -- For now, fall back to native
        -- local compat = require("luma.lexer.compat")
        -- return compat.new(source, source_name)
        error("Jinja compatibility mode not yet implemented")
    end

    return native.new(source, source_name)
end

--- Tokenize a template string
-- @param source string The template source code
-- @param options table|nil Options table
-- @return table Array of tokens
function lexer.tokenize(source, options)
    local lex = lexer.new(source, options)
    return lex:tokenize()
end

--- Create a token stream wrapper for the parser
-- Provides peek/consume interface over token array
-- @param token_list table Array of tokens
-- @return table Token stream
function lexer.stream(token_list)
    local stream = {
        tokens = token_list,
        pos = 1,
        length = #token_list,
    }

    --- Get current token without advancing
    function stream:peek(offset)
        offset = offset or 0
        local idx = self.pos + offset
        if idx < 1 or idx > self.length then
            return self.tokens[self.length]  -- Return EOF
        end
        return self.tokens[idx]
    end

    --- Get current token and advance
    function stream:advance()
        local token = self:peek()
        if self.pos < self.length then
            self.pos = self.pos + 1
        end
        return token
    end

    --- Check if current token matches type
    function stream:check(token_type)
        local token = self:peek()
        return token and token.type == token_type
    end

    --- Check if current token matches any of the given types
    function stream:check_any(...)
        local token = self:peek()
        if not token then return false end
        for i = 1, select("#", ...) do
            if token.type == select(i, ...) then
                return true
            end
        end
        return false
    end

    --- Consume token if it matches type, return it or nil
    function stream:match(token_type)
        if self:check(token_type) then
            return self:advance()
        end
        return nil
    end

    --- Consume token if it matches type, error if not
    function stream:expect(token_type, message)
        local token = self:peek()
        if not token or token.type ~= token_type then
            local errors = require("luma.utils.errors")
            local got = token and tokens.type_name(token.type) or "EOF"
            local expected = tokens.type_name(token_type)
            message = message or string.format("Expected %s, got %s", expected, got)
            errors.raise(errors.parse(message, token and token.line, token and token.column))
        end
        return self:advance()
    end

    --- Check if at end of input
    function stream:is_eof()
        return self:check(tokens.types.EOF)
    end

    --- Get current position for backtracking
    function stream:save()
        return self.pos
    end

    --- Restore position for backtracking
    function stream:restore(saved_pos)
        self.pos = saved_pos
    end

    return stream
end

return lexer
