#!/usr/bin/env luajit
--- Memory profiling for Luma
-- @module benchmarks.memory_profile

package.path = package.path .. ";./?.lua;./?/init.lua"

local luma = require("luma")

--- Get current memory usage in KB
local function get_memory()
    collectgarbage("collect")
    return collectgarbage("count")
end

--- Profile memory usage of a function
local function profile_memory(name, fn, iterations)
    iterations = iterations or 100
    
    collectgarbage("collect")
    local before = get_memory()
    
    for i = 1, iterations do
        fn()
    end
    
    collectgarbage("collect")
    local after = get_memory()
    
    local per_iteration = (after - before) / iterations
    
    return {
        name = name,
        total_kb = after - before,
        per_iteration_kb = per_iteration,
        iterations = iterations,
        before_kb = before,
        after_kb = after
    }
end

print("=" .. string.rep("=", 70))
print("  LUMA MEMORY PROFILING")
print("=" .. string.rep("=", 70))
print(string.format("Base memory: %.2f KB", get_memory()))
print("")

-- Test 1: Simple template rendering
local r1 = profile_memory("Simple Interpolation", function()
    luma.render("Hello, $name!", {name = "World"})
end)

print(string.format("%-30s %8.2f KB total  %8.3f KB/op",
    r1.name, r1.total_kb, r1.per_iteration_kb))

-- Test 2: Complex template with loops
local r2 = profile_memory("Complex Template", function()
    local template = [[
@for product in products
  <div>$product.name: $$product.price</div>
@end
]]
    luma.render(template, {
        products = {
            {name = "A", price = 10},
            {name = "B", price = 20},
            {name = "C", price = 30},
        }
    })
end)

print(string.format("%-30s %8.2f KB total  %8.3f KB/op",
    r2.name, r2.total_kb, r2.per_iteration_kb))

-- Test 3: Compilation memory
local r3 = profile_memory("Template Compilation", function()
    luma.compile("@for i in items\n  Item $i\n@end")
end)

print(string.format("%-30s %8.2f KB total  %8.3f KB/op",
    r3.name, r3.total_kb, r3.per_iteration_kb))

-- Test 4: Compiled template reuse
local template_source = "Hello, $name!"
local compiled = luma.compile(template_source)
local filters = require("luma.filters")
local runtime = require("luma.runtime")

local r4 = profile_memory("Compiled Template Reuse", function()
    compiled:render({name = "World"}, filters.get_all(), runtime)
end)

print(string.format("%-30s %8.2f KB total  %8.3f KB/op",
    r4.name, r4.total_kb, r4.per_iteration_kb))

print("")
print("=" .. string.rep("=", 70))
print(string.format("Final memory: %.2f KB", get_memory()))
print("")

-- Memory efficiency comparison
print("Memory Efficiency:")
print(string.format("  Compiled reuse is %.1fx more memory efficient than full render",
    r1.per_iteration_kb / r4.per_iteration_kb))

