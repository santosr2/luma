--- Token type definitions for Luma lexer
-- @module luma.lexer.tokens

local tokens = {}

--- Token types enumeration
tokens.types = {
    -- Content tokens
    TEXT = "TEXT",                      -- Raw text content
    NEWLINE = "NEWLINE",                -- Line ending (for whitespace control)

    -- Native interpolation
    INTERP_START = "INTERP_START",      -- ${ start of expression interpolation
    INTERP_END = "INTERP_END",          -- } end of expression interpolation
    INTERP_SIMPLE = "INTERP_SIMPLE",    -- $var or $foo.bar (simple path)

    -- Jinja compatibility
    JINJA_VAR_START = "JINJA_VAR_START",    -- {{
    JINJA_VAR_END = "JINJA_VAR_END",        -- }}
    JINJA_STMT_START = "JINJA_STMT_START",  -- {%
    JINJA_STMT_END = "JINJA_STMT_END",      -- %}
    JINJA_COMMENT = "JINJA_COMMENT",        -- {# ... #}

    -- Directives (@ at start of line)
    DIR_IF = "DIR_IF",                  -- @if condition
    DIR_ELIF = "DIR_ELIF",              -- @elif condition
    DIR_ELSE = "DIR_ELSE",              -- @else
    DIR_FOR = "DIR_FOR",                -- @for item in items
    DIR_LET = "DIR_LET",                -- @let name = expr
    DIR_ENDSET = "DIR_ENDSET",          -- @endset (closes set block)
    DIR_MACRO = "DIR_MACRO",            -- @macro name(args)
    DIR_CALL = "DIR_CALL",              -- @call macro(args)
    DIR_ENDCALL = "DIR_ENDCALL",        -- @endcall (closes call with caller)
    DIR_INCLUDE = "DIR_INCLUDE",        -- @include "file"
    DIR_IMPORT = "DIR_IMPORT",          -- @import "file"
    DIR_FROM = "DIR_FROM",              -- @from "file" import x, y (Jinja compat)
    DIR_END = "DIR_END",                -- @end
    DIR_RAW = "DIR_RAW",                -- @raw
    DIR_ENDRAW = "DIR_ENDRAW",          -- @endraw
    DIR_AUTOESCAPE = "DIR_AUTOESCAPE",  -- @autoescape
    DIR_ENDAUTOESCAPE = "DIR_ENDAUTOESCAPE", -- @endautoescape
    DIR_COMMENT = "DIR_COMMENT",        -- @# comment
    DIR_BREAK = "DIR_BREAK",            -- @break
    DIR_CONTINUE = "DIR_CONTINUE",      -- @continue
    DIR_EXTENDS = "DIR_EXTENDS",        -- @extends "base.html"
    DIR_BLOCK = "DIR_BLOCK",            -- @block name
    DIR_ENDBLOCK = "DIR_ENDBLOCK",      -- @endblock (alias for @end)

    -- Expression tokens (used inside ${} and directives)
    IDENT = "IDENT",                    -- identifier
    NUMBER = "NUMBER",                  -- numeric literal
    STRING = "STRING",                  -- string literal
    BOOLEAN = "BOOLEAN",                -- true/false
    NIL = "NIL",                        -- nil

    -- Punctuation
    DOT = "DOT",                        -- .
    COMMA = "COMMA",                    -- ,
    COLON = "COLON",                    -- :
    LBRACKET = "LBRACKET",              -- [
    RBRACKET = "RBRACKET",              -- ]
    LPAREN = "LPAREN",                  -- (
    RPAREN = "RPAREN",                  -- )
    LBRACE = "LBRACE",                  -- {
    RBRACE = "RBRACE",                  -- }

    -- Operators - Pipe/Filter
    PIPE = "PIPE",                      -- |
    PIPE_ARROW = "PIPE_ARROW",          -- |>

    -- Operators - Comparison
    EQ = "EQ",                          -- ==
    NE = "NE",                          -- != or ~=
    LT = "LT",                          -- <
    LE = "LE",                          -- <=
    GT = "GT",                          -- >
    GE = "GE",                          -- >=

    -- Operators - Logical
    AND = "AND",                        -- and
    OR = "OR",                          -- or
    NOT = "NOT",                        -- not

    -- Operators - Arithmetic
    PLUS = "PLUS",                      -- +
    MINUS = "MINUS",                    -- -
    STAR = "STAR",                      -- *
    SLASH = "SLASH",                    -- /
    PERCENT = "PERCENT",                -- %
    CARET = "CARET",                    -- ^

    -- Operators - Assignment
    ASSIGN = "ASSIGN",                  -- =

    -- Keywords (used in expressions and directives)
    IN = "IN",                          -- in (for loops, membership)
    NOT_IN = "NOT_IN",                  -- not in (membership)
    IS = "IS",                          -- is (tests)
    AS = "AS",                          -- as (aliasing)
    SCOPED = "SCOPED",                  -- scoped (block modifier)

    -- Special
    EOF = "EOF",                        -- End of input
}

--- Keywords mapping
tokens.keywords = {
    ["and"] = tokens.types.AND,
    ["or"] = tokens.types.OR,
    ["not"] = tokens.types.NOT,
    ["true"] = tokens.types.BOOLEAN,
    ["false"] = tokens.types.BOOLEAN,
    ["nil"] = tokens.types.NIL,
    ["in"] = tokens.types.IN,
    ["is"] = tokens.types.IS,
    ["as"] = tokens.types.AS,
    ["scoped"] = tokens.types.SCOPED,
}

--- Directive keywords mapping (after @)
tokens.directives = {
    ["if"] = tokens.types.DIR_IF,
    ["elif"] = tokens.types.DIR_ELIF,
    ["elseif"] = tokens.types.DIR_ELIF,  -- alias
    ["else"] = tokens.types.DIR_ELSE,
    ["for"] = tokens.types.DIR_FOR,
    ["let"] = tokens.types.DIR_LET,
    ["set"] = tokens.types.DIR_LET,      -- alias (Jinja compat)
    ["endset"] = tokens.types.DIR_ENDSET,
    ["macro"] = tokens.types.DIR_MACRO,
    ["call"] = tokens.types.DIR_CALL,
    ["endcall"] = tokens.types.DIR_ENDCALL,
    ["include"] = tokens.types.DIR_INCLUDE,
    ["import"] = tokens.types.DIR_IMPORT,
    ["from"] = tokens.types.DIR_FROM,
    ["end"] = tokens.types.DIR_END,
    ["endif"] = tokens.types.DIR_END,    -- Jinja compat
    ["endfor"] = tokens.types.DIR_END,   -- Jinja compat
    ["endmacro"] = tokens.types.DIR_END, -- Jinja compat
    ["raw"] = tokens.types.DIR_RAW,
    ["endraw"] = tokens.types.DIR_ENDRAW,
    ["autoescape"] = tokens.types.DIR_AUTOESCAPE,
    ["endautoescape"] = tokens.types.DIR_ENDAUTOESCAPE,
    ["break"] = tokens.types.DIR_BREAK,
    ["continue"] = tokens.types.DIR_CONTINUE,
    ["extends"] = tokens.types.DIR_EXTENDS,
    ["block"] = tokens.types.DIR_BLOCK,
    ["endblock"] = tokens.types.DIR_ENDBLOCK,
}

--- Create a new token
-- @param token_type string Token type from tokens.types
-- @param value any Token value
-- @param line number Line number (1-indexed)
-- @param column number Column number (1-indexed)
-- @return table Token object
function tokens.new(token_type, value, line, column)
    return {
        type = token_type,
        value = value,
        line = line,
        column = column,
    }
end

--- Create an EOF token
-- @param line number Line number
-- @param column number Column number
-- @return table EOF token
function tokens.eof(line, column)
    return tokens.new(tokens.types.EOF, nil, line, column)
end

--- Check if a token is of a specific type
-- @param token table Token to check
-- @param token_type string Expected type
-- @return boolean True if token matches type
function tokens.is(token, token_type)
    return token and token.type == token_type
end

--- Check if a token is any of the given types
-- @param token table Token to check
-- @param ... string Expected types
-- @return boolean True if token matches any type
function tokens.is_any(token, ...)
    if not token then
        return false
    end
    for i = 1, select("#", ...) do
        if token.type == select(i, ...) then
            return true
        end
    end
    return false
end

--- Get a human-readable name for a token type
-- @param token_type string Token type
-- @return string Human-readable name
function tokens.type_name(token_type)
    for name, t in pairs(tokens.types) do
        if t == token_type then
            return name
        end
    end
    return token_type
end

--- Format a token for debugging
-- @param token table Token to format
-- @return string Debug string
function tokens.format(token)
    if not token then
        return "nil"
    end
    local value_str = ""
    if token.value ~= nil then
        if type(token.value) == "string" then
            value_str = string.format(" %q", token.value)
        else
            value_str = " " .. tostring(token.value)
        end
    end
    return string.format("[%s%s] at %d:%d",
        tokens.type_name(token.type),
        value_str,
        token.line or 0,
        token.column or 0)
end

return tokens
