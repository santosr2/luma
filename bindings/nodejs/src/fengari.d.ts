// Type declarations for fengari and fengari-interop
declare module 'fengari' {
  export namespace lua {
    export const LUA_REGISTRYINDEX: number;
    [key: string]: any;
  }
  export namespace lauxlib {
    [key: string]: any;
  }
  export namespace lualib {
    [key: string]: any;
  }
}

declare module 'fengari-interop' {
  export function to_jsstring(luaString: any): string;
  export function to_luastring(jsString: string): any;
  export function push(L: any, value: any): void;
  export function tojs(L: any, index: number): any;
}

