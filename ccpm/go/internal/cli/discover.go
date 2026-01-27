package cli

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/config"
	"github.com/plinde/claude-utils/ccpm/internal/marketplace"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/spf13/cobra"
)

var discoverCmd = &cobra.Command{
	Use:   "discover",
	Short: "Discover and import installed marketplaces",
	Long: `Scan the marketplaces directory and import any that are not yet in the config.

For each discovered marketplace, extracts the org/repo from git remote and adds
it to the configuration file.`,
	RunE: runDiscover,
}

func init() {
	rootCmd.AddCommand(discoverCmd)
}

func runDiscover(cmd *cobra.Command, args []string) error {
	output.Info("=== Discovering Installed Marketplaces ===")
	fmt.Println()

	pluginsDir := config.PluginsDir()
	if _, err := os.Stat(pluginsDir); os.IsNotExist(err) {
		return fmt.Errorf("no marketplaces directory found at %s", pluginsDir)
	}

	entries, err := os.ReadDir(pluginsDir)
	if err != nil {
		return fmt.Errorf("reading plugins directory: %w", err)
	}

	discovered := 0
	imported := 0

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		alias := entry.Name()
		dirPath := filepath.Join(pluginsDir, alias)
		discovered++

		// Get git remote
		remoteCmd := exec.Command("git", "-C", dirPath, "remote", "get-url", "origin")
		remoteOut, err := remoteCmd.Output()
		if err != nil {
			fmt.Printf("  %s  %s %s\n", output.Yellow("⚠"), alias, output.Dim("(no git remote, skipping)"))
			continue
		}
		remote := strings.TrimSpace(string(remoteOut))

		// Parse org/repo from remote
		repo := marketplace.GetRepoFromRemote(remote)
		if repo == "" {
			fmt.Printf("  %s  %s %s\n", output.Yellow("⚠"), alias, output.Dim(fmt.Sprintf("(could not parse repo from: %s)", remote)))
			continue
		}

		// Check if already in config
		existingAlias := cfg.GetAlias(repo)
		if existingAlias != "" {
			fmt.Printf("  %s  %s %s\n", output.Dim("✓"), alias, output.Dim(fmt.Sprintf("(%s already configured)", repo)))
			continue
		}

		// Add to config
		cfg.AddMarketplace(repo, alias)
		fmt.Printf("  %s  %s %s\n", output.Green("+"), alias, output.Dim(fmt.Sprintf("(%s)", repo)))
		imported++
	}

	// Save config if we imported anything
	if imported > 0 {
		if err := cfg.Save(); err != nil {
			return fmt.Errorf("saving config: %w", err)
		}
	}

	fmt.Println()
	fmt.Printf("Discovered %d marketplace(s), imported %s new.\n", discovered, output.Green(fmt.Sprintf("%d", imported)))

	return nil
}
