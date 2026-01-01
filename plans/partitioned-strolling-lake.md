# Fix SuperThings MCP Tools Not Being Exposed

## Root Cause Analysis

**Finding:** The SuperThings MCP server is working correctly. When tested directly with NDJSON format, it properly returns all 20 tools including `things_update_todo`, `things_add_todo`, etc.

**The Real Issue:** Claude Code shows the server as "Connected" but the tools aren't available to me in this session. This is a **Claude Code session/caching issue**, not a SuperThings bug.

### Evidence:
1. `claude mcp list` shows: `things-mcp: node /Users/andrewwilkinson/Projects/SuperThings/dist/index.js - ✓ Connected`
2. Direct MCP server test returns all 20 tools correctly
3. When I try to call `mcp__things-mcp__things_update_todo`, I get "No such tool available"
4. The tools ARE listed in my function schema but not callable at runtime

## Fix

### Option 1: Restart Claude Code Session (Immediate Fix)
Simply quit and restart Claude Code. The MCP tools should be available in the new session.

### Option 2: Refresh MCP Connection (Alternative)
Run `/mcp` command and re-enable the things-mcp server to force a refresh.

### Option 3: Session was Started Before Server was Ready
If the MCP server wasn't ready when this session started, the tools wouldn't have been loaded. Restarting the session will fix this.

## Why This Happened

The MCP server was likely in a problematic state when this Claude Code session started:
- The session cached the "no tools available" state
- Even though the server later became healthy, the session didn't refresh its tool list
- Claude Code's MCP health check shows "Connected" but doesn't re-fetch tools mid-session

## No Code Changes Needed

The SuperThings MCP server code is working correctly. The `src/index.ts`, tool registry, and all handlers are functioning properly. The MCP SDK integration is correct.

## Verification After Fix

After restarting, verify the tools are available by:
1. Try calling `mcp__things-mcp__things_get_inbox`
2. Or run a simple test like `mcp__things-mcp__things_add_todo` with a test title

## Summary

- **SuperThings Plugin:** Working correctly ✓
- **MCP Configuration:** Correct ✓
- **Claude Code Session:** Needs restart to refresh tools
