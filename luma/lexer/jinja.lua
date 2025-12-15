--- Jinja2 compatibility lexer for Luma
-- Handles {{ expr }}, {% stmt %}, and {# comment #} syntax
-- @module luma.lexer.jinja

local tokens = require("luma.lexer.tokens")
local errors = require("luma.utils.errors")

local T = tokens.types

local jinja = {}

--- Character classification helpers
local function is_alpha(c)
    return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"
end

local function is_digit(c)
    return c >= "0" and c <= "9"
end

local function is_alnum(c)
    return is_alpha(c) or is_digit(c)
end

local function is_whitespace(c)
    return c == " " or c == "\t" or c == "\r"
end

--- Create a new Jinja lexer
-- @param source string The template source code
-- @param source_name string|nil Name for error messages
-- @return table Lexer instance
function jinja.new(source, source_name)
    local self = {
        source = source,
        source_name = source_name or "template",
        pos = 1,
        line = 1,
        column = 1,
        length = #source,
        -- Mode tracking
        in_var = false,        -- Inside {{ ... }}
        in_stmt = false,       -- Inside {% ... %}
        stmt_keyword = nil,    -- The keyword of the current statement
        trim_next = false,     -- Whether to trim whitespace on next text
    }
    setmetatable(self, { __index = jinja })
    return self
end

--- Get current character without advancing
function jinja:peek(offset)
    offset = offset or 0
    local pos = self.pos + offset
    if pos > self.length then
        return nil
    end
    return self.source:sub(pos, pos)
end

--- Advance position and return current character
function jinja:advance()
    if self.pos > self.length then
        return nil
    end
    local c = self.source:sub(self.pos, self.pos)
    self.pos = self.pos + 1
    if c == "\n" then
        self.line = self.line + 1
        self.column = 1
    else
        self.column = self.column + 1
    end
    return c
end

--- Check if we've reached the end
function jinja:is_eof()
    return self.pos > self.length
end

--- Match a string at current position
function jinja:match(str)
    local len = #str
    if self.pos + len - 1 > self.length then
        return false
    end
    return self.source:sub(self.pos, self.pos + len - 1) == str
end

--- Skip whitespace (not newlines unless in expression)
function jinja:skip_whitespace(include_newlines)
    while not self:is_eof() do
        local c = self:peek()
        if is_whitespace(c) then
            self:advance()
        elseif include_newlines and c == "\n" then
            self:advance()
        else
            break
        end
    end
end

--- Read an identifier
function jinja:read_identifier()
    local start = self.pos
    while not self:is_eof() and is_alnum(self:peek()) do
        self:advance()
    end
    return self.source:sub(start, self.pos - 1)
end

--- Read a number literal
function jinja:read_number()
    local start = self.pos
    local has_dot = false

    while not self:is_eof() do
        local c = self:peek()
        if is_digit(c) then
            self:advance()
        elseif c == "." and not has_dot and is_digit(self:peek(1) or "") then
            has_dot = true
            self:advance()
        else
            break
        end
    end

    local str = self.source:sub(start, self.pos - 1)
    return tonumber(str), str
end

--- Read a string literal
function jinja:read_string(quote)
    local start_line = self.line
    local start_col = self.column
    local parts = {}

    -- Skip opening quote
    self:advance()

    while not self:is_eof() do
        local c = self:peek()

        if c == quote then
            self:advance()
            return table.concat(parts)
        elseif c == "\\" then
            -- Escape sequence
            self:advance()
            local escaped = self:peek()
            if escaped == nil then
                errors.raise(errors.lexer("Unterminated string", start_line, start_col, self.source_name))
            end
            self:advance()
            if escaped == "n" then
                table.insert(parts, "\n")
            elseif escaped == "t" then
                table.insert(parts, "\t")
            elseif escaped == "r" then
                table.insert(parts, "\r")
            elseif escaped == "\\" then
                table.insert(parts, "\\")
            elseif escaped == quote then
                table.insert(parts, quote)
            else
                table.insert(parts, escaped)
            end
        elseif c == "\n" then
            errors.raise(errors.lexer("Unterminated string", start_line, start_col, self.source_name))
        else
            table.insert(parts, c)
            self:advance()
        end
    end

    errors.raise(errors.lexer("Unterminated string", start_line, start_col, self.source_name))
end

--- Create a token with current position
function jinja:make_token(token_type, value, start_line, start_col)
    return tokens.new(token_type, value, start_line or self.line, start_col or self.column)
end

--- Scan an expression token (inside {{ }} or {% %})
function jinja:scan_expression_token()
    self:skip_whitespace(true)

    if self:is_eof() then
        return self:make_token(T.EOF)
    end

    local c = self:peek()
    local start_line = self.line
    local start_col = self.column

    -- Check for end of Luma expression block: }
    if self.in_expression and c == "}" then
        self:advance()
        self.in_expression = false
        return self:make_token(T.INTERP_END, nil, start_line, start_col)
    end
    
    -- Check for end of variable block: }} or -}}
    if self.in_var then
        if self:match("-}}") then
            self:advance()
            self:advance()
            self:advance()
            self.in_var = false
            self.trim_next = true
            return self:make_token(T.INTERP_END, nil, start_line, start_col)
        elseif self:match("}}") then
            self:advance()
            self:advance()
            self.in_var = false
            return self:make_token(T.INTERP_END, nil, start_line, start_col)
        end
    end

    -- Check for end of statement block: %} or -%}
    if self.in_stmt then
        if self:match("-%}") then
            self:advance()
            self:advance()
            self:advance()
            self.in_stmt = false
            self.trim_next = true
            -- Return NEWLINE to end directive mode
            return self:make_token(T.NEWLINE, nil, start_line, start_col)
        elseif self:match("%}") then
            self:advance()
            self:advance()
            self.in_stmt = false
            -- Return NEWLINE to end directive mode
            return self:make_token(T.NEWLINE, nil, start_line, start_col)
        end
    end

    -- Identifiers and keywords
    if is_alpha(c) then
        local ident = self:read_identifier()
        local keyword = tokens.keywords[ident]
        if keyword then
            if keyword == T.BOOLEAN then
                return self:make_token(T.BOOLEAN, ident == "true", start_line, start_col)
            elseif keyword == T.NIL then
                return self:make_token(T.NIL, nil, start_line, start_col)
            elseif keyword == T.NOT then
                -- Check for "not in" compound keyword
                local saved_pos = self.pos
                local saved_line = self.line
                local saved_col = self.column
                self:skip_whitespace(true)
                if is_alpha(self:peek() or "") then
                    local next_ident = self:read_identifier()
                    if next_ident == "in" then
                        return self:make_token(T.NOT_IN, "not in", start_line, start_col)
                    end
                    -- Not "in", restore position
                    self.pos = saved_pos
                    self.line = saved_line
                    self.column = saved_col
                end
                return self:make_token(T.NOT, ident, start_line, start_col)
            else
                return self:make_token(keyword, ident, start_line, start_col)
            end
        end
        return self:make_token(T.IDENT, ident, start_line, start_col)
    end

    -- Numbers
    if is_digit(c) then
        local num, raw = self:read_number()
        return self:make_token(T.NUMBER, num, start_line, start_col)
    end

    -- Strings
    if c == '"' or c == "'" then
        local str = self:read_string(c)
        return self:make_token(T.STRING, str, start_line, start_col)
    end

    -- Two-character operators
    local two = self.source:sub(self.pos, self.pos + 1)

    if two == "|>" then
        self:advance()
        self:advance()
        return self:make_token(T.PIPE_ARROW, nil, start_line, start_col)
    end
    if two == "==" then
        self:advance()
        self:advance()
        return self:make_token(T.EQ, nil, start_line, start_col)
    end
    if two == "!=" or two == "~=" then
        self:advance()
        self:advance()
        return self:make_token(T.NE, nil, start_line, start_col)
    end
    if two == "<=" then
        self:advance()
        self:advance()
        return self:make_token(T.LE, nil, start_line, start_col)
    end
    if two == ">=" then
        self:advance()
        self:advance()
        return self:make_token(T.GE, nil, start_line, start_col)
    end

    -- Check for .. (concatenation) before . (member access)
    if c == "." and self:peek(1) == "." then
        self:advance()
        self:advance()
        return self:make_token(T.CONCAT, nil, start_line, start_col)
    end

    -- Single-character operators/punctuation
    self:advance()

    if c == "|" then return self:make_token(T.PIPE, nil, start_line, start_col) end
    if c == "." then return self:make_token(T.DOT, nil, start_line, start_col) end
    if c == "," then return self:make_token(T.COMMA, nil, start_line, start_col) end
    if c == ":" then return self:make_token(T.COLON, nil, start_line, start_col) end
    if c == "[" then return self:make_token(T.LBRACKET, nil, start_line, start_col) end
    if c == "]" then return self:make_token(T.RBRACKET, nil, start_line, start_col) end
    if c == "(" then return self:make_token(T.LPAREN, nil, start_line, start_col) end
    if c == ")" then return self:make_token(T.RPAREN, nil, start_line, start_col) end
    if c == "{" then return self:make_token(T.LBRACE, nil, start_line, start_col) end
    if c == "}" then return self:make_token(T.RBRACE, nil, start_line, start_col) end
    if c == "<" then return self:make_token(T.LT, nil, start_line, start_col) end
    if c == ">" then return self:make_token(T.GT, nil, start_line, start_col) end
    if c == "+" then return self:make_token(T.PLUS, nil, start_line, start_col) end
    if c == "-" then return self:make_token(T.MINUS, nil, start_line, start_col) end
    if c == "*" then return self:make_token(T.STAR, nil, start_line, start_col) end
    if c == "/" then return self:make_token(T.SLASH, nil, start_line, start_col) end
    if c == "%" then return self:make_token(T.PERCENT, nil, start_line, start_col) end
    if c == "^" then return self:make_token(T.CARET, nil, start_line, start_col) end
    if c == "=" then return self:make_token(T.ASSIGN, nil, start_line, start_col) end
    if c == "#" then return self:make_token(T.HASH, nil, start_line, start_col) end

    errors.raise(errors.lexer("Unexpected character in expression: " .. c, start_line, start_col, self.source_name))
end

--- Scan a statement block {% ... %}
function jinja:scan_statement()
    local start_line = self.line
    local start_col = self.column

    -- Skip {%
    self:advance()
    self:advance()

    -- Check for whitespace control: {%-
    local trim_prev = false
    if self:peek() == "-" then
        trim_prev = true
        self:advance()
    end

    self:skip_whitespace(true)

    -- Read statement keyword
    local keyword = self:read_identifier()

    -- Map Jinja keywords to our directive tokens
    local dir_type = tokens.directives[keyword]

    if not dir_type then
        errors.raise(errors.lexer("Unknown statement: " .. keyword, start_line, start_col, self.source_name))
    end

    -- For end-type statements, we need to scan past the %}
    if dir_type == T.DIR_END or dir_type == T.DIR_ENDRAW or dir_type == T.DIR_ENDBLOCK then
        self:skip_whitespace(true)
        if self:match("-%}") then
            self:advance()
            self:advance()
            self:advance()
            self.trim_next = true
        elseif self:match("%}") then
            self:advance()
            self:advance()
        else
            errors.raise(errors.lexer("Expected '%}' to close statement", self.line, self.column, self.source_name))
        end
        return self:make_token(dir_type, keyword, start_line, start_col), trim_prev
    end

    -- For else-type statements
    if dir_type == T.DIR_ELSE then
        self:skip_whitespace(true)
        if self:match("-%}") then
            self:advance()
            self:advance()
            self:advance()
            self.trim_next = true
        elseif self:match("%}") then
            self:advance()
            self:advance()
        else
            errors.raise(errors.lexer("Expected '%}' to close statement", self.line, self.column, self.source_name))
        end
        return self:make_token(dir_type, keyword, start_line, start_col), trim_prev
    end

    -- For break/continue
    if dir_type == T.DIR_BREAK or dir_type == T.DIR_CONTINUE then
        self:skip_whitespace(true)
        if self:match("-%}") then
            self:advance()
            self:advance()
            self:advance()
            self.trim_next = true
        elseif self:match("%}") then
            self:advance()
            self:advance()
        else
            errors.raise(errors.lexer("Expected '%}' to close statement", self.line, self.column, self.source_name))
        end
        return self:make_token(dir_type, keyword, start_line, start_col), trim_prev
    end

    -- Other statements enter statement mode for expression parsing
    self.in_stmt = true
    self.stmt_keyword = keyword
    return self:make_token(dir_type, keyword, start_line, start_col), trim_prev
end

--- Scan a comment block {# ... #}
function jinja:scan_comment()
    local start_line = self.line
    local start_col = self.column

    -- Skip {#
    self:advance()
    self:advance()

    local trim_prev = false
    if self:peek() == "-" then
        trim_prev = true
        self:advance()
    end

    local parts = {}
    while not self:is_eof() do
        if self:match("-#}") then
            self:advance()
            self:advance()
            self:advance()
            self.trim_next = true
            break
        elseif self:match("#}") then
            self:advance()
            self:advance()
            break
        else
            table.insert(parts, self:peek())
            self:advance()
        end
    end

    return self:make_token(T.DIR_COMMENT, table.concat(parts), start_line, start_col), trim_prev
end

--- Scan text content until we hit a special block
function jinja:scan_text()
    local start_line = self.line
    local start_col = self.column
    local parts = {}

    while not self:is_eof() do
        local c = self:peek()

        -- Check for Jinja blocks
        if c == "{" then
            local next_c = self:peek(1)
            if next_c == "{" or next_c == "%" or next_c == "#" then
                break
            end
        end
        
        -- Check for Luma interpolation (for mixed syntax support)
        if c == "$" then
            local next_c = self:peek(1)
            local next_next_c = self:peek(2)
            -- Only treat as interpolation if followed by identifier or single {
            -- Don't break on ${{ (literal $ + Jinja2 {{)
            if next_c and next_c:match("[a-zA-Z_]") then
                break
            elseif next_c == "{" and next_next_c ~= "{" then
                break
            end
        end

        table.insert(parts, c)
        self:advance()
    end

    local text = table.concat(parts)

    -- Handle whitespace trimming from previous block
    if self.trim_next then
        self.trim_next = false
        text = text:gsub("^%s+", "")
    end

    if #text > 0 then
        return self:make_token(T.TEXT, text, start_line, start_col)
    end
    return nil
end

--- Get the next token
function jinja:next_token()
    -- If in expression mode, scan expression tokens
    if self.in_var or self.in_stmt or self.in_expression then
        return self:scan_expression_token()
    end

    -- Check for EOF
    if self:is_eof() then
        return self:make_token(T.EOF)
    end

    local c = self:peek()
    local start_line = self.line
    local start_col = self.column

    -- Check for Luma interpolation (mixed syntax support)
    if c == "$" then
        local next_c = self:peek(1)
        local next_next_c = self:peek(2)
        
        -- Don't treat ${{ as interpolation (it's literal $ + Jinja2 {{)
        if next_c == "{" and next_next_c == "{" then
            -- Let it fall through to scan_text
        elseif next_c and next_c:match("[a-zA-Z_]") then
            -- Simple variable: $var
            self:advance()  -- skip $
            local var_name = self:read_identifier()
            return self:make_token(T.INTERP_SIMPLE, var_name, start_line, start_col)
        elseif next_c == "{" then
            -- Complex expression: ${...}
            self:advance()  -- skip $
            self:advance()  -- skip {
            self.in_expression = true
            return self:make_token(T.INTERP_START, nil, start_line, start_col)
        end
    end
    
    -- Check for Jinja blocks
    if c == "{" then
        local next_c = self:peek(1)

        if next_c == "{" then
            -- Variable block {{ ... }}
            self:advance()
            self:advance()
            -- Check for whitespace control: {{-
            local trim_prev = false
            if self:peek() == "-" then
                trim_prev = true
                self:advance()
            end
            self.in_var = true
            local token = self:make_token(T.INTERP_START, nil, start_line, start_col)
            token.trim_prev = trim_prev
            return token
        elseif next_c == "%" then
            -- Statement block {% ... %}
            local token, trim_prev = self:scan_statement()
            if trim_prev then
                token.trim_prev = true
            end
            return token
        elseif next_c == "#" then
            -- Comment block {# ... #}
            local token, trim_prev = self:scan_comment()
            if trim_prev then
                token.trim_prev = true
            end
            return token
        end
    end

    -- Otherwise scan text
    local text_token = self:scan_text()
    if text_token then
        return text_token
    end

    -- If scan_text returned nil, we must be at EOF or special char
    return self:next_token()
end

--- Tokenize the entire source
-- @return table Array of tokens
function jinja:tokenize()
    local result = {}

    while true do
        local token = self:next_token()
        
        -- Handle trim_prev: trim trailing whitespace from previous TEXT token
        if token.trim_prev and #result > 0 then
            for i = #result, 1, -1 do
                if result[i].type == T.TEXT then
                    -- Trim trailing whitespace from the last TEXT token
                    result[i].value = result[i].value:gsub("%s+$", "")
                    break
                end
            end
        end
        
        table.insert(result, token)
        if token.type == T.EOF then
            break
        end
    end

    return result
end

return jinja
