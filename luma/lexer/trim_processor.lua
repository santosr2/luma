--- Trim processor for Luma lexer
-- Applies whitespace trimming based on trim_prev/trim_next flags
-- @module luma.lexer.trim_processor

local tokens = require("luma.lexer.tokens")
local T = tokens.types

local trim_processor = {}

--- Trim leading whitespace from text
local function trim_leading(text)
	return text:gsub("^%s+", "")
end

--- Trim trailing whitespace from text
local function trim_trailing(text)
	return text:gsub("%s+$", "")
end

--- Process a token stream to apply trim flags
-- @param token_stream table Array of tokens
-- @return table Modified token stream
function trim_processor.process(token_stream)
	local i = 1
	while i <= #token_stream do
		local token = token_stream[i]

		-- If this token has trim_prev, trim trailing whitespace from previous TEXT token
		if token.trim_prev then
			-- Look backward for the previous TEXT token
			for j = i - 1, 1, -1 do
				local prev = token_stream[j]
				if prev.type == T.TEXT then
					prev.value = trim_trailing(prev.value)
					-- If the TEXT token becomes empty, we could remove it, but keep it for now
					break
				elseif prev.type ~= T.NEWLINE then
					-- Stop if we hit a non-TEXT, non-NEWLINE token
					break
				end
			end
		end

		-- If this token has trim_next, trim leading whitespace from next TEXT token
		if token.trim_next then
			-- Look forward for the next TEXT token
			for j = i + 1, #token_stream do
				local next_token = token_stream[j]
				if next_token.type == T.TEXT then
					next_token.value = trim_leading(next_token.value)
					break
				elseif next_token.type ~= T.NEWLINE then
					-- Stop if we hit a non-TEXT, non-NEWLINE token
					break
				end
			end
		end

		i = i + 1
	end

	return token_stream
end

return trim_processor
