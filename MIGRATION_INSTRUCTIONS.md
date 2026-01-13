# Migration Instructions for Other Computers

Copy and paste this entire message into Claude Code on your other computers that already have `claude-code-sync` installed.

---

## Instructions for Claude Code

I need you to migrate my existing `claude-code-sync` setup to the new `andrews-plugin` structure. Here's what you need to do:

### Step 1: Navigate to the plugin directory
```bash
cd ~/andrews-plugin
```

### Step 2: Pull the latest changes from GitHub
This will download all the new plugin files (manifest.json, .mcp.json, servers/, scripts/, etc.)
```bash
git pull origin main
```

### Step 3: Run the migration script
This script will:
- Build SuperThings dependencies
- Set up Unifi Python virtual environment
- Update the LaunchAgent for auto-sync
- Configure `~/.claude/settings.local.json` with the marketplace
- Verify everything is working

```bash
./scripts/migrate.sh
```

### Step 4: Verify the setup
Check that all servers and credentials are configured correctly:
```bash
./scripts/doctor.sh
```

### Step 5: Show me the results
Once complete, please show me:
1. The output from the migration script
2. The output from the doctor script
3. Confirmation that `~/.claude/settings.local.json` contains the marketplace configuration

---

## What This Migration Does

The migration transforms your existing `claude-code-sync` setup into "Andrew's Plugin":

**Before:**
- Configuration scattered across multiple files
- Hardcoded paths in `claude.json`
- Manual setup required on each machine

**After:**
- Proper Claude Code plugin structure
- Portable MCP server declarations using `${CLAUDE_PLUGIN_ROOT}`
- SuperThings and Unifi bundled into the plugin
- One-command setup on new machines
- Custom marketplace for easy distribution

**Key Changes:**
- SuperThings moved to `~/andrews-plugin/servers/super-things/`
- Unifi moved to `~/andrews-plugin/servers/unifi/`
- All credentials managed via Deep Env (no changes needed)
- Auto-sync LaunchAgent updated to use new structure
- Plugin marketplace registered at `~/.claude/settings.local.json`

**No Downtime:**
- Your existing MCP servers continue working
- Credentials remain unchanged (managed by Deep Env)
- Auto-sync continues running (updated LaunchAgent)

---

## Troubleshooting

If you encounter any issues:

1. **"Permission denied" when pulling from GitHub**
   - Check your git remote: `git remote -v`
   - If using SSH and you get permission denied, switch to HTTPS:
     ```bash
     git remote set-url origin https://github.com/Folly-Partners/andrews-plugin.git
     ```

2. **SuperThings build fails**
   - Clean install: `cd ~/andrews-plugin/servers/super-things && rm -rf node_modules && npm install && npm run build`

3. **Unifi venv fails**
   - Recreate venv: `cd ~/andrews-plugin/servers/unifi && rm -rf venv && python3 -m venv venv && ./venv/bin/pip install "mcp>=1.2.0" "pyunifi>=2.21"`

4. **Doctor script reports missing credentials**
   - Verify they're in Deep Env: `deep-env list`
   - If missing, check iCloud sync: `deep-env pull`

5. **settings.local.json update fails**
   - Manually add this to `~/.claude/settings.local.json`:
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

Once migrated, your setup will be identical to the primary machine:
- All 10 MCP servers configured
- SuperThings and Unifi bundled and ready
- Auto-sync running daily at 9am
- Plugin marketplace registered
- New machines can be set up with a single bootstrap command

To verify everything is working, restart Claude Code after the migration completes.
