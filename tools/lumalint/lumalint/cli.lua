---@module lumalint.cli
--- Command-line interface for Lumalint

local lumalint = require("lumalint.init")

local cli = {}

--- Print usage information
local function print_usage()
    print([[ -- luacheck: ignore
Lumalint - Linter for Luma templates

Usage:
  lumalint [OPTIONS] FILES...

Options:
  -h, --help              Show this help message
  -v, --version           Show version information
  --strict                Treat warnings as errors
  --max-line-length N     Set maximum line length (default: 120)
  --format FORMAT         Output format: text|json (default: text)
  --no-color              Disable colored output

Examples:
  lumalint template.luma
  lumalint templates/**/*.luma
  lumalint --strict --max-line-length 100 .

Exit Codes:
  0  No issues found
  1  Issues found (or errors with --strict)
  2  Fatal error (file not found, etc.)
]])
end

--- Print version information
local function print_version()
    print("Lumalint v0.1.0")
    print("Luma template linter")
end

--- Parse command-line arguments
---@param args string[] Command-line arguments
---@return table options Parsed options
---@return string[] files Files to lint
local function parse_args(args)
    local options = {
        strict = false,
        max_line_length = 120,
        format = "text",
        color = true,
    }
    local files = {}

    local i = 1
    while i <= #args do
        local arg = args[i]

        if arg == "-h" or arg == "--help" then
            print_usage()
            os.exit(0)
        elseif arg == "-v" or arg == "--version" then
            print_version()
            os.exit(0)
        elseif arg == "--strict" then
            options.strict = true
        elseif arg == "--max-line-length" then
            i = i + 1
            options.max_line_length = tonumber(args[i])
            if not options.max_line_length then
                io.stderr:write("Error: --max-line-length requires a number\n")
                os.exit(2)
            end
        elseif arg == "--format" then
            i = i + 1
            options.format = args[i]
            if options.format ~= "text" and options.format ~= "json" then
                io.stderr:write("Error: --format must be 'text' or 'json'\n")
                os.exit(2)
            end
        elseif arg == "--no-color" then
            options.color = false
        elseif arg:sub(1, 1) == "-" then
            io.stderr:write("Error: Unknown option: " .. arg .. "\n")
            print_usage()
            os.exit(2)
        else
            table.insert(files, arg)
        end

        i = i + 1
    end

    return options, files
end

--- Find Luma files in directory
---@param dir string Directory path
---@return string[] files List of Luma files
local function find_luma_files(dir)
    local files = {}

    -- Use find command (Unix) or dir command (Windows)
    local handle
    if package.config:sub(1, 1) == "/" then
        -- Unix
        handle = io.popen("find " .. dir .. " -name '*.luma' -o -name '*.j2' 2>/dev/null")
    else
        -- Windows
        handle = io.popen("dir /s /b " .. dir .. "\\*.luma " .. dir .. "\\*.j2 2>nul")
    end

    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
    end

    return files
end

--- Format output as JSON
---@param results table<string, LintMessage[]> Linting results by file
---@return string json JSON output
local function format_json(results)
    local output = {}

    for filename, messages in pairs(results) do
        local file_result = {
            file = filename,
            messages = messages,
        }
        table.insert(output, file_result)
    end

    -- Simple JSON encoding
    local json_parts = {}
    table.insert(json_parts, "[")

    for i, result in ipairs(output) do
        if i > 1 then
            table.insert(json_parts, ",")
        end

        table.insert(json_parts, string.format(
            '{"file":%q,"messages":[',
            result.file
        ))

        for j, msg in ipairs(result.messages) do
            if j > 1 then
                table.insert(json_parts, ",")
            end

            table.insert(json_parts, string.format(
                '{"rule":%q,"message":%q,"line":%d,"column":%d,"severity":%q}',
                msg.rule,
                msg.message,
                msg.line,
                msg.column,
                msg.severity
            ))
        end

        table.insert(json_parts, "]}")
    end

    table.insert(json_parts, "]")
    return table.concat(json_parts)
end

--- Main CLI function
---@param args string[] Command-line arguments
---@return number exit_code Exit code
function cli.main(args)
    local options, files = parse_args(args)

    if #files == 0 then
        io.stderr:write("Error: No files specified\n")
        print_usage()
        return 2
    end

    -- Expand directories
    local all_files = {}
    for _, file in ipairs(files) do
        -- Check if it's a directory
        local attr = io.open(file, "r")
        if attr then
            attr:close()
            table.insert(all_files, file)
        else
            -- Try as directory
            local dir_files = find_luma_files(file)
            for _, f in ipairs(dir_files) do
                table.insert(all_files, f)
            end
        end
    end

    if #all_files == 0 then
        io.stderr:write("Error: No Luma files found\n")
        return 2
    end

    -- Lint all files
    local results = {}
    local total_issues = 0
    local total_errors = 0

    for _, file in ipairs(all_files) do
        local lint_options = {
            rules = lumalint.default_options.rules,
            ignore_vars = lumalint.default_options.ignore_vars,
            max_line_length = options.max_line_length,
            strict = options.strict,
        }

        local messages = lumalint.lint_file(file, lint_options)
        results[file] = messages

        total_issues = total_issues + #messages

        -- Count errors
        for _, msg in ipairs(messages) do
            if msg.severity == "error" or (options.strict and msg.severity == "warning") then
                total_errors = total_errors + 1
            end
        end
    end

    -- Output results
    if options.format == "json" then
        print(format_json(results))
    else
        -- Text format
        for file, messages in pairs(results) do
            print(lumalint.format_messages(messages, file))
            print()
        end

        -- Summary
        print(string.format(
            "Summary: %d file(s) checked, %d issue(s) found (%d error(s))",
            #all_files,
            total_issues,
            total_errors
        ))
    end

    -- Exit code
    if total_errors > 0 then
        return 1
    elseif total_issues > 0 and options.strict then
        return 1
    else
        return 0
    end
end

return cli
