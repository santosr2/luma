--- Filter registry for Luma
-- Manages filter functions for template expressions
-- @module luma.filters

local runtime = require("luma.runtime")

local filters = {}

-- Internal registry
local _registry = {}

--- Initialize with default filters
local function init_defaults()
    local defaults = runtime.default_filters()
    for name, fn in pairs(defaults) do
        _registry[name] = fn
    end
end

-- Initialize on load
init_defaults()

--- Register a filter function
-- @param name string Filter name
-- @param fn function Filter function
function filters.register(name, fn)
    if type(fn) ~= "function" then
        error("Filter must be a function")
    end
    _registry[name] = fn
end

--- Get a filter by name
-- @param name string Filter name
-- @return function|nil Filter function or nil if not found
function filters.get(name)
    return _registry[name]
end

--- Check if a filter exists
-- @param name string Filter name
-- @return boolean True if filter exists
function filters.has(name)
    return _registry[name] ~= nil
end

--- Get all registered filters
-- @return table All filter functions
function filters.get_all()
    local copy = {}
    for k, v in pairs(_registry) do
        copy[k] = v
    end
    return copy
end

--- List all filter names
-- @return table Array of filter names
function filters.list()
    local names = {}
    for name, _ in pairs(_registry) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

--- Remove a filter
-- @param name string Filter name
function filters.remove(name)
    _registry[name] = nil
end

--- Clear all filters and reset to defaults
function filters.reset()
    _registry = {}
    init_defaults()
end

--- Clear all filters (including defaults)
function filters.clear()
    _registry = {}
end

return filters
