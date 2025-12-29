/**
 * @luma/browser - Luma template engine for browsers
 *
 * WebAssembly-powered template engine for client-side rendering.
 *
 * @example
 * ```html
 * <script src="https://unpkg.com/@luma/browser"></script>
 * <script>
 *   const result = await Luma.render('Hello, $name!', { name: 'World' });
 *   console.log(result); // Hello, World!
 * </script>
 * ```
 */

import { LuaFactory, LuaEngine } from 'wasmoon';
import lumaModules from './modules';

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
 * Convert JavaScript object to Lua table syntax string
 */
function convertToLuaTable(obj: any): string {
  if (obj === null || obj === undefined) {
    return 'nil';
  }
  if (typeof obj === 'string') {
    return JSON.stringify(obj);
  }
  if (typeof obj === 'number' || typeof obj === 'boolean') {
    return String(obj);
  }
  if (Array.isArray(obj)) {
    const items = obj.map(item => convertToLuaTable(item)).join(', ');
    return `{${items}}`;
  }
  if (typeof obj === 'object') {
    const pairs = Object.entries(obj)
      .map(([key, value]) => {
        // Use bracket notation for keys that aren't valid Lua identifiers
        const luaKey = /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(key) 
          ? key 
          : `[${JSON.stringify(key)}]`;
        return `${luaKey} = ${convertToLuaTable(value)}`;
      })
      .join(', ');
    return `{${pairs}}`;
  }
  return 'nil';
}

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

    // Convert context and options to Lua tables
    lua.global.set('ctx', context);
    
    // Convert options to Lua table syntax
    const luaOptions = convertToLuaTable(options);

    // Render template
    const renderCode = `
      local template = ${JSON.stringify(template)}
      local ctx = ctx or {}
      local options = ${luaOptions}
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
async function loadLumaModules(lua: LuaEngine): Promise<void> {
  // Preload all Luma modules from embedded sources
  const preloadCode = `
    -- Preload all Luma modules
    ${Object.entries(lumaModules)
      .map(
        ([moduleName, moduleCode]) => `
    package.preload["${moduleName}"] = function()
      ${moduleCode}
    end
    `
      )
      .join('\n')}
  `;

  await lua.doString(preloadCode);
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
