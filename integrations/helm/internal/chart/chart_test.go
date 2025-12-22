package chart_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/santosr2/helm-luma/internal/chart"
)

func TestLoadChart(t *testing.T) {
	// Create a temporary chart directory
	tmpDir := t.TempDir()

	// Create Chart.yaml
	chartYAML := `apiVersion: v2
name: test-chart
version: 0.1.0
appVersion: "1.0"
description: A test chart`

	if err := os.WriteFile(filepath.Join(tmpDir, "Chart.yaml"), []byte(chartYAML), 0644); err != nil {
		t.Fatal(err)
	}

	// Create values.yaml
	valuesYAML := `replicas: 3
image:
  repository: nginx
  tag: latest`

	if err := os.WriteFile(filepath.Join(tmpDir, "values.yaml"), []byte(valuesYAML), 0644); err != nil {
		t.Fatal(err)
	}

	// Create templates directory with a template
	templatesDir := filepath.Join(tmpDir, "templates")
	if err := os.MkdirAll(templatesDir, 0755); err != nil {
		t.Fatal(err)
	}

	template := `apiVersion: v1
kind: Service
metadata:
  name: $Chart.Name`

	if err := os.WriteFile(filepath.Join(templatesDir, "service.luma"), []byte(template), 0644); err != nil {
		t.Fatal(err)
	}

	// Load the chart
	c, err := chart.LoadChart(tmpDir)
	if err != nil {
		t.Fatalf("LoadChart() error = %v", err)
	}

	// Verify metadata
	if c.Metadata.Name != "test-chart" {
		t.Errorf("Chart name = %s, want test-chart", c.Metadata.Name)
	}
	if c.Metadata.Version != "0.1.0" {
		t.Errorf("Chart version = %s, want 0.1.0", c.Metadata.Version)
	}

	// Verify values
	if replicas, ok := c.Values["replicas"].(int); !ok || replicas != 3 {
		t.Errorf("Values.replicas = %v, want 3", c.Values["replicas"])
	}

	// Verify templates
	if len(c.Templates) != 1 {
		t.Errorf("Got %d templates, want 1", len(c.Templates))
	}
	if c.Templates[0].Name != "templates/service.luma" {
		t.Errorf("Template name = %s, want templates/service.luma", c.Templates[0].Name)
	}
}

func TestRenderTemplates(t *testing.T) {
	c := &chart.Chart{
		Metadata: chart.ChartMetadata{
			Name:    "test-app",
			Version: "1.0.0",
		},
		Templates: []chart.Template{
			{
				Name: "templates/service.yaml",
				Content: `apiVersion: v1
kind: Service
metadata:
  name: $Chart.Name
spec:
  ports:
    - port: $Values.port`,
			},
		{
			Name: "templates/deployment.yaml",
			Content: `apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${Release.Name ~ "-" ~ Chart.Name}
spec:
  replicas: ${Values.replicas | default(1)}`,
		},
		},
	}

	context := map[string]interface{}{
		"Chart": map[string]interface{}{
			"Name":    "test-app",
			"Version": "1.0.0",
		},
		"Release": map[string]interface{}{
			"Name": "my-release",
		},
		"Values": map[string]interface{}{
			"port":     80,
			"replicas": 3,
		},
	}

	rendered, err := chart.RenderTemplates(c, context, nil)
	if err != nil {
		t.Fatalf("RenderTemplates() error = %v", err)
	}

	if len(rendered) != 2 {
		t.Errorf("Got %d rendered templates, want 2", len(rendered))
	}

	// Check service template
	if service, ok := rendered["templates/service.yaml"]; ok {
		if !strings.Contains(service, "name: test-app") {
			t.Errorf("Service template missing chart name")
		}
		if !strings.Contains(service, "port: 80") {
			t.Errorf("Service template missing port")
		}
	} else {
		t.Error("Service template not rendered")
	}

	// Check deployment template
	if deployment, ok := rendered["templates/deployment.yaml"]; ok {
		if !strings.Contains(deployment, "name: my-release-test-app") {
			t.Errorf("Deployment template missing release name. Got:\n%s", deployment)
		}
		if !strings.Contains(deployment, "replicas: 3") {
			t.Errorf("Deployment template missing replicas. Got:\n%s", deployment)
		}
	} else {
		t.Error("Deployment template not rendered")
	}
}

func TestRenderTemplatesWithShowOnly(t *testing.T) {
	c := &chart.Chart{
		Metadata: chart.ChartMetadata{
			Name: "test-app",
		},
		Templates: []chart.Template{
			{
				Name:    "templates/service.yaml",
				Content: "apiVersion: v1\nkind: Service",
			},
			{
				Name:    "templates/deployment.yaml",
				Content: "apiVersion: apps/v1\nkind: Deployment",
			},
			{
				Name:    "templates/ingress.yaml",
				Content: "apiVersion: networking.k8s.io/v1\nkind: Ingress",
			},
		},
	}

	context := map[string]interface{}{
		"Chart": map[string]interface{}{
			"Name": "test-app",
		},
		"Values": map[string]interface{}{},
	}

	// Show only service
	rendered, err := chart.RenderTemplates(c, context, []string{"service"})
	if err != nil {
		t.Fatalf("RenderTemplates() error = %v", err)
	}

	if len(rendered) != 1 {
		t.Errorf("Got %d rendered templates, want 1", len(rendered))
	}

	if _, ok := rendered["templates/service.yaml"]; !ok {
		t.Error("Service template not rendered")
	}
	if _, ok := rendered["templates/deployment.yaml"]; ok {
		t.Error("Deployment template should not be rendered")
	}
}

func TestRenderTemplatesWithConditional(t *testing.T) {
	c := &chart.Chart{
		Metadata: chart.ChartMetadata{
			Name: "test-app",
		},
		Templates: []chart.Template{
			{
				Name: "templates/ingress.yaml",
				Content: `@if Values.ingress.enabled
apiVersion: networking.k8s.io/v1
kind: Ingress
@end`,
			},
		},
	}

	// Test with ingress disabled
	context := map[string]interface{}{
		"Chart": map[string]interface{}{
			"Name": "test-app",
		},
		"Values": map[string]interface{}{
			"ingress": map[string]interface{}{
				"enabled": false,
			},
		},
	}

	rendered, err := chart.RenderTemplates(c, context, nil)
	if err != nil {
		t.Fatalf("RenderTemplates() error = %v", err)
	}

	// Should be empty (conditional template with false condition)
	if len(rendered) > 0 {
		t.Errorf("Expected no templates rendered, got %d", len(rendered))
	}

	// Test with ingress enabled
	context["Values"].(map[string]interface{})["ingress"].(map[string]interface{})["enabled"] = true

	rendered, err = chart.RenderTemplates(c, context, nil)
	if err != nil {
		t.Fatalf("RenderTemplates() error = %v", err)
	}

	if len(rendered) != 1 {
		t.Errorf("Expected 1 template rendered, got %d", len(rendered))
	}

	if ingress, ok := rendered["templates/ingress.yaml"]; ok {
		if !strings.Contains(ingress, "kind: Ingress") {
			t.Error("Ingress template missing Ingress kind")
		}
	}
}
