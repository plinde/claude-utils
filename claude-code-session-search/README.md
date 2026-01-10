# ccss - Claude Code Session Search

Browse and search recent Claude Code sessions from `~/.claude/projects`.

## Usage

```
ccss [options] [count]
```

## Options

| Option | Description |
|--------|-------------|
| `-n COUNT` | Number of sessions to show (default: 3) |
| `-a, --all` | Include agent/subagent sessions |
| `-s, --short` | Use shortened paths (gh:, ws:, ~/) |
| `-v, --verbose` | Show extra info (refs, file path, message count) |
| `-g, --grep KEYWORD` | Search sessions for keyword (case-sensitive) |
| `-i` | Case-insensitive search (use with `-g`) |
| `-j, --json` | Output as JSON (one object per line) |
| `--here` | Only show sessions for current directory |
| `-h, --help` | Show help |

## Examples

### Default output

```
$ ccss
Dec 16 12:17 323.9K  /Users/jane/workspace/github.com/acme/webapp
             └─ Add authentication middleware to Express app
             ▶  git status
                56d2469f-acb8-4b82-9741-7fc81693d0d8
Dec 16 12:16 146.7K  /Users/jane/workspace/github.com/acme/webapp
             ▶  forget it
                00359c05-21e3-4d1e-ac2f-c73bce940228
Dec 16 12:08   1.2M  /Users/jane/workspace/github.com/acme/infra-terraform
             └─ Refactor VPC module for multi-region support
             ▶  Write CLAUDE.md with session context
                60215d77-6ac3-4cf8-9a55-18c67aaca6bd
```

### Verbose output

```
$ ccss -v
Dec 16 12:17 323.9K  /Users/jane/workspace/github.com/acme/webapp
             └─ Add authentication middleware to Express app
             ▶  git status
             📊 49/87 messages (user/assistant)
             🎫 PROJ-1234
             📁 /Users/jane/.claude/projects/-Users-jane-..../56d2469f-....jsonl
                56d2469f-acb8-4b82-9741-7fc81693d0d8
Dec 16 12:08   1.2M  /Users/jane/workspace/github.com/acme/infra-terraform
             └─ Refactor VPC module for multi-region support
             ▶  Write CLAUDE.md with session context
             📊 114/250 messages (user/assistant)
             🎫 PROJ-5678
             🌿 main
             🔗 https://docs.example.com/api/v2/...
             📁 /Users/jane/.claude/projects/-Users-jane-..../60215d77-....jsonl
                60215d77-6ac3-4cf8-9a55-18c67aaca6bd
```

### Short paths

```
$ ccss -s
Dec 16 12:17 323.9K  gh:acme/webapp
             └─ Add authentication middleware to Express app
             ▶  git status
                56d2469f-acb8-4b82-9741-7fc81693d0d8
```

### Search sessions

```
$ ccss -g Docker        # case-sensitive
$ ccss -g docker -i     # case-insensitive

$ ccss -g docker -i
Dec 15 14:22  89.4K  /Users/jane/workspace/github.com/acme/webapp
             └─ Configure Docker multi-stage build for production
             ▶  run the build
                a1b2c3d4-e5f6-7890-abcd-ef1234567890
Dec 14 09:15 156.2K  /Users/jane/workspace/github.com/acme/infra-terraform
             └─ Add ECS Fargate cluster with Docker support
             ▶  apply the changes
                b2c3d4e5-f6a7-8901-bcde-f23456789012
Dec 12 16:45  42.1K  /Users/jane/workspace/github.com/acme/docs
             └─ Document Docker deployment workflow
             ▶  commit this
                c3d4e5f6-a7b8-9012-cdef-345678901234
```
