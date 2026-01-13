package plugin

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/plinde/claude-utils/ccpm/internal/config"
)

// InstalledPlugins represents the installed_plugins.json structure
type InstalledPlugins struct {
	Version int                        `json:"version"`
	Plugins map[string][]PluginInstall `json:"plugins"`
}

// PluginInstall represents a single plugin installation
type PluginInstall struct {
	Scope        string    `json:"scope"`
	InstallPath  string    `json:"installPath"`
	Version      string    `json:"version"`
	InstalledAt  time.Time `json:"installedAt"`
	LastUpdated  time.Time `json:"lastUpdated"`
	GitCommitSha string    `json:"gitCommitSha"`
	IsLocal      bool      `json:"isLocal"`
}

// PluginID represents a parsed plugin identifier (name@marketplace)
type PluginID struct {
	Name        string
	Marketplace string
	Full        string
}

// ParsePluginID parses a plugin identifier like "name@marketplace"
func ParsePluginID(id string) (PluginID, error) {
	parts := strings.SplitN(id, "@", 2)
	if len(parts) != 2 {
		return PluginID{}, fmt.Errorf("invalid plugin ID format: %s (expected name@marketplace)", id)
	}
	return PluginID{
		Name:        parts[0],
		Marketplace: parts[1],
		Full:        id,
	}, nil
}

// LoadInstalled reads the installed_plugins.json file
func LoadInstalled() (*InstalledPlugins, error) {
	path := config.InstalledPluginsPath()

	data, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			// File doesn't exist, return empty structure
			return &InstalledPlugins{
				Version: 2,
				Plugins: make(map[string][]PluginInstall),
			}, nil
		}
		return nil, fmt.Errorf("reading installed plugins: %w", err)
	}

	var installed InstalledPlugins
	if err := json.Unmarshal(data, &installed); err != nil {
		return nil, fmt.Errorf("parsing installed plugins: %w", err)
	}

	if installed.Plugins == nil {
		installed.Plugins = make(map[string][]PluginInstall)
	}

	return &installed, nil
}

// GetPlugin returns the installation info for a specific plugin
func (ip *InstalledPlugins) GetPlugin(id string) (PluginInstall, bool) {
	installs, exists := ip.Plugins[id]
	if !exists || len(installs) == 0 {
		return PluginInstall{}, false
	}
	// Return the first (most recent) installation
	return installs[0], true
}

// Count returns the total number of installed plugins
func (ip *InstalledPlugins) Count() int {
	return len(ip.Plugins)
}

// ByMarketplace returns plugins grouped by marketplace alias
func (ip *InstalledPlugins) ByMarketplace() map[string][]string {
	result := make(map[string][]string)
	for id := range ip.Plugins {
		parsed, err := ParsePluginID(id)
		if err != nil {
			continue
		}
		result[parsed.Marketplace] = append(result[parsed.Marketplace], parsed.Name)
	}
	return result
}

// PluginsForMarketplace returns all plugins for a specific marketplace
func (ip *InstalledPlugins) PluginsForMarketplace(marketplace string) []string {
	var plugins []string
	for id := range ip.Plugins {
		parsed, err := ParsePluginID(id)
		if err != nil {
			continue
		}
		if parsed.Marketplace == marketplace {
			plugins = append(plugins, parsed.Name)
		}
	}
	return plugins
}

// All returns all plugin IDs
func (ip *InstalledPlugins) All() []string {
	ids := make([]string, 0, len(ip.Plugins))
	for id := range ip.Plugins {
		ids = append(ids, id)
	}
	return ids
}

// MatchingPattern returns plugin IDs matching a regex pattern
func (ip *InstalledPlugins) MatchingPattern(pattern string) ([]string, error) {
	// Simple substring match for now (can enhance to regex later)
	var matches []string
	for id := range ip.Plugins {
		if strings.Contains(id, pattern) {
			matches = append(matches, id)
		}
	}
	return matches, nil
}
