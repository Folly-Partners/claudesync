---
name: sync
description: Sync Claude Code components across Macs via iCloud
---

# Component Sync

Sync skills, servers, commands, hooks, and agents across all your Macs via iCloud.

## Instructions

Execute the appropriate sync action based on user request:

### Show Status (default)
```bash
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --status
```

### Force Sync Now
If the user wants to force a sync (bypass 24h cooldown):
```bash
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --force
```

### Force Sync with Debug Output
If troubleshooting:
```bash
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --force --debug
```

### Rollback a Component
If the user needs to rollback a component:
```bash
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --rollback <component>
```

Example components: `skills/my-skill`, `servers/my-server`, `commands`, `hooks`

## What Gets Synced

| Component | Location | Method |
|-----------|----------|--------|
| Skills | `skills/*/` | Tarball (excludes node_modules/venv) |
| Servers | `servers/*/` | Tarball + rebuild on pull |
| Commands | `commands/*.md` | Direct copy |
| Hooks | `hooks/` | Direct copy |
| Agents | `agents/` | Direct copy |
| MCP Config | `.mcp.json` | Direct copy |

## Automatic Sync

Component sync runs automatically at session start (once per 24 hours). Use `/sync` to force sync or check status.

## Troubleshooting

- **Check conflicts:** `cat ~/.claude/.claudesync-conflicts.log`
- **Check build logs:** `cat ~/.claude/.component-sync-build.log`
- **View backups:** `ls ~/.claude/.component-sync-backups/`
