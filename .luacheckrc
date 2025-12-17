-- Luacheck configuration for Luma
-- https://github.com/mpeterv/luacheck

std = "lua51+busted"

-- Don't report unused self arguments for methods
self = false

-- Ignore some pedantic warnings
ignore = {
    "211", -- Unused local variable (sometimes needed for clarity)
    "212", -- Unused argument (callbacks, interface compliance)
    "213", -- Unused loop variable
    "631", -- Line is too long (handled by max_line_length)
}

-- Global variables that are allowed
globals = {
    -- Busted test globals
    "describe",
    "it",
    "before_each",
    "after_each",
    "setup",
    "teardown",
    "pending",
    "assert",
    "spy",
    "stub",
    "mock",
}

-- Read-only globals
read_globals = {
    "string",
    "table",
    "math",
    "io",
    "os",
    "debug",
    "coroutine",
    "package",
}

-- Exclude paths
exclude_files = {
    ".luarocks/",
    ".install/",
    "lua_modules/",
    "**/spec/fixtures/",
}

-- Line length limits
max_line_length = 120
max_code_line_length = 120
max_comment_line_length = 120
max_cyclomatic_complexity = 15

-- Specific file configurations
files["spec/**/*.lua"] = {
    std = "+busted",
    globals = {
        "describe",
        "it",
        "before_each",
        "after_each",
        "setup",
        "teardown",
        "pending",
        "assert",
        "spy",
        "stub",
        "mock",
    }
}

files["luma/version.lua"] = {
    ignore = {"111", "112", "113"}, -- Allow redefining globals for version info
}
