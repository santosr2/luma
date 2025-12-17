--- Sandboxed execution environment for Luma
-- Provides a restricted Lua environment for template execution
-- @module luma.runtime.sandbox

local compat = require("luma.utils.compat")

local sandbox = {}

--- Safe string functions
local safe_string = {
	byte = string.byte,
	char = string.char,
	find = string.find,
	format = string.format,
	gmatch = string.gmatch,
	gsub = string.gsub,
	len = string.len,
	lower = string.lower,
	match = string.match,
	rep = string.rep,
	reverse = string.reverse,
	sub = string.sub,
	upper = string.upper,
}

--- Safe table functions
local safe_table = {
	concat = table.concat,
	insert = table.insert,
	remove = table.remove,
	sort = table.sort,
	unpack = table.unpack or unpack,
}

--- Safe math functions (all are safe)
local safe_math = {}
for k, v in pairs(math) do
	safe_math[k] = v
end

--- Create the whitelist of safe globals
local function create_whitelist()
	return {
		-- Safe built-ins
		assert = assert,
		error = error,
		ipairs = ipairs,
		pairs = pairs,
		next = next,
		select = select,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack or table.unpack,
		pcall = pcall,
		xpcall = xpcall,

		-- Safe modules
		string = safe_string,
		table = safe_table,
		math = safe_math,

		-- Metatable access (read-only)
		getmetatable = getmetatable,
		setmetatable = setmetatable,

		-- We explicitly DO NOT include:
		-- os (os.execute, os.remove, etc. are dangerous)
		-- io (file I/O is dangerous)
		-- debug (can break out of sandbox)
		-- loadfile, dofile, load (can execute arbitrary code)
		-- rawget, rawset (can bypass metatables)
		-- package (can load arbitrary modules)
	}
end

--- Create a sandboxed environment
-- @param base_env table|nil Base environment to extend
-- @param options table|nil Options for the sandbox
-- @return table Sandboxed environment
function sandbox.create(base_env, options)
	options = options or {}

	local env = {}
	local whitelist = create_whitelist()

	-- Copy whitelist into environment
	for k, v in pairs(whitelist) do
		env[k] = v
	end

	-- If power mode, add more functions
	if options.power_mode or options.unsafe then
		env.os = {
			clock = os.clock,
			date = os.date,
			difftime = os.difftime,
			time = os.time,
		}
		-- Still don't expose os.execute, os.remove, etc.
	end

	-- Add base environment values
	if base_env then
		for k, v in pairs(base_env) do
			env[k] = v
		end
	end

	-- Create a protected metatable
	local mt = {
		__index = function(t, k)
			-- First check the environment
			local v = rawget(t, k)
			if v ~= nil then
				return v
			end
			-- Then check whitelist
			return whitelist[k]
		end,
		__newindex = function(t, k, v)
			-- Allow setting values in the environment
			rawset(t, k, v)
		end,
	}

	setmetatable(env, mt)
	return env
end

--- Check if a function/value is safe
-- @param value any Value to check
-- @return boolean True if safe
function sandbox.is_safe(value)
	-- Primitives are safe
	local t = type(value)
	if t == "nil" or t == "boolean" or t == "number" or t == "string" then
		return true
	end

	-- Tables need to be checked recursively (but we won't do deep checks)
	if t == "table" then
		return true -- Tables are allowed, contents are runtime checked
	end

	-- Functions from our whitelist are safe
	if t == "function" then
		-- Check if it's in our whitelist
		local whitelist = create_whitelist()
		for _, v in pairs(whitelist) do
			if v == value then
				return true
			end
			if type(v) == "table" then
				for _, vv in pairs(v) do
					if vv == value then
						return true
					end
				end
			end
		end
		-- Unknown functions are not safe by default
		return false
	end

	return false
end

--- Blocked functions list (for error messages)
sandbox.blocked = {
	"os.execute",
	"os.remove",
	"os.rename",
	"os.exit",
	"os.setlocale",
	"os.getenv",
	"io.open",
	"io.popen",
	"io.input",
	"io.output",
	"io.read",
	"io.write",
	"io.close",
	"io.flush",
	"io.lines",
	"io.tmpfile",
	"loadfile",
	"dofile",
	"load",
	"loadstring",
	"require",
	"package.loadlib",
	"debug.getfenv",
	"debug.setfenv",
	"debug.getinfo",
	"debug.setlocal",
	"debug.setupvalue",
	"debug.sethook",
}

return sandbox
