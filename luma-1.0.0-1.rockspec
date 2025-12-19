package = "luma"
version = "1.0.0-1"
source = {
   url = "git+https://github.com/santosr2/luma.git",
   tag = "v1.0.0"
}
description = {
   summary = "A fast, clean templating language with full Jinja2 compatibility",
   detailed = [[
      Luma is a modern templating engine that combines clean,
      readable syntax with full Jinja2 compatibility. Perfect for
      DevOps, configuration management, and web applications.

      Features:
      - Clean native syntax (@if, @for, $var)
      - Full Jinja2 compatibility for seamless migration
      - Smart whitespace handling for YAML/config files
      - Template inheritance and macros
      - 80+ built-in filters and tests
      - LuaJIT-powered performance
      - Production-ready with 589 passing tests
   ]],
   homepage = "https://github.com/santosr2/luma",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.5"
}
build = {
   type = "builtin",
   modules = {
      luma = "luma/init.lua",
      ["luma.compiler.init"] = "luma/compiler/init.lua",
      ["luma.compiler.codegen"] = "luma/compiler/codegen.lua",
      ["luma.lexer.init"] = "luma/lexer/init.lua",
      ["luma.lexer.native"] = "luma/lexer/native.lua",
      ["luma.lexer.jinja"] = "luma/lexer/jinja.lua",
      ["luma.lexer.tokens"] = "luma/lexer/tokens.lua",
      ["luma.lexer.inline_detector"] = "luma/lexer/inline_detector.lua",
      ["luma.lexer.trim_processor"] = "luma/lexer/trim_processor.lua",
      ["luma.parser.init"] = "luma/parser/init.lua",
      ["luma.parser.ast"] = "luma/parser/ast.lua",
      ["luma.parser.expressions"] = "luma/parser/expressions.lua",
      ["luma.runtime.init"] = "luma/runtime/init.lua",
      ["luma.runtime.context"] = "luma/runtime/context.lua",
      ["luma.runtime.sandbox"] = "luma/runtime/sandbox.lua",
      ["luma.filters.init"] = "luma/filters/init.lua",
      ["luma.utils.init"] = "luma/utils/init.lua",
      ["luma.utils.compat"] = "luma/utils/compat.lua",
      ["luma.utils.errors"] = "luma/utils/errors.lua",
      ["luma.utils.warnings"] = "luma/utils/warnings.lua",
      ["luma.version"] = "luma/version.lua"
   },
   install = {
      bin = {
         luma = "bin/luma"
      }
   }
}
