--- Code generator for Luma
-- Transforms AST into executable Lua code
-- @module luma.compiler.codegen

local ast = require("luma.parser.ast")
local errors = require("luma.utils.errors")

local N = ast.types
local codegen = {}

--- Code generation context
local function create_context()
    return {
        indent = 0,
        lines = {},
        var_counter = 0,
        in_macro = false,
        macros = {},
    }
end

--- Generate a unique variable name
local function gen_var(ctx, prefix)
    ctx.var_counter = ctx.var_counter + 1
    return "__" .. (prefix or "v") .. ctx.var_counter
end

--- Add a line of code
local function emit(ctx, code)
    local indent = string.rep("  ", ctx.indent)
    table.insert(ctx.lines, indent .. code)
end

--- Add code without indentation
local function emit_raw(ctx, code)
    table.insert(ctx.lines, code)
end

--- Increase indentation
local function indent(ctx)
    ctx.indent = ctx.indent + 1
end

--- Decrease indentation
local function dedent(ctx)
    ctx.indent = ctx.indent - 1
end

--- Escape a Lua string
local function escape_lua_string(s)
    return (s:gsub("\\", "\\\\")
             :gsub("\n", "\\n")
             :gsub("\r", "\\r")
             :gsub("\t", "\\t")
             :gsub("\"", "\\\"")
             :gsub("%z", "\\000"))
end

--- Generate code for an expression
-- @param node table AST node
-- @param ctx table Context
-- @return string Lua expression string
function codegen.gen_expression(node, ctx)
    if not node then
        return "nil"
    end

    local t = node.type

    if t == N.LITERAL then
        if node.literal_type == "string" then
            return '"' .. escape_lua_string(node.value) .. '"'
        elseif node.literal_type == "nil" then
            return "nil"
        elseif node.literal_type == "boolean" then
            return node.value and "true" or "false"
        else
            return tostring(node.value)
        end
    end

    if t == N.IDENTIFIER then
        -- Special handling for super() function in template inheritance
        if node.name == "super" then
            return "(__super or function() return '' end)"
        end
        -- Special handling for namespace() builtin
        if node.name == "namespace" then
            return "__runtime.namespace"
        end
        return "__ctx[\"" .. node.name .. "\"]"
    end

    if t == N.MEMBER_ACCESS then
        local obj = codegen.gen_expression(node.object, ctx)
        return "(" .. obj .. " and " .. obj .. "[\"" .. node.member .. "\"])"
    end

    if t == N.INDEX_ACCESS then
        local obj = codegen.gen_expression(node.object, ctx)
        local idx = codegen.gen_expression(node.index, ctx)
        return "(" .. obj .. " and " .. obj .. "[" .. idx .. "])"
    end

    if t == N.FUNCTION_CALL then
        local callee = codegen.gen_expression(node.callee, ctx)
        local args = {}

        -- Add positional arguments
        for _, arg in ipairs(node.args) do
            table.insert(args, codegen.gen_expression(arg, ctx))
        end

        -- Add named arguments as a table (if present)
        if node.named_args and next(node.named_args) then
            local named_parts = {}
            for name, value_node in pairs(node.named_args) do
                local value_code = codegen.gen_expression(value_node, ctx)
                table.insert(named_parts, "[\"" .. name .. "\"]=" .. value_code)
            end
            table.insert(args, "{" .. table.concat(named_parts, ",") .. "}")
        end

        return callee .. "(" .. table.concat(args, ", ") .. ")"
    end

    if t == N.FILTER then
        local expr = codegen.gen_expression(node.expression, ctx)
        local args = { expr }

        -- Add positional arguments
        for _, arg in ipairs(node.args) do
            table.insert(args, codegen.gen_expression(arg, ctx))
        end

        -- If there are named arguments, add them as a table
        if node.named_args then
            local named_parts = {}
            for name, value_node in pairs(node.named_args) do
                local value_code = codegen.gen_expression(value_node, ctx)
                table.insert(named_parts, "[\"" .. name .. "\"]=" .. value_code)
            end
            table.insert(args, "{" .. table.concat(named_parts, ",") .. "}")
        end

        return "__filters[\"" .. node.filter_name .. "\"](" .. table.concat(args, ", ") .. ")"
    end

    if t == N.PIPELINE then
        local expr = codegen.gen_expression(node.expression, ctx)
        local filter_call = node.filter_call

        if filter_call.type == N.FUNCTION_CALL then
            -- Get the filter function
            local callee = codegen.gen_expression(filter_call.callee, ctx)
            local args = { expr }
            for _, arg in ipairs(filter_call.args) do
                table.insert(args, codegen.gen_expression(arg, ctx))
            end
            return callee .. "(" .. table.concat(args, ", ") .. ")"
        else
            -- Just call it as a function with expr as first arg
            local filter = codegen.gen_expression(filter_call, ctx)
            return filter .. "(" .. expr .. ")"
        end
    end

    if t == N.BINARY_OP then
        local left = codegen.gen_expression(node.left, ctx)
        local right = codegen.gen_expression(node.right, ctx)
        local op = node.operator

        -- Handle membership operators
        if op == "in" then
            return "(__runtime.contains(" .. right .. ", " .. left .. "))"
        elseif op == "not_in" then
            return "(not __runtime.contains(" .. right .. ", " .. left .. "))"
        end

        -- Map operators
        if op == "!=" then
            op = "~="
        end

        return "(" .. left .. " " .. op .. " " .. right .. ")"
    end

    if t == N.UNARY_OP then
        local operand = codegen.gen_expression(node.operand, ctx)
        return "(" .. node.operator .. " " .. operand .. ")"
    end

    if t == N.TABLE then
        local entries = {}
        local is_array = true
        
        for i, entry in ipairs(node.entries) do
            if entry.key then
                is_array = false
                local key = codegen.gen_expression(entry.key, ctx)
                local value = codegen.gen_expression(entry.value, ctx)
                
                -- Wrap nested table literals for Python-like methods
                if entry.value.type == N.TABLE then
                    local nested_is_array = true
                    for _, ne in ipairs(entry.value.entries) do
                        if ne.key then
                            nested_is_array = false
                            break
                        end
                    end
                    value = nested_is_array and ("__runtime.list(" .. value .. ")") or ("__runtime.dict(" .. value .. ")")
                end
                
                table.insert(entries, "[" .. key .. "] = " .. value)
            else
                local value = codegen.gen_expression(entry.value, ctx)
                
                -- Wrap nested table literals for Python-like methods
                if entry.value.type == N.TABLE then
                    local nested_is_array = true
                    for _, ne in ipairs(entry.value.entries) do
                        if ne.key then
                            nested_is_array = false
                            break
                        end
                    end
                    value = nested_is_array and ("__runtime.list(" .. value .. ")") or ("__runtime.dict(" .. value .. ")")
                end
                
                table.insert(entries, value)
            end
        end
        
        local table_code = "{" .. table.concat(entries, ", ") .. "}"
        
        -- Only wrap if we're in an assignment context (indicated by ctx.wrap_tables)
        if ctx.wrap_tables then
            if is_array then
                return "__runtime.list(" .. table_code .. ")"
            else
                return "__runtime.dict(" .. table_code .. ")"
            end
        end
        
        return table_code
    end

    if t == N.TEST then
        local expr = codegen.gen_expression(node.expression, ctx)
        local test_name = node.test_name
        local args_code = { expr }
        for _, arg in ipairs(node.args) do
            table.insert(args_code, codegen.gen_expression(arg, ctx))
        end
        local test_call = "__tests[\"" .. test_name .. "\"](" .. table.concat(args_code, ", ") .. ")"
        if node.negated then
            return "(not " .. test_call .. ")"
        end
        return "(" .. test_call .. ")"
    end
    
    if t == N.TERNARY then
        local condition = codegen.gen_expression(node.condition, ctx)
        local value = codegen.gen_expression(node.value, ctx)
        local alternative = codegen.gen_expression(node.alternative, ctx)
        -- Lua ternary: (condition and value or alternative)
        -- But needs special handling if value is false/nil
        return "(" .. condition .. " and " .. value .. " or " .. alternative .. ")"
    end

    errors.raise(errors.compile("Unknown expression type: " .. tostring(t), node.line, node.column))
end

--- Generate code for a node
-- @param node table AST node
-- @param ctx table Context
function codegen.gen_node(node, ctx)
    if not node then
        return
    end

    local t = node.type

    if t == N.TEMPLATE then
        for _, child in ipairs(node.body) do
            codegen.gen_node(child, ctx)
        end
        return
    end

    if t == N.TEXT then
        emit(ctx, "__out[#__out + 1] = \"" .. escape_lua_string(node.value) .. "\"")
        return
    end

    if t == N.RAW then
        emit(ctx, "__out[#__out + 1] = \"" .. escape_lua_string(node.content) .. "\"")
        return
    end

    if t == N.AUTOESCAPE then
        -- Save current autoescape state
        emit(ctx, "do")
        ctx.indent = ctx.indent + 1
        emit(ctx, "local __old_autoescape = __autoescape")

        -- Set new autoescape mode
        if type(node.enabled) == "boolean" then
            emit(ctx, "__autoescape = " .. tostring(node.enabled))
        elseif type(node.enabled) == "string" then
            -- Format name (e.g., "html", "xml") - treat as enabled
            emit(ctx, "__autoescape = true")
        else
            emit(ctx, "__autoescape = true")
        end

        -- Render body with new autoescape setting
        for _, child in ipairs(node.body) do
            codegen.gen_node(child, ctx)
        end

        -- Restore old autoescape state
        emit(ctx, "__autoescape = __old_autoescape")
        ctx.indent = ctx.indent - 1
        emit(ctx, "end")
        return
    end

    if t == N.WITH then
        -- Create scoped context with provided variables
        emit(ctx, "do")
        ctx.indent = ctx.indent + 1
        emit(ctx, "-- With block: scoped variables")
        emit(ctx, "local __with_ctx = {}")
        emit(ctx, "setmetatable(__with_ctx, {__index = __ctx})")
        emit(ctx, "local __saved_ctx = __ctx")
        emit(ctx, "__ctx = __with_ctx")

        -- Set the variables in the scoped context
        for _, var in ipairs(node.variables) do
            local value = codegen.gen_expression(var.value, ctx)
            emit(ctx, "__ctx[\"" .. var.name .. "\"] = " .. value)
        end

        -- Render body with scoped context
        for _, child in ipairs(node.body) do
            codegen.gen_node(child, ctx)
        end

        -- Restore previous context
        emit(ctx, "__ctx = __saved_ctx")
        ctx.indent = ctx.indent - 1
        emit(ctx, "end")
        return
    end

    if t == N.FILTER_BLOCK then
        -- Capture output, apply filter to it
        emit(ctx, "do")
        ctx.indent = ctx.indent + 1
        emit(ctx, "-- Filter block: capture and filter content")
        emit(ctx, "local __old_out = __out")
        emit(ctx, "__out = {}")

        -- Render body
        for _, child in ipairs(node.body) do
            codegen.gen_node(child, ctx)
        end

        -- Capture the output
        emit(ctx, "local __filtered_content = table.concat(__out)")
        emit(ctx, "__out = __old_out")

        -- Apply the filter
        local filter_args = {"__filtered_content"}
        for _, arg in ipairs(node.args) do
            table.insert(filter_args, codegen.gen_expression(arg, ctx))
        end

        -- Add named arguments if present
        if node.named_args then
            local named_parts = {}
            for name, value_node in pairs(node.named_args) do
                local value_code = codegen.gen_expression(value_node, ctx)
                table.insert(named_parts, "[\"" .. name .. "\"]=" .. value_code)
            end
            table.insert(filter_args, "{" .. table.concat(named_parts, ",") .. "}")
        end

        emit(ctx, "__out[#__out + 1] = __filters[\"" .. node.filter_name .. "\"](" .. table.concat(filter_args, ", ") .. ")")

        ctx.indent = ctx.indent - 1
        emit(ctx, "end")
        return
    end

    if t == N.DO then
        if node.is_assignment then
            -- Handle assignment: target = value
            -- node.expression is the target (e.g., ns.count or ns.data["key"])
            -- node.value is the value expression

            -- Generate assignment-friendly code for the target
            local target_expr = node.expression
            local value = codegen.gen_expression(node.value, ctx)

            if target_expr.type == N.MEMBER_ACCESS then
                -- For member access: obj.field
                local obj = codegen.gen_expression(target_expr.object, ctx)
                local field = target_expr.member
                emit(ctx, "if " .. obj .. " then " .. obj .. "[\"" .. field .. "\"] = " .. value .. " end")
            elseif target_expr.type == N.INDEX_ACCESS then
                -- For index access: obj[key]
                local obj = codegen.gen_expression(target_expr.object, ctx)
                local index = codegen.gen_expression(target_expr.index, ctx)
                emit(ctx, "if " .. obj .. " then " .. obj .. "[" .. index .. "] = " .. value .. " end")
            elseif target_expr.type == N.IDENT then
                -- For simple variable: x
                emit(ctx, "__ctx[\"" .. target_expr.name .. "\"] = " .. value)
            else
                -- Fallback for other expression types
                local target = codegen.gen_expression(target_expr, ctx)
                emit(ctx, target .. " = " .. value)
            end
        else
            -- Execute expression for side effects, discard result
            local expr = codegen.gen_expression(node.expression, ctx)
            emit(ctx, "do local _ = " .. expr .. " end")
        end
        return
    end

    if t == N.COMMENT then
        -- Comments are not rendered
        return
    end

    if t == N.INTERPOLATION then
        local expr = codegen.gen_expression(node.expression, ctx)
        local col = node.column or 1
        emit(ctx, "__out[#__out + 1] = __esc(" .. expr .. ", " .. col .. ")")
        return
    end

    if t == N.IF then
        codegen.gen_if(node, ctx)
        return
    end

    if t == N.FOR then
        codegen.gen_for(node, ctx)
        return
    end

    if t == N.LET then
        if node.is_block then
            -- Block syntax: @set x %}...{% endset
            -- Capture the rendered output of the body
            emit(ctx, "do")
            ctx.indent = ctx.indent + 1
            emit(ctx, "local __old_out = __out")
            emit(ctx, "__out = {}")

            -- Render the body
            for _, child in ipairs(node.value) do
                codegen.gen_node(child, ctx)
            end

            -- Capture the output and assign to variable
            emit(ctx, "__ctx[\"" .. node.name .. "\"] = table.concat(__out)")
            emit(ctx, "__out = __old_out")
            ctx.indent = ctx.indent - 1
            emit(ctx, "end")
        elseif node.is_member_assignment then
            -- Member assignment syntax: @let ns.found = value
            local value = codegen.gen_expression(node.value, ctx)

            -- Build the member access chain
            local path = node.member_path
            local obj = "__ctx[\"" .. path[1] .. "\"]"
            for i = 2, #path do
                obj = "(" .. obj .. " and " .. obj .. "[\"" .. path[i] .. "\"])"
            end

            -- For assignment, we need to set the last member
            local parent = "__ctx[\"" .. path[1] .. "\"]"
            for i = 2, #path - 1 do
                parent = parent .. "[\"" .. path[i] .. "\"]"
            end

            emit(ctx, "if " .. parent .. " then")
            ctx.indent = ctx.indent + 1
            emit(ctx, parent .. "[\"" .. path[#path] .. "\"] = " .. value)
            ctx.indent = ctx.indent - 1
            emit(ctx, "end")
        else
            -- Assignment syntax: @let x = value
            -- Set flag to wrap table literals recursively
            local old_wrap_tables = ctx.wrap_tables
            ctx.wrap_tables = true
            local value = codegen.gen_expression(node.value, ctx)
            ctx.wrap_tables = old_wrap_tables
            
            emit(ctx, "__ctx[\"" .. node.name .. "\"] = " .. value)
        end
        return
    end

    if t == N.MACRO_DEF then
        codegen.gen_macro_def(node, ctx)
        return
    end

    if t == N.MACRO_CALL then
        codegen.gen_macro_call(node, ctx)
        return
    end

    if t == N.INCLUDE then
        codegen.gen_include(node, ctx)
        return
    end

    if t == N.IMPORT then
        codegen.gen_import(node, ctx)
        return
    end

    if t == N.BREAK then
        -- Break out of the current loop
        if ctx.current_loop_var then
            emit(ctx, ctx.current_loop_var .. "_break = true")
            emit(ctx, "break")  -- Break out of repeat block
        end
        return
    end

    if t == N.CONTINUE then
        -- Continue to next iteration (break out of repeat block)
        emit(ctx, "break")  -- Break out of repeat block, but not the for loop
        return
    end

    if t == N.BLOCK then
        -- Block content - simply render its body (inheritance is resolved before codegen)

        -- If block is scoped, create isolated context
        if node.scoped then
            emit(ctx, "do")
            ctx.indent = ctx.indent + 1
            emit(ctx, "-- Scoped block: create isolated context")
            emit(ctx, "local __scoped_ctx = {}")
            emit(ctx, "setmetatable(__scoped_ctx, {__index = __ctx})")
            emit(ctx, "local __saved_ctx = __ctx")
            emit(ctx, "__ctx = __scoped_ctx")
        end

        -- If block has a parent (for super() support), make it available
        if node.parent_block then
            -- Save current block stack
            emit(ctx, "local __prev_super = __super")
            emit(ctx, "__super = function()")
            indent(ctx)
            emit(ctx, "local __out = {}")

            -- Render parent block content
            for _, child in ipairs(node.parent_block.body) do
                codegen.gen_node(child, ctx)
            end

            emit(ctx, "return table.concat(__out)")
            dedent(ctx)
            emit(ctx, "end")
        end

        -- Render child block content
        for _, child in ipairs(node.body) do
            codegen.gen_node(child, ctx)
        end

        -- Restore previous block stack
        if node.parent_block then
            emit(ctx, "__super = __prev_super")
        end

        -- Restore context if block was scoped
        if node.scoped then
            emit(ctx, "__ctx = __saved_ctx")
            ctx.indent = ctx.indent - 1
            emit(ctx, "end")
        end
        return
    end

    if t == N.EXTENDS then
        -- Extends is handled at compile time, not at runtime
        -- Should not appear in codegen (inheritance resolution removes it)
        return
    end

    -- Unknown node type - skip
end

--- Generate code for if statement
function codegen.gen_if(node, ctx)
    local cond = codegen.gen_expression(node.condition, ctx)
    emit(ctx, "if " .. cond .. " then")
    indent(ctx)

    for _, child in ipairs(node.then_body) do
        codegen.gen_node(child, ctx)
    end

    dedent(ctx)

    if node.else_body then
        if node.else_body.type == N.IF then
            -- elif chain
            emit(ctx, "else")
            indent(ctx)
            codegen.gen_if(node.else_body, ctx)
            dedent(ctx)
        else
            emit(ctx, "else")
            indent(ctx)
            for _, child in ipairs(node.else_body) do
                codegen.gen_node(child, ctx)
            end
            dedent(ctx)
        end
    end

    emit(ctx, "end")
end

--- Check if a body contains break or continue nodes
local function has_loop_control(body)
    for _, node in ipairs(body) do
        if node.type == N.BREAK or node.type == N.CONTINUE then
            return true
        end
        -- Check nested blocks
        if node.body and has_loop_control(node.body) then
            return true
        end
        if node.then_body and has_loop_control(node.then_body) then
            return true
        end
        if node.else_body then
            if type(node.else_body) == "table" and node.else_body.type then
                -- It's a single node (elif)
                if node.else_body.type == N.BREAK or node.else_body.type == N.CONTINUE then
                    return true
                end
            elseif type(node.else_body) == "table" then
                if has_loop_control(node.else_body) then
                    return true
                end
            end
        end
    end
    return false
end

--- Generate code for for loop
function codegen.gen_for(node, ctx)
    -- Detect if iterable is ipairs() or pairs() call BEFORE generating the expression
    -- If so, extract the argument for iteration
    local iterable
    local is_ipairs_call = false
    local is_pairs_call = false
    
    if node.iterable and node.iterable.type == "FUNCTION_CALL" then
        local callee = node.iterable.callee
        if callee and (callee.type == "IDENT" or callee.type == "IDENTIFIER") then
            local fn_name = callee.name
            if fn_name == "ipairs" and node.iterable.args and #node.iterable.args >= 1 then
                is_ipairs_call = true
                -- Extract the first argument (the table to iterate)
                iterable = codegen.gen_expression(node.iterable.args[1], ctx)
            elseif fn_name == "pairs" and node.iterable.args and #node.iterable.args >= 1 then
                is_pairs_call = true
                -- Extract the first argument (the table to iterate)
                iterable = codegen.gen_expression(node.iterable.args[1], ctx)
            end
        end
    end
    
    -- If not ipairs/pairs, generate the iterable expression normally
    if not iterable then
        iterable = codegen.gen_expression(node.iterable, ctx)
    end
    
    local var_names = node.var_names or { node.var_name }  -- Support both old and new format
    local loop_var = gen_var(ctx, "loop")
    local uses_loop_control = has_loop_control(node.body)

    -- Push loop context for break/continue tracking
    local old_loop_var = ctx.current_loop_var
    ctx.current_loop_var = loop_var

    -- Create loop metadata
    emit(ctx, "do")
    indent(ctx)
    emit(ctx, "local " .. loop_var .. "_parent = __ctx[\"loop\"]")  -- Save parent loop
    emit(ctx, "local " .. loop_var .. "_items = " .. iterable .. " or {}")
    emit(ctx, "local " .. loop_var .. "_len = #" .. loop_var .. "_items")

    if uses_loop_control then
        emit(ctx, "local " .. loop_var .. "_break = false")
    end

    -- Handle empty case - for tuple unpacking, use next() to check if table is empty
    local empty_check
    if #var_names > 1 then
        empty_check = "next(" .. loop_var .. "_items) == nil"
    else
        empty_check = loop_var .. "_len == 0"
    end
    emit(ctx, "if " .. empty_check .. " then")
    indent(ctx)
    if node.else_body then
        for _, child in ipairs(node.else_body) do
            codegen.gen_node(child, ctx)
        end
    end
    dedent(ctx)
    emit(ctx, "else")
    indent(ctx)

    -- Handle tuple unpacking vs single variable
    if #var_names > 1 then
        -- Tuple unpacking: for key, value in pairs(items)
        -- Count items for pairs (since #table doesn't work for dicts)
        emit(ctx, "local " .. loop_var .. "_count = 0")
        emit(ctx, "for _ in pairs(" .. loop_var .. "_items) do " .. loop_var .. "_count = " .. loop_var .. "_count + 1 end")
        emit(ctx, "local " .. loop_var .. "_idx = 0")
        emit(ctx, "for " .. loop_var .. "_k, " .. loop_var .. "_v in pairs(" .. loop_var .. "_items) do")
        indent(ctx)
        if uses_loop_control then
            emit(ctx, "if " .. loop_var .. "_break then break end")
        end
        emit(ctx, loop_var .. "_idx = " .. loop_var .. "_idx + 1")
        emit(ctx, "__ctx[\"" .. var_names[1] .. "\"] = " .. loop_var .. "_k")
        if var_names[2] then
            emit(ctx, "__ctx[\"" .. var_names[2] .. "\"] = " .. loop_var .. "_v")
        end
        -- For tuple unpacking, we use the counted length
        emit(ctx, "__ctx[\"loop\"] = __runtime.context.loop_meta(" .. loop_var .. "_idx, " .. loop_var .. "_count, nil, " .. loop_var .. "_parent)")
    else
        -- Single variable: for i, v in ipairs(items)
        emit(ctx, "for " .. loop_var .. "_i, " .. loop_var .. "_v in ipairs(" .. loop_var .. "_items) do")
        indent(ctx)
        if uses_loop_control then
            emit(ctx, "if " .. loop_var .. "_break then break end")
        end
        emit(ctx, "__ctx[\"" .. var_names[1] .. "\"] = " .. loop_var .. "_v")
        -- Enhanced loop metadata with items and parent
        emit(ctx, "__ctx[\"loop\"] = __runtime.context.loop_meta(" .. loop_var .. "_i, " .. loop_var .. "_len, " .. loop_var .. "_items, " .. loop_var .. "_parent)")
    end

    -- Loop body - wrap in repeat...until true to allow break for continue simulation
    if uses_loop_control then
        emit(ctx, "repeat")
        indent(ctx)
    end

    -- Loop body
    for _, child in ipairs(node.body) do
        codegen.gen_node(child, ctx)
    end

    if uses_loop_control then
        dedent(ctx)
        emit(ctx, "until true")
    end

    dedent(ctx)
    emit(ctx, "end")

    -- Restore parent loop
    emit(ctx, "__ctx[\"loop\"] = " .. loop_var .. "_parent")

    dedent(ctx)
    emit(ctx, "end")
    dedent(ctx)
    emit(ctx, "end")

    -- Restore old loop context
    ctx.current_loop_var = old_loop_var
end

--- Generate code for macro definition
function codegen.gen_macro_def(node, ctx)
    local macro_name = node.name
    local params = node.params
    local defaults = node.defaults or {}

    emit(ctx, "__macros[\"" .. macro_name .. "\"] = function(" .. table.concat(params, ", ") .. ")")
    indent(ctx)
    emit(ctx, "local __macro_out = {}")
    emit(ctx, "local __old_out = __out")
    emit(ctx, "__out = __macro_out")

    -- Create local context with parameters
    emit(ctx, "local __old_ctx = __ctx")
    emit(ctx, "__ctx = setmetatable({}, {__index = __old_ctx})")

    for _, param in ipairs(params) do
        -- Apply default value if parameter is nil and a default exists
        if defaults[param] then
            local default_code = codegen.gen_expression(defaults[param], ctx)
            emit(ctx, "__ctx[\"" .. param .. "\"] = " .. param .. " ~= nil and " .. param .. " or " .. default_code)
        else
            emit(ctx, "__ctx[\"" .. param .. "\"] = " .. param)
        end
    end

    -- Macro body
    for _, child in ipairs(node.body) do
        codegen.gen_node(child, ctx)
    end

    emit(ctx, "__ctx = __old_ctx")
    emit(ctx, "__out = __old_out")
    emit(ctx, "return table.concat(__macro_out)")
    dedent(ctx)
    emit(ctx, "end")
end

--- Generate code for macro call
-- Supports call with caller pattern: {% call(item) macro() %}...{% endcall %}
function codegen.gen_macro_call(node, ctx)
    local args = {}
    for _, arg in ipairs(node.args) do
        table.insert(args, codegen.gen_expression(arg, ctx))
    end

    -- Special case: caller() is a context function, not a macro
    if node.name == "caller" and not node.caller_body then
        -- Just output the result of calling the caller function from context
        emit(ctx, "__out[#__out + 1] = (__ctx[\"caller\"] and __ctx[\"caller\"](" .. table.concat(args, ", ") .. ") or \"\")")
        return
    end

    -- Check if this is a call-with-caller (has caller_body)
    if node.caller_body then
        -- Generate caller function
        local params = node.caller_params or {}

        emit(ctx, "do")
        ctx.indent = ctx.indent + 1
        emit(ctx, "-- Call with caller pattern")
        emit(ctx, "local __caller = function(" .. table.concat(params, ", ") .. ")")
        indent(ctx)
        emit(ctx, "local __caller_out = {}")
        emit(ctx, "local __old_out = __out")
        emit(ctx, "__out = __caller_out")

        -- Create local context with caller parameters
        emit(ctx, "local __old_ctx = __ctx")
        emit(ctx, "__ctx = setmetatable({}, {__index = __old_ctx})")

        for _, param in ipairs(params) do
            emit(ctx, "__ctx[\"" .. param .. "\"] = " .. param)
        end

        -- Render caller body
        for _, child in ipairs(node.caller_body) do
            codegen.gen_node(child, ctx)
        end

        emit(ctx, "__ctx = __old_ctx")
        emit(ctx, "__out = __old_out")
        emit(ctx, "return table.concat(__caller_out)")
        dedent(ctx)
        emit(ctx, "end")

        -- Store caller in context so macro can access it
        emit(ctx, "local __saved_caller = __ctx[\"caller\"]")
        emit(ctx, "__ctx[\"caller\"] = __caller")

        -- Call the macro
        emit(ctx, "__out[#__out + 1] = __macros[\"" .. node.name .. "\"](" .. table.concat(args, ", ") .. ")")

        -- Restore previous caller
        emit(ctx, "__ctx[\"caller\"] = __saved_caller")

        ctx.indent = ctx.indent - 1
        emit(ctx, "end")
    else
        -- Regular macro call
        emit(ctx, "__out[#__out + 1] = __macros[\"" .. node.name .. "\"](" .. table.concat(args, ", ") .. ")")
    end
end

--- Generate code for include
function codegen.gen_include(node, ctx)
    local path
    if type(node.path) == "string" then
        path = '"' .. escape_lua_string(node.path) .. '"'
    else
        path = codegen.gen_expression(node.path, ctx)
    end

    -- Build context argument based on with_context flag
    local context_arg
    if node.with_context then
        context_arg = "__ctx"
    else
        context_arg = "{}"  -- empty context
    end

    -- Handle ignore_missing flag
    if node.ignore_missing then
        emit(ctx, "do")
        ctx.indent = ctx.indent + 1
        emit(ctx, "local ok, result = pcall(__runtime.include, " .. path .. ", " .. context_arg .. ")")
        emit(ctx, "if ok then")
        ctx.indent = ctx.indent + 1
        emit(ctx, "__out[#__out + 1] = result")
        ctx.indent = ctx.indent - 1
        emit(ctx, "end")
        emit(ctx, "-- Silently ignore if template is missing")
        ctx.indent = ctx.indent - 1
        emit(ctx, "end")
    else
        emit(ctx, "__out[#__out + 1] = __runtime.include(" .. path .. ", " .. context_arg .. ")")
    end
end

--- Generate code for import
function codegen.gen_import(node, ctx)
    local path
    if type(node.path) == "string" then
        path = '"' .. escape_lua_string(node.path) .. '"'
    else
        path = codegen.gen_expression(node.path, ctx)
    end

    if node.names then
        -- Selective import: {% from "file" import x, y %}
        emit(ctx, "do")
        ctx.indent = ctx.indent + 1
        emit(ctx, "local __imported = __runtime.import(" .. path .. ")")

        for _, import_spec in ipairs(node.names) do
            local source_name = import_spec.name
            local target_name = import_spec.alias or source_name

            -- Import the specific name into context or macros
            emit(ctx, "if __imported[\"" .. source_name .. "\"] ~= nil then")
            ctx.indent = ctx.indent + 1
            emit(ctx, "__ctx[\"" .. target_name .. "\"] = __imported[\"" .. source_name .. "\"]")
            ctx.indent = ctx.indent - 1
            emit(ctx, "end")

            -- Also check if it's a macro
            emit(ctx, "if __imported.__macros and __imported.__macros[\"" .. source_name .. "\"] then")
            ctx.indent = ctx.indent + 1
            emit(ctx, "__macros[\"" .. target_name .. "\"] = __imported.__macros[\"" .. source_name .. "\"]")
            ctx.indent = ctx.indent - 1
            emit(ctx, "end")
        end

        ctx.indent = ctx.indent - 1
        emit(ctx, "end")
    elseif node.alias then
        -- Import with alias: {% import "file" as name %}
        emit(ctx, "__ctx[\"" .. node.alias .. "\"] = __runtime.import(" .. path .. ")")
    else
        -- Import all macros: {% import "file" %}
        emit(ctx, "__runtime.import_all(" .. path .. ", __macros)")
    end
end

--- Generate the complete template function
-- @param template_ast table Template AST
-- @param options table|nil Options
-- @return string Generated Lua code
function codegen.generate(template_ast, options)
    options = options or {}  -- luacheck: ignore options
    local ctx = create_context()

    -- Function header - receives globals as upvalues from the loader
    emit_raw(ctx, "local tostring, ipairs, pairs, setmetatable, type = tostring, ipairs, pairs, setmetatable, type")
    emit_raw(ctx, "local table, string, math, pcall = table, string, math, pcall")
    emit_raw(ctx, "return function(__ctx, __filters, __runtime, __macros, __tests)")
    indent(ctx)

    emit(ctx, "__ctx = __ctx or {}")
    emit(ctx, "__filters = __filters or {}")
    emit(ctx, "__macros = __macros or {}")
    emit(ctx, "__tests = __tests or {}")
    emit(ctx, "")
    emit(ctx, "-- Make Lua built-ins available in templates")
    emit(ctx, "__ctx.tostring = tostring")
    emit(ctx, "__ctx.tonumber = tonumber")
    emit(ctx, "__ctx.ipairs = ipairs")
    emit(ctx, "__ctx.pairs = pairs")
    emit(ctx, "__ctx.type = type")
    emit(ctx, "__ctx.pcall = pcall")
    emit(ctx, "__ctx.table = table")
    emit(ctx, "__ctx.string = string")
    emit(ctx, "__ctx.math = math")
    emit(ctx, "")
    emit(ctx, "local __out = {}")
    emit(ctx, "local __super = nil  -- Parent block content for super() calls")
    emit(ctx, "local __autoescape = true  -- Autoescape enabled by default")
    emit(ctx, "")

    -- Escape function - handles safe wrapper tables and indentation
    emit(ctx, "local function __esc(v, col)")
    indent(ctx)
    emit(ctx, "if v == nil then return \"\" end")
    emit(ctx, "if not __autoescape then return tostring(v) end")
    emit(ctx, "return __runtime.escape(v, col)")
    dedent(ctx)
    emit(ctx, "end")
    emit(ctx, "")

    -- Generate template body
    codegen.gen_node(template_ast, ctx)

    emit(ctx, "")
    emit(ctx, "return table.concat(__out)")

    dedent(ctx)
    emit_raw(ctx, "end")

    return table.concat(ctx.lines, "\n")
end

return codegen
