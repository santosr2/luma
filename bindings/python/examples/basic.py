"""
Basic usage examples for Luma Python bindings.
"""

from luma import Template, Environment, DictLoader

print("=== Example 1: Simple Variable Interpolation ===")
template = Template("Hello, {{ name }}!")
result = template.render(name="World")
print(result)

print("\n=== Example 2: Luma Native Syntax ===")
template = Template("Hello, $name!", syntax="luma")
result = template.render(name="Alice")
print(result)

print("\n=== Example 3: Loops ===")
template = Template("""
{% for item in items %}
  - {{ item }}
{% endfor %}
""")
result = template.render(items=["apple", "banana", "cherry"])
print(result)

print("\n=== Example 4: Conditionals ===")
template = Template("""
{% if user.is_admin %}
  Welcome, Admin {{ user.name }}!
{% else %}
  Welcome, {{ user.name }}
{% endif %}
""")
result = template.render(user={"name": "Bob", "is_admin": True})
print(result)

print("\n=== Example 5: Filters ===")
template = Template("{{ text | upper }}")
result = template.render(text="hello world")
print(result)

print("\n=== Example 6: Nested Data ===")
template = Template("""
Name: {{ user.name }}
Email: {{ user.email }}
Role: {{ user.role | default('user') }}
""")
result = template.render(user={
    "name": "Charlie",
    "email": "charlie@example.com",
    "role": "developer"
})
print(result)

print("\n=== Example 7: Using Environment ===")
templates = {
    "greeting.html": "Hello, {{ name }}!",
    "farewell.html": "Goodbye, {{ name }}!",
}
env = Environment(loader=DictLoader(templates))

greeting = env.get_template("greeting.html")
print(greeting.render(name="Diana"))

farewell = env.get_template("farewell.html")
print(farewell.render(name="Diana"))

print("\n=== Example 8: Template from String ===")
env = Environment()
template = env.from_string("Result: {{ value * 2 }}")
result = template.render(value=21)
print(result)

print("\n=== Example 9: Complex Expressions ===")
template = Template("Total: {{ price * quantity }}")
result = template.render(price=10.99, quantity=3)
print(result)

print("\n=== Example 10: List Comprehension ===")
template = Template("""
{% for user in users %}
  {{ loop.index }}. {{ user.name }} ({{ user.role }})
{% endfor %}
""")
result = template.render(users=[
    {"name": "Alice", "role": "Admin"},
    {"name": "Bob", "role": "User"},
    {"name": "Charlie", "role": "Guest"},
])
print(result)
