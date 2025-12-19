"""
Kubernetes manifest generation example.

This example demonstrates generating Kubernetes YAML manifests using Luma.
"""

from luma import Template

# Kubernetes Deployment template
deployment_template = Template("""
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ app.name }}
  namespace: {{ app.namespace }}
  labels:
    app: {{ app.name }}
    version: {{ app.version }}
spec:
  replicas: {{ app.replicas }}
  selector:
    matchLabels:
      app: {{ app.name }}
  template:
    metadata:
      labels:
        app: {{ app.name }}
        version: {{ app.version }}
    spec:
      containers:
        - name: {{ app.name }}
          image: {{ app.image }}:{{ app.tag }}
          ports:
            - name: http
              containerPort: {{ app.port }}
              protocol: TCP
          {% if app.env %}
          env:
          {% for key, value in app.env.items() %}
            - name: {{ key }}
              value: "{{ value }}"
          {% endfor %}
          {% endif %}
          {% if app.resources %}
          resources:
            {% if app.resources.limits %}
            limits:
              cpu: {{ app.resources.limits.cpu }}
              memory: {{ app.resources.limits.memory }}
            {% endif %}
            {% if app.resources.requests %}
            requests:
              cpu: {{ app.resources.requests.cpu }}
              memory: {{ app.resources.requests.memory }}
            {% endif %}
          {% endif %}
          livenessProbe:
            httpGet:
              path: {{ app.health_check | default('/health') }}
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: {{ app.health_check | default('/ready') }}
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
""")

# Kubernetes Service template
service_template = Template("""
---
apiVersion: v1
kind: Service
metadata:
  name: {{ app.name }}
  namespace: {{ app.namespace }}
  labels:
    app: {{ app.name }}
spec:
  type: {{ app.service_type | default('ClusterIP') }}
  ports:
    - port: {{ app.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: {{ app.name }}
""")

# ConfigMap template
configmap_template = Template("""
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ app.name }}-config
  namespace: {{ app.namespace }}
data:
{% for key, value in app.config.items() %}
  {{ key }}: "{{ value }}"
{% endfor %}
""")

# Example configurations
apps = [
    {
        "name": "myapp",
        "namespace": "production",
        "version": "v1.0.0",
        "replicas": 3,
        "image": "myapp",
        "tag": "1.0.0",
        "port": 8080,
        "service_type": "LoadBalancer",
        "env": {
            "NODE_ENV": "production",
            "LOG_LEVEL": "info",
            "API_URL": "https://api.example.com"
        },
        "resources": {
            "limits": {
                "cpu": "1000m",
                "memory": "512Mi"
            },
            "requests": {
                "cpu": "100m",
                "memory": "128Mi"
            }
        },
        "config": {
            "database_url": "postgresql://db:5432/myapp",
            "cache_ttl": "3600",
            "feature_flags": "flag1,flag2,flag3"
        },
        "health_check": "/healthz"
    },
    {
        "name": "worker",
        "namespace": "production",
        "version": "v1.0.0",
        "replicas": 5,
        "image": "myapp-worker",
        "tag": "1.0.0",
        "port": 9090,
        "env": {
            "WORKER_MODE": "async",
            "QUEUE_URL": "redis://redis:6379"
        },
        "resources": {
            "limits": {
                "cpu": "500m",
                "memory": "256Mi"
            },
            "requests": {
                "cpu": "50m",
                "memory": "64Mi"
            }
        },
        "config": {
            "max_jobs": "100",
            "timeout": "300"
        }
    }
]

print("=" * 80)
print("KUBERNETES MANIFESTS GENERATED WITH LUMA")
print("=" * 80)

for app in apps:
    print(f"\n{'=' * 80}")
    print(f"Application: {app['name']}")
    print(f"{'=' * 80}")

    # Generate Deployment
    deployment_manifest = deployment_template.render(app=app)
    print(deployment_manifest)

    # Generate Service
    service_manifest = service_template.render(app=app)
    print(service_manifest)

    # Generate ConfigMap
    configmap_manifest = configmap_template.render(app=app)
    print(configmap_manifest)

print("\n" + "=" * 80)
print("✅ All manifests generated successfully!")
print("=" * 80)
print("\nTo apply these manifests:")
print("  python kubernetes.py | kubectl apply -f -")
print("\nTo save to file:")
print("  python kubernetes.py > manifests.yaml")
