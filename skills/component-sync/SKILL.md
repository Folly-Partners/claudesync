# Component Sync Skill

Automatic, invisible syncing of Claude Code components (skills, servers, commands, hooks, agents, MCP configs) across all your Macs via iCloud.

## How It Works

This skill runs automatically at SessionStart (via hook) and:
1. Computes hashes of your installed plugin components
2. Compares with the iCloud registry
3. Pushes any local changes that are newer
4. Pulls any remote changes that are newer
5. Rebuilds servers if needed (npm install, pip install)

## What Gets Synced

| Component | Description |
|-----------|-------------|
| Skills | All skill directories (SKILL.md + scripts) |
| Servers | Custom MCP servers (source only, rebuilt on pull) |
| Commands | Slash command markdown files |
| Hooks | Hook scripts + hooks.json |
| Agents | Agent definitions |
| MCP Config | `.mcp.json` (contains credential references) |

## iCloud Registry Location

```
~/Library/Mobile Documents/com~apple~CloudDocs/.claudesync/
├── manifest.json              # Master index with hashes + timestamps
├── machines/
│   └── {hostname}.json        # Per-machine sync state
└── components/
    ├── skills/*.tar.gz        # Compressed skill directories
    ├── servers/*.tar.gz       # Compressed server source (no deps)
    ├── commands/              # Command markdown files
    ├── hooks/                 # Hook scripts + hooks.json
    └── agents/                # Agent definitions
```

## Usage

### Automatic (recommended)
The skill runs automatically once per day at session start. No action needed.

### Manual trigger
```bash
# Force a sync check now
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --force
```

### Check status
```bash
# View sync status
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --status
```

### Rollback a component
```bash
# Rollback to last-known-good state
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --rollback skills/my-skill
```

## Conflict Resolution

When the same component is modified on two machines at nearly the same time:
- The version with the latest timestamp wins
- Conflicts are logged to `~/.claude/.claudesync-conflicts.log`
- Both versions are kept temporarily for manual review

## Local State Files

```
~/.claude/
├── .component-sync-last-run       # Timestamp for rate limiting (24h)
├── .component-sync-state.json     # Local hashes for quick comparison
├── .component-sync-machine-id     # Hostname identifier
├── .component-sync-conflicts.log  # Conflict history
├── .component-sync-build.log      # Server build output
└── .component-sync-backups/       # Rollback backups
```

## Exclusions

These paths are excluded from sync:
- `node_modules/`
- `venv/`
- `dist/`
- `__pycache__/`
- `.git/`
- `*.pyc`

## Restart Requirements

Some changes require a Claude Code restart:
- New/modified MCP configs (`.mcp.json`)
- New/modified hooks (`hooks.json`)

The sync will notify you when a restart is needed.

## Troubleshooting

### Sync not running
Check the cooldown: `cat ~/.claude/.component-sync-last-run`
Force a sync: `component-sync.sh --force`

### Build failures
Check the build log: `cat ~/.claude/.component-sync-build.log`

### Conflicts
Review conflicts: `cat ~/.claude/.claudesync-conflicts.log`

### iCloud issues
Verify iCloud is accessible:
```bash
ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/.claudesync/
```
