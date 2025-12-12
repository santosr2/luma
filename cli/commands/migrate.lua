--- Migrate command - Convert Jinja2 templates to Luma syntax
-- @module cli.commands.migrate

local luma = require("luma")
local converter = require("cli.migrate.converter")

local migrate = {}

migrate.description = "Convert Jinja2 templates to Luma syntax"
migrate.usage = [[
Usage: luma migrate [options] <file>

Convert Jinja2 template syntax to native Luma syntax.

Options:
  --in-place, -i        Overwrite the input file with converted output
  --output, -o <file>   Write output to specified file
  --dry-run, -n         Show conversion without writing files
  --diff                Show diff between original and converted
  --from <syntax>       Source syntax (default: auto-detect)
  --to <syntax>         Target syntax (default: luma)
  --help, -h            Show this help message

Examples:
  # Convert and print to stdout
  luma migrate template.jinja

  # Convert and overwrite
  luma migrate template.jinja --in-place

  # Convert to different file
  luma migrate template.jinja --output template.luma

  # Show what would change
  luma migrate template.jinja --dry-run --diff

  # Convert entire directory
  luma migrate templates/ --output luma-templates/
]]

--- Parse command line arguments
local function parse_args(args)
    local options = {
        in_place = false,
        output = nil,
        dry_run = false,
        diff = false,
        from = "auto",
        to = "luma",
        help = false,
        files = {}
    }

    local i = 1
    while i <= #args do
        local arg = args[i]

        if arg == "--help" or arg == "-h" then
            options.help = true
        elseif arg == "--in-place" or arg == "-i" then
            options.in_place = true
        elseif arg == "--output" or arg == "-o" then
            i = i + 1
            options.output = args[i]
        elseif arg == "--dry-run" or arg == "-n" then
            options.dry_run = true
        elseif arg == "--diff" then
            options.diff = true
        elseif arg == "--from" then
            i = i + 1
            options.from = args[i]
        elseif arg == "--to" then
            i = i + 1
            options.to = args[i]
        elseif not arg:match("^%-") then
            table.insert(options.files, arg)
        else
            error("Unknown option: " .. arg)
        end

        i = i + 1
    end

    return options
end

--- Show diff between original and converted
local function show_diff(original, converted, filename)
    print("--- " .. filename .. " (original)")
    print("+++ " .. filename .. " (converted)")
    print("")

    local orig_lines = {}
    for line in original:gmatch("[^\n]*") do
        table.insert(orig_lines, line)
    end

    local conv_lines = {}
    for line in converted:gmatch("[^\n]*") do
        table.insert(conv_lines, line)
    end

    -- Simple line-by-line diff
    local max_lines = math.max(#orig_lines, #conv_lines)
    for i = 1, max_lines do
        local orig = orig_lines[i] or ""
        local conv = conv_lines[i] or ""

        if orig ~= conv then
            if orig ~= "" then
                print("- " .. orig)
            end
            if conv ~= "" then
                print("+ " .. conv)
            end
        else
            print("  " .. orig)
        end
    end
end

--- Read file contents
local function read_file(path)
    local file, err = io.open(path, "r")
    if not file then
        error("Cannot read file: " .. path .. " (" .. (err or "unknown error") .. ")")
    end
    local content = file:read("*all")
    file:close()
    return content
end

--- Write file contents
local function write_file(path, content)
    local file, err = io.open(path, "w")
    if not file then
        error("Cannot write file: " .. path .. " (" .. (err or "unknown error") .. ")")
    end
    file:write(content)
    file:close()
end

--- Execute migrate command
function migrate.execute(args)
    local options = parse_args(args)

    if options.help or #options.files == 0 then
        print(migrate.usage)
        return 0
    end

    if #options.files > 1 and options.output and not options.output:match("/$") then
        error("When converting multiple files, --output must be a directory")
    end

    for _, filepath in ipairs(options.files) do
        -- Read source file
        local source = read_file(filepath)

        -- Convert syntax
        local converted, err = converter.convert(source, {
            from = options.from,
            to = options.to
        })

        if not converted then
            io.stderr:write("Error converting " .. filepath .. ": " .. (err or "unknown error") .. "\n")
            return 1
        end

        -- Handle output
        if options.dry_run then
            if options.diff then
                show_diff(source, converted, filepath)
            else
                print("=== " .. filepath .. " (converted) ===")
                print(converted)
            end
        elseif options.in_place then
            write_file(filepath, converted)
            io.stderr:write("Converted: " .. filepath .. "\n")
        elseif options.output then
            write_file(options.output, converted)
            io.stderr:write("Converted: " .. filepath .. " -> " .. options.output .. "\n")
        else
            -- Print to stdout
            io.write(converted)
        end
    end

    return 0
end

return migrate

