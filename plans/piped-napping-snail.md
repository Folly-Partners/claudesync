# Plan: Cross-Machine Username Compatibility

## Problem Statement
Your Macs have different usernames (`andrew` vs `andrewwilkinson`), causing path incompatibilities when syncing Claude Code configuration via git.

## Issues Found

### HIGH Priority
1. **`~/.claude/mcp.json` line 6** - Hardcoded path:
   ```json
   "args": ["/Users/andrewwilkinson/SuperThings/dist/index.js"]
   ```
   This breaks on machines where username is `andrew`.

### MEDIUM Priority
2. **`~/.claude/skills/history-pruner/SKILL.md` line 45** - Example contains:
   ```bash
   du -sh ~/.claude/projects/-Users-andrewwilkinson/*.jsonl
   ```

### LOW Priority (Informational)
3. **LaunchAgent plists** - Created with expanded absolute paths at generation time. The setup script handles this correctly by regenerating on each machine.

4. **Project directory names** - Encode absolute paths (`-Users-andrew/`, `-Users-andrewwilkinson/`). This is expected behavior and not a sync issue.

## What Already Works Well
- Shell scripts use `$HOME` variable (portable)
- `settings.json` uses `$HOME` in bash contexts
- `deep-env` uses `$HOME` throughout
- Documentation uses `~/` tilde notation
- `setup-new-computer.sh` regenerates LaunchAgents with correct local paths

---

## Recommended Fixes

### Fix 1: mcp.json - Use $HOME in script wrapper
**Problem**: MCP server config doesn't support environment variable expansion in args.

**Solution**: Create a wrapper script that MCP calls, which then invokes the actual script with the correct path.

**Files to modify:**
- `~/.claude/mcp.json`
- Create: `~/.claude/scripts/run-superthings.sh`

**Implementation:**
```bash
# ~/.claude/scripts/run-superthings.sh
#!/bin/bash
exec node "$HOME/SuperThings/dist/index.js"
```

Then update mcp.json to call the wrapper:
```json
"superthings": {
  "command": "/bin/bash",
  "args": ["-c", "$HOME/.claude/scripts/run-superthings.sh"]
}
```

### Fix 2: history-pruner SKILL.md example
**Change:** Update line 45 to use portable path reference:
```bash
du -sh ~/.claude/projects/-Users-*/*.jsonl
```

---

## Verification
1. Run `git diff` after changes to confirm only intended files modified
2. Test on a machine with username `andrewwilkinson` to verify MCP server starts
3. Commit and push, then pull on other Mac to verify sync works

## Open Questions
- Is SuperThings located at `~/SuperThings/` on both machines, or different locations?
- Are there any other MCP servers with hardcoded paths?
