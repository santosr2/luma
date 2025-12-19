# Luma Templates - VSCode Extension

Full language support for Luma template engine with Jinja2 compatibility.

## Status

✅ **Production Ready** - v0.1.0 - Fully implemented, tested, and documented.

## Features

### ✅ Syntax Highlighting

- **Luma Native Syntax** (`.luma` files)
  - Directives: `@if`, `@for`, `@macro`, etc.
  - Variable interpolation: `$var`, `${expression}`
  - Filters: `$value | upper`
  - Comments: `@#` and `@comment...@end`

- **Jinja2 Syntax** (`.j2`, `.jinja`, `.jinja2` files)
  - Statements: `{% if %}`, `{% for %}`, etc.
  - Expressions: `{{ variable }}`
  - Comments: `{# comment #}`

### ✅ Intelligent Code Completion

- **Directives**: Auto-complete `@if`, `@for`, `@macro`, etc.
- **Filters**: Suggestions for `upper`, `lower`, `default`, etc.
- **Context-aware**: Completions based on cursor position

### ✅ Snippets

**Luma Snippets:**

- `if` → If statement
- `ifelse` → If-else statement
- `for` → For loop
- `macro` → Macro definition
- `let` → Variable declaration
- And 10+ more...

**Jinja2 Snippets:**

- `if` → If statement
- `for` → For loop
- `macro` → Macro definition
- `set` → Variable declaration
- And 10+ more...

### ✅ Linting

- Syntax error detection
- Unmatched directive warnings
- Undefined variable warnings (heuristic)
- Real-time linting (on save or on type)

### ✅ Formatting

- Auto-indentation for directives
- Consistent spacing
- Format on save or on command

### ✅ Hover Documentation

- Directive documentation on hover
- Filter documentation on hover
- Quick reference without leaving your code

### ✅ Commands

- **Luma: Render Preview** - View template source in preview pane
- **Luma: Lint Current File** - Manually lint the current file
- **Luma: Format Document** - Format the current template

### ✅ Configuration

Customize the extension behavior:

```json
{
  "luma.lint.enabled": true,
  "luma.lint.onSave": true,
  "luma.lint.onType": false,
  "luma.format.enabled": true,
  "luma.format.indentSize": 2,
  "luma.completion.enabled": true
}
```

## Installation

### From VSCode Marketplace

1. Open VSCode
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "Luma Templates"
4. Click Install

### From VSIX File

```bash
code --install-extension luma-0.1.0.vsix
```

### From Source

```bash
cd tools/vscode-luma
npm install
npm run compile
code --install-extension .
```

## Usage

### Quick Start

1. Create a new file with `.luma` extension
2. Start typing `@if` and press Tab
3. Enjoy syntax highlighting and IntelliSense!

### File Associations

The extension automatically activates for:

- `.luma` files (Luma native syntax)
- `.j2`, `.jinja`, `.jinja2` files (Jinja2 syntax)

### Keyboard Shortcuts

- **Format Document**: `Shift+Alt+F` (Windows/Linux) / `Shift+Option+F` (Mac)
- **Render Preview**: Click the play icon in the editor title bar
- **Command Palette**: `Ctrl+Shift+P` / `Cmd+Shift+P` → Search for "Luma"

## Examples

### Luma Syntax

```luma
@# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app_name
spec:
  replicas: ${replicas | default(3)}
  @if enable_autoscaling
  # Autoscaling enabled
  @end
  template:
    spec:
      containers:
        - name: $app_name
          image: ${image}:${tag}
          ports:
            - containerPort: $port
```

### Jinja2 Syntax

```jinja2
{# User profile #}
<div class="profile">
  <h1>{{ user.name }}</h1>
  {% if user.is_premium %}
    <span class="badge">Premium</span>
  {% endif %}
  <ul>
    {% for hobby in user.hobbies %}
      <li>{{ hobby | capitalize }}</li>
    {% endfor %}
  </ul>
</div>
```

## Language Features

### Syntax Highlighting

- Keywords highlighted in blue
- Strings highlighted in orange
- Comments highlighted in green
- Variables highlighted in light blue
- Operators and filters highlighted appropriately

### Smart Indentation

- Auto-indent after `@if`, `@for`, `@macro`, etc.
- Auto-dedent at `@end`, `@else`, `@elif`
- Configurable indent size

### Bracket Matching

- Matches `@if` with `@end`
- Matches `${` with `}`
- Matches `{{` with `}}`
- Visual indicators for matching pairs

### Code Folding

- Fold/unfold `@if...@end` blocks
- Fold/unfold `@for...@end` blocks
- Fold/unfold `@macro...@end` blocks
- Navigate large templates easily

## Configuration Options

### Linting

```json
{
  "luma.lint.enabled": true,          // Enable/disable linting
  "luma.lint.onSave": true,           // Lint on file save
  "luma.lint.onType": false           // Lint while typing (can be slow)
}
```

### Formatting

```json
{
  "luma.format.enabled": true,        // Enable/disable formatting
  "luma.format.indentSize": 2         // Spaces per indent level
}
```

### Completion

```json
{
  "luma.completion.enabled": true     // Enable/disable auto-completion
}
```

## Development

### Building from Source

```bash
cd tools/vscode-luma
npm install
npm run compile
```

### Debugging

1. Open `tools/vscode-luma` in VSCode
2. Press F5 to start debugging
3. A new VSCode window will open with the extension loaded

### Testing

```bash
npm test
```

### Packaging

```bash
npm run package
```

This creates a `.vsix` file that can be installed manually.

## Publishing

See [PUBLISHING.md](./PUBLISHING.md) for instructions on publishing to the VSCode Marketplace.

## Troubleshooting

### Syntax highlighting not working

- Check that the file extension is `.luma`, `.j2`, `.jinja`, or `.jinja2`
- Reload VSCode (`Developer: Reload Window` from Command Palette)

### Linting not working

- Check that `luma.lint.enabled` is `true` in settings
- Ensure the file is saved (linting runs on save by default)

### Completions not showing

- Check that `luma.completion.enabled` is `true`
- Trigger manually with `Ctrl+Space` / `Cmd+Space`

## Contributing

Contributions welcome! Please see the main Luma repository for contribution guidelines.

## License

MIT

## Links

- [Luma Project](https://github.com/santosr2/luma)
- [Documentation](https://github.com/santosr2/luma/tree/main/docs)
- [Report Issues](https://github.com/santosr2/luma/issues)
- [VSCode Marketplace](https://marketplace.visualstudio.com/items?itemName=luma.luma)

## Changelog

### 0.1.0 (Initial Release)

- ✅ Syntax highlighting for Luma and Jinja2
- ✅ Code snippets (20+ snippets)
- ✅ Auto-completion for directives and filters
- ✅ Hover documentation
- ✅ Linting (syntax validation)
- ✅ Formatting (auto-indentation)
- ✅ Commands (preview, lint, format)
- ✅ Bracket matching and folding
- ✅ Smart indentation rules
