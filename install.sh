#!/bin/bash

# Andrews Plugin - One-Line Installer
# Installs via Claude Code's official plugin system
#
# Usage: curl -fsSL https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/install.sh | bash

set -e

echo "📦 Installing Andrews Plugin..."
echo ""

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "❌ Claude Code CLI not found. Please install Claude Code first."
    echo "   https://claude.ai/code"
    exit 1
fi

# Add the marketplace
echo "1️⃣  Adding marketplace..."
if claude plugin marketplace add https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json 2>/dev/null; then
    echo "   ✅ Marketplace added"
else
    echo "   ℹ️  Marketplace may already exist, continuing..."
fi

# Install the plugin
echo "2️⃣  Installing plugin..."
if claude plugin install andrews-plugin 2>/dev/null; then
    echo "   ✅ Plugin installed"
else
    echo "   ℹ️  Plugin may already be installed, continuing..."
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next: Start Claude Code - the plugin will guide you through setup."
echo ""
echo "What happens on first run:"
echo "  • Checks for deep-env (credential manager)"
echo "  • Sets up automatic sync (launchd agent)"
echo "  • Configures MCP servers"
echo "  • Pulls credentials from iCloud (if available)"
echo ""
echo "Run 'claude' to get started!"
