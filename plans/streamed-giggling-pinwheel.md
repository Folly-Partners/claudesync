# Zapier MCP OAuth 500 Error - Troubleshooting Plan

## Problem Summary
Zapier MCP authentication fails with HTTP 500 during OAuth token exchange. Browser auth succeeds, but Zapier's backend returns an HTML error page instead of JSON tokens.

**Status:** Known bug affecting multiple users (Zapier Community thread Dec 27, 2025)

## Root Cause
- Zapier's OAuth token exchange endpoint (`mcp.zapier.com`) is returning HTTP 500
- This is a **server-side Zapier bug**, not a Claude Code or local config issue
- No credentials are stored because the exchange never completes

## Troubleshooting Steps (In Order)

### Step 1: Clean Slate - Delete & Recreate MCP Server
1. Go to https://mcp.zapier.com
2. Delete your existing MCP server completely
3. Create a NEW MCP server:
   - Client type: Select **"Other"** (not Claude specifically)
   - This may route to different backend infrastructure
4. Copy the new URL from the "Connect" tab
5. Update Claude Code config

**Config change needed in `/Users/andrewwilkinson/.claude.json`:**
```json
"zapier": {
  "type": "http",
  "url": "YOUR_NEW_URL_HERE"
}
```

### Step 2: Re-enable and Authenticate
1. Remove "zapier" from `disabledMcpServers` array in `.claude.json`
2. Restart Claude Code
3. Run `/mcp` and try to authenticate
4. If browser shows "Authentication Successful":
   - **Immediately restart Claude Code** (known bug #10250)
   - Check if it connects after restart

### Step 3: Check for Stored Credentials
After attempting auth, check if tokens were stored:
```bash
ls -la ~/.claude/.credentials.json
```
If file exists with `mcpOAuth` section containing `zapier`, restart should work.

### Step 4: Alternative - Use Authorization Header Format
Some users report success with explicit auth headers instead of URL-embedded tokens:
```json
"zapier": {
  "type": "http",
  "url": "https://mcp.zapier.com/api/mcp/mcp",
  "headers": {
    "Authorization": "Bearer YOUR_TOKEN_HERE"
  }
}
```
Get the bearer token from Zapier's MCP dashboard.

### Step 5: If All Else Fails
1. **Wait 24-48 hours** - Zapier may deploy a fix
2. **Report to Zapier** - Add your experience to the community thread:
   https://community.zapier.com/troubleshooting-99/mcp-oauth-token-exchange-returning-http-500-error-52483
3. **Join Zapier Early Access Slack** for faster support:
   https://join.slack.com/t/zapierearlyaccess/shared_invite/zt-2dqgxv9rn-ECeO5uS~n~27gk5hd91pPA

## Files to Modify
- `/Users/andrewwilkinson/.claude.json` - MCP server config (lines 86-90, 134-136)

## References
- Zapier Community Thread: https://community.zapier.com/troubleshooting-99/mcp-oauth-token-exchange-returning-http-500-error-52483
- Claude Code Bug #10250: https://github.com/anthropics/claude-code/issues/10250
- Zapier MCP Docs: https://help.zapier.com/hc/en-us/articles/36265392843917
