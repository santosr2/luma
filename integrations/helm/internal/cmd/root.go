package cmd

import (
	"github.com/spf13/cobra"
)

// NewRootCmd creates the root command for helm-luma plugin
func NewRootCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "luma",
		Short: "Use Luma templates in Helm charts",
		Long: `A Helm plugin that enables Luma template syntax as an alternative to Go templates.
Provides cleaner, more readable templates for Kubernetes manifests.

Luma syntax:
  - Variables: $var or ${expression}
  - Conditionals: @if condition ... @end
  - Loops: @for item in items ... @end
  - Filters: $value | upper | default('fallback')

Example:
  helm luma template mychart -f values.yaml
  helm luma convert templates/deployment.yaml`,
		SilenceUsage: true,
	}

	// Add subcommands
	cmd.AddCommand(newTemplateCmd())
	cmd.AddCommand(newConvertCmd())
	cmd.AddCommand(newVersionCmd())

	return cmd
}

func newVersionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Run: func(cmd *cobra.Command, args []string) {
			cmd.Println("helm-luma version 0.1.0")
			cmd.Println("Luma template engine with Helm integration")
		},
	}
}
