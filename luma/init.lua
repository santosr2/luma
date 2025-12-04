--- Luma - A Lua-powered templating engine
-- Clean, directive-based syntax as an alternative to Jinja2
-- @module luma

local compiler = require("luma.compiler")
local runtime = require("luma.runtime")
local filters = require("luma.filters")
local version = require("luma.version")
local parser = require("luma.parser")
local lexer = require("luma.lexer")

local luma = {}

-- Export version info
luma.version = version.string
luma.VERSION = version.string
luma._VERSION = version.full

-- Export submodules for advanced usage
luma.compiler = compiler
luma.runtime = runtime
luma.filters = filters
luma.parser = parser
luma.lexer = lexer

--- Render a template string with given context
-- @param template string Template source code
-- @param context table|nil Variable context
-- @param options table|nil Rendering options
-- @return string Rendered output
function luma.render(template, context, options)
    options = options or {}
    context = context or {}

    local compiled = compiler.compile(template, options)
    return compiled:render(context, filters.get_all(), runtime)
end

--- Compile a template for reuse
-- @param template string Template source code
-- @param options table|nil Compilation options
-- @return table Compiled template object
function luma.compile(template, options)
    return compiler.compile(template, options)
end

--- Create a new environment with custom configuration
-- @param options table|nil Environment options
-- @return table Environment object
function luma.create_environment(options)
    options = options or {}

    local env = {
        _filters = {},
        _globals = {},
        _paths = options.paths or { "." },
        _options = options,
    }

    -- Copy default filters
    for name, fn in pairs(filters.get_all()) do
        env._filters[name] = fn
    end

    --- Add a custom filter
    function env:add_filter(name, fn)
        self._filters[name] = fn
    end

    --- Add a global variable
    function env:add_global(name, value)
        self._globals[name] = value
    end

    --- Add a template search path
    function env:add_path(path)
        table.insert(self._paths, path)
    end

    --- Render a template string
    function env:render(template, context)
        context = context or {}

        -- Merge globals into context
        local merged = {}
        for k, v in pairs(self._globals) do
            merged[k] = v
        end
        for k, v in pairs(context) do
            merged[k] = v
        end

        local compiled = compiler.compile(template, self._options)
        return compiled:render(merged, self._filters, runtime)
    end

    --- Compile a template
    function env:compile(template)
        return compiler.compile(template, self._options)
    end

    --- Render a template file
    function env:render_file(name, context)
        runtime.set_paths(self._paths)
        local source, err = runtime.load_source(name)
        if not source then
            error(err)
        end
        return self:render(source, context)
    end

    return env
end

--- Register a global filter
-- @param name string Filter name
-- @param fn function Filter function
function luma.register_filter(name, fn)
    filters.register(name, fn)
end

--- Register multiple filters at once
-- @param filter_table table Table of name -> function
function luma.register_filters(filter_table)
    for name, fn in pairs(filter_table) do
        filters.register(name, fn)
    end
end

--- Get a registered filter
-- @param name string Filter name
-- @return function|nil Filter function
function luma.get_filter(name)
    return filters.get(name)
end

--- List all registered filters
-- @return table Array of filter names
function luma.list_filters()
    return filters.list()
end

--- Set template search paths
-- @param paths table Array of directory paths
function luma.set_paths(paths)
    runtime.set_paths(paths)
end

--- Add a template search path
-- @param path string Directory path
function luma.add_path(path)
    runtime.add_path(path)
end

--- Set a custom template loader
-- @param loader function Custom loader function(name) -> source
function luma.set_loader(loader)
    runtime.set_loader(loader)
end

--- Clear the template cache
function luma.clear_cache()
    runtime.clear_cache()
end

--- Parse a template to AST (for advanced usage)
-- @param template string Template source code
-- @param options table|nil Parser options
-- @return table AST root node
function luma.parse(template, options)
    return parser.parse(template, options)
end

--- Tokenize a template (for advanced usage)
-- @param template string Template source code
-- @param options table|nil Lexer options
-- @return table Array of tokens
function luma.tokenize(template, options)
    return lexer.tokenize(template, options)
end

return luma
