# Luma Go Bindings

Go bindings for the Luma templating engine using gopher-lua.

## Status

🚧 **Under Development** - Foundational structure ready, implementation in progress.

## Installation

```bash
go get github.com/santosr2/luma-go
```

## Quick Start

```go
package main

import (
    "fmt"
    "github.com/santosr2/luma-go"
)

func main() {
    // Simple rendering
    result, err := luma.Render("Hello, $name!", map[string]interface{}{
        "name": "World",
    })
    if err != nil {
        panic(err)
    }
    fmt.Println(result) // Hello, World!

    // Compiled template for reuse
    tmpl, err := luma.Compile("Hello, $name!")
    if err != nil {
        panic(err)
    }
    
    result, err = tmpl.Execute(map[string]interface{}{
        "name": "Go",
    })
    fmt.Println(result) // Hello, Go!
}
```

## Architecture

### Core Components

1. **Lua VM Integration** - Uses gopher-lua for Lua execution
2. **Template API** - Go-idiomatic template interface
3. **Environment** - Configuration and customization
4. **Loader System** - File system and custom loaders
5. **Error Handling** - Go-style error reporting

### File Structure

```text
bindings/go/
├── luma.go                 # Main API
├── template.go             # Template type
├── environment.go          # Environment management
├── loader.go               # Template loaders
├── bridge.go               # Lua-Go bridge
├── go.mod                  # Go module definition
├── go.sum                  # Dependency checksums
├── examples/               # Example code
│   ├── basic.go
│   ├── helm.go
│   └── kubernetes.go
└── tests/                  # Test suite
    ├── render_test.go
    ├── compile_test.go
    └── benchmark_test.go
```

## Implementation Steps

### Phase 1: Core Functionality

- [ ] Set up Go module structure
- [ ] Integrate gopher-lua
- [ ] Embed Luma Lua source code
- [ ] Implement basic `Render()` function
- [ ] Implement `Template.Compile()` and `Template.Execute()`
- [ ] Add error handling and conversion

### Phase 2: API Design

- [ ] `Environment` type with configuration
- [ ] `FileSystemLoader` for loading templates
- [ ] Custom filter registration
- [ ] Custom test registration
- [ ] Context management

### Phase 3: Advanced Features

- [ ] Template inheritance support
- [ ] Macro support
- [ ] Include system
- [ ] Cache management
- [ ] Concurrent rendering safety

### Phase 4: Helm Integration

- [ ] Helm plugin structure
- [ ] Chart.yaml support
- [ ] Values integration
- [ ] Release info access
- [ ] Helm CLI compatibility

### Phase 5: Testing & Documentation

- [ ] Unit tests (90%+ coverage)
- [ ] Benchmarks
- [ ] Examples
- [ ] GoDoc documentation
- [ ] Tutorial

## API Reference

### Types

```go
// Template represents a compiled template
type Template struct {
    source string
    compiled *lua.LFunction
}

// Environment manages template configuration
type Environment struct {
    Loader Loader
    Filters map[string]FilterFunc
    Tests map[string]TestFunc
    Cache map[string]*Template
}

// Loader interface for loading templates
type Loader interface {
    Load(name string) (string, error)
}
```

### Functions

```go
// Render renders a template string with context
func Render(template string, context interface{}) (string, error)

// Compile compiles a template for reuse
func Compile(template string) (*Template, error)

// Execute renders a compiled template
func (t *Template) Execute(context interface{}) (string, error)

// NewEnvironment creates a new template environment
func NewEnvironment(opts ...EnvironmentOption) *Environment

// GetTemplate loads and compiles a template by name
func (env *Environment) GetTemplate(name string) (*Template, error)
```

## Dependencies

- `github.com/yuin/gopher-lua` - Lua VM for Go
- Standard library only (no external deps beyond Lua)

## Helm Plugin Integration

### Installation

```bash
helm plugin install https://github.com/santosr2/helm-luma
```

### Usage

```bash
# Use Luma templates in Helm charts
helm luma template mychart -f values.yaml

# Convert Go templates to Luma
helm luma convert templates/deployment.yaml
```

### Chart Structure

```text
mychart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.luma      # Luma templates
    ├── service.luma
    └── _helpers.luma        # Shared macros
```

### Example Template

```luma
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $Values.name
spec:
  replicas: ${Values.replicas | default(3)}
  template:
    spec:
      containers:
@for container in Values.containers
        - name: $container.name
          image: ${container.image}:${container.tag | default("latest")}
@end
```

## Performance

Target performance metrics:

- Simple template: < 1ms compile, < 0.1ms render
- Complex template: < 10ms compile, < 1ms render
- Concurrent: Thread-safe by default
- Memory: < 1MB overhead per environment

## Testing

```bash
# Run tests
go test ./...

# Run benchmarks
go test -bench=. ./...

# Coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Next Steps

1. **Set up Go module**

   ```bash
   cd bindings/go
   go mod init github.com/santosr2/luma-go
   go get github.com/yuin/gopher-lua
   ```

2. **Embed Luma source**
   - Copy Lua source files to `lua/` directory
   - Use `go:embed` to bundle Lua code

3. **Implement basic rendering**
   - Create Lua state
   - Load Luma modules
   - Call render function
   - Convert results to Go

4. **Write tests**
   - Test basic rendering
   - Test error handling
   - Test with real-world templates

5. **Build Helm plugin**
   - Create plugin.yaml
   - Implement helm-luma CLI
   - Test with real charts

## Contributing

See main [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

MIT License - See [LICENSE](../../LICENSE)
