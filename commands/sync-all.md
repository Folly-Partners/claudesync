---
name: sync-all
description: Sync ALL projects - auto-commit, push, and pull everything to/from GitHub
---

# Sync All Projects

Run the full sync script to make sure all projects are up to date:

```bash
~/andrews-plugin/skills/github-sync/git-sync-all.sh
```

This will:
1. **Pull** any new commits from remote (with auto-stash if needed)
2. **Commit** any uncommitted changes with auto-generated message
3. **Push** all commits to GitHub

## Options

```bash
# Dry run - see what would happen without making changes
~/andrews-plugin/skills/github-sync/git-sync-all.sh --dry-run

# Custom commit message
~/andrews-plugin/skills/github-sync/git-sync-all.sh -m "Your commit message"

# Verbose output
~/andrews-plugin/skills/github-sync/git-sync-all.sh --verbose
```

## Registered Projects

The script syncs these repositories:
- `~/andrews-plugin` - Claude Code configuration and plugins
- `~/Deep-Personality` - Deep Personality project

To add more, edit `~/andrews-plugin/skills/github-sync/git-sync-all.sh` and add to the `REPOS` array.
