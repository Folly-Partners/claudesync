#!/bin/bash
# Migration script for existing claude-code-sync setups
# Transforms to the new andrews-plugin structure

set -e

OLD_LOCATION="$HOME/.claude"
NEW_LOCATION="$HOME/andrews-plugin"

echo "=========================================="
echo "Andrew's Plugin Migration Script"
echo "=========================================="
echo ""

# Detect current setup
if [ -d "$NEW_LOCATION/.git" ]; then
    echo "✓ Already at new location: $NEW_LOCATION"
    REPO_DIR="$NEW_LOCATION"
    NEEDS_MOVE=false
elif [ -d "$OLD_LOCATION/.git" ]; then
    echo "✓ Found repo at old location: $OLD_LOCATION"
    REPO_DIR="$OLD_LOCATION"
    NEEDS_MOVE=true
else
    echo "ERROR: Could not find git repository at $OLD_LOCATION or $NEW_LOCATION"
    echo "This script is for migrating existing claude-code-sync setups."
    exit 1
fi

cd "$REPO_DIR"

echo ""
echo "Step 1: Pulling latest changes from GitHub..."

# Check git remote and fix if needed
REMOTE_URL=$(git remote get-url origin)
if [[ "$REMOTE_URL" == *"claude-code-sync"* ]]; then
    echo "Updating remote URL to andrews-plugin..."
    git remote set-url origin https://github.com/Folly-Partners/andrews-plugin.git
fi

# Try to pull
if git pull origin main; then
    echo "✓ Successfully pulled latest changes"
else
    echo "WARNING: Pull failed. Attempting to fix..."
    # Check if it's an SSH issue
    if [[ "$REMOTE_URL" == git@github.com:* ]]; then
        echo "Switching from SSH to HTTPS..."
        git remote set-url origin https://github.com/Folly-Partners/andrews-plugin.git
        git pull origin main
    else
        echo "ERROR: Failed to pull changes from GitHub"
        exit 1
    fi
fi

# Verify plugin files are present
if [ ! -f "manifest.json" ] || [ ! -f ".mcp.json" ]; then
    echo "ERROR: Plugin files not found after pull. Something went wrong."
    exit 1
fi

echo "✓ Plugin files detected"

# Move to new location if needed
if [ "$NEEDS_MOVE" = true ]; then
    echo ""
    echo "Step 2: Moving repository to new location..."

    # Check if new location already exists
    if [ -d "$NEW_LOCATION" ] || [ -L "$NEW_LOCATION" ]; then
        echo "WARNING: $NEW_LOCATION already exists"
        echo "Please remove or rename it first, then run this script again."
        exit 1
    fi

    # Move the repo
    echo "Moving $OLD_LOCATION → $NEW_LOCATION..."
    mv "$OLD_LOCATION" "$NEW_LOCATION"

    # Create minimal ~/.claude for settings
    echo "Creating minimal ~/.claude directory for settings..."
    mkdir -p "$OLD_LOCATION"

    # Create symlink for backwards compatibility (optional)
    ln -s "$NEW_LOCATION" "$OLD_LOCATION/andrews-plugin"

    echo "✓ Moved to $NEW_LOCATION"

    # Update REPO_DIR for remaining steps
    REPO_DIR="$NEW_LOCATION"
    cd "$REPO_DIR"
fi

echo ""
echo "Step 3: Checking server directories..."

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
echo "Step 4: Building dependencies and setting up services..."

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

# Run setup
./scripts/setup.sh

# Note: Marketplace config is in ~/andrews-plugin/settings.json
# which setup.sh symlinked to ~/.claude/settings.json
# No need to create settings.local.json (it would override the symlink)

# Clean up any stale settings.local.json from previous migrations
if [ -f "$OLD_LOCATION/settings.local.json" ]; then
    echo "Removing stale settings.local.json (config is now in settings.json)..."
    rm "$OLD_LOCATION/settings.local.json"
    echo "✓ Cleaned up settings.local.json"
fi

echo ""
echo "Step 5: Running health check..."
eval "$(deep-env export 2>/dev/null || true)"
./scripts/doctor.sh

echo ""
echo "=========================================="
echo "Migration Complete!"
echo "=========================================="
echo ""
echo "Your setup has been successfully migrated to the new plugin structure."
echo ""
echo "Location: $NEW_LOCATION"
echo ""
echo "What changed:"
echo "  ✓ Repository moved to ~/andrews-plugin"
echo "  ✓ SuperThings bundled into plugin (servers/super-things/)"
echo "  ✓ Unifi server bundled into plugin (servers/unifi/)"
echo "  ✓ Auto-sync LaunchAgent updated"
echo "  ✓ Settings symlinked: ~/.claude/settings.json → ~/andrews-plugin/settings.json"
echo ""
echo "Next: Restart Claude Code for changes to take effect"
