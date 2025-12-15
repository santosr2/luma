--- Compiler module for Luma
-- Compiles parsed AST into executable Lua functions
-- @module luma.compiler

local parser = require("luma.parser")
local codegen = require("luma.compiler.codegen")
local compat = require("luma.utils.compat")
local errors = require("luma.utils.errors")
local ast_module = require("luma.parser.ast")

local compiler = {}
local N = ast_module.types

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
-- @param tests table|nil Test functions for 'is' expressions
-- @return string Rendered output
function CompiledTemplate:render(context, filters, runtime, macros, tests)
    context = context or {}
    filters = filters or {}
    runtime = runtime or require("luma.runtime")
    macros = macros or {}
    tests = tests or runtime.default_tests()

    local ok, result = pcall(self._fn, context, filters, runtime, macros, tests)
    if not ok then
        errors.raise(errors.runtime(tostring(result)))
    end
    return result
end

--- Extract blocks from an AST body
-- @param body table Array of AST nodes
-- @return table Map of block name to block node
local function extract_blocks(body)
    local blocks = {}
    for _, node in ipairs(body) do
        if node.type == N.BLOCK then
            blocks[node.name] = node
        end
    end
    return blocks
end

--- Find extends directive in AST
-- @param template_ast table Template AST
-- @return table|nil Extends node or nil
local function find_extends(template_ast)
    for _, node in ipairs(template_ast.body) do
        if node.type == N.EXTENDS then
            return node
        end
    end
    return nil
end

--- Replace blocks in body with child blocks, storing parent blocks for super()
-- @param body table Array of AST nodes
-- @param child_blocks table Map of block name to child block node
-- @return table Modified body
local function replace_blocks(body, child_blocks)
    local result = {}
    for _, node in ipairs(body) do
        if node.type == N.BLOCK and child_blocks[node.name] then
            -- Store parent block in child block for super() access
            local child_block = child_blocks[node.name]
            child_block.parent_block = node
            table.insert(result, child_block)
        else
            table.insert(result, node)
        end
    end
    return result
end

--- Resolve template inheritance
-- @param template_ast table Template AST
-- @param options table Compilation options
-- @return table Resolved AST (with inheritance applied)
function compiler.resolve_inheritance(template_ast, options)
    local extends_node = find_extends(template_ast)

    if not extends_node then
        -- No inheritance - return as-is
        return template_ast
    end

    -- Load the parent template
    local runtime = require("luma.runtime")
    local parent_path = extends_node.path
    local parent_source, err = runtime.load_source(parent_path)

    if not parent_source then
        errors.raise(errors.compile("Failed to load parent template '" .. tostring(parent_path) .. "': " .. tostring(err)))
    end

    -- Parse the parent template
    local parent_ast = parser.parse(parent_source, options)

    -- Recursively resolve parent inheritance
    parent_ast = compiler.resolve_inheritance(parent_ast, options)

    -- Extract blocks from child template
    local child_blocks = extract_blocks(template_ast.body)

    -- Replace blocks in parent with child blocks
    parent_ast.body = replace_blocks(parent_ast.body, child_blocks)

    return parent_ast
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

    -- Resolve template inheritance
    template_ast = compiler.resolve_inheritance(template_ast, options)

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
        pcall = pcall,  -- For error handling in templates
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
        pcall = pcall,  -- For error handling in templates
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
