--- Render command
-- @module cli.commands.render

local luma = require("luma")
local json = require("luma.utils.compat").json or require("cjson")

local render = {}

function render.execute(args)
    local template_file = args[2]
    local data_str = nil
    local data_file = nil
    local output_file = nil
    local syntax = "auto"
    
    -- Parse arguments
    local i = 3
    while i <= #args do
        local arg = args[i]
        if arg == "--data" or arg == "-d" then
            data_str = args[i + 1]
            i = i + 2
        elseif arg == "--data-file" or arg == "-f" then
            data_file = args[i + 1]
            i = i + 2
        elseif arg == "--output" or arg == "-o" then
            output_file = args[i + 1]
            i = i + 2
        elseif arg == "--syntax" or arg == "-s" then
            syntax = args[i + 1]
            i = i + 2
        else
            i = i + 1
        end
    end
    
    if not template_file then
        print("Error: No template file specified")
        print("Usage: luma render <template> [options]")
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
    
    -- Parse context data
    local context = {}
    if data_str then
        context = json.decode(data_str)
    elseif data_file then
        local f = io.open(data_file, "r")
        if not f then
            print("Error: Cannot open data file: " .. data_file)
            os.exit(1)
        end
        local content = f:read("*all")
        f:close()
        context = json.decode(content)
    end
    
    -- Render template
    local result = luma.render(template_source, context, { syntax = syntax })
    
    -- Output
    if output_file then
        local out = io.open(output_file, "w")
        if not out then
            print("Error: Cannot write to output file: " .. output_file)
            os.exit(1)
        end
        out:write(result)
        out:close()
        print("Output written to: " .. output_file)
    else
        print(result)
    end
end

return render

