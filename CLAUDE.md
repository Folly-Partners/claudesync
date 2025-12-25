# Claude Code Configuration

This directory contains Claude Code configuration that syncs across all of Andrew's Macs.

## Session Start: Git Sync Check

**At the START of every session** (first message, or resuming after a break), run the git sync check:

```bash
~/.claude/skills/github-sync/git-sync-check.sh
```

This checks `~/.claude` and `~/Deep-Personality` for:
- Uncommitted changes (from previous sessions)
- Unpushed commits (work that didn't get synced)
- Commits to pull from remote (changes from other machines)

**Actions based on results:**
- If behind remote: `git pull origin main` and tell user
- If uncommitted changes: Ask user if they want to commit or review
- If unpushed commits: Ask user if they want to push
- If clean: Proceed silently (don't mention git unless asked)

**While working:** Proactively suggest committing after completing significant work (features, bug fixes, new skills/commands). Before ending a session, remind about uncommitted/unpushed changes.

## Skills Available

See `~/.claude/skills/` for available skills:
- **deep-env** - Credential management for environment variables
- **github-sync** - Git synchronization at session start (this document)
- **history-pruner** - Prune old conversation history
- **commit-milestones** - Auto-commit at milestones

## Interaction Preferences

- **Plans with options**: When presenting plans that have multiple approaches or options, use the `AskUserQuestion` tool with multiple choice format instead of writing out options in prose. This lets Andrew quickly tap to select rather than typing responses.
