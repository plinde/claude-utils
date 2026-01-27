package cli

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/config"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/plinde/claude-utils/ccpm/internal/plugin"
	"github.com/spf13/cobra"
)

var (
	listPluginsPattern string
)

var listCmd = &cobra.Command{
	Use:   "list [alias]",
	Short: "List marketplaces and installed plugins",
	Long: `List configured marketplaces and their installed plugins.

If an alias is provided, shows plugins for that specific marketplace.
Use --plugins <pattern> to filter installed plugins by name.`,
	RunE: runList,
}

func init() {
	listCmd.Flags().StringVar(&listPluginsPattern, "plugins", "", "list plugins matching pattern (regex)")
	rootCmd.AddCommand(listCmd)
}

func runList(cmd *cobra.Command, args []string) error {
	// Handle --plugins flag
	if listPluginsPattern != "" {
		return listPluginsByPattern(listPluginsPattern)
	}

	// Load installed plugins
	installed, err := plugin.LoadInstalled()
	if err != nil {
		return fmt.Errorf("loading installed plugins: %w", err)
	}

	// If an alias is provided, show that marketplace only
	if len(args) > 0 {
		return listMarketplace(args[0], installed)
	}

	// Show all configured marketplaces
	return listAllMarketplaces(installed)
}

func listAllMarketplaces(installed *plugin.InstalledPlugins) error {
	output.Info("Configured marketplaces:")
	fmt.Println()

	repos := cfg.Repos()
	sort.Strings(repos)

	for _, repo := range repos {
		alias := cfg.GetAlias(repo)
		printMarketplaceDetail(alias, repo, installed)
	}

	return nil
}

func listMarketplace(aliasOrRepo string, installed *plugin.InstalledPlugins) error {
	// First try as alias
	alias := aliasOrRepo
	repo := cfg.GetRepo(aliasOrRepo)

	// If not found as alias, try as repo
	if repo == "" {
		if a := cfg.GetAlias(aliasOrRepo); a != "" {
			alias = a
			repo = aliasOrRepo
		} else {
			return fmt.Errorf("marketplace not found: %s", aliasOrRepo)
		}
	}

	output.Info("Marketplace: %s", alias)
	fmt.Println()
	printMarketplaceDetail(alias, repo, installed)

	return nil
}

func printMarketplaceDetail(alias, repo string, installed *plugin.InstalledPlugins) {
	pluginsDir := config.PluginsDir()
	mpDir := filepath.Join(pluginsDir, alias)

	// Check if installed
	isInstalled := false
	if _, err := os.Stat(mpDir); err == nil {
		isInstalled = true
	}

	// Print header
	status := output.Red("not installed")
	if isInstalled {
		status = output.Green("installed")
	}
	fmt.Printf("  %s (%s) [%s]\n", output.Blue(alias), repo, status)

	// Get git info
	if isInstalled {
		gitInfo := getMarketplaceGitInfo(mpDir)
		if gitInfo != "" {
			fmt.Printf("    %s\n", output.Dim("@ "+gitInfo))
		}
	}

	// Get installed plugins for this marketplace
	plugins := installed.PluginsForMarketplace(alias)
	sort.Strings(plugins)

	if len(plugins) == 0 {
		fmt.Printf("    %s\n", output.Dim("(no plugins installed)"))
	} else {
		for _, pluginName := range plugins {
			pluginID := fmt.Sprintf("%s@%s", pluginName, alias)
			info, _ := installed.GetPlugin(pluginID)

			version := ""
			if info.Version != "" {
				version = output.Dim("v" + info.Version)
			}

			gitHash := ""
			if info.GitCommitSha != "" {
				short := info.GitCommitSha
				if len(short) > 7 {
					short = short[:7]
				}
				gitHash = output.Dim("@" + short)
			}

			fmt.Printf("    %s %s %s %s\n", output.Dim("└─"), pluginName, version, gitHash)
		}
	}

	fmt.Println()
}

func getMarketplaceGitInfo(dir string) string {
	gitDir := filepath.Join(dir, ".git")
	if _, err := os.Stat(gitDir); err != nil {
		return ""
	}

	// Get commit hash
	hashCmd := exec.Command("git", "-C", dir, "rev-parse", "--short", "HEAD")
	hashOut, err := hashCmd.Output()
	if err != nil {
		return ""
	}
	hash := strings.TrimSpace(string(hashOut))

	// Get commit time (relative)
	timeCmd := exec.Command("git", "-C", dir, "log", "-1", "--format=%cr")
	timeOut, err := timeCmd.Output()
	if err != nil {
		return hash
	}
	relTime := strings.TrimSpace(string(timeOut))

	return fmt.Sprintf("%s (%s)", hash, relTime)
}

func listPluginsByPattern(pattern string) error {
	installed, err := plugin.LoadInstalled()
	if err != nil {
		return fmt.Errorf("loading installed plugins: %w", err)
	}

	output.Info("Installed plugins matching '%s':", pattern)
	fmt.Println()

	// Compile regex pattern (case-insensitive)
	re, err := regexp.Compile("(?i)" + pattern)
	if err != nil {
		// Fall back to simple substring match
		re = nil
	}

	allPlugins := installed.All()
	sort.Strings(allPlugins)

	var matches []string
	for _, pluginID := range allPlugins {
		parsed, err := plugin.ParsePluginID(pluginID)
		if err != nil {
			continue
		}

		// Match against plugin name
		if re != nil {
			if re.MatchString(parsed.Name) {
				matches = append(matches, pluginID)
			}
		} else {
			if strings.Contains(strings.ToLower(parsed.Name), strings.ToLower(pattern)) {
				matches = append(matches, pluginID)
			}
		}
	}

	if len(matches) == 0 {
		fmt.Printf("  %s\n", output.Dim("(no plugins found)"))
		return nil
	}

	for _, pluginID := range matches {
		parsed, _ := plugin.ParsePluginID(pluginID)
		info, _ := installed.GetPlugin(pluginID)

		version := ""
		if info.Version != "" {
			version = output.Dim("v" + info.Version)
		}

		gitHash := ""
		if info.GitCommitSha != "" {
			short := info.GitCommitSha
			if len(short) > 7 {
				short = short[:7]
			}
			gitHash = output.Dim("@" + short)
		}

		fmt.Printf("  %s@%s %s %s\n", output.Blue(parsed.Name), parsed.Marketplace, version, gitHash)
	}

	fmt.Println()
	fmt.Printf("Found %s installed plugin(s) matching '%s'\n", output.Green(fmt.Sprintf("%d", len(matches))), pattern)

	return nil
}
