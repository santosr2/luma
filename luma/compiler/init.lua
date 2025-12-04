--- Compiler module for Luma
-- Compiles parsed AST into executable Lua functions
-- @module luma.compiler

local parser = require("luma.parser")
local codegen = require("luma.compiler.codegen")
local compat = require("luma.utils.compat")
local errors = require("luma.utils.errors")

local compiler = {}

-- Re-export submodules
compiler.codegen = codegen

--- Compiled template object
local CompiledTemplate = {}
CompiledTemplate.__index = CompiledTemplate

--- Create a new compiled template
-- @param fn function The compiled render function
-- @param source string The generated Lua source code
-- @param name string Template name
-- @return table Compiled template object
local function create_compiled(fn, source, name)
    local self = {
        _fn = fn,
        source = source,
        name = name or "template",
        dependencies = {},
    }
    setmetatable(self, CompiledTemplate)
    return self
end

--- Render the template with given context
-- @param context table Variable context
-- @param filters table|nil Filter functions
-- @param runtime table|nil Runtime utilities
-- @param macros table|nil Pre-defined macros
-- @return string Rendered output
function CompiledTemplate:render(context, filters, runtime, macros)
    context = context or {}
    filters = filters or {}
    runtime = runtime or require("luma.runtime")
    macros = macros or {}

    local ok, result = pcall(self._fn, context, filters, runtime, macros)
    if not ok then
        errors.raise(errors.runtime(tostring(result)))
    end
    return result
end

--- Compile a template from source string
-- @param source string Template source code
-- @param options table|nil Compilation options
-- @return table Compiled template object
function compiler.compile(source, options)
    options = options or {}
    local name = options.name or options.source_name or "template"

    -- Parse source to AST
    local template_ast = parser.parse(source, options)

    -- Generate Lua code
    local lua_code = codegen.generate(template_ast, options)

    -- Create a safe environment with basic Lua functions
    local safe_env = {
        tostring = tostring,
        tonumber = tonumber,
        ipairs = ipairs,
        pairs = pairs,
        next = next,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        type = type,
        select = select,
        unpack = unpack or table.unpack,
        table = table,
        string = string,
        math = math,
    }

    -- Compile Lua code to function
    local fn, err = compat.load_with_env(lua_code, name, safe_env)

    if not fn then
        errors.raise(errors.compile("Failed to compile template: " .. tostring(err)))
    end

    -- Execute to get the template function
    local ok, template_fn = pcall(fn)
    if not ok then
        errors.raise(errors.compile("Failed to initialize template: " .. tostring(template_fn)))
    end

    return create_compiled(template_fn, lua_code, name)
end

--- Compile a template from AST
-- @param template_ast table Parsed AST
-- @param options table|nil Compilation options
-- @return table Compiled template object
function compiler.compile_ast(template_ast, options)
    options = options or {}
    local name = options.name or "template"

    -- Generate Lua code
    local lua_code = codegen.generate(template_ast, options)

    -- Create a safe environment with basic Lua functions
    local safe_env = {
        tostring = tostring,
        tonumber = tonumber,
        ipairs = ipairs,
        pairs = pairs,
        next = next,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        type = type,
        select = select,
        unpack = unpack or table.unpack,
        table = table,
        string = string,
        math = math,
    }

    -- Compile Lua code to function
    local fn, err = compat.load_with_env(lua_code, name, safe_env)

    if not fn then
        errors.raise(errors.compile("Failed to compile template: " .. tostring(err)))
    end

    -- Execute to get the template function
    local ok, template_fn = pcall(fn)
    if not ok then
        errors.raise(errors.compile("Failed to initialize template: " .. tostring(template_fn)))
    end

    return create_compiled(template_fn, lua_code, name)
end

return compiler
