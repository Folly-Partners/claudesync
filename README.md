```
   _____ _                 _      _____
  / ____| |               | |    / ____|
 | |    | | __ _ _   _  __| | ___| (___  _   _ _ __   ___
 | |    | |/ _` | | | |/ _` |/ _ \\___ \| | | | '_ \ / __|
 | |____| | (_| | |_| | (_| |  __/____) | |_| | | | | (__
  \_____|_|\__,_|\__,_|\__,_|\___|_____/ \__, |_| |_|\___|
                                          __/ |
                                         |___/
```

# ClaudeSync

**One plugin. All your Macs. Always in sync.**

ClaudeSync keeps your Claude Code setup identical across every Mac you own. MCP servers, credentials, custom commands, AI agents—set it up once, use it everywhere.

---

## The Problem

You have multiple Macs. You've configured Claude Code beautifully on one of them:
- API keys stored somewhere
- MCP servers configured just right
- Custom workflows and commands
- That one setting you can never remember

Now do it again on your other Mac. And again. And keep them all in sync when you change something.

**ClaudeSync fixes this.**

---

## Quick Start

```bash
# In Claude Code, run:
/plugin marketplace add Folly-Partners/claudesync
/plugin install claudesync@Folly
```

That's it. You now have access to 16 MCP servers, 13 commands, 6 skills, and 3 custom agents.

---

## What You Get

### MCP Servers (16)

| Server | What it does |
|--------|--------------|
| **SuperThings** | Control Things 3 directly from Claude |
| **Playwright** | Automate browsers, take screenshots, test websites |
| **Tavily** | Search the web with AI-powered results |
| **Hunter** | Find anyone's email address |
| **Browserbase** | Cloud browsers that don't get blocked |
| **Linear** | Manage issues and projects |
| **Ahrefs** | SEO data and competitor analysis |
| **TRMNL** | Push content to your TRMNL display |
| **Unifi** | Manage your UniFi network |
| **GitHub** | Repository operations without OAuth hassle |
| **Supabase** | Database queries and management |
| **updike-social-api** | Post to X, LinkedIn, Instagram, Threads |
| **updike-image-gen** | Generate quote cards, carousels, branded images |
| **updike-audio-gen** | Generate voice narration with ElevenLabs |
| **updike-content-archive** | Search 6,600+ pieces of content via Pinecone |
| **updike-webflow** | Manage Webflow CMS with 63 tools |

Full setup guide: [MCP-SERVERS.md](MCP-SERVERS.md)

### Commands (13)

**Git shortcuts:**
- `/commit` — Stage everything, generate a smart commit message, done
- `/push` — Same as commit, but also pushes
- `/scommit` — Pick specific files to commit
- `/spush` — Pick specific files, commit, and push

**Sync & maintenance:**
- `/github-sync` — Sync all your git repos at once
- `/setup` — Interactive setup wizard
- `/sync-env` — Generate `.env.local` from your stored credentials
- `/add-credential KEY value` — Store a new API key securely

**Power tools:**
- `/test [project]` — Run tests, find bugs, fix them automatically
- `/deepcodereview [project]` — Hours-long autonomous code review

**Communication:**
- `/email` — Rapid-fire email processing with AI-generated drafts
- `/texts` — Process text messages with AI responses

### Skills (6)

**deep-env** — The secret sauce. Stores all your API keys in macOS Keychain, syncs them encrypted via iCloud. One password prompt. Ever.

```bash
deep-env store OPENAI_KEY "sk-..."   # Store it
deep-env push                         # Sync to iCloud
deep-env sync .                       # Generate .env.local
```

**github-sync** — Checks all your git repos daily. Uncommitted changes? It'll tell you. Remote has updates? It'll pull them.

**enhanced-planning** — When Claude plans a feature, it runs parallel research: codebase patterns, external docs, best practices. All at once.

**history-pruner** — Conversation history getting huge? This cleans it up while keeping what matters.

**mcp-sync** — Validates your MCP config. Catches broken `${VAR}` expansions before they bite you.

**updike** — Social content engine. Post to platforms, search content archives, generate images and audio.

### Agents (3)

**inbox-task-manager** — Say "let's go" and it triages your Things 3 inbox. Categorizes, rewrites for clarity, moves to the right projects.

**email-response-processor** — Handles those "just reply with A, B, or C" emails automatically.

**wardrobe-cataloger** — Take photos of clothes, it catalogs them to a spreadsheet. (Yes, really.)

---

## How Sync Works

```
┌─────────────┐     ┌──────────┐     ┌─────────────┐
│   Mac A     │────▶│  GitHub  │────▶│   Mac B     │
│             │     │          │     │             │
│ Edit plugin │     │ Central  │     │ Auto-update │
│ git push    │     │  repo    │     │ via plugin  │
└─────────────┘     └──────────┘     └─────────────┘
```

**Plugin updates:** Edit on any Mac → push to GitHub → other Macs get it automatically

**Credentials:** Stored in Keychain → encrypted to iCloud → available everywhere

**No manual copying. No forgotten configs. Just works.**

---

## Setup

### New Installation

```bash
/plugin marketplace add Folly-Partners/claudesync
/plugin install claudesync@Folly
```

Then run the setup wizard:
```bash
/setup
```

It'll walk you through:
1. Installing the `deep-env` credential manager
2. Configuring your shell
3. Setting up daily sync
4. Storing your API keys

### Adding to Another Mac

```bash
# 1. Install the plugin (same as above)
/plugin marketplace add Folly-Partners/claudesync
/plugin install claudesync@Folly

# 2. Pull your credentials from iCloud
deep-env pull

# 3. Done. Everything's synced.
```

### Manual Setup (if you prefer)

```bash
git clone https://github.com/Folly-Partners/claudesync.git ~/claudesync
cd ~/claudesync

# Build the custom MCP servers
cd servers/super-things && npm install && npm run build
cd ../unifi && python3 -m venv venv && ./venv/bin/pip install -r requirements.txt
```

---

## Credential Management

ClaudeSync includes `deep-env`, a credential manager that actually makes sense:

```bash
# Store credentials (goes to macOS Keychain)
deep-env store ANTHROPIC_API_KEY "sk-ant-..."
deep-env store OPENAI_KEY "sk-..."
deep-env store SUPABASE_URL "https://..."

# Sync to iCloud (encrypted, for your other Macs)
deep-env push

# On another Mac, pull them down
deep-env pull

# Generate .env.local for any project
cd ~/my-project
deep-env sync .
```

**Why it's good:**
- Single Keychain entry (one password prompt, ever)
- AES-256 encrypted iCloud sync
- Project-specific credential assignment
- Works offline after initial sync

---

## File Structure

```
~/claudesync/
├── commands/        # 13 slash commands
├── skills/          # 6 reusable workflows
├── agents/          # 3 custom AI agents
├── servers/         # Custom MCP servers
│   ├── super-things/   # Things 3 (TypeScript)
│   ├── trmnl/          # TRMNL display (TypeScript)
│   ├── unifi/          # Network management (Python)
│   └── updike-*/       # Updike social engine (5 servers)
├── hooks/           # Session start & prompt hooks
├── mcp.json         # MCP server configuration
└── CLAUDE.md        # Instructions for Claude
```

---

## Troubleshooting

**Plugin not showing up?**
```bash
cat ~/.claude/settings.json | grep claudesync
# Should show: "claudesync@Folly": true
```

**MCP servers not loading?**
```bash
# Check if SuperThings is built
ls ~/claudesync/servers/super-things/dist/index.js

# If missing, build it
cd ~/claudesync/servers/super-things && npm run build
```

**Credentials not syncing?**
```bash
deep-env list      # See what's stored
deep-env validate  # Check for corruption
deep-env pull      # Pull from iCloud
```

**Git sync issues?**
```bash
~/claudesync/skills/github-sync/git-sync-check.sh --force
```

---

## Version History

| Version | Changes |
|---------|---------|
| **1.8.0** | Added Updike social engine, /email and /texts commands, 5 MCP servers |
| **1.4.0** | Fixed marketplace schema, cleaned up sensitive files |
| **1.3.0** | Major cleanup, improved documentation |
| **1.2.0** | Auto-discovery for git repos |
| **1.1.0** | Initial marketplace release |

---

## Links

- **Marketplace:** [Folly-Partners/claudesync](https://github.com/Folly-Partners/claudesync)
- **MCP Server Guide:** [MCP-SERVERS.md](MCP-SERVERS.md)
- **Claude Code Docs:** [code.claude.com/docs](https://code.claude.com/docs)

---

*Part of the Folly marketplace. Built by Andrew Wilkinson.*
