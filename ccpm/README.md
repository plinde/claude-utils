# ccpm - Claude Code Plugin Manager

A wrapper around `claude plugin` commands for managing multiple marketplaces. You can stop using ccpm anytime and continue using the native Claude Code plugin ecosystem directly.

## Features

- **Discover** - Auto-import marketplaces already installed via `claude plugin marketplace add`
- **Update** - Batch update all plugins from configured marketplaces
- **Manage** - Add/remove marketplace mappings in a central config

## Usage

```
ccpm discover                              # Import installed marketplaces
ccpm update [org/repo] [--dry-run]        # Update plugins from marketplace(s)
ccpm add <org/repo> <alias>               # Add marketplace mapping
ccpm remove <org/repo>                    # Remove marketplace mapping
ccpm list                                 # List configured marketplaces
ccpm config                               # Show config file path
```

## Quick Start

```bash
# 1. Discover marketplaces you've already installed
ccpm discover

# 2. See what's configured
ccpm list

# 3. Update all plugins
ccpm update
```

## Configuration

Default config location: `~/.config/ccpm.yaml`

```yaml
# ccpm - Claude Code Plugin Manager configuration
# Format: repo: alias
marketplaces:
  anthropics/skills: anthropic-skills
```

## Commands

### discover

Scans `~/.claude/plugins/marketplaces/` for installed marketplaces and imports them into the config. This is useful when:

- You installed marketplaces before using ccpm
- You installed a marketplace via `claude plugin marketplace add` and want ccpm to manage updates

```bash
ccpm discover
```

### update

Updates plugins from configured marketplaces by:
1. Running `claude plugin marketplace update <alias>` to fetch latest
2. Reinstalling each plugin via uninstall + install

```bash
ccpm update                      # Update all
ccpm update anthropics/skills    # Update specific
ccpm update --dry-run            # Preview changes
```

### add / remove

Manually manage marketplace mappings:

```bash
ccpm add anthropics/skills anthropic-skills
ccpm remove anthropics/skills
```

### list

Show configured marketplaces with installation status:

```bash
ccpm list
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
| `--dry-run` | Show what would be updated without making changes |

## How It Works

1. **discover** reads git remote URLs from installed marketplace directories to determine the org/repo
2. **update** uses the Claude Code CLI (`claude plugin marketplace update`, `claude plugin install/uninstall`)
3. Config maps GitHub repos (e.g., `anthropics/skills`) to local aliases (e.g., `anthropic-skills`)

## Dependencies

- `claude` - Claude Code CLI
- `git` - For discovering marketplace origins
- Bash 4.0+
