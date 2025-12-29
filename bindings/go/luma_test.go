package luma_test

import (
	"strings"
	"testing"

	"github.com/santosr2/luma/bindings/go"
)

func TestRenderSimple(t *testing.T) {
	tests := []struct {
		name     string
		template string
		context  interface{}
		want     string
		wantErr  bool
	}{
		{
			name:     "simple variable",
			template: "Hello, $name!",
			context:  map[string]interface{}{"name": "World"},
			want:     "Hello, World!",
		},
		{
			name:     "expression",
			template: "${1 + 2}",
			context:  map[string]interface{}{},
			want:     "3",
		},
		{
			name:     "if statement",
			template: "@if show\nVisible\n@end",
			context:  map[string]interface{}{"show": true},
			want:     "Visible\n",
		},
		{
			name:     "for loop",
			template: "@for item in items\n- $item\n@end",
			context: map[string]interface{}{
				"items": []interface{}{"a", "b", "c"},
			},
			want: "- a\n- b\n- c\n",
		},
		{
			name:     "nested data",
			template: "$user.name is $user.age years old",
			context: map[string]interface{}{
				"user": map[string]interface{}{
					"name": "Alice",
					"age":  30,
				},
			},
			want: "Alice is 30 years old",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := luma.Render(tt.template, tt.context)
			if (err != nil) != tt.wantErr {
				t.Errorf("Render() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && got != tt.want {
				t.Errorf("Render() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestRenderJinja2Syntax(t *testing.T) {
	tests := []struct {
		name     string
		template string
		context  interface{}
		want     string
	}{
		{
			name:     "jinja variable",
			template: "Hello, {{ name }}!",
			context:  map[string]interface{}{"name": "World"},
			want:     "Hello, World!",
		},
		{
			name:     "jinja if",
			template: "{% if show %}Visible{% endif %}",
			context:  map[string]interface{}{"show": true},
			want:     "Visible",
		},
		{
			name:     "jinja for",
			template: "{% for item in items %}{{ item }} {% endfor %}",
			context: map[string]interface{}{
				"items": []interface{}{"a", "b", "c"},
			},
			want: "a b c ",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := luma.Render(tt.template, tt.context)
			if err != nil {
				t.Errorf("Render() error = %v", err)
				return
			}
			if got != tt.want {
				t.Errorf("Render() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestCompileAndExecute(t *testing.T) {
	template := "Hello, $name!"

	// Compile once
	tmpl, err := luma.Compile(template)
	if err != nil {
		t.Fatalf("Compile() error = %v", err)
	}

	// Execute multiple times
	tests := []struct {
		name    string
		context interface{}
		want    string
	}{
		{
			name:    "Alice",
			context: map[string]interface{}{"name": "Alice"},
			want:    "Hello, Alice!",
		},
		{
			name:    "Bob",
			context: map[string]interface{}{"name": "Bob"},
			want:    "Hello, Bob!",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := tmpl.Execute(tt.context)
			if err != nil {
				t.Errorf("Execute() error = %v", err)
				return
			}
			if got != tt.want {
				t.Errorf("Execute() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestTemplateSource(t *testing.T) {
	source := "Hello, $name!"
	tmpl, err := luma.Compile(source)
	if err != nil {
		t.Fatalf("Compile() error = %v", err)
	}

	if got := tmpl.Source(); got != source {
		t.Errorf("Source() = %q, want %q", got, source)
	}
}

func TestRenderWithFilters(t *testing.T) {
	tests := []struct {
		name     string
		template string
		context  interface{}
		want     string
	}{
		{
			name:     "upper filter",
			template: "${name | upper}",
			context:  map[string]interface{}{"name": "hello"},
			want:     "HELLO",
		},
		{
			name:     "default filter",
			template: "${missing | default('fallback')}",
			context:  map[string]interface{}{},
			want:     "fallback",
		},
		{
			name:     "join filter",
			template: "${items | join(', ')}",
			context: map[string]interface{}{
				"items": []interface{}{"a", "b", "c"},
			},
			want: "a, b, c",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := luma.Render(tt.template, tt.context)
			if err != nil {
				t.Errorf("Render() error = %v", err)
				return
			}
			if got != tt.want {
				t.Errorf("Render() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestRenderKubernetesStyle(t *testing.T) {
	template := `apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
spec:
  replicas: ${replicas | default(3)}
  template:
    spec:
      containers:
@for container in containers
        - name: $container.name
          image: $container.image
@end`

	context := map[string]interface{}{
		"name":     "my-app",
		"replicas": 5,
		"containers": []interface{}{
			map[string]interface{}{
				"name":  "web",
				"image": "nginx:latest",
			},
			map[string]interface{}{
				"name":  "sidecar",
				"image": "busybox:latest",
			},
		},
	}

	result, err := luma.Render(template, context)
	if err != nil {
		t.Fatalf("Render() error = %v", err)
	}

	// Check key parts are present
	if !strings.Contains(result, "name: my-app") {
		t.Errorf("Result missing 'name: my-app'")
	}
	if !strings.Contains(result, "replicas: 5") {
		t.Errorf("Result missing 'replicas: 5'")
	}
	if !strings.Contains(result, "- name: web") {
		t.Errorf("Result missing container 'web'")
	}
	if !strings.Contains(result, "image: nginx:latest") {
		t.Errorf("Result missing nginx image")
	}
}

func BenchmarkRender(b *testing.B) {
	template := "Hello, $name!"
	context := map[string]interface{}{"name": "World"}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := luma.Render(template, context)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkCompileAndExecute(b *testing.B) {
	template := "Hello, $name!"
	context := map[string]interface{}{"name": "World"}

	tmpl, err := luma.Compile(template)
	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := tmpl.Execute(context)
		if err != nil {
			b.Fatal(err)
		}
	}
}
