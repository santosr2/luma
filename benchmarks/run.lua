#!/usr/bin/env luajit
--- Benchmark runner
-- Usage: luajit benchmarks/run.lua

package.path = package.path .. ";./?.lua;./?/init.lua"

local benchmarks = require("benchmarks.benchmark")

-- Run benchmarks
benchmarks.run_all()

