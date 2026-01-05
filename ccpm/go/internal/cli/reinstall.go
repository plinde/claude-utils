package cli

import (
	"fmt"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/claude"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/plinde/claude-utils/ccpm/internal/plugin"
	"github.com/spf13/cobra"
)

var (
	reinstallAll string
)

var reinstallCmd = &cobra.Command{
	Use:   "reinstall <plugin@marketplace> [plugin@marketplace...]",
	Short: "Reinstall specific plugin(s)",
	Long: `Reinstall one or more plugins by uninstalling and installing them.

Examples:
  ccpm reinstall trivy@plinde-plugins
  ccpm reinstall trivy@plinde-plugins snyk@elastic-psec-plugins
  ccpm reinstall --all plinde-plugins    # Reinstall all plugins from marketplace`,
	RunE: runReinstall,
}

func init() {
	reinstallCmd.Flags().StringVar(&reinstallAll, "all", "", "reinstall all plugins from a marketplace")
	rootCmd.AddCommand(reinstallCmd)
}

func runReinstall(cmd *cobra.Command, args []string) error {
	var pluginSpecs []string

	// Handle --all mode
	if reinstallAll != "" {
		installed, err := plugin.LoadInstalled()
		if err != nil {
			return fmt.Errorf("loading installed plugins: %w", err)
		}

		plugins := installed.PluginsForMarketplace(reinstallAll)
		if len(plugins) == 0 {
			output.Warning("No plugins installed from %s", reinstallAll)
			return nil
		}

		for _, p := range plugins {
			pluginSpecs = append(pluginSpecs, fmt.Sprintf("%s@%s", p, reinstallAll))
		}
	} else {
		if len(args) == 0 {
			return fmt.Errorf("no plugins specified\nUsage: ccpm reinstall <plugin@marketplace> [plugin@marketplace...]\n       ccpm reinstall --all <marketplace-alias>")
		}
		pluginSpecs = args
	}

	if dryRun {
		fmt.Println("DRY RUN MODE - no changes will be made")
		fmt.Println()
	}

	output.Info("=== Reinstalling plugins ===")
	fmt.Println()

	success := 0
	failed := 0

	installed, _ := plugin.LoadInstalled()

	for _, spec := range pluginSpecs {
		pluginName, marketplace, err := parsePluginSpec(spec, installed)
		if err != nil {
			fmt.Printf("  %s %s - %s\n", output.Red("✗"), spec, err)
			failed++
			continue
		}

		pluginID := fmt.Sprintf("%s@%s", pluginName, marketplace)
		fmt.Printf("  %s... ", pluginID)

		if dryRun {
			fmt.Println("would reinstall")
			success++
			continue
		}

		if err := claude.PluginReinstall(pluginID); err != nil {
			fmt.Printf("%s\n", output.Red("failed"))
			failed++
		} else {
			fmt.Printf("%s\n", output.Green("reinstalled"))
			success++
		}
	}

	fmt.Println()
	if failed == 0 {
		output.Success("Done! Reinstalled %d plugin(s).", success)
	} else {
		output.Warning("Done. Reinstalled %d, failed %d.", success, failed)
		return fmt.Errorf("failed to reinstall %d plugin(s)", failed)
	}

	return nil
}

// parsePluginSpec parses "plugin@marketplace" or finds the marketplace for a plugin name
func parsePluginSpec(spec string, installed *plugin.InstalledPlugins) (pluginName, marketplace string, err error) {
	if strings.Contains(spec, "@") {
		parts := strings.SplitN(spec, "@", 2)
		return parts[0], parts[1], nil
	}

	// Try to find which marketplace this plugin is installed from
	var matches []string
	for id := range installed.Plugins {
		parsed, err := plugin.ParsePluginID(id)
		if err != nil {
			continue
		}
		if parsed.Name == spec {
			matches = append(matches, parsed.Marketplace)
		}
	}

	if len(matches) == 0 {
		return "", "", fmt.Errorf("not found in any marketplace")
	}

	if len(matches) > 1 {
		return "", "", fmt.Errorf("ambiguous - exists in multiple marketplaces: %s\nPlease specify: %s@<marketplace>", strings.Join(matches, ", "), spec)
	}

	return spec, matches[0], nil
}
