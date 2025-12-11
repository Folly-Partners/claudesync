#!/bin/bash

# Claude Code Sync - New Computer Setup Script
# Run this on any new Mac to set up Claude Code config sync
#
# Usage: curl -fsSL https://raw.githubusercontent.com/awilkinson/claude-code-sync/main/setup-new-computer.sh | bash

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
git clone https://github.com/awilkinson/claude-code-sync.git "$HOME/.claude"

# Create symlink for MCP config
echo "🔗 Creating symlink for MCP config..."
ln -sf "$HOME/.claude/claude.json" "$HOME/.claude.json"

# Make sync script executable
echo "🔐 Making sync script executable..."
chmod +x "$HOME/.claude/sync-claude-config.sh"

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

echo ""
echo "✅ Setup complete!"
echo ""
echo "Your Claude Code is now synced with:"
echo "  - 7 MCP servers (things-mcp, webflow, browserbase, tavily, zapier, ahrefs, xero)"
echo "  - 3 custom agents (email-response-processor, inbox-task-manager, wardrobe-cataloger)"
echo "  - All your settings, history, and todos"
echo ""
echo "Sync schedule:"
echo "  - On login"
echo "  - Daily at 9am"
echo ""
echo "Useful commands:"
echo "  ~/.claude/sync-claude-config.sh     # Manual sync"
echo "  cat ~/.claude/sync.log              # View sync log"
echo "  launchctl start com.claude.config-sync  # Trigger sync now"
