---
name: first-run-plugins
description: On first run after claudesync setup, offer to install recommended plugins
triggers:
  - CLAUDESYNC_FIRST_RUN=true in hook output
---

# First-Run Plugin Recommendations

When you detect `CLAUDESYNC_FIRST_RUN=true` in the session start output, show the user how to install recommended plugins using the `/plugin` command.

## Trigger

The `first-run-plugins.sh` hook outputs `CLAUDESYNC_FIRST_RUN=true` when the flag file exists at `~/.claude/.claudesync-first-run`.

## Action

**Always ask before installing.** Show the user the commands and let them choose whether to install or skip.

### Implementation Steps

1. **Show welcome message with plugin recommendation**:

```
Welcome to claudesync!

I recommend the **compound-engineering** plugin for advanced workflows,
code review skills, and planning tools.

**Quick install** (run these commands in terminal):
```bash
claude plugin marketplace add https://github.com/EveryInc/every-marketplace
claude plugin install compound-engineering
```

**Or use the plugin manager UI**: Run `/plugin` to browse and install interactively.

Would you like me to install it now, or skip for now?
```

2. **Use AskUserQuestion** to let user choose:
   - "Install it" - run the two CLI commands above
   - "Skip for now" - continue without installing

3. **After showing the recommendation**, delete the flag file:
   ```bash
   rm ~/.claude/.claudesync-first-run
   touch ~/.claude/.claudesync-first-run.done
   ```

## Example Interaction

```
Welcome to claudesync!

I noticed this is your first session after setup. I recommend installing
the **compound-engineering** plugin for advanced workflows and planning tools.

**Quick install** (run in terminal):
  claude plugin marketplace add https://github.com/EveryInc/every-marketplace
  claude plugin install compound-engineering

Or run `/plugin` to browse and install via the UI.

[Install it] [Skip for now]
```

## Notes

- **Always ask first** - never install without user consent
- Only show this recommendation once (delete flag after showing)
- The `.done` file prevents showing again
- Keep it simple - just recommend compound-engineering for now
