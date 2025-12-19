# Helm-Luma Plugin

Helm plugin for using Luma templates in Kubernetes charts.

## Status

✅ **Production Ready** - v0.1.0 - Fully implemented, tested, and documented.

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

## Features

✅ **Implemented**:

- `helm luma template` - Render charts with Luma templates
- `helm luma convert` - Convert Go templates to Luma syntax
- Full Helm context support (Values, Chart, Release)
- Values file support (-f flag)
- Command-line value overrides (--set flag)
- Output to files or stdout
- Conditional templates
- Complete example chart

## Implementation

Built as a Go plugin using luma-go bindings.

### Commands

- **template**: Render Helm charts using Luma syntax
- **convert**: Convert existing Go templates to Luma
- **version**: Show version information

### Architecture

- Uses luma-go for template rendering
- Integrates with Helm chart structure
- Supports all Luma features (filters, loops, conditionals)
- Compatible with standard Helm workflows

## License

MIT
