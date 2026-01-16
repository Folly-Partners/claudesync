---
name: setup
description: Interactive setup wizard for ClaudeSync - configures identity, deep-env, sync agent, and credentials
---

# ClaudeSync Setup

Run the setup wizard to ensure this Mac is fully configured.

## Instructions

1. First, run the setup check to see current status:
```bash
~/claudesync/hooks/setup-wizard.sh --force
```

2. Based on the output, guide the user through fixing any issues interactively.

## Setup Components

### 1. Git Identity (REQUIRED FIRST)

Ask the user for their git commit identity using AskUserQuestion:
- **Name:** "What name should be used for git commits?"
- **Email:** "What email should be used for git commits?"

Store in deep-env:
```bash
deep-env store GIT_COMMIT_NAME "User Name"
deep-env store GIT_COMMIT_EMAIL "user@example.com"
deep-env push
```

Also configure git locally:
```bash
git config --global user.name "User Name"
git config --global user.email "user@example.com"
```

### 2. deep-env (Credential Manager)
- **Check:** `command -v deep-env` or `~/.local/bin/deep-env`
- **Install from iCloud:** `mkdir -p ~/.local/bin && cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/ && chmod +x ~/.local/bin/deep-env`
- **Pull credentials:** `deep-env pull` (will prompt for sync password)

### 2. Shell Configuration
- **Check:** `grep "deep-env export" ~/.zshrc`
- **Add if missing:**
```bash
echo '' >> ~/.zshrc
echo '# deep-env: Load credentials as environment variables' >> ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
echo 'if command -v deep-env &> /dev/null; then' >> ~/.zshrc
echo '  eval "$(deep-env export 2>/dev/null)"' >> ~/.zshrc
echo 'fi' >> ~/.zshrc
```

### 3. Sync Agent (LaunchD)
- **Check:** `ls ~/Library/LaunchAgents/com.claude.config-sync.plist`
- **Install:** Run the setup script to create and load the plist
- **Load if exists but not running:** `launchctl load ~/Library/LaunchAgents/com.claude.config-sync.plist`

### 4. Credentials
Required credentials for full functionality:
- `HUNTER_API_KEY` - Hunter.io email finder
- `TAVILY_API_KEY` - Tavily search API
- `THINGS_AUTH_TOKEN` - Things 3 integration
- `BROWSERBASE_API_KEY` - Browserbase cloud browser
- `ZAPIER_MCP_TOKEN` - Zapier automation

Check with: `deep-env list`
Add with: `deep-env store KEY_NAME "value"`
Push to iCloud: `deep-env push`

### 5. Marketplace Registration
- **Check:** `ls ~/.claude/plugins/marketplaces/claudesync.json`
- **Add:** `claude plugin marketplace add https://raw.githubusercontent.com/Folly-Partners/claudesync/main/marketplace.json`

## Interactive Flow

Ask the user about each missing component using AskUserQuestion with options like:
- "Install now"
- "Skip for now"
- "I'll do it manually"

For credentials, if deep-env is available, offer to show which are missing and help store new ones.
