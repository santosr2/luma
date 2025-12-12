--- Inline mode detector for context-aware directive handling
-- Post-processes token stream to detect inline vs block mode
-- @module luma.lexer.inline_detector

local T = require("luma.lexer.tokens").types

local detector = {}

--- Check if text ends with newline
local function text_ends_with_newline(text)
    if not text or #text == 0 then
        return true
    end
    return text:sub(-1) == "\n"
end

--- Check if text starts with newline
local function text_starts_with_newline(text)
    if not text or #text == 0 then
        return true
    end
    return text:sub(1, 1) == "\n"
end

--- Check if token is a directive that can be inline
local function is_inlineable_directive(token_type)
    return token_type == T.DIR_IF or
           token_type == T.DIR_ELIF or
           token_type == T.DIR_ELSE or
           token_type == T.DIR_FOR or
           token_type == T.DIR_END or
           token_type == T.DIR_ENDBLOCK
end

--- Detect inline mode for directives in token stream
-- Marks directives as inline if they have text on the same line
-- Also removes directive-ending newlines for inline directives
-- @param tokens table Array of tokens
-- @return table Modified token array with inline flags
function detector.detect_inline(tokens)
    for i, token in ipairs(tokens) do
        if is_inlineable_directive(token.type) then
            local has_text_before = false
            local has_text_after = false
            local text_before_idx = nil
            local text_after_idx = nil
            
            -- Check for text before (look backwards)
            for j = i - 1, 1, -1 do
                local prev = tokens[j]
                if prev.type == T.TEXT then
                    if not text_ends_with_newline(prev.value) then
                        has_text_before = true
                        text_before_idx = j
                    end
                    break
                elseif prev.type ~= T.NEWLINE then
                    -- Found non-text, non-newline token
                    break
                end
            end
            
            -- Check for text after (look forward)
            -- The NEWLINE token right after directive marks end of directive
            local newline_idx = nil
            if i + 1 <= #tokens and tokens[i + 1].type == T.NEWLINE then
                newline_idx = i + 1
            end
            
            local start_after = newline_idx and (newline_idx + 1) or (i + 1)
            
            for j = start_after, #tokens do
                local next_tok = tokens[j]
                if next_tok.type == T.TEXT then
                    if not text_starts_with_newline(next_tok.value) then
                        has_text_after = true
                        text_after_idx = j
                    end
                    break
                elseif next_tok.type ~= T.NEWLINE then
                    -- Found non-text, non-newline token
                    break
                end
            end
            
            -- Mark as inline if text on same line before OR after
            if has_text_before or has_text_after then
                token.inline = true
                
                -- Remove the NEWLINE token that terminates the directive
                -- This prevents block-mode newline handling
                if newline_idx then
                    table.remove(tokens, newline_idx)
                    -- Adjust indices if we removed a token
                    if text_after_idx and text_after_idx > newline_idx then
                        text_after_idx = text_after_idx - 1
                    end
                end
            end
        end
    end
    
    return tokens
end

return detector

