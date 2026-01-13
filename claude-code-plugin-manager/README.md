# ccpm - Claude Code Plugin Manager

A wrapper around `claude plugin` commands for managing multiple marketplaces. You can stop using ccpm anytime and continue using the native Claude Code plugin ecosystem directly.

## Features

- **Discover** - Auto-import marketplaces already installed via `claude plugin marketplace add`
- **Update/Upgrade** - Batch update catalogs and reinstall changed plugins
- **Search** - Find plugins across all installed marketplaces
- **Conflict Detection** - Warn about ambiguous plugin names across marketplaces
- **Manage** - Add/remove marketplace mappings in a central config

## Usage

```
ccpm discover                              # Import installed marketplaces
ccpm update [org/repo]                     # Fetch latest catalogs (like apt update)
ccpm upgrade [org/repo] [--dry-run]        # Update + reinstall changed plugins (like apt upgrade)
ccpm search <query> [-v]                   # Search for plugins
ccpm reinstall <plugin@mp> [--dry-run]     # Reinstall specific plugin(s)
ccpm uninstall <plugin@mp>                 # Uninstall specific plugin(s)
ccpm add <org/repo> <alias>                # Add marketplace mapping
ccpm remove <org/repo>                     # Remove marketplace mapping
ccpm list [alias]                          # List marketplaces (optionally filter by alias)
ccpm list --plugins <pattern>              # List installed plugins matching pattern
ccpm check-conflicts                       # Check for naming conflicts
ccpm config                                # Show config file path
```

## Quick Start

```bash
# 1. Discover marketplaces you've already installed
ccpm discover

# 2. See what's configured
ccpm list

# 3. Check for updates
ccpm update

# 4. Install updates
ccpm upgrade
```

## Configuration

Default config location: `~/.config/ccpm.yaml`

```yaml
# ccpm - Claude Code Plugin Manager configuration
# Format: repo: alias
marketplaces:
  anthropics/skills: anthropic-skills
  plinde/claude-plugins: plinde-plugins
```

## Commands

### discover

Scans `~/.claude/plugins/marketplaces/` for installed marketplaces and imports them into the config.

```bash
ccpm discover
```

### update

Fetches latest plugin catalogs from configured marketplaces (like `apt update`). Shows which plugins have available updates.

```bash
ccpm update                      # Update all
ccpm update anthropics/skills    # Update specific
```

### upgrade

Fetches updates AND reinstalls any changed plugins (like `apt upgrade`).

```bash
ccpm upgrade                     # Upgrade all
ccpm upgrade --dry-run           # Preview changes
```

### search

Search for plugins by name or description across all marketplaces:

```bash
ccpm search trivy                # Find plugins matching "trivy"
ccpm search security -v          # Verbose output with descriptions
```

### reinstall / uninstall

Manage specific plugins. Supports both explicit format (`plugin@marketplace`) and auto-detection:

```bash
ccpm reinstall trivy@plinde-plugins     # Explicit
ccpm reinstall trivy                    # Auto-detect (warns if ambiguous)
ccpm uninstall snyk@elastic-psec-plugins
```

**Note**: If a plugin exists in multiple marketplaces, you must use the explicit format.

### list

Show configured marketplaces and their installed plugins:

```bash
ccpm list                        # List all marketplaces
ccpm list plinde-plugins         # Filter to specific marketplace
ccpm list --plugins trivy        # List installed plugins matching pattern
```

### check-conflicts

Detect naming conflicts that could cause ambiguous behavior:

```bash
ccpm check-conflicts
```

Checks for:
- Plugins installed in multiple marketplaces
- Marketplace aliases matching plugin names

### add / remove

Manually manage marketplace mappings:

```bash
ccpm add anthropics/skills anthropic-skills
ccpm remove anthropics/skills
```

### config

Show config file location and contents:

```bash
ccpm config
ccpm --config /path/to/config.yaml config
```

## Options

| Option | Description |
|--------|-------------|
| `--config <path>` | Use alternate config file |
| `--dry-run` | Show what would happen without making changes |
| `-v, --verbose` | Show additional details (for search) |

## How It Works

1. **discover** reads git remote URLs from installed marketplace directories to determine the org/repo
2. **update/upgrade** uses the Claude Code CLI (`claude plugin marketplace update`, `claude plugin install/uninstall`)
3. Config maps GitHub repos (e.g., `anthropics/skills`) to local aliases (e.g., `anthropic-skills`)

## Conflict Detection

ccpm warns about ambiguous situations:

1. **Multi-marketplace plugins**: If `trivy` is installed from both `plinde-plugins` and `elastic-psec-plugins`, running `ccpm uninstall trivy` will error and require explicit format
2. **Alias/plugin collisions**: Adding a marketplace alias that matches an existing plugin name triggers a warning

Run `ccpm check-conflicts` to audit your setup.

## Dependencies

- `claude` - Claude Code CLI
- `git` - For discovering marketplace origins
- `jq` - For JSON parsing
- Bash 4.0+
