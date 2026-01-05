package cli

import (
	"fmt"

	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/spf13/cobra"
)

var removeCmd = &cobra.Command{
	Use:   "remove <org/repo>",
	Short: "Remove a marketplace mapping",
	Long: `Remove a marketplace mapping from the configuration.

Example:
  ccpm remove plinde/claude-plugins`,
	Args: cobra.ExactArgs(1),
	RunE: runRemove,
}

func init() {
	rootCmd.AddCommand(removeCmd)
}

func runRemove(cmd *cobra.Command, args []string) error {
	repo := args[0]

	// Check if exists
	if cfg.GetAlias(repo) == "" {
		return fmt.Errorf("marketplace not found: %s", repo)
	}

	// Remove from config
	if !cfg.RemoveMarketplace(repo) {
		return fmt.Errorf("failed to remove: %s", repo)
	}

	if err := cfg.Save(); err != nil {
		return fmt.Errorf("saving config: %w", err)
	}

	output.Success("Removed %s", repo)
	return nil
}
