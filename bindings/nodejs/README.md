# @luma/templates

TypeScript/JavaScript bindings for the Luma template engine.

Fast, clean templating with full Jinja2 compatibility for Node.js applications.

## Status

✅ **Production Ready** - v0.1.0 - Fully implemented, tested, and documented.

## Features

- ✅ Full Luma syntax support (`$var`, `@if`, `@for`, etc.)
- ✅ 100% Jinja2 compatibility (`{{ var }}`, `{% if %}`, etc.)
- ✅ TypeScript type definitions
- ✅ Synchronous and asynchronous API
- ✅ Template compilation for reuse
- ✅ File rendering support
- ✅ Zero native dependencies (pure JavaScript via Fengari)
- ✅ Comprehensive test suite (50+ tests)
- ✅ Works in Node.js 16+

## Installation

```bash
npm install @luma/templates
# or
yarn add @luma/templates
# or
pnpm add @luma/templates
```

## Quick Start

### JavaScript

```javascript
const { render, compile } = require('@luma/templates');

// Simple rendering
const result = render('Hello, $name!', { name: 'World' });
console.log(result); // Hello, World!

// Compiled template (reusable)
const tmpl = compile('Hello, $name!');
console.log(tmpl.render({ name: 'Alice' }));
console.log(tmpl.render({ name: 'Bob' }));
```

### TypeScript

```typescript
import { render, compile, Template } from '@luma/templates';

// With type safety
interface Context {
  name: string;
  items: string[];
}

const template = compile<Context>(`
@for item in items
  - $item
@end
`);

const result = template.render({
  name: 'Shopping List',
  items: ['apple', 'banana', 'cherry'],
});
```

## API

### `render(template, context?, options?)`

Render a template string with context data.

```typescript
function render(
  template: string,
  context?: Context,
  options?: RenderOptions
): string
```

**Parameters:**

- `template`: Template string to render
- `context`: Optional data object for template variables
- `options`: Optional rendering options

**Returns:** Rendered string

**Example:**

```typescript
const result = render('$greeting, $name!', {
  greeting: 'Hello',
  name: 'World'
});
```

### `compile(template)`

Compile a template for reuse.

```typescript
function compile(template: string): Template
```

**Parameters:**

- `template`: Template string to compile

**Returns:** `Template` instance

**Example:**

```typescript
const tmpl = compile('User: $name ($role)');
console.log(tmpl.render({ name: 'Alice', role: 'Admin' }));
console.log(tmpl.render({ name: 'Bob', role: 'User' }));
```

### `renderFile(filePath, context?, options?)`

Render a template from a file (async).

```typescript
async function renderFile(
  filePath: string,
  context?: Context,
  options?: RenderOptions
): Promise<string>
```

**Example:**

```typescript
const result = await renderFile('./template.luma', { name: 'World' });
```

### `renderFileSync(filePath, context?, options?)`

Render a template from a file (sync).

```typescript
function renderFileSync(
  filePath: string,
  context?: Context,
  options?: RenderOptions
): string
```

### `Template` Class

```typescript
class Template {
  render(context?: Context, options?: RenderOptions): string;
  getSource(): string;
}
```

## Syntax

### Luma Native Syntax

```luma
@# Variables
$name
${expression}

@# Conditionals
@if condition
  Content
@else
  Alternative
@end

@# Loops
@for item in items
  - $item
@end

@# Filters
$text | upper
$value | default("fallback")
```

### Jinja2 Compatibility

```jinja2
{{ name }}
{{ expression }}

{% if condition %}
  Content
{% else %}
  Alternative
{% endif %}

{% for item in items %}
  - {{ item }}
{% endfor %}

{{ text | upper }}
{{ value | default("fallback") }}
```

## Examples

### Basic Variable Interpolation

```typescript
render('Hello, $name!', { name: 'World' });
// Output: Hello, World!
```

### Conditionals

```typescript
const tmpl = `@if premium
Premium User
@else
Free User
@end`;

render(tmpl, { premium: true });
// Output: Premium User
```

### Loops

```typescript
const tmpl = `@for item in items
- $item
@end`;

render(tmpl, { items: ['apple', 'banana', 'cherry'] });
// Output:
// - apple
// - banana
// - cherry
```

### Filters

```typescript
render('$name | upper', { name: 'alice' });
// Output: ALICE

render('${missing | default("N/A")}', {});
// Output: N/A
```

### Kubernetes Manifests

```typescript
const template = `apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app_name
spec:
  replicas: ${replicas | default(3)}
  template:
    spec:
      containers:
        - name: $app_name
          image: ${image}:${tag}
          ports:
            - containerPort: $port`;

const manifest = render(template, {
  app_name: 'myapp',
  replicas: 5,
  image: 'nginx',
  tag: '1.21',
  port: 80,
});
```

See [examples/](./examples/) for more examples.

## Options

### RenderOptions

```typescript
interface RenderOptions {
  syntax?: 'auto' | 'jinja' | 'luma'; // Default: 'auto'
}
```

- `auto`: Automatically detect syntax based on template content
- `jinja`: Force Jinja2 syntax parsing
- `luma`: Force Luma native syntax parsing

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Test
npm test

# Lint
npm run lint

# Format
npm run format
```

## Testing

```bash
npm test
```

Comprehensive test suite with 50+ tests covering:

- Variable interpolation
- Control structures (if/for)
- Filters
- Jinja2 compatibility
- File rendering
- Error handling
- Complex data structures

## Architecture

- **Fengari**: Lua VM compiled to JavaScript
- **TypeScript**: Full type definitions and IDE support
- **Zero Native Dependencies**: Works everywhere Node.js runs
- **Embedded Luma**: All Luma Lua modules bundled

## Performance

- Template compilation caches parsed AST
- Fengari provides near-native Lua performance
- Suitable for production use

## Comparison

| Feature | @luma/templates | Nunjucks | EJS |
|---------|----------------|----------|-----|
| Jinja2 Compatible | ✅ | ✅ | ❌ |
| Native Syntax | ✅ | ❌ | ❌ |
| TypeScript | ✅ | ⚠️ | ⚠️ |
| Zero Config | ✅ | ✅ | ✅ |
| Filters | ✅ | ✅ | ❌ |
| Template Inheritance | ✅ | ✅ | ❌ |

## License

MIT

## Links

- [Luma Project](https://github.com/santosr2/luma)
- [Documentation](https://github.com/santosr2/luma/tree/main/docs)
- [Examples](./examples/)
- [npm Package](https://www.npmjs.com/package/@luma/templates)
