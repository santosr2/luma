--- Native syntax lexer for Luma
-- Handles $var, ${expr}, and @directive syntax
-- @module luma.lexer.native

local tokens = require("luma.lexer.tokens")
local errors = require("luma.utils.errors")

local T = tokens.types

local native = {}

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

--- Create a new native lexer
-- @param source string The template source code
-- @param source_name string|nil Name for error messages
-- @return table Lexer instance
function native.new(source, source_name)
    local self = {
        source = source,
        source_name = source_name or "template",
        pos = 1,
        line = 1,
        column = 1,
        length = #source,
        -- Mode tracking
        in_expression = false,    -- Inside ${...}
        in_directive = false,     -- Inside @directive
        at_line_start = true,     -- At start of line (for directive detection)
        brace_depth = 0,          -- Nesting depth for ${...}
    }
    setmetatable(self, { __index = native })
    return self
end

--- Get current character without advancing
function native:peek(offset)
    offset = offset or 0
    local pos = self.pos + offset
    if pos > self.length then
        return nil
    end
    return self.source:sub(pos, pos)
end

--- Advance position and return current character
function native:advance()
    if self.pos > self.length then
        return nil
    end
    local c = self.source:sub(self.pos, self.pos)
    self.pos = self.pos + 1
    if c == "\n" then
        self.line = self.line + 1
        self.column = 1
        self.at_line_start = true
    else
        self.column = self.column + 1
        if not is_whitespace(c) then
            self.at_line_start = false
        end
    end
    return c
end

--- Check if we've reached the end
function native:is_eof()
    return self.pos > self.length
end

--- Match a string at current position
function native:match(str)
    local len = #str
    if self.pos + len - 1 > self.length then
        return false
    end
    return self.source:sub(self.pos, self.pos + len - 1) == str
end

--- Skip whitespace (not newlines)
function native:skip_whitespace()
    while not self:is_eof() do
        local c = self:peek()
        if is_whitespace(c) then
            self:advance()
        else
            break
        end
    end
end

--- Read an identifier
function native:read_identifier()
    local start = self.pos
    while not self:is_eof() and is_alnum(self:peek()) do
        self:advance()
    end
    return self.source:sub(start, self.pos - 1)
end

--- Read a number literal
function native:read_number()
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
function native:read_string(quote)
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

--- Read a simple interpolation path (e.g., $foo.bar.baz)
function native:read_simple_path()
    local parts = {}

    -- First identifier
    local ident = self:read_identifier()
    table.insert(parts, ident)

    -- Read any .member accesses
    while self:peek() == "." do
        local next_char = self:peek(1)
        if next_char and is_alpha(next_char) then
            self:advance()  -- skip .
            local member = self:read_identifier()
            table.insert(parts, member)
        else
            break
        end
    end

    return table.concat(parts, ".")
end

--- Create a token with current position
function native:make_token(token_type, value, start_line, start_col)
    return tokens.new(token_type, value, start_line or self.line, start_col or self.column)
end

--- Scan an expression token (inside ${...} or directive)
function native:scan_expression_token()
    self:skip_whitespace()

    if self:is_eof() then
        return self:make_token(T.EOF)
    end

    local c = self:peek()
    local start_line = self.line
    local start_col = self.column

    -- End of expression
    if c == "}" and self.in_expression then
        self.brace_depth = self.brace_depth - 1
        if self.brace_depth == 0 then
            self:advance()
            self.in_expression = false
            return self:make_token(T.INTERP_END, nil, start_line, start_col)
        else
            self:advance()
            return self:make_token(T.RBRACE, nil, start_line, start_col)
        end
    end

    -- Nested brace
    if c == "{" then
        self:advance()
        self.brace_depth = self.brace_depth + 1
        return self:make_token(T.LBRACE, nil, start_line, start_col)
    end

    -- Newline ends directive
    if c == "\n" and self.in_directive then
        self:advance()
        self.in_directive = false
        return self:make_token(T.NEWLINE, nil, start_line, start_col)
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
    if c == "<" then return self:make_token(T.LT, nil, start_line, start_col) end
    if c == ">" then return self:make_token(T.GT, nil, start_line, start_col) end
    if c == "+" then return self:make_token(T.PLUS, nil, start_line, start_col) end
    if c == "-" then return self:make_token(T.MINUS, nil, start_line, start_col) end
    if c == "*" then return self:make_token(T.STAR, nil, start_line, start_col) end
    if c == "/" then return self:make_token(T.SLASH, nil, start_line, start_col) end
    if c == "%" then return self:make_token(T.PERCENT, nil, start_line, start_col) end
    if c == "^" then return self:make_token(T.CARET, nil, start_line, start_col) end
    if c == "=" then return self:make_token(T.ASSIGN, nil, start_line, start_col) end

    errors.raise(errors.lexer("Unexpected character in expression: " .. c, start_line, start_col, self.source_name))
end

--- Scan a directive at line start
function native:scan_directive()
    local start_line = self.line
    local start_col = self.column

    -- Skip @
    self:advance()

    -- Check for comment @#
    if self:peek() == "#" then
        -- Read to end of line
        local comment_start = self.pos + 1
        while not self:is_eof() and self:peek() ~= "\n" do
            self:advance()
        end
        local comment = self.source:sub(comment_start, self.pos - 1)
        return self:make_token(T.DIR_COMMENT, comment, start_line, start_col)
    end

    -- Read directive keyword
    local keyword = self:read_identifier()
    local dir_type = tokens.directives[keyword]

    if not dir_type then
        errors.raise(errors.lexer("Unknown directive: @" .. keyword, start_line, start_col, self.source_name))
    end

    -- For directives that don't need expressions, return immediately
    if dir_type == T.DIR_ELSE or dir_type == T.DIR_END or
       dir_type == T.DIR_RAW or dir_type == T.DIR_ENDRAW then
        return self:make_token(dir_type, keyword, start_line, start_col)
    end

    -- Other directives enter directive mode for expression parsing
    self.in_directive = true
    return self:make_token(dir_type, keyword, start_line, start_col)
end

--- Scan text content until we hit a special character
function native:scan_text()
    local start_line = self.line
    local start_col = self.column
    local parts = {}
    -- Track leading whitespace on current line for potential directive
    local line_whitespace = {}
    local on_line_start = self.at_line_start

    while not self:is_eof() do
        local c = self:peek()

        -- Check for $ (interpolation)
        if c == "$" then
            local next_c = self:peek(1)
            if next_c == "$" then
                -- Escaped $$ -> literal $
                self:advance()
                self:advance()
                -- Whitespace before this is real content now
                for _, ws in ipairs(line_whitespace) do
                    table.insert(parts, ws)
                end
                line_whitespace = {}
                on_line_start = false
                table.insert(parts, "$")
            elseif next_c == "{" or (next_c and is_alpha(next_c)) then
                -- Start of interpolation - keep the line whitespace as content
                for _, ws in ipairs(line_whitespace) do
                    table.insert(parts, ws)
                end
                break
            else
                -- Lone $ is just text
                for _, ws in ipairs(line_whitespace) do
                    table.insert(parts, ws)
                end
                line_whitespace = {}
                on_line_start = false
                table.insert(parts, c)
                self:advance()
            end
        -- Check for @ at line start (directive)
        elseif c == "@" and self.at_line_start then
            -- Don't include the leading whitespace - it belongs to the directive line
            -- The whitespace will be discarded as the directive takes over
            break
        -- Newline handling
        elseif c == "\n" then
            -- Include any accumulated whitespace before newline
            for _, ws in ipairs(line_whitespace) do
                table.insert(parts, ws)
            end
            line_whitespace = {}
            table.insert(parts, c)
            self:advance()
            on_line_start = true
        -- Whitespace at line start - accumulate it
        elseif is_whitespace(c) and on_line_start then
            table.insert(line_whitespace, c)
            self:advance()
        else
            -- Regular content - flush any accumulated whitespace
            for _, ws in ipairs(line_whitespace) do
                table.insert(parts, ws)
            end
            line_whitespace = {}
            on_line_start = false
            table.insert(parts, c)
            self:advance()
        end
    end

    local text = table.concat(parts)
    if #text > 0 then
        return self:make_token(T.TEXT, text, start_line, start_col)
    end
    return nil
end

--- Get the next token
function native:next_token()
    -- If in expression mode, scan expression tokens
    if self.in_expression or self.in_directive then
        return self:scan_expression_token()
    end

    -- Check for EOF
    if self:is_eof() then
        return self:make_token(T.EOF)
    end

    local c = self:peek()
    local start_line = self.line
    local start_col = self.column

    -- Check for directive at line start
    if c == "@" and self.at_line_start then
        return self:scan_directive()
    end

    -- Check for interpolation
    if c == "$" then
        local next_c = self:peek(1)

        if next_c == "$" then
            -- Escaped $$ - handled in scan_text
            return self:scan_text()
        elseif next_c == "{" then
            -- Expression interpolation ${...}
            self:advance()  -- skip $
            self:advance()  -- skip {
            self.in_expression = true
            self.brace_depth = 1
            return self:make_token(T.INTERP_START, nil, start_line, start_col)
        elseif next_c and is_alpha(next_c) then
            -- Simple interpolation $var or $foo.bar
            self:advance()  -- skip $
            local path = self:read_simple_path()
            return self:make_token(T.INTERP_SIMPLE, path, start_line, start_col)
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
function native:tokenize()
    local result = {}

    while true do
        local token = self:next_token()
        table.insert(result, token)
        if token.type == T.EOF then
            break
        end
    end

    return result
end

return native
