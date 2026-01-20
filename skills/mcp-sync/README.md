# mcp-sync

Check and manage MCP server configuration across your Macs.

## Quick Start

Check if required env vars are set:
```bash
~/.claude/plugins/marketplaces/Folly/skills/mcp-sync/mcp-sync.sh
```

List configured servers:
```bash
~/.claude/plugins/marketplaces/Folly/skills/mcp-sync/mcp-sync.sh list
```

Reload and check:
```bash
~/.claude/plugins/marketplaces/Folly/skills/mcp-sync/mcp-sync.sh reload
```

## How It Works

```
┌─────────────────────────────────────────────────────┐
│  mcp.json                                           │
│  Uses ${VAR} syntax for credentials                 │
│                                                     │
│  "env": {                                           │
│    "API_KEY": "${MY_SERVER_API_KEY}"               │
│  }                                                  │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  deep-env                                           │
│  Stores credentials in macOS Keychain              │
│  Syncs across Macs via iCloud                       │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  Claude Code                                        │
│  Expands ${VAR} at runtime                          │
│  Loads credentials from environment                 │
└─────────────────────────────────────────────────────┘
```

Claude Code natively supports variable expansion in `mcp.json`:
- `${HOME}` - expands to home directory (portable across machines)
- `${VAR_NAME}` - expands to environment variable value

## Commands

| Command | Description |
|---------|-------------|
| `mcp-sync.sh` | Check if required env vars are set |
| `mcp-sync.sh list` | List servers in mcp.json |
| `mcp-sync.sh reload` | Reload env vars from deep-env and check |
| `mcp-sync.sh check` | Verify all vars are set |

## Adding a New MCP Server

1. Edit `~/claudesync/mcp.json`:
```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "node",
      "args": ["${HOME}/Projects/my-server/dist/index.js"],
      "env": {
        "API_KEY": "${MY_SERVER_API_KEY}"
      }
    }
  }
}
```

2. Store the credential:
```bash
deep-env store MY_SERVER_API_KEY "secret123"
deep-env push
```

3. Reload shell:
```bash
source ~/.zshrc
```

## On a New Mac

```bash
# Pull credentials from iCloud
deep-env pull

# Reload shell to get env vars
source ~/.zshrc

# Verify all vars are set
~/.claude/plugins/marketplaces/Folly/skills/mcp-sync/mcp-sync.sh check
```

## Files

| File | Purpose |
|------|---------|
| `~/claudesync/mcp.json` | Server configs with `${VAR}` syntax (synced via git) |
| Keychain via deep-env | Credentials (synced via iCloud) |
| `~/.zshrc` | Loads credentials via `deep-env export` |

## Troubleshooting

### "Variable MISSING" in check

```bash
# Store the missing credential
deep-env store VAR_NAME "value"
deep-env push
source ~/.zshrc
```

### MCP server not connecting

```bash
# Check env vars are loaded
echo $VAR_NAME

# If empty, reload from deep-env
eval "$(deep-env export)"
```

## For Claude Code

When working with MCP servers:

1. Use `mcp-sync.sh list` to see configured servers
2. Use `mcp-sync.sh check` to verify env vars are set
3. If vars are missing, store them with `deep-env store`
4. After storing, remind user to reload shell: `source ~/.zshrc`
