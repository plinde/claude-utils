package marketplace

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/plinde/claude-utils/ccpm/internal/config"
)

// Marketplace represents a marketplace catalog
type Marketplace struct {
	Name     string           `json:"name"`
	Owner    Owner            `json:"owner"`
	Metadata MarketplaceMeta  `json:"metadata"`
	Plugins  []PluginMetadata `json:"plugins"`

	// Internal fields (not serialized)
	path string // Directory path
	repo string // org/name
}

// Owner represents the marketplace owner
type Owner struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

// MarketplaceMeta represents marketplace metadata
type MarketplaceMeta struct {
	Description string `json:"description"`
	Version     string `json:"version"`
	Homepage    string `json:"homepage"`
	Repository  string `json:"repository"`
}

// PluginMetadata represents plugin info in the marketplace catalog
type PluginMetadata struct {
	Name        string   `json:"name"`
	Source      string   `json:"source"`
	Description string   `json:"description"`
	Version     string   `json:"version"`
	Author      Owner    `json:"author"`
	Homepage    string   `json:"homepage"`
	Repository  string   `json:"repository"`
	License     string   `json:"license"`
	Keywords    []string `json:"keywords"`
	Category    string   `json:"category"`
	Tags        []string `json:"tags"`
}

// LoadMarketplace loads a marketplace from its directory
func LoadMarketplace(path string) (*Marketplace, error) {
	marketplaceFile := filepath.Join(path, ".claude-plugin", "marketplace.json")

	data, err := os.ReadFile(marketplaceFile)
	if err != nil {
		return nil, fmt.Errorf("reading marketplace.json: %w", err)
	}

	var mp Marketplace
	if err := json.Unmarshal(data, &mp); err != nil {
		return nil, fmt.Errorf("parsing marketplace.json: %w", err)
	}

	mp.path = path
	return &mp, nil
}

// Path returns the marketplace directory path
func (m *Marketplace) Path() string {
	return m.path
}

// Repo returns the org/name identifier
func (m *Marketplace) Repo() string {
	return m.repo
}

// SetRepo sets the org/name identifier
func (m *Marketplace) SetRepo(repo string) {
	m.repo = repo
}

// GetPlugin returns plugin metadata by name
func (m *Marketplace) GetPlugin(name string) (PluginMetadata, bool) {
	for _, p := range m.Plugins {
		if p.Name == name {
			return p, true
		}
	}
	return PluginMetadata{}, false
}

// PluginNames returns all plugin names in this marketplace
func (m *Marketplace) PluginNames() []string {
	names := make([]string, len(m.Plugins))
	for i, p := range m.Plugins {
		names[i] = p.Name
	}
	return names
}

// DiscoverMarketplaces finds all marketplace directories in the plugins dir
func DiscoverMarketplaces() ([]string, error) {
	pluginsDir := config.PluginsDir()

	entries, err := os.ReadDir(pluginsDir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("reading plugins directory: %w", err)
	}

	var marketplaces []string
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		// Check if it has a .claude-plugin/marketplace.json
		mpFile := filepath.Join(pluginsDir, entry.Name(), ".claude-plugin", "marketplace.json")
		if _, err := os.Stat(mpFile); err == nil {
			marketplaces = append(marketplaces, entry.Name())
		}
	}

	return marketplaces, nil
}

// GetRepoFromRemote extracts org/repo from git remote URL
func GetRepoFromRemote(remoteURL string) string {
	// Handle various formats:
	// git@github.com:org/repo.git
	// https://github.com/org/repo.git
	// https://github.com/org/repo

	url := strings.TrimSuffix(remoteURL, ".git")

	// SSH format
	if strings.HasPrefix(url, "git@github.com:") {
		return strings.TrimPrefix(url, "git@github.com:")
	}

	// HTTPS format
	if strings.Contains(url, "github.com/") {
		parts := strings.SplitN(url, "github.com/", 2)
		if len(parts) == 2 {
			return parts[1]
		}
	}

	return ""
}

// LoadAll loads all marketplaces for the given repos
func LoadAll(cfg *config.Config) (map[string]*Marketplace, error) {
	result := make(map[string]*Marketplace)
	pluginsDir := config.PluginsDir()

	for repo, alias := range cfg.Marketplaces {
		path := filepath.Join(pluginsDir, alias)
		mp, err := LoadMarketplace(path)
		if err != nil {
			// Skip marketplaces that can't be loaded
			continue
		}
		mp.repo = repo
		result[alias] = mp
	}

	return result, nil
}
