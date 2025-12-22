/**
 * Type declarations for fengari-interop
 * CommonJS module providing JS<->Lua value conversion utilities
 */

declare module 'fengari-interop' {
  /**
   * Convert JavaScript string to Lua string (Uint8Array)
   */
  export function to_luastring(s: string): Uint8Array;

  /**
   * Convert Lua string (Uint8Array) to JavaScript string
   */
  export function to_jsstring(s: Uint8Array): string;

  /**
   * Push a JavaScript value onto the Lua stack
   */
  export function push(L: any, value: any): void;

  /**
   * Convert a Lua value from the stack to JavaScript
   */
  export function tojs(L: any, idx: number): any;
}

