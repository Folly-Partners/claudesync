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
./venv/bin/pip install "mcp>=1.2.0" "pyunifi>=2.21"

# 3. Make scripts executable
chmod +x "$PLUGIN_ROOT/scripts/"*.sh
chmod +x "$PLUGIN_ROOT/skills/"*/*.sh 2>/dev/null || true

# 4. Create settings.json symlink (so synced permissions work)
echo "Setting up settings symlink..."
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
  mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup"
fi
ln -sf "$PLUGIN_ROOT/settings.json" "$HOME/.claude/settings.json"

# 5. Create settings.local.json with machine-specific hooks
echo "Creating settings.local.json..."
cat > "$HOME/.claude/settings.local.json" << EOF
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$PLUGIN_ROOT/skills/github-sync/sync-mcp-oauth.sh push --quiet"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "andrews-plugin@andrews-marketplace": true
  },
  "extraKnownMarketplaces": {
    "andrews-marketplace": {
      "source": {
        "source": "url",
        "url": "https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json"
      }
    }
  }
}
EOF

# 6. Install LaunchAgent for auto-sync
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
