// Type declarations for fengari and fengari-interop
declare module 'fengari' {
  export const lua: any;
  export const lauxlib: any;
  export const lualib: any;
}

declare module 'fengari-interop' {
  export function to_jsstring(luaString: any): string;
  export function to_luastring(jsString: string): any;
  export function push(L: any, value: any): void;
  export function tojs(L: any, index: number): any;
}

