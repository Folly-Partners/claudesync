#!/bin/bash
# Auto-format hook for PostToolUse (Edit/Write)
# Runs prettier on supported file types after edits

# Get file path from CLAUDE_TOOL_INPUT (JSON)
FILE=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty')
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Only format supported extensions
case "$FILE" in
  *.js|*.jsx|*.ts|*.tsx|*.json|*.md|*.css|*.html|*.yaml|*.yml)
    # Find prettier in project or use global
    if [ -f "$(dirname "$FILE")/node_modules/.bin/prettier" ]; then
      "$(dirname "$FILE")/node_modules/.bin/prettier" --write "$FILE" 2>/dev/null
    elif command -v prettier &>/dev/null; then
      prettier --write "$FILE" 2>/dev/null
    fi
    ;;
esac
exit 0
