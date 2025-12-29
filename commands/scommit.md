# Session Commit

Commit only specific files from this session (you select which ones).

## Instructions

1. Check if we're in a git repository:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null || echo "NOT_A_REPO"
```

If not a repo, tell the user and stop.

2. Get the list of all modified/staged/untracked files:
```bash
git status --porcelain
```

If there are no changes, tell the user "No changes to commit" and stop.

3. Parse the output and present each changed file as an option using AskUserQuestion with multiSelect: true. Format each option clearly showing the status (M=modified, A=added, D=deleted, ??=untracked).

4. After the user selects files, stage ONLY those specific files:
```bash
git add <selected-files>
```

5. Get a diff of the staged changes to understand what's being committed:
```bash
git diff --cached --stat
git diff --cached
```

6. Auto-generate a concise commit message based on the changes. Present it to the user using AskUserQuestion with options:
   - "Use this message" (the generated message)
   - "Edit message" (let them provide their own)

7. Create the commit with the final message. Always append the Claude Code footer:
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
```

Confirm the commit was successful.
