#!/bin/bash

# Andrews Plugin - One-Line Installer
# Installs via Claude Code's official plugin system
#
# Usage: curl -fsSL https://raw.githubusercontent.com/Folly-Partners/claudesync/main/install.sh | bash

set -e

# Track current step for error messages
CURRENT_STEP="initialization"
trap 'echo ""; echo "Installation failed at step: $CURRENT_STEP"; echo "Run with VERBOSE=1 for more details"; exit 1' ERR

# Verbose mode for debugging
VERBOSE=${VERBOSE:-0}

log_verbose() {
    if [ "$VERBOSE" = "1" ]; then
        echo "  [debug] $*"
    fi
}

echo "Installing Andrews Plugin + Dependencies..."
echo ""

# ============================================================================
#  Pre-flight Checks
# ============================================================================

CURRENT_STEP="checking Claude CLI"

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "Claude Code CLI not found. Please install Claude Code first."
    echo "   https://claude.ai/code"
    exit 1
fi

log_verbose "Claude CLI found at: $(which claude)"

# Verify Claude CLI actually works (not just exists)
CURRENT_STEP="validating Claude CLI plugin system"

if ! claude plugin marketplace list &>/dev/null; then
    echo "Claude CLI found but plugin system not responding."
    echo "   Try running: claude --version"
    echo "   Or restart Claude Code and try again."
    exit 1
fi

log_verbose "Plugin system is working"

# ============================================================================
#  Remove OAuth Plugins (replaced by API key MCPs)
# ============================================================================

echo "----------------------------------------------------"
echo "  Removing OAuth Plugins (replaced by API key MCPs)"
echo "----------------------------------------------------"

CURRENT_STEP="removing OAuth plugins"

for plugin in github supabase vercel; do
    log_verbose "Checking if $plugin OAuth plugin is installed..."
    if claude plugin uninstall "$plugin" 2>/dev/null; then
        echo "   Removed $plugin OAuth plugin (replaced by API key MCP)"
    else
        log_verbose "$plugin not installed or already removed"
    fi
done

# ============================================================================
#  Add Marketplaces
# ============================================================================

echo ""
echo "----------------------------------------------------"
echo "  Adding Marketplaces"
echo "----------------------------------------------------"

ANDREWS_MARKETPLACE="https://raw.githubusercontent.com/Folly-Partners/claudesync/main/marketplace.json"
EVERY_MARKETPLACE="https://github.com/EveryInc/every-marketplace"

# Add Andrews Plugin marketplace
CURRENT_STEP="adding Andrews marketplace"
echo "1. Adding Andrews Plugin marketplace..."

# Capture output and exit code separately to avoid grep exit code issues
add_output=""
if add_output=$(claude plugin marketplace add "$ANDREWS_MARKETPLACE" 2>&1); then
    add_success=true
else
    add_success=false
fi
[ -n "$add_output" ] && log_verbose "$add_output"

if [ "$add_success" = "true" ]; then
    echo "   Andrews marketplace added"
elif claude plugin marketplace list 2>/dev/null | grep -qi "andrew"; then
    echo "   Andrews marketplace already registered"
else
    echo "   Failed to add Andrews marketplace"
    echo "   Check network connection and try again"
    exit 1
fi

# Add Every Inc marketplace (for Compound Engineering)
CURRENT_STEP="adding Every Inc marketplace"
echo "2. Adding Every Inc marketplace..."

add_output=""
if add_output=$(claude plugin marketplace add "$EVERY_MARKETPLACE" 2>&1); then
    add_success=true
else
    add_success=false
fi
[ -n "$add_output" ] && log_verbose "$add_output"

if [ "$add_success" = "true" ]; then
    echo "   Every Inc marketplace added"
elif claude plugin marketplace list 2>/dev/null | grep -qi "every"; then
    echo "   Every Inc marketplace already registered"
else
    echo "   Failed to add Every Inc marketplace (non-critical)"
    log_verbose "Continuing without Every Inc marketplace"
fi

# ============================================================================
#  Install Plugins
# ============================================================================

echo ""
echo "----------------------------------------------------"
echo "  Installing Plugins"
echo "----------------------------------------------------"

# Install Andrews Plugin
CURRENT_STEP="installing Andrews Plugin"
echo "3. Installing Andrews Plugin..."

install_output=""
if install_output=$(claude plugin install claudesync 2>&1); then
    install_success=true
else
    install_success=false
fi
[ -n "$install_output" ] && log_verbose "$install_output"

if [ "$install_success" = "true" ]; then
    echo "   Andrews Plugin installed"
elif claude plugin list 2>/dev/null | grep -qi "claudesync"; then
    echo "   Andrews Plugin already installed"
else
    echo "   Failed to install Andrews Plugin"
    exit 1
fi

# Install Compound Engineering Plugin
CURRENT_STEP="installing Compound Engineering"
echo "4. Installing Compound Engineering..."

install_output=""
if install_output=$(claude plugin install compound-engineering 2>&1); then
    install_success=true
else
    install_success=false
fi
[ -n "$install_output" ] && log_verbose "$install_output"

if [ "$install_success" = "true" ]; then
    echo "   Compound Engineering installed"
elif claude plugin list 2>/dev/null | grep -qi "compound"; then
    echo "   Compound Engineering already installed"
else
    echo "   Compound Engineering not available (non-critical)"
    log_verbose "Every Inc marketplace may not have been added"
fi

# ============================================================================
#  Verification
# ============================================================================

CURRENT_STEP="verifying installation"
echo ""
echo "----------------------------------------------------"
echo "  Verifying Installation"
echo "----------------------------------------------------"

# Verify claudesync is installed
if ! claude plugin list 2>/dev/null | grep -qi "claudesync"; then
    echo "   Andrews Plugin verification failed"
    echo "   Plugin may not be properly installed"
    exit 1
fi

echo "   Andrews Plugin verified"

# ============================================================================
#  Success
# ============================================================================

echo ""
echo "----------------------------------------------------"
echo "  Installation Complete!"
echo "----------------------------------------------------"
echo ""
echo "Installed Plugins:"
echo "  - Andrews Plugin - 11 MCP servers (API key auth, no OAuth)"
echo "  - Compound Engineering - Advanced workflows"
echo ""
echo "MCP Servers included (all API key based):"
echo "  SuperThings, Playwright, Hunter, Browserbase, Tavily,"
echo "  Zapier, Linear, Unifi, GitHub, Supabase, Vercel"
echo ""
echo "Next: Start Claude Code - the plugin will guide you through setup."
echo ""
echo "What happens on first run:"
echo "  - Builds custom MCP servers (SuperThings, Unifi)"
echo "  - Checks for deep-env (credential manager)"
echo "  - Sets up automatic sync (launchd agent)"
echo "  - Pulls credentials from iCloud (if available)"
echo ""
echo "Run 'claude' to get started!"
echo ""
echo "Troubleshooting:"
echo "  - Run with VERBOSE=1 for debug output"
echo "  - Check ~/.claude/plugins/ for plugin files"
echo "  - Run 'claude plugin list' to see installed plugins"
