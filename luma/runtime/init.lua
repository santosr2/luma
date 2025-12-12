--- Runtime module for Luma
-- Provides runtime utilities for template execution
-- @module luma.runtime

local sandbox = require("luma.runtime.sandbox")
local context = require("luma.runtime.context")

local runtime = {}

-- Re-export submodules
runtime.sandbox = sandbox
runtime.context = context

--- Helper to extract named arguments from filter arguments
-- Filters receive: (value, arg1, arg2, ..., [named_args_table])
-- This helper extracts positional and named args
-- @param args table All arguments passed to filter
-- @param num_positional number Expected number of positional args (excluding input value)
-- @return table Positional arguments (including input value at [1])
-- @return table Named arguments table or empty table
local function extract_filter_args(args, num_positional)
    num_positional = num_positional or 0
    local positional = {}
    local named = {}
    
    -- Last arg might be named args table (check if it's a plain table with string keys)
    local last_arg = args[#args]
    local has_named = false
    
    if type(last_arg) == "table" and not getmetatable(last_arg) then
        -- Check if it looks like a named args table (has string keys, no numeric keys)
        local has_string_keys = false
        local has_numeric_keys = false
        
        for k, v in pairs(last_arg) do
            if type(k) == "string" then
                has_string_keys = true
            elseif type(k) == "number" then
                has_numeric_keys = true
            end
        end
        
        if has_string_keys and not has_numeric_keys then
            has_named = true
            named = last_arg
        end
    end
    
    -- Extract positional args
    local pos_count = has_named and (#args - 1) or #args
    for i = 1, pos_count do
        positional[i] = args[i]
    end
    
    return positional, named
end

runtime._extract_filter_args = extract_filter_args

--- HTML escape sequences
local HTML_ESCAPES = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#x27;",
    ["/"] = "&#x2F;",
}

--- Escape HTML special characters and preserve indentation
-- @param str string String to escape
-- @param col number|nil Column position for indentation (1-indexed)
-- @return string Escaped string with preserved indentation
function runtime.escape(str, col)
    if str == nil then
        return ""
    end
    -- Check if value is marked as safe (already escaped or should not be escaped)
    if type(str) == "table" and str.__luma_safe then
        str = tostring(str.value or "")
    else
        str = tostring(str)
        -- Note: Forward slashes don't need escaping in HTML (only in JS contexts)
        str = str:gsub("[&<>\"']", HTML_ESCAPES)
    end
    -- Apply indentation to multiline content if column is provided
    if col and col > 1 and str:find("\n") then
        local indent_str = string.rep(" ", col - 1)
        str = str:gsub("\n", "\n" .. indent_str)
    end
    return str
end

--- Mark a string as safe (no escaping)
-- @param str string String to mark as safe
-- @return table Safe string wrapper
function runtime.safe(str)
    return {
        __luma_safe = true,
        value = str,
    }
end

--- Create a namespace object for mutable variables
-- Useful for modifying variables inside loops (where normal assignment creates new local)
-- @param initial table|nil Initial values
-- @return table Namespace object
function runtime.namespace(initial)
    local ns = initial or {}
    return ns
end

--- Check if a value is marked as safe
-- @param value any Value to check
-- @return boolean True if marked as safe
function runtime.is_safe(value)
    return type(value) == "table" and value.__luma_safe == true
end

--- Get the string value, handling safe wrappers
-- @param value any Value to convert
-- @return string String value
function runtime.to_string(value)
    if value == nil then
        return ""
    end
    if runtime.is_safe(value) then
        return tostring(value.value)
    end
    return tostring(value)
end

--- Check if a value is contained in a container
-- Supports strings (substring check) and tables (value membership)
-- @param container string|table The container to search in
-- @param value any The value to search for
-- @return boolean True if value is in container
function runtime.contains(container, value)
    if container == nil then
        return false
    end
    if type(container) == "string" then
        -- Substring check for strings
        if value == nil then
            return false
        end
        return container:find(tostring(value), 1, true) ~= nil
    elseif type(container) == "table" then
        -- Check array values and table keys
        for k, v in pairs(container) do
            if v == value or k == value then
                return true
            end
        end
    end
    return false
end

--- Template cache for includes
local template_cache = {}

--- Loader configuration
local loader_paths = { "." }
local custom_loader = nil

--- Add a path to search for templates
-- @param path string Directory path
function runtime.add_path(path)
    table.insert(loader_paths, path)
end

--- Set paths for template loading
-- @param paths table Array of directory paths
function runtime.set_paths(paths)
    loader_paths = paths or { "." }
end

--- Set a custom loader function
-- @param loader function Custom loader function(name) -> source
function runtime.set_loader(loader)
    custom_loader = loader
end

--- Load a template source by name
-- @param name string Template name
-- @return string|nil Template source or nil if not found
-- @return string|nil Error message if not found
function runtime.load_source(name)
    -- Try custom loader first
    if custom_loader then
        local source = custom_loader(name)
        if source then
            return source
        end
    end

    -- If name is an absolute path, try it directly first
    if name:sub(1, 1) == "/" or name:match("^[A-Za-z]:") then
        local file = io.open(name, "r")
        if file then
            local source = file:read("*a")
            file:close()
            return source
        end
    end

    -- Try each path
    for _, path in ipairs(loader_paths) do
        local filepath = path .. "/" .. name
        local file = io.open(filepath, "r")
        if file then
            local source = file:read("*a")
            file:close()
            return source
        end
    end

    return nil, "Template not found: " .. name
end

--- Include another template
-- @param name string Template name to include
-- @param ctx table Context to pass
-- @return string Rendered template
function runtime.include(name, ctx)
    -- Check cache
    local compiled = template_cache[name]

    if not compiled then
        local source, err = runtime.load_source(name)
        if not source then
            error(err)
        end

        -- Compile the template
        local compiler = require("luma.compiler")
        compiled = compiler.compile(source, { name = name })
        template_cache[name] = compiled
    end

    -- Render with context
    local filters = require("luma.filters")
    return compiled:render(ctx, filters.get_all(), runtime)
end

--- Import macros from another template
-- @param name string Template name to import
-- @return table Macros from the template
function runtime.import(name)
    -- For now, just return an empty table
    -- Full implementation would parse the template and extract macros
    return {}
end

--- Import all macros from another template into target
-- @param name string Template name to import
-- @param target table Target macros table
function runtime.import_all(name, target)
    local macros = runtime.import(name)
    for k, v in pairs(macros) do
        target[k] = v
    end
end

--- Clear the template cache
function runtime.clear_cache()
    template_cache = {}
end

--- Create a default set of built-in tests
-- Tests are used with 'is' / 'is not' expressions
-- @return table Test functions
function runtime.default_tests()
    return {
        -- Existence tests
        defined = function(v) return v ~= nil end,
        undefined = function(v) return v == nil end,
        none = function(v) return v == nil end,
        ["nil"] = function(v) return v == nil end,

        -- Type tests
        string = function(v) return type(v) == "string" end,
        number = function(v) return type(v) == "number" end,
        boolean = function(v) return type(v) == "boolean" end,
        table = function(v) return type(v) == "table" end,
        callable = function(v) return type(v) == "function" end,

        -- Numeric tests
        odd = function(v) return type(v) == "number" and math.floor(v) % 2 ~= 0 end,
        even = function(v) return type(v) == "number" and math.floor(v) % 2 == 0 end,
        divisibleby = function(v, n)
            if type(v) ~= "number" or type(n) ~= "number" or n == 0 then
                return false
            end
            return v % n == 0
        end,

        -- Collection tests
        iterable = function(v)
            return type(v) == "table" or type(v) == "string"
        end,
        mapping = function(v)
            if type(v) ~= "table" then return false end
            -- Check if it's a dictionary (has non-integer keys)
            for k, _ in pairs(v) do
                if type(k) ~= "number" or k ~= math.floor(k) then
                    return true
                end
            end
            return false
        end,
        sequence = function(v)
            if type(v) ~= "table" then return false end
            -- Check if it's an array (sequential integer keys starting at 1)
            local count = 0
            for _ in pairs(v) do count = count + 1 end
            return count == #v
        end,
        empty = function(v)
            if v == nil then return true end
            if type(v) == "string" then return #v == 0 end
            if type(v) == "table" then return next(v) == nil end
            return false
        end,

        -- Value tests
        ["true"] = function(v) return v == true end,
        ["false"] = function(v) return v == false end,
        sameas = function(v, other) return rawequal(v, other) end,
        
        -- Containment test (checks if v is in other)
        -- Note: This is different from the 'in' operator which is left-to-right
        -- The test 'x is in(container)' checks if x is in container
        ["in"] = function(v, container) return runtime.contains(container, v) end,
        
        -- String escaping test
        escaped = function(v)
            -- Check if the value is marked as safe (escaped or should not be escaped)
            return runtime.is_safe(v)
        end,

        -- String tests
        lower = function(v)
            if type(v) ~= "string" then return false end
            return v == v:lower() and v:match("%a") ~= nil
        end,
        upper = function(v)
            if type(v) ~= "string" then return false end
            return v == v:upper() and v:match("%a") ~= nil
        end,
    }
end

--- Create a default set of built-in filters
-- @return table Filter functions
function runtime.default_filters()
    return {
        -- String filters
        upper = function(s) return s and tostring(s):upper() or "" end,
        lower = function(s) return s and tostring(s):lower() or "" end,
        capitalize = function(s)
            s = s and tostring(s) or ""
            return s:sub(1, 1):upper() .. s:sub(2):lower()
        end,
        title = function(s)
            s = s and tostring(s) or ""
            return (s:gsub("(%a)([%w_']*)", function(first, rest)
                return first:upper() .. rest:lower()
            end))
        end,
        trim = function(s) return s and tostring(s):match("^%s*(.-)%s*$") or "" end,
        ltrim = function(s) return s and tostring(s):match("^%s*(.*)") or "" end,
        rtrim = function(s) return s and tostring(s):match("(.-)%s*$") or "" end,

        -- Default value
        default = function(v, default_val)
            if v == nil or v == "" then
                return default_val
            end
            return v
        end,
        d = function(v, default_val)
            if v == nil or v == "" then
                return default_val
            end
            return v
        end,

        -- Collection filters
        first = function(t) return t and t[1] end,
        last = function(t) return t and t[#t] end,
        length = function(t)
            if type(t) == "string" then return #t end
            if type(t) == "table" then return #t end
            return 0
        end,
        join = function(t, sep)
            if type(t) ~= "table" then return tostring(t or "") end
            sep = sep or ""
            local result = {}
            for _, v in ipairs(t) do
                table.insert(result, tostring(v))
            end
            return table.concat(result, sep)
        end,
        reverse = function(t)
            if type(t) == "string" then
                return t:reverse()
            end
            if type(t) == "table" then
                local result = {}
                for i = #t, 1, -1 do
                    table.insert(result, t[i])
                end
                return result
            end
            return t
        end,
        sort = function(t)
            if type(t) ~= "table" then return t end
            local result = {}
            for _, v in ipairs(t) do
                table.insert(result, v)
            end
            table.sort(result)
            return result
        end,

        -- Number filters
        abs = function(n) return math.abs(tonumber(n) or 0) end,
        round = function(n, precision)
            n = tonumber(n) or 0
            precision = tonumber(precision) or 0
            local mult = 10 ^ precision
            return math.floor(n * mult + 0.5) / mult
        end,
        floor = function(n) return math.floor(tonumber(n) or 0) end,
        ceil = function(n) return math.ceil(tonumber(n) or 0) end,

        -- HTML filters
        escape = function(s) return runtime.escape(s) end,
        e = function(s) return runtime.escape(s) end,
        safe = function(s) return runtime.safe(s) end,

        -- Type conversion
        int = function(v) return math.floor(tonumber(v) or 0) end,
        float = function(v) return tonumber(v) or 0.0 end,
        string = function(v) return tostring(v or "") end,
        list = function(v)
            if type(v) == "table" then return v end
            if type(v) == "string" then
                local result = {}
                for c in v:gmatch(".") do
                    table.insert(result, c)
                end
                return result
            end
            return { v }
        end,

        -- Additional string filters
        replace = function(s, old, new)
            s = s and tostring(s) or ""
            old = old and tostring(old) or ""
            new = new and tostring(new) or ""
            -- Use plain text replacement (escape pattern special chars)
            return (s:gsub(old:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0"), new))
        end,
        split = function(s, sep)
            s = s and tostring(s) or ""
            sep = sep or " "
            local result = {}
            if sep == "" then
                -- Split into characters
                for c in s:gmatch(".") do
                    table.insert(result, c)
                end
            else
                -- Escape special pattern characters
                local pattern = sep:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
                for part in (s .. sep):gmatch("(.-)" .. pattern) do
                    table.insert(result, part)
                end
            end
            return result
        end,
        wordwrap = function(s, ...)
            -- Support both positional and named arguments
            -- Positional: wordwrap(s, width, break_long_words, wrapstring)
            -- Named: wordwrap(s, {width=79, break_long_words=false, wrapstring='\n'})
            s = s and tostring(s) or ""
            local pos, named = extract_filter_args({s, ...}, 3)
            
            local width = named.width or pos[2] or 79
            local break_long = named.break_long_words or pos[3] or false
            local wrapstring = named.wrapstring or pos[4] or "\n"
            
            local result = {}
            local line = ""
            for word in s:gmatch("%S+") do
                if #line + #word + 1 > width then
                    if #line > 0 then
                        table.insert(result, line)
                    end
                    line = word
                else
                    if #line > 0 then
                        line = line .. " " .. word
                    else
                        line = word
                    end
                end
            end
            if #line > 0 then
                table.insert(result, line)
            end
            return table.concat(result, wrapstring)
        end,
        center = function(s, width)
            s = s and tostring(s) or ""
            width = width or 80
            if #s >= width then return s end
            local pad = width - #s
            local left = math.floor(pad / 2)
            local right = pad - left
            return string.rep(" ", left) .. s .. string.rep(" ", right)
        end,
        indent = function(s, ...)
            -- Support both positional and named arguments
            -- Positional: indent(s, width, first, blank)
            -- Named: indent(s, {width=4, first=true, blank=false})
            s = s and tostring(s) or ""
            local pos, named = extract_filter_args({s, ...}, 3)
            
            local width = named.width or pos[2] or 4
            local first = named.first
            if first == nil then
                first = pos[3]
                if first == nil then
                    first = true
                end
            end
            local blank = named.blank or pos[4] or false
            
            local prefix = string.rep(" ", width)
            local lines = {}
            local i = 1
            for line in (s .. "\n"):gmatch("([^\n]*)\n") do
                local is_blank = line:match("^%s*$")
                if i == 1 then
                    if first then
                        table.insert(lines, prefix .. line)
                    else
                        table.insert(lines, line)
                    end
                elseif is_blank and not blank then
                    table.insert(lines, line)
                else
                    table.insert(lines, prefix .. line)
                end
                i = i + 1
            end
            -- Remove trailing newline we added
            return table.concat(lines, "\n")
        end,
        truncate = function(s, ...)
            -- Support both positional and named arguments
            -- Positional: truncate(s, length, killwords, end_str)
            -- Named: truncate(s, {length=255, killwords=true, end='...'})
            s = s and tostring(s) or ""
            local args = {...}
            local pos, named = extract_filter_args({s, ...}, 3)
            
            local length = named.length or pos[2] or 255
            local killwords = named.killwords or pos[3] or false
            local end_str = named['end'] or pos[4] or "..."
            
            if #s <= length then return s end
            local truncated = s:sub(1, length - #end_str)
            if not killwords then
                -- Find last space
                local last_space = truncated:match(".*()%s")
                if last_space then
                    truncated = truncated:sub(1, last_space - 1)
                end
            end
            return truncated .. end_str
        end,
        striptags = function(s)
            s = s and tostring(s) or ""
            return (s:gsub("<[^>]+>", ""))
        end,
        urlencode = function(s)
            s = s and tostring(s) or ""
            return (s:gsub("[^%w%-_.~]", function(c)
                return string.format("%%%02X", string.byte(c))
            end))
        end,

        -- Additional collection filters
        unique = function(t)
            if type(t) ~= "table" then return t end
            local seen = {}
            local result = {}
            for _, v in ipairs(t) do
                local key = tostring(v)
                if not seen[key] then
                    seen[key] = true
                    table.insert(result, v)
                end
            end
            return result
        end,
        sum = function(t, attr, start)
            start = start or 0
            if type(t) ~= "table" then return start end
            local total = start
            for _, v in ipairs(t) do
                local val = attr and v[attr] or v
                total = total + (tonumber(val) or 0)
            end
            return total
        end,
        min = function(t)
            if type(t) ~= "table" or #t == 0 then return nil end
            local result = t[1]
            for i = 2, #t do
                if t[i] < result then result = t[i] end
            end
            return result
        end,
        max = function(t)
            if type(t) ~= "table" or #t == 0 then return nil end
            local result = t[1]
            for i = 2, #t do
                if t[i] > result then result = t[i] end
            end
            return result
        end,
        groupby = function(t, attr)
            if type(t) ~= "table" then return {} end
            local groups = {}
            local order = {}
            for _, item in ipairs(t) do
                local key = item[attr]
                local key_str = tostring(key)
                if not groups[key_str] then
                    groups[key_str] = { grouper = key, list = {} }
                    table.insert(order, key_str)
                end
                table.insert(groups[key_str].list, item)
            end
            local result = {}
            for _, key in ipairs(order) do
                table.insert(result, groups[key])
            end
            return result
        end,
        selectattr = function(t, attr, test, testval)
            if type(t) ~= "table" then return {} end
            local result = {}
            for _, item in ipairs(t) do
                local val = item[attr]
                local keep = false
                if test == nil or test == "defined" then
                    keep = val ~= nil
                elseif test == "undefined" then
                    keep = val == nil
                elseif test == "none" then
                    keep = val == nil
                elseif test == "eq" or test == "equalto" then
                    keep = val == testval
                elseif test == "ne" then
                    keep = val ~= testval
                elseif test == "lt" then
                    keep = val < testval
                elseif test == "le" then
                    keep = val <= testval
                elseif test == "gt" then
                    keep = val > testval
                elseif test == "ge" then
                    keep = val >= testval
                else
                    -- Truthy test by default
                    keep = val and true or false
                end
                if keep then
                    table.insert(result, item)
                end
            end
            return result
        end,
        rejectattr = function(t, attr, test, testval)
            if type(t) ~= "table" then return {} end
            local result = {}
            for _, item in ipairs(t) do
                local val = item[attr]
                local reject = false
                if test == nil or test == "defined" then
                    reject = val ~= nil
                elseif test == "undefined" then
                    reject = val == nil
                elseif test == "none" then
                    reject = val == nil
                elseif test == "eq" or test == "equalto" then
                    reject = val == testval
                elseif test == "ne" then
                    reject = val ~= testval
                elseif test == "lt" then
                    reject = val < testval
                elseif test == "le" then
                    reject = val <= testval
                elseif test == "gt" then
                    reject = val > testval
                elseif test == "ge" then
                    reject = val >= testval
                else
                    reject = val and true or false
                end
                if not reject then
                    table.insert(result, item)
                end
            end
            return result
        end,
        map = function(t, attr)
            if type(t) ~= "table" then return {} end
            local result = {}
            for _, item in ipairs(t) do
                if type(item) == "table" then
                    table.insert(result, item[attr])
                else
                    table.insert(result, item)
                end
            end
            return result
        end,

        -- Utility filters
        tojson = function(v, indent_val)
            local function encode(val, level)
                level = level or 0
                local t = type(val)
                if val == nil then
                    return "null"
                elseif t == "boolean" then
                    return val and "true" or "false"
                elseif t == "number" then
                    if val ~= val then return "null" end -- NaN
                    if val == math.huge or val == -math.huge then return "null" end
                    return tostring(val)
                elseif t == "string" then
                    return '"' .. val:gsub('[\\"\n\r\t]', {
                        ["\\"] = "\\\\",
                        ['"'] = '\\"',
                        ["\n"] = "\\n",
                        ["\r"] = "\\r",
                        ["\t"] = "\\t"
                    }) .. '"'
                elseif t == "table" then
                    -- Check if array
                    local is_array = true
                    local max_idx = 0
                    for k, _ in pairs(val) do
                        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                            is_array = false
                            break
                        end
                        if k > max_idx then max_idx = k end
                    end
                    if max_idx ~= #val then is_array = false end

                    local parts = {}
                    if is_array then
                        for _, item in ipairs(val) do
                            table.insert(parts, encode(item, level + 1))
                        end
                        return "[" .. table.concat(parts, ", ") .. "]"
                    else
                        for k, item in pairs(val) do
                            table.insert(parts, encode(tostring(k), level + 1) .. ": " .. encode(item, level + 1))
                        end
                        return "{" .. table.concat(parts, ", ") .. "}"
                    end
                else
                    return "null"
                end
            end
            return encode(v)
        end,
        batch = function(t, size, fill)
            if type(t) ~= "table" then return {} end
            size = size or 1
            local result = {}
            local batch = {}
            for i, v in ipairs(t) do
                table.insert(batch, v)
                if #batch >= size then
                    table.insert(result, batch)
                    batch = {}
                end
            end
            if #batch > 0 then
                if fill then
                    while #batch < size do
                        table.insert(batch, fill)
                    end
                end
                table.insert(result, batch)
            end
            return result
        end,
        slice = function(t, slices, fill)
            if type(t) ~= "table" then return {} end
            slices = slices or 1
            local n = #t
            local per_slice = math.ceil(n / slices)
            local result = {}
            local idx = 1
            for i = 1, slices do
                local slice = {}
                for j = 1, per_slice do
                    if idx <= n then
                        table.insert(slice, t[idx])
                        idx = idx + 1
                    elseif fill then
                        table.insert(slice, fill)
                    end
                end
                if #slice > 0 then
                    table.insert(result, slice)
                end
            end
            return result
        end,
        dictsort = function(t, case_sensitive, by)
            if type(t) ~= "table" then return {} end
            by = by or "key"
            case_sensitive = case_sensitive ~= false  -- default true
            local items = {}
            for k, v in pairs(t) do
                table.insert(items, { key = k, value = v })
            end
            table.sort(items, function(a, b)
                local av, bv
                if by == "value" then
                    av, bv = a.value, b.value
                else
                    av, bv = a.key, b.key
                end
                if not case_sensitive and type(av) == "string" and type(bv) == "string" then
                    av, bv = av:lower(), bv:lower()
                end
                return av < bv
            end)
            return items
        end,
        keys = function(t)
            if type(t) ~= "table" then return {} end
            local result = {}
            for k, _ in pairs(t) do
                table.insert(result, k)
            end
            return result
        end,
        values = function(t)
            if type(t) ~= "table" then return {} end
            local result = {}
            for _, v in pairs(t) do
                table.insert(result, v)
            end
            return result
        end,
        items = function(t)
            if type(t) ~= "table" then return {} end
            local result = {}
            for k, v in pairs(t) do
                table.insert(result, { k, v })
            end
            return result
        end,
        attr = function(t, name)
            if type(t) ~= "table" then return nil end
            return t[name]
        end,
        reject = function(t, test)
            if type(t) ~= "table" then return {} end
            local result = {}
            for _, v in ipairs(t) do
                -- Reject truthy values, keep falsy ones (but not nil which ipairs skips)
                if v == false or v == 0 or v == "" then
                    table.insert(result, v)
                end
            end
            return result
        end,
        select = function(t, test)
            if type(t) ~= "table" then return {} end
            local result = {}
            for _, v in ipairs(t) do
                -- Select truthy values: not false, not 0, not empty string, not nil
                if v and v ~= 0 and v ~= "" then
                    table.insert(result, v)
                end
            end
            return result
        end,
    }
end

return runtime
