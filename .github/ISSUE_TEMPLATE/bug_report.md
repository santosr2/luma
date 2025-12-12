---
name: Bug Report
about: Report a bug to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## To Reproduce

Steps to reproduce the behavior:

1. Create template with '...'
2. Render with context '...'
3. See error

**Minimal reproducible example:**

```lua
local luma = require("luma")
local template = [[
-- Your template here
]]
local result = luma.render(template, {
    -- Your context here
})
```

## Expected Behavior

A clear description of what you expected to happen.

## Actual Behavior

What actually happened. Include error messages if any:

```
Error message here
```

## Environment

- **Luma Version:** [e.g., 1.0.0]
- **Lua Version:** [e.g., Lua 5.4, LuaJIT 2.1]
- **OS:** [e.g., Ubuntu 22.04, macOS 13, Windows 11]
- **Installation Method:** [e.g., LuaRocks, from source]

## Additional Context

Add any other context about the problem here:
- Does this work in Jinja2?
- Related to specific syntax (Jinja2 vs Luma native)?
- Occurs with specific data types?
- Regression from previous version?

## Possible Solution

If you have ideas on how to fix this, please share them here.

