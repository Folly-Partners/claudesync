#!/bin/bash
# Auto-merge settings.local.json into settings.json

LOCAL="$HOME/.claude/settings.local.json"
MAIN="$HOME/.claude/settings.json"

# Exit silently if no local settings to merge
[ ! -f "$LOCAL" ] && exit 0

# Check jq is available (exit 0 to not block session)
command -v jq &>/dev/null || exit 0

# Validate both files are valid JSON
jq empty "$LOCAL" 2>/dev/null || exit 0
jq empty "$MAIN" 2>/dev/null || exit 0

# Skip merge if wildcard already present (everything already allowed)
if jq -e '.permissions.allow | index("*")' "$MAIN" &>/dev/null; then
    rm -f "$LOCAL"  # Clean up local file since it's not needed
    exit 0
fi

# Create backup
cp "$MAIN" "$MAIN.bak"

# Deep merge with special array handling for permissions
# - Arrays under .permissions are concatenated and deduped
# - All other settings use jq's recursive merge (local overwrites main)
jq -s '
  .[0] as $main | .[1] as $local |
  ($main * $local) |
  .permissions.allow = ([($main.permissions.allow // [])[], ($local.permissions.allow // [])[]] | unique) |
  .permissions.deny = ([($main.permissions.deny // [])[], ($local.permissions.deny // [])[]] | unique)
' "$MAIN" "$LOCAL" > "$MAIN.tmp"

# Only replace if output is valid JSON
if jq empty "$MAIN.tmp" 2>/dev/null; then
  mv "$MAIN.tmp" "$MAIN"
  rm -f "$LOCAL" "$MAIN.bak"
else
  # Restore backup on failure
  mv "$MAIN.bak" "$MAIN"
  rm -f "$MAIN.tmp"
fi

exit 0
