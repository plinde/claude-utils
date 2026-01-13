package config

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

// Config represents the ccpm configuration
type Config struct {
	// Marketplaces maps repo (org/name) to alias
	Marketplaces map[string]string `yaml:"marketplaces"`

	// path is the config file path (not serialized)
	path string
}

// Load reads the config from the specified path, or the default path if empty
func Load(path string) (*Config, error) {
	if path == "" {
		path = DefaultConfigPath()
	}

	cfg := &Config{
		Marketplaces: make(map[string]string),
		path:         path,
	}

	data, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			// Config doesn't exist yet, return empty config
			return cfg, nil
		}
		return nil, fmt.Errorf("reading config: %w", err)
	}

	if err := yaml.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("parsing config: %w", err)
	}

	// Ensure marketplaces map is not nil
	if cfg.Marketplaces == nil {
		cfg.Marketplaces = make(map[string]string)
	}

	return cfg, nil
}

// Save writes the config to disk
func (c *Config) Save() error {
	// Ensure directory exists
	dir := filepath.Dir(c.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("creating config directory: %w", err)
	}

	data, err := yaml.Marshal(c)
	if err != nil {
		return fmt.Errorf("marshaling config: %w", err)
	}

	// Add header comment
	header := []byte("# ccpm - Claude Code Plugin Manager configuration\n# Format: repo: alias\n")
	data = append(header, data...)

	if err := os.WriteFile(c.path, data, 0644); err != nil {
		return fmt.Errorf("writing config: %w", err)
	}

	return nil
}

// Path returns the config file path
func (c *Config) Path() string {
	return c.path
}

// IsDefault returns true if using the default config path
func (c *Config) IsDefault() bool {
	return c.path == DefaultConfigPath()
}

// GetAlias returns the alias for a given repo, or empty string if not found
func (c *Config) GetAlias(repo string) string {
	return c.Marketplaces[repo]
}

// GetRepo returns the repo for a given alias, or empty string if not found
func (c *Config) GetRepo(alias string) string {
	for repo, a := range c.Marketplaces {
		if a == alias {
			return repo
		}
	}
	return ""
}

// AddMarketplace adds or updates a marketplace mapping
func (c *Config) AddMarketplace(repo, alias string) {
	c.Marketplaces[repo] = alias
}

// RemoveMarketplace removes a marketplace by repo
func (c *Config) RemoveMarketplace(repo string) bool {
	if _, exists := c.Marketplaces[repo]; exists {
		delete(c.Marketplaces, repo)
		return true
	}
	return false
}

// Repos returns all configured repos
func (c *Config) Repos() []string {
	repos := make([]string, 0, len(c.Marketplaces))
	for repo := range c.Marketplaces {
		repos = append(repos, repo)
	}
	return repos
}
