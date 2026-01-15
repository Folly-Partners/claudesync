---
name: first-run-plugins
description: On first run after claudesync setup, offer to install recommended plugins
triggers:
  - CLAUDESYNC_FIRST_RUN=true in hook output
---

# First-Run Plugin Recommendations

When you detect `CLAUDESYNC_FIRST_RUN=true` in the session start output, offer the user recommended plugins to install.

## Trigger

The `first-run-plugins.sh` hook outputs `CLAUDESYNC_FIRST_RUN=true` when the flag file exists at `~/.claude/.claudesync-first-run`.

## Action

Use `AskUserQuestion` with `multiSelect: true` to offer these plugins:

### Plugins to Offer

| Plugin | Marketplace | Description |
|--------|-------------|-------------|
| compound-engineering | every-marketplace | Advanced workflows, code review, planning |

### Implementation Steps

1. **Show welcome message**: "Welcome to claudesync! Would you like to install recommended plugins?"

2. **Use AskUserQuestion** with multi-select to let user choose plugins

3. **For selected plugins**:
   - If compound-engineering selected:
     ```
     /plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin
     /plugin install compound-engineering
     ```

4. **After installation**, delete the flag file:
   ```bash
   rm ~/.claude/.claudesync-first-run
   touch ~/.claude/.claudesync-first-run.done
   ```

## Example Interaction

```
Welcome to claudesync!

I noticed this is your first session after setup.
Would you like to install the recommended compound-engineering plugin?

It provides advanced workflows, code review skills, and planning tools.

[Yes, install it] [No, skip for now]
```

## Notes

- Only show this once (delete flag after showing)
- The `.done` file prevents showing again
- Keep it simple - just offer compound-engineering for now
