package chart

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	luma "github.com/santosr2/luma-go"
	"gopkg.in/yaml.v3"
)

// Chart represents a Helm chart
type Chart struct {
	Metadata  ChartMetadata
	Templates []Template
	Values    map[string]interface{}
	Path      string
}

// ChartMetadata represents Chart.yaml
type ChartMetadata struct {
	Name        string `yaml:"name"`
	Version     string `yaml:"version"`
	AppVersion  string `yaml:"appVersion"`
	Description string `yaml:"description"`
	Keywords    []string `yaml:"keywords"`
	Home        string `yaml:"home"`
	Sources     []string `yaml:"sources"`
}

// Template represents a template file
type Template struct {
	Name    string
	Path    string
	Content string
}

// LoadChart loads a Helm chart from a directory
func LoadChart(chartPath string) (*Chart, error) {
	chart := &Chart{
		Path: chartPath,
	}

	// Load Chart.yaml
	chartFile := filepath.Join(chartPath, "Chart.yaml")
	data, err := os.ReadFile(chartFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read Chart.yaml: %w", err)
	}

	if err := yaml.Unmarshal(data, &chart.Metadata); err != nil {
		return nil, fmt.Errorf("failed to parse Chart.yaml: %w", err)
	}

	// Load default values.yaml
	valuesFile := filepath.Join(chartPath, "values.yaml")
	if data, err := os.ReadFile(valuesFile); err == nil {
		if err := yaml.Unmarshal(data, &chart.Values); err != nil {
			return nil, fmt.Errorf("failed to parse values.yaml: %w", err)
		}
	}

	// Load templates
	templatesDir := filepath.Join(chartPath, "templates")
	if err := filepath.Walk(templatesDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		// Only process .yaml, .yml, and .luma files
		ext := filepath.Ext(path)
		if ext != ".yaml" && ext != ".yml" && ext != ".luma" {
			return nil
		}

		// Skip files starting with _ (helpers)
		if strings.HasPrefix(filepath.Base(path), "_") {
			return nil
		}

		content, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("failed to read template %s: %w", path, err)
		}

		relPath, _ := filepath.Rel(chartPath, path)
		chart.Templates = append(chart.Templates, Template{
			Name:    relPath,
			Path:    path,
			Content: string(content),
		})

		return nil
	}); err != nil {
		return nil, fmt.Errorf("failed to load templates: %w", err)
	}

	return chart, nil
}

// RenderTemplates renders all templates in a chart
func RenderTemplates(chart *Chart, context map[string]interface{}, showOnly []string) (map[string]string, error) {
	results := make(map[string]string)

	for _, tmpl := range chart.Templates {
		// Filter by showOnly if specified
		if len(showOnly) > 0 {
			matched := false
			for _, pattern := range showOnly {
				if strings.Contains(tmpl.Name, pattern) {
					matched = true
					break
				}
			}
			if !matched {
				continue
			}
		}

		// Render template
		rendered, err := luma.Render(tmpl.Content, context)
		if err != nil {
			return nil, fmt.Errorf("failed to render %s: %w", tmpl.Name, err)
		}

		// Skip empty templates
		if strings.TrimSpace(rendered) == "" {
			continue
		}

		results[tmpl.Name] = rendered
	}

	return results, nil
}
