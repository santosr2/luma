# Luma Python Examples

Complete examples demonstrating Luma's Python bindings.

## Examples

### 1. Basic Usage (`basic.py`)

Demonstrates fundamental Luma features:

- Simple variable interpolation
- Luma native syntax
- Loops and conditionals
- Filters
- Nested data structures
- Environment usage

**Run:**

```bash
python examples/basic.py
```

### 2. Flask Integration (`flask_app.py`)

Full Flask web application using Luma as the template engine.

**Features:**

- Dynamic HTML rendering
- JSON API responses
- Form handling
- Template inheritance
- Health check endpoint

**Run:**

```bash
# Install Flask first
pip install flask

# Run the app
python examples/flask_app.py
```

Then open <http://localhost:5000> in your browser.

**Endpoints:**

- `/` - Main page with form
- `/api/example` - JSON API example
- `/health` - Health check

### 3. Kubernetes Manifests (`kubernetes.py`)

Generate production-ready Kubernetes YAML manifests.

**Features:**

- Multi-container deployments
- Resource limits and requests
- Environment variables
- ConfigMaps
- Health checks
- Service configurations

**Run:**

```bash
# View manifests
python examples/kubernetes.py

# Apply to cluster
python examples/kubernetes.py | kubectl apply -f -

# Save to file
python examples/kubernetes.py > manifests.yaml
```

## Installation

```bash
# From PyPI
pip install luma-py

# From source
cd bindings/python
pip install -e .
```

## Additional Examples

### Custom Filters

```python
from luma import Environment

env = Environment()

# Add custom filter
env.add_filter("double", lambda x: x * 2)

template = env.from_string("{{ value | double }}")
print(template.render(value=21))  # Output: 42
```

### Custom Tests

```python
from luma import Environment

env = Environment()

# Add custom test
env.add_test("positive", lambda x: x > 0)

template = env.from_string("""
{% if num is positive %}
    Positive
{% else %}
    Negative or zero
{% endif %}
""")
print(template.render(num=5))
```

### Template Inheritance

```python
from luma import Environment, DictLoader

templates = {
    "base.html": """
<!DOCTYPE html>
<html>
<head>
    <title>{% block title %}Default{% endblock %}</title>
</head>
<body>
    {% block content %}{% endblock %}
</body>
</html>
""",
    "page.html": """
{% extends "base.html" %}

{% block title %}My Page{% endblock %}

{% block content %}
    <h1>Hello, World!</h1>
{% endblock %}
"""
}

env = Environment(loader=DictLoader(templates))
template = env.get_template("page.html")
print(template.render())
```

## Next Steps

- Read the [Python API documentation](../README.md)
- Check out the [Luma documentation](../../../docs/)
- Explore [more examples](../../../examples/)

## Support

- [GitHub Issues](https://github.com/santosr2/luma/issues)
- [Discussions](https://github.com/santosr2/luma/discussions)
