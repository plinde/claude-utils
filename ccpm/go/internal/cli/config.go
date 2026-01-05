package cli

import (
	"fmt"
	"os"

	"github.com/plinde/claude-utils/ccpm/internal/config"
	"github.com/plinde/claude-utils/ccpm/internal/output"
	"github.com/spf13/cobra"
)

var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Show config file path and contents",
	Long:  `Display the current configuration file path and its contents.`,
	RunE:  runConfig,
}

func init() {
	rootCmd.AddCommand(configCmd)
}

func runConfig(cmd *cobra.Command, args []string) error {
	configPath := config.DefaultConfigPath()
	if cfgFile != "" {
		configPath = cfgFile
	}

	output.Label("Config file", configPath)

	if cfgFile != "" && cfgFile != config.DefaultConfigPath() {
		output.Warning("(overridden from default: %s)", config.DefaultConfigPath())
	}

	fmt.Println()

	// Check if file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		output.StatusLabel("Status", "not created yet (will be created on first 'add' or 'discover')", false)
		return nil
	}

	output.StatusLabel("Status", "exists", true)

	// Read and display contents
	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("reading config: %w", err)
	}

	output.Label("Contents", "")
	fmt.Print(string(data))

	return nil
}
