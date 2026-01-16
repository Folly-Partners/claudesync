# MCP Server Sync

Check and manage MCP server configuration across your Macs.

## How It Works

Claude Code natively supports `${VAR}` expansion in `mcp.json`:
- `${HOME}` - expands to home directory (portable across machines)
- `${VAR_NAME}` - expands to environment variable value

Credentials are stored in deep-env (macOS Keychain) and synced via iCloud.

## Usage

```bash
# Check if required env vars are set (default)
~/claudesync/skills/mcp-sync/mcp-sync.sh

# List servers in mcp.json
~/claudesync/skills/mcp-sync/mcp-sync.sh list

# Reload env vars from deep-env and check
~/claudesync/skills/mcp-sync/mcp-sync.sh reload
```

## Adding a New MCP Server

1. Edit `~/claudesync/mcp.json`
2. Use `${HOME}` for any paths
3. Use `${VAR_NAME}` for credentials
4. Store the credential: `deep-env store VAR_NAME "value"`
5. Push to iCloud: `deep-env push`
6. Reload shell: `source ~/.zshrc`

### Example

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

Then:
```bash
deep-env store MY_SERVER_API_KEY "secret123"
deep-env push
source ~/.zshrc
```

## On a New Mac

```bash
# Pull credentials from iCloud
deep-env pull

# Reload shell to get env vars
source ~/.zshrc

# Verify all vars are set
~/claudesync/skills/mcp-sync/mcp-sync.sh check
```

## Files

| File | Purpose |
|------|---------|
| `~/claudesync/mcp.json` | Server configs with `${VAR}` syntax (synced via git) |
| Keychain via deep-env | Credentials (synced via iCloud) |
| `~/.zshrc` | Loads credentials via `deep-env export` |

## Troubleshooting

**"Variable MISSING" in check:**
```bash
# Store the missing credential
deep-env store VAR_NAME "value"
deep-env push
source ~/.zshrc
```

**MCP server not connecting:**
```bash
# Check env vars are loaded
echo $VAR_NAME

# If empty, reload from deep-env
eval "$(deep-env export)"
```
