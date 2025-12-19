"""
Flask integration example for Luma.

This example shows how to use Luma as the template engine for Flask applications.
"""

from flask import Flask, request
from luma import Environment, DictLoader

app = Flask(__name__)

# Set up Luma environment with templates
templates = {
    "index.html": """
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        .greeting { color: #2c3e50; font-size: 24px; margin: 20px 0; }
        .info { background: #ecf0f1; padding: 15px; border-radius: 5px; }
        form { margin: 20px 0; }
        input, button { padding: 10px; margin: 5px 0; }
        button { background: #3498db; color: white; border: none; cursor: pointer; }
        button:hover { background: #2980b9; }
    </style>
</head>
<body>
    <h1>{{ title }}</h1>
    <div class="greeting">Hello, {{ name }}!</div>

    <div class="info">
        <h2>Template Features:</h2>
        <ul>
        {% for feature in features %}
            <li>{{ feature }}</li>
        {% endfor %}
        </ul>
    </div>

    <form action="/" method="get">
        <input type="text" name="name" placeholder="Enter your name" value="{{ name }}">
        <button type="submit">Update</button>
    </form>
</body>
</html>
""",
    "api_response.json": """
{
    "success": true,
    "message": "{{ message }}",
    "data": {
        "user": "{{ user }}",
        "timestamp": "{{ timestamp }}",
        "items": [
        {% for item in items %}
            "{{ item }}"{% if not loop.last %},{% endif %}
        {% endfor %}
        ]
    }
}
"""
}

luma_env = Environment(loader=DictLoader(templates))


@app.route("/")
def index():
    """Render the main page."""
    name = request.args.get("name", "World")

    template = luma_env.get_template("index.html")
    return template.render(
        title="Luma Flask Demo",
        name=name,
        features=[
            "Jinja2 compatible syntax",
            "Fast Lua-powered rendering",
            "Clean and readable templates",
            "Built-in filters and tests",
            "Template inheritance"
        ]
    )


@app.route("/api/example")
def api_example():
    """Render JSON response using Luma."""
    template = luma_env.get_template("api_response.json")
    response = template.render(
        message="Data retrieved successfully",
        user="demo_user",
        timestamp="2024-01-01T00:00:00Z",
        items=["item1", "item2", "item3"]
    )
    return response, 200, {"Content-Type": "application/json"}


@app.route("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy", "engine": "luma"}, 200


if __name__ == "__main__":
    print("Starting Flask app with Luma templates...")
    print("Open http://localhost:5000 in your browser")
    print("Try: http://localhost:5000/?name=YourName")
    print("API endpoint: http://localhost:5000/api/example")
    app.run(debug=True, port=5000)
