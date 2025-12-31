# Plan: Fix Things MCP Issues

## Root Cause Identified

**The working directory doesn't exist.** The session is set to `/Users/andrewwilkinson/Projects/things-mcp-silent` but this project was renamed to `SuperThings`. All bash commands fail with exit code 1 because they're executing in a non-existent directory.

## Solution

### Step 1: Change Working Directory
Start a new Claude Code session from a valid directory:
```bash
cd /Users/andrewwilkinson/Projects/SuperThings
# or any other valid directory like ~
```

### Step 2: Verify Things 3 is Running
Once bash works, ensure Things 3 is open:
```bash
open -a "Things3"
```

### Step 3: Check Automation Permissions
If Things MCP still fails after bash works:
- System Settings > Privacy & Security > Automation
- Ensure Terminal (or the app running Claude) can control Things 3

### Step 4: Apply Pending Things Updates
Once Things MCP responds, apply updates from:
`~/.claude/cache/things-updates-pending-2024-12-31.md`

**19 tasks to mark complete:**
- Use `mcp__things-mcp__things_update_todo` with `completed: true`

**4 tasks to update (title + notes):**
- Task 7 (ADHD Conferences): ID `DzFrUvxSrA7459YKmZC3fe`
- Task 17 (Google Voice): ID `5zEoJpxrxVsizPS9qV2Qdm`
- Task 22 (Hoffman Process): ID `2g5pbEGE7XsKdtYk9hKh9a`
- Task 29 (Elf on Shelf): ID `5J9aWeT2xR5FLSEU9PBWDE`

**1 task to move:**
- Task 26 (Sun Café): ID `3dsYDpM6P8bVU2rSjFGGZq` → Deep Work project

## Why This Happened

The project `/Users/andrewwilkinson/Projects/things-mcp-silent` was renamed to `SuperThings` (per CHANGELOG.md line 39). The Claude session retained the old path as working directory.

## Files Reference
- Things updates: `~/.claude/cache/things-updates-pending-2024-12-31.md`
- Emails to send: `~/.claude/cache/emails-to-send-2024-12-31.md`
