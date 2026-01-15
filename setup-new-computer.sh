#!/bin/bash

# Claude Code Sync - New Computer Setup Script
# Run this on any new Mac to set up Claude Code config sync
#
# Usage: curl -fsSL https://raw.githubusercontent.com/Folly-Partners/claudesync/main/setup-new-computer.sh | bash

set -e

echo "🔧 Setting up Claude Code sync..."

# Backup existing config if present
if [ -d "$HOME/.claude" ]; then
    echo "📦 Backing up existing ~/.claude to ~/.claude.backup"
    mv "$HOME/.claude" "$HOME/.claude.backup"
fi

if [ -f "$HOME/.claude.json" ]; then
    echo "📦 Backing up existing ~/.claude.json to ~/.claude.json.backup"
    mv "$HOME/.claude.json" "$HOME/.claude.json.backup"
fi

# Clone the repo
echo "📥 Cloning claude-code-sync repository..."
git clone https://github.com/Folly-Partners/claudesync.git "$HOME/.claude"

# Create symlink for MCP config
echo "🔗 Creating symlink for MCP config..."
ln -sf "$HOME/.claude/claude.json" "$HOME/.claude.json"

# Make scripts executable
echo "🔐 Making scripts executable..."
chmod +x "$HOME/.claude/sync-claude-config.sh"
chmod +x "$HOME/.claude/skills/"*/*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$HOME/.claude/hooks/"*.py 2>/dev/null || true

# Set up deep-env for credential management
echo "🔑 Setting up deep-env for credentials..."
if [ ! -f "$HOME/.local/bin/deep-env" ]; then
    mkdir -p "$HOME/.local/bin"
    if [ -f "$HOME/Library/Mobile Documents/com~apple~CloudDocs/.deep-env/deep-env" ]; then
        cp "$HOME/Library/Mobile Documents/com~apple~CloudDocs/.deep-env/deep-env" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/deep-env"
        echo "✅ deep-env installed from iCloud"
    else
        echo "⚠️  deep-env not found in iCloud. Install manually or copy from another Mac."
    fi
fi

# Add deep-env to PATH and load credentials in shell
if ! grep -q "deep-env export" "$HOME/.zshrc" 2>/dev/null; then
    echo "" >> "$HOME/.zshrc"
    echo "# deep-env: Load credentials as environment variables" >> "$HOME/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    echo 'if command -v deep-env &> /dev/null; then' >> "$HOME/.zshrc"
    echo '  eval "$(deep-env export 2>/dev/null)"' >> "$HOME/.zshrc"
    echo 'fi' >> "$HOME/.zshrc"
    echo "✅ Added deep-env to shell profile"
fi

# Pull credentials from iCloud
if command -v deep-env &> /dev/null || [ -f "$HOME/.local/bin/deep-env" ]; then
    echo "🔄 Pulling credentials from iCloud..."
    "$HOME/.local/bin/deep-env" pull || echo "⚠️  Failed to pull credentials. Run 'deep-env pull' manually."
fi

# Get the current username for the plist
USERNAME=$(whoami)
HOME_DIR=$(eval echo ~$USERNAME)

# Create launch agent directory if it doesn't exist
mkdir -p "$HOME/Library/LaunchAgents"

# Create the launch agent plist
echo "⏰ Setting up automatic sync (on login + daily at 9am)..."
cat > "$HOME/Library/LaunchAgents/com.claude.config-sync.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.config-sync</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME_DIR}/.claude/sync-claude-config.sh</string>
    </array>

    <!-- Run on login -->
    <key>RunAtLoad</key>
    <true/>

    <!-- Also run daily at 9am -->
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME_DIR}/.claude/sync-launchd.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME_DIR}/.claude/sync-launchd.log</string>
</dict>
</plist>
EOF

# Load the launch agent
echo "🚀 Loading launch agent..."
launchctl load "$HOME/Library/LaunchAgents/com.claude.config-sync.plist"

# Run initial sync
echo "🔄 Running initial sync..."
"$HOME/.claude/sync-claude-config.sh" || true

# Configure Terminal.app for clean tab titles
echo "🖥️  Configuring Terminal.app for clean tab titles..."
defaults write com.apple.Terminal ShowActiveProcessInTitle -bool false
defaults write com.apple.Terminal ShowActiveProcessArgumentsInTitle -bool false
defaults write com.apple.Terminal ShowWorkingDirectoryInTitle -bool false
defaults write com.apple.Terminal ShowDimensionsInTitle -bool false
echo "   Terminal.app configured (restart Terminal to apply)"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Your Claude Code is now synced with:"
echo "  - MCP servers (TRMNL, SuperThings, playwright, hunter, ahrefs, browserbase)"
echo "  - Custom agents and skills"
echo "  - All your settings"
echo "  - Tab title hook (auto-sets terminal tab based on project)"
echo ""
echo "Credentials:"
echo "  - Stored in macOS Keychain via deep-env"
echo "  - Synced via iCloud (encrypted)"
echo "  - mcp.json uses \${VAR} syntax for portability"
echo ""
echo "Sync schedule:"
echo "  - On login"
echo "  - Daily at 9am"
echo ""
echo "Useful commands:"
echo "  ~/.claude/sync-claude-config.sh     # Manual sync"
echo "  deep-env list                        # View stored credentials"
echo "  deep-env pull                        # Pull credentials from iCloud"
echo "  cat ~/.claude/sync.log              # View sync log"
