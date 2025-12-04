--- Runtime module for Luma
-- Provides runtime utilities for template execution
-- @module luma.runtime

local sandbox = require("luma.runtime.sandbox")
local context = require("luma.runtime.context")

local runtime = {}

-- Re-export submodules
runtime.sandbox = sandbox
runtime.context = context

--- HTML escape sequences
local HTML_ESCAPES = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#x27;",
    ["/"] = "&#x2F;",
}

--- Escape HTML special characters
-- @param str string String to escape
-- @return string Escaped string
function runtime.escape(str)
    if str == nil then
        return ""
    end
    str = tostring(str)
    return (str:gsub("[&<>\"'/]", HTML_ESCAPES))
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
    }
end

return runtime
