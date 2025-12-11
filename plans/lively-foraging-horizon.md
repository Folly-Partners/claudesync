# Plan: Sync This Claude Code Instance to GitHub Repo

## Goal
Push this machine's Claude Code configuration to overwrite the `awilkinson/claude-code-sync` repo, then set up the sync script for ongoing synchronization.

## What Will Be Synced (from this machine)

| Item | Path | Description |
|------|------|-------------|
| **MCP Servers** | `~/.claude.json` | All 7 MCP servers with auth tokens (things-mcp, webflow, browserbase, tavily, zapier, ahrefs, xero) |
| Settings | `~/.claude/settings.local.json` | Which MCP servers are enabled + permissions |
| Agents | `~/.claude/agents/` | 3 custom agents (email-response-processor, inbox-task-manager, wardrobe-cataloger) |
| Plugins | `~/.claude/plugins/` | Plugin configuration |
| Plans | `~/.claude/plans/` | Saved planning documents |
| Todos | `~/.claude/todos/` | Task lists |
| Projects | `~/.claude/projects/` | Conversation history |
| File History | `~/.claude/file-history/` | File access history |
| History | `~/.claude/history.jsonl` | Chat history |

## What Will NOT Be Synced (excluded via .gitignore)

- `~/.claude/.credentials.json` - OAuth session tokens (would cause conflicts)
- `~/.claude/debug/` - Debug logs
- `~/.claude/shell-snapshots/` - Session-specific
- `~/.claude/session-env/` - Session-specific
- `~/.claude/statsig/` - Analytics/telemetry
- `*.log`, `*.tmp` - Temporary files

## Steps

### Step 1: Initialize Git in ~/.claude
```bash
cd ~/.claude
git init
git remote add origin https://github.com/awilkinson/claude-code-sync.git
```

### Step 2: Pull the Sync Script and .gitignore from Repo (preserve them)
```bash
git fetch origin main
git checkout origin/main -- sync-claude-config.sh
git checkout origin/main -- sync-setup.md
git checkout origin/main -- .gitignore
```

### Step 3: Update .gitignore
Add `.credentials.json` to protect OAuth session tokens:
```
.credentials.json
```

### Step 4: Symlink ~/.claude.json into the repo
Since `~/.claude.json` lives outside `~/.claude/`, we'll symlink it in:
```bash
# Copy the actual file into the repo directory
cp ~/.claude.json ~/.claude/claude.json

# Replace the original with a symlink to the repo copy
mv ~/.claude.json ~/.claude.json.backup
ln -s ~/.claude/claude.json ~/.claude.json
```

This way:
- The MCP config lives in `~/.claude/claude.json` (synced via git)
- `~/.claude.json` is a symlink pointing to it (Claude Code still finds it)
- On other computers, after cloning, run the same symlink command

### Step 5: Force Push This Config to Repo
```bash
cd ~/.claude
git add .
git commit -m "Sync from primary machine with MCP servers

Includes:
- 7 MCP servers with auth (things-mcp, webflow, browserbase, tavily, zapier, ahrefs, xero)
- 3 custom agents (email, inbox-task-manager, wardrobe-cataloger)
- Full project history and todos

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

git push --force origin main
```

### Step 6: Verify Sync Script is Executable
```bash
chmod +x ~/.claude/sync-claude-config.sh
```

### Step 7: Update Sync Script
Modify `sync-claude-config.sh` to also sync the `claude.json` file (it should already be included via `git add .`)

### Step 8: Test the Setup
```bash
~/.claude/sync-claude-config.sh
```

## Impact on Other Computers

When other computers pull this config:
- They will get all 7 MCP servers with auth tokens pre-configured
- They will receive the 3 custom agents
- Their local permissions will be updated
- **Required setup on other machines after pull:**
  ```bash
  # Create symlink so Claude Code finds the MCP config
  ln -sf ~/.claude/claude.json ~/.claude.json
  ```

## Files Modified

| File | Action |
|------|--------|
| `~/.claude.json` | Becomes symlink to `~/.claude/claude.json` |
| `~/.claude/claude.json` | New file (copy of MCP config) |
| `~/.claude/.gitignore` | Update to add `.credentials.json` |
| `~/.claude/` | Initialize as git repo |
| GitHub repo | Force push to overwrite |

## Rollback

If something goes wrong:
```bash
# Restore original ~/.claude.json from backup
rm ~/.claude.json
mv ~/.claude.json.backup ~/.claude.json

# Or reset git repo
cd ~/.claude
git log  # find previous commit
git reset --hard <commit-hash>
git push --force origin main
```

## Setup Script for Other Computers

After cloning on a new machine, run:
```bash
cd ~
git clone https://github.com/awilkinson/claude-code-sync.git .claude
ln -sf ~/.claude/claude.json ~/.claude.json
chmod +x ~/.claude/sync-claude-config.sh
```
