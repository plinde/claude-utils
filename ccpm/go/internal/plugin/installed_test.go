package plugin

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParsePluginID(t *testing.T) {
	tests := []struct {
		input       string
		wantName    string
		wantMP      string
		shouldError bool
	}{
		{"trivy@plinde-plugins", "trivy", "plinde-plugins", false},
		{"snyk@elastic-psec-plugins", "snyk", "elastic-psec-plugins", false},
		{"plugin-with-dashes@mp-with-dashes", "plugin-with-dashes", "mp-with-dashes", false},
		{"no-at-sign", "", "", true},
		{"", "", "", true},
	}

	for _, tt := range tests {
		parsed, err := ParsePluginID(tt.input)
		if tt.shouldError {
			if err == nil {
				t.Errorf("ParsePluginID(%q) expected error, got nil", tt.input)
			}
			continue
		}
		if err != nil {
			t.Errorf("ParsePluginID(%q) unexpected error: %v", tt.input, err)
			continue
		}
		if parsed.Name != tt.wantName {
			t.Errorf("ParsePluginID(%q).Name = %q, want %q", tt.input, parsed.Name, tt.wantName)
		}
		if parsed.Marketplace != tt.wantMP {
			t.Errorf("ParsePluginID(%q).Marketplace = %q, want %q", tt.input, parsed.Marketplace, tt.wantMP)
		}
	}
}

func TestLoadInstalledNonExistent(t *testing.T) {
	// Temporarily override the path
	origHome := os.Getenv("HOME")
	tmpDir := t.TempDir()
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", origHome)

	installed, err := LoadInstalled()
	if err != nil {
		t.Fatalf("LoadInstalled failed: %v", err)
	}
	if installed == nil {
		t.Fatal("expected non-nil InstalledPlugins")
	}
	if installed.Count() != 0 {
		t.Errorf("expected 0 plugins, got %d", installed.Count())
	}
}

func TestLoadInstalledValid(t *testing.T) {
	tmpDir := t.TempDir()
	pluginsDir := filepath.Join(tmpDir, ".claude", "plugins")
	if err := os.MkdirAll(pluginsDir, 0755); err != nil {
		t.Fatal(err)
	}

	jsonContent := `{
		"version": 2,
		"plugins": {
			"trivy@plinde-plugins": [{
				"scope": "user",
				"version": "1.0.0",
				"gitCommitSha": "abc1234"
			}],
			"snyk@elastic-psec-plugins": [{
				"scope": "user",
				"version": "2.0.0",
				"gitCommitSha": "def5678"
			}]
		}
	}`

	if err := os.WriteFile(filepath.Join(pluginsDir, "installed_plugins.json"), []byte(jsonContent), 0644); err != nil {
		t.Fatal(err)
	}

	origHome := os.Getenv("HOME")
	os.Setenv("HOME", tmpDir)
	defer os.Setenv("HOME", origHome)

	installed, err := LoadInstalled()
	if err != nil {
		t.Fatalf("LoadInstalled failed: %v", err)
	}

	if installed.Count() != 2 {
		t.Errorf("expected 2 plugins, got %d", installed.Count())
	}

	// Test GetPlugin
	info, ok := installed.GetPlugin("trivy@plinde-plugins")
	if !ok {
		t.Error("GetPlugin failed for trivy@plinde-plugins")
	}
	if info.Version != "1.0.0" {
		t.Errorf("expected version 1.0.0, got %s", info.Version)
	}

	// Test PluginsForMarketplace
	plugins := installed.PluginsForMarketplace("plinde-plugins")
	if len(plugins) != 1 || plugins[0] != "trivy" {
		t.Errorf("PluginsForMarketplace failed: %v", plugins)
	}

	// Test ByMarketplace
	byMP := installed.ByMarketplace()
	if len(byMP) != 2 {
		t.Errorf("expected 2 marketplaces, got %d", len(byMP))
	}
}

func TestInstalledPluginsAll(t *testing.T) {
	ip := &InstalledPlugins{
		Plugins: map[string][]PluginInstall{
			"a@mp1": {},
			"b@mp2": {},
			"c@mp1": {},
		},
	}

	all := ip.All()
	if len(all) != 3 {
		t.Errorf("expected 3 plugins, got %d", len(all))
	}
}
