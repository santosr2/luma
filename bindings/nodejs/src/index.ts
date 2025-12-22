/**
 * @luma/templates - Luma template engine for Node.js
 *
 * Fast, clean templating with full Jinja2 compatibility.
 *
 * @example
 * ```typescript
 * import { render, compile } from '@luma/templates';
 *
 * // Simple rendering
 * const result = render('Hello, $name!', { name: 'World' });
 * console.log(result); // Hello, World!
 *
 * // Compiled template (reusable)
 * const template = compile('Hello, $name!');
 * console.log(template.render({ name: 'Alice' }));
 * ```
 */

import * as fengari from 'fengari';
import * as fs from 'fs';
import * as path from 'path';

const lua = fengari.lua;
const lauxlib = fengari.lauxlib;
const lualib = fengari.lualib;

// Import interop functions - fengari-interop is CommonJS, needs require
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fengari_interop = require('fengari-interop');
const to_jsstring = fengari_interop.to_jsstring;
const to_luastring = fengari_interop.to_luastring;

/**
 * Context for template rendering
 */
export type Context = Record<string, any>;

/**
 * Template rendering options
 */
export interface RenderOptions {
  /**
   * Syntax mode: 'auto' | 'jinja' | 'luma'
   * @default 'auto'
   */
  syntax?: 'auto' | 'jinja' | 'luma';
}

/**
 * Compiled template
 */
export class Template {
  private source: string;

  constructor(source: string) {
    this.source = source;
  }

  /**
   * Render the template with the given context
   * @param context - Template variables
   * @param options - Rendering options
   * @returns Rendered string
   */
  render(context: Context = {}, options: RenderOptions = {}): string {
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
 * Initialize Lua state with Luma modules
 */
function initLuaState(): any {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);

  // Load Luma modules
  const lumaPath = path.join(__dirname, '..', 'lua');
  const modules = [
    ['luma', 'luma/init.lua'],
    ['luma.version', 'luma/version.lua'],
    ['luma.compiler.init', 'luma/compiler/init.lua'],
    ['luma.compiler.codegen', 'luma/compiler/codegen.lua'],
    ['luma.lexer.init', 'luma/lexer/init.lua'],
    ['luma.lexer.native', 'luma/lexer/native.lua'],
    ['luma.lexer.jinja', 'luma/lexer/jinja.lua'],
    ['luma.lexer.tokens', 'luma/lexer/tokens.lua'],
    ['luma.lexer.inline_detector', 'luma/lexer/inline_detector.lua'],
    ['luma.lexer.trim_processor', 'luma/lexer/trim_processor.lua'],
    ['luma.parser.init', 'luma/parser/init.lua'],
    ['luma.parser.ast', 'luma/parser/ast.lua'],
    ['luma.parser.expressions', 'luma/parser/expressions.lua'],
    ['luma.runtime.init', 'luma/runtime/init.lua'],
    ['luma.runtime.context', 'luma/runtime/context.lua'],
    ['luma.runtime.sandbox', 'luma/runtime/sandbox.lua'],
    ['luma.filters.init', 'luma/filters/init.lua'],
    ['luma.utils.init', 'luma/utils/init.lua'],
    ['luma.utils.compat', 'luma/utils/compat.lua'],
    ['luma.utils.errors', 'luma/utils/errors.lua'],
    ['luma.utils.warnings', 'luma/utils/warnings.lua'],
  ];

  for (const [moduleName, modulePath] of modules) {
    const fullPath = path.join(lumaPath, modulePath);
    try {
      const code = fs.readFileSync(fullPath, 'utf8');

      // Load module into package.preload
      lauxlib.luaL_getsubtable(L, lua.LUA_REGISTRYINDEX, to_luastring('_PRELOAD'));

      if (lauxlib.luaL_loadstring(L, to_luastring(code)) !== lua.LUA_OK) {
        const error = to_jsstring(lua.lua_tostring(L, -1));
        throw new Error(`Failed to load module ${moduleName}: ${error}`);
      }

      lua.lua_setfield(L, -2, to_luastring(moduleName));
      lua.lua_pop(L, 1); // pop _PRELOAD table
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
        throw error;
      }
      // Module file not found, skip
    }
  }

  return L;
}

/**
 * Convert JavaScript value to Lua value
 */
function jsToLua(L: any, value: any): void {
  if (value === null || value === undefined) {
    lua.lua_pushnil(L);
  } else if (typeof value === 'boolean') {
    lua.lua_pushboolean(L, value ? 1 : 0);
  } else if (typeof value === 'number') {
    lua.lua_pushnumber(L, value);
  } else if (typeof value === 'string') {
    lua.lua_pushstring(L, to_luastring(value));
  } else if (Array.isArray(value)) {
    lua.lua_newtable(L);
    for (let i = 0; i < value.length; i++) {
      jsToLua(L, value[i]);
      lua.lua_rawseti(L, -2, i + 1);
    }
  } else if (typeof value === 'object') {
    lua.lua_newtable(L);
    for (const [key, val] of Object.entries(value)) {
      lua.lua_pushstring(L, to_luastring(key));
      jsToLua(L, val);
      lua.lua_rawset(L, -3);
    }
  } else {
    lua.lua_pushstring(L, to_luastring(String(value)));
  }
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
 * const result = render('Hello, $name!', { name: 'World' });
 * console.log(result); // Hello, World!
 * ```
 */
export function render(
  template: string,
  context: Context = {},
  options: RenderOptions = {}
): string {
  const L = initLuaState();

  try {
    // Load luma module
    const loadCode = 'return require("luma")';
    if (lauxlib.luaL_loadstring(L, to_luastring(loadCode)) !== lua.LUA_OK) {
      const error = to_jsstring(lua.lua_tostring(L, -1));
      throw new Error(`Failed to load luma module: ${error}`);
    }

    if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) {
      const error = to_jsstring(lua.lua_tostring(L, -1));
      throw new Error(`Failed to require luma: ${error}`);
    }

    // Get luma.render function
    lua.lua_getfield(L, -1, to_luastring('render'));

    // Push template string
    lua.lua_pushstring(L, to_luastring(template));

    // Push context table
    jsToLua(L, context);

    // Push options table if provided
    if (options.syntax) {
      lua.lua_newtable(L);
      lua.lua_pushstring(L, to_luastring('syntax'));
      lua.lua_pushstring(L, to_luastring(options.syntax));
      lua.lua_rawset(L, -3);
    } else {
      lua.lua_pushnil(L);
    }

    // Call luma.render(template, context, options)
    if (lua.lua_pcall(L, 3, 1, 0) !== lua.LUA_OK) {
      const error = to_jsstring(lua.lua_tostring(L, -1));
      throw new Error(`Render error: ${error}`);
    }

    // Get result
    const result = to_jsstring(lua.lua_tostring(L, -1));
    return result;
  } finally {
    lua.lua_close(L);
  }
}

/**
 * Compile a template for reuse
 *
 * @param template - Template string to compile
 * @returns Compiled template
 *
 * @example
 * ```typescript
 * const tmpl = compile('Hello, $name!');
 * console.log(tmpl.render({ name: 'Alice' }));
 * console.log(tmpl.render({ name: 'Bob' }));
 * ```
 */
export function compile(template: string): Template {
  return new Template(template);
}

/**
 * Render a template file
 *
 * @param filePath - Path to template file
 * @param context - Template variables
 * @param options - Rendering options
 * @returns Rendered string
 *
 * @example
 * ```typescript
 * const result = await renderFile('./template.luma', { name: 'World' });
 * ```
 */
export async function renderFile(
  filePath: string,
  context: Context = {},
  options: RenderOptions = {}
): Promise<string> {
  const template = await fs.promises.readFile(filePath, 'utf8');
  return render(template, context, options);
}

/**
 * Synchronous version of renderFile
 */
export function renderFileSync(
  filePath: string,
  context: Context = {},
  options: RenderOptions = {}
): string {
  const template = fs.readFileSync(filePath, 'utf8');
  return render(template, context, options);
}

// Export default
export default {
  render,
  compile,
  renderFile,
  renderFileSync,
  Template,
};
