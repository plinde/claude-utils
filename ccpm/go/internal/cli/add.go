package cli

import (
	"fmt"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/plinde/claude-utils/ccpm/internal/plugin"
	"github.com/spf13/cobra"
)

var addCmd = &cobra.Command{
	Use:   "add <org/repo> <alias>",
	Short: "Add a marketplace mapping",
	Long: `Add a mapping from an org/repo to a marketplace alias.

Example:
  ccpm add plinde/claude-plugins plinde-plugins`,
	Args: cobra.ExactArgs(2),
	RunE: runAdd,
}

func init() {
	rootCmd.AddCommand(addCmd)
}

func runAdd(cmd *cobra.Command, args []string) error {
	repo := args[0]
	alias := args[1]

	// Validate repo format
	if !strings.Contains(repo, "/") {
		return fmt.Errorf("invalid repo format: %s (expected org/name)", repo)
	}

	// Warn if alias conflicts with an installed plugin name
	installed, _ := plugin.LoadInstalled()
	if installed != nil {
		var conflicts []string
		for id := range installed.Plugins {
			parsed, err := plugin.ParsePluginID(id)
			if err != nil {
				continue
			}
			if strings.EqualFold(parsed.Name, alias) {
				conflicts = append(conflicts, id)
			}
		}

		if len(conflicts) > 0 {
			output.Warning("Alias '%s' matches installed plugin(s):", alias)
			for _, p := range conflicts {
				fmt.Printf("  - %s\n", p)
			}
			fmt.Println("This may cause confusion when using 'ccpm list " + alias + "'.")
			fmt.Println()
		}
	}

	// Add to config
	cfg.AddMarketplace(repo, alias)
	if err := cfg.Save(); err != nil {
		return fmt.Errorf("saving config: %w", err)
	}

	output.Success("Added %s -> %s", repo, alias)
	return nil
}
