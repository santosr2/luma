# Helm-Luma Plugin

Helm plugin for using Luma templates in Kubernetes charts.

## Status

🚧 **Planned** - Architecture defined, ready for Go implementation.

## Installation

```bash
helm plugin install https://github.com/santosr2/helm-luma
```

## Usage

```bash
# Template with Luma
helm luma template mychart -f values.yaml

# Convert Go templates to Luma
helm luma convert templates/deployment.yaml

# Dry run
helm luma install mychart --dry-run

# Install with Luma
helm luma install myrelease mychart
```

## Chart Structure

```text
mychart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.luma
    ├── service.luma
    └── _helpers.luma       # Macros
```

## Example Template

```luma
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${Chart.Name}-${Release.Name}
spec:
  replicas: ${Values.replicas | default(3)}
  template:
    spec:
      containers:
@for container in Values.containers
        - name: $container.name
          image: $container.image
@if container.env
          env:
@for key, value in pairs(container.env)
            - name: $key
              value: "$value"
@end
@end
@end
```

## Implementation

Built as Go plugin using luma-go bindings.

## License

MIT
