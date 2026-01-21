# MCP Servers Reference

This document describes each MCP server included in Andrews Plugin, their requirements, and how to troubleshoot issues.

## Quick Reference

| Server | Type | Auth | Required Env Vars |
|--------|------|------|-------------------|
| SuperThings | stdio | API Key | `THINGS_AUTH_TOKEN` |
| Playwright | stdio | None | - |
| Hunter | SSE | API Key | `HUNTER_API_KEY` |
| Browserbase | stdio | API Key | `BROWSERBASE_API_KEY`, `BROWSERBASE_PROJECT_ID` |
| Tavily | stdio | API Key | `TAVILY_API_KEY` |
| Pipedream | HTTP | API Key | `PIPEDREAM_API_KEY` |
| Linear | stdio | API Key | `LINEAR_ACCESS_TOKEN` |
| Unifi | stdio | Credentials | `UNIFI_HOST`, `UNIFI_USERNAME`, `UNIFI_PASSWORD` |
| GitHub | stdio | PAT | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| Supabase | stdio | API Key | `SUPABASE_ACCESS_TOKEN` |
| Vercel | stdio | API Token | `VERCEL_API_TOKEN` |
| updike-social-api | stdio | OAuth 2.0 | (stored in keychain) |
| updike-image-gen | stdio | API Key | `GEMINI_API_KEY` |
| updike-audio-gen | stdio | API Key | (stored in keychain) |
| updike-content-archive | stdio | API Key | `PINECONE_API_KEY`, `ANTHROPIC_API_KEY` |
| updike-webflow | stdio | API Key | (stored in keychain) |

---

## Server Details

### SuperThings

**Purpose**: Things 3 task management integration.

**Requirements**:
- macOS with Things 3 installed
- `THINGS_AUTH_TOKEN` from Things 3 settings

**Setup**:
```bash
# Get token from Things 3 → Settings → Enable Things URLs → Copy auth token
deep-env store THINGS_AUTH_TOKEN "your-token-here"
```

**Build Required**: Yes - runs from `servers/super-things/dist/index.js`
```bash
cd servers/super-things && npm install && npm run build
```

**Common Errors**:
- `Cannot find module`: Build not complete, run `npm run build`
- `Invalid auth token`: Token incorrect or expired, re-copy from Things 3

---

### Playwright

**Purpose**: Browser automation for web scraping and testing.

**Requirements**:
- None (uses npx to install on-demand)

**Setup**: No configuration needed.

**Common Errors**:
- `Browser not found`: Run `npx playwright install chromium`
- Slow first run: npm is downloading the package

---

### Hunter

**Purpose**: Email finding and verification.

**Requirements**:
- Hunter.io account
- `HUNTER_API_KEY` from https://hunter.io/api-keys

**Setup**:
```bash
deep-env store HUNTER_API_KEY "your-api-key"
```

**Connection Type**: SSE (Server-Sent Events) to `https://mcp.hunter.io/sse`

**Common Errors**:
- `401 Unauthorized`: Invalid or expired API key
- `429 Too Many Requests`: Rate limited, wait and retry

---

### Browserbase

**Purpose**: Cloud browser automation with anti-detection.

**Requirements**:
- Browserbase account
- `BROWSERBASE_API_KEY` and `BROWSERBASE_PROJECT_ID`

**Setup**:
```bash
deep-env store BROWSERBASE_API_KEY "your-api-key"
deep-env store BROWSERBASE_PROJECT_ID "your-project-id"
```

**Common Errors**:
- `Invalid project ID`: Check project ID in Browserbase dashboard
- Connection timeout: Network issue or Browserbase service down

---

### Tavily

**Purpose**: AI-powered web search.

**Requirements**:
- Tavily account
- `TAVILY_API_KEY` from https://tavily.com

**Setup**:
```bash
deep-env store TAVILY_API_KEY "tvly-xxxxxxxx"
```

**Common Errors**:
- `Invalid API key`: Key doesn't start with `tvly-`
- Rate limited: Free tier has limited requests

---

### Pipedream

**Purpose**: Integration with 10,000+ pre-built tools across 3,000+ APIs.

**Why Pipedream**:
- Better security: Credentials isolated from AI models
- SOC 2 Type II, HIPAA, GDPR compliant
- Simple API key auth (no OAuth dance)

**Requirements**:
- Pipedream account
- `PIPEDREAM_API_KEY` from Pipedream dashboard

**Setup**:
```bash
# Get API key from Pipedream → Settings → API Keys
deep-env store PIPEDREAM_API_KEY "pd_xxxxxx"
```

**Connection Type**: HTTP to `https://mcp.pipedream.com/mcp/`

**Common Errors**:
- `401 Unauthorized`: Invalid API key
- `403 Forbidden`: Key doesn't have required permissions

---

### Linear

**Purpose**: Issue tracking and project management.

**Requirements**:
- Linear account
- `LINEAR_ACCESS_TOKEN` (personal API key)

**Setup**:
```bash
# Get from Linear → Settings → API → Personal API Keys
deep-env store LINEAR_ACCESS_TOKEN "lin_api_xxxxxx"
```

**Common Errors**:
- `Unauthorized`: Token expired, regenerate in Linear
- `Not found`: Check workspace permissions

---

### Unifi

**Purpose**: Ubiquiti UniFi network management.

**Requirements**:
- UniFi Controller access
- Python 3.10+
- `UNIFI_HOST`, `UNIFI_USERNAME`, `UNIFI_PASSWORD`

**Setup**:
```bash
deep-env store UNIFI_HOST "https://192.168.1.1:8443"
deep-env store UNIFI_USERNAME "admin"
deep-env store UNIFI_PASSWORD "your-password"
```

**Build Required**: Yes - needs Python venv
```bash
cd servers/unifi && python3 -m venv venv && ./venv/bin/pip install fastmcp
```

**Common Errors**:
- `ModuleNotFoundError: fastmcp`: venv not created, run setup
- `SSL certificate verify failed`: Self-signed cert, may need to disable verification
- `Connection refused`: Wrong host or controller not running

---

### GitHub

**Purpose**: GitHub repository and issue management.

**Requirements**:
- GitHub account
- `GITHUB_PERSONAL_ACCESS_TOKEN` with appropriate scopes

**Setup**:
```bash
# Create PAT at GitHub → Settings → Developer settings → Personal access tokens
deep-env store GITHUB_PERSONAL_ACCESS_TOKEN "ghp_xxxxxx"
```

**Recommended Scopes**: `repo`, `read:org`, `read:user`

**Common Errors**:
- `Bad credentials`: Token expired or revoked
- `Not found`: Token doesn't have required scope

---

### Supabase

**Purpose**: Supabase database and auth management.

**Requirements**:
- Supabase account
- `SUPABASE_ACCESS_TOKEN` from Supabase dashboard

**Setup**:
```bash
# Get from Supabase → Account → Access Tokens
deep-env store SUPABASE_ACCESS_TOKEN "sbp_xxxxxx"
```

**Common Errors**:
- `Invalid token`: Token format incorrect
- `Project not found`: Token doesn't have access to project

---

### Vercel

**Purpose**: Vercel deployment and project management.

**Requirements**:
- Vercel account
- `VERCEL_API_TOKEN` from Vercel dashboard

**Setup**:
```bash
# Get from Vercel → Settings → Tokens
deep-env store VERCEL_API_TOKEN "your-token"
```

**Common Errors**:
- `Unauthorized`: Token expired or invalid
- `Forbidden`: Token doesn't have required permissions

---

### updike-social-api

**Purpose**: Post to X/Twitter, LinkedIn, Instagram, Threads.

**Requirements**:
- OAuth credentials stored in macOS Keychain

**Setup**: Credentials managed via OAuth flows, no manual setup needed.

---

### updike-image-gen

**Purpose**: Generate branded images with Gemini AI.

**Requirements**:
- `GEMINI_API_KEY` from Google AI Studio

**Setup**:
```bash
deep-env store GEMINI_API_KEY "your-api-key"
```

---

### updike-audio-gen

**Purpose**: Generate voice narration using ElevenLabs.

**Requirements**:
- ElevenLabs account with cloned voice

**Setup**: Voice ID stored in keychain, no manual config needed.

---

### updike-content-archive

**Purpose**: Semantic search across content archive.

**Requirements**:
- `PINECONE_API_KEY` from Pinecone
- `ANTHROPIC_API_KEY` for embeddings

**Setup**:
```bash
deep-env store PINECONE_API_KEY "your-api-key"
deep-env store ANTHROPIC_API_KEY "sk-ant-..."
```

---

### updike-webflow

**Purpose**: Webflow CMS management with 63 tools.

**Requirements**:
- Webflow API token

**Setup**: Token stored in keychain via deep-env.

---

## Troubleshooting

### Check Environment Variables

Run the validation script:
```bash
./hooks/validate-env.sh
```

### Check MCP Server Status

If a tool isn't working:
1. Check if the required env var is set: `echo $VAR_NAME`
2. Check deep-env: `deep-env get VAR_NAME`
3. Restart Claude Code to reload MCP servers

### Rebuild Custom Servers

```bash
# SuperThings
cd servers/super-things && npm install && npm run build

# Unifi
cd servers/unifi && python3 -m venv venv && ./venv/bin/pip install fastmcp
```

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Tool not available | MCP server failed to start | Check env vars, rebuild if needed |
| "Connection refused" | Network issue or server down | Check endpoint URL |
| "Unauthorized" | Invalid/expired token | Regenerate API key |
| First call is slow | npx downloading package | Wait, subsequent calls will be fast |
| "Module not found" | Build incomplete | Run `npm run build` or create venv |

### Getting Help

- Run `/setup` in Claude Code for interactive troubleshooting
- Check `~/.claude/logs/` for MCP server logs
- Run `./hooks/setup-wizard.sh --force` to re-run all checks
