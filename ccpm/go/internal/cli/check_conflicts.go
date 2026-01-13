package cli

import (
	"fmt"
	"sort"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/plinde/claude-utils/ccpm/internal/plugin"
	"github.com/spf13/cobra"
)

var checkConflictsCmd = &cobra.Command{
	Use:   "check-conflicts",
	Short: "Check for naming conflicts",
	Long: `Check for naming conflicts between marketplaces and plugins.

Detects:
- Plugins installed from multiple marketplaces (same name, different sources)
- Marketplace aliases that match installed plugin names`,
	RunE: runCheckConflicts,
}

func init() {
	rootCmd.AddCommand(checkConflictsCmd)
}

func runCheckConflicts(cmd *cobra.Command, args []string) error {
	output.Info("=== Checking for Naming Conflicts ===")
	fmt.Println()

	installed, err := plugin.LoadInstalled()
	if err != nil {
		return fmt.Errorf("loading installed plugins: %w", err)
	}

	conflictsFound := 0

	// Check 1: Plugins installed in multiple marketplaces
	output.Info("Plugins in multiple marketplaces:")

	// Build a map of plugin name -> list of full IDs
	pluginsByName := make(map[string][]string)
	for _, id := range installed.All() {
		parsed, err := plugin.ParsePluginID(id)
		if err != nil {
			continue
		}
		pluginsByName[parsed.Name] = append(pluginsByName[parsed.Name], id)
	}

	// Find duplicates
	var duplicates []string
	for name, ids := range pluginsByName {
		if len(ids) > 1 {
			duplicates = append(duplicates, name)
		}
	}
	sort.Strings(duplicates)

	if len(duplicates) > 0 {
		for _, name := range duplicates {
			conflictsFound++
			fmt.Printf("  %s %s:\n", output.Yellow("⚠"), name)
			sort.Strings(pluginsByName[name])
			for _, id := range pluginsByName[name] {
				fmt.Printf("      - %s\n", id)
			}
		}
	} else {
		fmt.Printf("  %s None found\n", output.Green("✓"))
	}

	fmt.Println()

	// Check 2: Marketplace aliases matching plugin names
	output.Info("Marketplace aliases matching plugin names:")

	aliasConflicts := 0
	repos := cfg.Repos()
	sort.Strings(repos)

	for _, repo := range repos {
		alias := cfg.GetAlias(repo)

		// Check if any plugin name starts with this alias
		var matching []string
		for id := range installed.Plugins {
			parsed, err := plugin.ParsePluginID(id)
			if err != nil {
				continue
			}
			if strings.EqualFold(parsed.Name, alias) {
				matching = append(matching, id)
			}
		}

		if len(matching) > 0 {
			aliasConflicts++
			conflictsFound++
			fmt.Printf("  %s Marketplace alias '%s' conflicts with:\n", output.Yellow("⚠"), alias)
			sort.Strings(matching)
			for _, id := range matching {
				fmt.Printf("      - %s\n", id)
			}
		}
	}

	if aliasConflicts == 0 {
		fmt.Printf("  %s None found\n", output.Green("✓"))
	}

	fmt.Println()
	output.Info("=== Summary ===")
	if conflictsFound == 0 {
		output.Success("No conflicts detected.")
		return nil
	}

	output.Warning("%d conflict(s) found.", conflictsFound)
	fmt.Println("Use explicit 'plugin@marketplace' format to avoid ambiguity.")
	return fmt.Errorf("%d conflict(s) found", conflictsFound)
}
