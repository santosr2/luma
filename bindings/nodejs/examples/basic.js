/**
 * Basic usage example for @luma/templates
 */

const { render, compile } = require('../dist/index');

console.log('=== Basic Variable Interpolation ===');
const greeting = render('Hello, $name!', { name: 'World' });
console.log(greeting);

console.log('\n=== Conditionals ===');
const conditional = render(
  `@if show
Welcome!
@else
Goodbye!
@end`,
  { show: true }
);
console.log(conditional);

console.log('\n=== Loops ===');
const loop = render(
  `@for item in items
- $item
@end`,
  { items: ['apple', 'banana', 'cherry'] }
);
console.log(loop);

console.log('\n=== Filters ===');
const filtered = render('$text | upper', { text: 'hello world' });
console.log(filtered);

console.log('\n=== Compiled Template (Reusable) ===');
const tmpl = compile('User: $name ($role)');
console.log(tmpl.render({ name: 'Alice', role: 'Admin' }));
console.log(tmpl.render({ name: 'Bob', role: 'User' }));

console.log('\n=== Jinja2 Compatibility ===');
const jinja = render('{{ greeting }}, {{ name }}!', {
  greeting: 'Hello',
  name: 'World',
});
console.log(jinja);

console.log('\n=== Complex Expressions ===');
const complex = render('Total: ${price * quantity}', {
  price: 10.99,
  quantity: 3,
});
console.log(complex);
