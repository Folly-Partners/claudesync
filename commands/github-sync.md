---
name: github-sync
description: Sync ALL projects and credentials - auto-commit, push, pull everything across all Macs
---

# GitHub Sync - One Command to Sync Everything

Run the full sync to make sure all projects and credentials are up to date across all Macs:

```bash
~/andrews-plugin/skills/github-sync/git-sync-all.sh
```

This syncs:
- **andrews-plugin** - Claude Code configuration and plugins
- **Deep-Personality** - Deep Personality project
- **deep-env credentials** - All API keys and secrets to iCloud

## What It Does

1. **Pulls** latest changes from GitHub (with auto-stash if needed)
2. **Commits** any uncommitted changes with auto-generated message
3. **Pushes** all commits to GitHub
4. **Pushes** deep-env credentials to iCloud

## Options

```bash
# Dry run - see what would happen without making changes
git-sync-all --dry-run

# Custom commit message
git-sync-all -m "Your commit message"

# Verbose output
git-sync-all --verbose
```

## When to Use

- At the end of a work session
- Before switching to another Mac
- After making changes to credentials or configuration
- Anytime you want to ensure everything is synced
