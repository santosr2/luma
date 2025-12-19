package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
)

type convertOptions struct {
	inPlace bool
	dryRun  bool
}

func newConvertCmd() *cobra.Command {
	opts := &convertOptions{}

	cmd := &cobra.Command{
		Use:   "convert [FILE]",
		Short: "Convert Go templates to Luma syntax",
		Long: `Convert Helm Go template syntax to Luma syntax.

This command reads a Go template file and converts common patterns to Luma syntax:
  - {{ .Values.x }} → $Values.x
  - {{ if .Values.show }} → @if Values.show
  - {{ range .Values.items }} → @for item in Values.items
  - {{ .Values.name | upper }} → $Values.name | upper

Example:
  helm luma convert templates/deployment.yaml
  helm luma convert templates/deployment.yaml --in-place
  helm luma convert templates/deployment.yaml --dry-run`,
		Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runConvert(opts, args[0])
		},
	}

	cmd.Flags().BoolVar(&opts.inPlace, "in-place", false, "Modify file in place")
	cmd.Flags().BoolVar(&opts.dryRun, "dry-run", false, "Show conversion without modifying file")

	return cmd
}

func runConvert(opts *convertOptions, filename string) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return fmt.Errorf("failed to read file: %w", err)
	}

	content := string(data)
	converted := convertGoTemplateToLuma(content)

	if opts.dryRun {
		fmt.Println(converted)
		return nil
	}

	if opts.inPlace {
		// Change extension to .luma
		newFilename := strings.TrimSuffix(filename, ".yaml") + ".luma"
		if err := os.WriteFile(newFilename, []byte(converted), 0644); err != nil {
			return fmt.Errorf("failed to write file: %w", err)
		}
		fmt.Printf("Converted: %s → %s\n", filename, newFilename)
	} else {
		fmt.Println(converted)
	}

	return nil
}

// convertGoTemplateToLuma converts common Go template patterns to Luma syntax
func convertGoTemplateToLuma(content string) string {
	result := content

	// Convert {{ .Values.x }} to $Values.x
	// Simple variables
	result = strings.ReplaceAll(result, "{{", "${")
	result = strings.ReplaceAll(result, "}}", "}")
	result = strings.ReplaceAll(result, "${ .", "${")
	result = strings.ReplaceAll(result, ". ", " ")

	// Convert control structures
	// {{ if condition }} → @if condition
	result = strings.ReplaceAll(result, "${if ", "@if ")
	result = strings.ReplaceAll(result, "{ if ", "@if ")

	// {{ else }} → @else
	result = strings.ReplaceAll(result, "${else}", "@else")
	result = strings.ReplaceAll(result, "{ else }", "@else")

	// {{ end }} → @end
	result = strings.ReplaceAll(result, "${end}", "@end")
	result = strings.ReplaceAll(result, "{ end }", "@end")

	// {{ range .Items }} → @for item in Items
	result = strings.ReplaceAll(result, "${range .", "@for item in ")
	result = strings.ReplaceAll(result, "{ range .", "@for item in ")

	// {{ with .X }} → @let x = X (approximate)
	result = strings.ReplaceAll(result, "${with .", "@let temp = ")
	result = strings.ReplaceAll(result, "{ with .", "@let temp = ")

	// Clean up simple variable references
	// Remove leading dots
	for strings.Contains(result, "${.") {
		result = strings.ReplaceAll(result, "${.", "$")
	}

	// Convert ${Values.x} to $Values.x when no pipe or complex expression
	lines := strings.Split(result, "\n")
	for i, line := range lines {
		// If line has ${ but no | or other operators, simplify
		if strings.Contains(line, "${") && !strings.Contains(line, "|") &&
		   !strings.Contains(line, "+") && !strings.Contains(line, "-") &&
		   !strings.Contains(line, "*") && !strings.Contains(line, "(") {
			line = strings.ReplaceAll(line, "${", "$")
			line = strings.ReplaceAll(line, "}", "")
			lines[i] = line
		}
	}
	result = strings.Join(lines, "\n")

	return result
}
