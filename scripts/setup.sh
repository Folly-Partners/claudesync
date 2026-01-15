#!/bin/bash
# One-time setup for the claudesync plugin

set -e

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Setting up claudesync plugin..."

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
chmod +x "$PLUGIN_ROOT/hooks/"*.sh 2>/dev/null || true

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Ensure credentials are in deep-env: deep-env list"
echo "  2. Enable the plugin: /plugin install claudesync@Folly"
echo "  3. Run doctor to verify: $PLUGIN_ROOT/scripts/doctor.sh"
