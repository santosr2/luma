--- AST node definitions for Luma
-- Defines all node types used in the abstract syntax tree
-- @module luma.parser.ast

local ast = {}

--- Node types enumeration
ast.types = {
    -- Root
    TEMPLATE = "TEMPLATE",              -- Root node containing all content

    -- Content nodes
    TEXT = "TEXT",                      -- Raw text content
    INTERPOLATION = "INTERPOLATION",    -- Variable/expression interpolation

    -- Control flow
    IF = "IF",                          -- If/elif/else block
    FOR = "FOR",                        -- For loop
    LET = "LET",                        -- Variable assignment

    -- Macros and includes
    MACRO_DEF = "MACRO_DEF",            -- Macro definition
    MACRO_CALL = "MACRO_CALL",          -- Macro invocation
    INCLUDE = "INCLUDE",                -- Include another template
    IMPORT = "IMPORT",                  -- Import macros from another template

    -- Expression nodes
    LITERAL = "LITERAL",                -- String, number, boolean, nil
    IDENTIFIER = "IDENTIFIER",          -- Variable reference
    MEMBER_ACCESS = "MEMBER_ACCESS",    -- foo.bar
    INDEX_ACCESS = "INDEX_ACCESS",      -- foo[expr]
    FUNCTION_CALL = "FUNCTION_CALL",    -- func(args)
    FILTER = "FILTER",                  -- expr | filter
    PIPELINE = "PIPELINE",              -- expr |> filter()
    BINARY_OP = "BINARY_OP",            -- expr op expr
    UNARY_OP = "UNARY_OP",              -- op expr
    TABLE = "TABLE",                    -- {key: value} or [a, b, c]
    TEST = "TEST",                      -- expr is test / expr is not test

    -- Special
    RAW = "RAW",                        -- Raw text block (no processing)
    AUTOESCAPE = "AUTOESCAPE",          -- Autoescape block
    COMMENT = "COMMENT",                -- Comment (not rendered)

    -- Loop control
    BREAK = "BREAK",                    -- Break out of loop
    CONTINUE = "CONTINUE",              -- Continue to next iteration

    -- Template inheritance
    EXTENDS = "EXTENDS",                -- @extends "base.html"
    BLOCK = "BLOCK",                    -- @block name ... @end
}

local N = ast.types

--- Create a node with common fields
-- @param node_type string Node type from ast.types
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Node base
local function make_node(node_type, line, column)
    return {
        type = node_type,
        line = line,
        column = column,
    }
end

--- Create a template root node
-- @param body table Array of content nodes
-- @param line number|nil Line number
-- @return table Template node
function ast.template(body, line)
    local node = make_node(N.TEMPLATE, line, 1)
    node.body = body or {}
    return node
end

--- Create a text node
-- @param value string Text content
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Text node
function ast.text(value, line, column)
    local node = make_node(N.TEXT, line, column)
    node.value = value
    return node
end

--- Create an interpolation node
-- @param expression table Expression node
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Interpolation node
function ast.interpolation(expression, line, column)
    local node = make_node(N.INTERPOLATION, line, column)
    node.expression = expression
    return node
end

--- Create an if node
-- @param condition table Condition expression
-- @param then_body table Array of nodes for true branch
-- @param else_body table|nil Array of nodes for false branch (may include elif)
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table If node
function ast.if_node(condition, then_body, else_body, line, column)
    local node = make_node(N.IF, line, column)
    node.condition = condition
    node.then_body = then_body or {}
    node.else_body = else_body  -- Can be nil, array, or another IF node (for elif)
    return node
end

--- Create a for loop node
-- @param var_names string|table Loop variable name(s) - string or array for tuple unpacking
-- @param iterable table Expression for iterable
-- @param body table Array of body nodes
-- @param else_body table|nil Array of nodes for empty iteration
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table For node
function ast.for_node(var_names, iterable, body, else_body, line, column)
    local node = make_node(N.FOR, line, column)
    -- Support both single variable name and array of names for tuple unpacking
    if type(var_names) == "string" then
        node.var_names = { var_names }
        node.var_name = var_names  -- Keep for backwards compatibility
    else
        node.var_names = var_names
        node.var_name = var_names[1]  -- Keep for backwards compatibility
    end
    node.iterable = iterable
    node.body = body or {}
    node.else_body = else_body  -- Optional @else for empty iteration
    return node
end

--- Create a let (assignment) node
-- @param name string Variable name
-- @param value table Expression for value
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Let node
function ast.let(name, value, line, column)
    local node = make_node(N.LET, line, column)
    node.name = name
    node.value = value
    return node
end

--- Create a macro definition node
-- @param name string Macro name
-- @param params table Array of parameter names
-- @param body table Array of body nodes
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Macro definition node
function ast.macro_def(name, params, body, line, column)
    local node = make_node(N.MACRO_DEF, line, column)
    node.name = name
    node.params = params or {}
    node.body = body or {}
    return node
end

--- Create a macro call node
-- @param name string Macro name
-- @param args table Array of argument expressions
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Macro call node
function ast.macro_call(name, args, line, column)
    local node = make_node(N.MACRO_CALL, line, column)
    node.name = name
    node.args = args or {}
    return node
end

--- Create an include node
-- @param path table|string Path expression or string
-- @param with_context boolean|nil Whether to include with current context
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Include node
function ast.include(path, with_context, line, column)
    local node = make_node(N.INCLUDE, line, column)
    node.path = path
    node.with_context = with_context ~= false  -- default true
    return node
end

--- Create an import node
-- @param path table|string Path expression or string
-- @param names table|nil Specific names to import (nil = all)
-- @param alias string|nil Alias for the import
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Import node
function ast.import(path, names, alias, line, column)
    local node = make_node(N.IMPORT, line, column)
    node.path = path
    node.names = names  -- nil means import all
    node.alias = alias
    return node
end

--- Create a literal node
-- @param value any Literal value
-- @param literal_type string "string", "number", "boolean", or "nil"
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Literal node
function ast.literal(value, literal_type, line, column)
    local node = make_node(N.LITERAL, line, column)
    node.value = value
    node.literal_type = literal_type
    return node
end

--- Create an identifier node
-- @param name string Variable name
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Identifier node
function ast.identifier(name, line, column)
    local node = make_node(N.IDENTIFIER, line, column)
    node.name = name
    return node
end

--- Create a member access node (foo.bar)
-- @param object table Object expression
-- @param member string Member name
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Member access node
function ast.member_access(object, member, line, column)
    local node = make_node(N.MEMBER_ACCESS, line, column)
    node.object = object
    node.member = member
    return node
end

--- Create an index access node (foo[expr])
-- @param object table Object expression
-- @param index table Index expression
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Index access node
function ast.index_access(object, index, line, column)
    local node = make_node(N.INDEX_ACCESS, line, column)
    node.object = object
    node.index = index
    return node
end

--- Create a function call node
-- @param callee table Function expression
-- @param args table Array of argument expressions
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Function call node
function ast.function_call(callee, args, line, column)
    local node = make_node(N.FUNCTION_CALL, line, column)
    node.callee = callee
    node.args = args or {}
    return node
end

--- Create a filter node (expr | filter)
-- @param expression table Input expression
-- @param filter_name string Filter name
-- @param args table|nil Filter positional arguments
-- @param named_args table|nil Filter named arguments (name -> expression)
-- @param line number|nil Line number  
-- @param column number|nil Column number
-- @return table Filter node
function ast.filter(expression, filter_name, args, named_args, line, column)
    local node = make_node(N.FILTER, line, column)
    node.expression = expression
    node.filter_name = filter_name
    node.args = args or {}
    node.named_args = named_args
    return node
end

--- Create a pipeline node (expr |> filter())
-- @param expression table Input expression
-- @param filter_call table Filter call expression
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Pipeline node
function ast.pipeline(expression, filter_call, line, column)
    local node = make_node(N.PIPELINE, line, column)
    node.expression = expression
    node.filter_call = filter_call
    return node
end

--- Create a binary operation node
-- @param operator string Operator ("+", "-", "*", "/", "==", etc.)
-- @param left table Left operand expression
-- @param right table Right operand expression
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Binary operation node
function ast.binary_op(operator, left, right, line, column)
    local node = make_node(N.BINARY_OP, line, column)
    node.operator = operator
    node.left = left
    node.right = right
    return node
end

--- Create a unary operation node
-- @param operator string Operator ("not", "-")
-- @param operand table Operand expression
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Unary operation node
function ast.unary_op(operator, operand, line, column)
    local node = make_node(N.UNARY_OP, line, column)
    node.operator = operator
    node.operand = operand
    return node
end

--- Create a table/array literal node
-- @param entries table Array of {key, value} pairs (key may be nil for array)
-- @param is_array boolean True if array syntax [a, b, c]
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Table node
function ast.table_literal(entries, is_array, line, column)
    local node = make_node(N.TABLE, line, column)
    node.entries = entries or {}
    node.is_array = is_array or false
    return node
end

--- Create a test expression node (is / is not)
-- @param expression table Expression to test
-- @param test_name string Name of the test (e.g., "defined", "string")
-- @param args table|nil Test arguments (for tests like divisibleby(n))
-- @param negated boolean True if "is not" was used
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Test node
function ast.test(expression, test_name, args, negated, line, column)
    local node = make_node(N.TEST, line, column)
    node.expression = expression
    node.test_name = test_name
    node.args = args or {}
    node.negated = negated or false
    return node
end

--- Create a break node
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Break node
function ast.break_node(line, column)
    return make_node(N.BREAK, line, column)
end

--- Create a continue node
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Continue node
function ast.continue_node(line, column)
    return make_node(N.CONTINUE, line, column)
end

--- Create an extends node
-- @param path string|table Template path to extend
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Extends node
function ast.extends(path, line, column)
    local node = make_node(N.EXTENDS, line, column)
    node.path = path
    return node
end

--- Create a block node
-- @param name string Block name
-- @param body table Array of body nodes
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Block node
function ast.block(name, body, line, column)
    local node = make_node(N.BLOCK, line, column)
    node.name = name
    node.body = body or {}
    return node
end

--- Create a raw block node
-- @param content string Raw content (not processed)
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Raw node
function ast.raw(content, line, column)
    local node = make_node(N.RAW, line, column)
    node.content = content
    return node
end

--- Create an autoescape block node
-- @param enabled boolean|string Autoescape mode (true, false, or format like "html")
-- @param body table Array of body nodes
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Autoescape node
function ast.autoescape(enabled, body, line, column)
    local node = make_node(N.AUTOESCAPE, line, column)
    node.enabled = enabled
    node.body = body or {}
    return node
end

--- Create a comment node
-- @param content string Comment content
-- @param line number|nil Line number
-- @param column number|nil Column number
-- @return table Comment node
function ast.comment(content, line, column)
    local node = make_node(N.COMMENT, line, column)
    node.content = content
    return node
end

--- Check if a node is of a specific type
-- @param node table Node to check
-- @param node_type string Expected type
-- @return boolean True if node matches type
function ast.is(node, node_type)
    return node and node.type == node_type
end

--- Pretty print an AST node for debugging
-- @param node table Node to print
-- @param indent number|nil Indentation level
-- @return string Formatted string
function ast.format(node, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)

    if not node then
        return prefix .. "nil"
    end

    if type(node) ~= "table" then
        return prefix .. tostring(node)
    end

    if not node.type then
        -- Array of nodes
        local parts = { prefix .. "[" }
        for i, child in ipairs(node) do
            table.insert(parts, ast.format(child, indent + 1))
        end
        table.insert(parts, prefix .. "]")
        return table.concat(parts, "\n")
    end

    local parts = { prefix .. node.type }

    -- Add relevant fields based on node type
    if node.value ~= nil then
        table.insert(parts, prefix .. "  value: " .. tostring(node.value))
    end
    if node.name then
        table.insert(parts, prefix .. "  name: " .. node.name)
    end
    if node.operator then
        table.insert(parts, prefix .. "  operator: " .. node.operator)
    end
    if node.member then
        table.insert(parts, prefix .. "  member: " .. node.member)
    end
    if node.filter_name then
        table.insert(parts, prefix .. "  filter: " .. node.filter_name)
    end
    if node.var_name then
        table.insert(parts, prefix .. "  var: " .. node.var_name)
    end

    -- Add child nodes
    if node.body then
        table.insert(parts, prefix .. "  body:")
        for _, child in ipairs(node.body) do
            table.insert(parts, ast.format(child, indent + 2))
        end
    end
    if node.expression then
        table.insert(parts, prefix .. "  expression:")
        table.insert(parts, ast.format(node.expression, indent + 2))
    end
    if node.condition then
        table.insert(parts, prefix .. "  condition:")
        table.insert(parts, ast.format(node.condition, indent + 2))
    end
    if node.then_body then
        table.insert(parts, prefix .. "  then:")
        for _, child in ipairs(node.then_body) do
            table.insert(parts, ast.format(child, indent + 2))
        end
    end
    if node.else_body then
        table.insert(parts, prefix .. "  else:")
        if node.else_body.type then
            table.insert(parts, ast.format(node.else_body, indent + 2))
        else
            for _, child in ipairs(node.else_body) do
                table.insert(parts, ast.format(child, indent + 2))
            end
        end
    end
    if node.left then
        table.insert(parts, prefix .. "  left:")
        table.insert(parts, ast.format(node.left, indent + 2))
    end
    if node.right then
        table.insert(parts, prefix .. "  right:")
        table.insert(parts, ast.format(node.right, indent + 2))
    end
    if node.operand then
        table.insert(parts, prefix .. "  operand:")
        table.insert(parts, ast.format(node.operand, indent + 2))
    end
    if node.object then
        table.insert(parts, prefix .. "  object:")
        table.insert(parts, ast.format(node.object, indent + 2))
    end
    if node.index then
        table.insert(parts, prefix .. "  index:")
        table.insert(parts, ast.format(node.index, indent + 2))
    end
    if node.callee then
        table.insert(parts, prefix .. "  callee:")
        table.insert(parts, ast.format(node.callee, indent + 2))
    end
    if node.args and #node.args > 0 then
        table.insert(parts, prefix .. "  args:")
        for _, arg in ipairs(node.args) do
            table.insert(parts, ast.format(arg, indent + 2))
        end
    end
    if node.iterable then
        table.insert(parts, prefix .. "  iterable:")
        table.insert(parts, ast.format(node.iterable, indent + 2))
    end

    return table.concat(parts, "\n")
end

return ast
