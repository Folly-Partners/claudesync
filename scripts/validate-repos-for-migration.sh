#!/bin/bash
# validate-repos-for-migration.sh
# Check repository migration status before migrating from awilkinson to Folly-Partners

set -e

# Repository list (path:github-repo-name)
REPOS=(
  "$HOME/.claude:claude-code-sync"
  "$HOME/Journal:Journal"
  "$HOME/tiny-investors-lovable:tiny-investors-lovable"
  "$HOME/SuperThings:SuperThings"
  "$HOME/deep-background:deep-background"
  "$HOME/email-triage:email-triage"
  "$HOME/ThingsTodayPanel:ThingsTodayPanel"
  "$HOME/tiny-investors:tiny-investors"
  "$HOME/Dealhunter:Dealhunter"
  "$HOME/Overstory:Overstory"
  "$HOME/Deep-Personality:Deep-Personality"
)

OLD_ORG="awilkinson"
NEW_ORG="Folly-Partners"

# ANSI colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "Repository Migration Status Check"
echo "========================================"
echo ""

NEEDS_MIGRATION=0
ALREADY_MIGRATED=0
ISSUES=0

for REPO_INFO in "${REPOS[@]}"; do
  REPO_PATH="${REPO_INFO%%:*}"
  REPO_NAME="${REPO_INFO##*:}"
  REPO_BASENAME=$(basename "$REPO_PATH")

  # Check if directory exists
  if [ ! -d "$REPO_PATH" ]; then
    echo -e "${RED}✗${NC} $REPO_BASENAME - Directory not found: $REPO_PATH"
    ((ISSUES++))
    continue
  fi

  # Check if it's a git repo
  if [ ! -d "$REPO_PATH/.git" ]; then
    echo -e "${RED}✗${NC} $REPO_BASENAME - Not a git repository"
    ((ISSUES++))
    continue
  fi

  cd "$REPO_PATH"

  # Get current remote
  CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

  if [ -z "$CURRENT_REMOTE" ]; then
    echo -e "${RED}✗${NC} $REPO_BASENAME - No origin remote configured"
    ((ISSUES++))
    continue
  fi

  # Check migration status (case-insensitive - GitHub URLs are lowercase)
  if echo "$CURRENT_REMOTE" | grep -iq "$NEW_ORG/$REPO_NAME"; then
    echo -e "${GREEN}✓${NC} $REPO_BASENAME - Already migrated to $NEW_ORG"
    ((ALREADY_MIGRATED++))
  elif echo "$CURRENT_REMOTE" | grep -iq "$OLD_ORG"; then
    # Check for uncommitted changes
    UNCOMMITTED=""
    if ! git diff --quiet || ! git diff --cached --quiet; then
      UNCOMMITTED=" ${YELLOW}(has uncommitted changes)${NC}"
    fi

    # Check for unpushed commits
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    UNPUSHED=$(git log origin/$DEFAULT_BRANCH..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNPUSHED" != "0" ]; then
      UNCOMMITTED="$UNCOMMITTED ${YELLOW}($UNPUSHED unpushed commits)${NC}"
    fi

    echo -e "${BLUE}→${NC} $REPO_BASENAME - Needs migration$UNCOMMITTED"
    ((NEEDS_MIGRATION++))
  else
    echo -e "${YELLOW}⚠${NC} $REPO_BASENAME - Unknown remote: $CURRENT_REMOTE"
    ((ISSUES++))
  fi
done

echo ""
echo "========================================"
echo "Summary:"
echo "  Needs migration: $NEEDS_MIGRATION"
echo "  Already migrated: $ALREADY_MIGRATED"
echo "  Issues: $ISSUES"
echo "========================================"

if [ $NEEDS_MIGRATION -eq 0 ] && [ $ISSUES -eq 0 ]; then
  echo -e "${GREEN}All repositories are migrated!${NC}"
  exit 0
elif [ $ISSUES -gt 0 ]; then
  echo -e "${YELLOW}Some issues found. Review above.${NC}"
  exit 1
else
  echo -e "${BLUE}Ready to migrate $NEEDS_MIGRATION repositories.${NC}"
  exit 0
fi
