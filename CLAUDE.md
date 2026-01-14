# Claude Code Configuration

This directory contains Claude Code configuration that syncs across all of Andrew's Macs.

## Git Identity

When making commits, use:
- **Name:** Andrew Wilkinson
- **Email:** andrew@tiny.com

## Session Start: Git Sync Check (Daily)

**Once per day**, run the git sync check at session start:

```bash
~/.claude/skills/github-sync/git-sync-check.sh
```

The script self-limits to once every 24 hours. To force a check: `git-sync-check.sh --force`

This automatically finds all git repos in your home directory and checks them for:
- Uncommitted changes (from previous sessions)
- Unpushed commits (work that didn't get synced)
- Commits to pull from remote (changes from other machines)

**Actions based on results:**
- If behind remote: `git pull origin main` and tell user
- If uncommitted changes: Ask user if they want to commit or review
- If unpushed commits: Ask user if they want to push
- If clean or already checked today: Proceed silently

## Skills Available

See `~/.claude/skills/` for available skills:
- **deep-env** - Credential management for environment variables
- **github-sync** - Git synchronization at session start (this document)
- **history-pruner** - Prune old conversation history
- **commit-milestones** - Auto-commit at milestones
- **enhanced-planning** - Upgraded planning with parallel research and flow analysis

## Enhanced Planning Mode

**For non-trivial features**, use the enhanced planning workflow from `~/.claude/skills/enhanced-planning/SKILL.md`:

1. **Parallel Research** - Launch 3 simultaneous Task agents:
   - Codebase pattern analysis (similar implementations, conventions)
   - External best practices (WebSearch + WebFetch for current docs)
   - Framework/dependency documentation

2. **User Flow Analysis** - Before implementation, map:
   - Happy paths and all entry points
   - Edge cases and error states
   - User variations (roles, devices, network conditions)
   - State management and cleanup

3. **Gap Identification** - Identify missing specs, then use AskUserQuestion for critical ambiguities

4. **Structured Output** - Write plan with: research findings, user flows, implementation steps, open questions, testing strategy

**When to apply:** Any feature touching 3+ files, new integrations, architectural changes, or when Andrew says "plan" for something complex. Skip for simple bug fixes or single-file changes.

## Interaction Preferences

- **Plans with options**: When presenting plans that have multiple approaches or options, use the `AskUserQuestion` tool with multiple choice format instead of writing out options in prose. This lets Andrew quickly tap to select rather than typing responses.
