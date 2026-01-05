package claude

import (
	"bytes"
	"fmt"
	"os/exec"
)

// Result holds the result of a Claude CLI command
type Result struct {
	Stdout   string
	Stderr   string
	ExitCode int
}

// Run executes a claude CLI command and returns the result
func Run(args ...string) (*Result, error) {
	cmd := exec.Command("claude", args...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()

	result := &Result{
		Stdout: stdout.String(),
		Stderr: stderr.String(),
	}

	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			result.ExitCode = exitErr.ExitCode()
		} else {
			return nil, fmt.Errorf("executing claude: %w", err)
		}
	}

	return result, nil
}

// RunSilent executes a claude CLI command silently (discards output)
func RunSilent(args ...string) error {
	cmd := exec.Command("claude", args...)
	return cmd.Run()
}

// MarketplaceUpdate updates a marketplace catalog
func MarketplaceUpdate(alias string) error {
	return RunSilent("plugin", "marketplace", "update", alias)
}

// PluginInstall installs a plugin
func PluginInstall(pluginID string) error {
	return RunSilent("plugin", "install", pluginID)
}

// PluginUninstall uninstalls a plugin
func PluginUninstall(pluginID string) error {
	return RunSilent("plugin", "uninstall", pluginID)
}

// PluginReinstall uninstalls then installs a plugin
func PluginReinstall(pluginID string) error {
	// Uninstall first (ignore errors - plugin might not be installed)
	_ = PluginUninstall(pluginID)
	return PluginInstall(pluginID)
}
