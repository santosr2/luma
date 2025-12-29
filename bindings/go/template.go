package luma

import (
	"fmt"
	"sync"

	lua "github.com/yuin/gopher-lua"
)

// Template represents a compiled Luma template.
// Templates are safe for concurrent use after compilation.
type Template struct {
	source string
	mu     sync.RWMutex
}

// Compile compiles a template string for later execution.
// The compiled template can be executed multiple times with different contexts.
//
// Example:
//
//	tmpl, err := luma.Compile("Hello, $name!")
//	if err != nil {
//	    log.Fatal(err)
//	}
//	result, err := tmpl.Execute(map[string]interface{}{"name": "Alice"})
func Compile(source string) (*Template, error) {
	// Validate the template by attempting to parse it
	// We use a simple Render call with empty context to validate syntax
	L := lua.NewState()
	defer L.Close()

	if err := loadLumaModules(L); err != nil {
		return nil, fmt.Errorf("failed to load Luma modules: %w", err)
	}

	// Validate template syntax by attempting to parse/compile it
	luaCode := fmt.Sprintf(`
		local luma = require("luma")
		local source = %q
		
		-- Try to parse the template to validate syntax
		local ast, parse_err = luma.parse(source)
		if parse_err then
			error("Parse error: " .. tostring(parse_err))
		end
		
		return true
	`, source)

	if err := L.DoString(luaCode); err != nil {
		return nil, fmt.Errorf("compilation error: %w", err)
	}

	// Store the source for later execution
	// A full implementation would cache the compiled Lua function
	return &Template{
		source: source,
	}, nil
}

// Execute renders the compiled template with the given context.
// The context can be a map[string]interface{} or any Go value that
// can be converted to a Lua table.
func (t *Template) Execute(context interface{}) (string, error) {
	t.mu.RLock()
	defer t.mu.RUnlock()

	// For now, just use Render since we're storing source
	// A full implementation would use the compiled template
	return Render(t.source, context)
}

// Source returns the original template source code.
func (t *Template) Source() string {
	t.mu.RLock()
	defer t.mu.RUnlock()
	return t.source
}
