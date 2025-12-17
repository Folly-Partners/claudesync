---
name: github-sync
description: Automatically sync with GitHub at session start and remind Claude to push/pull changes as it works. Triggers on session start, reactivation, or when working in git repositories.
---

# github-sync - Session Git Synchronization

Ensures Claude Code sessions stay synchronized with GitHub, preventing lost work and merge conflicts across machines.

## When to Use This Skill

**AUTOMATICALLY TRIGGER** at the start of every session or when resuming work:
- Session just started (first message of a conversation)
- Session reactivated after inactivity (>30 min gap)
- Working in any git repository
- Before making significant changes to a codebase
- After completing a significant milestone

## Session Start Routine

**At the beginning of EVERY session**, run this check:

```bash
# Quick git health check for common directories
for dir in ~/.claude ~/Deep-Personality; do
  if [ -d "$dir/.git" ]; then
    echo "=== Git status for $dir ==="
    cd "$dir"
    git fetch origin 2>/dev/null

    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
      echo "WARNING: Uncommitted changes detected"
      git status --short
    fi

    # Check for unpushed commits
    UNPUSHED=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNPUSHED" != "0" ]; then
      echo "WARNING: $UNPUSHED unpushed commit(s)"
    fi

    # Check if behind remote
    BEHIND=$(git log HEAD..origin/main --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "$BEHIND" != "0" ]; then
      echo "NOTICE: $BEHIND commit(s) to pull from remote"
    fi
  fi
done
```

## What to Do Based on Status

### If behind remote:
```bash
git pull origin main
```
Tell user: "Pulled X new commits from GitHub."

### If uncommitted changes exist:
Ask user: "There are uncommitted changes from a previous session. Should I commit them or review first?"

### If unpushed commits exist:
Ask user: "You have X commits that haven't been pushed to GitHub. Push now?"

### If everything is clean:
Silently proceed with the session (don't mention git is clean unless asked).

## Ongoing Work Reminders

### While Working in a Git Repository

**After completing a significant piece of work:**
1. Run `git status` to see changes
2. Suggest committing with a descriptive message
3. Ask if user wants to push

**Significant milestones include:**
- Completing a feature
- Fixing a bug
- Finishing a refactor
- Creating a new skill or command
- Any work that took >15 minutes

### Before Ending a Session

If the user says goodbye, ends work, or the conversation seems to be concluding:
1. Check for uncommitted changes
2. Check for unpushed commits
3. Remind user: "Don't forget to push your changes to GitHub if you haven't already."

## Quick Reference Commands

```bash
# Full sync (pull then push)
cd ~/.claude && git pull origin main && git add -A && git commit -m "Sync: $(date '+%Y-%m-%d %H:%M')" && git push origin main

# Check status across key repos
~/.claude/skills/github-sync/git-sync-check.sh

# Force sync ~/.claude config
~/.claude/sync-claude-config.sh

# Push changes to current repo
git add -A && git commit -m "message" && git push origin main
```

## Repositories to Monitor

- `~/.claude` - Claude Code configuration (syncs via launch agent, but check anyway)
- `~/Deep-Personality` - Deep Personality project
- Any directory where user is actively working

## Important Notes

- Never force push without explicit user permission
- Always pull before pushing to avoid conflicts
- If merge conflicts occur, help user resolve them
- The `~/.claude` repo has a daily auto-sync, but manual sync is still good practice
- Credential files (`.env.local`, `.credentials.json`) should never be committed
