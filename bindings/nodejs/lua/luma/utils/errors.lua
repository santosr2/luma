--- Error types and formatting for Luma
-- Provides structured error types with line/column information
-- @module luma.utils.errors

local errors = {}

--- Base error class
-- @table LumaError
-- @field type string Error type identifier
-- @field message string Human-readable error message
-- @field line number|nil Line number where error occurred
-- @field column number|nil Column number where error occurred
-- @field source_name string|nil Name of the template source

--- Create a new error object
-- @param error_type string The error type
-- @param message string The error message
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @param source_name string|nil Source name
-- @return table Error object
local function make_error(error_type, message, line, column, source_name)
	return {
		type = error_type,
		message = message,
		line = line,
		column = column,
		source_name = source_name or "template",
		is_luma_error = true,
	}
end

--- Create a lexer error
-- @param message string Error message
-- @param line number Line number
-- @param column number Column number
-- @param source_name string|nil Source name
-- @return table LexerError
function errors.lexer(message, line, column, source_name)
	return make_error("LexerError", message, line, column, source_name)
end

--- Create a parse error
-- @param message string Error message
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @param source_name string|nil Source name
-- @return table ParseError
function errors.parse(message, line, column, source_name)
	return make_error("ParseError", message, line, column, source_name)
end

--- Create a compile error
-- @param message string Error message
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @param source_name string|nil Source name
-- @return table CompileError
function errors.compile(message, line, column, source_name)
	return make_error("CompileError", message, line, column, source_name)
end

--- Create a runtime error
-- @param message string Error message
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @param source_name string|nil Source name
-- @return table RuntimeError
function errors.runtime(message, line, column, source_name)
	return make_error("RuntimeError", message, line, column, source_name)
end

--- Create a template not found error
-- @param template_name string Name of the template that wasn't found
-- @param search_paths table|nil Paths that were searched
-- @return table TemplateNotFoundError
function errors.template_not_found(template_name, search_paths)
	local msg = "Template not found: " .. template_name
	if search_paths and #search_paths > 0 then
		msg = msg .. " (searched: " .. table.concat(search_paths, ", ") .. ")"
	end
	return make_error("TemplateNotFoundError", msg, nil, nil, template_name)
end

--- Create a security error (sandbox violation)
-- @param message string Error message
-- @param attempted_access string|nil What was attempted
-- @return table SecurityError
function errors.security(message, attempted_access)
	local msg = message
	if attempted_access then
		msg = msg .. ": " .. attempted_access
	end
	return make_error("SecurityError", msg, nil, nil, nil)
end

--- Create an undefined variable error
-- @param var_name string Name of the undefined variable
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table UndefinedVariableError
function errors.undefined_variable(var_name, line, column)
	return make_error("UndefinedVariableError", "Undefined variable: " .. var_name, line, column, nil)
end

--- Format an error for display
-- @param err table Error object
-- @param source string|nil Original source code for context
-- @return string Formatted error message
function errors.format(err, source)
	if not err or not err.is_luma_error then
		-- Not a Luma error, return as string
		return tostring(err)
	end

	local parts = {}

	-- Error type and message
	table.insert(parts, err.type .. ": " .. err.message)

	-- Location info
	if err.line then
		local location = "  at " .. (err.source_name or "template")
		location = location .. ":" .. err.line
		if err.column then
			location = location .. ":" .. err.column
		end
		table.insert(parts, location)
	end

	-- Source context (if provided)
	if source and err.line then
		local lines = {}
		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			table.insert(lines, line)
		end

		if lines[err.line] then
			table.insert(parts, "")
			-- Show line before (if exists)
			if err.line > 1 and lines[err.line - 1] then
				table.insert(parts, string.format("  %4d | %s", err.line - 1, lines[err.line - 1]))
			end
			-- Show error line with marker
			table.insert(parts, string.format("> %4d | %s", err.line, lines[err.line]))
			-- Show column marker
			if err.column then
				local marker = string.rep(" ", err.column + 8) .. "^"
				table.insert(parts, marker)
			end
			-- Show line after (if exists)
			if lines[err.line + 1] then
				table.insert(parts, string.format("  %4d | %s", err.line + 1, lines[err.line + 1]))
			end
		end
	end

	return table.concat(parts, "\n")
end

--- Raise an error (throws)
-- @param err table Error object
-- @param source string|nil Original source for context
function errors.raise(err, source)
	error(errors.format(err, source), 2)
end

--- Check if a value is a Luma error
-- @param v any Value to check
-- @return boolean True if v is a Luma error
function errors.is_error(v)
	return type(v) == "table" and v.is_luma_error == true
end

--- Wrap a function call with error handling
-- @param fn function Function to call
-- @param ... any Arguments to pass to fn
-- @return boolean success
-- @return any result or error
function errors.try(fn, ...)
	local results = { pcall(fn, ...) }
	local ok = results[1]
	if ok then
		table.remove(results, 1)
		return true, unpack(results)
	else
		return false, results[2]
	end
end

return errors
