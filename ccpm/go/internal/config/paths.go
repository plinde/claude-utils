package config

import (
	"os"
	"path/filepath"
)

const (
	// DefaultConfigFileName is the default config file name
	DefaultConfigFileName = "ccpm.yaml"

	// PluginsDirName is the directory containing marketplace plugins
	PluginsDirName = "plugins/marketplaces"

	// InstalledPluginsFile is the file tracking installed plugins
	InstalledPluginsFile = "plugins/installed_plugins.json"
)

// DefaultConfigDir returns the default config directory
// Uses XDG_CONFIG_HOME if set, otherwise ~/.config
func DefaultConfigDir() string {
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return xdg
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ".config"
	}
	return filepath.Join(home, ".config")
}

// DefaultConfigPath returns the default config file path
func DefaultConfigPath() string {
	return filepath.Join(DefaultConfigDir(), DefaultConfigFileName)
}

// ClaudeDir returns the Claude config directory (~/.claude)
func ClaudeDir() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ".claude"
	}
	return filepath.Join(home, ".claude")
}

// PluginsDir returns the marketplace plugins directory
func PluginsDir() string {
	return filepath.Join(ClaudeDir(), PluginsDirName)
}

// InstalledPluginsPath returns the path to installed_plugins.json
func InstalledPluginsPath() string {
	return filepath.Join(ClaudeDir(), InstalledPluginsFile)
}
