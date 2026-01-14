#!/bin/bash

# Andrews Plugin - One-Line Installer
# Installs via Claude Code's official plugin system
#
# Usage: curl -fsSL https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/install.sh | bash

set -e

echo "📦 Installing Andrews Plugin + Dependencies..."
echo ""

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "❌ Claude Code CLI not found. Please install Claude Code first."
    echo "   https://claude.ai/code"
    exit 1
fi

# Add Andrews Plugin marketplace
echo "1️⃣  Adding Andrews Plugin marketplace..."
if claude plugin marketplace add https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json 2>/dev/null; then
    echo "   ✅ Andrews marketplace added"
else
    echo "   ℹ️  Andrews marketplace may already exist, continuing..."
fi

# Add Every Inc marketplace (for Compound Engineering)
echo "2️⃣  Adding Every Inc marketplace..."
if claude plugin marketplace add https://github.com/EveryInc/every-marketplace 2>/dev/null; then
    echo "   ✅ Every Inc marketplace added"
else
    echo "   ℹ️  Every Inc marketplace may already exist, continuing..."
fi

# Install Andrews Plugin
echo "3️⃣  Installing Andrews Plugin..."
if claude plugin install andrews-plugin 2>/dev/null; then
    echo "   ✅ Andrews Plugin installed"
else
    echo "   ℹ️  Andrews Plugin may already be installed, continuing..."
fi

# Install Compound Engineering Plugin
echo "4️⃣  Installing Compound Engineering Plugin..."
if claude plugin install compound-engineering 2>/dev/null; then
    echo "   ✅ Compound Engineering installed"
else
    echo "   ℹ️  Compound Engineering may already be installed, continuing..."
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Installed:"
echo "  • Andrews Plugin (MCP servers, skills, commands, agents)"
echo "  • Compound Engineering (advanced workflows)"
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
