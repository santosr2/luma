# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Luma is a Lua-powered templating engine with a clean, directive-based syntax as an alternative to Jinja2. It uses `$variable` interpolation and `@directive` line-based control flow.

## Development Commands

```bash
# Run all tests (uses busted test framework)
busted spec/

# Run a single test file
busted spec/lexer_spec.lua

# Run tests with coverage
busted --coverage spec/
```

## Architecture

The codebase follows a compiler pipeline architecture:

```
Template Source → Lexer → Parser → Compiler → Runtime Execution
```

### Core Modules (luma/)

- **lexer/** - Tokenizes template source into tokens (TEXT, INTERPOLATION, DIRECTIVE, etc.)
  - `tokens.lua` - Token type definitions
  - `native.lua` - Native Lua lexer implementation

- **parser/** - Converts tokens into an Abstract Syntax Tree
  - `ast.lua` - AST node definitions
  - `expressions.lua` - Expression parsing (variables, filters, operators)

- **compiler/** - Generates executable Lua code from AST
  - `codegen.lua` - Code generation logic

- **runtime/** - Executes compiled templates
  - `context.lua` - Variable context management
  - `sandbox.lua` - Sandboxed Lua execution environment

- **filters/** - Built-in template filters (upper, lower, join, default, etc.)

- **utils/** - Shared utilities
  - `compat.lua` - Lua version compatibility
  - `errors.lua` - Error handling

### Entry Point

`luma/init.lua` is the main module that exposes the public API:
- `luma.render(template, context)` - One-shot rendering
- `luma.compile(template)` - Compile for reuse
- `luma.create_environment()` - Custom environment with filters/globals

## Template Syntax Reference

- Interpolation: `$var`, `$user.name`, `${expr | filter}`
- Directives: `@if`, `@elif`, `@else`, `@for`, `@let`, `@end`
- Comments: `@# comment`
- Escape: `$$` for literal `$`

## Testing

Tests are in `spec/` using the busted framework. The `.busted` config sets up the Lua path for running tests.
