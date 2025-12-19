# Luma WebAssembly Build

Browser and edge runtime support via WebAssembly.

## Status

🚧 **Planned** - Architecture designed, awaiting implementation.

## Usage

### Browser

```html
<script src="https://cdn.jsdelivr.net/npm/@luma/wasm/luma.min.js"></script>
<script>
  const luma = await Luma.init();
  const result = luma.render('Hello, $name!', { name: 'Browser' });
  console.log(result);
</script>
```

### Cloudflare Workers

```typescript
import { Luma } from '@luma/wasm';

export default {
  async fetch(request: Request): Promise<Response> {
    const luma = await Luma.init();
    const html = luma.render(template, { request });
    return new Response(html, {
      headers: { 'content-type': 'text/html' }
    });
  }
};
```

## Build Process

Uses `wasmoon` (Lua 5.4 in WASM) to compile Luma to WebAssembly.

## Implementation Steps

1. Evaluate WASM Lua runtimes (wasmoon, fengari)
2. Bundle Luma source code
3. Create JavaScript wrapper API
4. Build browser bundle
5. Build ESM module for edge runtimes
6. Optimize for size and performance
7. Publish to npm and CDN

## Distribution

- **npm**: `@luma/wasm`
- **CDN**: jsDelivr, unpkg
- **Size target**: < 200KB gzipped

## License

MIT
