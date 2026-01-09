# Fix Claude Island Session Detection

## Problem Summary
Claude Island is not detecting the current Claude Code session despite:
- Claude Island app running (PID 24167) and listening on `/tmp/claude-island.sock`
- Hook file exists at `~/.claude/hooks/claude-island-state.py` with correct code
- Hooks configured in `~/.claude/settings.json` with absolute paths
- User restarted their Claude session

## Root Cause
The hooks in settings.json are not being executed by Claude Code because **settings changes require killing all Claude Code processes, not just starting a new session**.

User confirmed:
- They only exited and ran `claude` again (not a full process restart)
- This is a fresh Claude Island install that has never worked

Secondary issues:
- Some hooks (SessionStart, SessionEnd, Stop, SubagentStop, UserPromptSubmit) are missing the `"matcher"` field for consistency

## Implementation Plan

### Step 1: Kill all Claude Code processes (PRIMARY FIX)
This is the most likely fix - settings.json changes don't take effect until Claude Code processes are fully restarted.

```bash
# Exit current session first (if in one)
# Then kill all Claude processes:
killall claude

# Wait a moment, then start fresh
claude
```

Claude Island should immediately detect the new session.

### Step 2: If Step 1 doesn't work - Add missing matcher fields
Some hooks are missing `"matcher"` fields that other hooks have:
- SessionStart (line 133)
- SessionEnd (line 123)
- Stop (line 143)
- SubagentStop (line 153)
- UserPromptSubmit (line 163)

Add `"matcher": "*"` to each for consistency with other hooks.

**Critical files:**
- `/Users/andrewwilkinson/.claude/settings.json`

Then repeat Step 1 (kill and restart).

### Step 3: If still not working - Debug hook execution
Test if the hook script works when called manually:
```bash
echo '{"session_id":"manual-test","hook_event_name":"SessionStart","cwd":"'$(pwd)'"}' | python3 ~/.claude/hooks/claude-island-state.py
```

Check if Claude Island shows a session after this manual test. If it does, hooks work but Claude Code isn't calling them.

### Step 4: Last resort - Check Claude Island app state
- Quit and reopen Claude Island app (Cmd+Q, then relaunch)
- Verify socket exists: `ls -la /tmp/claude-island.sock`
- Verify app is listening: `lsof /tmp/claude-island.sock`
- Try the manual hook test again (Step 3)

## Verification
After implementing the fix:
1. Start a new Claude session with `claude`
2. Claude Island should immediately show the session in its UI
3. The session should show status like "waiting_for_input"
4. When you run a command, status should change to "running_tool" or "processing"
5. The session should disappear from Claude Island when you `/exit`

## Alternative Hypothesis
If none of the above works, the issue might be:
- Claude Code version incompatibility with the hook format
- macOS permissions blocking hook execution
- Security settings preventing socket communication
- Hook script needs different Python path or environment
