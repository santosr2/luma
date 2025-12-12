--- Validate command
-- @module cli.commands.validate

local luma = require("luma")

local validate = {}

function validate.execute(args)
    local template_file = args[2]
    local syntax = "auto"
    
    -- Parse arguments
    local i = 3
    while i <= #args do
        local arg = args[i]
        if arg == "--syntax" or arg == "-s" then
            syntax = args[i + 1]
            i = i + 2
        else
            i = i + 1
        end
    end
    
    if not template_file then
        print("Error: No template file specified")
        print("Usage: luma validate <template> [options]")
        os.exit(1)
    end
    
    -- Read template
    local file = io.open(template_file, "r")
    if not file then
        print("Error: Cannot open template file: " .. template_file)
        os.exit(1)
    end
    local template_source = file:read("*all")
    file:close()
    
    -- Try to compile template
    local ok, result = pcall(luma.compile, template_source, { syntax = syntax })
    
    if ok then
        print("✓ Template is valid")
        print("  File: " .. template_file)
        print("  Syntax: " .. syntax)
        print("  Lines: " .. select(2, template_source:gsub('\n', '\n')) + 1)
        os.exit(0)
    else
        print("✗ Template has errors:")
        print("  " .. tostring(result))
        os.exit(1)
    end
end

return validate

