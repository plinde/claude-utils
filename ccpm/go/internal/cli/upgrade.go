package cli

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/plinde/claude-utils/ccpm/internal/claude"
	"github.com/plinde/claude-utils/ccpm/internal/config"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/spf13/cobra"
)

var upgradeCmd = &cobra.Command{
	Use:   "upgrade [org/repo...]",
	Short: "Fetch and reinstall changed plugins",
	Long: `Fetch the latest marketplace catalogs and reinstall any plugins that have changed.

If no repos are specified, upgrades all configured marketplaces.

Example:
  ccpm upgrade                      # Upgrade all marketplaces
  ccpm upgrade plinde/claude-plugins   # Upgrade specific marketplace
  ccpm upgrade --dry-run            # Show what would be upgraded`,
	RunE: runUpgrade,
}

func init() {
	rootCmd.AddCommand(upgradeCmd)
}

func runUpgrade(cmd *cobra.Command, args []string) error {
	aliases, err := getTargetAliases(args)
	if err != nil {
		return err
	}

	if dryRun {
		fmt.Println("DRY RUN MODE - no changes will be made")
		fmt.Println()
	}

	output.Info("=== Upgrading plugins ===")
	fmt.Println()

	totalUpdated := 0
	anyChanges := false
	pluginsDir := config.PluginsDir()

	for _, alias := range aliases {
		mpDir := filepath.Join(pluginsDir, alias)

		if _, err := os.Stat(mpDir); os.IsNotExist(err) {
			fmt.Printf("  %s: not installed, skipping\n", output.Dim(alias))
			continue
		}

		// Get current commit hash
		oldHash := getGitHash(mpDir)
		if oldHash == "" {
			fmt.Printf("  %s: not a git repo, skipping\n", output.Yellow(alias))
			continue
		}

		fmt.Printf("  %s... ", alias)

		// Update the marketplace (unless dry-run)
		if !dryRun {
			_ = claude.MarketplaceUpdate(alias)
		}

		// Get new commit hash
		newHash := getGitHash(mpDir)

		if oldHash == newHash {
			fmt.Printf("%s\n", output.Dim("up to date"))
			continue
		}

		// Get list of changed plugins
		changed := getChangedPlugins(mpDir, oldHash, newHash)

		if len(changed) == 0 {
			fmt.Printf("%s\n", output.Dim("no plugin changes"))
			continue
		}

		fmt.Printf("%s\n", output.Green(fmt.Sprintf("%d plugin(s) to upgrade", len(changed))))
		anyChanges = true

		// Reinstall changed plugins
		for _, pluginName := range changed {
			pluginID := fmt.Sprintf("%s@%s", pluginName, alias)
			fmt.Printf("    %s... ", pluginName)

			if dryRun {
				fmt.Println("would reinstall")
				continue
			}

			// Try to reinstall
			if err := claude.PluginReinstall(pluginID); err != nil {
				fmt.Printf("%s\n", output.Red("failed"))
			} else {
				fmt.Printf("%s\n", output.Green("upgraded"))
				totalUpdated++
			}
		}
	}

	fmt.Println()
	if !anyChanges {
		fmt.Printf("%s\n", output.Dim("All plugins up to date."))
	} else if dryRun {
		output.Warning("Dry run complete. Run without --dry-run to apply changes.")
	} else {
		output.Success("Done! Upgraded %d plugin(s).", totalUpdated)
	}

	return nil
}
