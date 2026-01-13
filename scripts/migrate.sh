#!/bin/bash
# Migration script for existing claude-code-sync setups
# Transforms to the new andrews-plugin structure

set -e

PLUGIN_DIR="$HOME/andrews-plugin"
CLAUDE_DIR="$HOME/.claude"

echo "=========================================="
echo "Andrew's Plugin Migration Script"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "$PLUGIN_DIR/.git" ]; then
    echo "ERROR: $PLUGIN_DIR does not exist or is not a git repository"
    echo "This script is for migrating existing setups only."
    exit 1
fi

cd "$PLUGIN_DIR"

# Check if already migrated
if [ -f "manifest.json" ] && [ -f ".mcp.json" ] && [ -f "scripts/setup.sh" ]; then
    echo "✓ Plugin files detected (already migrated)"
else
    echo "ERROR: Plugin files not found. Pull from GitHub first."
    exit 1
fi

echo "Step 1: Pulling latest changes from GitHub..."
git pull origin main

echo ""
echo "Step 2: Checking for SuperThings and Unifi servers..."

if [ ! -d "servers/super-things" ]; then
    echo "ERROR: servers/super-things directory not found"
    exit 1
fi

if [ ! -d "servers/unifi" ]; then
    echo "ERROR: servers/unifi directory not found"
    exit 1
fi

echo "✓ Server directories found"

echo ""
echo "Step 3: Running setup to build dependencies..."
./scripts/setup.sh

echo ""
echo "Step 4: Configuring ~/.claude/settings.local.json..."

# Update settings.local.json
if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
    # Backup existing settings
    cp "$CLAUDE_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json.backup.$(date +%Y%m%d%H%M%S)"
    echo "✓ Backed up existing settings.local.json"

    # Check if it already has the marketplace config
    if grep -q "andrews-marketplace" "$CLAUDE_DIR/settings.local.json"; then
        echo "✓ Marketplace already configured"
    else
        echo "Adding marketplace configuration..."
        # Use Python to merge JSON (safer than manual editing)
        python3 -c "
import json
import sys

with open('$CLAUDE_DIR/settings.local.json', 'r') as f:
    settings = json.load(f)

# Add marketplace config
if 'extraKnownMarketplaces' not in settings:
    settings['extraKnownMarketplaces'] = {}

settings['extraKnownMarketplaces']['andrews-marketplace'] = {
    'source': {
        'source': 'url',
        'url': 'https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json'
    }
}

# Add enabled plugins
if 'enabledPlugins' not in settings:
    settings['enabledPlugins'] = {}

settings['enabledPlugins']['andrews-plugin@andrews-marketplace'] = True

with open('$CLAUDE_DIR/settings.local.json', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print('✓ Updated settings.local.json')
" || {
            echo "ERROR: Failed to update settings.local.json"
            echo "You may need to update it manually"
            exit 1
        }
    fi
else
    echo "Creating new settings.local.json..."
    cat > "$CLAUDE_DIR/settings.local.json" << 'EOF'
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
EOF
    echo "✓ Created settings.local.json"
fi

echo ""
echo "Step 5: Running health check..."
./scripts/doctor.sh

echo ""
echo "=========================================="
echo "Migration Complete!"
echo "=========================================="
echo ""
echo "The plugin is now configured and ready to use."
echo ""
echo "Changes made:"
echo "  - SuperThings bundled into plugin (servers/super-things/)"
echo "  - Unifi server moved to plugin (servers/unifi/)"
echo "  - Auto-sync LaunchAgent updated"
echo "  - Plugin marketplace registered"
echo ""
echo "Next: Restart Claude Code for changes to take effect."
