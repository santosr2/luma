import { render, compile, renderFile, renderFileSync, Template } from './index';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

describe('Luma Node.js Bindings', () => {
  describe('render()', () => {
    it('should render simple variable interpolation', () => {
      const result = render('Hello, $name!', { name: 'World' });
      expect(result).toBe('Hello, World!');
    });

    it('should render complex expressions', () => {
      const result = render('Result: ${value * 2}', { value: 21 });
      expect(result).toBe('Result: 42');
    });

    it('should handle nested objects', () => {
      const result = render('User: $user.name', {
        user: { name: 'Alice', age: 30 },
      });
      expect(result).toBe('User: Alice');
    });

    it('should handle arrays', () => {
      const template = `@for item in items
- $item
@end`;
      const result = render(template, { items: ['apple', 'banana', 'cherry'] });
      expect(result).toContain('- apple');
      expect(result).toContain('- banana');
      expect(result).toContain('- cherry');
    });

    it('should handle conditionals', () => {
      const template = `@if show
Visible
@else
Hidden
@end`;

      const result1 = render(template, { show: true });
      expect(result1).toContain('Visible');
      expect(result1).not.toContain('Hidden');

      const result2 = render(template, { show: false });
      expect(result2).toContain('Hidden');
      expect(result2).not.toContain('Visible');
    });

    it('should handle filters', () => {
      const result = render('$name | upper', { name: 'alice' });
      expect(result).toBe('ALICE');
    });

    it('should handle default filter', () => {
      const result = render('${missing | default("fallback")}', {});
      expect(result).toBe('fallback');
    });

    it('should handle empty context', () => {
      const result = render('Static text');
      expect(result).toBe('Static text');
    });

    it('should throw on invalid template', () => {
      expect(() => {
        render('@if missing_end', {});
      }).toThrow();
    });
  });

  describe('Jinja2 compatibility', () => {
    it('should render Jinja2 variable syntax', () => {
      const result = render('Hello, {{ name }}!', { name: 'World' });
      expect(result).toBe('Hello, World!');
    });

    it('should render Jinja2 control structures', () => {
      const template = `{% if show %}Visible{% endif %}`;
      const result = render(template, { show: true });
      expect(result).toContain('Visible');
    });

    it('should render Jinja2 loops', () => {
      const template = `{% for item in items %}{{ item }}{% endfor %}`;
      const result = render(template, { items: ['a', 'b', 'c'] });
      expect(result).toContain('a');
      expect(result).toContain('b');
      expect(result).toContain('c');
    });

    it('should handle Jinja2 filters', () => {
      const result = render('{{ name | upper }}', { name: 'test' });
      expect(result).toBe('TEST');
    });
  });

  describe('compile()', () => {
    it('should create a reusable template', () => {
      const tmpl = compile('Hello, $name!');

      const result1 = tmpl.render({ name: 'Alice' });
      expect(result1).toBe('Hello, Alice!');

      const result2 = tmpl.render({ name: 'Bob' });
      expect(result2).toBe('Hello, Bob!');
    });

    it('should return Template instance', () => {
      const tmpl = compile('Test');
      expect(tmpl).toBeInstanceOf(Template);
    });

    it('should get original source', () => {
      const source = 'Hello, $name!';
      const tmpl = compile(source);
      expect(tmpl.getSource()).toBe(source);
    });
  });

  describe('Template class', () => {
    it('should render with context', () => {
      const tmpl = new Template('Value: $value');
      const result = tmpl.render({ value: 42 });
      expect(result).toBe('Value: 42');
    });

    it('should render with empty context', () => {
      const tmpl = new Template('Static');
      const result = tmpl.render();
      expect(result).toBe('Static');
    });

    it('should handle multiple renders', () => {
      const tmpl = new Template('$x + $y = ${x + y}');

      expect(tmpl.render({ x: 1, y: 2 })).toBe('1 + 2 = 3');
      expect(tmpl.render({ x: 10, y: 20 })).toBe('10 + 20 = 30');
    });
  });

  describe('renderFile()', () => {
    let tmpDir: string;
    let tmpFile: string;

    beforeEach(() => {
      tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'luma-test-'));
      tmpFile = path.join(tmpDir, 'template.luma');
    });

    afterEach(() => {
      if (fs.existsSync(tmpDir)) {
        fs.rmSync(tmpDir, { recursive: true });
      }
    });

    it('should render from file asynchronously', async () => {
      fs.writeFileSync(tmpFile, 'Hello, $name!');
      const result = await renderFile(tmpFile, { name: 'World' });
      expect(result).toBe('Hello, World!');
    });

    it('should throw on missing file', async () => {
      await expect(
        renderFile('/nonexistent/file.luma', {})
      ).rejects.toThrow();
    });
  });

  describe('renderFileSync()', () => {
    let tmpDir: string;
    let tmpFile: string;

    beforeEach(() => {
      tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'luma-test-'));
      tmpFile = path.join(tmpDir, 'template.luma');
    });

    afterEach(() => {
      if (fs.existsSync(tmpDir)) {
        fs.rmSync(tmpDir, { recursive: true });
      }
    });

    it('should render from file synchronously', () => {
      fs.writeFileSync(tmpFile, 'Hello, $name!');
      const result = renderFileSync(tmpFile, { name: 'World' });
      expect(result).toBe('Hello, World!');
    });

    it('should throw on missing file', () => {
      expect(() => {
        renderFileSync('/nonexistent/file.luma', {});
      }).toThrow();
    });
  });

  describe('Kubernetes example', () => {
    it('should render a Kubernetes deployment', () => {
      const template = `apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app_name
spec:
  replicas: \${replicas | default(3)}
  selector:
    matchLabels:
      app: $app_name
  template:
    metadata:
      labels:
        app: $app_name
    spec:
      containers:
        - name: $app_name
          image: \${image}:\${tag | default("latest")}
          ports:
            - containerPort: $port`;

      const result = render(template, {
        app_name: 'myapp',
        replicas: 5,
        image: 'nginx',
        tag: '1.21',
        port: 80,
      });

      expect(result).toContain('name: myapp');
      expect(result).toContain('replicas: 5');
      expect(result).toContain('image: nginx:1.21');
      expect(result).toContain('containerPort: 80');
    });
  });

  describe('Complex data structures', () => {
    it('should handle nested maps and arrays', () => {
      const template = `@for user in users
Name: $user.name
@for role in user.roles
  - $role
@end
@end`;

      const result = render(template, {
        users: [
          { name: 'Alice', roles: ['admin', 'developer'] },
          { name: 'Bob', roles: ['viewer'] },
        ],
      });

      expect(result).toContain('Name: Alice');
      expect(result).toContain('- admin');
      expect(result).toContain('- developer');
      expect(result).toContain('Name: Bob');
      expect(result).toContain('- viewer');
    });

    it('should handle numbers and booleans', () => {
      const template = `Count: $count
Price: $price
Active: $active`;

      const result = render(template, {
        count: 42,
        price: 19.99,
        active: true,
      });

      expect(result).toContain('Count: 42');
      expect(result).toContain('Price: 19.99');
      expect(result).toContain('Active: true');
    });
  });

  describe('Syntax options', () => {
    it('should force Jinja2 syntax', () => {
      const result = render(
        '{{ value }}',
        { value: 'test' },
        { syntax: 'jinja' }
      );
      expect(result).toBe('test');
    });

    it('should force Luma syntax', () => {
      const result = render(
        '$value',
        { value: 'test' },
        { syntax: 'luma' }
      );
      expect(result).toBe('test');
    });

    it('should auto-detect syntax', () => {
      const result = render(
        '$value',
        { value: 'test' },
        { syntax: 'auto' }
      );
      expect(result).toBe('test');
    });
  });
});
