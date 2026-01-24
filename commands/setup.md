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

### 2. MCP Server Selection

Use AskUserQuestion with `multiSelect: true` to let the user choose which MCP servers to enable:

```
"Which MCP servers would you like to enable?"

Options (multiSelect: true):
- Playwright: Browser automation and screenshots (no API key needed)
- Tavily: AI-powered web search
- SuperThings: Things 3 task management
- Hunter: Find and verify email addresses
- Browserbase: Cloud browser automation
- Linear: Issue and project tracking
- Ahrefs: SEO and competitor analysis
- GitHub: Repository operations
- Supabase: Database management
- Vercel: Deployment platform
- Unifi: Network management
- TRMNL: Smart display integration
```

Store selection in deep-env:
```bash
deep-env store ENABLED_MCP_SERVERS "playwright,tavily,superthings,github"
deep-env push
```

**Only prompt for credentials for selected servers** in step 5.

### 3. deep-env (Credential Manager)
- **Check:** `command -v deep-env` or `~/.local/bin/deep-env`
- **Install from iCloud:** `mkdir -p ~/.local/bin && cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/.deep-env/deep-env ~/.local/bin/ && chmod +x ~/.local/bin/deep-env`
- **Pull credentials:** `deep-env pull` (will prompt for sync password)

### 4. Shell Configuration
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

### 5. Credentials (Based on MCP Selection)

Only prompt for credentials for MCP servers the user selected in step 2:

| MCP Server | Required Credential |
|------------|---------------------|
| Tavily | `TAVILY_API_KEY` |
| SuperThings | `THINGS_AUTH_TOKEN` |
| Hunter | `HUNTER_API_KEY` |
| Browserbase | `BROWSERBASE_API_KEY`, `BROWSERBASE_PROJECT_ID` |
| Linear | `LINEAR_ACCESS_TOKEN` |
| Ahrefs | (uses HTTP endpoint, no key needed) |
| GitHub | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| Supabase | `SUPABASE_ACCESS_TOKEN` |
| Vercel | `VERCEL_API_TOKEN` |
| Unifi | `UNIFI_HOST`, `UNIFI_USERNAME`, `UNIFI_PASSWORD` |
| TRMNL | `TRMNL_API_KEY` |
| Playwright | (no credentials needed) |

For each selected server that needs credentials:
1. Check if already set: `deep-env get KEY_NAME`
2. If missing, ask user for the value
3. Store: `deep-env store KEY_NAME "value"`
4. After all credentials: `deep-env push`

### 6. Updike MCP Servers

The 5 updike MCP servers require the `~/updike` repository to be cloned and built.

- **Check:** `ls ~/updike/mcp-servers/social-api/src/index.ts`
- **Clone if missing:**
```bash
git clone https://github.com/Folly-Partners/updike.git ~/updike
```
- **Build webflow server** (only server requiring compilation):
```bash
cd ~/updike/mcp-servers/webflow && npm install && npm run build
```

**Verification:**
```bash
# Check all 5 servers exist
ls ~/updike/mcp-servers/social-api/src/index.ts
ls ~/updike/mcp-servers/image-gen/src/index.ts
ls ~/updike/mcp-servers/audio-gen/src/index.ts
ls ~/updike/mcp-servers/content-archive/src/index.ts
ls ~/updike/mcp-servers/webflow/dist/index.js
```

### 7. Marketplace Registration
- **Check:** `ls ~/.claude/plugins/marketplaces/claudesync.json`
- **Add:** `claude plugin marketplace add https://raw.githubusercontent.com/Folly-Partners/claudesync/main/marketplace.json`

## Interactive Flow

Ask the user about each missing component using AskUserQuestion with options like:
- "Install now"
- "Skip for now"
- "I'll do it manually"

For credentials, if deep-env is available, offer to show which are missing and help store new ones.
