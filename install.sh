#!/bin/bash

# Andrews Plugin - Quick Install
# Registers the marketplace so you can install via /plugin
#
# Usage: curl -fsSL https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/install.sh | bash

set -e

echo "📦 Registering Andrews Plugin marketplace..."

# Create plugins directory if needed
mkdir -p ~/.claude/plugins/marketplaces

# Register the marketplace
cat > ~/.claude/plugins/marketplaces/andrews-plugin.json << 'EOF'
{
  "name": "andrews-plugin",
  "displayName": "Andrew's Plugin Marketplace",
  "url": "https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json",
  "autoUpdate": true
}
EOF

echo "✅ Marketplace registered!"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code"
echo "  2. Run /plugin → Discover tab → Find 'andrews-plugin'"
echo "  3. Install the plugin"
echo "  4. Run ~/.claude/setup-new-computer.sh for full setup (deep-env, sync agent)"
