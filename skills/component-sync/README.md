# component-sync

Automatic, invisible syncing of Claude Code components across all your Macs via iCloud.

## Quick Start

This skill runs automatically at session start. No action needed.

To force a sync:
```bash
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --force
```

To check status:
```bash
~/.claude/plugins/marketplaces/Folly/skills/component-sync/component-sync.sh --status
```

## How It Works

```
┌─────────────┐                    ┌─────────────┐
│   Mac #1    │                    │   Mac #2    │
│             │                    │             │
│  skills/    │    ┌─────────┐    │  skills/    │
│  servers/   │◄──►│ iCloud  │◄──►│  servers/   │
│  commands/  │    │ .cloud- │    │  commands/  │
│  hooks/     │    │  sync/  │    │  hooks/     │
│  agents/    │    └─────────┘    │  agents/    │
└─────────────┘                    └─────────────┘
```

At session start, the skill:
1. Computes hashes of installed plugin components
2. Compares with the iCloud registry
3. Pushes local changes that are newer
4. Pulls remote changes that are newer
5. Rebuilds servers if needed (npm install, pip install)

## What Gets Synced

| Component | Description |
|-----------|-------------|
| Skills | All skill directories (SKILL.md + scripts) |
| Servers | Custom MCP servers (source only, rebuilt on pull) |
| Commands | Plugin slash command markdown files |
| Hooks | Hook scripts + hooks.json |
| Agents | Agent definitions |
| MCP Config | `.mcp.json` (contains credential references) |
| Global Commands | User's `~/.claude/commands/` directory |
| User CLAUDE.md | User's `~/.claude/CLAUDE.md` instructions |

## Commands

| Command | Description |
|---------|-------------|
| `component-sync.sh` | Default: run sync if due |
| `component-sync.sh --force` | Force sync now (bypass 24h cooldown) |
| `component-sync.sh --status` | View sync status |
| `component-sync.sh --rollback skills/my-skill` | Rollback to backup |

## iCloud Registry Location

```
~/Library/Mobile Documents/com~apple~CloudDocs/.claudesync/
├── manifest.json              # Master index with hashes + timestamps
├── machines/
│   └── {hostname}.json        # Per-machine sync state
└── components/
    ├── skills/*.tar.gz        # Compressed skill directories
    ├── servers/*.tar.gz       # Compressed server source
    ├── commands/              # Plugin command files
    ├── hooks/                 # Hook scripts
    ├── agents/                # Agent definitions
    └── user-claude-md.md      # User's ~/.claude/CLAUDE.md
```

## Conflict Resolution

When the same component is modified on two machines at nearly the same time:
- The version with the latest timestamp wins
- Conflicts are logged to `~/.claude/.claudesync-conflicts.log`
- Both versions are kept temporarily for manual review

## Restart Requirements

Some changes require a Claude Code restart:
- New/modified MCP configs (`.mcp.json`)
- New/modified hooks (`hooks.json`)

The sync will notify you when a restart is needed.

## For Claude Code

This skill runs automatically at session start (via hook). You don't need to invoke it manually unless:
- User explicitly asks to sync
- User wants to check sync status
- User needs to rollback a component
