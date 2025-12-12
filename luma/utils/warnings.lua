--- Warning system for Luma
-- Handles deprecation warnings and suggestions
-- @module luma.utils.warnings

local warnings = {}

-- Track which warnings have been shown (per process)
local shown_warnings = {}

--- Check if warning should be suppressed
-- @param key string Warning key
-- @param options table|nil User options
-- @return boolean True if warning should be suppressed
local function is_suppressed(key, options)
    -- Check if already shown this warning
    if shown_warnings[key] then
        return true
    end

    -- Check environment variable
    local env_var = "LUMA_NO_" .. key:upper() .. "_WARNING"
    if os.getenv(env_var) == "1" then
        return true
    end

    -- Check global suppression
    if os.getenv("LUMA_NO_WARNINGS") == "1" then
        return true
    end

    -- Check user options
    if options then
        if options.no_warnings then
            return true
        end
        if options["no_" .. key .. "_warning"] then
            return true
        end
    end

    return false
end

--- Emit a warning message
-- @param key string Warning key (e.g., "jinja", "deprecated")
-- @param message string Warning message
-- @param options table|nil User options
local function emit(key, message, options)
    if is_suppressed(key, options) then
        return
    end

    -- Mark as shown
    shown_warnings[key] = true

    -- Output to stderr
    io.stderr:write("\n")
    io.stderr:write(message)
    io.stderr:write("\n\n")
end

--- Show Jinja2 syntax deprecation warning
-- @param options table|nil User options
function warnings.jinja_syntax(options)
    local message = [[
⚠️  Jinja2 Syntax Detected
────────────────────────────────────────────────────────
This template uses Jinja2 syntax ({{ }}, {% %}).
While fully supported, we recommend migrating to Luma's
cleaner native syntax for better readability.

Example migration:
  Jinja2:  {% if user %}Hello {{ user.name }}!{% endif %}
  Luma:    @if user
             Hello $user.name!
           @end

Run:  luma migrate template.jinja > template.luma

To suppress this warning:
  - Pass option: { no_jinja_warning = true }
  - Or set: LUMA_NO_JINJA_WARNING=1
────────────────────────────────────────────────────────]]

    emit("jinja", message, options)
end

--- Reset warning state (useful for testing)
function warnings.reset()
    shown_warnings = {}
end

--- Check if a warning has been shown
-- @param key string Warning key
-- @return boolean
function warnings.was_shown(key)
    return shown_warnings[key] == true
end

return warnings

