--- Performance benchmark suite for Luma
-- @module benchmarks.benchmark

local luma = require("luma")

local benchmarks = {}

-- Benchmark configuration
local CONFIG = {
    iterations = 1000,  -- Number of iterations per benchmark
    warmup = 100,       -- Warmup iterations
}

--- High-resolution timer (uses os.clock for CPU time)
local function gettime()
    return os.clock()
end

--- Measure execution time
local function measure(name, fn, iterations)
    iterations = iterations or CONFIG.iterations
    
    -- Warmup
    for i = 1, CONFIG.warmup do
        fn()
    end
    
    -- Collect garbage before benchmark
    collectgarbage("collect")
    
    -- Measure
    local start = gettime()
    for i = 1, iterations do
        fn()
    end
    local elapsed = gettime() - start
    
    local avg_ms = (elapsed / iterations) * 1000
    local ops_per_sec = iterations / elapsed
    
    return {
        name = name,
        total_time = elapsed,
        avg_time_ms = avg_ms,
        ops_per_sec = ops_per_sec,
        iterations = iterations
    }
end

--- Simple template rendering
function benchmarks.simple_interpolation()
    local template = "Hello, $name!"
    local context = {name = "World"}
    
    return measure("Simple Interpolation", function()
        luma.render(template, context)
    end)
end

--- Jinja2 syntax rendering
function benchmarks.jinja2_interpolation()
    local template = "Hello, {{ name }}!"
    local context = {name = "World"}
    
    return measure("Jinja2 Interpolation", function()
        luma.render(template, context, {syntax = "jinja", no_jinja_warning = true})
    end)
end

--- Loop rendering
function benchmarks.loop_rendering()
    local template = [[
@for item in items
  - $item
@end
]]
    local context = {items = {"apple", "banana", "cherry", "date", "elderberry"}}
    
    return measure("Loop Rendering (5 items)", function()
        luma.render(template, context)
    end)
end

--- Large loop rendering
function benchmarks.large_loop()
    local template = [[
@for i in items
  Item $i
@end
]]
    
    -- Generate 100 items
    local items = {}
    for i = 1, 100 do
        items[i] = i
    end
    
    local context = {items = items}
    
    return measure("Large Loop (100 items)", function()
        luma.render(template, context)
    end, 100)  -- Fewer iterations for expensive test
end

--- Conditional rendering
function benchmarks.conditional_rendering()
    local template = [[
@if user
  Welcome, $user.name!
@else
  Please log in.
@end
]]
    local context = {user = {name = "Alice"}}
    
    return measure("Conditional Rendering", function()
        luma.render(template, context)
    end)
end

--- Template with filters
function benchmarks.filter_usage()
    local template = "{{ text | upper | truncate(10) }}"
    local context = {text = "hello world from luma"}
    
    return measure("Filter Usage", function()
        luma.render(template, context, {syntax = "jinja", no_jinja_warning = true})
    end)
end

--- Template inheritance
function benchmarks.template_inheritance()
    local base = [[
@block title
Base Title
@end
@block content
Base Content
@end
]]
    
    local child = [[
@extends base
@block title
Child Title
@end
]]
    
    return measure("Template Inheritance", function()
        -- Note: This requires file-based templates
        -- For now, we'll use a simpler nested template test
        luma.render(base, {})
    end)
end

--- Complex template
function benchmarks.complex_template()
    local template = [[
@let title = "Product Catalog"
<h1>$title</h1>
@for product in products
  <div class="product">
    <h2>${product.name | title}</h2>
    <p class="price">$$product.price</p>
    @if product.in_stock
      <span class="available">In Stock</span>
    @else
      <span class="out">Out of Stock</span>
    @end
  </div>
@end
]]
    
    local context = {
        products = {
            {name = "laptop", price = 999, in_stock = true},
            {name = "mouse", price = 29, in_stock = true},
            {name = "keyboard", price = 79, in_stock = false},
            {name = "monitor", price = 299, in_stock = true},
        }
    }
    
    return measure("Complex Template", function()
        luma.render(template, context)
    end)
end

--- Compilation benchmark
function benchmarks.compilation_speed()
    local template = [[
@for i in range(10)
  @if i % 2 == 0
    Even: $i
  @else
    Odd: $i
  @end
@end
]]
    
    return measure("Template Compilation", function()
        luma.compile(template)
    end)
end

--- Reusable compiled template
function benchmarks.compiled_template_reuse()
    local template = "Hello, $name!"
    local compiled = luma.compile(template)
    local contexts = {
        {name = "Alice"},
        {name = "Bob"},
        {name = "Charlie"},
    }
    
    local i = 1
    return measure("Compiled Template Reuse", function()
        local filters = require("luma.filters")
        local runtime = require("luma.runtime")
        compiled:render(contexts[((i - 1) % #contexts) + 1], filters.get_all(), runtime)
        i = i + 1
    end)
end

--- Run all benchmarks
function benchmarks.run_all()
    print("=" .. string.rep("=", 70))
    print("  LUMA PERFORMANCE BENCHMARKS")
    print("=" .. string.rep("=", 70))
    print(string.format("Iterations: %d (warmup: %d)", CONFIG.iterations, CONFIG.warmup))
    print("")
    
    local tests = {
        benchmarks.simple_interpolation,
        benchmarks.jinja2_interpolation,
        benchmarks.loop_rendering,
        benchmarks.conditional_rendering,
        benchmarks.filter_usage,
        benchmarks.template_inheritance,
        benchmarks.complex_template,
        benchmarks.compilation_speed,
        benchmarks.compiled_template_reuse,
        benchmarks.large_loop,
    }
    
    local results = {}
    for _, test in ipairs(tests) do
        local result = test()
        table.insert(results, result)
        
        print(string.format("%-30s %8.3f ms/op  %10.0f ops/sec",
            result.name,
            result.avg_time_ms,
            result.ops_per_sec
        ))
    end
    
    print("")
    print("=" .. string.rep("=", 70))
    
    -- Summary
    local fastest = results[1]
    local slowest = results[1]
    for _, r in ipairs(results) do
        if r.avg_time_ms < fastest.avg_time_ms then
            fastest = r
        end
        if r.avg_time_ms > slowest.avg_time_ms then
            slowest = r
        end
    end
    
    print(string.format("Fastest: %s (%.3f ms/op)", fastest.name, fastest.avg_time_ms))
    print(string.format("Slowest: %s (%.3f ms/op)", slowest.name, slowest.avg_time_ms))
    print(string.format("Ratio: %.1fx", slowest.avg_time_ms / fastest.avg_time_ms))
    
    return results
end

return benchmarks

