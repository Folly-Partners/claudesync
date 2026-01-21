# ClaudeSync Custom MCP Servers

Custom MCP (Model Context Protocol) servers that extend Claude Code with specialized integrations.

## Available Servers

| Server | Purpose | Tech | Docs |
|--------|---------|------|------|
| [super-things](super-things/) | Things 3 task management with learning | TypeScript | Full docs |
| [trmnl](trmnl/) | TRMNL e-ink display management | TypeScript | [SKILL.md](trmnl/SKILL.md) |
| [unifi](unifi/) | Ubiquiti network management | Python | [SKILL.md](unifi/SKILL.md) |
| [updike-social-api](updike-social-api/) | Social media posting | TypeScript | - |
| [updike-image-gen](updike-image-gen/) | Image generation with Gemini | TypeScript | - |
| [updike-audio-gen](updike-audio-gen/) | Voice narration with ElevenLabs | TypeScript | - |
| [updike-content-archive](updike-content-archive/) | Pinecone content search | TypeScript | - |
| [updike-webflow](updike-webflow/) | Webflow CMS management | TypeScript | - |

## Server Descriptions

### SuperThings
Intelligent Things 3 integration that learns from your corrections. Includes MCP server with 19 tools plus Claude Code commands for inbox triage (`/thingsinbox`) and GTD workflow (`/gtd`).

**Key features:**
- Learning system for title transforms and project hints
- Silent AppleScript operations (no focus stealing)
- URL resolution and research caching
- Batch task processing

### TRMNL
Manage TRMNL e-ink displays. Push custom messages, control playlists, check device status.

**Key features:**
- Push webhook content to display
- Manage playlist items
- Check battery and signal
- Update plugin data

### UniFi
Manage Ubiquiti UniFi networks. Monitor devices and clients, check health, restart APs, block/unblock clients.

**Key features:**
- List devices by type (AP, switch, gateway)
- Monitor connected clients
- Network health status
- Guest authorization with limits

### Updike Servers (5)

Suite of MCP servers for the Updike social content engine:

**updike-social-api** — Post to X/Twitter, LinkedIn, Instagram, and Threads. OAuth 2.0 with auto-refresh.

**updike-image-gen** — Generate branded quote cards and carousels using Gemini AI. Supports Andrew's warm earthy palette.

**updike-audio-gen** — Convert text to speech using ElevenLabs with Andrew's cloned voice.

**updike-content-archive** — Semantic search across 6,600+ pieces (tweets, newsletters, book chapters, YouTube transcripts) via Pinecone.

**updike-webflow** — Full Webflow API v2 access with 63 tools for CMS management.

## Quick Setup

### 1. Store Credentials

All servers use deep-env for credential storage:

```bash
# SuperThings
deep-env store THINGS_AUTH_TOKEN "your-token"

# TRMNL
deep-env store TRMNL_API_KEY "user_xxxxx"

# UniFi
deep-env store UNIFI_HOST "controller-ip"
deep-env store UNIFI_USERNAME "admin"
deep-env store UNIFI_PASSWORD "password"
deep-env store UNIFI_VERSION "UDMP-unifiOS"

# Push to iCloud for other Macs
deep-env push
```

### 2. Configure MCP

Servers are configured in `~/.mcp.json` or `~/claudesync/.mcp.json`:

```json
{
  "mcpServers": {
    "super-things": {
      "command": "node",
      "args": ["${HOME}/claudesync/servers/super-things/dist/index.js"]
    }
  }
}
```

### 3. Verify Installation

After restarting Claude Code, servers appear in the MCP tools list.

## Server Structure

Each server directory contains:

```
server-name/
├── README.md           # Full documentation
├── SKILL.md            # Claude instructions (when to use)
├── src/                # Source code
├── dist/               # Compiled output (TypeScript)
└── package.json        # Dependencies (TypeScript)
```

Or for Python servers:

```
server-name/
├── README.md
├── SKILL.md
├── server.py           # Main server
├── requirements.txt    # Dependencies
└── setup.py            # Install script
```

## Creating New Servers

1. Create directory under `servers/`
2. Implement MCP server using SDK
3. Add README.md with setup instructions
4. Add SKILL.md with Claude usage instructions
5. Configure in `.mcp.json`
6. Push to sync across Macs

See [super-things](super-things/) for a complete TypeScript example.
