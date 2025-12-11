# Claude Code Sync

Syncs Claude Code configuration across all my computers automatically.

## Quick Setup (New Computer)

```bash
curl -fsSL https://raw.githubusercontent.com/awilkinson/claude-code-sync/main/setup-new-computer.sh | bash
```

That's it. Everything else is automatic.

---

## What Gets Synced

| Item | Path | Description |
|------|------|-------------|
| MCP Servers | `claude.json` | 7 servers: things-mcp, webflow, browserbase, tavily, zapier, ahrefs, xero (with auth tokens) |
| Custom Agents | `agents/` | email-response-processor, inbox-task-manager, wardrobe-cataloger |
| Settings | `settings.local.json` | Enabled MCP servers + permissions |
| Plugins | `plugins/` | Plugin configuration |
| History | `history.jsonl` | Chat history |
| Todos | `todos/` | Task lists |
| Projects | `projects/` | Conversation history |

## What Does NOT Sync

| Item | Path | Reason |
|------|------|--------|
| OAuth Tokens | `.credentials.json` | Machine-specific, would cause auth conflicts |
| Debug Logs | `debug/` | Not useful across machines |
| Session Data | `session-env/`, `shell-snapshots/` | Machine-specific |
| Analytics | `statsig/` | Machine-specific |

## How It Works

### Architecture

```
~/.claude.json  →  symlink  →  ~/.claude/claude.json (in git repo)
~/.claude/      →  git repo  →  github.com/awilkinson/claude-code-sync
```

The key trick: `~/.claude.json` (where Claude Code looks for MCP config) is a symlink pointing to `~/.claude/claude.json` (inside the git repo). This lets us sync the MCP config without moving it.

### Sync Flow

```
┌─────────────────────────────────────────────────────────┐
│                    sync-claude-config.sh                │
├─────────────────────────────────────────────────────────┤
│  1. Check: Already synced today? → Skip if yes         │
│  2. Check: Internet available? → Skip if no            │
│  3. git pull origin main (get changes from other Macs) │
│  4. git add . (stage local changes)                    │
│  5. git commit (with timestamp)                        │
│  6. git push origin main (push to GitHub)              │
│  7. Mark today as synced (prevents re-runs)            │
└─────────────────────────────────────────────────────────┘
```

### Schedule

The sync runs automatically via macOS Launch Agent (`~/Library/LaunchAgents/com.claude.config-sync.plist`):
- **On login** - when you start your Mac
- **Daily at 9am** - catches any missed syncs

The script self-throttles to once per day, so multiple triggers won't cause issues.

## File Structure

```
~/.claude/
├── claude.json              # MCP server config (symlinked from ~/.claude.json)
├── settings.local.json      # Claude Code settings
├── agents/                  # Custom agents
│   ├── email-response-processor.md
│   ├── inbox-task-manager.md
│   └── wardrobe-cataloger.md
├── plugins/                 # Plugin config
├── projects/                # Conversation history
├── todos/                   # Task lists
├── history.jsonl            # Chat history
├── sync-claude-config.sh    # Sync script
├── setup-new-computer.sh    # Setup script for new Macs
├── .gitignore               # Excludes sensitive/machine-specific files
├── sync.log                 # Sync script log
└── sync-launchd.log         # Launch agent log
```

## Manual Commands

```bash
# Force sync now (bypass daily limit)
rm ~/.claude/.last_sync_date && ~/.claude/sync-claude-config.sh

# View sync log
cat ~/.claude/sync.log

# Trigger sync via launch agent
launchctl start com.claude.config-sync

# Check launch agent status
launchctl list | grep claude.config

# Disable auto-sync
launchctl unload ~/Library/LaunchAgents/com.claude.config-sync.plist

# Re-enable auto-sync
launchctl load ~/Library/LaunchAgents/com.claude.config-sync.plist
```

## Troubleshooting

### Sync failed with merge conflict
```bash
cd ~/.claude
git status                    # See what conflicted
git checkout --theirs .       # Accept remote version (or --ours for local)
git add . && git commit -m "Resolve merge conflict"
git push origin main
```

### MCP servers not loading
Check the symlink exists:
```bash
ls -la ~/.claude.json
# Should show: ~/.claude.json -> ~/.claude/claude.json
```

If broken, recreate it:
```bash
ln -sf ~/.claude/claude.json ~/.claude.json
```

### Launch agent not running
```bash
launchctl list | grep claude.config
# If not listed:
launchctl load ~/Library/LaunchAgents/com.claude.config-sync.plist
```

## Limitations

- **Conversations are NOT resumable across computers** - `/resume` only works for sessions started on that specific machine
- **Sync is one-way per run** - if two computers make changes before syncing, you may get merge conflicts
- **macOS only** - the launch agent setup is Mac-specific (Linux would need cron/systemd)

## For Claude (AI Assistant)

If a user asks you to set up Claude Code sync on a new computer, direct them to run:

```bash
curl -fsSL https://raw.githubusercontent.com/awilkinson/claude-code-sync/main/setup-new-computer.sh | bash
```

This will:
1. Backup existing `~/.claude` and `~/.claude.json` if present
2. Clone this repo to `~/.claude`
3. Create symlink: `~/.claude.json` → `~/.claude/claude.json`
4. Set up launch agent for automatic sync (login + 9am daily)
5. Run initial sync

No manual steps required.
