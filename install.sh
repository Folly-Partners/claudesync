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

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Adding Marketplaces"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Add Andrews Plugin marketplace
echo "1️⃣  Adding Andrews Plugin marketplace..."
if claude plugin marketplace add https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json 2>/dev/null; then
    echo "   ✅ Andrews marketplace added"
else
    echo "   ℹ️  May already exist, continuing..."
fi

# Add Every Inc marketplace (for Compound Engineering)
echo "2️⃣  Adding Every Inc marketplace..."
if claude plugin marketplace add https://github.com/EveryInc/every-marketplace 2>/dev/null; then
    echo "   ✅ Every Inc marketplace added"
else
    echo "   ℹ️  May already exist, continuing..."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installing Plugins"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install Andrews Plugin
echo "3️⃣  Installing Andrews Plugin..."
if claude plugin install andrews-plugin 2>/dev/null; then
    echo "   ✅ Andrews Plugin installed"
else
    echo "   ℹ️  May already be installed, continuing..."
fi

# Install Compound Engineering Plugin
echo "4️⃣  Installing Compound Engineering..."
if claude plugin install compound-engineering 2>/dev/null; then
    echo "   ✅ Compound Engineering installed"
else
    echo "   ℹ️  May already be installed, continuing..."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Installed Plugins:"
echo "  • Andrews Plugin - 11 MCP servers (API key auth, no OAuth)"
echo "  • Compound Engineering - Advanced workflows"
echo ""
echo "MCP Servers included (all API key based):"
echo "  SuperThings, Playwright, Hunter, Browserbase, Tavily,"
echo "  Zapier, Linear, Unifi, GitHub, Supabase, Vercel"
echo ""
echo "Next: Start Claude Code - the plugin will guide you through setup."
echo ""
echo "What happens on first run:"
echo "  • Builds custom MCP servers (SuperThings, Unifi)"
echo "  • Checks for deep-env (credential manager)"
echo "  • Sets up automatic sync (launchd agent)"
echo "  • Pulls credentials from iCloud (if available)"
echo ""
echo "Run 'claude' to get started!"
