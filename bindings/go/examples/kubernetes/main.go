package main

import (
	"fmt"
	"log"

	"github.com/santosr2/luma/bindings/go"
)

func main() {
	// Example: Kubernetes Deployment template
	template := `apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app.name}
  labels:
    app: ${app.name}
    version: ${app.version}
spec:
  replicas: ${replicas | default(3)}
  selector:
    matchLabels:
      app: ${app.name}
  template:
    metadata:
      labels:
        app: ${app.name}
        version: ${app.version}
    spec:
      containers:
@for container in containers
        - name: ${container.name}
          image: ${container.image}:${container.tag | default("latest")}
@if container.ports
          ports:
@for port in container.ports
            - containerPort: ${port.port}
              name: ${port.name}
              protocol: ${port.protocol | default("TCP")}
@end
@end
@if container.env
          env:
@for key, value in pairs(container.env)
            - name: ${key}
              value: "${value}"
@end
@end
          resources:
            requests:
              memory: "${container.resources.memory | default('256Mi')}"
              cpu: "${container.resources.cpu | default('100m')}"
@end
`

	context := map[string]interface{}{
		"app": map[string]interface{}{
			"name":    "my-app",
			"version": "1.0.0",
		},
		"replicas": 5,
		"containers": []interface{}{
			map[string]interface{}{
				"name":  "web",
				"image": "nginx",
				"tag":   "1.21",
				"ports": []interface{}{
					map[string]interface{}{
						"port": 80,
						"name": "http",
					},
					map[string]interface{}{
						"port":     443,
						"name":     "https",
						"protocol": "TCP",
					},
				},
				"env": map[string]interface{}{
					"ENV":      "production",
					"LOG_LEVEL": "info",
				},
				"resources": map[string]interface{}{
					"memory": "512Mi",
					"cpu":    "500m",
				},
			},
			map[string]interface{}{
				"name":  "sidecar",
				"image": "busybox",
				"env": map[string]interface{}{
					"SIDECAR_MODE": "enabled",
				},
			},
		},
	}

	result, err := luma.Render(template, context)
	if err != nil {
		log.Fatalf("Error rendering template: %v", err)
	}

	fmt.Println(result)
}
