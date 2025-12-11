# Claude Code Sync Setup

## Repository Setup Complete ✅
- Local git repository initialized
- .gitignore configured to exclude sensitive data
- Initial commit created with your Claude Code settings

## Manual Steps Required:

### 1. Create GitHub Repository
Go to https://github.com/new and create:
- Repository name: `claude-code-config`
- Description: `Claude Code settings and configuration sync across multiple computers`
- **Make it Private** ✅
- Don't initialize with README/license

### 2. Push to GitHub
Once you've created the repo, run:
```bash
cd ~/.claude
git push -u origin main
```

## Syncing to Other Computers

### First time setup on a new computer:
```bash
# Clone the repository
git clone https://github.com/andrewwilkinson/claude-code-config.git ~/.claude

# Make sure Claude Code can find the config
claude --version  # Should work immediately
```

### Regular sync workflow:
```bash
# On any computer, to sync changes TO GitHub:
cd ~/.claude
git add .
git commit -m "Update Claude Code settings"
git push

# To sync changes FROM GitHub:
cd ~/.claude
git pull
```

## What Gets Synced:
- ✅ Settings (`settings.local.json`)
- ✅ Plugins configuration
- ✅ Todo lists and project history
- ❌ Debug logs (excluded for privacy)
- ❌ Session data (excluded for privacy)
- ❌ Downloads folder (excluded for privacy)

Your Claude Code configuration is now ready to sync across all your computers!