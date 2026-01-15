```
   _____ _                 _      _____
  / ____| |               | |    / ____|
 | |    | | __ _ _   _  __| | ___| (___  _   _ _ __   ___
 | |    | |/ _` | | | |/ _` |/ _ \\___ \| | | | '_ \ / __|
 | |____| | (_| | |_| | (_| |  __/____) | |_| | | | | (__
  \_____|_|\__,_|\__,_|\__,_|\___|_____/ \__, |_| |_|\___|
                                          __/ |
                                         |___/
```

# claudesync

**Sync Claude Code across all your Macs** - MCP servers, skills, commands, credentials, and more.

Part of the **Folly** marketplace.

## Quick Install

```bash
# Add the Folly marketplace
/plugin marketplace add Folly-Partners/claudesync

# Install claudesync
/plugin install claudesync@Folly
```

Or run the setup wizard:
```bash
./hooks/setup-wizard.sh
```

---

## What's Included

### 11 MCP Servers

Complete list in [MCP-SERVERS.md](MCP-SERVERS.md):

| Server | Purpose |
|--------|---------|
| **SuperThings** | Things 3 task management integration |
| **Playwright** | Browser automation and testing |
| **Pipedream** | 10,000+ tools across 3,000+ APIs |
| **Browserbase** | Cloud browser automation |
| **Tavily** | AI-powered web search |
| **Hunter** | Email finding and verification |
| **Linear** | Issue tracking |
| **Unifi** | Network management |
| **GitHub** | Repository operations |
| **Supabase** | Database management |
| **Vercel** | Deployment platform |

### 5 Skills

- **deep-env** - Secure credential management (macOS Keychain + iCloud sync)
- **github-sync** - Automatic git synchronization across repos
- **enhanced-planning** - Structured planning workflow with parallel research
- **history-pruner** - Clean up old conversation history
- **mcp-sync** - MCP server configuration validation

### 11 Commands

| Command | Purpose |
|---------|---------|
| `/commit` | Stage all changes and commit with auto-generated message |
| `/push` | Stage all, commit, and push to remote |
| `/scommit` | Selective staging with file picker |
| `/spush` | Selective staging + push |
| `/github-sync` | Full sync across all git repos |
| `/test` | Run tests and generate comprehensive reports |
| `/deepcodereview` | Multi-hour autonomous code review |
| `/setup` | Interactive setup wizard |
| `/setup-deep-env` | Configure deep-env credential manager |
| `/sync-env` | Sync environment variables to project |
| `/add-credential` | Store credentials securely |

### 3 Custom Agents

- **email-response-processor** - Process Gmail "simple-decision" emails with multi-option responses
- **inbox-task-manager** - Triage and organize Things 3 inbox tasks
- **wardrobe-cataloger** - Analyze clothing photos and catalog to Google Sheets

---

## Architecture

### Plugin Structure

```
~/andrews-plugin/
├── .claude-plugin/           # Plugin metadata
├── agents/                   # Custom AI agents
├── commands/                 # Slash commands
├── skills/                   # Reusable skills
├── servers/                  # Custom MCP servers
│   ├── super-things/        # Things 3 integration (TypeScript)
│   └── unifi/               # Network management (Python)
├── hooks/                    # Event hooks (SessionStart, UserPromptSubmit)
├── scripts/                  # Setup and maintenance scripts
├── mcp.json                  # MCP server configuration
└── marketplace.json          # Plugin marketplace definition
```

### How Syncing Works

| What | How | When |
|------|-----|------|
| **Plugin updates** | Folly marketplace | Automatic (Claude Code auto-updates) |
| **Credentials** | deep-env → iCloud | Daily at 9am + login (LaunchAgent) |
| **Manual changes** | Git push → marketplace | When you're ready |

**Workflow:**
1. Modify plugin on Mac A (add skill, update MCP server, etc.)
2. Commit & push to GitHub
3. Marketplace distributes the update
4. Mac B gets update automatically

---

## Setup on New Mac

### Automated Setup

```bash
# Clone the repo
git clone https://github.com/Folly-Partners/claudesync.git ~/andrews-plugin
cd ~/andrews-plugin

# Run setup script
./scripts/setup.sh
```

The setup script will:
1. Build SuperThings MCP server (npm install + build)
2. Set up Python environment for Unifi server
3. Register plugin with Claude Code
4. Configure auto-sync

### Manual Steps

If you prefer manual setup:

```bash
# 1. Clone repo
git clone https://github.com/Folly-Partners/claudesync.git ~/andrews-plugin

# 2. Set git identity
cd ~/andrews-plugin
git config user.name "Andrew Wilkinson"
git config user.email "andrew@tiny.com"

# 3. Build SuperThings server
cd ~/andrews-plugin/servers/super-things
npm install && npm run build

# 4. Setup Python for Unifi server
cd ~/andrews-plugin/servers/unifi
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Register plugin with Claude Code
# Open Claude Code settings and add custom marketplace
```

---

## Configuration Files

### mcp.json

Defines all MCP servers with portable paths using `${VAR}` expansion:

```json
{
  "SuperThings": {
    "command": "node",
    "args": ["${HOME}/andrews-plugin/servers/super-things/dist/index.js"]
  }
}
```

### CLAUDE.md

Project-level instructions stored in:
- `~/andrews-plugin/CLAUDE.md` - Instructions for working on the plugin itself
- `~/CLAUDE.md` - Global instructions for Claude Code (copied from plugin)
- `~/.claude/CLAUDE.md` - User-level instructions (synced across all projects)

---

## Skills Overview

### deep-env (Credential Management)

Stores credentials in macOS Keychain, syncs encrypted to iCloud:

```bash
# Store a credential
deep-env store ANTHROPIC_API_KEY "sk-ant-..."

# Sync to current project
deep-env sync .

# Push to iCloud (for other Macs)
deep-env push
```

### github-sync (Git Synchronization)

Automatically discovers and checks all git repos in home directory:

```bash
# Manual check (daily auto-check via CLAUDE.md)
~/andrews-plugin/skills/github-sync/git-sync-check.sh

# Force check
~/andrews-plugin/skills/github-sync/git-sync-check.sh --force

# Sync all repos
~/andrews-plugin/skills/github-sync/git-sync-all.sh
```

---

## Troubleshooting

### Plugin not showing in Claude Code

Check plugin is registered:
```bash
cat ~/.claude/settings.json | grep claudesync
```

Should show:
```json
"enabledPlugins": {
  "claudesync@Folly": true
}
```

### MCP servers not loading

Check MCP configuration:
```bash
claude mcp list
```

Verify SuperThings is built:
```bash
ls ~/andrews-plugin/servers/super-things/dist/index.js
```

### Git sync not working

Check git status:
```bash
cd ~/andrews-plugin
git status
git log --oneline -5
```

Verify github-sync skill is working:
```bash
~/andrews-plugin/skills/github-sync/git-sync-check.sh --force
```

### Credentials not syncing

Check deep-env status:
```bash
deep-env list
deep-env pull  # Pull from iCloud
```

---

## Version History

- **1.3.0** - Major cleanup, removed session artifacts, updated docs, fixed paths
- **1.2.0** - Added auto-discovery for git repos, updated git identity
- **1.1.0** - Initial plugin marketplace release
- **1.0.0** - Legacy claude-code-sync architecture

---

## For Claude (AI Assistant)

When working with this plugin:

1. **Git identity** - Always use Andrew Wilkinson <andrew@tiny.com>
2. **Path references** - Use `~/andrews-plugin/` for the repo
3. **Plugin name** - `claudesync@Folly`
4. **Credentials** - Use deep-env for storing API keys and secrets

See [CLAUDE.md](CLAUDE.md) for complete instructions.
