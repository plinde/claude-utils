# claude-resume

Resume a Claude Code session by ID.

Finds the session, changes to its project directory, and resumes.

## Usage

```
claude-resume <session-id>
```

Accepts full or partial session IDs (matches from start).

## Examples

```bash
# Full session ID
claude-resume 60215d77-6ac3-4cf8-9a55-18c67aaca6bd

# Partial ID (must be unique)
claude-resume 60215d77
claude-resume 602

# Typical workflow with claude-sessions
claude-sessions -g docker
#=> Dec 15 14:22  89.4K  /Users/jane/workspace/github.com/acme/webapp
#=>              └─ Configure Docker multi-stage build
#=>                 a1b2c3d4-e5f6-7890-abcd-ef1234567890

claude-resume a1b2c3d4
```

## Dependencies

- `jq` - JSON parsing
- `claude` - Claude Code CLI
