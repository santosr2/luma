// Type declarations for fengari and fengari-interop
declare module 'fengari' {
  export const lua: any;
  export const lauxlib: any;
  export const lualib: any;
  // String conversion utilities (part of main fengari package)
  export function to_jsstring(luaString: Uint8Array): string;
  export function to_luastring(jsString: string): Uint8Array;
}

declare module 'fengari-interop' {
  // JS<->Lua value conversion (different from string conversion)
  export function push(L: any, value: any): void;
  export function tojs(L: any, index: number): any;
}

