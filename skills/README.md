# ClaudeSync Skills

Skills extend Claude Code with specialized capabilities that trigger automatically or on-demand.

## Decision Matrix

| Need | Use This Skill |
|------|----------------|
| Sync components across Macs | [component-sync](component-sync/SKILL.md) |
| Manage env vars securely | [deep-env](deep-env/SKILL.md) |
| Plan complex features | [enhanced-planning](enhanced-planning/SKILL.md) |
| Git status check at session start | [github-sync](github-sync/SKILL.md) |
| Clean up old conversation history | [history-pruner](history-pruner/SKILL.md) |
| Auto-commit at milestones | [commit-milestones](commit-milestones/SKILL.md) |
| First-run plugin recommendations | [first-run-plugins](first-run-plugins/SKILL.md) |
| MCP config management | [mcp-sync](mcp-sync/SKILL.md) |
| Post to social, search content, generate images | [updike](updike/SKILL.md) |

## Available Skills

### [deep-env](deep-env/)
Secure credential management across Macs via macOS Keychain + iCloud. Automatically generates `.env.local` files from `.env.example` templates.

### [component-sync](component-sync/)
Automatic, invisible syncing of Claude Code components (skills, servers, commands, hooks, agents) across all Macs via iCloud. Runs automatically at session start.

### [github-sync](github-sync/)
Daily git health check at session start. Finds uncommitted changes, unpushed commits, and commits to pull across all repositories.

### [enhanced-planning](enhanced-planning/)
Upgraded planning workflow with parallel research, external documentation fetching, and systematic user flow analysis. Use for non-trivial features.

### [history-pruner](history-pruner/)
Prunes old Claude Code conversation history to save disk space. Useful when project files exceed 50MB or for periodic maintenance.

### [commit-milestones](commit-milestones/)
Automatically commits changes when completing significant milestones like features, bug fixes, or refactors.

### [first-run-plugins](first-run-plugins/)
Shows plugin recommendations on first run after claudesync setup. Offers to install compound-engineering plugin.

### [mcp-sync](mcp-sync/)
Manages MCP server configuration with `${VAR}` expansion for credentials stored in deep-env.

### [updike](updike/)
Social content engine for Andrew Wilkinson. Post to X/LinkedIn/Instagram/Threads, search 6,600+ content archive pieces, generate quote cards and carousels, create voice narration.

## How Skills Work

Skills are defined in `SKILL.md` files with YAML frontmatter:

```yaml
---
name: skill-name
description: When Claude should use this skill
triggers:
  - trigger condition 1
  - trigger condition 2
---

# Skill Title

Instructions for Claude when this skill is active...
```

Claude automatically invokes skills based on:
- **Name match**: User references the skill
- **Description match**: Conversation matches the description
- **Trigger match**: A trigger condition is detected
- **Hook output**: Session hooks output trigger values

## Creating New Skills

1. Create a new directory under `skills/`
2. Add a `SKILL.md` with YAML frontmatter
3. Optionally add supporting scripts
4. Push to sync across Macs

See [deep-env](deep-env/) for a complete example with both README and SKILL.md.
