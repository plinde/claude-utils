package cli

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/claude"
	"github.com/plinde/claude-utils/ccpm/internal/config"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/spf13/cobra"
)

var updateCmd = &cobra.Command{
	Use:   "update [org/repo...]",
	Short: "Fetch latest marketplace catalogs",
	Long: `Fetch the latest marketplace catalogs and show available upgrades.

If no repos are specified, updates all configured marketplaces.

Example:
  ccpm update                     # Update all marketplaces
  ccpm update plinde/claude-plugins  # Update specific marketplace`,
	RunE: runUpdate,
}

func init() {
	rootCmd.AddCommand(updateCmd)
}

func runUpdate(cmd *cobra.Command, args []string) error {
	aliases, err := getTargetAliases(args)
	if err != nil {
		return err
	}

	output.Info("=== Fetching marketplace updates ===")
	fmt.Println()

	totalAvailable := 0
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

		// Update the marketplace
		if err := claude.MarketplaceUpdate(alias); err != nil {
			fmt.Printf("%s\n", output.Red("failed"))
			continue
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
			fmt.Printf("%s\n", output.Dim("updated (no plugin changes)"))
			continue
		}

		fmt.Printf("%s\n", output.Green(fmt.Sprintf("%d plugin(s) can be upgraded", len(changed))))
		totalAvailable += len(changed)

		// List changed plugins
		for _, pluginName := range changed {
			fmt.Printf("    %s\n", output.Dim(pluginName))
		}
	}

	fmt.Println()
	if totalAvailable == 0 {
		fmt.Printf("%s\n", output.Dim("All plugins up to date."))
	} else {
		output.Warning("%d plugin(s) can be upgraded. Run 'ccpm upgrade' to install.", totalAvailable)
	}

	return nil
}

// getTargetAliases resolves org/repo args to aliases, or returns all if no args
func getTargetAliases(repos []string) ([]string, error) {
	if len(repos) > 0 {
		var aliases []string
		for _, repo := range repos {
			alias := cfg.GetAlias(repo)
			if alias == "" {
				return nil, fmt.Errorf("unknown marketplace '%s'\nRun 'ccpm discover' or add it with: ccpm add %s <alias>", repo, repo)
			}
			aliases = append(aliases, alias)
		}
		return aliases, nil
	}

	// No specific repos, use all configured
	configuredRepos := cfg.Repos()
	if len(configuredRepos) == 0 {
		return nil, fmt.Errorf("no marketplaces configured\nRun 'ccpm discover' to import installed marketplaces\nOr add one with: ccpm add <org/repo> <alias>")
	}

	var aliases []string
	for _, repo := range configuredRepos {
		alias := cfg.GetAlias(repo)
		if alias != "" {
			aliases = append(aliases, alias)
		}
	}
	sort.Strings(aliases)
	return aliases, nil
}

// getGitHash returns the current HEAD commit hash for a directory
func getGitHash(dir string) string {
	cmd := exec.Command("git", "-C", dir, "rev-parse", "HEAD")
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

// getChangedPlugins returns plugin directories that changed between two commits
func getChangedPlugins(mpDir, oldHash, newHash string) []string {
	cmd := exec.Command("git", "-C", mpDir, "diff", "--name-only", oldHash, newHash)
	out, err := cmd.Output()
	if err != nil {
		return nil
	}

	// Extract unique top-level directories
	dirs := make(map[string]bool)
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, "/", 2)
		if len(parts) > 0 {
			dirs[parts[0]] = true
		}
	}

	// Filter to only plugin directories
	var plugins []string
	for dir := range dirs {
		pluginDir := filepath.Join(mpDir, dir, ".claude-plugin")
		if _, err := os.Stat(pluginDir); err == nil {
			plugins = append(plugins, dir)
		}
	}

	sort.Strings(plugins)
	return plugins
}
