--- Lua version compatibility layer for Luma
-- Provides consistent API across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT
-- @module luma.utils.compat

local compat = {}

-- Detect Lua version
local lua_version = _VERSION:match("Lua (%d+%.%d+)")
compat.lua_version = lua_version
compat.is_lua51 = lua_version == "5.1"
compat.is_lua52 = lua_version == "5.2"
compat.is_lua53 = lua_version == "5.3"
compat.is_lua54 = lua_version == "5.4"
compat.is_luajit = type(jit) == "table"

-- unpack compatibility (table.unpack in 5.2+, unpack in 5.1)
compat.unpack = table.unpack or unpack

-- pack compatibility
compat.pack = table.pack or function(...)
	return { n = select("#", ...), ... }
end

--- Load a chunk with environment support
-- In Lua 5.1, uses setfenv. In 5.2+, uses load with env parameter.
-- @param code string The Lua code to load
-- @param name string The chunk name for error messages
-- @param env table The environment table
-- @return function|nil The loaded chunk or nil on error
-- @return string|nil Error message if loading failed
function compat.load_with_env(code, name, env)
	if compat.is_lua51 or compat.is_luajit then
		-- Lua 5.1 / LuaJIT: use loadstring + setfenv
		local fn, err = loadstring(code, name)
		if fn and env then
			setfenv(fn, env)
		end
		return fn, err
	else
		-- Lua 5.2+: use load with environment
		return load(code, name, "t", env)
	end
end

--- Set environment for a function
-- In Lua 5.1, uses setfenv. In 5.2+, environment is set at load time.
-- @param fn function The function to modify
-- @param env table The environment table
-- @return function The function (possibly modified)
function compat.setfenv(fn, env)
	if compat.is_lua51 or compat.is_luajit then
		return setfenv(fn, env)
	else
		-- In Lua 5.2+, we can't change environment after loading
		-- This is only used as a fallback; prefer load_with_env
		return fn
	end
end

--- Get environment for a function
-- @param fn function The function to query
-- @return table The environment table
function compat.getfenv(fn)
	if compat.is_lua51 or compat.is_luajit then
		return getfenv(fn)
	else
		-- In Lua 5.2+, return _ENV or _G as fallback
		return _ENV or _G
	end
end

--- Create a shallow copy of a table
-- @param t table The table to copy
-- @return table A new table with the same key-value pairs
function compat.shallow_copy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

--- Create a table with a metatable for __index fallback
-- @param base table The base table for __index
-- @return table A new table that falls back to base for missing keys
function compat.create_env_with_fallback(base)
	local env = {}
	setmetatable(env, { __index = base })
	return env
end

--- Safe require that returns nil on failure
-- @param modname string The module name
-- @return any|nil The module or nil if not found
function compat.try_require(modname)
	local ok, mod = pcall(require, modname)
	if ok then
		return mod
	end
	return nil
end

--- Check if a value is callable (function or table with __call)
-- @param v any The value to check
-- @return boolean True if v is callable
function compat.is_callable(v)
	if type(v) == "function" then
		return true
	end
	local mt = getmetatable(v)
	return mt and type(mt.__call) == "function"
end

--- Get iterator for pairs that works consistently
-- @param t table The table to iterate
-- @return function iterator
-- @return table t
-- @return nil initial key
function compat.pairs(t)
	return pairs(t)
end

--- Get iterator for ipairs that works consistently
-- @param t table The array to iterate
-- @return function iterator
-- @return table t
-- @return number initial index
function compat.ipairs(t)
	return ipairs(t)
end

--- Floor division compatible across versions
-- In Lua 5.3+, we have // operator. This provides compatibility.
-- @param a number Dividend
-- @param b number Divisor
-- @return number Floor of a/b
function compat.idiv(a, b)
	return math.floor(a / b)
end

--- Modulo that matches Lua 5.3+ behavior for negative numbers
-- @param a number Dividend
-- @param b number Divisor
-- @return number Remainder
function compat.mod(a, b)
	return a % b
end

--- String pattern escape
-- @param s string The string to escape
-- @return string The escaped pattern
function compat.escape_pattern(s)
	return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

--- Get table length (# operator behavior)
-- @param t table The table
-- @return number The length
function compat.table_len(t)
	return #t
end

--- xpcall with arguments support (Lua 5.1 compatibility)
-- In Lua 5.1, xpcall doesn't support passing arguments to the function.
-- @param fn function The function to call
-- @param msgh function The message handler
-- @param ... any Arguments to pass to fn
-- @return boolean success
-- @return any result or error
function compat.xpcall(fn, msgh, ...)
	if compat.is_lua51 and not compat.is_luajit then
		-- Lua 5.1 doesn't support xpcall with args
		local args = { ... }
		local n = select("#", ...)
		return xpcall(function()
			return fn(compat.unpack(args, 1, n))
		end, msgh)
	else
		-- Lua 5.2+ and LuaJIT support xpcall with args
		return xpcall(fn, msgh, ...)
	end
end

return compat
