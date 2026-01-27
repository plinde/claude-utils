package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadNonExistent(t *testing.T) {
	cfg, err := Load("/nonexistent/path/config.yaml")
	if err != nil {
		t.Fatalf("expected no error for nonexistent config, got: %v", err)
	}
	if cfg == nil {
		t.Fatal("expected non-nil config")
	}
	if len(cfg.Marketplaces) != 0 {
		t.Errorf("expected empty marketplaces, got %d", len(cfg.Marketplaces))
	}
}

func TestLoadAndSave(t *testing.T) {
	tmpDir := t.TempDir()
	cfgPath := filepath.Join(tmpDir, "test-config.yaml")

	// Load (creates empty)
	cfg, err := Load(cfgPath)
	if err != nil {
		t.Fatalf("Load failed: %v", err)
	}

	// Add marketplace
	cfg.AddMarketplace("test/repo", "test-alias")

	// Save
	if err := cfg.Save(); err != nil {
		t.Fatalf("Save failed: %v", err)
	}

	// Verify file exists
	if _, err := os.Stat(cfgPath); err != nil {
		t.Fatalf("config file not created: %v", err)
	}

	// Reload and verify
	cfg2, err := Load(cfgPath)
	if err != nil {
		t.Fatalf("Reload failed: %v", err)
	}

	if cfg2.GetAlias("test/repo") != "test-alias" {
		t.Errorf("expected alias 'test-alias', got '%s'", cfg2.GetAlias("test/repo"))
	}
}

func TestGetAlias(t *testing.T) {
	cfg := &Config{
		Marketplaces: map[string]string{
			"org/repo1": "alias1",
			"org/repo2": "alias2",
		},
	}

	tests := []struct {
		repo     string
		expected string
	}{
		{"org/repo1", "alias1"},
		{"org/repo2", "alias2"},
		{"org/nonexistent", ""},
	}

	for _, tt := range tests {
		got := cfg.GetAlias(tt.repo)
		if got != tt.expected {
			t.Errorf("GetAlias(%q) = %q, want %q", tt.repo, got, tt.expected)
		}
	}
}

func TestGetRepo(t *testing.T) {
	cfg := &Config{
		Marketplaces: map[string]string{
			"org/repo1": "alias1",
			"org/repo2": "alias2",
		},
	}

	tests := []struct {
		alias    string
		expected string
	}{
		{"alias1", "org/repo1"},
		{"alias2", "org/repo2"},
		{"nonexistent", ""},
	}

	for _, tt := range tests {
		got := cfg.GetRepo(tt.alias)
		if got != tt.expected {
			t.Errorf("GetRepo(%q) = %q, want %q", tt.alias, got, tt.expected)
		}
	}
}

func TestAddRemoveMarketplace(t *testing.T) {
	cfg := &Config{
		Marketplaces: make(map[string]string),
	}

	// Add
	cfg.AddMarketplace("org/repo", "alias")
	if cfg.GetAlias("org/repo") != "alias" {
		t.Error("AddMarketplace failed")
	}

	// Remove
	if !cfg.RemoveMarketplace("org/repo") {
		t.Error("RemoveMarketplace returned false")
	}
	if cfg.GetAlias("org/repo") != "" {
		t.Error("RemoveMarketplace didn't remove")
	}

	// Remove nonexistent
	if cfg.RemoveMarketplace("org/nonexistent") {
		t.Error("RemoveMarketplace should return false for nonexistent")
	}
}

func TestRepos(t *testing.T) {
	cfg := &Config{
		Marketplaces: map[string]string{
			"org/repo1": "alias1",
			"org/repo2": "alias2",
		},
	}

	repos := cfg.Repos()
	if len(repos) != 2 {
		t.Errorf("expected 2 repos, got %d", len(repos))
	}
}
