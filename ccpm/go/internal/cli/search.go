package cli

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/config"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/plinde/claude-utils/ccpm/internal/plugin"
	"github.com/spf13/cobra"
)

var searchCmd = &cobra.Command{
	Use:   "search <query>",
	Short: "Search plugins in local marketplace repos",
	Long: `Search for plugins across all local marketplace repositories.

Searches plugin names and descriptions (case-insensitive).
Use -v/--verbose to show plugin descriptions in results.`,
	Args: cobra.ExactArgs(1),
	RunE: runSearch,
}

func init() {
	rootCmd.AddCommand(searchCmd)
}

// pluginJSON represents the plugin.json structure
type pluginJSON struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Version     string `json:"version"`
}

func runSearch(cmd *cobra.Command, args []string) error {
	query := args[0]

	output.Info("=== Searching for '%s' ===", query)
	fmt.Println()

	// Load installed plugins to mark installed ones
	installed, _ := plugin.LoadInstalled()

	pluginsDir := config.PluginsDir()
	entries, err := os.ReadDir(pluginsDir)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Println("No marketplaces found.")
			return nil
		}
		return fmt.Errorf("reading plugins directory: %w", err)
	}

	type searchResult struct {
		name        string
		marketplace string
		version     string
		description string
		installed   bool
	}

	var results []searchResult
	queryLower := strings.ToLower(query)

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		marketplaceAlias := entry.Name()
		mpDir := filepath.Join(pluginsDir, marketplaceAlias)

		// Iterate plugin directories
		pluginEntries, err := os.ReadDir(mpDir)
		if err != nil {
			continue
		}

		for _, pEntry := range pluginEntries {
			if !pEntry.IsDir() {
				continue
			}
			pluginName := pEntry.Name()

			// Skip hidden and .claude-plugin directories
			if strings.HasPrefix(pluginName, ".") {
				continue
			}

			pluginDir := filepath.Join(mpDir, pluginName)
			pluginJSONPath := filepath.Join(pluginDir, ".claude-plugin", "plugin.json")

			// Check if this is a valid plugin
			if _, err := os.Stat(pluginJSONPath); err != nil {
				continue
			}

			// Read plugin.json
			var pj pluginJSON
			if data, err := os.ReadFile(pluginJSONPath); err == nil {
				_ = json.Unmarshal(data, &pj)
			}

			// Match against name or description
			matched := false
			if strings.Contains(strings.ToLower(pluginName), queryLower) {
				matched = true
			} else if strings.Contains(strings.ToLower(pj.Description), queryLower) {
				matched = true
			}

			if matched {
				pluginID := fmt.Sprintf("%s@%s", pluginName, marketplaceAlias)
				_, isInstalled := installed.GetPlugin(pluginID)

				results = append(results, searchResult{
					name:        pluginName,
					marketplace: marketplaceAlias,
					version:     pj.Version,
					description: pj.Description,
					installed:   isInstalled,
				})
			}
		}
	}

	// Sort results by name
	sort.Slice(results, func(i, j int) bool {
		return results[i].name < results[j].name
	})

	if len(results) == 0 {
		fmt.Println("No plugins found matching your query.")
		return nil
	}

	for _, r := range results {
		installedMarker := ""
		if r.installed {
			installedMarker = " " + output.Green("[installed]")
		}

		versionStr := ""
		if r.version != "" {
			versionStr = " " + output.Dim("v"+r.version)
		}

		fmt.Printf("  %s@%s%s%s\n", output.Blue(r.name), r.marketplace, versionStr, installedMarker)

		if verbose && r.description != "" {
			fmt.Printf("    %s\n", output.Dim(r.description))
		}
	}

	fmt.Println()
	fmt.Printf("Found %s plugin(s)\n", output.Green(fmt.Sprintf("%d", len(results))))

	return nil
}
