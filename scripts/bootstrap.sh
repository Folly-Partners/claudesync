#!/bin/bash
# Bootstrap Andrew's Plugin on a new Mac
set -e

echo "Bootstrapping Andrew's Plugin..."

# 1. Install deep-env if needed
if ! command -v deep-env &> /dev/null; then
    echo "Installing deep-env..."
    mkdir -p ~/.local/bin
    ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    if [ -f "$ICLOUD/.deep-env/deep-env" ]; then
        cp "$ICLOUD/.deep-env/deep-env" ~/.local/bin/
        chmod +x ~/.local/bin/deep-env
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "ERROR: deep-env not found in iCloud. Copy from another Mac first."
        exit 1
    fi
fi

# 2. Pull credentials
echo "Pulling credentials from iCloud..."
deep-env pull

# 3. Clone plugin
echo "Cloning plugin..."
git clone git@github.com:Folly-Partners/andrews-plugin.git ~/andrews-plugin

# 4. Run setup
echo "Running setup..."
cd ~/andrews-plugin
./scripts/setup.sh

# 5. Set up minimal ~/.claude with marketplace
mkdir -p ~/.claude
cat > ~/.claude/settings.local.json << 'EOF'
{
  "pluginMarketplaces": [
    "https://raw.githubusercontent.com/Folly-Partners/andrews-plugin/main/marketplace.json"
  ],
  "enabledPlugins": {
    "andrews-plugin@andrews-marketplace": true
  }
}
EOF

# 6. Add deep-env to shell if not present
if ! grep -q "deep-env export" ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo '# deep-env: Load credentials as environment variables' >> ~/.zshrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo 'if command -v deep-env &> /dev/null; then eval "$(deep-env export 2>/dev/null)"; fi' >> ~/.zshrc
fi

echo ""
echo "Done! Run 'source ~/.zshrc' then 'claude' to start."
echo "Verify with: ~/andrews-plugin/scripts/doctor.sh"
