# Migration Instructions for Other Computers

Copy and paste this entire message into Claude Code on your other computers that already have `claude-code-sync` installed.

---

## Instructions for Claude Code

I need you to migrate my existing claude-code-sync setup to the new andrews-plugin structure. Run this single command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/scripts/migrate.sh)
```

Then show me the output so I can confirm everything worked.

---

## What This Migration Does

The migration script will automatically:

1. **Detect your current setup** - Finds your repo at `~/.claude`
2. **Pull latest changes** - Downloads all new plugin files from GitHub
3. **Move to new location** - Moves `~/.claude` → `~/andrews-plugin`
4. **Create minimal ~/.claude** - Sets up a minimal `~/.claude` directory for settings only
5. **Build dependencies** - Installs SuperThings (npm) and Unifi (Python venv)
6. **Configure marketplace** - Registers the plugin in `~/.claude/settings.local.json`
7. **Verify setup** - Runs health checks to ensure everything works

**Time Required:** ~2-3 minutes per machine

---

## What Changes

### Before Migration
```
~/.claude/                  # Git repo with everything
  ├── agents/
  ├── skills/
  ├── mcp.json
  ├── settings.json
  └── ... (all files mixed together)
```

### After Migration
```
~/andrews-plugin/           # Git repo (moved from ~/.claude)
  ├── manifest.json         # NEW: Plugin metadata
  ├── .mcp.json             # NEW: Portable MCP declarations
  ├── marketplace.json      # NEW: Custom marketplace
  ├── servers/              # NEW: Bundled MCP servers
  │   ├── super-things/     #   - SuperThings (copied from ~/SuperThings)
  │   └── unifi/            #   - Unifi (moved from mcp-servers/)
  ├── scripts/              # NEW: Setup & utility scripts
  ├── agents/               # Existing agents
  ├── skills/               # Existing skills
  └── ...

~/.claude/                  # NEW: Minimal directory for settings
  ├── settings.local.json   # Plugin marketplace config
  └── andrews-plugin/       # Symlink to ~/andrews-plugin
```

---

## No Downtime

Your existing setup continues working during migration:
- ✅ All MCP servers keep running
- ✅ Credentials stay unchanged (managed by Deep Env)
- ✅ Auto-sync continues (LaunchAgent updates automatically)
- ✅ All agents, skills, and hooks preserved

---

## Troubleshooting

If you encounter any issues, Claude can try these fixes:

### 1. Git Permission Denied
```bash
cd ~/.claude
git remote set-url origin https://github.com/Folly-Partners/andrews-plugin.git
git pull origin main
```

### 2. SuperThings Build Fails
```bash
cd ~/andrews-plugin/servers/super-things
rm -rf node_modules package-lock.json
npm install && npm run build
```

### 3. Unifi Virtual Environment Fails
```bash
cd ~/andrews-plugin/servers/unifi
rm -rf venv
python3 -m venv venv
./venv/bin/pip install "mcp>=1.2.0" "pyunifi>=2.21"
```

### 4. Missing Credentials
```bash
deep-env pull
deep-env list
```

### 5. Manual settings.local.json Update
If the Python script fails, manually add this to `~/.claude/settings.local.json`:
```json
{
  "extraKnownMarketplaces": {
    "andrews-marketplace": {
      "source": {
        "source": "url",
        "url": "https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json"
      }
    }
  },
  "enabledPlugins": {
    "andrews-plugin@andrews-marketplace": true
  }
}
```

---

## After Migration

Once migrated:
- ✅ Restart Claude Code for changes to take effect
- ✅ Your setup will be identical to the primary machine
- ✅ All 10 MCP servers will be configured and ready
- ✅ Auto-sync runs daily at 9am
- ✅ Plugin marketplace is registered

To verify: `~/andrews-plugin/scripts/doctor.sh`

---

## Alternative: Manual Migration

If you prefer to run commands step-by-step instead of the one-liner:

```bash
# 1. Navigate to existing repo
cd ~/.claude

# 2. Pull latest changes (includes migration script)
git pull origin main

# 3. Run migration script
./scripts/migrate.sh
```

This gives you more control and lets you see each step as it happens.
