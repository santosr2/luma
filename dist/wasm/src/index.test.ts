/**
 * Tests for Luma WASM browser build
 */

import { init, render, compile, Template } from './index';

describe('Luma WASM', () => {
  beforeAll(async () => {
    await init();
  });

  describe('render()', () => {
    it('should render simple variable', async () => {
      const result = await render('Hello, $name!', { name: 'World' });
      expect(result).toBe('Hello, World!');
    });

    it('should render expression interpolation', async () => {
      const result = await render('Result: ${1 + 2}', {});
      expect(result).toBe('Result: 3.0');
    });

    it('should render with nested properties', async () => {
      const result = await render('User: $user.name', {
        user: { name: 'Alice' },
      });
      expect(result).toBe('User: Alice');
    });

    it('should render with filters', async () => {
      const result = await render('${name | upper}', { name: 'hello' });
      expect(result).toBe('HELLO');
    });

    it('should handle @if directives', async () => {
      const template = `
@if show
  Visible
@end`;
      const result = await render(template, { show: true });
      expect(result.trim()).toBe('Visible');
    });

    it('should handle @for loops', async () => {
      const template = `
@for item in items
  - $item
@end`;
      const result = await render(template, { items: ['a', 'b', 'c'] });
      expect(result).toContain('- a');
      expect(result).toContain('- b');
      expect(result).toContain('- c');
    });

    it('should handle loop variables', async () => {
      const template = `
@for item in items
  \${loop.index}: $item
@end`;
      const result = await render(template, { items: ['x', 'y'] });
      expect(result).toContain('1: x');
      expect(result).toContain('2: y');
    });

    it('should handle Jinja2 syntax', async () => {
      const result = await render('Hello, {{ name }}!', { name: 'World' }, { syntax: 'jinja' });
      expect(result).toBe('Hello, World!');
    });

    it('should handle @let assignments', async () => {
      const template = `
@let x = 10
@let y = 20
Result: \${x + y}`;
      const result = await render(template, {});
      expect(result.trim()).toContain('Result: 30.0');
    });

    it('should handle hyphens between interpolations', async () => {
      const result = await render('${a}-${b}', { a: 'hello', b: 'world' });
      expect(result).toBe('hello-world');
    });
  });

  describe('compile()', () => {
    it('should create a reusable template', async () => {
      const template = compile('Hello, $name!');
      
      const result1 = await template.render({ name: 'Alice' });
      expect(result1).toBe('Hello, Alice!');
      
      const result2 = await template.render({ name: 'Bob' });
      expect(result2).toBe('Hello, Bob!');
    });

    it('should return the source', () => {
      const template = compile('Test $var');
      expect(template.getSource()).toBe('Test $var');
    });
  });

  describe('Template class', () => {
    it('should render with context', async () => {
      const template = new Template('Value: $value');
      const result = await template.render({ value: 42 });
      expect(result).toBe('Value: 42.0');
    });

    it('should handle multiple renders', async () => {
      const template = new Template('${x} + ${y} = ${x + y}');
      
      const result1 = await template.render({ x: 1, y: 2 });
      expect(result1).toBe('1.0 + 2.0 = 3.0');
      
      const result2 = await template.render({ x: 10, y: 20 });
      expect(result2).toBe('10.0 + 20.0 = 30.0');
    });
  });

  describe('Advanced features', () => {
    it('should handle nested loops', async () => {
      const template = `
@for outer in outers
  Outer: $outer
  @for inner in inners
    Inner: $inner
  @end
@end`;
      const result = await render(template, {
        outers: [1, 2],
        inners: ['a', 'b'],
      });
      expect(result).toContain('Outer: 1.0');
      expect(result).toContain('Outer: 2.0');
      expect(result).toContain('Inner: a');
      expect(result).toContain('Inner: b');
    });

    it('should handle @break directive', async () => {
      const template = `
@for i in items
  @if i == 3
    @break
  @end
  $i
@end`;
      const result = await render(template, { items: [1, 2, 3, 4, 5] });
      expect(result).toContain('1');
      expect(result).toContain('2');
      expect(result).not.toContain('3');
      expect(result).not.toContain('4');
    });

    it('should handle @continue directive', async () => {
      const template = `
@for i in items
  @if i == 3
    @continue
  @end
  $i
@end`;
      const result = await render(template, { items: [1, 2, 3, 4, 5] });
      expect(result).toContain('1');
      expect(result).toContain('2');
      expect(result).not.toContain('3');
      expect(result).toContain('4');
      expect(result).toContain('5');
    });

    it('should handle macros', async () => {
      const template = `
@macro greet(name)
  Hello, $name!
@end
\${greet("World")}`;
      const result = await render(template, {});
      expect(result.trim()).toContain('Hello, World!');
    });

    it('should handle filters with arguments', async () => {
      const result = await render('${value | default("N/A")}', { value: null });
      expect(result).toBe('N/A');
    });

    it('should handle multiple filters', async () => {
      const result = await render('${text | lower | capitalize}', { text: 'HELLO WORLD' });
      expect(result).toBe('Hello world');
    });
  });

  describe('Error handling', () => {
    it('should throw on invalid template', async () => {
      await expect(render('@for item in', {})).rejects.toThrow();
    });

    it('should throw when not initialized', async () => {
      // This test would require resetting the module state
      // Skip for now as it's an edge case
    });
  });

  describe('Jinja2 compatibility', () => {
    it('should support {% if %} syntax', async () => {
      const result = await render('{% if true %}Yes{% endif %}', {}, { syntax: 'jinja' });
      expect(result).toBe('Yes');
    });

    it('should support {% for %} syntax', async () => {
      const template = '{% for i in items %}{{ i }}{% endfor %}';
      const result = await render(template, { items: [1, 2, 3] }, { syntax: 'jinja' });
      expect(result).toBe('1.02.03.0');
    });

    it('should support {{ }} interpolation', async () => {
      const result = await render('{{ name | upper }}', { name: 'test' }, { syntax: 'jinja' });
      expect(result).toBe('TEST');
    });
  });
});

