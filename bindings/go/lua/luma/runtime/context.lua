--- Context management for Luma
-- Handles variable scope and lookup
-- @module luma.runtime.context

local context = {}

--- Create a new context
-- @param data table|nil Initial data
-- @param parent table|nil Parent context for scope chain
-- @return table Context object
function context.new(data, parent)
	local ctx = {}
	local mt = {}

	-- Store the actual data
	local _data = data or {}
	local _parent = parent

	-- Index metamethod for variable lookup
	mt.__index = function(t, k)
		-- First check local data
		local v = _data[k]
		if v ~= nil then
			return v
		end
		-- Then check parent context
		if _parent then
			return _parent[k]
		end
		return nil
	end

	-- Newindex metamethod for variable assignment
	mt.__newindex = function(t, k, v)
		_data[k] = v
	end

	-- Pairs metamethod for iteration
	mt.__pairs = function(t)
		-- Merge parent and local data for iteration
		local merged = {}
		if _parent then
			for k, v in pairs(_parent) do
				merged[k] = v
			end
		end
		for k, v in pairs(_data) do
			merged[k] = v
		end
		return pairs(merged)
	end

	setmetatable(ctx, mt)

	--- Create a child context (new scope)
	function ctx:push(new_data)
		return context.new(new_data or {}, self)
	end

	--- Get the raw data table
	function ctx:get_data()
		return _data
	end

	--- Get the parent context
	function ctx:get_parent()
		return _parent
	end

	--- Check if a key exists in this context or parents
	function ctx:has(key)
		if _data[key] ~= nil then
			return true
		end
		if _parent and _parent.has then
			return _parent:has(key)
		end
		return false
	end

	--- Get a value with default
	function ctx:get(key, default)
		local v = self[key]
		if v == nil then
			return default
		end
		return v
	end

	--- Set a value
	function ctx:set(key, value)
		_data[key] = value
	end

	--- Update multiple values
	function ctx:update(new_data)
		if new_data then
			for k, v in pairs(new_data) do
				_data[k] = v
			end
		end
	end

	--- Create a copy of the context
	function ctx:copy()
		local copy_data = {}
		for k, v in pairs(_data) do
			copy_data[k] = v
		end
		return context.new(copy_data, _parent)
	end

	return ctx
end

--- Create loop metadata
-- @param index number Current index (1-based)
-- @param length number Total length
-- @param items table|nil The items array (for previtem/nextitem)
-- @param parent_loop table|nil Parent loop metadata (for depth)
-- @return table Loop metadata
function context.loop_meta(index, length, items, parent_loop)
	local meta = {
		index = index,
		index0 = index - 1,
		first = index == 1,
		last = index == length,
		length = length,
		revindex = length - index + 1,
		revindex0 = length - index,
		depth = parent_loop and (parent_loop.depth + 1) or 1,
		depth0 = parent_loop and parent_loop.depth or 0,
	}

	-- Add previtem and nextitem if items array is provided
	if items then
		meta.previtem = index > 1 and items[index - 1] or nil
		meta.nextitem = index < length and items[index + 1] or nil
	end

	-- Add cycle function
	meta.cycle = function(...)
		local args = { ... }
		if #args == 0 then
			return nil
		end
		return args[((index - 1) % #args) + 1]
	end

	return meta
end

--- Create an iterator with loop metadata
-- @param items table Array to iterate
-- @return function Iterator function
function context.loop_iterator(items)
	local i = 0
	local n = #items

	return function()
		i = i + 1
		if i <= n then
			return items[i], context.loop_meta(i, n)
		end
	end
end

return context
