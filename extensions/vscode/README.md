# Luma VSCode Extension

Visual Studio Code extension for Luma template development.

## Status

🚧 **Planned** - Requirements defined, ready for development.

## Features

### Syntax Highlighting

- `.luma` file support
- Native Luma syntax (`@if`, `@for`, `$var`)
- Jinja2 syntax compatibility
- Embedded in HTML, YAML, etc.

### IntelliSense

- Filter auto-completion
- Directive completion
- Variable suggestions
- Test expression completion

### Code Actions

- Quick fixes for common errors
- Convert Jinja2 to Luma syntax
- Extract macros
- Inline macros

### Diagnostics

- Real-time syntax validation
- Undefined variable warnings
- Type checking
- Best practice hints

### Navigation

- Go to definition (macros, blocks)
- Find all references
- Symbol outline
- Breadcrumbs

## Installation

```bash
ext install luma.luma-vscode
```

## Development Setup

```bash
cd extensions/vscode
npm install
npm run compile
# Press F5 to launch extension dev host
```

## Project Structure

```text
extensions/vscode/
├── package.json              # Extension manifest
├── syntaxes/
│   └── luma.tmLanguage.json  # TextMate grammar
├── language-configuration.json
├── snippets/
│   └── luma.json             # Code snippets
└── src/
    ├── extension.ts          # Entry point
    ├── providers/
    │   ├── completion.ts     # IntelliSense
    │   ├── hover.ts          # Hover tooltips
    │   ├── diagnostics.ts    # Error checking
    │   └── formatting.ts     # Code formatting
    └── grammar/
        └── luma.ts           # Semantic highlighting
```

## Implementation Steps

1. Create extension manifest
2. Define TextMate grammar
3. Implement language server
4. Add completion providers
5. Add diagnostics
6. Publish to marketplace

## License

MIT
