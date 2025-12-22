// Package luma provides Go bindings for the Luma template engine.
//
// Luma is a fast, clean templating language with full Jinja2 compatibility.
// This package uses gopher-lua to execute Luma templates from Go.
//
// Example usage:
//
//	result, err := luma.Render("Hello, $name!", map[string]interface{}{
//	    "name": "World",
//	})
//	if err != nil {
//	    log.Fatal(err)
//	}
//	fmt.Println(result) // Hello, World!
package luma

import (
	_ "embed"
	"fmt"

	lua "github.com/yuin/gopher-lua"
)

//go:embed lua/luma/init.lua
var lumaInitCode string

//go:embed lua/luma/compiler/init.lua
var lumaCompilerInit string

//go:embed lua/luma/compiler/codegen.lua
var lumaCompilerCodegen string

//go:embed lua/luma/lexer/init.lua
var lumaLexerInit string

//go:embed lua/luma/lexer/native.lua
var lumaLexerNative string

//go:embed lua/luma/lexer/jinja.lua
var lumaLexerJinja string

//go:embed lua/luma/lexer/tokens.lua
var lumaLexerTokens string

//go:embed lua/luma/lexer/inline_detector.lua
var lumaLexerInlineDetector string

//go:embed lua/luma/lexer/trim_processor.lua
var lumaLexerTrimProcessor string

//go:embed lua/luma/parser/init.lua
var lumaParserInit string

//go:embed lua/luma/parser/ast.lua
var lumaParserAst string

//go:embed lua/luma/parser/expressions.lua
var lumaParserExpressions string

//go:embed lua/luma/runtime/init.lua
var lumaRuntimeInit string

//go:embed lua/luma/runtime/context.lua
var lumaRuntimeContext string

//go:embed lua/luma/runtime/sandbox.lua
var lumaRuntimeSandbox string

//go:embed lua/luma/filters/init.lua
var lumaFiltersInit string

//go:embed lua/luma/utils/init.lua
var lumaUtilsInit string

//go:embed lua/luma/utils/errors.lua
var lumaUtilsErrors string

//go:embed lua/luma/utils/compat.lua
var lumaUtilsCompat string

//go:embed lua/luma/utils/warnings.lua
var lumaUtilsWarnings string

//go:embed lua/luma/version.lua
var lumaVersion string

// Render renders a template string with the given context.
// This is the simplest way to render a template.
func Render(template string, context interface{}) (string, error) {
	L := lua.NewState()
	defer L.Close()

	if err := loadLumaModules(L); err != nil {
		return "", fmt.Errorf("failed to load Luma modules: %w", err)
	}

	// Convert context to Lua table
	ctxTable := goToLua(L, context)
	L.SetGlobal("__go_context", ctxTable)

	// Call luma.render(template, context)
	luaCode := fmt.Sprintf(`
		local luma = require("luma")
		local template = %q
		local context = __go_context
		return luma.render(template, context)
	`, template)

	if err := L.DoString(luaCode); err != nil {
		return "", fmt.Errorf("render error: %w", err)
	}

	result := L.ToString(-1)
	L.Pop(1)
	return result, nil
}

// loadLumaModules loads all Luma Lua modules into the Lua state
func loadLumaModules(L *lua.LState) error {
	modules := map[string]string{
		"luma":                         lumaInitCode,
		"luma.version":                 lumaVersion,
		"luma.compiler.init":           lumaCompilerInit,
		"luma.compiler.codegen":        lumaCompilerCodegen,
		"luma.lexer.init":              lumaLexerInit,
		"luma.lexer.native":            lumaLexerNative,
		"luma.lexer.jinja":             lumaLexerJinja,
		"luma.lexer.tokens":            lumaLexerTokens,
		"luma.lexer.inline_detector":   lumaLexerInlineDetector,
		"luma.lexer.trim_processor":    lumaLexerTrimProcessor,
		"luma.parser.init":             lumaParserInit,
		"luma.parser.ast":              lumaParserAst,
		"luma.parser.expressions":      lumaParserExpressions,
		"luma.runtime.init":            lumaRuntimeInit,
		"luma.runtime.context":         lumaRuntimeContext,
		"luma.runtime.sandbox":         lumaRuntimeSandbox,
		"luma.filters.init":            lumaFiltersInit,
		"luma.utils.init":              lumaUtilsInit,
		"luma.utils.errors":            lumaUtilsErrors,
		"luma.utils.compat":            lumaUtilsCompat,
		"luma.utils.warnings":          lumaUtilsWarnings,
	}

	// Register preload functions for each module
	for name, code := range modules {
		moduleName := name
		moduleCode := code
		preloadFunc := func(L *lua.LState) int {
			if err := L.DoString(moduleCode); err != nil {
				L.RaiseError("failed to load module %s: %s", moduleName, err.Error())
				return 0
			}
			return 1
		}
		
		L.PreloadModule(moduleName, preloadFunc)
		
		// Also register without .init suffix for init.lua files
		// So "luma.lexer.init" is also accessible as "luma.lexer"
		if len(moduleName) > 5 && moduleName[len(moduleName)-5:] == ".init" {
			shortName := moduleName[:len(moduleName)-5]
			L.PreloadModule(shortName, preloadFunc)
		}
	}

	return nil
}

// goToLua converts a Go value to a Lua value
func goToLua(L *lua.LState, val interface{}) lua.LValue {
	if val == nil {
		return lua.LNil
	}

	switch v := val.(type) {
	case bool:
		return lua.LBool(v)
	case int:
		return lua.LNumber(v)
	case int64:
		return lua.LNumber(v)
	case float64:
		return lua.LNumber(v)
	case string:
		return lua.LString(v)
	case []interface{}:
		tbl := L.NewTable()
		for i, item := range v {
			tbl.RawSetInt(i+1, goToLua(L, item))
		}
		return tbl
	case map[string]interface{}:
		tbl := L.NewTable()
		for key, item := range v {
			tbl.RawSetString(key, goToLua(L, item))
		}
		return tbl
	default:
		// Try to handle as generic map or slice using reflection
		return lua.LString(fmt.Sprintf("%v", v))
	}
}
