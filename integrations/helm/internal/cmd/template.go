package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/santosr2/helm-luma/internal/chart"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
)

type templateOptions struct {
	valuesFiles []string
	values      []string
	outputDir   string
	showOnly    []string
	namespace   string
	releaseName string
}

func newTemplateCmd() *cobra.Command {
	opts := &templateOptions{}

	cmd := &cobra.Command{
		Use:   "template [NAME] [CHART]",
		Short: "Render chart templates using Luma",
		Long: `Render chart templates locally using Luma template engine.

This command takes a chart path and renders all templates using Luma syntax.
The rendered output can be displayed or written to files.

Example:
  helm luma template myrelease ./mychart
  helm luma template myrelease ./mychart -f values.yaml
  helm luma template myrelease ./mychart --set replicas=5`,
		Args: cobra.MinimumNArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			opts.releaseName = args[0]
			chartPath := args[1]

			return runTemplate(opts, chartPath)
		},
	}

	cmd.Flags().StringArrayVarP(&opts.valuesFiles, "values", "f", nil, "Specify values in a YAML file (can specify multiple)")
	cmd.Flags().StringArrayVar(&opts.values, "set", nil, "Set values on the command line (can specify multiple)")
	cmd.Flags().StringVarP(&opts.outputDir, "output-dir", "o", "", "Write templates to files in output-dir instead of stdout")
	cmd.Flags().StringArrayVarP(&opts.showOnly, "show-only", "s", nil, "Only show the specified templates")
	cmd.Flags().StringVarP(&opts.namespace, "namespace", "n", "default", "Kubernetes namespace")

	return cmd
}

func runTemplate(opts *templateOptions, chartPath string) error {
	// Load chart
	c, err := chart.LoadChart(chartPath)
	if err != nil {
		return fmt.Errorf("failed to load chart: %w", err)
	}

	// Load values
	values := make(map[string]interface{})

	// Load from values files
	for _, valuesFile := range opts.valuesFiles {
		data, err := os.ReadFile(valuesFile)
		if err != nil {
			return fmt.Errorf("failed to read values file %s: %w", valuesFile, err)
		}

		var fileValues map[string]interface{}
		if err := yaml.Unmarshal(data, &fileValues); err != nil {
			return fmt.Errorf("failed to parse values file %s: %w", valuesFile, err)
		}

		// Merge values
		values = mergeMaps(values, fileValues)
	}

	// Apply --set values
	for _, setValue := range opts.values {
		parts := strings.SplitN(setValue, "=", 2)
		if len(parts) != 2 {
			return fmt.Errorf("invalid --set format: %s", setValue)
		}
		setNestedValue(values, parts[0], parts[1])
	}

	// Build Helm context
	helmContext := map[string]interface{}{
		"Values": values,
		"Chart": map[string]interface{}{
			"Name":        c.Metadata.Name,
			"Version":     c.Metadata.Version,
			"AppVersion":  c.Metadata.AppVersion,
			"Description": c.Metadata.Description,
		},
		"Release": map[string]interface{}{
			"Name":      opts.releaseName,
			"Namespace": opts.namespace,
			"IsUpgrade": false,
			"IsInstall": true,
		},
	}

	// Render templates
	rendered, err := chart.RenderTemplates(c, helmContext, opts.showOnly)
	if err != nil {
		return fmt.Errorf("failed to render templates: %w", err)
	}

	// Output results
	if opts.outputDir != "" {
		// Write to files
		if err := os.MkdirAll(opts.outputDir, 0755); err != nil {
			return fmt.Errorf("failed to create output directory: %w", err)
		}

		for name, content := range rendered {
			outputPath := filepath.Join(opts.outputDir, filepath.Base(name))
			if err := os.WriteFile(outputPath, []byte(content), 0644); err != nil {
				return fmt.Errorf("failed to write %s: %w", outputPath, err)
			}
		}
		fmt.Printf("Templates written to %s\n", opts.outputDir)
	} else {
		// Print to stdout
		for name, content := range rendered {
			fmt.Printf("---\n# Source: %s\n", name)
			fmt.Println(content)
		}
	}

	return nil
}

// mergeMaps merges two maps, with values from src overwriting dst
func mergeMaps(dst, src map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for k, v := range dst {
		result[k] = v
	}
	for k, v := range src {
		if dstMap, dstOk := result[k].(map[string]interface{}); dstOk {
			if srcMap, srcOk := v.(map[string]interface{}); srcOk {
				result[k] = mergeMaps(dstMap, srcMap)
				continue
			}
		}
		result[k] = v
	}
	return result
}

// setNestedValue sets a value in a nested map using dot notation
func setNestedValue(m map[string]interface{}, key string, value string) {
	keys := strings.Split(key, ".")
	current := m

	for i := 0; i < len(keys)-1; i++ {
		if _, ok := current[keys[i]]; !ok {
			current[keys[i]] = make(map[string]interface{})
		}
		if nextMap, ok := current[keys[i]].(map[string]interface{}); ok {
			current = nextMap
		}
	}

	current[keys[len(keys)-1]] = value
}
