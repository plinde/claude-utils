package marketplace

import (
	"testing"
)

func TestGetRepoFromRemote(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		// SSH format
		{"git@github.com:plinde/claude-plugins.git", "plinde/claude-plugins"},
		{"git@github.com:elastic/platform-security-claude-plugins.git", "elastic/platform-security-claude-plugins"},
		{"git@github.com:org/repo", "org/repo"},

		// HTTPS format
		{"https://github.com/plinde/claude-plugins.git", "plinde/claude-plugins"},
		{"https://github.com/plinde/claude-plugins", "plinde/claude-plugins"},
		{"https://github.com/elastic/cloud.git", "elastic/cloud"},

		// Invalid
		{"not-a-url", ""},
		{"https://gitlab.com/org/repo", ""},
	}

	for _, tt := range tests {
		got := GetRepoFromRemote(tt.input)
		if got != tt.expected {
			t.Errorf("GetRepoFromRemote(%q) = %q, want %q", tt.input, got, tt.expected)
		}
	}
}

func TestMarketplaceGetPlugin(t *testing.T) {
	mp := &Marketplace{
		Plugins: []PluginMetadata{
			{Name: "trivy", Version: "1.0.0", Description: "Scanner"},
			{Name: "snyk", Version: "2.0.0", Description: "Security"},
		},
	}

	// Found
	p, ok := mp.GetPlugin("trivy")
	if !ok {
		t.Error("GetPlugin failed for trivy")
	}
	if p.Version != "1.0.0" {
		t.Errorf("expected version 1.0.0, got %s", p.Version)
	}

	// Not found
	_, ok = mp.GetPlugin("nonexistent")
	if ok {
		t.Error("GetPlugin should return false for nonexistent")
	}
}

func TestMarketplacePluginNames(t *testing.T) {
	mp := &Marketplace{
		Plugins: []PluginMetadata{
			{Name: "a"},
			{Name: "b"},
			{Name: "c"},
		},
	}

	names := mp.PluginNames()
	if len(names) != 3 {
		t.Errorf("expected 3 names, got %d", len(names))
	}
}
