#!/bin/bash
# git-sync-check.sh - Check git status across key repositories
# Used by github-sync skill for session start checks

set -e

# ANSI colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repositories to check (add more as needed)
REPOS=(
    "$HOME/.claude"
    "$HOME/Deep-Personality"
)

# Add current directory if it's a git repo and not already in the list
if [ -d ".git" ]; then
    CWD=$(pwd)
    ALREADY_LISTED=false
    for repo in "${REPOS[@]}"; do
        if [ "$repo" = "$CWD" ]; then
            ALREADY_LISTED=true
            break
        fi
    done
    if [ "$ALREADY_LISTED" = false ]; then
        REPOS+=("$CWD")
    fi
fi

echo "========================================"
echo "Git Sync Status Check"
echo "========================================"
echo ""

ISSUES_FOUND=false

for REPO in "${REPOS[@]}"; do
    if [ ! -d "$REPO/.git" ]; then
        continue
    fi

    REPO_NAME=$(basename "$REPO")
    echo -e "${BLUE}[$REPO_NAME]${NC} $REPO"

    cd "$REPO"

    # Fetch quietly to update remote tracking
    git fetch origin 2>/dev/null || true

    # Get default branch
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

    # Check for uncommitted changes
    UNCOMMITTED=$(git status --porcelain 2>/dev/null)
    if [ -n "$UNCOMMITTED" ]; then
        echo -e "  ${YELLOW}! Uncommitted changes:${NC}"
        echo "$UNCOMMITTED" | head -10 | sed 's/^/    /'
        COUNT=$(echo "$UNCOMMITTED" | wc -l | tr -d ' ')
        if [ "$COUNT" -gt 10 ]; then
            echo "    ... and $((COUNT - 10)) more"
        fi
        ISSUES_FOUND=true
    fi

    # Check for unpushed commits
    UNPUSHED=$(git log origin/$DEFAULT_BRANCH..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "$UNPUSHED" != "0" ]; then
        echo -e "  ${YELLOW}! $UNPUSHED unpushed commit(s)${NC}"
        git log origin/$DEFAULT_BRANCH..HEAD --oneline 2>/dev/null | head -5 | sed 's/^/    /'
        if [ "$UNPUSHED" -gt 5 ]; then
            echo "    ... and $((UNPUSHED - 5)) more"
        fi
        ISSUES_FOUND=true
    fi

    # Check if behind remote
    BEHIND=$(git log HEAD..origin/$DEFAULT_BRANCH --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "$BEHIND" != "0" ]; then
        echo -e "  ${RED}! $BEHIND commit(s) behind remote${NC}"
        git log HEAD..origin/$DEFAULT_BRANCH --oneline 2>/dev/null | head -5 | sed 's/^/    /'
        if [ "$BEHIND" -gt 5 ]; then
            echo "    ... and $((BEHIND - 5)) more"
        fi
        ISSUES_FOUND=true
    fi

    # Check for stashed changes
    STASH_COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STASH_COUNT" != "0" ]; then
        echo -e "  ${YELLOW}! $STASH_COUNT stashed change(s)${NC}"
        ISSUES_FOUND=true
    fi

    # If nothing found, show clean status
    if [ -z "$UNCOMMITTED" ] && [ "$UNPUSHED" = "0" ] && [ "$BEHIND" = "0" ] && [ "$STASH_COUNT" = "0" ]; then
        echo -e "  ${GREEN}✓ Clean and up to date${NC}"
    fi

    echo ""
done

echo "========================================"

# Check for plugin updates
echo ""
echo "========================================"
echo "Plugin Update Check"
echo "========================================"
echo ""

# Check compound-engineering version
INSTALLED_PLUGIN="$HOME/.claude/plugins/marketplaces/every-marketplace/plugins/compound-engineering/.claude-plugin/plugin.json"
if [ -f "$INSTALLED_PLUGIN" ]; then
    INSTALLED_VERSION=$(grep '"version"' "$INSTALLED_PLUGIN" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
    echo -e "${BLUE}[compound-engineering]${NC}"
    echo "  Installed: $INSTALLED_VERSION"

    # Fetch latest version from GitHub (cached for 24 hours)
    CACHE_FILE="/tmp/compound-engineering-latest-version"
    CACHE_AGE=86400  # 24 hours

    if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -lt $CACHE_AGE ]; then
        LATEST_VERSION=$(cat "$CACHE_FILE")
    else
        # Fetch from GitHub raw file
        LATEST_VERSION=$(curl -s --max-time 5 "https://raw.githubusercontent.com/EveryInc/compound-engineering-plugin/main/plugins/compound-engineering/.claude-plugin/plugin.json" 2>/dev/null | \
            grep '"version"' | head -1 | \
            sed 's/.*: *"\([^"]*\)".*/\1/' || echo "")

        if [ -n "$LATEST_VERSION" ]; then
            echo "$LATEST_VERSION" > "$CACHE_FILE"
        fi
    fi

    if [ -n "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$INSTALLED_VERSION" ]; then
        echo -e "  Latest:    ${GREEN}$LATEST_VERSION${NC}"
        echo -e "  ${YELLOW}! Update available. Run: /plugin update compound-engineering${NC}"
        ISSUES_FOUND=true
    elif [ -n "$LATEST_VERSION" ]; then
        echo -e "  ${GREEN}✓ Up to date${NC}"
    else
        echo "  Latest: (unable to check)"
    fi
else
    echo -e "${YELLOW}compound-engineering not installed${NC}"
    echo "  Install with: /plugin install compound-engineering"
fi

echo ""
echo "========================================"
if [ "$ISSUES_FOUND" = true ]; then
    echo -e "${YELLOW}Action may be needed. Review above.${NC}"
    exit 1
else
    echo -e "${GREEN}All repositories are in sync.${NC}"
    exit 0
fi
