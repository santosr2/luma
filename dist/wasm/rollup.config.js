import resolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import typescript from '@rollup/plugin-typescript';
import terser from '@rollup/plugin-terser';

const production = process.env.NODE_ENV === 'production';

export default [
  // UMD build (for browsers via <script>)
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/luma.js',
      format: 'umd',
      name: 'Luma',
      sourcemap: true,
    },
    plugins: [
      resolve({
        browser: true,
      }),
      commonjs(),
      typescript({
        tsconfig: './tsconfig.json',
      }),
    ],
  },
  // UMD minified
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/luma.min.js',
      format: 'umd',
      name: 'Luma',
      sourcemap: true,
    },
    plugins: [
      resolve({
        browser: true,
      }),
      commonjs(),
      typescript({
        tsconfig: './tsconfig.json',
      }),
      production && terser(),
    ].filter(Boolean),
  },
  // ES Module build
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/luma.esm.js',
      format: 'es',
      sourcemap: true,
    },
    plugins: [
      resolve({
        browser: true,
      }),
      commonjs(),
      typescript({
        tsconfig: './tsconfig.json',
      }),
    ],
  },
];
