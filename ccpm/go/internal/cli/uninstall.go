package cli

import (
	"fmt"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/claude"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/plinde/claude-utils/ccpm/internal/plugin"
	"github.com/spf13/cobra"
)

var uninstallCmd = &cobra.Command{
	Use:   "uninstall <plugin@marketplace> [plugin@marketplace...]",
	Short: "Uninstall specific plugin(s)",
	Long: `Uninstall one or more plugins.

Examples:
  ccpm uninstall trivy@plinde-plugins
  ccpm uninstall trivy@plinde-plugins snyk@elastic-psec-plugins`,
	Args: cobra.MinimumNArgs(1),
	RunE: runUninstall,
}

func init() {
	rootCmd.AddCommand(uninstallCmd)
}

func runUninstall(cmd *cobra.Command, args []string) error {
	output.Info("=== Uninstalling plugins ===")
	fmt.Println()

	success := 0
	failed := 0

	installed, _ := plugin.LoadInstalled()

	for _, spec := range args {
		pluginName, marketplace, err := parsePluginSpec(spec, installed)
		if err != nil {
			fmt.Printf("  %s %s - %s\n", output.Red("✗"), spec, err)
			failed++
			continue
		}

		pluginID := fmt.Sprintf("%s@%s", pluginName, marketplace)
		fmt.Printf("  %s... ", pluginID)

		if err := claude.PluginUninstall(pluginID); err != nil {
			fmt.Printf("%s\n", output.Red("failed"))
			failed++
		} else {
			fmt.Printf("%s\n", output.Green("uninstalled"))
			success++
		}
	}

	fmt.Println()
	if failed == 0 {
		output.Success("Done! Uninstalled %d plugin(s).", success)
	} else {
		output.Warning("Done. Uninstalled %d, failed %d.", success, failed)
		return fmt.Errorf("failed to uninstall %d plugin(s)", failed)
	}

	return nil
}

// findMarketplaceForPlugin finds which marketplace a plugin is installed from
func findMarketplaceForPlugin(pluginName string, installed *plugin.InstalledPlugins) (string, error) {
	var matches []string
	for id := range installed.Plugins {
		parsed, err := plugin.ParsePluginID(id)
		if err != nil {
			continue
		}
		if strings.EqualFold(parsed.Name, pluginName) {
			matches = append(matches, parsed.Marketplace)
		}
	}

	if len(matches) == 0 {
		return "", fmt.Errorf("not installed")
	}

	if len(matches) > 1 {
		return "", fmt.Errorf("ambiguous - installed from multiple marketplaces: %s", strings.Join(matches, ", "))
	}

	return matches[0], nil
}
