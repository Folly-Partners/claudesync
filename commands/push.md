---
name: push
description: Commit all uncommitted changes and push to remote
---

# Commit and Push All Changes

Commit all uncommitted changes and push to remote.

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

If there are no changes to commit, check if there are unpushed commits:
```bash
git log @{u}..HEAD --oneline 2>/dev/null
```

If there are unpushed commits, skip to step 8 to push them. If nothing to commit or push, tell the user and stop.

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

8. Push to remote:
```bash
git push
```

If push fails due to no upstream, set it:
```bash
git push -u origin $(git branch --show-current)
```

9. Show the result:
```bash
git log -1 --oneline
git status
```

Confirm the commit and push were successful.
