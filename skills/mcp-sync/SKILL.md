# MCP Server Sync

Sync MCP server configurations across all your Macs. Stores server definitions in a template with variable substitution, and credentials securely via deep-env.

## How It Works

1. **Template file** (`~/.claude/mcp-servers.template.json`) stores MCP server configs with variables
2. **Credentials** are stored in deep-env (macOS Keychain + iCloud sync)
3. **Sync script** expands variables and writes to `~/.claude.json`

## Usage

```bash
# Sync MCP servers (expand template → ~/.claude.json)
~/.claude/skills/mcp-sync/mcp-sync.sh

# Check for missing credentials
~/.claude/skills/mcp-sync/mcp-sync.sh check

# List servers in template
~/.claude/skills/mcp-sync/mcp-sync.sh list

# Add a credential
~/.claude/skills/mcp-sync/mcp-sync.sh add-credential HUNTER_API_KEY "your-key"
```

## Template Variables

| Variable | Expands To |
|----------|------------|
| `${HOME}` | Home directory (`/Users/andrewwilkinson`) |
| `${ENV:KEY_NAME}` | Credential from deep-env |

## Adding a New MCP Server

1. Edit `~/.claude/mcp-servers.template.json`
2. Use `${HOME}` for any paths
3. Use `${ENV:KEY_NAME}` for any secrets
4. Store the credential: `deep-env store KEY_NAME "value"`
5. Push credentials: `deep-env push`
6. Run sync: `~/.claude/skills/mcp-sync/mcp-sync.sh`

### Example: Adding a new server

```json
{
  "mcpServers": {
    "my-new-server": {
      "type": "stdio",
      "command": "node",
      "args": ["${HOME}/Projects/my-server/dist/index.js"],
      "env": {
        "API_KEY": "${ENV:MY_SERVER_API_KEY}"
      }
    }
  }
}
```

Then:
```bash
deep-env store MY_SERVER_API_KEY "secret123"
deep-env push
~/.claude/skills/mcp-sync/mcp-sync.sh
```

## On a New Mac

1. Pull credentials from iCloud:
   ```bash
   deep-env pull
   ```

2. Sync MCP servers:
   ```bash
   ~/.claude/skills/mcp-sync/mcp-sync.sh
   ```

That's it. All your MCP servers will be configured.

## Integration with Session Start

The github-sync skill runs at session start. Add mcp-sync to run automatically:

In `~/.claude/skills/github-sync/git-sync-check.sh`, add after the git checks:
```bash
# Sync MCP servers
~/.claude/skills/mcp-sync/mcp-sync.sh
```

## Files

| File | Purpose |
|------|---------|
| `~/.claude/mcp-servers.template.json` | Server configs with variables (synced via git) |
| `~/.claude.json` | Actual config Claude Code reads (generated) |
| Keychain via deep-env | Credentials (synced via iCloud) |

## Troubleshooting

**"Credential not found" warnings:**
```bash
# Check which credentials are missing
~/.claude/skills/mcp-sync/mcp-sync.sh check

# Add the missing credential
deep-env store MISSING_KEY "value"
```

**MCP server not working after sync:**
```bash
# Restart Claude Code to pick up new config
# Check the generated config
cat ~/.claude.json | jq '.mcpServers'
```

**Path doesn't exist on this machine:**
- The script uses `${HOME}` which works on any Mac
- For project-specific servers, ensure the repo is cloned to the same relative path
