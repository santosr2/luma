# Luma Node.js Bindings

TypeScript/JavaScript bindings for Luma using Fengari (Lua in JS).

## Status

🚧 **Planned** - Architecture defined, awaiting implementation.

## Installation

```bash
npm install @luma/templates
# or
yarn add @luma/templates
```

## Quick Start

```typescript
import { Luma, Template } from '@luma/templates';

// Simple usage
const luma = new Luma();
const result = luma.render('Hello, $name!', { name: 'World' });
console.log(result); // Hello, World!

// Compiled templates
const template = luma.compile('Hello, $name!');
console.log(template.render({ name: 'Node.js' }));

// Async file rendering
const result = await luma.renderFile('template.luma', { user: 'Alice' });
```

## Architecture

- **Fengari Integration** - Lua VM in JavaScript
- **TypeScript** - Full type definitions
- **Express/Koa Middleware** - Web framework integration
- **Browser Support** - Client-side rendering
- **Stream API** - For large templates

## Implementation Plan

See [IMPLEMENTATION.md](./IMPLEMENTATION.md) for detailed steps.

## License

MIT
