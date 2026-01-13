#!/bin/bash
# One-time setup for the plugin

set -e

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Setting up Andrew's Plugin..."

# 1. Install SuperThings dependencies
echo "Installing SuperThings dependencies..."
cd "$PLUGIN_ROOT/servers/super-things"
npm install
npm run build

# 2. Create Python venv for unifi
echo "Setting up unifi server..."
cd "$PLUGIN_ROOT/servers/unifi"
python3 -m venv venv
./venv/bin/pip install -r requirements.txt

# 3. Make scripts executable
chmod +x "$PLUGIN_ROOT/scripts/"*.sh
chmod +x "$PLUGIN_ROOT/skills/"*/*.sh 2>/dev/null || true

# 4. Install LaunchAgent for auto-sync
echo "Installing LaunchAgent for auto-sync..."
PLIST_SRC="$PLUGIN_ROOT/scripts/com.andrews-plugin.sync.plist.template"
PLIST_DST="$HOME/Library/LaunchAgents/com.andrews-plugin.sync.plist"

# Replace __PLUGIN_DIR__ with actual path
sed "s|__PLUGIN_DIR__|$PLUGIN_ROOT|g" "$PLIST_SRC" > "$PLIST_DST"

# Unload old agent if exists, load new one
launchctl unload "$PLIST_DST" 2>/dev/null || true
launchctl unload "$HOME/Library/LaunchAgents/com.claude.config-sync.plist" 2>/dev/null || true
launchctl load "$PLIST_DST"

echo ""
echo "Setup complete!"
echo ""
echo "Auto-sync: Enabled (daily at 9am + on login)"
echo ""
echo "Next steps:"
echo "  1. Ensure credentials are in deep-env: deep-env list"
echo "  2. Enable the plugin in Claude Code settings"
echo "  3. Run doctor to verify: $PLUGIN_ROOT/scripts/doctor.sh"
