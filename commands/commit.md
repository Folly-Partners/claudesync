---
name: commit
description: Commit all uncommitted changes in the current repository with auto-generated message
---

# Commit All Changes

Commit all uncommitted changes in the current repository.

## Instructions

1. Check if we're in a git repository:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null || echo "NOT_A_REPO"
```

If not a repo, tell the user and stop.

2. Check for changes:
```bash
git status --porcelain
```

If there are no changes, tell the user "No changes to commit" and stop.

3. Show what will be committed:
```bash
git status
```

4. Stage all changes:
```bash
git add -A
```

5. Get a diff of the staged changes to understand what's being committed:
```bash
git diff --cached --stat
git diff --cached
```

6. Auto-generate a concise commit message based on all the changes. Do NOT ask the user - just use the generated message.

7. Create the commit with the generated message. Always append the Claude Code footer:
```bash
git commit -m "$(cat <<'EOF'
<commit message here>

Generated with Claude Code
EOF
)"
```

8. Show the result:
```bash
git log -1 --oneline
git status
```

Confirm the commit was successful. Remind the user they can use /push if they want to push to remote.
