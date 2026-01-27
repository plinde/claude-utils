package cli

import (
	"github.com/plinde/claude-utils/ccpm/internal/config"
	"github.com/spf13/cobra"
)

var (
	// Global flags
	cfgFile string
	verbose bool
	dryRun  bool

	// Global config instance
	cfg *config.Config
)

var rootCmd = &cobra.Command{
	Use:   "ccpm",
	Short: "Claude Code Plugin Manager",
	Long: `ccpm - Claude Code Plugin Manager

A wrapper around 'claude plugin' commands for managing multiple marketplaces.

Configuration: ~/.config/ccpm.yaml (default)`,
	SilenceUsage:  true,
	SilenceErrors: true,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		// Skip config loading for help command
		if cmd.Name() == "help" {
			return nil
		}

		var err error
		cfg, err = config.Load(cfgFile)
		if err != nil {
			return err
		}
		return nil
	},
}

func init() {
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is ~/.config/ccpm.yaml)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
	rootCmd.PersistentFlags().BoolVar(&dryRun, "dry-run", false, "show what would be done without making changes")
}

// Execute runs the root command
func Execute() error {
	return rootCmd.Execute()
}

// GetConfig returns the loaded configuration
func GetConfig() *config.Config {
	return cfg
}

// IsVerbose returns whether verbose mode is enabled
func IsVerbose() bool {
	return verbose
}

// IsDryRun returns whether dry-run mode is enabled
func IsDryRun() bool {
	return dryRun
}
