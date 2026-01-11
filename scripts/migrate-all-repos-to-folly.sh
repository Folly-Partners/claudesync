#!/bin/bash
# migrate-all-repos-to-folly.sh
# Migrate git remotes from personal account (awilkinson) to Folly-Partners organization

set -e

# Repository list (path:github-repo-name)
REPOS=(
  "$HOME/.claude:claude-code-sync"
  "$HOME/Journal:Journal"
  "$HOME/tiny-investors-lovable:tiny-investors-lovable"
  "$HOME/Projects/SuperThings:SuperThings"
  "$HOME/deep-background:deep-background"
  "$HOME/email-triage:email-triage"
  "$HOME/ThingsTodayPanel:ThingsTodayPanel"
  "$HOME/tiny-investors:tiny-investors"
  "$HOME/Dealhunter:Dealhunter"
  "$HOME/company-analyzer:Dealhunter"
  "$HOME/Overstory:Overstory"
)

OLD_ORG="awilkinson"
NEW_ORG="Folly-Partners"
LOG_FILE="$HOME/.claude/migration.log"

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

echo "========================================"
echo "GitHub Organization Migration"
echo "From: $OLD_ORG → To: $NEW_ORG"
echo "========================================"
echo ""

log "Migration started"

# Phase 1: Pre-flight checks
echo "Phase 1: Pre-flight checks..."
echo ""

NEEDS_MIGRATION=()
ALREADY_MIGRATED=()
ISSUES=()

for REPO_INFO in "${REPOS[@]}"; do
  REPO_PATH="${REPO_INFO%%:*}"
  REPO_NAME="${REPO_INFO##*:}"
  REPO_BASENAME=$(basename "$REPO_PATH")

  if [ ! -d "$REPO_PATH/.git" ]; then
    ISSUES+=("$REPO_BASENAME:Not a git repository")
    log "SKIP $REPO_BASENAME - not a git repo"
    continue
  fi

  cd "$REPO_PATH"
  CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

  if [ -z "$CURRENT_REMOTE" ]; then
    ISSUES+=("$REPO_BASENAME:No origin remote")
    log "SKIP $REPO_BASENAME - no origin"
    continue
  fi

  # Check migration status
  if echo "$CURRENT_REMOTE" | grep -q "$NEW_ORG/$REPO_NAME"; then
    ALREADY_MIGRATED+=("$REPO_BASENAME")
    echo -e "${GREEN}✓${NC} $REPO_BASENAME - Already migrated"
    log "SKIP $REPO_BASENAME - already migrated"
  elif echo "$CURRENT_REMOTE" | grep -q "$OLD_ORG"; then
    NEEDS_MIGRATION+=("$REPO_INFO")

    # Check for uncommitted changes (warning only)
    if ! git diff --quiet || ! git diff --cached --quiet; then
      echo -e "${YELLOW}⚠${NC} $REPO_BASENAME - Has uncommitted changes (will proceed anyway)"
      log "INFO $REPO_BASENAME - has uncommitted changes"
    else
      echo -e "${BLUE}→${NC} $REPO_BASENAME - Ready to migrate"
    fi
  else
    ISSUES+=("$REPO_BASENAME:Unknown remote - $CURRENT_REMOTE")
    log "ERROR $REPO_BASENAME - unknown remote: $CURRENT_REMOTE"
  fi
done

echo ""
echo "Summary:"
echo "  Ready to migrate: ${#NEEDS_MIGRATION[@]}"
echo "  Already migrated: ${#ALREADY_MIGRATED[@]}"
echo "  Issues: ${#ISSUES[@]}"

# Display issues if any
if [ ${#ISSUES[@]} -gt 0 ]; then
  echo ""
  echo -e "${RED}Issues found:${NC}"
  for ISSUE in "${ISSUES[@]}"; do
    REPO="${ISSUE%%:*}"
    MSG="${ISSUE##*:}"
    echo "  - $REPO: $MSG"
  done
  echo ""
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled."
    log "Migration cancelled by user - issues found"
    exit 1
  fi
fi

# Check if any repos need migration
if [ ${#NEEDS_MIGRATION[@]} -eq 0 ]; then
  echo ""
  echo -e "${GREEN}All repositories are already migrated!${NC}"
  log "Migration complete - nothing to migrate"
  exit 0
fi

# Phase 2: Confirm migration
echo ""
echo "========================================"
echo "Phase 2: Migrate Repositories"
echo "========================================"
echo ""
echo "The following repositories will be migrated:"
for REPO_INFO in "${NEEDS_MIGRATION[@]}"; do
  REPO_PATH="${REPO_INFO%%:*}"
  REPO_NAME="${REPO_INFO##*:}"
  echo "  - $(basename "$REPO_PATH") → $NEW_ORG/$REPO_NAME"
done
echo ""
read -p "Proceed with migration? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Migration cancelled."
  log "Migration cancelled by user"
  exit 1
fi

log "User confirmed - proceeding with migration"

# Phase 3: Perform migration
echo ""
SUCCESSFUL=()
FAILED=()

for REPO_INFO in "${NEEDS_MIGRATION[@]}"; do
  REPO_PATH="${REPO_INFO%%:*}"
  REPO_NAME="${REPO_INFO##*:}"
  REPO_BASENAME=$(basename "$REPO_PATH")

  echo -e "${BLUE}Migrating $REPO_BASENAME...${NC}"
  log "START $REPO_BASENAME"

  cd "$REPO_PATH"

  # Get current remote for logging
  OLD_REMOTE=$(git remote get-url origin)
  NEW_REMOTE="https://github.com/$NEW_ORG/$REPO_NAME.git"

  echo "  Old: $OLD_REMOTE"
  echo "  New: $NEW_REMOTE"
  log "  Old remote: $OLD_REMOTE"
  log "  New remote: $NEW_REMOTE"

  # Update remote URL
  if git remote set-url origin "$NEW_REMOTE" 2>&1 | tee -a "$LOG_FILE"; then
    # Validate connection
    echo "  Testing connection..."
    if git fetch origin --quiet 2>&1 | tee -a "$LOG_FILE"; then
      echo -e "  ${GREEN}✓ Successfully migrated${NC}"
      log "SUCCESS $REPO_BASENAME"
      SUCCESSFUL+=("$REPO_BASENAME")
    else
      echo -e "  ${RED}✗ Migration failed - cannot fetch from new remote${NC}"
      log "FAILED $REPO_BASENAME - fetch failed"
      FAILED+=("$REPO_BASENAME")

      # Rollback
      echo "  Rolling back..."
      git remote set-url origin "$OLD_REMOTE"
      log "  Rolled back to old remote"
    fi
  else
    echo -e "  ${RED}✗ Failed to update remote URL${NC}"
    log "FAILED $REPO_BASENAME - set-url failed"
    FAILED+=("$REPO_BASENAME")
  fi

  echo ""
done

# Phase 4: Final summary
echo "========================================"
echo "Migration Complete"
echo "========================================"
echo ""

if [ ${#SUCCESSFUL[@]} -gt 0 ]; then
  echo "Successful: ${#SUCCESSFUL[@]}"
  for REPO in "${SUCCESSFUL[@]}"; do
    echo -e "  ${GREEN}✓${NC} $REPO"
  done
fi

if [ ${#FAILED[@]} -gt 0 ]; then
  echo ""
  echo "Failed: ${#FAILED[@]}"
  for REPO in "${FAILED[@]}"; do
    echo -e "  ${RED}✗${NC} $REPO"
  done
  echo ""
  echo -e "${YELLOW}Some repositories failed to migrate.${NC}"
  echo "Check the log for details: $LOG_FILE"
  log "Migration completed with failures"
  exit 1
fi

echo ""
echo -e "${GREEN}All repositories successfully migrated!${NC}"
log "Migration completed successfully"

echo ""
echo "Next steps:"
echo "  1. Update documentation:"
echo "     - ~/.claude/README.md (lines 8, 42, 155)"
echo "     - ~/.claude/setup-new-computer.sh (line 25)"
echo "  2. Test critical repos:"
echo "     cd ~/.claude && git pull && git push"
echo "     cd ~/Deep-Personality && git pull && git push"
echo "  3. Run migration on other Macs"
echo "  4. Run validation: ~/.claude/scripts/validate-repos-for-migration.sh"
