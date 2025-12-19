/**
 * @luma/browser - Luma template engine for browsers
 *
 * WebAssembly-powered template engine for client-side rendering.
 *
 * @example
 * ```html
 * <script src="https://unpkg.com/@luma/browser"></script>
 * <script>
 *   const result = Luma.render('Hello, $name!', { name: 'World' });
 *   console.log(result); // Hello, World!
 * </script>
 * ```
 */

import { LuaFactory } from 'wasmoon';

/**
 * Context for template rendering
 */
export interface Context {
  [key: string]: any;
}

/**
 * Rendering options
 */
export interface RenderOptions {
  syntax?: 'auto' | 'jinja' | 'luma';
}

let luaFactory: LuaFactory | null = null;
let isInitialized = false;

/**
 * Initialize the Luma engine
 * Must be called before rendering templates
 */
export async function init(): Promise<void> {
  if (isInitialized) {
    return;
  }

  luaFactory = new LuaFactory();
  isInitialized = true;
}

/**
 * Render a template string with context
 *
 * @param template - Template string to render
 * @param context - Template variables
 * @param options - Rendering options
 * @returns Rendered string
 *
 * @example
 * ```typescript
 * await Luma.init();
 * const result = await Luma.render('Hello, $name!', { name: 'World' });
 * ```
 */
export async function render(
  template: string,
  context: Context = {},
  options: RenderOptions = {}
): Promise<string> {
  if (!isInitialized || !luaFactory) {
    throw new Error('Luma not initialized. Call Luma.init() first.');
  }

  const lua = await luaFactory.createEngine();

  try {
    // Load Luma modules (embedded)
    await loadLumaModules(lua);

    // Load luma module
    await lua.doString('luma = require("luma")');

    // Convert context to Lua table
    lua.global.set('ctx', context);

    // Render template
    const renderCode = `
      local template = ${JSON.stringify(template)}
      local ctx = ctx or {}
      local options = ${JSON.stringify(options)}
      return luma.render(template, ctx, options)
    `;

    const result = await lua.doString(renderCode);
    return result as string;
  } finally {
    lua.global.close();
  }
}

/**
 * Compiled template for reuse
 */
export class Template {
  private source: string;

  constructor(source: string) {
    this.source = source;
  }

  /**
   * Render the template with context
   */
  async render(context: Context = {}, options: RenderOptions = {}): Promise<string> {
    return render(this.source, context, options);
  }

  /**
   * Get the original template source
   */
  getSource(): string {
    return this.source;
  }
}

/**
 * Compile a template for reuse
 *
 * @param template - Template string to compile
 * @returns Compiled template
 */
export function compile(template: string): Template {
  return new Template(template);
}

/**
 * Load Luma Lua modules into the Lua engine
 */
async function loadLumaModules(lua: any): Promise<void> {
  // In a real implementation, these would be embedded or fetched
  // For now, we'll provide a minimal stub

  const lumaStub = `
-- Minimal Luma implementation for browser
local luma = {}

function luma.render(template, context, options)
  -- Basic variable interpolation
  local result = template

  -- Replace $var with context values
  result = result:gsub("%$([%w_]+)", function(var)
    return tostring(context[var] or "")
  end)

  -- Replace \${expr} with evaluated expressions
  result = result:gsub("%${([^}]+)}", function(expr)
    -- Simple evaluation (limited)
    local value = context[expr]
    return tostring(value or "")
  end)

  return result
end

return luma
`;

  await lua.doString(`
    package.preload["luma"] = function()
      ${lumaStub}
    end
  `);
}

// Auto-initialize on import (can be disabled if needed)
if (typeof window !== 'undefined') {
  // Browser environment
  (window as any).Luma = {
    init,
    render,
    compile,
    Template,
  };

  // Auto-init
  init().catch((err) => {
    console.error('Failed to initialize Luma:', err);
  });
}

// Export for module usage
export default {
  init,
  render,
  compile,
  Template,
};
